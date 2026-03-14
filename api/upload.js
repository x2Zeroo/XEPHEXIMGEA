/**
 * api/upload.js  —  Vercel Serverless Function (CommonJS)
 */

const formidable = require("formidable");
const fs         = require("fs");
const path       = require("path");
const crypto     = require("crypto");

module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST")
    return res.status(405).json({ error: "Method not allowed" });

  const GITHUB_TOKEN  = process.env.GITHUB_TOKEN;
  const GITHUB_OWNER  = process.env.GITHUB_OWNER;
  const GITHUB_REPO   = process.env.GITHUB_REPO;
  const GITHUB_BRANCH = process.env.GITHUB_BRANCH || "main";

  const missing = [];
  if (!GITHUB_TOKEN) missing.push("GITHUB_TOKEN");
  if (!GITHUB_OWNER) missing.push("GITHUB_OWNER");
  if (!GITHUB_REPO)  missing.push("GITHUB_REPO");
  if (missing.length) {
    return res.status(500).json({
      error: `ยังไม่ได้ตั้งค่า: ${missing.join(", ")} — ไปตั้งใน Vercel Dashboard > Settings > Environment Variables แล้ว Redeploy`,
    });
  }

  const form = formidable({ maxFileSize: 100 * 1024 * 1024, keepExtensions: true });
  let fields, files;
  try {
    [fields, files] = await form.parse(req);
  } catch (err) {
    return res.status(400).json({ error: "อ่านไฟล์ไม่ได้: " + err.message });
  }

  const fileArr = files.file;
  if (!fileArr || !fileArr.length)
    return res.status(400).json({ error: "ไม่พบไฟล์ — กรุณาแนบไฟล์มาด้วย" });

  const file         = fileArr[0];
  const expiry       = (fields.expiry?.[0]  || "").trim();
  const folder       = (fields.folder?.[0]  || "uploads").trim() || "uploads";
  const originalName = file.originalFilename || "upload";
  const mimeType     = file.mimetype || "application/octet-stream";

  let fileBuffer;
  try {
    fileBuffer = fs.readFileSync(file.filepath);
  } catch (err) {
    return res.status(500).json({ error: "อ่านไฟล์ temp ไม่ได้: " + err.message });
  }

  const ext      = path.extname(originalName).toLowerCase();
  const uid      = crypto.randomBytes(6).toString("hex");
  const ts       = new Date().toISOString().slice(0, 10);
  const repoPath = `${folder.replace(/^\/|\/$/g, "")}/${ts}_${uid}${ext}`;
  const apiUrl   = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${repoPath}`;
  const b64      = fileBuffer.toString("base64");

  let sha;
  try {
    const check = await fetch(apiUrl, {
      headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28" },
    });
    if (check.ok) sha = (await check.json()).sha;
  } catch (_) {}

  const body = { message: `Upload ${originalName}`, content: b64, branch: GITHUB_BRANCH };
  if (sha) body.sha = sha;

  let ghRes;
  try {
    ghRes = await fetch(apiUrl, {
      method: "PUT",
      headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28", "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  } catch (err) {
    return res.status(502).json({ error: "เชื่อมต่อ GitHub ไม่ได้: " + err.message });
  }

  if (!ghRes.ok) {
    const errBody = await ghRes.json().catch(() => ({}));
    let msg = errBody.message || `GitHub API ${ghRes.status}`;
    if (ghRes.status === 401) msg = "GITHUB_TOKEN ไม่ถูกต้องหรือหมดอายุ — ตรวจสอบ token";
    if (ghRes.status === 403) msg = "GITHUB_TOKEN ไม่มีสิทธิ์ — ต้องเปิด scope: repo";
    if (ghRes.status === 404) msg = "ไม่พบ repo — ตรวจสอบ GITHUB_OWNER และ GITHUB_REPO";
    if (ghRes.status === 422) msg = "ชื่อไฟล์ซ้ำหรือ branch ไม่มีอยู่";
    return res.status(502).json({ error: msg });
  }

  const ghData   = await ghRes.json();
  const expiryMs = parseExpiry(expiry);
  if (expiryMs) {
    const metaPath = repoPath + ".meta.json";
    const metaBuf  = Buffer.from(JSON.stringify({ original_name: originalName, repo_path: repoPath, uploaded_at: new Date().toISOString(), expires_at: new Date(Date.now() + expiryMs).toISOString() }, null, 2));
    fetch(`https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${metaPath}`, {
      method: "PUT",
      headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28", "Content-Type": "application/json" },
      body: JSON.stringify({ message: `Meta: ${originalName}`, content: metaBuf.toString("base64"), branch: GITHUB_BRANCH }),
    }).catch(() => {});
  }

  try { fs.unlinkSync(file.filepath); } catch (_) {}

  // สร้าง URL ของเว็บเอง (proxy ผ่าน /uploads/...)
  const host = req.headers['x-forwarded-host'] || req.headers.host || '';
  const proto = req.headers['x-forwarded-proto'] || 'https';
  const baseUrl = host ? (proto + '://' + host) : '';
  const serveUrl = baseUrl + '/' + repoPath;
  const rawUrl = "https://raw.githubusercontent.com/" + GITHUB_OWNER + "/" + GITHUB_REPO + "/" + GITHUB_BRANCH + "/" + repoPath;

  return res.status(200).json({
    success: true,
    url: serveUrl,
    raw_url: rawUrl,
    path: repoPath,
    name: originalName,
    size: fileBuffer.length,
    mime: mimeType,
    expires_at: expiryMs ? new Date(Date.now() + expiryMs).toISOString() : null,
  });
};

function parseExpiry(e) {
  const map = {"1h":3600000,"3h":10800000,"6h":21600000,"12h":43200000,"1d":86400000,"2d":172800000,"3d":259200000,"4d":345600000,"5d":432000000,"6d":518400000,"1w":604800000,"2w":1209600000,"3w":1814400000,"1mo":2592000000,"2mo":5184000000,"3mo":7776000000,"4mo":10368000000,"5mo":12960000000,"6mo":15552000000,"1y":31536000000};
  return map[e] || null;
}
