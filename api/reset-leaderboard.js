export const config = {
  runtime: 'edge',
};

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
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

async function collectKeys(kvUrl, kvToken, pattern) {
  let cursor = '0';
  const found = [];

  do {
    const result = await kvCommand(kvUrl, kvToken, [
      'scan',
      cursor,
      'match',
      pattern,
      'count',
      '1000',
    ]);
    if (!Array.isArray(result) || result.length < 2) {
      break;
    }

    const nextCursor = String(result[0]);
    const keys = Array.isArray(result[1]) ? result[1] : [];
    for (const key of keys) {
      if (typeof key === 'string' && key.length > 0) {
        found.push(key);
      }
    }
    cursor = nextCursor;
  } while (cursor !== '0');

  return found;
}

async function deleteKeys(kvUrl, kvToken, keys) {
  if (keys.length === 0) {
    return 0;
  }

  let deleted = 0;
  const chunkSize = 128;
  for (let index = 0; index < keys.length; index += chunkSize) {
    const chunk = keys.slice(index, index + chunkSize);
    await kvCommand(kvUrl, kvToken, ['del', ...chunk]);
    deleted += chunk.length;
  }

  return deleted;
}

export default async function handler(request) {
  if (request.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' });
  }

  const adminKey = process.env.LEADERBOARD_ADMIN_KEY || '';
  const submittedAdminKey = request.headers.get('x-leaderboard-admin-key') || '';
  if (!adminKey || submittedAdminKey !== adminKey) {
    return jsonResponse(401, { error: 'unauthorized' });
  }

  const kvUrl = process.env.KV_REST_API_URL;
  const kvToken = process.env.KV_REST_API_TOKEN;
  if (!kvUrl || !kvToken) {
    return jsonResponse(500, { error: 'kv_not_configured' });
  }

  try {
    await kvCommand(kvUrl, kvToken, ['del', 'leaderboard:times']);

    const [bestKeys, dedupeKeys] = await Promise.all([
      collectKeys(kvUrl, kvToken, 'leaderboard:best:*'),
      collectKeys(kvUrl, kvToken, 'leaderboard:dedupe:*'),
    ]);

    const deletedBest = await deleteKeys(kvUrl, kvToken, bestKeys);
    const deletedDedupe = await deleteKeys(kvUrl, kvToken, dedupeKeys);

    return jsonResponse(200, {
      ok: true,
      deletedBest,
      deletedDedupe,
    });
  } catch (error) {
    return jsonResponse(500, { error: 'reset_failed' });
  }
}
