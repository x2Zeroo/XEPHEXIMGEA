'use sAllct';

/**
 * index.js — Discord Bot Entry Point
 * ------------------------------------------------------------
 * โฟลว์การทำงาน:
 *  1) ผู้ใช้ DM ไฟล์ .lua มาหาบอท
 *  2) บอทเช็คสิทธิ์ -> ถ้าไม่มีสิทธิ์เลย ตอบปฏิเสธ
 *  3) ถ้ามีสิทธิ์ -> ส่ง Embed "Obfuscator" พร้อมปุ่มเลือกระดับ
 *     (MINIMAL / BASIC / PREMIUM / COMMERCIAL / ENTERPRISE)
 *  4) กดปุ่มแล้ว -> เช็คสิทธิ์ระดับนั้นอีกครั้ง -> obfuscate ด้วย obf.js
 *     (engine ตัวเดียวกับหน้าเว็บ ไม่มีการแก้ไข logic ใดๆ)
 *  5) ส่งผลลัพธ์กลับพร้อมไฟล์แนบ
 *
 * เจ้าของบอท (ownerIds ใน config.json) ใช้คำสั่ง /obf จัดการสิทธิ์ผู้ใช้
 * และเปิด/ปิดโหมด public ได้
 *
 *  6) Supabase job queue: ตาราง obf_jobs — insert แถวใหม่ (file_name, level, code)
 *     -> บอทรับผ่าน Realtime -> log เข้าห้อง logChannelId เหมือนไฟล์จาก DM
 *     -> obfuscate ตาม level -> เขียนผลลง obf -> วนรอรับงานถัดไปเรื่อยๆ
 * ------------------------------------------------------------
 */

const fs = require('fs');
const path = require('path');
const {
  Client,
  GatewayIntentBits,
  Partials,
  Events,
  EmbedBuilder,
  ActionRowBuilder,
  SlashCommandBuilder,
  StringSelectMenuBuilder,
  REST,
  Routes,
  AttachmentBuilder,
} = require('discord.js');
const { createClient } = require('@supabase/supabase-js');

const { obfuscate, INTENSITY_LABELS, optionsForLevel } = require('./obf.js');

const CONFIG_PATH = path.join(__dirname, 'config.json');
const USER_DATA_PATH = path.join(__dirname, 'user.json');

// ---------------------------------------------------------------
// โหลด / บันทึก config.json
// ---------------------------------------------------------------
function loadConfig() {
  const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
  return JSON.parse(raw);
}

function saveConfig(cfg) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(cfg, null, 2), 'utf8');
}

let config = loadConfig();

// ---------------------------------------------------------------
// โหลด / บันทึก user.json — เก็บสิทธิ์ผู้ใช้แยกออกจาก config.json
// ถ้ายังไม่มีไฟล์ บอทจะสร้างให้เองอัตโนมัติ
// ---------------------------------------------------------------
function loadUsers() {
  if (!fs.existsSync(USER_DATA_PATH)) {
    fs.writeFileSync(USER_DATA_PATH, JSON.stringify({}, null, 2), 'utf8');
    return {};
  }
  const raw = fs.readFileSync(USER_DATA_PATH, 'utf8');
  return raw.trim() ? JSON.parse(raw) : {};
}

function saveUsers(users) {
  fs.writeFileSync(USER_DATA_PATH, JSON.stringify(users, null, 2), 'utf8');
}

let userData = loadUsers();

// ---------------------------------------------------------------
// ระบบสิทธิ์ (permissions)
// ---------------------------------------------------------------
function isOwner(userId) {
  return Array.isArray(config.ownerIds) && config.ownerIds.includes(userId);
}

/** คืนค่า array ของระดับที่ userId มีสิทธิ์ใช้ (เรียงตาม INTENSITY_LABELS) */
function getAllowedLevels(userId) {
  if (isOwner(userId)) return [...INTENSITY_LABELS];
  if (config.publicAccess) return [...INTENSITY_LABELS];
  const entry = userData && userData[userId];
  if (!entry || !Array.isArray(entry.levels)) return [];
  return INTENSITY_LABELS.filter((lvl) => entry.levels.includes(lvl));
}

function hasAnyAccess(userId) {
  return getAllowedLevels(userId).length > 0;
}

function hasLevelAccess(userId, level) {
  return getAllowedLevels(userId).includes(level);
}

// ---------------------------------------------------------------
// Embed แบบสำเร็จรูป
// ---------------------------------------------------------------
const COLOR_MAIN = 0x7c6ff5;
const COLOR_DENY = 0xf55a5a;
const COLOR_DONE = 0x5af5a0;

function embedObfuscatorPrompt(fileName) {
  return new EmbedBuilder()
    .setTitle('Obfuscator')
    .setDescription(`Got your file **${fileName}**.\nPick an **obfuscation level** below.`)
    .setColor(COLOR_MAIN);
}

function embedObfuscating(fileName, level) {
  return new EmbedBuilder()
    .setTitle('Obfuscator')
    .setDescription(`Obfuscating **${fileName}**...\nLevel: **${level}**`)
    .setColor(COLOR_MAIN);
}

function embedDone(level) {
  return new EmbedBuilder()
    .setTitle('Obfuscator')
    .setDescription(`done!\nLevel: **${level}**`)
    .setColor(COLOR_DONE);
}

function embedNoAccess() {
  return new EmbedBuilder()
    .setTitle('Luna | Obfuscator')
    .setDescription("You don't have access to the obfuscator right now. Reach out to an admin if you'd like access.")
    .setColor(COLOR_DENY);
}

function embedNoLevelAccess(level) {
  return new EmbedBuilder()
    .setTitle('Luna | Obfuscator')
    .setDescription(`You don't have permission to use the **${level}** level yet. Ask an admin to unlock it for you.`)
    .setColor(COLOR_DENY);
}

function embedNewFileLog(user, fileName) {
  return new EmbedBuilder()
    .setTitle('ไฟล์ใหม่ (ก่อน obf)')
    .addFields(
      { name: 'ผู้ใช้', value: `${user} (${user.tag})` },
      { name: 'ชื่อไฟล์', value: fileName }
    )
    .setColor(COLOR_MAIN)
    .setTimestamp(new Date());
}

async function logNewFileSubmission(user, fileName, buffer) {
  const channelId = config.logChannelId;
  if (!channelId) return;
  try {
    const channel = await client.channels.fetch(channelId);
    if (!channel) return;
    const file = new AttachmentBuilder(buffer, { name: fileName });
    await channel.send({ embeds: [embedNewFileLog(user, fileName)], files: [file] });
  } catch (err) {
    console.error('[obf-bot] ส่ง log ไฟล์ใหม่ไปห้อง log ล้มเหลว:', err);
  }
}

function levelSelectRow(sessionId, allowedLevels) {
  const select = new StringSelectMenuBuilder()
    .setCustomId(`obflvl:${sessionId}`)
    .setPlaceholder('Select level obfuscate')
    .addOptions(
      allowedLevels.map((level) => ({
        label: level,
        value: level,
      }))
    );
  return new ActionRowBuilder().addComponents(select);
}

// ---------------------------------------------------------------
// เก็บ session ไฟล์ที่รอเลือกระดับ (ในหน่วยความจำ)
// ---------------------------------------------------------------
const sessions = new Map(); // sessionId -> { userId, fileName, content, createdAt }
const SESSION_TTL_MS = 30 * 60 * 1000; // 30 นาที

function makeSessionId() {
  return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
}

setInterval(() => {
  const now = Date.now();
  for (const [id, s] of sessions) {
    if (now - s.createdAt > SESSION_TTL_MS) sessions.delete(id);
  }
}, 5 * 60 * 1000).unref();

// ---------------------------------------------------------------
// Slash command: /obf
// ---------------------------------------------------------------
const obfCommand = new SlashCommandBuilder()
  .setName('obf')
  .setDescription('จัดการระบบ Obfuscator (เฉพาะเจ้าของบอท)')
  .addSubcommand((sub) =>
    sub
      .setName('public')
      .setDescription('เปิด/ปิดให้ทุกคนใช้งาน obfuscate ได้')
      .addBooleanOption((opt) =>
        opt.setName('enable').setDescription('เปิด (true) หรือ ปิด (false)').setRequired(true)
      )
  )
  .addSubcommand((sub) => sub.setName('list').setDescription('แสดงรายชื่อผู้ใช้และสิทธิ์ระดับ obfuscate'))
  .addSubcommand((sub) =>
    sub
      .setName('adduser')
      .setDescription('เพิ่มสิทธิ์ผู้ใช้ให้ obfuscate ในระดับที่กำหนด')
      .addUserOption((opt) => opt.setName('user').setDescription('ผู้ใช้ที่ต้องการให้สิทธิ์').setRequired(true))
      .addStringOption((opt) =>
        opt
          .setName('level')
          .setDescription('ระดับที่ต้องการให้สิทธิ์')
          .setRequired(true)
          .addChoices(...INTENSITY_LABELS.map((lvl) => ({ name: lvl, value: lvl })))
      )
  )
  .addSubcommand((sub) =>
    sub
      .setName('removeuser')
      .setDescription('ลบสิทธิ์ผู้ใช้ (ระบุระดับเพื่อลบเฉพาะระดับ หรือเว้นว่างเพื่อลบทั้งหมด)')
      .addUserOption((opt) => opt.setName('user').setDescription('ผู้ใช้ที่ต้องการลบสิทธิ์').setRequired(true))
      .addStringOption((opt) =>
        opt
          .setName('level')
          .setDescription('ระดับที่ต้องการลบ (เว้นว่าง = ลบสิทธิ์ทั้งหมดของผู้ใช้)')
          .setRequired(false)
          .addChoices(...INTENSITY_LABELS.map((lvl) => ({ name: lvl, value: lvl })))
      )
  );

async function registerCommands(client) {
  const rest = new REST({ version: '10' }).setToken(config.token);
  const clientId = config.clientId || client.user.id;
  const guildIds = Array.isArray(config.guildIds) ? config.guildIds.filter(Boolean) : [];

  if (guildIds.length === 0) {
    console.warn('[obf-bot] ไม่พบ guildIds ใน config.json — ข้ามการลงทะเบียนคำสั่ง slash command');
    return;
  }

  for (const guildId of guildIds) {
    try {
      await rest.put(Routes.applicationGuildCommands(clientId, guildId), {
        body: [obfCommand.toJSON()],
      });
      console.log(`[obf-bot] ลงทะเบียนคำสั่งกับเซิร์ฟเวอร์ ${guildId} สำเร็จ`);
    } catch (err) {
      console.error(`[obf-bot] ลงทะเบียนคำสั่งกับเซิร์ฟเวอร์ ${guildId} ล้มเหลว:`, err);
    }
  }
}

// ---------------------------------------------------------------
// Client setup
// ---------------------------------------------------------------
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.DirectMessages,
    GatewayIntentBits.MessageContent,
  ],
  partials: [Partials.Channel, Partials.Message],
});

client.once(Events.ClientReady, async (c) => {
  console.log(`[obf-bot] ล็อกอินสำเร็จในชื่อ ${c.user.tag}`);
  await registerCommands(c);
  startSupabaseWorker(c);
});

// ---------------------------------------------------------------
// DM: รับไฟล์ -> ส่ง prompt เลือกระดับ
// ---------------------------------------------------------------
client.on(Events.MessageCreate, async (message) => {
  try {
    if (message.author.bot) return;
    if (message.guild) return; // DMs only
    if (message.attachments.size === 0) return;

    const attachment = message.attachments.first();
    const ext = path.extname(attachment.name || '').toLowerCase();
    const allowedExt = config.allowedExtensions || ['.lua'];

    if (!allowedExt.includes(ext)) {
      await message.reply(`I can only take these file types: ${allowedExt.join(', ')}`);
      return;
    }

    if (attachment.size > (config.maxInputFileSizeBytes || 5 * 1024 * 1024)) {
      await message.reply("That file's a bit too big — please keep it under 5MB.");
      return;
    }

    // Discord renames attachments to a random hex string in some upload flows
    // (mobile share sheet, non-Latin filenames, etc.), so we lose the real name.
    // If the user typed the intended filename as the message text, use that instead.
    let fileName = attachment.name || 'script.lua';
    const typed = (message.content || '').trim();
    if (typed) {
      const typedName = typed.length > 120 ? typed.slice(0, 120) : typed;
      const typedExt = path.extname(typedName).toLowerCase();
      fileName = allowedExt.includes(typedExt) ? typedName : `${typedName}${ext}`;
    }

    const userId = message.author.id;

    // Download the file content once (used for both the log channel and obfuscation)
    const res = await fetch(attachment.url);
    const arrBuf = await res.arrayBuffer();
    const buffer = Buffer.from(arrBuf);
    const content = buffer.toString('utf8');

    // Mirror every incoming file to the log channel, before obfuscation
    await logNewFileSubmission(message.author, fileName, buffer);

    if (!hasAnyAccess(userId)) {
      await message.reply({ embeds: [embedNoAccess()] });
      return;
    }

    const sessionId = makeSessionId();
    sessions.set(sessionId, {
      userId,
      fileName,
      content,
      createdAt: Date.now(),
    });

    const allowedLevels = getAllowedLevels(userId);
    await message.reply({
      embeds: [embedObfuscatorPrompt(fileName)],
      components: [levelSelectRow(sessionId, allowedLevels)],
    });
  } catch (err) {
    console.error('[obf-bot] error handling incoming file:', err);
  }
});

// ---------------------------------------------------------------
// ปุ่มเลือกระดับ -> obfuscate -> ส่งผลลัพธ์
// ---------------------------------------------------------------
client.on(Events.InteractionCreate, async (interaction) => {
  if (interaction.isStringSelectMenu()) {
    await handleLevelSelect(interaction);
    return;
  }
  if (interaction.isChatInputCommand()) {
    await handleObfCommand(interaction);
    return;
  }
});

async function handleLevelSelect(interaction) {
  const [prefix, sessionId] = interaction.customId.split(':');
  if (prefix !== 'obflvl') return;
  const level = interaction.values[0];

  const session = sessions.get(sessionId);
  if (!session) {
    await interaction.reply({ content: 'This session has expired — please send the file again.', ephemeral: true });
    return;
  }

  if (interaction.user.id !== session.userId) {
    await interaction.reply({ content: "This isn't your file.", ephemeral: true });
    return;
  }

  if (!hasLevelAccess(session.userId, level)) {
    await interaction.reply({ embeds: [embedNoLevelAccess(level)] });
    return;
  }

  // Clear the dropdown and switch the message to the "in progress" state
  await interaction.update({
    embeds: [embedObfuscating(session.fileName, level)],
    components: [],
  });

  try {
    const opts = optionsForLevel(level);
    const result = obfuscate(session.content, opts);
    const outBuffer = Buffer.from(result, 'utf8');

    if (outBuffer.length > (config.maxOutputFileSizeBytes || 8 * 1024 * 1024)) {
      await interaction.message.delete().catch(() => {});
      await interaction.followUp({
        content: "The obfuscated output is too large to send through Discord. Try a lower level.",
      });
      sessions.delete(sessionId);
      return;
    }

    const outName = `obf_${level.toLowerCase()}_${session.fileName}`;
    const file = new AttachmentBuilder(outBuffer, { name: outName });

    // Remove the "in progress" message and post the result as a new message
    await interaction.message.delete().catch(() => {});
    await interaction.followUp({
      embeds: [embedDone(level)],
      files: [file],
    });
  } catch (err) {
    console.error('[obf-bot] obfuscation failed:', err);
    await interaction.message.delete().catch(() => {});
    await interaction.followUp({ content: `Something went wrong while obfuscating: ${err.message || err}` });
  } finally {
    sessions.delete(sessionId);
  }
}

// ---------------------------------------------------------------
// /obf คำสั่งจัดการสิทธิ์ (เฉพาะเจ้าของบอท)
// ---------------------------------------------------------------
async function handleObfCommand(interaction) {
  if (interaction.commandName !== 'obf') return;

  if (!isOwner(interaction.user.id)) {
    await interaction.reply({ content: 'คุณไม่มีสิทธิ์ใช้งานคำสั่งนี้', ephemeral: true });
    return;
  }

  const sub = interaction.options.getSubcommand();

  if (sub === 'public') {
    const enable = interaction.options.getBoolean('enable', true);
    config.publicAccess = enable;
    saveConfig(config);
    await interaction.reply({
      content: `ตั้งค่าโหมด public เป็น **${enable ? 'เปิด' : 'ปิด'}** แล้ว`,
      ephemeral: true,
    });
    return;
  }

  if (sub === 'list') {
    const lines = [];
    lines.push(`โหมด public: **${config.publicAccess ? 'เปิด' : 'ปิด'}**`);
    lines.push('');
    const userIds = Object.keys(userData || {});
    if (userIds.length === 0) {
      lines.push('ยังไม่มีผู้ใช้ที่ถูกกำหนดสิทธิ์แบบเจาะจง');
    } else {
      for (const uid of userIds) {
        const levels = (userData[uid].levels || []).join(', ') || '-';
        lines.push(`<@${uid}> — ${levels}`);
      }
    }
    const embed = new EmbedBuilder()
      .setTitle('Obfuscator | รายชื่อสิทธิ์ผู้ใช้')
      .setDescription(lines.join('\n'))
      .setColor(COLOR_MAIN);
    await interaction.reply({ embeds: [embed], ephemeral: true });
    return;
  }

  if (sub === 'adduser') {
    const user = interaction.options.getUser('user', true);
    const level = interaction.options.getString('level', true);
    if (!userData[user.id]) userData[user.id] = { levels: [] };
    if (!userData[user.id].levels.includes(level)) {
      userData[user.id].levels.push(level);
    }
    saveUsers(userData);
    await interaction.reply({
      content: `ให้สิทธิ์ระดับ **${level}** แก่ <@${user.id}> แล้ว`,
      ephemeral: true,
    });
    return;
  }

  if (sub === 'removeuser') {
    const user = interaction.options.getUser('user', true);
    const level = interaction.options.getString('level', false);

    if (!userData[user.id]) {
      await interaction.reply({ content: `<@${user.id}> ยังไม่มีสิทธิ์ที่กำหนดไว้`, ephemeral: true });
      return;
    }

    if (level) {
      userData[user.id].levels = (userData[user.id].levels || []).filter((l) => l !== level);
      saveUsers(userData);
      await interaction.reply({ content: `ลบสิทธิ์ระดับ **${level}** ของ <@${user.id}> แล้ว`, ephemeral: true });
    } else {
      delete userData[user.id];
      saveUsers(userData);
      await interaction.reply({ content: `ลบสิทธิ์ทั้งหมดของ <@${user.id}> แล้ว`, ephemeral: true });
    }
    return;
  }
}

// ---------------------------------------------------------------
// Supabase job queue — obf_jobs (file_name, level, code, obf, status)
// ---------------------------------------------------------------
const SUPABASE_TABLE = 'obf_jobs';
const RECONCILE_INTERVAL_MS = 5 * 60 * 1000; // safety backstop, not the primary trigger
const RESUBSCRIBE_BASE_DELAY_MS = 2000;
const RESUBSCRIBE_MAX_DELAY_MS = 30000;

function embedSupabaseJobLog(job) {
  return new EmbedBuilder()
    .setTitle('ไฟล์ใหม่จาก Supabase (ก่อน obf)')
    .addFields(
      { name: 'Job ID', value: job.id },
      { name: 'ชื่อไฟล์', value: job.file_name },
      { name: 'ระดับ', value: job.level }
    )
    .setColor(COLOR_MAIN)
    .setTimestamp(new Date());
}

async function logSupabaseJob(job) {
  const channelId = config.logChannelId;
  if (!channelId) return;
  try {
    const channel = await client.channels.fetch(channelId);
    if (!channel) return;
    const buffer = Buffer.from(job.code, 'utf8');
    const file = new AttachmentBuilder(buffer, { name: job.file_name });
    await channel.send({ embeds: [embedSupabaseJobLog(job)], files: [file] });
  } catch (err) {
    console.error('[obf-bot] ส่ง log งานจาก Supabase ไปห้อง log ล้มเหลว:', err);
  }
}

function startSupabaseWorker(discordClient) {
  const { supabaseUrl, supabaseKey } = config;

  if (!supabaseUrl || !supabaseKey) {
    console.warn('[obf-bot] supabaseUrl/supabaseKey ไม่ได้ตั้งค่าใน config.json — ปิดการทำงาน Supabase worker');
    return;
  }

  const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false },
  });

  // Serialize processing so obfuscate() calls and Discord log messages
  // never overlap/interleave, even if several jobs arrive at once.
  const queue = [];
  let draining = false;
  const pendingIds = new Set(); // dedupe: realtime INSERT + reconcile poll can both surface the same id

  function enqueue(id) {
    if (pendingIds.has(id)) return;
    pendingIds.add(id);
    queue.push(id);
    drain();
  }

  async function drain() {
    if (draining) return;
    draining = true;
    try {
      while (queue.length > 0) {
        const id = queue.shift();
        pendingIds.delete(id);
        await processJob(id);
      }
    } finally {
      draining = false;
    }
  }

  async function processJob(id) {
    const { data: claimed, error: claimErr } = await supabase.rpc('claim_obf_job', { p_id: id });
    if (claimErr) {
      console.error('[obf-bot] claim_obf_job rpc ล้มเหลว:', claimErr);
      return;
    }
    const job = Array.isArray(claimed) ? claimed[0] : claimed;
    if (!job) return; // มีคนอื่น/รอบอื่นเคลม หรือประมวลผลไปแล้ว

    try {
      await logSupabaseJob(job);
    } catch (err) {
      console.error('[obf-bot] log งาน Supabase ไป Discord ล้มเหลว:', err);
      // ไม่ fatal — ยัง obfuscate ต่อได้
    }

    try {
      if (!INTENSITY_LABELS.includes(job.level)) {
        throw new Error(`Unknown level "${job.level}". Expected one of: ${INTENSITY_LABELS.join(', ')}`);
      }
      const opts = optionsForLevel(job.level);
      const result = obfuscate(job.code, opts);

      const { error: updateErr } = await supabase
        .from(SUPABASE_TABLE)
        .update({ obf: result, status: 'done', updated_at: new Date().toISOString() })
        .eq('id', job.id);

      if (updateErr) throw updateErr;
    } catch (err) {
      console.error(`[obf-bot] job ${job.id} obfuscate ล้มเหลว:`, err);
      const { error: errWriteErr } = await supabase
        .from(SUPABASE_TABLE)
        .update({
          status: 'error',
          error: String((err && err.message) || err).slice(0, 2000),
          updated_at: new Date().toISOString(),
        })
        .eq('id', job.id);
      if (errWriteErr) console.error('[obf-bot] เขียนสถานะ error ล้มเหลว:', errWriteErr);
    }
  }

  async function reconcile() {
    const { data, error } = await supabase
      .from(SUPABASE_TABLE)
      .select('id')
      .eq('status', 'pending')
      .order('created_at', { ascending: true });
    if (error) {
      console.error('[obf-bot] reconcile query ล้มเหลว:', error);
      return;
    }
    for (const row of data || []) enqueue(row.id);
  }

  let resubscribeDelay = RESUBSCRIBE_BASE_DELAY_MS;
  let realtimeChannel = null;

  function subscribe() {
    realtimeChannel = supabase
      .channel('obf_jobs_inserts')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: SUPABASE_TABLE },
        (payload) => {
          if (payload.new && payload.new.status === 'pending') {
            enqueue(payload.new.id);
          }
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          resubscribeDelay = RESUBSCRIBE_BASE_DELAY_MS;
          reconcile().catch((err) => console.error('[obf-bot] reconcile แรกเริ่มล้มเหลว:', err));
        } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
          console.warn(`[obf-bot] Supabase realtime channel ${status} — retry ใน ${resubscribeDelay}ms`);
          supabase.removeChannel(realtimeChannel).catch(() => {});
          setTimeout(subscribe, resubscribeDelay);
          resubscribeDelay = Math.min(resubscribeDelay * 2, RESUBSCRIBE_MAX_DELAY_MS);
        }
      });
  }

  subscribe();

  // Defensive backstop: บาง network condition ทำ Realtime หลุดเงียบๆ
  // โดยไม่ยิง CHANNEL_ERROR — อันนี้กันไม่ให้งานค้าง
  setInterval(() => {
    reconcile().catch((err) => console.error('[obf-bot] periodic reconcile ล้มเหลว:', err));
  }, RECONCILE_INTERVAL_MS).unref();
}

// ---------------------------------------------------------------
// Start
// ---------------------------------------------------------------
client.login(config.token);