function applyCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Accept',
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

function validEmail(value) {
  return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

async function handler(req, res) {
  applyCors(res);
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }
  if (req.method !== 'POST') {
    res.statusCode = 405;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end('{"error":"method"}');
    return;
  }
  const key = process.env.RESEND_API_KEY;
  if (!key) {
    res.statusCode = 503;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end('{"error":"mail"}');
    return;
  }
  try {
    const raw = await readBody(req);
    const body = JSON.parse(raw);
    const to = typeof body.to === 'string' ? body.to.trim() : '';
    const subject = typeof body.subject === 'string' ? body.subject.trim() : '';
    const text = typeof body.text === 'string' ? body.text : '';
    if (!validEmail(to) || subject.length < 1 || subject.length > 120 || text.length < 1 || text.length > 2000) {
      res.statusCode = 400;
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.end('{"error":"payload"}');
      return;
    }
    const from = process.env.MAIL_FROM || 'رابط <onboarding@resend.dev>';
    const upstream = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from, to: [to], subject, text }),
    });
    res.statusCode = upstream.ok ? 200 : upstream.status;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end(upstream.ok ? '{"ok":true}' : '{"error":"upstream"}');
  } catch (_) {
    res.statusCode = 502;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end('{"error":"upstream"}');
  }
}

module.exports = handler;
