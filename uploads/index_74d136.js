const {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  SlashCommandBuilder,
  EmbedBuilder,
} = require("discord.js")
const {
  joinVoiceChannel,
  createAudioPlayer,
  createAudioResource,
  AudioPlayerStatus,
  VoiceConnectionStatus,
  NoSubscriberBehavior,
  entersState,
  getVoiceConnection,
} = require("@discordjs/voice")
const play = require("play-dl")
const config = require("./config.json")

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates],
})

// ===== ระบบคิวเพลง (แยกตามกิล) =====
// guildId -> { connection, player, songs: [], playing: bool, loop: bool, textChannel }
const queues = new Map()

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

  // ดึงกิลไอดีจากทุกกิลที่บอทอยู่ แล้วลงทะเบียนคำสั่งทีละกิล
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
    const stream = await play.stream(song.url)
    const resource = createAudioResource(stream.stream, {
      inputType: stream.type,
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
  const isUrl = play.yt_validate(query) === "video"

  if (isUrl) {
    const info = await play.video_info(query)
    const v = info.video_details
    return {
      title: v.title,
      url: v.url,
      duration: v.durationRaw,
      thumbnail: v.thumbnails?.[0]?.url,
      requestedBy,
    }
  }

  const results = await play.search(query, { limit: 1, source: { youtube: "video" } })
  if (!results.length) return null
  const v = results[0]
  return {
    title: v.title,
    url: v.url,
    duration: v.durationRaw,
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
          return interaction.reply({ content: "❌ คุณต้องเข้าห้องเสียงก่อน!", ephemeral: true })
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
            adapterCreator: interaction.guild.voiceAdapterCreator,
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

          // ถ้าหลุดจากห้องเสียง พยายามต่อใหม่ ถ้าไม่ได้ให้ล้างคิว
          connection.on(VoiceConnectionStatus.Disconnected, async () => {
            try {
              await Promise.race([
                entersState(connection, VoiceConnectionStatus.Signalling, 5_000),
                entersState(connection, VoiceConnectionStatus.Connecting, 5_000),
              ])
            } catch {
              connection.destroy()
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
          return interaction.reply({ content: "❌ ไม่มีเพลงกำลังเล่นอยู่", ephemeral: true })
        }
        queue.loop = false
        queue.player.stop() // จะ trigger Idle แล้วเล่นเพลงถัดไปเอง
        return interaction.reply("⏭️ ข้ามเพลงแล้ว!")
      }

      case "stop": {
        if (!queue) {
          return interaction.reply({ content: "❌ ไม่มีเพลงกำลังเล่นอยู่", ephemeral: true })
        }
        queue.songs = []
        queue.loop = false
        queue.player.stop()
        queue.connection.destroy()
        queues.delete(guildId)
        return interaction.reply("⏹️ หยุดเล่นและล้างคิวเรียบร้อย!")
      }

      case "pause": {
        if (!queue || !queue.playing) {
          return interaction.reply({ content: "❌ ไม่มีเพลงกำลังเล่นอยู่", ephemeral: true })
        }
        queue.player.pause()
        return interaction.reply("⏸️ หยุดเพลงชั่วคราวแล้ว")
      }

      case "resume": {
        if (!queue) {
          return interaction.reply({ content: "❌ ไม่มีเพลงในคิว", ephemeral: true })
        }
        queue.player.unpause()
        return interaction.reply("▶️ เล่นเพลงต่อแล้ว")
      }

      case "queue": {
        if (!queue || queue.songs.length === 0) {
          return interaction.reply({ content: "📭 คิวว่างเปล่า", ephemeral: true })
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
          return interaction.reply({ content: "❌ ไม่มีเพลงกำลังเล่นอยู่", ephemeral: true })
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
          return interaction.reply({ content: "❌ ไม่มีเพลงกำลังเล่นอยู่", ephemeral: true })
        }
        queue.loop = !queue.loop
        return interaction.reply(queue.loop ? "🔁 เปิดเล่นวนเพลงปัจจุบันแล้ว" : "➡️ ปิดเล่นวนแล้ว")
      }

      case "leave": {
        const conn = getVoiceConnection(guildId)
        if (!conn) {
          return interaction.reply({ content: "❌ บอทไม่ได้อยู่ในห้องเสียง", ephemeral: true })
        }
        conn.destroy()
        queues.delete(guildId)
        return interaction.reply("👋 ออกจากห้องเสียงแล้ว บายจ้า~")
      }
    }
  } catch (err) {
    console.error("Command error:", err)
    const msg = "❌ เกิดข้อผิดพลาด ลองใหม่อีกครั้ง"
    if (interaction.deferred || interaction.replied) {
      interaction.editReply(msg).catch(() => {})
    } else {
      interaction.reply({ content: msg, ephemeral: true }).catch(() => {})
    }
  }
})

// ===== เริ่มบอท =====
if (!config.token || config.token.includes("ใส่โทเคน")) {
  console.error("❌ กรุณาใส่โทเคนบอทใน config.json ก่อน!")
  process.exit(1)
}

client.login(config.token)
