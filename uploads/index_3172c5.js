const {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  SlashCommandBuilder,
  EmbedBuilder,
  MessageFlags,
} = require("discord.js")
const {
  joinVoiceChannel,
  createAudioPlayer,
  createAudioResource,
  AudioPlayerStatus,
  VoiceConnectionStatus,
  NoSubscriberBehavior,
  StreamType,
  entersState,
  getVoiceConnection,
} = require("@discordjs/voice")
const ytdl = require("@distube/ytdl-core")
const YouTube = require("youtube-sr").default
const config = require("./config.json")

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates],
})

// สร้าง agent สำหรับ ytdl (ถ้ามี cookies ใน config จะช่วยเลี่ยงการโดนบล็อกได้ดีขึ้น)
const ytdlAgent = config.cookies && config.cookies.length ? ytdl.createAgent(config.cookies) : undefined
if (ytdlAgent) {
  console.log(`🍪 โหลด cookies สำเร็จ (${config.cookies.length} รายการ) ใช้เลี่ยงการโดน YouTube บล็อก`)
} else {
  console.warn("⚠️ ไม่พบ cookies ใน config.json อาจโดน YouTube บล็อก (Sign in to confirm you're not a bot)")
}

// ===== กัน process แครชจาก error ที่หลุดมา (สำคัญมากสำหรับโฮสต์) =====
process.on("unhandledRejection", (err) => {
  console.error("Unhandled rejection:", err?.message || err)
})
process.on("uncaughtException", (err) => {
  console.error("Uncaught exception:", err?.message || err)
})

// ===== ระบบคิวเพลง (แยกตามกิล) =====
// guildId -> { connection, player, songs: [], playing: bool, loop: bool, textChannel }
const queues = new Map()

// ===== แก้ปัญหาโฮสต์บล็อกพอร์ต voice (2083, 2087 ฯลฯ) =====
// Discord ส่ง endpoint มาเป็นพอร์ตแปลกๆ ซึ่งโฮสต์ส่วนใหญ่บล็อก
// เลยบังคับให้ต่อผ่านพอร์ต 443 แทน (Discord รองรับ)
function createFixedAdapter(guild) {
  return (methods) =>
    guild.voiceAdapterCreator({
      ...methods,
      onVoiceServerUpdate: (data) => {
        if (data?.endpoint) {
          data = { ...data, endpoint: data.endpoint.replace(/:\d+$/, ":443") }
        }
        return methods.onVoiceServerUpdate(data)
      },
    })
}

// ===== คำสั่งทั้งหมด =====
const commands = [
  new SlashCommandBuilder()
    .setName("play")
    .setDescription("เล่นเพลงจากชื่อเพลงหรือลิ้งค์ YouTube")
    .addStringOption((opt) =>
      opt.setName("song").setDescription("ชื่อเพลง หรือ ลิ้งค์ YouTube").setRequired(true),
    ),
  new SlashCommandBuilder().setName("skip").setDescription("ข้ามเพลงปัจจุบัน"),
  new SlashCommandBuilder().setName("stop").setDescription("หยุดเล่นและล้างคิวทั้งหมด"),
  new SlashCommandBuilder().setName("pause").setDescription("หยุดเพลงชั่วคราว"),
  new SlashCommandBuilder().setName("resume").setDescription("เล่นเพลงต่อ"),
  new SlashCommandBuilder().setName("queue").setDescription("ดูคิวเพลง"),
  new SlashCommandBuilder().setName("nowplaying").setDescription("ดูเพลงที่กำลังเล่นอยู่"),
  new SlashCommandBuilder().setName("loop").setDescription("เปิด/ปิด เล่นวนเพลงปัจจุบัน"),
  new SlashCommandBuilder().setName("leave").setDescription("ให้บอทออกจากห้องเสียง"),
].map((c) => c.toJSON())

// ตอบกลับแบบ ephemeral (ใช้ flags แทน ephemeral ที่ deprecated แล้ว)
function ephemeralReply(interaction, content) {
  return interaction.reply({ content, flags: MessageFlags.Ephemeral })
}

// ===== ลงทะเบียนคำสั่งแบบรายกิล (มีผลทันที ไม่ต้องรอ 1 ชม.) =====
async function registerCommandsForGuild(rest, appId, guildId, guildName) {
  try {
    await rest.put(Routes.applicationGuildCommands(appId, guildId), { body: commands })
    console.log(`✅ ลงทะเบียนคำสั่งในกิล: ${guildName} (${guildId})`)
  } catch (err) {
    console.error(`❌ ลงทะเบียนคำสั่งไม่สำเร็จในกิล ${guildId}:`, err.message)
  }
}

client.once("clientReady", async () => {
  console.log(`🤖 บอทออนไลน์แล้ว: ${client.user.tag}`)

  const rest = new REST({ version: "10" }).setToken(config.token)
  const appId = client.user.id

  const guilds = [...client.guilds.cache.values()]
  console.log(`📋 พบ ${guilds.length} กิล กำลังลงทะเบียนคำสั่ง...`)
  for (const guild of guilds) {
    await registerCommandsForGuild(rest, appId, guild.id, guild.name)
  }
  console.log("🎉 ลงทะเบียนคำสั่งครบทุกกิลแล้ว!")
})

// ถ้าบอทถูกเชิญเข้ากิลใหม่ ลงทะเบียนคำสั่งให้ทันที
client.on("guildCreate", async (guild) => {
  const rest = new REST({ version: "10" }).setToken(config.token)
  await registerCommandsForGuild(rest, client.user.id, guild.id, guild.name)
})

// แปลงวินาทีเป็น mm:ss หรือ hh:mm:ss
function formatDuration(seconds) {
  const s = Number(seconds)
  if (!s || isNaN(s)) return "ไม่ทราบ"
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  const pad = (n) => String(n).padStart(2, "0")
  return h > 0 ? `${h}:${pad(m)}:${pad(sec)}` : `${m}:${pad(sec)}`
}

// ===== ฟังก์ชันเล่นเพลง =====
async function playSong(guildId) {
  const queue = queues.get(guildId)
  if (!queue) return

  const song = queue.songs[0]
  if (!song) {
    queue.playing = false
    // ไม่มีเพลงในคิวแล้ว รอ 3 นาทีแล้วออกจากห้อง
    queue.leaveTimeout = setTimeout(() => {
      const conn = getVoiceConnection(guildId)
      if (conn) conn.destroy()
      queues.delete(guildId)
    }, 3 * 60 * 1000)
    return
  }

  if (queue.leaveTimeout) {
    clearTimeout(queue.leaveTimeout)
    queue.leaveTimeout = null
  }

  try {
    const stream = ytdl(song.url, {
      filter: "audioonly",
      quality: "highestaudio",
      highWaterMark: 1 << 25,
      dlChunkSize: 0,
      agent: ytdlAgent,
    })

    // กัน stream error ทำบอทแครช
    stream.on("error", (err) => {
      console.error("Stream error:", err.message)
    })

    const resource = createAudioResource(stream, {
      inputType: StreamType.Arbitrary,
    })
    queue.player.play(resource)
    queue.playing = true

    const embed = new EmbedBuilder()
      .setColor(0x1db954)
      .setTitle("🎶 กำลังเล่นเพลง")
      .setDescription(`**[${song.title}](${song.url})**`)
      .addFields(
        { name: "⏱️ ความยาว", value: song.duration || "ไม่ทราบ", inline: true },
        { name: "🙋 ขอโดย", value: song.requestedBy, inline: true },
      )
    if (song.thumbnail) embed.setThumbnail(song.thumbnail)
    queue.textChannel?.send({ embeds: [embed] }).catch(() => {})
  } catch (err) {
    console.error("เล่นเพลงไม่สำเร็จ:", err.message)
    queue.textChannel?.send(`❌ เล่นเพลง **${song.title}** ไม่ได้ ข้ามไปเพลงถัดไป...`).catch(() => {})
    queue.songs.shift()
    playSong(guildId)
  }
}

// ===== ค้นหาเพลง (รองรับทั้งลิ้งค์และชื่อเพลง) =====
async function findSong(query, requestedBy) {
  // ถ้าเป็นลิ้งค์ YouTube ใช้ ytdl ดึงข้อมูลโดยตรง
  if (ytdl.validateURL(query)) {
    const info = await ytdl.getBasicInfo(query, { agent: ytdlAgent })
    const v = info.videoDetails
    return {
      title: v.title,
      url: v.video_url,
      duration: formatDuration(v.lengthSeconds),
      thumbnail: v.thumbnails?.[0]?.url,
      requestedBy,
    }
  }

  // ค้นหาด้วยชื่อเพลงผ่าน youtube-sr (ไม่ต้องล็อกอิน ไม่โดนบล็อก)
  const result = await YouTube.searchOne(query, "video")
  if (!result) return null
  return {
    title: result.title,
    url: result.url,
    duration: result.durationFormatted || "ไม่ทราบ",
    thumbnail: result.thumbnail?.url,
    requestedBy,
  }
}

// ===== จัดการคำสั่ง =====
client.on("interactionCreate", async (interaction) => {
  if (!interaction.isChatInputCommand()) return

  const { commandName, guildId } = interaction
  const queue = queues.get(guildId)
  const memberVoice = interaction.member?.voice?.channel

  try {
    switch (commandName) {
      case "play": {
        if (!memberVoice) {
          return ephemeralReply(interaction, "❌ คุณต้องเข้าห้องเสียงก่อน!")
        }

        await interaction.deferReply()

        const query = interaction.options.getString("song")
        const song = await findSong(query, interaction.user.username)

        if (!song) {
          return interaction.editReply("❌ หาเพลงไม่เจอ ลองใหม่อีกครั้ง")
        }

        let q = queues.get(guildId)
        if (!q) {
          const connection = joinVoiceChannel({
            channelId: memberVoice.id,
            guildId,
            // ใช้ adapter ที่บังคับพอร์ต 443 แก้ปัญหาโฮสต์บล็อกพอร์ต voice
            adapterCreator: createFixedAdapter(interaction.guild),
          })

          const player = createAudioPlayer({
            behaviors: { noSubscriber: NoSubscriberBehavior.Pause },
          })
          connection.subscribe(player)

          q = {
            connection,
            player,
            songs: [],
            playing: false,
            loop: false,
            textChannel: interaction.channel,
            leaveTimeout: null,
          }
          queues.set(guildId, q)

          // เมื่อเพลงจบ เล่นเพลงถัดไป
          player.on(AudioPlayerStatus.Idle, () => {
            const cur = queues.get(guildId)
            if (!cur) return
            if (!cur.loop) cur.songs.shift()
            playSong(guildId)
          })

          player.on("error", (err) => {
            console.error("Player error:", err.message)
            const cur = queues.get(guildId)
            if (cur) {
              cur.songs.shift()
              playSong(guildId)
            }
          })

          // สำคัญ! กัน error จาก voice connection ทำบอทแครช (ECONNREFUSED ฯลฯ)
          connection.on("error", (err) => {
            console.error("Voice connection error:", err.message)
          })

          // ถ้าหลุดจากห้องเสียง พยายามต่อใหม่ ถ้าไม่ได้ให้ล้างคิว
          connection.on(VoiceConnectionStatus.Disconnected, async () => {
            try {
              await Promise.race([
                entersState(connection, VoiceConnectionStatus.Signalling, 5_000),
                entersState(connection, VoiceConnectionStatus.Connecting, 5_000),
              ])
            } catch {
              try {
                connection.destroy()
              } catch {}
              queues.delete(guildId)
            }
          })

          // รอให้ต่อ voice สำเร็จก่อน (สูงสุด 20 วิ) ถ้าไม่ได้แจ้งผู้ใช้
          try {
            await entersState(connection, VoiceConnectionStatus.Ready, 20_000)
          } catch {
            try {
              connection.destroy()
            } catch {}
            queues.delete(guildId)
            return interaction.editReply(
              "❌ เชื่อมต่อห้องเสียงไม่สำเร็จ (โฮสต์อาจบล็อกการเชื่อมต่อ) ลองใหม่อีกครั้ง",
            )
          }
        }

        q.textChannel = interaction.channel
        q.songs.push(song)

        if (!q.playing) {
          playSong(guildId)
          return interaction.editReply(`✅ เริ่มเล่น: **${song.title}**`)
        }
        return interaction.editReply(`➕ เพิ่มเข้าคิวแล้ว (ลำดับที่ ${q.songs.length - 1}): **${song.title}**`)
      }

      case "skip": {
        if (!queue || !queue.playing) {
          return ephemeralReply(interaction, "❌ ไม่มีเพลงกำลังเล่นอยู่")
        }
        queue.loop = false
        queue.player.stop() // จะ trigger Idle แล้วเล่นเพลงถัดไปเอง
        return interaction.reply("⏭️ ข้ามเพลงแล้ว!")
      }

      case "stop": {
        if (!queue) {
          return ephemeralReply(interaction, "❌ ไม่มีเพลงกำลังเล่นอยู่")
        }
        queue.songs = []
        queue.loop = false
        queue.player.stop()
        try {
          queue.connection.destroy()
        } catch {}
        queues.delete(guildId)
        return interaction.reply("⏹️ หยุดเล่นและล้างคิวเรียบร้อย!")
      }

      case "pause": {
        if (!queue || !queue.playing) {
          return ephemeralReply(interaction, "❌ ไม่มีเพลงกำลังเล่นอยู่")
        }
        queue.player.pause()
        return interaction.reply("⏸️ หยุดเพลงชั่วคราวแล้ว")
      }

      case "resume": {
        if (!queue) {
          return ephemeralReply(interaction, "❌ ไม่มีเพลงในคิว")
        }
        queue.player.unpause()
        return interaction.reply("▶️ เล่นเพลงต่อแล้ว")
      }

      case "queue": {
        if (!queue || queue.songs.length === 0) {
          return ephemeralReply(interaction, "📭 คิวว่างเปล่า")
        }
        const list = queue.songs
          .slice(0, 10)
          .map((s, i) => (i === 0 ? `🎶 **กำลังเล่น:** ${s.title}` : `**${i}.** ${s.title}`))
          .join("\n")
        const more = queue.songs.length > 10 ? `\n...และอีก ${queue.songs.length - 10} เพลง` : ""
        const embed = new EmbedBuilder().setColor(0x1db954).setTitle("📋 คิวเพลง").setDescription(list + more)
        return interaction.reply({ embeds: [embed] })
      }

      case "nowplaying": {
        if (!queue || !queue.songs[0]) {
          return ephemeralReply(interaction, "❌ ไม่มีเพลงกำลังเล่นอยู่")
        }
        const s = queue.songs[0]
        const embed = new EmbedBuilder()
          .setColor(0x1db954)
          .setTitle("🎶 กำลังเล่นอยู่ตอนนี้")
          .setDescription(`**[${s.title}](${s.url})**`)
          .addFields(
            { name: "⏱️ ความยาว", value: s.duration || "ไม่ทราบ", inline: true },
            { name: "🙋 ขอโดย", value: s.requestedBy, inline: true },
            { name: "🔁 เล่นวน", value: queue.loop ? "เปิด" : "ปิด", inline: true },
          )
        if (s.thumbnail) embed.setThumbnail(s.thumbnail)
        return interaction.reply({ embeds: [embed] })
      }

      case "loop": {
        if (!queue) {
          return ephemeralReply(interaction, "❌ ไม่มีเพลงกำลังเล่นอยู่")
        }
        queue.loop = !queue.loop
        return interaction.reply(queue.loop ? "🔁 เปิดเล่นวนเพลงปัจจุบันแล้ว" : "➡️ ปิดเล่นวนแล้ว")
      }

      case "leave": {
        const conn = getVoiceConnection(guildId)
        if (!conn) {
          return ephemeralReply(interaction, "❌ บอทไม่ได้อยู่ในห้องเสียง")
        }
        conn.destroy()
        queues.delete(guildId)
        return interaction.reply("👋 ออกจากห้องเสียงแล้ว บายจ้า~")
      }
    }
  } catch (err) {
    console.error("Command error:", err)
    let msg = "❌ เกิดข้อผิดพลาด ลองใหม่อีกครั้ง"
    if (err?.message?.includes("Sign in to confirm")) {
      msg = "❌ YouTube บล็อกการเข้าถึง (โดนตรวจว่าเป็นบอท) กรุณาอัปเดต cookies ใหม่ใน config.json"
    }
    if (interaction.deferred || interaction.replied) {
      interaction.editReply(msg).catch(() => {})
    } else {
      interaction.reply({ content: msg, flags: MessageFlags.Ephemeral }).catch(() => {})
    }
  }
})

// ===== เริ่มบอท =====
if (!config.token || config.token.includes("ใส่โทเคน")) {
  console.error("❌ กรุณาใส่โทเคนบอทใน config.json ก่อน!")
  process.exit(1)
}

client.login(config.token)
