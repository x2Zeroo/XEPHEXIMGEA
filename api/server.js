/**
 * api/serve.js — Proxy ดึงไฟล์จาก GitHub private repo แล้วส่งกลับ
 * 
 * เรียกผ่าน rewrite: /uploads/* → /api/serve?path=uploads/*
 */

module.exports = async function handler(req, res) {
  const GITHUB_TOKEN  = process.env.GITHUB_TOKEN;
  const GITHUB_OWNER  = process.env.GITHUB_OWNER;
  const GITHUB_REPO   = process.env.GITHUB_REPO;
  const GITHUB_BRANCH = process.env.GITHUB_BRANCH || 'main';

  if (!GITHUB_TOKEN || !GITHUB_OWNER || !GITHUB_REPO) {
    return res.status(500).send('Server misconfigured');
  }

  // path มาจาก rewrite query เช่น "uploads/2026-03-14_abc123.png"
  const filePath = req.query.path;
  if (!filePath) return res.status(400).send('Missing path');

  // ป้องกัน path traversal
  const safePath = filePath.replace(/\.\./g, '').replace(/^\/+/, '');

  // ดึงไฟล์จาก GitHub Contents API (base64)
  const apiUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${safePath}?ref=${GITHUB_BRANCH}`;

  let ghRes;
  try {
    ghRes = await fetch(apiUrl, {
      headers: {
        Authorization: `Bearer ${GITHUB_TOKEN}`,
        Accept: 'application/vnd.github.raw+json', // ขอ raw bytes โดยตรง
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'PixVault/1.0',
      },
    });
  } catch (err) {
    return res.status(502).send('Cannot reach GitHub: ' + err.message);
  }

  if (!ghRes.ok) {
    if (ghRes.status === 404) return res.status(404).send('File not found');
    if (ghRes.status === 403) return res.status(403).send('Access denied');
    return res.status(ghRes.status).send('GitHub error ' + ghRes.status);
  }

  // กำหนด Content-Type จากนามสกุลไฟล์
  const ext = safePath.split('.').pop().toLowerCase();
  const mimeMap = {
    jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png',
    gif: 'image/gif',  webp: 'image/webp', svg: 'image/svg+xml',
    mp4: 'video/mp4',  mov: 'video/quicktime', webm: 'video/webm',
    avi: 'video/x-msvideo', mkv: 'video/x-matroska',
    pdf: 'application/pdf',
  };
  const contentType = mimeMap[ext] || 'application/octet-stream';

  // Cache 1 วัน
  res.setHeader('Content-Type', contentType);
  res.setHeader('Cache-Control', 'public, max-age=86400');
  res.setHeader('X-Content-Type-Options', 'nosniff');

  // Stream body กลับ
  const arrayBuffer = await ghRes.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  res.setHeader('Content-Length', buffer.length);
  return res.status(200).send(buffer);
};
