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
  AttachmentBuilder,
  REST,
  Routes,
  SlashCommandBuilder,
  ChannelType,
  MessageFlags,
} = require("discord.js");

const { obfuscate, LEVELS, LEVEL_ORDER } = require("./obf");

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const CONFIG_PATH = path.join(__dirname, "config.json");
let config = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));

function saveConfig() {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2), "utf8");
}

const BRAND = "Luna | Obfuscator";
const COLOR = 0x8b5cf6;
const COLOR_ERR = 0xef4444;
const COLOR_OK = 0x22c55e;

// ---------------------------------------------------------------------------
// Permission helpers
// ---------------------------------------------------------------------------
function isOwner(id) {
  return Array.isArray(config.ownerIds) && config.ownerIds.includes(id);
}

// ระดับสูงสุดที่ user คนนี้ใช้ได้ (null = ไม่มีสิทธิ์เลย)
function getMaxLevel(id) {
  if (isOwner(id)) return "ENTERPRISE";
  if (config.publicMode) return config.publicDefaultLevel || "ENTERPRISE";
  const lvl = config.permissions ? config.permissions[id] : null;
  return LEVELS[lvl] ? lvl : null;
}

function canUseSystem(id) {
  return getMaxLevel(id) !== null;
}

function canUseLevel(id, level) {
  const max = getMaxLevel(id);
  if (!max) return false;
  return LEVEL_ORDER.indexOf(level) <= LEVEL_ORDER.indexOf(max);
}

// ---------------------------------------------------------------------------
// Embeds
// ---------------------------------------------------------------------------
function baseEmbed() {
  return new EmbedBuilder().setColor(COLOR).setAuthor({ name: BRAND });
}

function embedReceived(filename) {
  return baseEmbed()
    .setTitle("Obfuscator")
    .setDescription(
      `ได้รับไฟล์ **${filename}** แล้ว\nกรุณาเลือก **ระดับการ obfuscate** ด้านล่าง`
    );
}

function embedProcessing(filename, level) {
  return baseEmbed()
    .setTitle("Obfuscator")
    .setDescription(
      `กำลัง obfuscate **${filename}**\nระดับ: **${LEVELS[level].label}**`
    );
}

function embedDone(level) {
  return baseEmbed()
    .setColor(COLOR_OK)
    .setTitle("Obfuscator")
    .setDescription(`obfuscate เสร็จแล้ว\nระดับ **${LEVELS[level].label}**`);
}

function embedNoSystem() {
  return baseEmbed()
    .setColor(COLOR_ERR)
    .setDescription(
      "คุณไม่มีสิทธิ์ใช้งานระบบ Obfuscate นี้ กรุณาติดต่อผู้ดูแลเพื่อขอสิทธิ์"
    );
}

function embedNoLevel(level) {
  return baseEmbed()
    .setColor(COLOR_ERR)
    .setDescription(
      `คุณไม่มีสิทธิ์ใช้งานระดับ Obfuscate นี้ **${LEVELS[level].label}** กรุณาติดต่อผู้ดูแลเพื่อขอสิทธิ์`
    );
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------
const BUTTON_STYLE = {
  MINIMAL: ButtonStyle.Secondary,
  BASIC: ButtonStyle.Primary,
  PREMIUM: ButtonStyle.Primary,
  COMMERCIAL: ButtonStyle.Success,
  ENTERPRISE: ButtonStyle.Danger,
};

function levelButtons(jobId) {
  const row = new ActionRowBuilder();
  for (const level of LEVEL_ORDER) {
    row.addComponents(
      new ButtonBuilder()
        .setCustomId(`obf|${jobId}|${level}`)
        .setLabel(level)
        .setStyle(BUTTON_STYLE[level] || ButtonStyle.Secondary)
    );
  }
  return row;
}

// เก็บงานที่รอเลือกระดับ (jobId -> {url, filename, userId})
const jobs = new Map();

function newJobId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function outputName(filename) {
  const ext = path.extname(filename) || ".lua";
  const base = path.basename(filename, ext);
  return `${base}.obf${ext}`;
}

// ---------------------------------------------------------------------------
// Slash commands
// ---------------------------------------------------------------------------
const levelChoices = LEVEL_ORDER.map((l) => ({ name: l, value: l }));

const obfCommand = new SlashCommandBuilder()
  .setName("obf")
  .setDescription("จัดการระบบ Obfuscator (เฉพาะเจ้าของบอท)")
  .addSubcommand((sc) =>
    sc
      .setName("public")
      .setDescription("เปิด/ปิด โหมดสาธารณะ (ทุกคนใช้ได้)")
      .addBooleanOption((o) =>
        o.setName("enabled").setDescription("true = เปิด, false = ปิด").setRequired(true)
      )
  )
  .addSubcommand((sc) =>
    sc.setName("list").setDescription("ดูรายชื่อผู้ใช้และระดับสิทธิ์")
  )
  .addSubcommand((sc) =>
    sc
      .setName("adduser")
      .setDescription("เพิ่ม/แก้ไข สิทธิ์ผู้ใช้ พร้อมเลือกระดับ")
      .addUserOption((o) => o.setName("user").setDescription("ผู้ใช้").setRequired(true))
      .addStringOption((o) =>
        o
          .setName("level")
          .setDescription("ระดับสูงสุดที่อนุญาต")
          .setRequired(true)
          .addChoices(...levelChoices)
      )
  )
  .addSubcommand((sc) =>
    sc
      .setName("remove")
      .setDescription("ลบสิทธิ์ผู้ใช้ออกจากระบบ")
      .addUserOption((o) => o.setName("user").setDescription("ผู้ใช้").setRequired(true))
  );

async function registerCommands(clientId) {
  const rest = new REST({ version: "10" }).setToken(config.token);
  const body = [obfCommand.toJSON()];
  const guildIds = Array.isArray(config.guildIds) ? config.guildIds : [];
  for (const gid of guildIds) {
    try {
      await rest.put(Routes.applicationGuildCommands(clientId, gid), { body });
      console.log(`[Luna] ลงทะเบียนคำสั่งในเซิร์ฟเวอร์ ${gid} สำเร็จ`);
    } catch (e) {
      console.error(`[Luna] ลงทะเบียนคำสั่งในเซิร์ฟเวอร์ ${gid} ล้มเหลว:`, e.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.DirectMessages,
    GatewayIntentBits.MessageContent,
  ],
  partials: [Partials.Channel, Partials.Message],
});

client.once(Events.ClientReady, async (c) => {
  console.log(`[Luna] ล็อกอินเป็น ${c.user.tag}`);
  await registerCommands(config.clientId || c.user.id);
});

// รับไฟล์ทาง DM
client.on(Events.MessageCreate, async (message) => {
  try {
    if (message.partial) await message.fetch().catch(() => {});
    if (message.author?.bot) return;
    if (message.channel?.type !== ChannelType.DM) return;
    if (!message.attachments || message.attachments.size === 0) return;

    const attachment = message.attachments.first();
    const maxBytes = (config.maxFileSizeMB || 5) * 1024 * 1024;
    if (attachment.size > maxBytes) {
      await message.reply({
        embeds: [
          baseEmbed()
            .setColor(COLOR_ERR)
            .setDescription(`ไฟล์ใหญ่เกินไป (จำกัด ${config.maxFileSizeMB || 5} MB)`),
        ],
      });
      return;
    }

    const jobId = newJobId();
    jobs.set(jobId, {
      url: attachment.url,
      filename: attachment.name || "script.lua",
      userId: message.author.id,
    });

    // ล้าง job ที่ค้างเกิน 10 นาที
    setTimeout(() => jobs.delete(jobId), 10 * 60 * 1000).unref?.();

    await message.reply({
      embeds: [embedReceived(attachment.name || "script.lua")],
      components: [levelButtons(jobId)],
    });
  } catch (e) {
    console.error("[Luna] MessageCreate error:", e);
  }
});

// ปุ่มเลือกระดับ + คำสั่ง slash
client.on(Events.InteractionCreate, async (interaction) => {
  // ---------- ปุ่ม ----------
  if (interaction.isButton()) {
    const parts = interaction.customId.split("|");
    if (parts[0] !== "obf") return;
    const [, jobId, level] = parts;
    const uid = interaction.user.id;

    if (!canUseSystem(uid)) {
      await interaction.reply({ embeds: [embedNoSystem()], flags: MessageFlags.Ephemeral });
      return;
    }
    if (!canUseLevel(uid, level)) {
      await interaction.reply({ embeds: [embedNoLevel(level)], flags: MessageFlags.Ephemeral });
      return;
    }

    const job = jobs.get(jobId);
    if (!job) {
      await interaction.reply({
        embeds: [baseEmbed().setColor(COLOR_ERR).setDescription("งานนี้หมดอายุแล้ว กรุณาส่งไฟล์ใหม่อีกครั้ง")],
        flags: MessageFlags.Ephemeral,
      });
      return;
    }
    if (job.userId !== uid && !isOwner(uid)) {
      await interaction.reply({
        embeds: [baseEmbed().setColor(COLOR_ERR).setDescription("นี่ไม่ใช่ไฟล์ของคุณ")],
        flags: MessageFlags.Ephemeral,
      });
      return;
    }

    await interaction.update({
      embeds: [embedProcessing(job.filename, level)],
      components: [],
    });

    try {
      const res = await fetch(job.url);
      if (!res.ok) throw new Error("ดาวน์โหลดไฟล์ไม่สำเร็จ");
      const src = await res.text();
      const out = obfuscate(src, level);
      const file = new AttachmentBuilder(Buffer.from(out, "utf8"), {
        name: outputName(job.filename),
      });
      await interaction.editReply({ embeds: [embedDone(level)], files: [file] });
    } catch (e) {
      console.error("[Luna] Obfuscate error:", e);
      await interaction.editReply({
        embeds: [baseEmbed().setColor(COLOR_ERR).setDescription("เกิดข้อผิดพลาดระหว่าง obfuscate: " + e.message)],
      });
    } finally {
      jobs.delete(jobId);
    }
    return;
  }

  // ---------- คำสั่ง slash ----------
  if (interaction.isChatInputCommand()) {
    if (interaction.commandName !== "obf") return;

    if (!isOwner(interaction.user.id)) {
      await interaction.reply({ embeds: [embedNoSystem()], flags: MessageFlags.Ephemeral });
      return;
    }

    const sub = interaction.options.getSubcommand();

    if (sub === "public") {
      const enabled = interaction.options.getBoolean("enabled");
      config.publicMode = enabled;
      saveConfig();
      await interaction.reply({
        embeds: [
          baseEmbed()
            .setColor(COLOR_OK)
            .setDescription(`โหมดสาธารณะถูก **${enabled ? "เปิด" : "ปิด"}** แล้ว`),
        ],
        flags: MessageFlags.Ephemeral,
      });
      return;
    }

    if (sub === "list") {
      const perms = config.permissions || {};
      const entries = Object.entries(perms).filter(([, v]) => LEVELS[v]);
      const lines = entries.length
        ? entries.map(([id, lvl]) => `• <@${id}> — **${LEVELS[lvl].label}**`).join("\n")
        : "_ยังไม่มีผู้ใช้ในระบบ_";
      const owners = (config.ownerIds || []).map((id) => `<@${id}>`).join(", ") || "-";
      await interaction.reply({
        embeds: [
          baseEmbed()
            .setTitle("รายชื่อสิทธิ์ Obfuscator")
            .setDescription(
              `โหมดสาธารณะ: **${config.publicMode ? "เปิด" : "ปิด"}**\n` +
                `เจ้าของบอท: ${owners}\n\n**ผู้ใช้ที่ได้รับสิทธิ์:**\n${lines}`
            ),
        ],
        flags: MessageFlags.Ephemeral,
      });
      return;
    }

    if (sub === "adduser") {
      const user = interaction.options.getUser("user");
      const level = interaction.options.getString("level");
      if (!config.permissions) config.permissions = {};
      config.permissions[user.id] = level;
      saveConfig();
      await interaction.reply({
        embeds: [
          baseEmbed()
            .setColor(COLOR_OK)
            .setDescription(`เพิ่มสิทธิ์ให้ <@${user.id}> ระดับ **${LEVELS[level].label}** แล้ว`),
        ],
        flags: MessageFlags.Ephemeral,
      });
      return;
    }

    if (sub === "remove") {
      const user = interaction.options.getUser("user");
      if (config.permissions && config.permissions[user.id]) {
        delete config.permissions[user.id];
        saveConfig();
        await interaction.reply({
          embeds: [baseEmbed().setColor(COLOR_OK).setDescription(`ลบสิทธิ์ของ <@${user.id}> แล้ว`)],
          flags: MessageFlags.Ephemeral,
        });
      } else {
        await interaction.reply({
          embeds: [baseEmbed().setColor(COLOR_ERR).setDescription(`<@${user.id}> ไม่มีสิทธิ์อยู่ในระบบ`)],
          flags: MessageFlags.Ephemeral,
        });
      }
      return;
    }
  }
});

client.login(config.token);
