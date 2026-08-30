"use strict";

const fs = require("fs");
const path = require("path");
const {
  Client,
  GatewayIntentBits,
  Partials,
  Events,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  REST,
  Routes,
  SlashCommandBuilder,
  ApplicationCommandOptionType,
  AttachmentBuilder,
  Colors,
} = require("discord.js");

// ============================================================
// CONFIG
// ============================================================
const CONFIG_PATH = path.join(__dirname, "config.json");

function loadConfig() {
  const raw = fs.readFileSync(CONFIG_PATH, "utf8");
  const cfg = JSON.parse(raw);
  cfg.public = cfg.public ?? false;
  cfg.publicLevel = cfg.publicLevel ?? "BASIC";
  cfg.users = cfg.users ?? {};
  cfg.guildIds = cfg.guildIds ?? [];
  return cfg;
}

function saveConfig(cfg) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(cfg, null, 2), "utf8");
}

let config = loadConfig();

// ============================================================
// TIER SYSTEM (สะสม / cumulative)
// ============================================================
const TIERS = ["MINIMAL", "BASIC", "PREMIUM", "COMMERCIAL", "ENTERPRISE"];

// ป้ายกำกับความแรงของแต่ละระดับ (ใช้แสดงใน embed)
const STRENGTH_LABEL = {
  MINIMAL: "Weak",
  BASIC: "Light",
  PREMIUM: "Strong",
  COMMERCIAL: "Very Strong",
  ENTERPRISE: "Maximum",
};

function tierIndex(level) {
  return TIERS.indexOf(level);
}

// ระดับสูงสุดที่ user มีสิทธิ์ใช้ (null = ไม่มีสิทธิ์เลย)
function userMaxTier(userId) {
  if (userId === config.ownerId) return "ENTERPRISE";
  if (config.users && config.users[userId]) return config.users[userId];
  if (config.public) return config.publicLevel || "BASIC";
  return null;
}

function hasSystemAccess(userId) {
  return userMaxTier(userId) !== null;
}

// ระบบสะสม: มีระดับ X = ใช้ได้ทุกระดับที่ <= X
function canUseLevel(userId, level) {
  const max = userMaxTier(userId);
  if (!max) return false;
  return tierIndex(level) <= tierIndex(max);
}

// ============================================================
// LUA / LUAU OBFUSCATOR
// ============================================================
function randName(len = 8) {
  const first = "abcdefghijklmnopqrstuvwxyz";
  const all = first + "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
  let s = first[Math.floor(Math.random() * first.length)];
  for (let i = 1; i < len; i++) {
    s += all[Math.floor(Math.random() * all.length)];
  }
  return s;
}

// สร้างโค้ด junk ที่ไม่กระทบการทำงาน
function junkBlock(count = 3) {
  let out = "";
  for (let i = 0; i < count; i++) {
    const t = Math.floor(Math.random() * 3);
    if (t === 0) {
      out += `local ${randName()}=${Math.floor(Math.random() * 999999)}\n`;
    } else if (t === 1) {
      out += `local ${randName()}=function() return ${Math.floor(Math.random() * 9999)} end\n`;
    } else {
      out += `local ${randName()}="${randName(Math.floor(Math.random() * 10) + 4)}"\n`;
    }
  }
  return out;
}

// เลเยอร์ escape ธรรมดา (decimal escape) — ใช้กับ MINIMAL
function escapeLoader(src) {
  const bytes = Array.from(Buffer.from(src, "utf8"));
  const esc = bytes.map((b) => "\\" + b).join("");
  const vL = randName();
  return `local ${vL}=load or loadstring\nreturn ${vL}("${esc}")()`;
}

// เลเยอร์ cipher (additive + rotating key) — ทำงานได้ทั้ง Lua 5.1 / 5.3 / Luau
function cipherLoader(src, { junk = false } = {}) {
  const bytes = Array.from(Buffer.from(src, "utf8"));
  const key = 1 + Math.floor(Math.random() * 250);
  const rot = 7;
  // encode: (b + key + (i % rot)) % 256   (i = 0-based)
  const enc = bytes.map((b, i) => (b + key + (i % rot)) % 256);

  const vL = randName();
  const vK = randName();
  const vD = randName();
  const vS = randName();
  const vI = randName();

  const data = enc.join(",");
  const junkTop = junk ? junkBlock(3) : "";
  const junkMid = junk ? junkBlock(2) : "";

  return (
    `local ${vL}=load or loadstring\n` +
    junkTop +
    `local ${vK}=${key}\n` +
    `local ${vD}={${data}}\n` +
    junkMid +
    `local ${vS}={}\n` +
    `for ${vI}=1,#${vD} do ${vS}[${vI}]=string.char((${vD}[${vI}]-${vK}-((${vI}-1)%${rot}))%256) end\n` +
    `return ${vL}(table.concat(${vS}))()`
  );
}

/**
 * Obfuscate ตามระดับ (แบบสะสมชั้น)
 *  MINIMAL     -> escape 1 ชั้น
 *  BASIC       -> cipher 1 ชั้น
 *  PREMIUM     -> cipher 2 ชั้น + junk
 *  COMMERCIAL  -> cipher 3 ชั้น + junk
 *  ENTERPRISE  -> cipher 4 ชั้น + junk
 */
function obfuscate(src, level) {
  const header = `--[[ Protected by Luna Obfuscator | Level: ${level} ]]\n`;
  let out;
  switch (level) {
    case "MINIMAL":
      out = escapeLoader(src);
      break;
    case "BASIC":
      out = cipherLoader(src, { junk: false });
      break;
    case "PREMIUM":
      out = src;
      for (let i = 0; i < 2; i++) out = cipherLoader(out, { junk: true });
      break;
    case "COMMERCIAL":
      out = src;
      for (let i = 0; i < 3; i++) out = cipherLoader(out, { junk: true });
      break;
    case "ENTERPRISE":
      out = src;
      for (let i = 0; i < 4; i++) out = cipherLoader(out, { junk: true });
      break;
    default:
      out = cipherLoader(src, { junk: false });
  }
  return header + out;
}

// ============================================================
// EMBED HELPERS
// ============================================================
const BRAND = "Luna | Obfuscator";

function baseEmbed() {
  return new EmbedBuilder().setColor(0x8b5cf6).setFooter({ text: BRAND });
}

function noSystemAccessEmbed() {
  return new EmbedBuilder()
    .setColor(0xed4245)
    .setTitle(BRAND)
    .setDescription(
      "คุณไม่มีสิทธิ์ใช้งานระบบ Obfuscate นี้ กรุณาติดต่อผู้ดูแลเพื่อขอสิทธิ์"
    );
}

function noLevelAccessEmbed(level) {
  return new EmbedBuilder()
    .setColor(0xed4245)
    .setTitle(BRAND)
    .setDescription(
      `คุณไม่มีสิทธิ์ใช้งานระดับ Obfuscate นี้ **${level}** กรุณาติดต่อผู้ดูแลเพื่อขอสิทธิ์`
    );
}

// ============================================================
// PENDING FILE STATE (ต่อผู้ใช้)
// ============================================================
// userId -> { fileName, url, size }
const pending = new Map();

const MAX_SIZE = 5 * 1024 * 1024; // 5MB
const ALLOWED_EXT = [".lua", ".luau", ".txt"];

function isLuaFile(name) {
  const lower = name.toLowerCase();
  return ALLOWED_EXT.some((ext) => lower.endsWith(ext));
}

function buildLevelButtons(userId) {
  const row1 = new ActionRowBuilder();
  const row2 = new ActionRowBuilder();
  TIERS.forEach((lvl, idx) => {
    const btn = new ButtonBuilder()
      .setCustomId(`obf_level:${userId}:${lvl}`)
      .setLabel(lvl)
      .setStyle(canUseLevel(userId, lvl) ? ButtonStyle.Primary : ButtonStyle.Secondary);
    if (idx < 3) row1.addComponents(btn);
    else row2.addComponents(btn);
  });
  return [row1, row2];
}

// ============================================================
// DISCORD CLIENT
// ============================================================
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.DirectMessages,
    GatewayIntentBits.MessageContent,
  ],
  partials: [Partials.Channel, Partials.Message],
});

// ------------------------------------------------------------
// Slash commands
// ------------------------------------------------------------
function buildCommands() {
  const obf = new SlashCommandBuilder()
    .setName("obf")
    .setDescription("จัดการระบบ Obfuscate (เฉพาะเจ้าของบอท)")
    .addSubcommand((sub) =>
      sub
        .setName("public")
        .setDescription("เปิด/ปิด โหมด public (ทุกคนใช้งานได้)")
        .addBooleanOption((opt) =>
          opt.setName("value").setDescription("true = เปิด, false = ปิด").setRequired(true)
        )
    )
    .addSubcommand((sub) =>
      sub.setName("list").setDescription("ดูรายชื่อผู้ใช้และระดับสิทธิ์ทั้งหมด")
    )
    .addSubcommand((sub) =>
      sub
        .setName("adduser")
        .setDescription("เพิ่ม/แก้ไข สิทธิ์ผู้ใช้ พร้อมเลือกระดับ")
        .addUserOption((opt) =>
          opt.setName("user").setDescription("ผู้ใช้ที่จะให้สิทธิ์").setRequired(true)
        )
        .addStringOption((opt) =>
          opt
            .setName("level")
            .setDescription("ระดับสูงสุดที่อนุญาต (แบบสะสม)")
            .setRequired(true)
            .addChoices(...TIERS.map((t) => ({ name: t, value: t })))
        )
    )
    .addSubcommand((sub) =>
      sub
        .setName("addremove")
        .setDescription("ลบสิทธิ์ผู้ใช้ออกจากระบบ")
        .addUserOption((opt) =>
          opt.setName("user").setDescription("ผู้ใช้ที่จะลบสิทธิ์").setRequired(true)
        )
    );

  return [obf.toJSON()];
}

async function registerCommands() {
  const rest = new REST({ version: "10" }).setToken(config.token);
  const commands = buildCommands();
  const guildIds = (config.guildIds || []).filter(
    (g) => g && !g.includes("ใส่")
  );

  if (guildIds.length === 0) {
    console.log("[WARN] ไม่มี guildIds ใน config.json — ข้ามการลงทะเบียนคำสั่ง");
    return;
  }

  for (const gid of guildIds) {
    try {
      await rest.put(Routes.applicationGuildCommands(config.clientId, gid), {
        body: commands,
      });
      console.log(`[OK] ลงทะเบียนคำสั่งใน guild ${gid} สำเร็จ`);
    } catch (err) {
      console.error(`[ERR] ลงทะเบียนคำสั่งใน guild ${gid} ล้มเหลว:`, err.message);
    }
  }
}

// ------------------------------------------------------------
// Ready
// ------------------------------------------------------------
client.once(Events.ClientReady, async (c) => {
  console.log(`[READY] เข้าสู่ระบบเป็น ${c.user.tag}`);
  await registerCommands();
});

// ------------------------------------------------------------
// DM: รับไฟล์ -> ถามระดับ
// ------------------------------------------------------------
client.on(Events.MessageCreate, async (message) => {
  try {
    if (message.author.bot) return;
    // เฉพาะ DM เท่านั้น
    if (message.guild) return;

    if (message.attachments.size === 0) return;

    // ตรวจสิทธิ์เข้าระบบก่อน
    if (!hasSystemAccess(message.author.id)) {
      await message.reply({ embeds: [noSystemAccessEmbed()] });
      return;
    }

    const attachment = message.attachments.first();

    if (!isLuaFile(attachment.name)) {
      await message.reply({
        embeds: [
          baseEmbed()
            .setTitle("Obfuscator")
            .setDescription(
              "รองรับเฉพาะไฟล์ **.lua**, **.luau** หรือ **.txt** เท่านั้น"
            ),
        ],
      });
      return;
    }

    if (attachment.size > MAX_SIZE) {
      await message.reply({
        embeds: [
          baseEmbed()
            .setTitle("Obfuscator")
            .setDescription("ไฟล์ใหญ่เกินไป (จำกัดที่ 5MB)"),
        ],
      });
      return;
    }

    // เก็บ state
    pending.set(message.author.id, {
      fileName: attachment.name,
      url: attachment.url,
      size: attachment.size,
    });

    const embed = baseEmbed()
      .setTitle("Obfuscator")
      .setDescription(
        `ได้รับไฟล์ **${attachment.name}** แล้ว\nกรุณาเลือก **ระดับการ obfuscate** ด้านล่าง`
      );

    await message.reply({
      embeds: [embed],
      components: buildLevelButtons(message.author.id),
    });
  } catch (err) {
    console.error("[ERR] messageCreate:", err);
  }
});

// ------------------------------------------------------------
// Interaction: ปุ่มเลือกระดับ + slash commands
// ------------------------------------------------------------
client.on(Events.InteractionCreate, async (interaction) => {
  try {
    // ---------- ปุ่มเลือกระดับ ----------
    if (interaction.isButton()) {
      const [prefix, ownerId, level] = interaction.customId.split(":");
      if (prefix !== "obf_level") return;

      // เฉพาะเจ้าของ interaction เท่านั้น
      if (interaction.user.id !== ownerId) {
        await interaction.reply({
          content: "ปุ่มนี้ไม่ใช่ของคุณ",
          ephemeral: true,
        });
        return;
      }

      // ตรวจสิทธิ์ระดับ
      if (!canUseLevel(interaction.user.id, level)) {
        await interaction.reply({ embeds: [noLevelAccessEmbed(level)] });
        return;
      }

      const state = pending.get(interaction.user.id);
      if (!state) {
        await interaction.reply({
          embeds: [
            baseEmbed()
              .setTitle("Obfuscator")
              .setDescription("ไม่พบไฟล์ค้างในระบบ กรุณาส่งไฟล์ใหม่อีกครั้ง"),
          ],
        });
        return;
      }

      const strength = STRENGTH_LABEL[level] || level;

      // แจ้งกำลัง obfuscate
      await interaction.update({
        embeds: [
          baseEmbed()
            .setTitle("Obfuscator")
            .setDescription(
              `กำลัง obfuscate **${state.fileName}**\nระดับ: **${strength}**`
            ),
        ],
        components: [],
      });

      // ดาวน์โหลดไฟล์
      let sourceCode;
      try {
        const res = await fetch(state.url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        sourceCode = await res.text();
      } catch (err) {
        await interaction.editReply({
          embeds: [
            baseEmbed()
              .setColor(0xed4245)
              .setTitle("Obfuscator")
              .setDescription("ดาวน์โหลดไฟล์ไม่สำเร็จ กรุณาลองใหม่"),
          ],
        });
        pending.delete(interaction.user.id);
        return;
      }

      // obfuscate
      let obfCode;
      try {
        obfCode = obfuscate(sourceCode, level);
      } catch (err) {
        console.error("[ERR] obfuscate:", err);
        await interaction.editReply({
          embeds: [
            baseEmbed()
              .setColor(0xed4245)
              .setTitle("Obfuscator")
              .setDescription("เกิดข้อผิดพลาดระหว่าง obfuscate"),
          ],
        });
        pending.delete(interaction.user.id);
        return;
      }

      // ตั้งชื่อไฟล์ผลลัพธ์
      const dot = state.fileName.lastIndexOf(".");
      const baseName = dot > 0 ? state.fileName.slice(0, dot) : state.fileName;
      const ext = dot > 0 ? state.fileName.slice(dot) : ".lua";
      const outName = `${baseName}_obf${ext}`;

      const file = new AttachmentBuilder(Buffer.from(obfCode, "utf8"), {
        name: outName,
      });

      const doneEmbed = baseEmbed()
        .setColor(0x57f287)
        .setTitle("Obfuscator")
        .setDescription("obfuscate เสร็จแล้ว")
        .addFields(
          { name: "ระดับ", value: strength, inline: true },
          { name: "ไฟล์", value: state.fileName, inline: true }
        );

      await interaction.followUp({ embeds: [doneEmbed], files: [file] });
      pending.delete(interaction.user.id);
      return;
    }

    // ---------- Slash commands ----------
    if (interaction.isChatInputCommand()) {
      if (interaction.commandName !== "obf") return;

      // เฉพาะเจ้าของบอทเท่านั้น
      if (interaction.user.id !== config.ownerId) {
        await interaction.reply({
          embeds: [
            baseEmbed()
              .setColor(0xed4245)
              .setTitle(BRAND)
              .setDescription("คำสั่งนี้ใช้ได้เฉพาะเจ้าของบอทเท่านั้น"),
          ],
          ephemeral: true,
        });
        return;
      }

      const sub = interaction.options.getSubcommand();

      if (sub === "public") {
        const value = interaction.options.getBoolean("value");
        config.public = value;
        saveConfig(config);
        await interaction.reply({
          embeds: [
            baseEmbed()
              .setTitle("Obfuscator")
              .setDescription(
                `โหมด public ถูก **${value ? "เปิด" : "ปิด"}** แล้ว` +
                  (value ? `\nระดับเริ่มต้นสำหรับ public: **${config.publicLevel}**` : "")
              ),
          ],
          ephemeral: true,
        });
        return;
      }

      if (sub === "list") {
        const entries = Object.entries(config.users || {});
        let desc = `**โหมด public:** ${config.public ? "เปิด" : "ปิด"} (ระดับ ${config.publicLevel})\n`;
        desc += `**เจ้าของบอท:** <@${config.ownerId}> (ENTERPRISE)\n\n`;
        if (entries.length === 0) {
          desc += "ยังไม่มีผู้ใช้ที่ได้รับสิทธิ์เพิ่มเติม";
        } else {
          desc += "**รายชื่อผู้ใช้:**\n";
          desc += entries
            .map(([uid, lvl]) => `• <@${uid}> — **${lvl}**`)
            .join("\n");
        }
        await interaction.reply({
          embeds: [baseEmbed().setTitle("Obfuscator — รายชื่อสิทธิ์").setDescription(desc)],
          ephemeral: true,
        });
        return;
      }

      if (sub === "adduser") {
        const user = interaction.options.getUser("user");
        const level = interaction.options.getString("level");
        config.users[user.id] = level;
        saveConfig(config);
        await interaction.reply({
          embeds: [
            baseEmbed()
              .setColor(0x57f287)
              .setTitle("Obfuscator")
              .setDescription(
                `เพิ่มสิทธิ์ให้ <@${user.id}> ระดับ **${level}** แล้ว\n(ใช้ได้ทุกระดับตั้งแต่ MINIMAL ถึง ${level})`
              ),
          ],
          ephemeral: true,
        });
        return;
      }

      if (sub === "addremove") {
        const user = interaction.options.getUser("user");
        if (config.users[user.id]) {
          delete config.users[user.id];
          saveConfig(config);
          await interaction.reply({
            embeds: [
              baseEmbed()
                .setColor(0xed4245)
                .setTitle("Obfuscator")
                .setDescription(`ลบสิทธิ์ของ <@${user.id}> ออกจากระบบแล้ว`),
            ],
            ephemeral: true,
          });
        } else {
          await interaction.reply({
            embeds: [
              baseEmbed()
                .setTitle("Obfuscator")
                .setDescription(`<@${user.id}> ไม่มีสิทธิ์ในระบบอยู่แล้ว`),
            ],
            ephemeral: true,
          });
        }
        return;
      }
    }
  } catch (err) {
    console.error("[ERR] interaction:", err);
    if (interaction.isRepliable() && !interaction.replied && !interaction.deferred) {
      try {
        await interaction.reply({ content: "เกิดข้อผิดพลาด", ephemeral: true });
      } catch (_) {}
    }
  }
});

// ============================================================
// LOGIN
// ============================================================
if (!config.token || config.token.includes("ใส่")) {
  console.error("[FATAL] กรุณาใส่ token ใน config.json ก่อนรันบอท");
  process.exit(1);
}

client.login(config.token);
