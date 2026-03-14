/**
 * api/serve.js — Proxy ดึงไฟล์จาก GitHub private repo
 * เรียกผ่าน: GET /api/serve?path=uploads/filename.png
 */

const https = require('https');

module.exports = async function handler(req, res) {
  try {
    const GITHUB_TOKEN  = process.env.GITHUB_TOKEN  || '';
    const GITHUB_OWNER  = process.env.GITHUB_OWNER  || '';
    const GITHUB_REPO   = process.env.GITHUB_REPO   || '';
    const GITHUB_BRANCH = process.env.GITHUB_BRANCH || 'main';

    if (!GITHUB_TOKEN || !GITHUB_OWNER || !GITHUB_REPO) {
      res.status(500).end('Server misconfigured: missing env vars');
      return;
    }

    var filePath = (req.query.path || '').replace(/\.\./g, '').replace(/^\/+/, '');
    if (!filePath) {
      res.status(400).end('Missing path');
      return;
    }

    // ใช้ raw.githubusercontent.com โดยตรง — ง่ายและเร็วกว่า Contents API
    var rawUrl = 'https://raw.githubusercontent.com/' +
      GITHUB_OWNER + '/' + GITHUB_REPO + '/' + GITHUB_BRANCH + '/' + filePath;

    var ghRes = await fetch(rawUrl, {
      headers: {
        'Authorization': 'Bearer ' + GITHUB_TOKEN,
        'User-Agent': 'PixVault/1.0',
      },
    });

    if (!ghRes.ok) {
      if (ghRes.status === 404) { res.status(404).end('File not found'); return; }
      if (ghRes.status === 401 || ghRes.status === 403) { res.status(403).end('Access denied'); return; }
      res.status(ghRes.status).end('GitHub error ' + ghRes.status);
      return;
    }

    // Content-Type จากนามสกุล
    var ext = filePath.split('.').pop().toLowerCase();
    var mimeMap = {
      'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png',
      'gif':'image/gif','webp':'image/webp','svg':'image/svg+xml',
      'mp4':'video/mp4','mov':'video/quicktime','webm':'video/webm',
      'avi':'video/x-msvideo','mkv':'video/x-matroska',
      'pdf':'application/pdf',
    };
    var ct = mimeMap[ext] || 'application/octet-stream';

    res.setHeader('Content-Type', ct);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');

    var buf = Buffer.from(await ghRes.arrayBuffer());
    res.setHeader('Content-Length', buf.length);
    res.status(200).end(buf);

  } catch (err) {
    res.status(500).end('Error: ' + (err.message || 'unknown'));
  }
};
