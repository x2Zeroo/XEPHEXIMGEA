/**
 * api/upload.js — รับ JSON { file: base64, name, type, resize, expiry, folder }
 * ไม่ต้องใช้ external package เลย
 */

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST')    { res.status(405).json({ error: 'Method not allowed' }); return; }

  // ── Env check ──────────────────────────────────────────────
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

  // ── อ่าน body (JSON) ───────────────────────────────────────
  var body = await new Promise(function(resolve, reject) {
    var chunks = [];
    req.on('data', function(c) { chunks.push(c); });
    req.on('end',  function()  { resolve(Buffer.concat(chunks).toString('utf8')); });
    req.on('error', reject);
  });

  var data;
  try { data = JSON.parse(body); }
  catch(e) { res.status(400).json({ error: 'JSON parse error: ' + e.message }); return; }

  var fileBase64   = data.file   || '';
  var fileName     = data.name   || 'upload';
  var fileType     = data.type   || 'application/octet-stream';
  var expiry       = data.expiry || '';
  var folder       = (data.folder || 'uploads').replace(/^\/+|\/+$/g, '') || 'uploads';

  if (!fileBase64) { res.status(400).json({ error: 'ไม่พบข้อมูลไฟล์' }); return; }

  // ── สร้างชื่อไฟล์ unique ───────────────────────────────────
  var crypto = require('crypto');
  var path   = require('path');
  var ext    = path.extname(fileName).toLowerCase();
  var uid    = crypto.randomBytes(6).toString('hex');
  var ts     = new Date().toISOString().slice(0, 10);
  var repoPath = folder + '/' + ts + '_' + uid + ext;

  // ── Upload ขึ้น GitHub ─────────────────────────────────────
  var apiUrl = 'https://api.github.com/repos/' + GITHUB_OWNER + '/' + GITHUB_REPO + '/contents/' + repoPath;

  // check SHA (กรณีไฟล์ซ้ำ)
  var sha;
  try {
    var chk = await fetch(apiUrl, {
      headers: { 'Authorization': 'Bearer ' + GITHUB_TOKEN, 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28' }
    });
    if (chk.ok) sha = (await chk.json()).sha;
  } catch(_) {}

  var putBody = { message: 'Upload ' + fileName, content: fileBase64, branch: GITHUB_BRANCH };
  if (sha) putBody.sha = sha;

  var ghRes;
  try {
    ghRes = await fetch(apiUrl, {
      method: 'PUT',
      headers: { 'Authorization': 'Bearer ' + GITHUB_TOKEN, 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json' },
      body: JSON.stringify(putBody),
    });
  } catch(err) {
    res.status(502).json({ error: 'เชื่อมต่อ GitHub ไม่ได้: ' + err.message }); return;
  }

  if (!ghRes.ok) {
    var e = await ghRes.json().catch(function(){ return {}; });
    var msg = e.message || ('GitHub ' + ghRes.status);
    if (ghRes.status === 401) msg = 'GITHUB_TOKEN ไม่ถูกต้องหรือหมดอายุ';
    if (ghRes.status === 403) msg = 'GITHUB_TOKEN ไม่มีสิทธิ์ — ต้อง scope: repo';
    if (ghRes.status === 404) msg = 'ไม่พบ repo — ตรวจสอบ GITHUB_OWNER / GITHUB_REPO';
    if (ghRes.status === 422) msg = 'ชื่อไฟล์ซ้ำหรือ branch ไม่มีอยู่';
    res.status(502).json({ error: msg }); return;
  }

  // ── Expiry metadata ────────────────────────────────────────
  var expiryMs = parseExpiry(expiry);
  if (expiryMs) {
    var metaPath = repoPath + '.meta.json';
    var metaContent = Buffer.from(JSON.stringify({
      original_name: fileName, repo_path: repoPath,
      uploaded_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + expiryMs).toISOString()
    })).toString('base64');
    fetch('https://api.github.com/repos/' + GITHUB_OWNER + '/' + GITHUB_REPO + '/contents/' + metaPath, {
      method: 'PUT',
      headers: { 'Authorization': 'Bearer ' + GITHUB_TOKEN, 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Meta: ' + fileName, content: metaContent, branch: GITHUB_BRANCH }),
    }).catch(function(){});
  }

  // ── Response ───────────────────────────────────────────────
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
