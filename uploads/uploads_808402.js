// /api/uploads.js — Vercel Serverless Function
// ตัวกลางเดียวที่หน้าเว็บ (index.html) ใช้คุยกับ Supabase
// อนุญาตให้เรียกจาก "เว็บตัวเอง" เท่านั้น (เช็ค Origin) เรียกจากที่อื่นจะโดนบล็อก
//
// Environment Variables ที่ต้องตั้งใน Vercel:
//   SUPABASE_URL        = https://xxxx.supabase.co
//   SUPABASE_SECRET_KEY = secret API key (sb_secret_...) จาก Supabase > Project Settings > API Keys
//
// ตาราง: keyfree (key, hwid, status, expired, placeid)
// status: active | expired | banned

const SUPABASE_URL = process.env.SUPABASE_URL || "https://ciegrrvjocdcssklbjwo.supabase.co";
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;

const KEY_LIFETIME_MS = 24 * 60 * 60 * 1000;      // อายุคีย์ 24 ชั่วโมง
const DELETE_AFTER_MS = 3 * 24 * 60 * 60 * 1000;  // expired เกิน 3 วัน = ลบทิ้ง
const MAX_KEYS_PER_USER = 6;

// เผื่อมี domain อื่นของตัวเองเพิ่มในอนาคต ใส่เพิ่มตรงนี้ได้
const EXTRA_ALLOWED_ORIGINS = [
    "https://xephex.xyz",
    "https://www.xephex.xyz",
    "https://xephex.vercel.app"
];

async function sb(method, path, body, extraHeaders) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
        method,
        headers: {
            "Content-Type": "application/json",
            // ต้องส่งทั้ง apikey และ Authorization — ถ้าส่ง apikey อย่างเดียว
            // Supabase จะตอบ 401 ในหลายกรณี (ทั้ง sb_secret_... และ service_role JWT)
            "apikey": SUPABASE_SECRET_KEY,
            "Authorization": `Bearer ${SUPABASE_SECRET_KEY}`,
            ...(extraHeaders || {})
        },
        body: body ? JSON.stringify(body) : undefined
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`Supabase ${res.status}: ${text}`);
    return text ? JSON.parse(text) : null;
}

// host จริงของเว็บ — บน Vercel/proxy ต้องดู x-forwarded-host ก่อน ไม่งั้นเทียบ Origin ไม่ตรง
function requestHost(req) {
    const fwd = req.headers["x-forwarded-host"];
    if (fwd) return String(fwd).split(",")[0].trim();
    return req.headers.host || "";
}

// อนุญาตเฉพาะ request จากเว็บตัวเองเท่านั้น
function isAllowedOrigin(req) {
    const origin = req.headers.origin;
    if (!origin) return false;
    if (EXTRA_ALLOWED_ORIGINS.includes(origin)) return true;
    try {
        const originHost = new URL(origin).host;
        return originHost === requestHost(req);
    } catch {
        return false;
    }
}

// req.body บน Vercel บางทีมาเป็น string — parse ให้ชัวร์
function parseBody(req) {
    const b = req.body;
    if (!b) return {};
    if (typeof b === "object") return b;
    try { return JSON.parse(b); } catch { return {}; }
}

function nowISO() { return new Date().toISOString(); }

function genKey() {
    // ใช้ Web Crypto (มีใน Node 18+) — ไม่ต้อง require เพิ่ม กันปัญหา module system
    const bytes = new Uint8Array(16);
    if (globalThis.crypto && globalThis.crypto.getRandomValues) {
        globalThis.crypto.getRandomValues(bytes);
    } else {
        for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
    }
    let hex = "";
    for (let i = 0; i < bytes.length; i++) hex += bytes[i].toString(16).padStart(2, "0");
    return "FREE_" + hex;
}

// งานดูแลฐานข้อมูล — เรียกทุกครั้งที่มี request เข้ามา
// 1) คีย์ active ที่เลยเวลาหมดแล้ว → เปลี่ยน status เป็น expired ทันที
// 2) คีย์ expired ที่หมดเวลามาเกิน 3 วัน → ลบออกจากฐานข้อมูล
async function housekeeping() {
    const now = nowISO();
    const cutoff = new Date(Date.now() - DELETE_AFTER_MS).toISOString();
    await Promise.all([
        sb("PATCH", `keyfree?status=eq.active&expired=lt.${encodeURIComponent(now)}`,
            { status: "expired" }).catch(() => null),
        sb("DELETE", `keyfree?status=eq.expired&expired=lt.${encodeURIComponent(cutoff)}`)
            .catch(() => null)
    ]);
}

module.exports = async function handler(req, res) {
    // เกราะชั้นนอกสุด — ต่อให้โค้ดข้างใน crash ยังไง ก็ตอบเป็น JSON พร้อมสาเหตุเสมอ
    // (กันเคส 502 เปล่าๆ จาก Vercel ที่ไม่บอกอะไรเลย)
    try {
        await handleRequest(req, res);
    } catch (err) {
        console.error("uploads.js crashed:", err);
        try {
            res.status(500).json({ error: "Server crash", detail: String((err && err.message) || err) });
        } catch { /* ตอบไปแล้ว */ }
    }
};

async function handleRequest(req, res) {
    // ต้องเป็น Node 18+ ถึงจะมี fetch — ถ้าไม่มีให้บอกตรงๆ แทนที่จะ crash เงียบๆ
    if (typeof fetch !== "function") {
        res.status(500).json({ error: "Server misconfigured: Node runtime too old, need Node 18+ (set in Vercel Project Settings > Node.js Version)" });
        return;
    }

    const origin = req.headers.origin;
    if (origin && isAllowedOrigin(req)) {
        res.setHeader("Access-Control-Allow-Origin", origin);
    }
    res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    res.setHeader("Vary", "Origin");

    if (req.method === "OPTIONS") { res.status(204).end(); return; }
    if (req.method !== "POST") { res.status(405).json({ error: "Method not allowed" }); return; }

    // บล็อกทุก request ที่ไม่ได้มาจากเว็บตัวเอง
    if (!isAllowedOrigin(req)) {
        res.status(403).json({ error: "Forbidden" });
        return;
    }
    if (!SUPABASE_SECRET_KEY) {
        res.status(500).json({ error: "Server misconfigured: missing SUPABASE_SECRET_KEY" });
        return;
    }

    const body = parseBody(req);
    const action = String(body.action || "");

    try {
        await housekeeping();

        switch (action) {

            // ── ดึงสถานะล่าสุดของคีย์ที่หน้าเว็บถืออยู่ ─────────────────
            case "list": {
                const keys = Array.isArray(body.keys)
                    ? body.keys.filter(k => typeof k === "string" && /^[A-Za-z0-9_]{1,64}$/.test(k)).slice(0, 20)
                    : [];
                if (keys.length === 0) { res.status(200).json({ ok: true, rows: [] }); return; }
                const filter = keys.map(k => `"${k}"`).join(",");
                const rows = await sb("GET",
                    `keyfree?key=in.(${encodeURIComponent(filter)})&select=key,status,expired`);
                res.status(200).json({ ok: true, rows: rows || [] });
                return;
            }

            // ── สร้างคีย์ใหม่ ────────────────────────────────────────────
            case "create": {
                const owned = Array.isArray(body.keys)
                    ? body.keys.filter(k => typeof k === "string").slice(0, 20)
                    : [];
                if (owned.length >= MAX_KEYS_PER_USER) {
                    res.status(200).json({ ok: false, reason: "max_keys" });
                    return;
                }

                const key = genKey();
                const expired = new Date(Date.now() + KEY_LIFETIME_MS).toISOString();
                const created = await sb("POST", "keyfree", {
                    key,
                    hwid: "",
                    status: "active",
                    expired,
                    placeid: ""
                }, { "Prefer": "return=representation" });

                const row = created && created[0];
                if (!row) {
                    res.status(502).json({ error: "Database error", detail: "insert returned no row" });
                    return;
                }
                res.status(200).json({ ok: true, key: row.key, expired: row.expired, status: row.status });
                return;
            }

            // ── ต่อเวลา +24 ชั่วโมง ─────────────────────────────────────
            case "extend": {
                const key = String(body.key || "");
                if (!/^[A-Za-z0-9_]{1,64}$/.test(key)) {
                    res.status(400).json({ error: "Invalid key" });
                    return;
                }

                const rows = await sb("GET", `keyfree?key=eq.${encodeURIComponent(key)}&select=*`);
                const row = rows && rows[0];
                if (!row) { res.status(200).json({ ok: false, reason: "not_found" }); return; }
                if (row.status === "banned") { res.status(200).json({ ok: false, reason: "banned" }); return; }

                const now = Date.now();
                const oldExpire = row.expired ? new Date(row.expired).getTime() : 0;
                const base = (Number.isFinite(oldExpire) && oldExpire > now) ? oldExpire : now;
                const newExpired = new Date(base + KEY_LIFETIME_MS).toISOString();

                const updated = await sb("PATCH", `keyfree?key=eq.${encodeURIComponent(key)}`, {
                    status: "active",
                    expired: newExpired
                }, { "Prefer": "return=representation" });

                const u = updated && updated[0];
                res.status(200).json({ ok: true, key: u.key, expired: u.expired, status: u.status });
                return;
            }

            // ── แจ้งว่าคีย์หมดเวลา (จากหน้าเว็บตอน countdown ถึง 0) ─────
            case "expire": {
                const key = String(body.key || "");
                if (!/^[A-Za-z0-9_]{1,64}$/.test(key)) {
                    res.status(400).json({ error: "Invalid key" });
                    return;
                }
                const now = nowISO();
                await sb("PATCH",
                    `keyfree?key=eq.${encodeURIComponent(key)}&status=eq.active&expired=lt.${encodeURIComponent(now)}`,
                    { status: "expired" }).catch(() => null);
                res.status(200).json({ ok: true });
                return;
            }

            default:
                res.status(400).json({ error: "Unknown action" });
        }
    } catch (err) {
        console.error("uploads.js error:", err);
        res.status(502).json({ error: "Database error", detail: String((err && err.message) || err) });
    }
}
