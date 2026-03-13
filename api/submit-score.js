const CORS_HEADERS = {
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-leaderboard-key',
};

export const config = {
  runtime: 'edge',
};

function jsonResponse(status, body, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...extraHeaders,
    },
  });
}

function normalizeName(name) {
  return name.trim().replace(/\s+/g, ' ');
}

function sanitizeNameKey(name) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function normalizeSeed(seed) {
  if (typeof seed !== 'string') {
    return null;
  }
  const normalized = seed.trim().toUpperCase();
  if (!/^[A-Z0-9]{5}$/.test(normalized)) {
    return null;
  }
  return normalized;
}

function buildLeaderboardMember(name, createdAt, seed) {
  return JSON.stringify({
    n: name,
    c: createdAt,
    s: seed,
    i: crypto.randomUUID(),
  });
}

function buildDedupeKey(name, timeMs) {
  const normalizedName = name.toLowerCase();
  return `leaderboard:dedupe:${normalizedName}:${timeMs}`;
}

async function kvCommand(baseUrl, token, commandParts) {
  const encoded = commandParts.map((part) => encodeURIComponent(String(part)));
  const response = await fetch(`${baseUrl}/${encoded.join('/')}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error(`kv command failed: ${response.status}`);
  }

  const json = await response.json();
  return json.result;
}

export default async function handler(request) {
  const allowedOrigin = process.env.LEADERBOARD_ALLOWED_ORIGIN || '*';
  const corsHeaders = {
    ...CORS_HEADERS,
    'Access-Control-Allow-Origin': allowedOrigin,
    Vary: 'Origin',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' }, corsHeaders);
  }

  const serverKey = process.env.LEADERBOARD_SERVER_KEY || '';
  const submittedKey = request.headers.get('x-leaderboard-key') || '';
  if (!serverKey || submittedKey != serverKey) {
    return jsonResponse(401, { error: 'unauthorized' }, corsHeaders);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse(400, { error: 'invalid_json' }, corsHeaders);
  }

  const rawName = typeof payload?.name === 'string' ? payload.name : '';
  const name = normalizeName(rawName);
  const timeMs = Number(payload?.timeMs);
  const seed = normalizeSeed(payload?.seed);

  const validName = name.length >= 2 && name.length <= 24;
  const validTime = Number.isInteger(timeMs) && timeMs >= 1000 && timeMs <= 3600000;
  if (!validName || !validTime) {
    return jsonResponse(400, { error: 'invalid_payload' }, corsHeaders);
  }

  const kvUrl = process.env.KV_REST_API_URL;
  const kvToken = process.env.KV_REST_API_TOKEN;
  if (!kvUrl || !kvToken) {
    return jsonResponse(500, { error: 'kv_not_configured' }, corsHeaders);
  }

  const keySuffix = sanitizeNameKey(name);
  if (!keySuffix) {
    return jsonResponse(400, { error: 'invalid_name' }, corsHeaders);
  }

  const dedupeKey = buildDedupeKey(keySuffix, timeMs);
  const dedupeResult = await kvCommand(kvUrl, kvToken, [
    'set',
    dedupeKey,
    '1',
    'EX',
    '1800',
    'NX',
  ]);
  if (dedupeResult !== 'OK') {
    return jsonResponse(200, { ok: true, duplicate: true }, corsHeaders);
  }

  const bestKey = `leaderboard:best:${keySuffix}`;
  const currentRaw = await kvCommand(kvUrl, kvToken, ['get', bestKey]);
  const currentBest = currentRaw == null ? null : Number(currentRaw);
  if (currentBest == null || (Number.isFinite(currentBest) && timeMs < currentBest)) {
    await kvCommand(kvUrl, kvToken, ['set', bestKey, String(timeMs)]);
    await kvCommand(kvUrl, kvToken, ['set', `${bestKey}:name`, name]);
  }

  const createdAt = Date.now();
  await kvCommand(kvUrl, kvToken, [
    'zadd',
    'leaderboard:times',
    String(timeMs),
    buildLeaderboardMember(name, createdAt, seed),
  ]);

  return jsonResponse(200, { ok: true, duplicate: false }, corsHeaders);
}
