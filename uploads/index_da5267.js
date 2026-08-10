const fs = require("fs")

// ===== ตั้งค่า ffmpeg (แก้ปัญหาโฮสต์บล็อก install script) =====
// ใช้ @ffmpeg-installer/ffmpeg เพราะ binary มาพร้อมแพ็กเกจเลย ไม่ต้องดาวน์โหลดตอน install
// (ffmpeg-static ใช้ไม่ได้บนโฮสต์นี้ เพราะต้องดาวน์โหลด binary ผ่าน install script ที่โดนบล็อก)
try {
  const ffmpegInstaller = require("@ffmpeg-installer/ffmpeg")
  if (ffmpegInstaller.path && fs.existsSync(ffmpegInstaller.path)) {
    // โฮสต์บล็อก postinstall script ทำให้ binary อาจไม่มีสิทธิ์ execute ต้อง chmod เอง
    try {
      fs.chmodSync(ffmpegInstaller.path, 0o755)
    } catch {}
    process.env.FFMPEG_PATH = ffmpegInstaller.path
    console.log("🎬 ใช้ ffmpeg จาก @ffmpeg-installer/ffmpeg")
  }
} catch {}
if (!process.env.FFMPEG_PATH) {
  console.warn("⚠️ ไม่พบ ffmpeg ใน node_modules จะลองใช้ ffmpeg ของระบบแทน")
}

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
const { Innertube, Platform } = require("youtubei.js")
const { Readable } = require("stream")
const config = require("./config.json")

// จำเป็นสำหรับ decipher URL ของ YouTube (youtubei.js v17+ ต้องใส่ evaluator เอง)
Platform.shim.eval = async (data) => new Function(data.output)()

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates],
})

// ===== YouTube client (youtubei.js) =====
let yt = null
let hasCookies = false

async function initYouTube() {
  // แปลง cookies จาก config (รูปแบบ array จาก browser extension) เป็น cookie string
  let cookie
  if (Array.isArray(config.cookies) && config.cookies.length > 0) {
    cookie = config.cookies.map((c) => `${c.name}=${c.value}`).join("; ")
    hasCookies = true
    console.log(`🍪 โหลด cookies สำเร็จ (${config.cookies.length} รายการ) ใช้เลี่ยงการโดน YouTube บล็อก`)
  } else {
    console.warn("⚠️ ไม่พบ cookies ใน config.json อาจโดน YouTube บล็อกได้ง่ายขึ้น")
  }
  yt = await Innertube.create({ cookie, retrieve_player: true })
  console.log("📺 เชื่อมต่อ YouTube สำเร็จ (youtubei.js)")
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

// ===== เชื่อมต่อห้องเสียงแบบมี retry =====
// อัปเดตเป็น @discordjs/voice v0.19 แล้ว (v0.18 มีบั๊ก reconnect loop กับ voice gateway ใหม่
// ทำให้ค้างที่ connecting -> signalling วนไปเรื่อยๆ แล้ว timeout)
async function connectToVoice(voiceChannel, guild) {
  const connection = joinVoiceChannel({
    channelId: voiceChannel.id,
    guildId: guild.id,
    adapterCreator: guild.voiceAdapterCreator,
    selfDeaf: true,
  })

  // log สถานะ + สาเหตุที่โดนตัด (close code) ไว้ดูใน console เวลามีปัญหา
  if (!connection._v0LogsAttached) {
    connection._v0LogsAttached = true
    connection.on("stateChange", (oldState, newState) => {
      if (oldState.status !== newState.status) {
        console.log(`🔊 Voice: ${oldState.status} -> ${newState.status}`)
      }
      if (newState.status === VoiceConnectionStatus.Disconnected) {
        const code = newState.closeCode !== undefined ? ` (close code ${newState.closeCode})` : ""
        console.log(`🔊 สาเหตุที่หลุด: reason=${newState.reason}${code}`)
      }
    })
    connection.on("error", (err) => {
      console.error("Voice connection error:", err.message)
    })
  }

  // ลองต่อสูงสุด 3 ครั้ง ครั้งละ 20 วิ (บางทีครั้งแรก timeout แต่ rejoin แล้วติด)
  const MAX_TRIES = 3
  for (let attempt = 1; attempt <= MAX_TRIES; attempt++) {
    try {
      await entersState(connection, VoiceConnectionStatus.Ready, 20_000)
      console.log(`✅ ต่อห้องเสียงสำเร็จ (ครั้งที่ ${attempt})`)
      return connection
    } catch {
      console.warn(`⚠️ ต่อห้องเสียงไม่สำเร็จ (ครั้งที่ ${attempt}/${MAX_TRIES})`)
      if (attempt < MAX_TRIES) {
        try {
          connection.rejoin()
        } catch {}
      }
    }
  }
  try {
    connection.destroy()
  } catch {}
  return null
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

// ===== ดึงสตรีมเสียง (ลองหลาย client เผื่อบางตัวโดนบล็อก) =====
function getStreamClients() {
  return hasCookies
    ? ["MWEB", "WEB_CREATOR", "YTMUSIC", "TV", "WEB", "IOS", "ANDROID"]
    : ["IOS", "ANDROID", "TV", "WEB", "MWEB"]
}

async function createStream(videoId) {
  let lastErr
  for (const clientName of getStreamClients()) {
    try {
      const webStream = await yt.download(videoId, {
        type: "audio",
        quality: "best",
        client: clientName,
      })
      return Readable.fromWeb(webStream)
    } catch (err) {
      lastErr = err
      console.warn(`⚠️ ดึงสตรีมด้วย client ${clientName} ไม่ได้: ${err.message}`)
    }
  }
  throw lastErr || new Error("ดึงสตรีมเสียงไม่ได้")
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
    const stream = await createStream(song.id)

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

// ===== แยก video ID จากลิ้งค์ YouTube =====
function extractVideoId(query) {
  const m = query.match(
    /(?:youtube\.com\/(?:watch\?.*?v=|shorts\/|live\/|embed\/)|youtu\.be\/)([\w-]{11})/,
  )
  return m ? m[1] : null
}

// ===== ค้นหาเพลง (รองรับทั้งลิ้งค์และชื่อเพลง) =====
async function findSong(query, requestedBy) {
  // ถ้าเป็นลิ้งค์ YouTube ดึงข้อมูลวิดีโอโดยตรง
  // (client IOS ใช้กับ cookies ไม่ได้ จะโดน 400 เลยเลือกตาม cookies)
  const videoId = extractVideoId(query)
  if (videoId) {
    const info = await yt.getBasicInfo(videoId, hasCookies ? "MWEB" : "IOS")
    const b = info.basic_info
    return {
      id: videoId,
      title: b.title || "ไม่ทราบชื่อเพลง",
      url: `https://www.youtube.com/watch?v=${videoId}`,
      duration: formatDuration(b.duration),
      thumbnail: b.thumbnail?.[0]?.url,
      requestedBy,
    }
  }

  // ค้นหาด้วยชื่อเพลง
  const results = await yt.search(query, { type: "video" })
  const v = results.videos?.[0]
  if (!v || !v.id) return null
  return {
    id: v.id,
    title: v.title?.text || String(v.title) || "ไม่ทราบชื่อเพลง",
    url: `https://www.youtube.com/watch?v=${v.id}`,
    duration: v.duration?.text || "ไม่ทราบ",
    thumbnail: v.thumbnails?.[0]?.url,
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
        if (!yt) {
          return ephemeralReply(interaction, "⏳ กำลังเชื่อมต่อ YouTube รอสักครู่แล้วลองใหม่")
        }

        await interaction.deferReply()

        const query = interaction.options.getString("song")
        const song = await findSong(query, interaction.user.username)

        if (!song) {
          return interaction.editReply("❌ หาเพลงไม่เจอ ลองใหม่อีกครั้ง")
        }

        let q = queues.get(guildId)
        if (!q) {
          // เชื่อมต่อห้องเสียง (มี retry ในตัว 3 ครั้ง)
          const connection = await connectToVoice(memberVoice, interaction.guild)
          if (!connection) {
            queues.delete(guildId)
            return interaction.editReply(
              "❌ เชื่อมต่อห้องเสียงไม่สำเร็จ (ลองครบ 3 ครั้งแล้ว) ดู close code ใน console เพื่อหาสาเหตุ",
            )
          }

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

initYouTube()
  .then(() => client.login(config.token))
  .catch((err) => {
    console.error("❌ เชื่อมต่อ YouTube ไม่สำเร็จ:", err.message)
    // ล็อกอินบอทอยู่ดี เผื่อ YouTube ล่มชั่วคราว จะได้ใช้คำสั่งอื่นได้
    client.login(config.token)
  })
