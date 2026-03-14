/**
 * api/upload.js  —  Vercel Serverless Function
 *
 * POST /api/upload  (multipart/form-data)
 *   file    — File blob (required)
 *   resize  — Target width px, e.g. "640" (optional, images only)
 *   expiry  — e.g. "1h", "3d", "1mo", "" = never (optional)
 *   folder  — Subfolder path in repo, e.g. "photos/2026" (optional)
 *
 * ENV vars required:
 *   GITHUB_TOKEN   — Personal Access Token (repo scope)
 *   GITHUB_OWNER   — GitHub username or org
 *   GITHUB_REPO    — Repository name
 *   GITHUB_BRANCH  — Branch (default: main)
 */

import formidable from "formidable";
import fs from "fs";
import path from "path";
import crypto from "crypto";

export const config = {
  api: {
    bodyParser: false, // required for multipart
  },
};

// ── Env ──────────────────────────────────────────────────────────
const GITHUB_TOKEN  = process.env.GITHUB_TOKEN;
const GITHUB_OWNER  = process.env.GITHUB_OWNER;
const GITHUB_REPO   = process.env.GITHUB_REPO;
const GITHUB_BRANCH = process.env.GITHUB_BRANCH || "main";

const GITHUB_API    = "https://api.github.com";
const RAW_BASE      = `https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}`;

// ── Parse expiry → ms ────────────────────────────────────────────
function parseExpiry(expiry) {
  if (!expiry) return null;
  const map = {
    "1h": 60 * 60 * 1000,
    "3h": 3 * 60 * 60 * 1000,
    "6h": 6 * 60 * 60 * 1000,
    "12h": 12 * 60 * 60 * 1000,
    "1d": 86400000,
    "2d": 2 * 86400000,
    "3d": 3 * 86400000,
    "4d": 4 * 86400000,
    "5d": 5 * 86400000,
    "6d": 6 * 86400000,
    "1w": 7 * 86400000,
    "2w": 14 * 86400000,
    "3w": 21 * 86400000,
    "1mo": 30 * 86400000,
    "2mo": 60 * 86400000,
    "3mo": 90 * 86400000,
    "4mo": 120 * 86400000,
    "5mo": 150 * 86400000,
    "6mo": 180 * 86400000,
    "1y": 365 * 86400000,
  };
  return map[expiry] || null;
}

// ── Build a unique file path in the repo ─────────────────────────
function buildRepoPath(originalName, folder) {
  const ext  = path.extname(originalName).toLowerCase();
  const uid  = crypto.randomBytes(6).toString("hex");
  const ts   = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const base = folder ? folder.replace(/^\/|\/$/g, "") : "uploads";
  return `${base}/${ts}_${uid}${ext}`;
}

// ── Upload file buffer to GitHub Contents API ────────────────────
async function uploadToGitHub(repoPath, fileBuffer, commitMsg) {
  const url = `${GITHUB_API}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${repoPath}`;
  const b64  = fileBuffer.toString("base64");

  // Check if file exists (to get its SHA for overwrite — unlikely with uid, but safe)
  let sha;
  try {
    const check = await fetch(url, {
      headers: {
        Authorization: `Bearer ${GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
    });
    if (check.ok) {
      const existing = await check.json();
      sha = existing.sha;
    }
  } catch (_) {}

  const body = {
    message: commitMsg || `Upload ${path.basename(repoPath)}`,
    content: b64,
    branch: GITHUB_BRANCH,
  };
  if (sha) body.sha = sha;

  const res = await fetch(url, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${GITHUB_TOKEN}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `GitHub API error ${res.status}`);
  }

  return await res.json();
}

// ── Save expiry metadata (as a JSON file next to the upload) ─────
async function saveMetadata(repoPath, metadata) {
  const metaPath = repoPath + ".meta.json";
  const buf = Buffer.from(JSON.stringify(metadata, null, 2), "utf-8");
  try {
    await uploadToGitHub(metaPath, buf, `Add metadata for ${path.basename(repoPath)}`);
  } catch (_) {
    // Non-fatal — metadata save failure shouldn't fail the whole upload
    console.warn("Failed to save metadata:", _.message);
  }
}

// ── Main handler ─────────────────────────────────────────────────
export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST")
    return res.status(405).json({ error: "Method not allowed" });

  // Env check
  if (!GITHUB_TOKEN || !GITHUB_OWNER || !GITHUB_REPO) {
    return res.status(500).json({
      error: "Server misconfigured: missing GITHUB_TOKEN, GITHUB_OWNER, or GITHUB_REPO",
    });
  }

  // Parse multipart
  const form = formidable({
    maxFileSize: 100 * 1024 * 1024, // 100 MB
    keepExtensions: true,
  });

  let fields, files;
  try {
    [fields, files] = await form.parse(req);
  } catch (err) {
    return res.status(400).json({ error: "Failed to parse form: " + err.message });
  }

  const fileArr = files.file;
  if (!fileArr || !fileArr.length) {
    return res.status(400).json({ error: "No file provided" });
  }

  const file     = fileArr[0];
  const resize   = (fields.resize?.[0] || "").trim();
  const expiry   = (fields.expiry?.[0] || "").trim();
  const folder   = (fields.folder?.[0] || "").trim();

  const originalName = file.originalFilename || "upload";
  const mimeType     = file.mimetype || "application/octet-stream";

  // Read file buffer
  let fileBuffer;
  try {
    fileBuffer = fs.readFileSync(file.filepath);
  } catch (err) {
    return res.status(500).json({ error: "Failed to read uploaded file" });
  }

  // Optional: basic client-side resize note (server-side resize needs sharp)
  // If you want server-side resize, install sharp and uncomment below:
  /*
  if (resize && mimeType.startsWith("image/") && mimeType !== "image/gif") {
    const sharp = (await import("sharp")).default;
    const targetW = parseInt(resize, 10);
    if (!isNaN(targetW) && targetW > 0) {
      fileBuffer = await sharp(fileBuffer)
        .resize({ width: targetW, withoutEnlargement: true })
        .toBuffer();
    }
  }
  */

  // Build repo path and upload
  const repoPath = buildRepoPath(originalName, folder || "uploads");

  let githubResponse;
  try {
    githubResponse = await uploadToGitHub(
      repoPath,
      fileBuffer,
      `📦 Upload: ${originalName}`
    );
  } catch (err) {
    return res.status(502).json({ error: "GitHub upload failed: " + err.message });
  }

  // Expiry metadata
  const expiryMs = parseExpiry(expiry);
  if (expiryMs) {
    const expiresAt = new Date(Date.now() + expiryMs).toISOString();
    await saveMetadata(repoPath, {
      original_name: originalName,
      mime_type: mimeType,
      repo_path: repoPath,
      uploaded_at: new Date().toISOString(),
      expires_at: expiresAt,
      expiry_setting: expiry,
    });
  }

  // Build URLs
  const rawUrl  = `${RAW_BASE}/${repoPath}`;
  const htmlUrl = githubResponse.content?.html_url || "";

  // Cleanup temp file
  try { fs.unlinkSync(file.filepath); } catch (_) {}

  return res.status(200).json({
    success:   true,
    url:       htmlUrl,
    raw_url:   rawUrl,
    path:      repoPath,
    name:      originalName,
    size:      fileBuffer.length,
    mime:      mimeType,
    expires_at: expiryMs ? new Date(Date.now() + expiryMs).toISOString() : null,
    github:    {
      sha:      githubResponse.content?.sha,
      html_url: htmlUrl,
      download_url: githubResponse.content?.download_url,
    },
  });
}
