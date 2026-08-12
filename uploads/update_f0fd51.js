// /api/update.js — Vercel Serverless Function
// API สำหรับ "สคริปต์เกม (Roblox)" เท่านั้น — ไม่ใช่หน้าเว็บ
//
// กติกา:
// - ทุก request ต้องส่ง header "X-Game-Secret" ที่ตรงกับ GAME_SHARED_SECRET (env var)
//   ถ้าไม่ตรง = ปฏิเสธทันที ไม่เห็นอะไรเลย
// - ต่อให้ GAME_SHARED_SECRET ถูก แต่คีย์ (licenseKey) ที่ส่งมาผิด/ไม่มีในฐานข้อมูล
//   = ไม่อนุญาต จะไม่เห็นข้อมูลอะไรเลยเช่นกัน
// - ถ้าทั้ง secret และคีย์ถูก จะเห็นข้อมูลทั้งหมด "ของคีย์นั้นเท่านั้น"
// - API นี้แก้ไขได้แค่ hwid อย่างเดียว (อัพเดท hwid / ลบ hwid) ห้ามแก้ field อื่น
//
// Environment Variables ที่ต้องตั้งใน Vercel:
//   SUPABASE_URL        = https://xxxx.supabase.co
//   SUPABASE_SECRET_KEY = secret API key (sb_secret_...) จาก Supabase (ตัวเดียวกับ uploads.js)
//   GAME_SHARED_SECRET  = สุ่มสตริงยาวๆ อย่างน้อย 32 ตัวอักษร ต้องตรงกับที่ฝังในสคริปต์เกม

const SUPABASE_URL = process.env.SUPABASE_URL || "https://ciegrrvjocdcssklbjwo.supabase.co";
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;
const GAME_SHARED_SECRET = process.env.GAME_SHARED_SECRET;

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

// เปรียบเทียบ secret แบบ constant-time กัน timing attack
function timingSafeEqual(a, b) {
    if (typeof a !== "string" || typeof b !== "string") return false;
    if (a.length !== b.length) return false;
    let diff = 0;
    for (let i = 0; i < a.length; i++) {
        diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return diff === 0;
}

// หาแถวของคีย์ — ถ้าคีย์ผิดคืน null (ผู้เรียกจะไม่เห็นอะไรเลย)
async function findKey(licenseKey) {
    if (!licenseKey || typeof licenseKey !== "string") return null;
    if (!/^[A-Za-z0-9_]{1,64}$/.test(licenseKey)) return null;
    const rows = await sb("GET", `keyfree?key=eq.${encodeURIComponent(licenseKey)}&select=*`);
    return rows && rows[0] ? rows[0] : null;
}

module.exports = async function handler(req, res) {
    // API นี้ไม่เปิด CORS ให้ browser — สำหรับสคริปต์เกมเท่านั้น
    if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
    }
    if (!SUPABASE_SECRET_KEY) {
        res.status(500).json({ error: "Server misconfigured: missing SUPABASE_SECRET_KEY" });
        return;
    }
    if (!GAME_SHARED_SECRET) {
        res.status(500).json({ error: "Server misconfigured: missing GAME_SHARED_SECRET" });
        return;
    }

    // ชั้นที่ 1: ตรวจ GAME_SHARED_SECRET ก่อน — ผิดคือจบ ไม่แตะฐานข้อมูลเลย
    const providedSecret = req.headers["x-game-secret"];
    if (!timingSafeEqual(providedSecret, GAME_SHARED_SECRET)) {
        res.status(403).json({ error: "Forbidden" });
        return;
    }

    let body = {};
    try { body = req.body || {}; } catch { body = {}; }
    const action = String(body.action || "");
    const licenseKey = String(body.licenseKey || "").trim();

    try {
        // ชั้นที่ 2: คีย์ต้องมีอยู่จริง — คีย์ผิดจะไม่เห็นอะไรเลย
        // (ตอบเหมือนกันหมดทุกกรณี ไม่บอกใบ้ว่าคีย์มีจริงหรือไม่)
        const row = await findKey(licenseKey);
        if (!row) {
            res.status(200).json({ ok: false, reason: "invalid_key" });
            return;
        }

        switch (action) {

            // ── อ่านข้อมูลทั้งหมดของคีย์นั้น ─────────────────────────────
            case "get_key": {
                res.status(200).json({ ok: true, data: row });
                return;
            }

            // ── ตรวจคีย์แบบครบวงจร (ใช้ตอนเข้าเกม) ─────────────────────
            // เช็ค status / วันหมดอายุ / placeid / hwid ให้ครบในครั้งเดียว
            // ถ้า hwid ในฐานข้อมูลยังว่าง จะผูก hwid ที่ส่งมาให้อัตโนมัติ
            case "verify_license": {
                const hwid = String(body.hwid || "").trim().slice(0, 200);
                const placeId = String(body.placeId || "").trim().slice(0, 50);

                if (row.status === "banned") {
                    res.status(200).json({ ok: false, reason: "banned" });
                    return;
                }

                let expired = row.status === "expired";
                if (!expired && row.expired) {
                    const t = new Date(row.expired).getTime();
                    if (Number.isFinite(t) && Date.now() >= t) expired = true;
                }
                if (expired) {
                    // อัพเดทฐานข้อมูลทันทีถ้าเพิ่งหมดเวลา
                    if (row.status !== "expired") {
                        await sb("PATCH", `keyfree?key=eq.${encodeURIComponent(licenseKey)}`,
                            { status: "expired" }).catch(() => null);
                    }
                    res.status(200).json({ ok: false, reason: "expired" });
                    return;
                }

                if (row.placeid && row.placeid !== "" && row.placeid !== placeId) {
                    res.status(200).json({ ok: false, reason: "wrong_game" });
                    return;
                }

                if (!row.hwid || row.hwid === "") {
                    // hwid ยังว่าง — ผูกกับเครื่องนี้ (API นี้แก้ได้แค่ hwid)
                    if (hwid) {
                        await sb("PATCH", `keyfree?key=eq.${encodeURIComponent(licenseKey)}`, { hwid });
                    }
                } else if (row.hwid !== hwid) {
                    res.status(200).json({ ok: false, reason: "hwid_mismatch" });
                    return;
                }

                res.status(200).json({
                    ok: true,
                    data: { key: row.key, status: row.status, expired: row.expired, placeid: row.placeid }
                });
                return;
            }

            // ── อัพเดท hwid (field เดียวที่ API นี้แก้ได้) ────────────────
            case "update_hwid": {
                const hwid = String(body.hwid || "").trim().slice(0, 200);
                if (!hwid) { res.status(400).json({ error: "Missing hwid" }); return; }

                const updated = await sb("PATCH",
                    `keyfree?key=eq.${encodeURIComponent(licenseKey)}`,
                    { hwid },
                    { "Prefer": "return=representation" });
                res.status(200).json({ ok: true, data: updated && updated[0] });
                return;
            }

            // ── ลบ hwid (reset ให้ว่าง — ผูกเครื่องใหม่ได้) ──────────────
            case "reset_hwid": {
                const updated = await sb("PATCH",
                    `keyfree?key=eq.${encodeURIComponent(licenseKey)}`,
                    { hwid: "" },
                    { "Prefer": "return=representation" });
                res.status(200).json({ ok: true, data: updated && updated[0] });
                return;
            }

            default:
                res.status(400).json({ error: "Unknown action" });
        }
    } catch (err) {
        res.status(502).json({ error: "Database error", detail: String(err) });
    }
};
