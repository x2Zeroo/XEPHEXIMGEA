module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST' && req.method !== 'DELETE') {
    res.status(405).json({ error: 'Method not allowed' }); return;
  }

  var SUPABASE_URL         = process.env.SUPABASE_URL || '';
  var SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || '';
  var SUPABASE_BUCKET      = process.env.SUPABASE_BUCKET || 'cloudzone';

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    res.status(500).json({ error: 'Server misconfigured' }); return;
  }

  var body = await new Promise(function(resolve, reject) {
    var chunks = [];
    req.on('data', function(c) { chunks.push(c); });
    req.on('end', function() { resolve(Buffer.concat(chunks).toString('utf8')); });
    req.on('error', reject);
  });

  var data;
  try { data = JSON.parse(body); } catch(e) {
    res.status(400).json({ error: 'Invalid JSON: ' + e.message }); return;
  }

  var filePath = (data.path || '').replace(/\.\./g, '').replace(/^\/+/, '');
  if (!filePath) { res.status(400).json({ error: 'Missing path' }); return; }

  var base = SUPABASE_URL.replace(/\/+$/, '');
  var headers = {
    'Authorization': 'Bearer ' + SUPABASE_SERVICE_KEY,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  try {
    var delRes = await fetch(base + '/storage/v1/object/' + SUPABASE_BUCKET, {
      method: 'DELETE',
      headers: headers,
      body: JSON.stringify({ prefixes: [filePath] }),
    });
    if (!delRes.ok) {
      var e = await delRes.json().catch(function() { return {}; });
      res.status(502).json({ error: e.message || 'Delete error ' + delRes.status }); return;
    }
  } catch(err) {
    res.status(502).json({ error: 'เชื่อมต่อไม่ได้: ' + err.message }); return;
  }

  try {
    await fetch(base + '/storage/v1/object/' + SUPABASE_BUCKET, {
      method: 'DELETE',
      headers: headers,
      body: JSON.stringify({ prefixes: [filePath + '.meta.json'] }),
    });
  } catch(_) {}

  res.status(200).json({ success: true, deleted: filePath });
};
