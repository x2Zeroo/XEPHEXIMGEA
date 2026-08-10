// /api/uploads.js — Vercel Serverless Function
// ตัวกลางเดียวที่หน้าเว็บ (index.html) ใช้คุยกับ Supabase
// อนุญาตให้เรียกจาก "เว็บตัวเอง" เท่านั้น (เช็ค Origin) เรียกจากที่อื่นจะโดนบล็อก
//
// Environment Variables ที่ต้องตั้งใน Vercel:
//   SUPABASE_URL        = https://xxxx.supabase.co
//   SUPABASE_SECRET_KEY = secret API key (sb_secret_...) จาก Supabase > Project Settings > API Keys
//
// ตาราง: keys (key, hwid, status, expired, placeid)
// status: active | expired | banned
//
// กติกา:
// - สร้างคีย์: key ใหม่, hwid ว่าง, status active, expired = now + 24 ชม., placeid ว่าง
// - ต่อเวลา: อัพเดทฐานข้อมูลทันที (+24 ชม. จากเวลาหมดเดิม หรือจากตอนนี้ถ้าหมดไปแล้ว)
// - คีย์ banned ต่อเวลาไม่ได้
// - คีย์หมดเวลา: อัพเดท status เป็น expired ในฐานข้อมูลทันที
// - คีย์ expired เกิน 3 วันโดยไม่ต่อเวลา: ลบออกจากฐานข้อมูลอัตโนมัติ

const SUPABASE_URL = process.env.SUPABASE_URL || "https://ciegrrvjocdcssklbjwo.supabase.co";
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;

const KEY_LIFETIME_MS = 24 * 60 * 60 * 1000;      // อายุคีย์ 24 ชั่วโมง
const DELETE_AFTER_MS = 3 * 24 * 60 * 60 * 1000;  // expired เกิน 3 วัน = ลบทิ้ง
const MAX_KEYS_PER_USER = 6;

// เผื่อมี domain อื่นของตัวเองเพิ่มในอนาคต ใส่เพิ่มตรงนี้ได้
const EXTRA_ALLOWED_ORIGINS = [
    "https://dashboard.xephex.xyz",
    "https://xephex.vercel.app"
];

async function sb(method, path, body, extraHeaders) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
        method,
        headers: {
            "Content-Type": "application/json",
            // secret key (sb_secret_...) ไม่ใช่ JWT — ส่งผ่าน apikey header อย่างเดียว
            "apikey": SUPABASE_SECRET_KEY,
            ...(extraHeaders || {})
        },
        body: body ? JSON.stringify(body) : undefined
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`Supabase ${res.status}: ${text}`);
    return text ? JSON.parse(text) : null;
}

// อนุญาตเฉพาะ request จากเว็บตัวเองเท่านั้น:
// Origin ต้องมี และ host ของ Origin ต้องตรงกับ host ที่ deploy อยู่ (หรืออยู่ในลิสต์ที่อนุญาต)
// request ที่ไม่มี Origin (curl / สคริปต์ / เกม) จะโดนบล็อกทั้งหมด
function isAllowedOrigin(req) {
    const origin = req.headers.origin;
    if (!origin) return false;
    if (EXTRA_ALLOWED_ORIGINS.includes(origin)) return true;
    try {
        const originHost = new URL(origin).host;
        return originHost === req.headers.host;
    } catch {
        return false;
    }
}

function nowISO() { return new Date().toISOString(); }

function genKey(len) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let out = "";
    for (let i = 0; i < len; i++) out += chars[Math.floor(Math.random() * chars.length)];
    return out;
}

// งานดูแลฐานข้อมูล — เรียกทุกครั้งที่มี request เข้ามา
// 1) คีย์ active ที่เลยเวลาหมดแล้ว → เปลี่ยน status เป็น expired ทันที
// 2) คีย์ expired ที่หมดเวลามาเกิน 3 วัน → ลบออกจากฐานข้อมูล
async function housekeeping() {
    const now = nowISO();
    const cutoff = new Date(Date.now() - DELETE_AFTER_MS).toISOString();
    await Promise.all([
        sb("PATCH", `keys?status=eq.active&expired=lt.${encodeURIComponent(now)}`,
            { status: "expired" }).catch(() => null),
        sb("DELETE", `keys?status=eq.expired&expired=lt.${encodeURIComponent(cutoff)}`)
            .catch(() => null)
    ]);
}

module.exports = async function handler(req, res) {
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

    let body = {};
    try { body = req.body || {}; } catch { body = {}; }
    const action = String(body.action || "");

    try {
        await housekeeping();

        switch (action) {

            // ── ดึงสถานะล่าสุดของคีย์ที่หน้าเว็บถืออยู่ ─────────────────
            // ส่ง keys: ["ABC...", ...] มา แล้วคืนแถวที่ยังอยู่ในฐานข้อมูล
            // คีย์ไหนไม่อยู่ในผลลัพธ์ = โดนลบไปแล้ว (เช่น expired เกิน 3 วัน)
            case "list": {
                const keys = Array.isArray(body.keys)
                    ? body.keys.filter(k => typeof k === "string" && /^[A-Za-z0-9]{1,64}$/.test(k)).slice(0, 20)
                    : [];
                if (keys.length === 0) { res.status(200).json({ ok: true, rows: [] }); return; }
                const filter = keys.map(k => `"${k}"`).join(",");
                const rows = await sb("GET",
                    `keys?key=in.(${encodeURIComponent(filter)})&select=key,status,expired`);
                res.status(200).json({ ok: true, rows: rows || [] });
                return;
            }

            // ── สร้างคีย์ใหม่ ────────────────────────────────────────────
            // server เป็นคนสุ่มคีย์เอง: hwid ว่าง, status active, expired +24 ชม., placeid ว่าง
            case "create": {
                const owned = Array.isArray(body.keys)
                    ? body.keys.filter(k => typeof k === "string").slice(0, 20)
                    : [];
                if (owned.length >= MAX_KEYS_PER_USER) {
                    res.status(200).json({ ok: false, reason: "max_keys" });
                    return;
                }

                const key = genKey(24);
                const expired = new Date(Date.now() + KEY_LIFETIME_MS).toISOString();
                const created = await sb("POST", "keys", {
                    key,
                    hwid: "",
                    status: "active",
                    expired,
                    placeid: ""
                }, { "Prefer": "return=representation" });

                const row = created && created[0];
                res.status(200).json({ ok: true, key: row.key, expired: row.expired, status: row.status });
                return;
            }

            // ── ต่อเวลา +24 ชั่วโมง ─────────────────────────────────────
            // อัพเดทฐานข้อมูลทันที / คีย์ banned ต่อไม่ได้
            case "extend": {
                const key = String(body.key || "");
                if (!/^[A-Za-z0-9]{1,64}$/.test(key)) {
                    res.status(400).json({ error: "Invalid key" });
                    return;
                }

                const rows = await sb("GET", `keys?key=eq.${encodeURIComponent(key)}&select=*`);
                const row = rows && rows[0];
                if (!row) { res.status(200).json({ ok: false, reason: "not_found" }); return; }
                if (row.status === "banned") { res.status(200).json({ ok: false, reason: "banned" }); return; }

                const now = Date.now();
                const oldExpire = row.expired ? new Date(row.expired).getTime() : 0;
                const base = (Number.isFinite(oldExpire) && oldExpire > now) ? oldExpire : now;
                const newExpired = new Date(base + KEY_LIFETIME_MS).toISOString();

                const updated = await sb("PATCH", `keys?key=eq.${encodeURIComponent(key)}`, {
                    status: "active",
                    expired: newExpired
                }, { "Prefer": "return=representation" });

                const u = updated && updated[0];
                res.status(200).json({ ok: true, key: u.key, expired: u.expired, status: u.status });
                return;
            }

            // ── แจ้งว่าคีย์หมดเวลา (จากหน้าเว็บตอน countdown ถึง 0) ─────
            // server ตรวจเองอีกรอบว่าหมดจริง ถึงจะเปลี่ยน status ให้
            case "expire": {
                const key = String(body.key || "");
                if (!/^[A-Za-z0-9]{1,64}$/.test(key)) {
                    res.status(400).json({ error: "Invalid key" });
                    return;
                }
                const now = nowISO();
                await sb("PATCH",
                    `keys?key=eq.${encodeURIComponent(key)}&status=eq.active&expired=lt.${encodeURIComponent(now)}`,
                    { status: "expired" }).catch(() => null);
                res.status(200).json({ ok: true });
                return;
            }

            default:
                res.status(400).json({ error: "Unknown action" });
        }
    } catch (err) {
        res.status(502).json({ error: "Database error", detail: String(err) });
    }
};
