// Vercel Serverless Function — ตัวกลางเดียวสำหรับคุยกับ Supabase ในส่วนที่อ่อนไหว
// วางไฟล์นี้ไว้ที่ /api/data.js ในโปรเจกต์ Vercel (อยู่ในโฟลเดอร์ api/ เดียวกับ proxy.js, ban.js)
//
// เหตุผล: เดิม index.html เรียก Supabase ตรงๆ ด้วย anon key จาก client ทำให้ถ้า RLS
// ไม่ได้ตั้งไว้แน่นหนา ใครก็ query/แก้ข้อมูลข้ามบัญชีได้หมด ย้ายมาไว้หลัง server แบบนี้
// ทำให้ client ไม่มีทางคุยกับ Supabase ตรงได้อีก ทุก request ต้องผ่านการตรวจสอบ
// "api_key มีอยู่จริงไหม" ก่อน แล้ว filter ข้อมูลเฉพาะของ key นั้นเท่านั้นทุกครั้ง
//
// ต้องตั้งค่า Environment Variable ใน Vercel:
//   SUPABASE_SECRET_KEY = <secret API key (sb_secret_...) จาก Supabase Project Settings > API Keys>
//   GAME_SHARED_SECRET  = <สุ่มสตริงยาวๆ อย่างน้อย 32 ตัวอักษร ไม่ซ้ำกับที่อื่น>
//
// หมายเหตุ: secret key รูปแบบใหม่ (sb_secret_...) ไม่ใช่ JWT อีกต่อไป ตาม Supabase docs
// ต้องส่งผ่าน header "apikey" เท่านั้น ห้ามส่งใน "Authorization: Bearer" (จะถูก reject
// เพราะไม่ใช่ JWT) — ดู sb() helper ด้านล่าง
//
// ==========================================================================
// GAME_SHARED_SECRET คืออะไร:
// action register / sync_inventory / poll_command / mark_command / verify_license
// เป็น action ที่ควรถูกเรียกจาก "สคริปต์เกมเท่านั้น" ไม่ใช่จาก browser dashboard
// (index.html เรียกแค่ login/status/send/history/command_status) ปัญหาคือ Origin
// header ใช้เช็คไม่ได้กับ executor เพราะ request()/http.request ไม่ส่ง Origin header
// แบบ browser (CORS เป็นกลไกฝั่ง browser เท่านั้น ไม่ใช่ auth ฝั่ง server) ดังนั้นต้องมี
// secret แยกต่างหากที่ฝังในสคริปต์เกม ส่งมาทาง header "X-Game-Secret" ทุกครั้งที่เรียก
// 5 action นี้
//
// ข้อจำกัดที่ต้องรู้ (บอกไว้ตรงๆ ไม่ใช่ช่องโหว่ที่มองข้าม): secret ที่ฝังใน Lua ที่รันบน
// client เป็นความลับที่ไม่สมบูรณ์แบบเสมอ — ถ้ามีคน decompile/dump สคริปต์ได้ secret ไป
// จะปลอม userId/licenseKey มาเรียก 5 action นี้ได้ แต่ "ไม่สามารถ" เข้าถึง Supabase ตรง
// หรือ action อื่นนอกเหนือจากนี้ได้ ความเสียหายจำกัดกว่าการหลุด service_role key มาก

const SUPABASE_URL = "https://ciegrrvjocdcssklbjwo.supabase.co";
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;
const GAME_SHARED_SECRET = process.env.GAME_SHARED_SECRET;

const ALLOWED_ORIGINS = [
    "https://dashboard.xephex.xyz"
];

// action ที่ต้องผ่าน GAME_SHARED_SECRET ก่อน (เรียกจากสคริปต์เกมเท่านั้น)
const GAME_ONLY_ACTIONS = new Set([
    "register", "sync_inventory", "poll_command", "mark_command", "verify_license"
]);

async function sb(method, path, body, extraHeaders) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
        method,
        headers: {
            "Content-Type": "application/json",
            // Secret key (sb_secret_...) ไม่ใช่ JWT — ส่งผ่าน apikey header อย่างเดียว
            // ห้ามส่งใน Authorization: Bearer เพราะจะถูก Supabase gateway reject
            "apikey": SUPABASE_SECRET_KEY,
            ...(extraHeaders || {})
        },
        body: body ? JSON.stringify(body) : undefined
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`Supabase ${res.status}: ${text}`);
    return text ? JSON.parse(text) : null;
}

// ตรวจว่า api_key มีอยู่จริงในตาราง api_keys ก่อนทุกครั้ง กันคน "เดา" key มั่วๆ มาดึงข้อมูล
async function verifyApiKey(apiKey) {
    if (!apiKey || typeof apiKey !== "string") return null;
    const rows = await sb("GET", `api_keys?api_key=eq.${encodeURIComponent(apiKey)}`);
    return rows && rows[0] ? rows[0] : null;
}

// เปรียบเทียบ secret แบบ constant-time กัน timing attack (ยาวไม่เท่ากันก็ต้องคืน false แบบ fixed cost)
function timingSafeEqual(a, b) {
    if (typeof a !== "string" || typeof b !== "string") return false;
    if (a.length !== b.length) return false;
    let diff = 0;
    for (let i = 0; i < a.length; i++) {
        diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return diff === 0;
}

function GetISOTime() {
    return new Date().toISOString();
}

module.exports = async function handler(req, res) {
    const origin = req.headers.origin;
    if (origin && ALLOWED_ORIGINS.includes(origin)) {
        res.setHeader("Access-Control-Allow-Origin", origin);
    }
    res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-Game-Secret");

    if (req.method === "OPTIONS") {
        res.status(204).end();
        return;
    }
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

    let body = {};
    try { body = req.body || {}; } catch { body = {}; }
    const { action, apiKey } = body;

    // ชั้น auth แรก: ถ้า action เป็นของสคริปต์เกม ต้องมี secret ที่ถูกต้องก่อน ไม่งั้น
    // reject ทันทีโดยไม่แตะ Supabase เลย (กันทั้ง cost และ information leak)
    if (GAME_ONLY_ACTIONS.has(action)) {
        const providedSecret = req.headers["x-game-secret"];
        if (!timingSafeEqual(providedSecret, GAME_SHARED_SECRET)) {
            res.status(403).json({ error: "Invalid game secret" });
            return;
        }
    }

    try {
        switch (action) {
            case "login": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(200).json({ ok: false }); return; }
                res.status(200).json({ ok: true, profile });
                return;
            }

            case "get_inventory": {
                const rows = await sb("GET",
                    `api_keys?api_key=eq.${encodeURIComponent(apiKey)}&select=inventory,last_updated`);
                const row = rows && rows[0];
                if (!row) { res.status(200).json({ ok: false }); return; }
                res.status(200).json({ ok: true, inventory: row.inventory, last_updated: row.last_updated });
                return;
            }

            case "status": {
                const keys = Array.isArray(body.apiKeys) ? body.apiKeys.filter(k => typeof k === "string") : [];
                if (keys.length === 0) { res.status(200).json({ results: [] }); return; }
                const keysFilter = keys.map(k => `"${k}"`).join(",");
                const rows = await sb("GET", `api_keys?api_key=in.(${keysFilter})&select=api_key,last_updated`);
                res.status(200).json({ results: rows || [] });
                return;
            }

            case "send": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(403).json({ error: "Invalid key" }); return; }

                const targetName = String(body.targetName || "").trim().slice(0, 100);
                const note = String(body.note || "").trim().slice(0, 1000);
                const rawQuantity = parseInt(body.quantity, 10);
                const quantity = Number.isFinite(rawQuantity) ? Math.min(Math.max(rawQuantity, 1), 200000) : 1;
                const items = Array.isArray(body.items) ? body.items.slice(0, 50) : [];

                if (!targetName || items.length === 0) {
                    res.status(400).json({ error: "Missing targetName or items" });
                    return;
                }

                const safeItems = items.map(i => ({
                    Category: String(i.Category || "").slice(0, 50),
                    ItemKey: String(i.ItemKey || "").slice(0, 100),
                    Count: quantity
                }));

                const created = await sb("POST", "commands", {
                    api_key: apiKey,
                    target_name: targetName,
                    items: safeItems,
                    note,
                    status: "pending"
                }, { "Prefer": "return=representation" });

                res.status(200).json({ ok: true, command: created && created[0] });
                return;
            }

            case "command_status": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(403).json({ error: "Invalid key" }); return; }

                const commandId = String(body.commandId || "");
                if (!commandId) { res.status(400).json({ error: "Missing commandId" }); return; }

                const rows = await sb("GET",
                    `commands?id=eq.${encodeURIComponent(commandId)}&api_key=eq.${encodeURIComponent(apiKey)}&select=status,processed_at`);
                res.status(200).json({ rows: rows || [] });
                return;
            }

            case "history": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(403).json({ error: "Invalid key" }); return; }

                const keyFilter = `api_key=eq.${encodeURIComponent(apiKey)}`;
                const [commands, history] = await Promise.all([
                    sb("GET", `commands?${keyFilter}&order=created_at.desc&limit=50`).catch(() => []),
                    sb("GET", `history?${keyFilter}&order=sent_at.desc&limit=50`).catch(() => [])
                ]);
                res.status(200).json({ commands: commands || [], history: history || [] });
                return;
            }

            // ==================================================================
            // Action ใหม่: ใช้แทน SupabaseRequest ตรงในสคริปต์เกม (Mailbox)
            // ==================================================================

            case "register": {
                const rawUserId = body.userId;
                const userId = parseInt(rawUserId, 10);
                if (!Number.isFinite(userId) || userId <= 0) {
                    res.status(400).json({ error: "Invalid userId" });
                    return;
                }
                const username = String(body.username || "").trim().slice(0, 50);
                const displayName = String(body.displayName || username).trim().slice(0, 50);
                if (!username) {
                    res.status(400).json({ error: "Missing username" });
                    return;
                }

                const existing = await sb("GET",
                    `api_keys?user_id=eq.${userId}&select=api_key&limit=1`);

                if (existing && existing[0]) {
                    // เคย register แล้ว — ห้ามคืน apiKey ให้ฟรีๆ จากแค่ userId อีกต่อไป
                    // (userId เป็นข้อมูลสาธารณะ ใครก็เดาได้ผ่าน Roblox profile/GetPlayers())
                    // ต้องพิสูจน์ตัวด้วย apiKey เดิมที่สคริปต์เกมเก็บไว้ตั้งแต่ครั้งแรกก่อน
                    // ป้องกันคนที่มีแค่ GAME_SHARED_SECRET + userId สาธารณะ สวมรอยขโมย apiKey
                    const providedKey = String(body.apiKey || "");
                    if (!timingSafeEqual(providedKey, existing[0].api_key)) {
                        res.status(403).json({ error: "apiKey mismatch" });
                        return;
                    }
                    res.status(200).json({ ok: true, apiKey: existing[0].api_key });
                    return;
                }

                // ยังไม่เคย register — จุดนี้ยังต้องเชื่อ userId เปล่าๆ อยู่ (ยังไม่มี apiKey
                // ให้พิสูจน์ตัวได้เลย) ผลกระทบเหลือแค่ "แย่งตัดหน้าสร้างบัญชีก่อน" ไม่ใช่
                // "ขโมย apiKey ที่มีอยู่แล้วของ user คนอื่น" อีกต่อไป
                const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
                let newKey = "";
                for (let i = 0; i < 32; i++) {
                    newKey += chars[Math.floor(Math.random() * chars.length)];
                }

                const inventory = (body.inventory && typeof body.inventory === "object") ? body.inventory : {};

                try {
                    await sb("POST", "api_keys", {
                        user_id: userId,
                        username,
                        display_name: displayName,
                        api_key: newKey,
                        inventory,
                        last_updated: GetISOTime()
                    });
                    res.status(200).json({ ok: true, apiKey: newKey });
                } catch (err) {
                    // race condition: อีก request แทรกไปพร้อมกันจนชน unique constraint
                    // ต้อง verify ด้วย apiKey ด้วยเช่นกัน ไม่ใช่ retry แล้วคืนให้ฟรีๆ
                    const retry = await sb("GET",
                        `api_keys?user_id=eq.${userId}&select=api_key&limit=1`).catch(() => null);
                    if (retry && retry[0]) {
                        const providedKey = String(body.apiKey || "");
                        if (timingSafeEqual(providedKey, retry[0].api_key)) {
                            res.status(200).json({ ok: true, apiKey: retry[0].api_key });
                            return;
                        }
                        res.status(403).json({ error: "apiKey mismatch" });
                        return;
                    }
                    throw err;
                }
                return;
            }

            case "sync_inventory": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(403).json({ error: "Invalid key" }); return; }

                const inventory = (body.inventory && typeof body.inventory === "object") ? body.inventory : {};

                // Prefer: return=representation บังคับให้ PostgREST ตอบแถวที่ถูกแก้จริงกลับมา
                // เดิมไม่มี header นี้ ทำให้ PATCH คืน 204 เสมอไม่ว่าจะ match 0 หรือ N แถว —
                // เป็นสาเหตุที่ sync ดู "สำเร็จ" (status 200, ok:true) ทั้งที่ไม่มีแถวไหนถูกเขียนจริง
                const updated = await sb("PATCH", `api_keys?api_key=eq.${encodeURIComponent(apiKey)}`, {
                    inventory,
                    last_updated: GetISOTime()
                }, { "Prefer": "return=representation" });

                if (!updated || updated.length === 0) {
                    // เจอ apiKey ตอน verify (query แยก) แต่ PATCH filter เดียวกันกลับไม่ match
                    // แถวไหนเลย — ผิดปกติ ควรเกิดจาก apiKey มีช่องว่าง/ตัวอักษรพิเศษที่ query
                    // string encode ต่างกันระหว่าง verifyApiKey (encodeURIComponent เหมือนกัน
                    // จริงๆ) กับที่ client ส่งมา หรือมี row ซ้ำ/RLS policy กันการเขียนเฉพาะ UPDATE
                    res.status(200).json({ ok: false, reason: "no_row_updated" });
                    return;
                }

                res.status(200).json({ ok: true });
                return;
            }

            case "poll_command": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(403).json({ error: "Invalid key" }); return; }

                const rows = await sb("GET",
                    `commands?api_key=eq.${encodeURIComponent(apiKey)}&status=eq.pending&order=created_at.asc&limit=1`);
                res.status(200).json({ command: (rows && rows[0]) || null });
                return;
            }

            case "mark_command": {
                const profile = await verifyApiKey(apiKey);
                if (!profile) { res.status(403).json({ error: "Invalid key" }); return; }

                const commandId = String(body.commandId || "");
                const status = String(body.status || "");
                if (!commandId || (status !== "sent" && status !== "failed")) {
                    res.status(400).json({ error: "Missing commandId or invalid status" });
                    return;
                }
                const targetName = String(body.targetName || "").trim().slice(0, 100);
                const note = String(body.note || "").trim().slice(0, 1000);
                const items = Array.isArray(body.items) ? body.items.slice(0, 50) : [];

                const updatedCmd = await sb("PATCH",
                    `commands?id=eq.${encodeURIComponent(commandId)}&api_key=eq.${encodeURIComponent(apiKey)}`,
                    { status, processed_at: GetISOTime() },
                    { "Prefer": "return=representation" });

                const commandUpdated = !!(updatedCmd && updatedCmd.length > 0);

                let historyOk = true;
                try {
                    await sb("POST", "history", {
                        api_key: apiKey,
                        target_name: targetName,
                        items,
                        note,
                        status,
                        sent_at: GetISOTime()
                    });
                } catch {
                    historyOk = false;
                }

                res.status(200).json({ ok: true, commandUpdated, historyRecorded: historyOk });
                return;
            }

            // ==================================================================
            // Action ใหม่: ใช้แทน supabaseRequest ตรงในระบบ key-checker (checkKey)
            // ==================================================================

            case "verify_license": {
                const licenseKey = String(body.licenseKey || "").trim();
                const hwid = String(body.hwid || "").trim();
                const placeId = String(body.placeId || "").trim();

                if (!licenseKey) {
                    res.status(400).json({ error: "Missing licenseKey" });
                    return;
                }

                const rows = await sb("GET",
                    `keys?key=eq.${encodeURIComponent(licenseKey)}&select=*`);
                const row = rows && rows[0];
                if (!row) {
                    res.status(200).json({ ok: false, reason: "invalid_key" });
                    return;
                }

                if (row.status === "banned") {
                    res.status(200).json({ ok: false, reason: "banned" });
                    return;
                }

                if (row.expires_at) {
                    const expiresAtMs = new Date(row.expires_at).getTime();
                    if (Number.isFinite(expiresAtMs) && Date.now() >= expiresAtMs) {
                        res.status(200).json({ ok: false, reason: "expired" });
                        return;
                    }
                }

                if (row.place_id && row.place_id !== "" && row.place_id !== placeId) {
                    res.status(200).json({ ok: false, reason: "wrong_game" });
                    return;
                }

                if (!row.hwid || row.hwid === "") {
                    if (hwid) {
                        await sb("PATCH", `keys?key=eq.${encodeURIComponent(licenseKey)}`, { hwid });
                    }
                } else if (row.hwid !== hwid) {
                    res.status(200).json({ ok: false, reason: "hwid_mismatch" });
                    return;
                }

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
