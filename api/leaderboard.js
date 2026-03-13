const CORS_HEADERS = {
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type',
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

function clampLimit(rawLimit) {
  const parsed = Number(rawLimit);
  if (!Number.isFinite(parsed)) {
    return 10;
  }
  const value = Math.floor(parsed);
  if (value < 1) {
    return 1;
  }
  if (value > 50) {
    return 50;
  }
  return value;
}

function parseMember(member) {
  const fallback = {
    name: 'Anonymous',
    seed: null,
  };
  if (typeof member !== 'string' || member.length == 0) {
    return fallback;
  }

  if (member.startsWith('{')) {
    try {
      const parsed = JSON.parse(member);
      const parsedName =
        typeof parsed?.n === 'string' && parsed.n.trim().length > 0
          ? parsed.n.trim()
          : 'Anonymous';
      const parsedSeed =
        typeof parsed?.s === 'string' && /^[A-Z0-9]{5}$/.test(parsed.s)
          ? parsed.s
          : null;
      return {
        name: parsedName,
        seed: parsedSeed,
      };
    } catch {}
  }

  const separatorIndex = member.indexOf(':');
  if (separatorIndex > -1 && separatorIndex < member.length - 1) {
    return {
      name: member.slice(separatorIndex + 1).trim() || 'Anonymous',
      seed: null,
    };
  }

  return {
    name: member.trim() || 'Anonymous',
    seed: null,
  };
}

export default async function handler(request) {
  const allowedOrigin = process.env.LEADERBOARD_ALLOWED_ORIGIN || '*';
  const corsHeaders = {
    ...CORS_HEADERS,
    'Access-Control-Allow-Origin': allowedOrigin,
    'Cache-Control': 'public, s-maxage=15, stale-while-revalidate=45',
    Vary: 'Origin',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== 'GET') {
    return jsonResponse(405, { error: 'method_not_allowed' }, corsHeaders);
  }

  const kvUrl = process.env.KV_REST_API_URL;
  const kvToken = process.env.KV_REST_API_TOKEN;
  if (!kvUrl || !kvToken) {
    return jsonResponse(500, { error: 'kv_not_configured' }, corsHeaders);
  }

  try {
    const url = new URL(request.url);
    const limit = clampLimit(url.searchParams.get('limit'));
    const rows = await kvCommand(kvUrl, kvToken, [
      'zrange',
      'leaderboard:times',
      0,
      limit - 1,
      'withscores',
    ]);

    const entries = [];
    for (let index = 0; index < rows.length; index += 2) {
      const member = rows[index];
      const scoreRaw = rows[index + 1];
      const timeMs = Number(scoreRaw);
      if (!Number.isFinite(timeMs) || timeMs <= 0) {
        continue;
      }

      const parsedMember = parseMember(member);
      entries.push({
        rank: entries.length + 1,
        name: parsedMember.name,
        seed: parsedMember.seed,
        timeMs,
      });
    }

    return jsonResponse(200, { entries }, corsHeaders);
  } catch (error) {
    return jsonResponse(500, { error: 'internal_error' }, corsHeaders);
  }
}
