var crypto = require('crypto');
var path   = require('path');

var MAX_CHUNKS = 16;

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST')    { res.status(405).json({ error: 'Method not allowed' }); return; }

  var GITHUB_TOKEN  = process.env.GITHUB_TOKEN  || '';
  var GITHUB_OWNER  = process.env.GITHUB_OWNER  || '';
  var GITHUB_REPO   = process.env.GITHUB_REPO   || '';
  var GITHUB_BRANCH = process.env.GITHUB_BRANCH || 'main';

  var missing = [];
  if (!GITHUB_TOKEN) missing.push('GITHUB_TOKEN');
  if (!GITHUB_OWNER) missing.push('GITHUB_OWNER');
  if (!GITHUB_REPO)  missing.push('GITHUB_REPO');
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

  var base    = 'https://api.github.com/repos/' + GITHUB_OWNER + '/' + GITHUB_REPO + '/contents/';
  var baseHdr = { 'Authorization': 'Bearer ' + GITHUB_TOKEN, 'X-GitHub-Api-Version': '2022-11-28' };
  var jsonHdr = Object.assign({ 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json' }, baseHdr);

  function ghError(status, e) {
    var msg = (e && e.message) || ('GitHub ' + status);
    if (status === 401) msg = 'GITHUB_TOKEN ไม่ถูกต้องหรือหมดอายุ';
    if (status === 403) msg = 'GITHUB_TOKEN ไม่มีสิทธิ์ — ต้อง scope: repo';
    if (status === 404) msg = 'ไม่พบ repo — ตรวจสอบ GITHUB_OWNER / GITHUB_REPO';
    if (status === 422) msg = 'ชื่อไฟล์ซ้ำหรือ branch ไม่มีอยู่';
    return msg;
  }

  var action = data.action || 'single';

  if (action === 'chunk') {
    var cid = String(data.id || '');
    var idx = parseInt(data.index, 10);
    if (!/^[a-zA-Z0-9]{8,40}$/.test(cid) || !(idx >= 0 && idx < MAX_CHUNKS) || !data.file) {
      res.status(400).json({ error: 'chunk ไม่ถูกต้อง' }); return;
    }
    var chunkPath = '_chunks/' + cid + '/' + ('00' + idx).slice(-2) + '.part';
    var cr;
    try {
      cr = await fetch(base + chunkPath, {
        method: 'PUT', headers: jsonHdr,
        body: JSON.stringify({ message: 'chunk ' + cid + ' #' + idx, content: data.file, branch: GITHUB_BRANCH }),
      });
    } catch(err) { res.status(502).json({ error: 'เชื่อมต่อ GitHub ไม่ได้: ' + err.message }); return; }
    if (!cr.ok) {
      var ce = await cr.json().catch(function(){ return {}; });
      res.status(502).json({ error: ghError(cr.status, ce) }); return;
    }
    res.status(200).json({ success: true, path: chunkPath });
    return;
  }

  var fileName = data.name   || 'upload';
  var fileType = data.type   || 'application/octet-stream';
  var expiry   = data.expiry || '';
  var folder   = (data.folder || 'uploads').replace(/\.\./g, '').replace(/^\/+|\/+$/g, '') || 'uploads';
  var fileBase64 = '';

  if (action === 'finish') {
    var fid   = String(data.id || '');
    var total = parseInt(data.total, 10);
    if (!/^[a-zA-Z0-9]{8,40}$/.test(fid) || !(total >= 1 && total <= MAX_CHUNKS)) {
      res.status(400).json({ error: 'finish ไม่ถูกต้อง' }); return;
    }
    var parts = new Array(total);
    try {
      for (var s = 0; s < total; s += 4) {
        var batch = [];
        for (var i = s; i < Math.min(s + 4, total); i++) {
          (function(n) {
            batch.push(
              fetch(base + '_chunks/' + fid + '/' + ('00' + n).slice(-2) + '.part?ref=' + encodeURIComponent(GITHUB_BRANCH), {
                headers: Object.assign({ 'Accept': 'application/vnd.github.raw+json' }, baseHdr),
              }).then(function(r) {
                if (!r.ok) throw new Error('อ่าน chunk ' + n + ' ไม่ได้ (' + r.status + ')');
                return r.arrayBuffer();
              }).then(function(ab) { parts[n] = Buffer.from(ab); })
            );
          })(i);
        }
        await Promise.all(batch);
      }
    } catch(err) { res.status(502).json({ error: err.message }); return; }
    fileBase64 = Buffer.concat(parts).toString('base64');
    parts = null;
  } else {
    fileBase64 = data.file || '';
  }

  if (!fileBase64) { res.status(400).json({ error: 'ไม่พบข้อมูลไฟล์' }); return; }

  var ext      = path.extname(fileName).toLowerCase();
  var baseName = path.basename(fileName, ext)
    .replace(/[^a-zA-Z0-9ก-๙._\-() ]/g, '_')
    .replace(/\s+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .substring(0, 150) || 'file';
  var suffix   = crypto.randomBytes(3).toString('hex');
  var repoPath = folder + '/' + baseName + '_' + suffix + ext;
  var apiUrl   = base + repoPath;

  var sha;
  try {
    var chk = await fetch(apiUrl, { headers: Object.assign({ 'Accept': 'application/vnd.github+json' }, baseHdr) });
    if (chk.ok) sha = (await chk.json()).sha;
  } catch(_) {}

  var putBody = { message: 'Upload ' + fileName, content: fileBase64, branch: GITHUB_BRANCH };
  if (sha) putBody.sha = sha;

  var ghRes;
  try {
    ghRes = await fetch(apiUrl, { method: 'PUT', headers: jsonHdr, body: JSON.stringify(putBody) });
  } catch(err) {
    res.status(502).json({ error: 'เชื่อมต่อ GitHub ไม่ได้: ' + err.message }); return;
  }

  if (!ghRes.ok) {
    var e = await ghRes.json().catch(function(){ return {}; });
    res.status(502).json({ error: ghError(ghRes.status, e) }); return;
  }

  var expiryMs = parseExpiry(expiry);
  if (expiryMs) {
    var metaContent = Buffer.from(JSON.stringify({
      original_name: fileName, repo_path: repoPath,
      uploaded_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + expiryMs).toISOString()
    })).toString('base64');
    try {
      await fetch(base + repoPath + '.meta.json', {
        method: 'PUT', headers: jsonHdr,
        body: JSON.stringify({ message: 'Meta: ' + fileName, content: metaContent, branch: GITHUB_BRANCH }),
      });
    } catch(_) {}
  }

  var host   = req.headers['x-forwarded-host'] || req.headers['host'] || '';
  var proto  = req.headers['x-forwarded-proto'] || 'https';
  var serveUrl = (host ? proto + '://' + host : '') + '/' + repoPath;

  res.status(200).json({
    success: true,
    url: serveUrl,
    raw_url: 'https://raw.githubusercontent.com/' + GITHUB_OWNER + '/' + GITHUB_REPO + '/' + GITHUB_BRANCH + '/' + repoPath,
    path: repoPath,
    name: fileName,
    mime: fileType,
    expires_at: expiryMs ? new Date(Date.now() + expiryMs).toISOString() : null,
  });
};

function parseExpiry(e) {
  var map = {'1h':3600000,'3h':10800000,'6h':21600000,'12h':43200000,'1d':86400000,'2d':172800000,'3d':259200000,'4d':345600000,'5d':432000000,'6d':518400000,'1w':604800000,'2w':1209600000,'3w':1814400000,'1mo':2592000000,'2mo':5184000000,'3mo':7776000000,'4mo':10368000000,'5mo':12960000000,'6mo':15552000000,'1y':31536000000};
  return map[e] || null;
}
