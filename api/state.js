const binUrl = 'https://extendsclass.com/api/json-storage/bin/fdbdfcd';

function applyCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Accept, Cache-Control',
  );
  res.setHeader('Cache-Control', 'no-store');
}

function readBody(req) {
  if (req.body != null && req.body !== '') {
    if (typeof req.body === 'string') return Promise.resolve(req.body);
    if (Buffer.isBuffer(req.body)) return Promise.resolve(req.body.toString('utf8'));
    return Promise.resolve(JSON.stringify(req.body));
  }
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

async function handler(req, res) {
  applyCors(res);
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }
  try {
    if (req.method === 'GET') {
      const upstream = await fetch(`${binUrl}?t=${Date.now()}`, {
        headers: { Accept: 'application/json', 'Cache-Control': 'no-cache' },
      });
      const text = await upstream.text();
      res.statusCode = upstream.status;
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.end(text);
      return;
    }
    if (req.method === 'PUT') {
      const body = await readBody(req);
      if (body.length > 1_000_000) {
        res.statusCode = 413;
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
        res.end('{"error":"payload"}');
        return;
      }
      const upstream = await fetch(binUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body,
      });
      const text = await upstream.text();
      res.statusCode = upstream.status;
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.end(text);
      return;
    }
    res.statusCode = 405;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end('{"error":"method"}');
  } catch (error) {
    res.statusCode = 502;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end('{"error":"upstream"}');
  }
}

module.exports = handler;

if (process.env.SERVICK_PROXY_PORT) {
  const http = require('http');
  const port = Number(process.env.SERVICK_PROXY_PORT);
  http.createServer(handler).listen(port, '127.0.0.1');
}
