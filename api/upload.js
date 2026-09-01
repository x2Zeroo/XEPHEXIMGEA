module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST')    { res.status(405).json({ error: 'Method not allowed' }); return; }

  var SUPABASE_URL         = process.env.SUPABASE_URL || '';
  var SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || '';
  var SUPABASE_BUCKET      = process.env.SUPABASE_BUCKET || 'cloudzone';

  var missing = [];
  if (!SUPABASE_URL) missing.push('SUPABASE_URL');
  if (!SUPABASE_SERVICE_KEY) missing.push('SUPABASE_SERVICE_KEY');
  if (missing.length) {
    res.status(500).json({ error: 'ยังไม่ได้ตั้งค่า: ' + missing.join(', ') + ' — ไปตั้งใน Vercel Dashboard > Settings > Environment Variables แล้ว Redeploy' });
    return;
  }

  var body = await new Promise(function(resolve, reject) {
    var chunks = [];
    req.on('data', function(c) { chunks.push(c); });
    req.on('end',  function()  { resolve(Buffer.concat(chunks).toString('utf8')); });
    req.on('error', reject);
  });

  var data;
  try { data = JSON.parse(body); }
  catch(e) { res.status(400).json({ error: 'JSON parse error: ' + e.message }); return; }

  var fileBase64 = data.file   || '';
  var fileName   = data.name   || 'upload';
  var fileType   = data.type   || 'application/octet-stream';
  var expiry     = data.expiry || '';
  var folder     = (data.folder || 'uploads').replace(/^\/+|\/+$/g, '') || 'uploads';

  if (!fileBase64) { res.status(400).json({ error: 'ไม่พบข้อมูลไฟล์' }); return; }

  var crypto = require('crypto');
  var path   = require('path');
  var ext      = path.extname(fileName).toLowerCase();
  var baseName = path.basename(fileName, ext)
    .replace(/[^a-zA-Z0-9ก-๙._\-() ]/g, '_')
    .replace(/\s+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .substring(0, 150) || 'file';
  var suffix   = crypto.randomBytes(3).toString('hex');
  var storagePath = folder + '/' + baseName + '_' + suffix + ext;

  var fileBuffer = Buffer.from(fileBase64, 'base64');
  var uploadUrl = SUPABASE_URL.replace(/\/+$/, '') + '/storage/v1/object/' + SUPABASE_BUCKET + '/' + storagePath;

  var upRes;
  try {
    upRes = await fetch(uploadUrl, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + SUPABASE_SERVICE_KEY,
        'apikey': SUPABASE_SERVICE_KEY,
        'Content-Type': fileType,
        'x-upsert': 'true',
      },
      body: fileBuffer,
    });
  } catch(err) {
    res.status(502).json({ error: 'เชื่อมต่อ Supabase ไม่ได้: ' + err.message }); return;
  }

  if (!upRes.ok) {
    var e = await upRes.json().catch(function(){ return {}; });
    var msg = e.message || ('Supabase ' + upRes.status);
    if (upRes.status === 401 || upRes.status === 403) msg = 'SUPABASE_SERVICE_KEY ไม่ถูกต้องหรือไม่มีสิทธิ์';
    if (upRes.status === 404) msg = 'ไม่พบ bucket "' + SUPABASE_BUCKET + '" — สร้าง bucket ใน Supabase ก่อน';
    res.status(502).json({ error: msg }); return;
  }

  var expiryMs = parseExpiry(expiry);
  var expiresAt = expiryMs ? new Date(Date.now() + expiryMs).toISOString() : null;

  if (expiryMs) {
    var metaPath = storagePath + '.meta.json';
    var metaBuffer = Buffer.from(JSON.stringify({
      original_name: fileName, storage_path: storagePath,
      uploaded_at: new Date().toISOString(),
      expires_at: expiresAt,
    }));
    fetch(SUPABASE_URL.replace(/\/+$/, '') + '/storage/v1/object/' + SUPABASE_BUCKET + '/' + metaPath, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + SUPABASE_SERVICE_KEY,
        'apikey': SUPABASE_SERVICE_KEY,
        'Content-Type': 'application/json',
        'x-upsert': 'true',
      },
      body: metaBuffer,
    }).catch(function(){});
  }

  var host   = req.headers['x-forwarded-host'] || req.headers['host'] || '';
  var proto  = req.headers['x-forwarded-proto'] || 'https';
  var serveUrl = (host ? proto + '://' + host : '') + '/' + storagePath;
  var rawUrl = SUPABASE_URL.replace(/\/+$/, '') + '/storage/v1/object/public/' + SUPABASE_BUCKET + '/' + storagePath;

  res.status(200).json({
    success: true,
    url: serveUrl,
    raw_url: rawUrl,
    path: storagePath,
    name: fileName,
    mime: fileType,
    expires_at: expiresAt,
  });
};

function parseExpiry(e) {
  var map = {'1h':3600000,'3h':10800000,'6h':21600000,'12h':43200000,'1d':86400000,'2d':172800000,'3d':259200000,'4d':345600000,'5d':432000000,'6d':518400000,'1w':604800000,'2w':1209600000,'3w':1814400000,'1mo':2592000000,'2mo':5184000000,'3mo':7776000000,'4mo':10368000000,'5mo':12960000000,'6mo':15552000000,'1y':31536000000};
  return map[e] || null;
}
