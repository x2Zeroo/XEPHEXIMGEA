/**
 * obf.js — Lua Obfuscation Engine
 * ------------------------------------------------------------
 * ดึงมาจาก engine ตัวเดียวกับหน้าเว็บ (Lurapha) แบบคำต่อคำ (byte-for-byte)
 * ไม่มีการแก้ไข/ปรับ logic การ obfuscate ใดๆ ทั้งสิ้น
 * เปลี่ยนแค่ให้รันบน Node.js (CommonJS module) แทน browser เท่านั้น
 * ------------------------------------------------------------
 */
'use strict';



let _rngState = 0x9e3779b1;
function seedRng(s) { _rngState = (s | 0) || 0x12345678; }
function rng() {
  let x = _rngState;
  x ^= x << 13; x = x | 0;
  x ^= x >>> 17;
  x ^= x << 5; x = x | 0;
  _rngState = x;
  return x >>> 0;
}
function randInt(min, max) { return min + (rng() % (max - min + 1)); }
let _nameCounter = 0;
function randName(prefix) {
  if (prefix === undefined) prefix = '_0x';
  const tag = (_nameCounter++).toString(36);
  const scheme = randInt(0, 5);
  if (scheme === 0) {
    const chars = 'lIoO';
    let s = '';
    for (let i = 0; i < 6 + randInt(0, 4); i++) s += chars[randInt(0, chars.length - 1)];
    return s + tag;
  }
  if (scheme === 1) {
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    const head = letters[randInt(0, 25)] + letters[randInt(0, 25)];
    return '_' + head + randInt(100, 99999).toString(36) + tag;
  }
  if (scheme === 2) {
    const words = ['tmp','buf','ref','ctx','ent','obj','val','tag','idx','raw','sym'];
    return '__' + words[randInt(0, words.length - 1)] + tag;
  }
  if (scheme === 3) {
    const u = 'ZXCVBNM'[randInt(0, 6)];
    return u + randInt(1000, 99999).toString(16) + tag;
  }
  if (scheme === 4) {
    return '_' + randInt(0x10000, 0xfffffff).toString(16) + tag;
  }
  const hex = 'abcdef0123456789';
  let s = prefix;
  const len = randInt(6, 9);
  for (let i = 0; i < len; i++) s += hex[randInt(0, hex.length - 1)];
  return s + tag;
}




const KEYWORDS = new Set(['and','break','do','else','elseif','end','false','for','function',
  'goto','if','in','local','nil','not','or','repeat','return','then','true','until','while',
  'continue','type','export']);




function tokenize(src) {
  const tokens = [];
  const n = src.length;
  let i = 0;
  while (i < n) {
    const c = src[i];
    if (/\s/.test(c)) {
      let j = i;
      while (j < n && /\s/.test(src[j])) j++;
      tokens.push({ type: 'whitespace', value: src.slice(i, j) });
      i = j; continue;
    }
    if (c === '-' && src[i+1] === '-') {
      if (src[i+2] === '[') {
        let eq = 0, k = i + 3;
        while (src[k] === '=') { eq++; k++; }
        if (src[k] === '[') {
          const close = ']' + '='.repeat(eq) + ']';
          const end = src.indexOf(close, k + 1);
          if (end !== -1) {
            tokens.push({ type: 'longcomment', value: src.slice(i, end + close.length) });
            i = end + close.length; continue;
          }
        }
      }
      let j = i;
      while (j < n && src[j] !== '\n') j++;
      tokens.push({ type: 'comment', value: src.slice(i, j) });
      i = j; continue;
    }
    if (c === '[') {
      let eq = 0, k = i + 1;
      while (src[k] === '=') { eq++; k++; }
      if (src[k] === '[') {
        const close = ']' + '='.repeat(eq) + ']';
        const end = src.indexOf(close, k + 1);
        if (end !== -1) {
          tokens.push({ type: 'longstring', value: src.slice(i, end + close.length) });
          i = end + close.length; continue;
        }
      }
    }
    if (c === '"' || c === "'") {
      const quote = c; let j = i + 1;
      while (j < n) {
        const ch = src[j];
        if (ch === '\\') { j += 2; continue; }
        if (ch === quote) { j++; break; }
        if (ch === '\n') break;
        j++;
      }
      tokens.push({ type: 'string', value: src.slice(i, j) });
      i = j; continue;
    }
    if (/\d/.test(c) || (c === '.' && /\d/.test(src[i+1]))) {
      let j = i;
      if (c === '0' && (src[i+1] === 'x' || src[i+1] === 'X')) {
        j = i + 2;
        while (j < n && /[0-9a-fA-F.pP+-]/.test(src[j])) j++;
      } else {
        let sawDot = false;
        while (j < n) {
          const cc = src[j];
          if (cc === '.') {
            if (sawDot) break;
            if (src[j+1] === '.') break;
            sawDot = true; j++;
          } else if (/\d/.test(cc)) { j++; }
          else break;
        }
        if (src[j] === 'e' || src[j] === 'E') {
          j++;
          if (src[j] === '+' || src[j] === '-') j++;
          while (j < n && /\d/.test(src[j])) j++;
        }
      }
      tokens.push({ type: 'number', value: src.slice(i, j) });
      i = j; continue;
    }
    if (/[A-Za-z_]/.test(c)) {
      let j = i;
      while (j < n && /[A-Za-z0-9_]/.test(src[j])) j++;
      const value = src.slice(i, j);
      tokens.push({ type: KEYWORDS.has(value) ? 'keyword' : 'identifier', value });
      i = j; continue;
    }
    const two = src.slice(i, i+2);
    if (['==','~=','<=','>=','..','::','->','<<','>>','//'].includes(two)) {
      tokens.push({ type: 'operator', value: two }); i += 2; continue;
    }
    if (src.slice(i, i+3) === '...') {
      tokens.push({ type: 'operator', value: '...' }); i += 3; continue;
    }
    tokens.push({ type: 'operator', value: c }); i++;
  }
  return tokens;
}




function parseLuaShortString(literal) {
  const inner = literal.slice(1, -1);
  let out = '', i = 0;
  while (i < inner.length) {
    const c = inner[i];
    if (c === '\\') {
      const next = inner[i+1];
      if (next === undefined) { i++; continue; }
      if (/\d/.test(next)) {
        let j = i+1, digits = '';
        while (j < inner.length && /\d/.test(inner[j]) && digits.length < 3) { digits += inner[j]; j++; }
        out += String.fromCharCode(parseInt(digits, 10)); i = j; continue;
      }
      if (next === 'x') { out += String.fromCharCode(parseInt(inner.slice(i+2, i+4), 16)); i += 4; continue; }
      const escMap = { n:'\n', t:'\t', r:'\r', a:'\x07', b:'\x08', f:'\x0c', v:'\x0b',
        '\\':'\\', '"':'"', "'":"'", '\n':'\n', '0':'\0' };
      out += (escMap[next] !== undefined ? escMap[next] : next); i += 2; continue;
    }
    out += c; i++;
  }
  return out;
}
function parseLuaLongString(literal) {
  const m = literal.match(/^\[(=*)\[/);
  if (!m) return literal;
  const eqLen = m[1].length;
  const content = literal.slice(2 + eqLen, literal.length - 2 - eqLen);
  return content.startsWith('\n') ? content.slice(1) : content;
}
function toBytes(str) {
  const bytes = [];
  for (let i = 0; i < str.length; i++) {
    const code = str.charCodeAt(i);
    if (code < 0x80) { bytes.push(code); }
    else if (code < 0x800) { bytes.push(0xc0 | (code >> 6)); bytes.push(0x80 | (code & 0x3f)); }
    else if (code >= 0xd800 && code <= 0xdbff) {
      const hi = code, lo = str.charCodeAt(++i);
      const cp = 0x10000 + ((hi - 0xd800) << 10) + (lo - 0xdc00);
      bytes.push(0xf0|(cp>>18)); bytes.push(0x80|((cp>>12)&0x3f));
      bytes.push(0x80|((cp>>6)&0x3f)); bytes.push(0x80|(cp&0x3f));
    } else { bytes.push(0xe0|(code>>12)); bytes.push(0x80|((code>>6)&0x3f)); bytes.push(0x80|(code&0x3f)); }
  }
  return bytes;
}








function ascii85Encode(bytes) {
  let out = '';
  for (let i = 0; i < bytes.length; i += 4) {
    const m = Math.min(4, bytes.length - i);
    let val = 0;
    for (let k = 0; k < 4; k++) val = val * 256 + ((k < m) ? (bytes[i + k] & 0xff) : 0);
    const d = [];
    let v = val;
    for (let k = 0; k < 5; k++) { d.unshift(v % 85); v = Math.floor(v / 85); }
    for (let k = 0; k < m + 1; k++) out += String.fromCharCode(33 + d[k]);
  }
  return out;
}



function luaQuoteA85(body) {
  let out = '"';
  for (let i = 0; i < body.length; i++) {
    const ch = body[i];
    if (ch === '"' || ch === '\\') out += '\\';
    out += ch;
  }
  return out + '"';
}
function bytesToLuaLiteral(bytes) {
  return luaQuoteA85(ascii85Encode(bytes));
}




function luaA85Decoder(name) {
  return `local function ${name}(s) local o={} local n=#s local i=1 local oi=0 local fl=math.floor local bt=string.byte local ch=string.char while i<=n do local c=n-i+1 if c>5 then c=5 end local v=0 for k=0,4 do local d if k<c then d=bt(s,i+k)-33 else d=84 end v=v*85+d end local b1=fl(v/16777216)%256 local b2=fl(v/65536)%256 local b3=fl(v/256)%256 local b4=v%256 local bb={b1,b2,b3,b4} for k=1,c-1 do oi=oi+1 o[oi]=ch(bb[k]) end i=i+c end return table.concat(o) end`;
}
function rollingChecksum(bytes) {
  let ck = 0; const MOD = 4294967291;
  for (let i = 0; i < bytes.length; i++) ck = (ck * 131 + bytes[i]) % MOD;
  return ck;
}
function polyHash(bytes) {
  let h = 0; const MOD = 4294967291;
  for (let i = 0; i < bytes.length; i++) h = (h * 7 + bytes[i] * 13) % MOD;
  return h;
}
function polyHash3(bytes) {
  let h = 1; const MOD = 2147483647;
  for (let i = 0; i < bytes.length; i++) h = (h * 17 + bytes[i] * 31 + (i % 251)) % MOD;
  return h;
}







function hashA(bytes, from, to) {
  from = from || 0; if (to === undefined) to = bytes.length;
  let h = 0; const MOD = 4294967291;
  for (let i = from; i < to; i++) h = (h * 127 + bytes[i] * 3 + ((i - from) % 251) + 1) % MOD;
  return h;
}
function hashB(bytes, from, to) {
  from = from || 0; if (to === undefined) to = bytes.length;
  let h = 2166136261; const MOD = 4294967279;
  for (let i = from; i < to; i++) h = (h * 151 + bytes[i] * 5 + 7) % MOD;
  return h;
}




function buildSbox(k1, k2) {
  const S = new Array(256);
  for (let i = 0; i < 256; i++) S[i] = i;
  let j = 0;
  for (let i = 0; i < 256; i++) {
    j = (j + S[i] + ((k1 * i + k2) % 256)) & 0xff;
    const t = S[i]; S[i] = S[j]; S[j] = t;
  }
  return S;
}
function rotl8(b, r) { b = b & 0xff; r = r & 7; return ((b << r) | (b >>> (8 - r))) & 0xff; }
function deriveRotation(k1, k2, k3, k4) { return 1 + (((k1 ^ k2 ^ k3 ^ k4) >>> 0) % 7); }
function rc4Keystream(k3, k4, len) {
  const S = buildSbox(k3, k4);
  const ks = new Array(len);
  let i = 0, j = 0;
  for (let n = 0; n < len; n++) {
    i = (i + 1) & 0xff; j = (j + S[i]) & 0xff;
    const t = S[i]; S[i] = S[j]; S[j] = t;
    ks[n] = S[(S[i] + S[j]) & 0xff];
  }
  return ks;
}
function strongEncrypt(plain, k1, k2, k3, k4) {
  const sbox = buildSbox(k1, k2);
  const ks = rc4Keystream(k3, k4, plain.length);
  const rot = deriveRotation(k1, k2, k3, k4);
  const out = new Array(plain.length);
  let prev = (k3 ^ k4) & 0xff;
  for (let n = 0; n < plain.length; n++) {
    const idx = n + 1;
    let b = plain[n] & 0xff;
    b = (b + idx * k1) & 0xff;
    b = b ^ ((k2 * idx + k3) & 0xff);
    b = sbox[b];
    b = rotl8(b, rot);
    b = b ^ ks[n];
    b = b ^ prev;
    out[n] = b & 0xff;
    prev = out[n];
  }
  return out;
}
const RLE_ESC = 0xf7;
function rleCompress(bytes) {
  const out = []; let i = 0;
  while (i < bytes.length) {
    const b = bytes[i] & 0xff;
    let run = 1;
    while (i + run < bytes.length && (bytes[i+run] & 0xff) === b && run < 255) run++;
    if (b === RLE_ESC) { out.push(RLE_ESC, RLE_ESC); i += 1; }
    else if (run >= 4) { out.push(RLE_ESC, run, b); i += run; }
    else { out.push(b); i += 1; }
  }
  return out;
}
function preXorLayer(plain, k7, k8) {
  const ks = rc4Keystream(k7, k8, plain.length);
  const out = new Array(plain.length);
  for (let n = 0; n < plain.length; n++) out[n] = (plain[n] ^ ks[n] ^ ((n * k7 + k8) & 0xff)) & 0xff;
  return out;
}
function secondLayer(cipher, k5, k6) {
  const s3 = buildSbox(k5, k6);
  const ks2 = rc4Keystream(k6, k5, cipher.length);
  const out = new Array(cipher.length);
  for (let n = 0; n < cipher.length; n++) { let b = cipher[n] & 0xff; b = s3[b]; b = b ^ ks2[n]; out[n] = b & 0xff; }
  return out;
}




class StringVault {
  constructor() { this._map = new Map(); this._list = []; }
  add(value) {
    const existing = this._map.get(value);
    if (existing !== undefined) return existing;
    const id = this._list.length + 1;
    this._map.set(value, id); this._list.push({ id, value }); return id;
  }
  size() { return this._list.length; }
  build(rngSeed, accessorName, vaultName) {
    if (this._list.length === 0) return '';
    const allBytes = []; const offsets = [];
    for (const entry of this._list) {
      offsets.push(allBytes.length);
      const bytes = toBytes(entry.value);
      for (const b of bytes) allBytes.push(b);
    }
    offsets.push(allBytes.length);
    seedRng(rngSeed);
    const k1 = randInt(13,251), k2 = randInt(17,239), k3 = randInt(11,241), k4 = randInt(19,233);
    const rot = deriveRotation(k1,k2,k3,k4);
    const cipher = strongEncrypt(allBytes, k1, k2, k3, k4);
    const blobLit = bytesToLuaLiteral(cipher);
    const offsetsLit = offsets.join(',');
    const Q = 1 << rot, P = 1 << (8 - rot);
    const iv = (k3 ^ k4) & 0xff;
    const N = { bx:randName('_x'), si:randName('_I'), ks:randName('_Q'), i:randName('_i'),
      j:randName('_j'), n:randName('_n'), b:randName('_a'), c:randName('_d'),
      prev:randName('_v'), out:randName('_r'), s:randName('_s'), e:randName('_e'),
      r:randName('_R'), sb:randName('_sb'), sc:randName('_sc'), tc:randName('_tc'), bo:randName('_bo'), dec:randName('_u5') };
    return [
      luaA85Decoder(N.dec),
      `local ${vaultName}_blob=${N.dec}(${blobLit})`,
      `local ${vaultName}_offs={${offsetsLit}}`,
      `local ${vaultName}_cache={}`,
      `local ${N.sb}=string.byte`,
      `local ${N.sc}=string.char`,
      `local ${N.tc}=table.concat`,
      `local ${N.bx}=bit32 and bit32.bxor or function(a,b) local r,p=0,1 for _=1,8 do local x,y=a%2,b%2 if x~=y then r=r+p end a,b,p=(a-x)/2,(b-y)/2,p*2 end return r end`,
      `local ${N.si}=nil`,
      `local ${N.ks}=nil`,
      `local function ${accessorName}(id)`,
      `  local ${N.r}=${vaultName}_cache[id]`,
      `  if ${N.r} then return ${N.r} end`,
      `  local ${N.bo}=${vaultName}_blob`,
      `  if not ${N.si} then`,
      `    local S={} for ${N.i}=0,255 do S[${N.i}]=${N.i} end`,
      `    do local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+S[${N.i}]+((${k1}*${N.i}+${k2})%256))%256 S[${N.i}],S[${N.j}]=S[${N.j}],S[${N.i}] end end`,
      `    local SI={} for ${N.i}=0,255 do SI[S[${N.i}]]=${N.i} end`,
      `    local S2={} for ${N.i}=0,255 do S2[${N.i}]=${N.i} end`,
      `    do local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+S2[${N.i}]+((${k3}*${N.i}+${k4})%256))%256 S2[${N.i}],S2[${N.j}]=S2[${N.j}],S2[${N.i}] end end`,
      `    local KS={} local kI,kJ=0,0`,
      `    for ${N.n}=1,#${N.bo} do kI=(kI+1)%256 kJ=(kJ+S2[kI])%256 S2[kI],S2[kJ]=S2[kJ],S2[kI] KS[${N.n}]=S2[(S2[kI]+S2[kJ])%256] end`,
      `    ${N.si}=SI ${N.ks}=KS`,
      `  end`,
      `  local ${N.s}=${vaultName}_offs[id]+1`,
      `  local ${N.e}=${vaultName}_offs[id+1]`,
      `  if ${N.s}>${N.e} then ${vaultName}_cache[id]="" return "" end`,
      `  local SI=${N.si} local KS=${N.ks} local bx=${N.bx} local sb=${N.sb} local sc=${N.sc}`,
      `  local ${N.out}={}`,
      `  local ${N.prev} if ${N.s}==1 then ${N.prev}=${iv} else ${N.prev}=sb(${N.bo},${N.s}-1) end`,
      `  for ${N.i}=${N.s},${N.e} do`,
      `    local ${N.c}=sb(${N.bo},${N.i})`,
      `    local ${N.b}=${N.c}`,
      `    ${N.b}=bx(${N.b},${N.prev})`,
      `    ${N.b}=bx(${N.b},KS[${N.i}])`,
      `    ${N.b}=(${N.b}-${N.b}%${Q})/${Q}+(${N.b}%${Q})*${P}`,
      `    ${N.b}=SI[${N.b}]`,
      `    ${N.b}=bx(${N.b},(${k2}*${N.i}+${k3})%256)`,
      `    ${N.b}=(${N.b}-${N.i}*${k1})%256`,
      `    ${N.out}[${N.i}-${N.s}+1]=sc(${N.b})`,
      `    ${N.prev}=${N.c}`,
      `  end`,
      `  ${N.r}=${N.tc}(${N.out})`,
      `  ${vaultName}_cache[id]=${N.r}`,
      `  return ${N.r}`,
      `end`,
    ].join('\n');
  }
}




function prevSignificantToken(tokens, i) {
  for (let j = i-1; j >= 0; j--) {
    const t = tokens[j];
    if (t.type === 'whitespace' || t.type === 'comment' || t.type === 'longcomment') continue;
    return t;
  }
  return null;
}
function nextSignificantToken(tokens, i) {
  for (let j = i+1; j < tokens.length; j++) {
    const t = tokens[j];
    if (t.type === 'whitespace' || t.type === 'comment' || t.type === 'longcomment') continue;
    return t;
  }
  return null;
}
function isInTypePosition(tokens, i) {
  let j = i-1, safety = 0;
  while (j >= 0 && safety < 200) {
    safety++;
    const t = tokens[j];
    if (t.type === 'whitespace' || t.type === 'comment' || t.type === 'longcomment') { j--; continue; }
    if (t.type === 'identifier' || t.type === 'string' || t.type === 'longstring' || t.type === 'number') { j--; continue; }
    if (t.type === 'operator') {
      if (['|','&','?','.','->' ].includes(t.value)) { j--; continue; }
      if (t.value === ':') return true;
      return false;
    }
    if (t.type === 'keyword') return t.value === 'type' || t.value === 'export';
    j--;
  }
  return false;
}




function obfuscateNumber(numStr, intensity) {
  if (/^0[xX]/.test(numStr)) return numStr;
  if (numStr.includes('.') || /[eE]/.test(numStr)) return numStr;
  const n = parseInt(numStr, 10);
  if (!isFinite(n) || Math.abs(n) > 2000000000) return numStr;
  const op = randInt(0, Math.min(2 + intensity, 4));
  if (op === 0) { const a = randInt(1,500); return `(${n+a}-${a})`; }
  if (op === 1) { const a = randInt(1,500); return `(${n-a}+${a})`; }
  if (op === 2) { const a = randInt(1,999), b = randInt(1,999); return `(${n+a+b}-${a}-${b})`; }
  if (op === 3) { const a = randInt(1,200), b = randInt(1,200); return `((${n+a}+${b})-${a+b})`; }
  const a = randInt(1,300), b = randInt(1,300), c = randInt(1,300);
  return `(${n+a-b+c}-${a}+${b}-${c})`;
}
function obfuscateBool(value) {
  if (value === 'true') return ['(not false)','(1==1)','(0<1)','(1+1==2)'][randInt(0,3)];
  if (value === 'false') return ['(not true)','(1==0)','(1<0)','(1+1==3)'][randInt(0,3)];
  if (value === 'nil') return ['(({})[1])','(nil)'][randInt(0,1)];
  return value;
}




function replaceStringsWithVault(tokens, vault, accessorName) {
  return tokens.map((t, idx) => {
    if (t.type !== 'string' && t.type !== 'longstring') return t;
    if (isInTypePosition(tokens, idx)) return t;
    const decoded = t.type === 'longstring' ? parseLuaLongString(t.value) : parseLuaShortString(t.value);
    if (decoded.length === 0) return { type: 'string', value: '""' };
    const id = vault.add(decoded);
    return { type: 'identifier', value: `(${accessorName}(${id}))` };
  });
}




function rebuildSource(tokens, from, to) { let s = ''; for (let i = from; i < to; i++) s += tokens[i].value; return s; }
function findBlockEnd(tokens, start) {
  let depth = 1, i = start + 1;
  while (i < tokens.length) {
    const t = tokens[i];
    if (t.type === 'keyword') {
      if (['function','do','then','repeat'].includes(t.value)) depth++;
      else if (t.value === 'elseif') depth--;
      else if (t.value === 'end' || t.value === 'until') { depth--; if (depth === 0) return i; }
    }
    i++;
  }
  return -1;
}
function isFunctionExpression(tokens, i) {
  const prev = prevSignificantToken(tokens, i);
  if (!prev) return false;
  if (prev.type === 'operator') {
    return ['=','(', ',','[','{','...','+','-','*','/','%','^','<','>','<=','>=','==','~=',':','->'].includes(prev.value);
  }
  if (prev.type === 'keyword') {
    return ['return','or','and','not','in','then','do','else','elseif','if','while','until'].includes(prev.value);
  }
  return false;
}
function classifyFunctionStatement(tokens, funcIdx) {
  const prev = prevSignificantToken(tokens, funcIdx);
  const isLocal = !!prev && prev.type === 'keyword' && prev.value === 'local';
  let j = funcIdx + 1;
  while (j < tokens.length && ['whitespace','comment','longcomment'].includes(tokens[j].type)) j++;
  if (j >= tokens.length || tokens[j].type !== 'identifier') return { kind: 'complex', nameStart: -1, nameEnd: -1 };
  const nameStart = j;
  let k = j + 1;
  while (k < tokens.length && ['whitespace','comment','longcomment'].includes(tokens[k].type)) k++;
  if (k >= tokens.length || tokens[k].type !== 'operator' || tokens[k].value !== '(') return { kind: 'complex', nameStart: -1, nameEnd: -1 };
  return { kind: isLocal ? 'local-named' : 'named', nameStart, nameEnd: j + 1 };
}
function encryptFunctionsPass(tokens, vault, decryptName, loaderName, proxyName) {
  
  
  
  
  
  const injList = [decryptName, proxyName].filter(Boolean);
  const injArgs = injList.join(',');
  const header = injList.length ? `local ${injArgs}=... ` : '';
  const provided = new Set(injList);
  const out = []; let i = 0, curDepth = 0;
  const maxDepth = 1;
  while (i < tokens.length) {
    const t = tokens[i];
    if (t.type === 'keyword' && t.value === 'function' && curDepth < maxDepth) {
      const blockEnd = findBlockEnd(tokens, i);
      
      
      
      if (blockEnd !== -1 && sliceIsSelfContained(tokens, i, blockEnd, provided)) {
        if (isFunctionExpression(tokens, i)) {
          const funcSrc = rebuildSource(tokens, i, blockEnd + 1);
          const payloadId = vault.add(`${header}return ${funcSrc}`);
          out.push({ type: 'identifier', value: `((${loaderName}(${decryptName}(${payloadId})))(${injArgs}))` });
          i = blockEnd + 1; continue;
        }
        const stmt = classifyFunctionStatement(tokens, i);
        if (stmt.kind === 'named' || stmt.kind === 'local-named') {
          const nameTok = tokens[stmt.nameStart];
          let anon = '';
          for (let q = i; q <= blockEnd; q++) { if (q === stmt.nameStart) continue; anon += tokens[q].value; }
          const payloadId = vault.add(`${header}return ${anon}`);
          const expr = `((${loaderName}(${decryptName}(${payloadId})))(${injArgs}))`;
          if (stmt.kind === 'local-named') {
            for (let q = out.length - 1; q >= 0; q--) {
              const ot = out[q];
              if (['whitespace','comment','longcomment'].includes(ot.type)) continue;
              if (ot.type === 'keyword' && ot.value === 'local') out.splice(q, out.length - q);
              break;
            }
            out.push({ type: 'identifier', value: `local ${nameTok.value}=${expr}` });
          } else {
            out.push({ type: 'identifier', value: `${nameTok.value}=${expr}` });
          }
          i = blockEnd + 1; continue;
        }
      }
    }
    if (t.type === 'keyword') {
      if (['function','do','then','repeat'].includes(t.value)) curDepth++;
      else if (t.value === 'elseif') curDepth = Math.max(0, curDepth - 1);
      else if (t.value === 'end' || t.value === 'until') curDepth = Math.max(0, curDepth - 1);
    }
    out.push(t); i++;
  }
  return out;
}




function flattenControlFlow(source, intensity) {
  const stateVar = randName();
  const realState = randInt(1000, 9999);
  const decoyCount = Math.min(2 + intensity, 6);
  const decoys = []; const used = new Set([realState]);
  while (decoys.length < decoyCount) { const n = randInt(1000,9999); if (!used.has(n)) { used.add(n); decoys.push(n); } }
  const sequence = [...decoys, realState];
  const transitions = {};
  for (let i = 0; i < sequence.length - 1; i++) transitions[sequence[i]] = sequence[i+1];
  transitions[realState] = 0;
  const lines = [];
  lines.push(`local ${stateVar}=${sequence[0]}`);
  lines.push(`while ${stateVar}~=0 do`);
  const allStates = [...sequence];
  for (let i = allStates.length - 1; i > 0; i--) {
    const j = randInt(0, i); const tmp = allStates[i]; allStates[i] = allStates[j]; allStates[j] = tmp;
  }
  let first = true;
  for (const state of allStates) {
    const kw = first ? 'if' : 'elseif'; first = false;
    const opaque = intensity >= 4 ? ` and ((${randInt(1,99)}*${randInt(1,99)})%${randInt(2,99)}>=0)` : '';
    lines.push(`  ${kw} ${stateVar}==${state}${opaque} then`);
    if (state === realState) { lines.push(`    ${stateVar}=0`); lines.push(source); }
    else { const tmpName = randName(); lines.push(`    local ${tmpName}=(${randInt(1,999)}*${randInt(1,999)})%${randInt(2,999)}`); lines.push(`    ${stateVar}=${transitions[state]}`); }
  }
  lines.push('  else'); lines.push(`    ${stateVar}=0`); lines.push('  end'); lines.push('end');
  return lines.join('\n');
}




function generateJunk(intensity) {
  const count = Math.max(1, intensity - 1);
  const lines = [];
  for (let i = 0; i < count; i++) {
    const name = randName(); const choice = randInt(0, 6);
    if (choice === 0) { const bytes = []; const len = randInt(6,14); for (let k = 0; k < len; k++) bytes.push(randInt(48,122)); lines.push(`local ${name}=string.char(${bytes.join(',')});`); }
    else if (choice === 1) lines.push(`local ${name}=function() return ${randInt(1000,99999)} end;`);
    else if (choice === 2) lines.push(`local ${name}={[${randInt(1,99)}]=${randInt(1,99)},[${randInt(1,99)}]=${randInt(1,99)}};`);
    else if (choice === 3) lines.push(`local ${name}=#tostring(${randInt(1000,999999)});`);
    else if (choice === 4) lines.push(`local ${name}=(${randInt(1,999)}*${randInt(1,999)})%${randInt(2,99)};`);
    else if (choice === 5) { const a = randName(), b = randName(); lines.push(`local ${a}=${randInt(1,9)} local ${b}={[${a}]=function() return ${a}+1 end};`); }
    else { const a = randName(); lines.push(`local ${a}=0 for _=1,${randInt(2,5)} do ${a}=${a}+${randInt(1,99)} end;`); }
  }
  return lines.join('');
}




function shuffleLines(lines) {
  const a = lines.slice();
  for (let i = a.length - 1; i > 0; i--) { const j = randInt(0, i); const t = a[i]; a[i] = a[j]; a[j] = t; }
  return a;
}




function buildVmLoader(source, layer, opts) {
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  const rawBytes = toBytes(source);
  seedRng((0xdeadbeef ^ (layer * 0x9e3779b1) ^ rawBytes.length) >>> 0);
  const k1 = randInt(13,251), k2 = randInt(17,239), k3 = randInt(11,241), k4 = randInt(19,233);
  const k5 = randInt(23,241), k6 = randInt(29,229), k7 = randInt(31,227), k8 = randInt(37,223);
  const rot = deriveRotation(k1,k2,k3,k4);
  const compressed = rleCompress(rawBytes);
  const cipherPre = preXorLayer(compressed, k7, k8);
  const cipher1 = strongEncrypt(cipherPre, k1, k2, k3, k4);
  const cipher = secondLayer(cipher1, k5, k6);
  const h1 = rollingChecksum(cipher), h2 = polyHash(cipher), h3 = polyHash3(cipher);
  const Q = 1 << rot, P = 1 << (8 - rot);
  const h1_lo = h1&0xff, h1_hi = (h1>>>8)&0xff;
  const h2_lo = h2&0xff, h2_hi = (h2>>>8)&0xff;
  const h3_lo = h3&0xff, h3_hi = (h3>>>8)&0xff;
  const f1=k1^h1_lo, f2=k2^h1_hi, f3=k3^h2_lo, f4=k4^h2_hi, f5=k5^h3_lo, f6=k6^h3_hi;
  
  
  
  
  
  
  
  
  
  const midIdx = Math.floor(cipher.length / 2);
  const hAv = hashA(cipher), hBv = hashB(cipher);
  const hS1v = hashA(cipher, 0, midIdx), hS2v = hashB(cipher, midIdx, cipher.length);
  const hA_lo=hAv&0xff, hA_hi=(hAv>>>8)&0xff;
  const hB_lo=hBv&0xff, hB_hi=(hBv>>>8)&0xff;
  const hS1_lo=hS1v&0xff, hS1_hi=(hS1v>>>8)&0xff;
  const hS2_lo=hS2v&0xff, hS2_hi=(hS2v>>>8)&0xff;
  const lenLo=cipher.length&0xff, lenHi=(cipher.length>>>8)&0xff;
  
  
  
  const g1=f1^hA_lo, g2=f2^hA_hi, g3=f3^hB_lo, g4=f4^hB_hi;
  const g5=f5^hS1_lo, g6=f6^hS1_hi, g7=(k7^hS2_lo^lenLo), g8=(k8^hS2_hi^lenHi);
  const N = {
    ld:randName('_l'), sc:randName('_c'), sb:randName('_b'), ss:randName('_u'),
    tc:randName('_t'), sr:randName('_z'), tn:randName('_T'), bx:randName('_x'),
    sf:randName('_F'), D:randName('_d'), h1:randName('_h'), h2:randName('_g'),
    h3:randName('_H'), S1:randName('_S'), SI:randName('_I'), S2:randName('_K'),
    S3:randName('_T2'), S3I:randName('_J'), KS:randName('_Q'), KS2:randName('_R'),
    kI:randName('_p'), kJ:randName('_q'), kI2:randName('_pp'), kJ2:randName('_qq'),
    K1:randName('_k'), K2:randName('_m'), K3:randName('_n'), K4:randName('_o'),
    K5:randName('_kk'), K6:randName('_mm'), K7:randName('_K7'), K8:randName('_K8'),
    O:randName('_r'), prev:randName('_v'), src:randName('_s'), f:randName('_f'),
    i:randName('_i'), j:randName('_y'), n:randName('_w'), b:randName('_a'),
    c:randName('_e'), c1:randName('_e1'), P:randName('_pp'), KS0:randName('_K0'),
    raw:randName('_raw'), A:randName('_AC'), G:randName('_GC'),
    hA:randName('_hA'), hB:randName('_hB'), hS1:randName('_hS'), hS2:randName('_hT'),
    M:randName('_MC'), Gm:randName('_GM'), dec:randName('_D5'),
  };
  const _used = new Set();
  
  
  
  let EA = 0;
  const poisonPrime = () => {
    const primes = [3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71];
    for (;;) {
      const p = primes[randInt(0, primes.length-1)];
      if (!_used.has(p)) { _used.add(p); return p; }
      if (_used.size >= primes.length) { _used.clear(); }
    }
  };
  const mkCheck = (failCond) => {
    const p = poisonPrime();
    
    
    
    
    if (opts.tamperLock) {
      const C = randInt(1, 255); EA ^= C;
      return `if ${failCond} then ${N.P}=${N.P}*${p}+${p} else ${N.A}=${N.bx}(${N.A},${C}) end`;
    }
    return `if ${failCond} then ${N.P}=${N.P}*${p}+${p} end`;
  };
  const sanityPool = [];
  if (opts.antiHook) {
    
    
    
    
    
    
    
    
    
    const pois = () => `${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()}`;
    const _ra = randInt(1000, 9999), _rb = randInt(1000, 9999), _rsum = _ra + _rb;
    const _tokB = []; for (let _z = 0; _z < 6; _z++) _tokB.push(randInt(65, 90));
    const _tok = String.fromCharCode(..._tokB);
    sanityPool.push(
      mkCheck(`not (${N.sc} and ${N.sb} and ${N.tc} and ${N.ss} and ${N.sr} and ${N.tn})`),
      mkCheck(`type(${N.sc})~="function" or type(${N.sb})~="function" or type(${N.tc})~="function" or type(${N.ss})~="function"`),
      mkCheck(`type(${N.sr})~="function" or type(${N.bx})~="function" or type(${N.sf})~="function" or type(${N.tn})~="function"`),
      mkCheck(`${N.sc}(65)~="A"`),
      mkCheck(`${N.sb}("Z")~=90`),
      mkCheck(`${N.sc}(72,105)~="Hi"`),
      mkCheck(`${N.ss}("ABCDE",2,4)~="BCD"`),
      mkCheck(`${N.sc}(${N.sb}("X"))~="X"`),
      mkCheck(`${N.sr}("a",4)~="aaaa"`),
      mkCheck(`#"abcde"~=5`),
      mkCheck(`${N.tc}({"a","b","c"})~="abc"`),
      mkCheck(`${N.tc}({"x","y","z"},"-")~="x-y-z"`),
      mkCheck(`${N.tn}("42")~=42`),
      mkCheck(`tostring(7)~="7"`),
      mkCheck(`${N.bx}(255,15)~=240`),
      mkCheck(`${N.bx}(170,85)~=255`),
      mkCheck(`${N.bx}(${N.bx}(123,77),77)~=123`),
      mkCheck(`${N.sf}(255,15)~=240`),
      mkCheck(`${N.bx}(${N.sf}(170,85),255)~=0`),
      mkCheck(`${N.ss}("obfuscate",4,6)~="usc"`),
      mkCheck(`${N.sr}("ab",3)~="ababab"`),
      mkCheck(`${N.tn}("ff",16)~=255`),
      mkCheck(`${N.sb}(${N.sc}(200))~=200`),
      mkCheck(`#${N.tc}({"12","34","56"})~=6`),
      `do local _ok=pcall(function() if rawequal then if not rawequal(${N.sc},string.char) or not rawequal(${N.sb},string.byte) or not rawequal(${N.tc},table.concat) then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end end) end`,
      `do local _ok,_h=pcall(function() return debug and debug.gethook and debug.gethook() end) if _ok and _h then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end`,
      `do local _ok=pcall(function() return ${N.sc}(65)..${N.sc}(66) end) if not _ok then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end`,
      
      
      
      
      
      
      
      
      
      
      
      `do local _sd=(type(string)=="table" and string.dump) if _sd then if pcall(_sd,${N.sc}) then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end if pcall(_sd,${N.sb}) then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end if pcall(_sd,${N.tc}) then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end end`,
      `do local _sd=(type(string)=="table" and string.dump) if _sd then local _lx=(loadstring or load) if _lx and pcall(_sd,_lx) then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end end`,
      
      
      `do local _lx=(loadstring or load) if type(_lx)=="function" then local _o,_fn=pcall(_lx,"return 116+11") if _o and type(_fn)=="function" then local _o2,_rv=pcall(_fn) if (not _o2) or _rv~=127 then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end else ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end end`,
      
      
      `do local _lx=(loadstring or load) if type(_lx)=="function" then local _o,_fn=pcall(_lx,"return (((") if _o and type(_fn)=="function" then ${N.P}=${N.P}*${poisonPrime()}+${poisonPrime()} end end end`,
    );
    
    
    
    
    
    sanityPool.push(
      
      
      
      
      `do if type(iscclosure)=="function" then for _,_fn in ipairs({${N.sc},${N.sb},${N.tc},${N.ss},${N.sr},${N.tn}}) do local _o,_r=pcall(iscclosure,_fn) if _o and _r==false then ${pois()} end end end end`,
      `do if type(islclosure)=="function" then for _,_fn in ipairs({${N.sc},${N.sb},${N.tc}}) do local _o,_r=pcall(islclosure,_fn) if _o and _r==true then ${pois()} end end end end`,
      
      
      `do local _gi=(type(debug)=="table") and debug.getinfo if type(_gi)=="function" then for _,_fn in ipairs({${N.sc},${N.sb},${N.tc},${N.ss}}) do local _o,_r=pcall(_gi,_fn,"S") if _o and type(_r)=="table" and _r.what=="Lua" then ${pois()} end end end end`,

      
      
      
      `do local _o=pcall(function() local _s=(type(_G)=="table" and _G.string) or string if type(_s)=="table" then if _s.char~=${N.sc} then ${pois()} end if _s.byte~=${N.sb} then ${pois()} end if _s.sub~=${N.ss} then ${pois()} end if _s.rep~=${N.sr} then ${pois()} end end end) end`,
      `do local _o=pcall(function() local _t=(type(_G)=="table" and _G.table) or table if type(_t)=="table" and _t.concat~=${N.tc} then ${pois()} end local _n=(type(_G)=="table" and _G.tonumber) or tonumber if _n~=${N.tn} then ${pois()} end end) end`,

      
      
      
      `do if type(getrawmetatable)=="function" then local _o,_mt=pcall(getrawmetatable,"") if _o and type(_mt)=="table" then if type(_mt.__index)=="function" then ${pois()} end end end end`,
      
      
      
      `do if game~=nil and type(getrawmetatable)=="function" and type(iscclosure)=="function" then local _o,_mt=pcall(getrawmetatable,game) if _o and type(_mt)=="table" then local _nc=_mt.__namecall if type(_nc)=="function" then local _o2,_r=pcall(iscclosure,_nc) if _o2 and _r==false then ${pois()} end end local _ix=_mt.__index if type(_ix)=="function" then local _o3,_r3=pcall(iscclosure,_ix) if _o3 and _r3==false then ${pois()} end end end end end`,

      
      
      
      `do local _o=pcall(error,"x") if _o~=false then ${pois()} end end`,
      `do local _o,_r=pcall(function() return ${N.sc}(65) end) if (not _o) or _r~="A" then ${pois()} end end`,
      mkCheck(`select("#","a","b","c")~=3`),
      mkCheck(`select(2,"x","y","z")~="y"`),
      mkCheck(`tostring(nil)~="nil" or tostring(true)~="true"`),
      mkCheck(`type("")~="string" or type({})~="table" or type(0)~="number"`),

      
      
      
      
      `do local _sd=(type(string)=="table" and string.dump) if _sd then if pcall(_sd,pcall) then ${pois()} end if pcall(_sd,error) then ${pois()} end if pcall(_sd,${N.ss}) then ${pois()} end if pcall(_sd,${N.sr}) then ${pois()} end end end`,

      
      mkCheck(`${N.bx}(0,0)~=0 or ${N.bx}(15,240)~=255 or ${N.bx}(${N.bx}(99,200),200)~=99`),
      `do if type(bit32)=="table" and type(bit32.bxor)=="function" then if bit32.bxor(171,204)~=${N.bx}(171,204) then ${pois()} end end end`,

      
      
      
      
      
      `do local _lx=(loadstring or load) if type(_lx)=="function" then local _o,_fn=pcall(_lx,"return ${_ra}+${_rb}") if _o and type(_fn)=="function" then local _o2,_rv=pcall(_fn) if (not _o2) or _rv~=${_rsum} then ${pois()} end else ${pois()} end end end`,
      `do local _lx=(loadstring or load) if type(_lx)=="function" then local _o,_fn=pcall(_lx,"return '${_tok}'") if _o and type(_fn)=="function" then local _o2,_rv=pcall(_fn) if (not _o2) or _rv~="${_tok}" then ${pois()} end end end end`,

      
      
      
      
      
      
      
      
      
      
      
      
      
      `do local _ck=(type(os)=="table" and os.clock) or tick if type(_ck)=="function" then local function _meas() local _o0,_t0=pcall(_ck) for _=1,3000 do local _=${N.sc}(65,66,67) end local _o1,_t1=pcall(_ck) if _o0 and _o1 and type(_t0)=="number" and type(_t1)=="number" then return _t1-_t0 end return 0 end if _meas()>2.5 and _meas()>2.5 then ${pois()} end end end`,

      
      
      
      `do local _o,_h=pcall(function() return type(debug)=="table" and debug.gethook and debug.gethook() end) if _o and _h~=nil and _h~=false then ${pois()} end end`,
    );
  }
  const keyDerivLines = [];
  if (opts.tamperLock) {
    
    const BX = (...t) => t.reduce((a, x) => a === null ? x : `${N.bx}(${a},${x})`, null);
    const HL = n => `${n}%256`;
    const HH = n => `(${n}-${n}%256)/256%256`;
    keyDerivLines.push(
      
      `local ${N.h1}=0 for ${N.i}=1,#${N.D} do ${N.h1}=(${N.h1}*131+${N.sb}(${N.D},${N.i}))%4294967291 end`,
      `local ${N.h2}=0 for ${N.i}=1,#${N.D} do ${N.h2}=(${N.h2}*7+${N.sb}(${N.D},${N.i})*13)%4294967291 end`,
      `local ${N.h3}=1 for ${N.i}=1,#${N.D} do ${N.h3}=(${N.h3}*17+${N.sb}(${N.D},${N.i})*31+((${N.i}-1)%251))%2147483647 end`,
      `local ${N.hA}=0 for ${N.i}=1,#${N.D} do ${N.hA}=(${N.hA}*127+${N.sb}(${N.D},${N.i})*3+((${N.i}-1)%251)+1)%4294967291 end`,
      `local ${N.hB}=2166136261 for ${N.i}=1,#${N.D} do ${N.hB}=(${N.hB}*151+${N.sb}(${N.D},${N.i})*5+7)%4294967279 end`,
      `local ${N.hS1}=0 for ${N.i}=1,${midIdx} do ${N.hS1}=(${N.hS1}*127+${N.sb}(${N.D},${N.i})*3+((${N.i}-1)%251)+1)%4294967291 end`,
      `local ${N.hS2}=2166136261 for ${N.i}=${midIdx + 1},#${N.D} do ${N.hS2}=(${N.hS2}*151+${N.sb}(${N.D},${N.i})*5+7)%4294967279 end`,
      
      
      
      
      
      
      
      
      `local ${N.K1}=${BX(g1, HL(N.h1), HL(N.hA), `(${N.P}*131)%256`, `(${N.G}*7)%256`, `(${N.Gm}*3)%256`)}`,
      `local ${N.K2}=${BX(g2, HH(N.h1), HH(N.hA), `(${N.P}*199)%256`, `(${N.G}*11)%256`, `(${N.Gm}*5)%256`)}`,
      `local ${N.K3}=${BX(g3, HL(N.h2), HL(N.hB), `(${N.P}*211)%256`, `(${N.G}*13)%256`, `(${N.Gm}*7)%256`)}`,
      `local ${N.K4}=${BX(g4, HH(N.h2), HH(N.hB), `(${N.P}*223)%256`, `(${N.G}*17)%256`, `(${N.Gm}*11)%256`)}`,
      `local ${N.K5}=${BX(g5, HL(N.h3), HL(N.hS1), `(${N.P}*227)%256`, `(${N.G}*19)%256`, `(${N.Gm}*13)%256`)}`,
      `local ${N.K6}=${BX(g6, HH(N.h3), HH(N.hS1), `(${N.P}*239)%256`, `(${N.G}*23)%256`, `(${N.Gm}*17)%256`)}`,
      `local ${N.K7}=${BX(g7, HL(N.hS2), `#${N.D}%256`, `(${N.P}*241)%256`, `(${N.G}*29)%256`, `(${N.Gm}*19)%256`)}`,
      `local ${N.K8}=${BX(g8, HH(N.hS2), `(#${N.D}-#${N.D}%256)/256%256`, `(${N.P}*251)%256`, `(${N.G}*31)%256`, `(${N.Gm}*23)%256`)}`,
    );
  } else {
    keyDerivLines.push(
      `local ${N.K1}=${N.bx}(${k1},(${N.P}*131)%256)`,
      `local ${N.K2}=${N.bx}(${k2},(${N.P}*199)%256)`,
      `local ${N.K3}=${N.bx}(${k3},(${N.P}*211)%256)`,
      `local ${N.K4}=${N.bx}(${k4},(${N.P}*223)%256)`,
      `local ${N.K5}=${N.bx}(${k5},(${N.P}*227)%256)`,
      `local ${N.K6}=${N.bx}(${k6},(${N.P}*239)%256)`,
      `local ${N.K7}=${N.bx}(${k7},(${N.P}*241)%256)`,
      `local ${N.K8}=${N.bx}(${k8},(${N.P}*251)%256)`,
    );
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  const ANCHOR_MOD = 4294967291, ANCHOR_MULT = 131;
  const anchorItems = [];
  if (opts.tamperLock) {
    const anchorCount = 16 + randInt(0, 12);
    const roll = expr => `${N.M}=(${N.M}*${ANCHOR_MULT}+${expr})%${ANCHOR_MOD}`;
    for (let q = 0; q < anchorCount; q++) {
      const mode = randInt(0, 2);
      if (mode === 0) {
        const C = randInt(1, 255); EA ^= C;
        anchorItems.push({ mC: C, code: `${N.A}=${N.bx}(${N.A},${C}) ${roll(C)}` });
      } else if (mode === 1) {
        
        
        
        const ch = randInt(33, 126); const mask = randInt(1, 255);
        const C = ch ^ mask; EA ^= C;
        const rc = `${N.bx}(${N.sb}(${N.sc}(${ch})),${mask})`;
        anchorItems.push({ mC: C, code: `${N.A}=${N.bx}(${N.A},${rc}) ${roll(rc)}` });
      } else {
        
        const C = randInt(1, 255); EA ^= C;
        anchorItems.push({ mC: C, code: `if ${N.bx}(${randInt(1, 255)},0)>=0 then ${N.A}=${N.bx}(${N.A},${C}) ${roll(C)} end` });
      }
    }
  }
  const junkLines = [];
  const junkCount = 1 + randInt(0, 2);
  for (let q = 0; q < junkCount; q++) {
    const a = randInt(1,255), b = randInt(1,255), jn = randName('_j');
    const variants = [
      `local ${jn}=(${N.K1}*${a}+${N.K2}*${b})%256`,
      `local ${jn}=${N.bx}(${N.K3},${a})+${b}`,
      `local ${jn}=${N.bx}(${N.K2}*${a},${N.K4}*${b})%256`,
      `local ${jn}=(${N.K1}+${N.K5}-${a}+${b})%256`,
      `local ${jn}=${N.sf}(${N.K6},${N.K3})`,
      `local ${jn}=${N.bx}(${N.K7},${N.K8})+${a}`,
    ];
    junkLines.push(variants[randInt(0, variants.length-1)]);
  }
  const s1Block = [
    `local ${N.S1}={} for ${N.i}=0,255 do ${N.S1}[${N.i}]=${N.i} end`,
    `do local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+${N.S1}[${N.i}]+((${N.K1}*${N.i}+${N.K2})%256))%256 ${N.S1}[${N.i}],${N.S1}[${N.j}]=${N.S1}[${N.j}],${N.S1}[${N.i}] end end`,
    `local ${N.SI}={} for ${N.i}=0,255 do ${N.SI}[${N.S1}[${N.i}]]=${N.i} end`,
  ].join('\n');
  const s2Block = [
    `local ${N.S2}={} for ${N.i}=0,255 do ${N.S2}[${N.i}]=${N.i} end`,
    `do local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+${N.S2}[${N.i}]+((${N.K3}*${N.i}+${N.K4})%256))%256 ${N.S2}[${N.i}],${N.S2}[${N.j}]=${N.S2}[${N.j}],${N.S2}[${N.i}] end end`,
    `local ${N.KS}={}`,
    `do local ${N.kI},${N.kJ}=0,0`,
    `for ${N.n}=1,#${N.D} do`,
    `  ${N.kI}=(${N.kI}+1)%256`,
    `  ${N.kJ}=(${N.kJ}+${N.S2}[${N.kI}])%256`,
    `  ${N.S2}[${N.kI}],${N.S2}[${N.kJ}]=${N.S2}[${N.kJ}],${N.S2}[${N.kI}]`,
    `  ${N.KS}[${N.n}]=${N.S2}[(${N.S2}[${N.kI}]+${N.S2}[${N.kJ}])%256]`,
    `end end`,
  ].join('\n');
  const s3Block = [
    `local ${N.S3}={} for ${N.i}=0,255 do ${N.S3}[${N.i}]=${N.i} end`,
    `do local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+${N.S3}[${N.i}]+((${N.K5}*${N.i}+${N.K6})%256))%256 ${N.S3}[${N.i}],${N.S3}[${N.j}]=${N.S3}[${N.j}],${N.S3}[${N.i}] end end`,
    `local ${N.S3I}={} for ${N.i}=0,255 do ${N.S3I}[${N.S3}[${N.i}]]=${N.i} end`,
  ].join('\n');
  const s4Block = [
    `local ${N.KS2}={}`,
    `do local ${N.S2}2={} for ${N.i}=0,255 do ${N.S2}2[${N.i}]=${N.i} end`,
    `local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+${N.S2}2[${N.i}]+((${N.K6}*${N.i}+${N.K5})%256))%256 ${N.S2}2[${N.i}],${N.S2}2[${N.j}]=${N.S2}2[${N.j}],${N.S2}2[${N.i}] end`,
    `local ${N.kI2},${N.kJ2}=0,0`,
    `for ${N.n}=1,#${N.D} do`,
    `  ${N.kI2}=(${N.kI2}+1)%256`,
    `  ${N.kJ2}=(${N.kJ2}+${N.S2}2[${N.kI2}])%256`,
    `  ${N.S2}2[${N.kI2}],${N.S2}2[${N.kJ2}]=${N.S2}2[${N.kJ2}],${N.S2}2[${N.kI2}]`,
    `  ${N.KS2}[${N.n}]=${N.S2}2[(${N.S2}2[${N.kI2}]+${N.S2}2[${N.kJ2}])%256]`,
    `end end`,
  ].join('\n');
  const s0Block = [
    `local ${N.KS0}={}`,
    `do local _S0={} for ${N.i}=0,255 do _S0[${N.i}]=${N.i} end`,
    `local ${N.j}=0 for ${N.i}=0,255 do ${N.j}=(${N.j}+_S0[${N.i}]+((${N.K7}*${N.i}+${N.K8})%256))%256 _S0[${N.i}],_S0[${N.j}]=_S0[${N.j}],_S0[${N.i}] end`,
    `local _kI,_kJ=0,0`,
    `for ${N.n}=1,#${N.D} do`,
    `  _kI=(_kI+1)%256`,
    `  _kJ=(_kJ+_S0[_kI])%256`,
    `  _S0[_kI],_S0[_kJ]=_S0[_kJ],_S0[_kI]`,
    `  ${N.KS0}[${N.n}]=_S0[(_S0[_kI]+_S0[_kJ])%256]`,
    `end end`,
  ].join('\n');
  const sboxBlocks = shuffleLines([s1Block, s2Block, s3Block, s4Block, s0Block]);
  const decryptLines = [
    `local ${N.O}={}`,
    `local ${N.prev}=${N.bx}(${N.K3},${N.K4})%256`,
    `for ${N.i}=1,#${N.D} do`,
    `  local ${N.c}=${N.sb}(${N.D},${N.i})`,
    `  local ${N.c1}=${N.S3I}[${N.bx}(${N.c},${N.KS2}[${N.i}])]`,
    `  local ${N.b}=${N.bx}(${N.c1},${N.prev})`,
    `  ${N.b}=${N.bx}(${N.b},${N.KS}[${N.i}])`,
    `  ${N.b}=(${N.b}-${N.b}%${Q})/${Q}+(${N.b}%${Q})*${P}`,
    `  ${N.b}=${N.SI}[${N.b}]`,
    `  ${N.b}=${N.bx}(${N.b},(${N.K2}*${N.i}+${N.K3})%256)`,
    `  ${N.b}=(${N.b}-${N.i}*${N.K1})%256`,
    `  ${N.b}=${N.bx}(${N.b},${N.KS0}[${N.i}])`,
    `  ${N.b}=${N.bx}(${N.b},((${N.i}-1)*${N.K7}+${N.K8})%256)`,
    `  ${N.O}[${N.i}]=${N.b}`,
    `  ${N.prev}=${N.c1}`,
    `end`,
  ];
  const rleLines = [
    `local ${N.raw}={}`,
    `do local ${N.j}=1 local ${N.n}=1 local _len=#${N.O}`,
    `while ${N.j}<=_len do`,
    `  local _b=${N.O}[${N.j}]`,
    `  if _b==${RLE_ESC} then`,
    `    local _nx=${N.O}[${N.j}+1]`,
    `    if _nx==${RLE_ESC} then`,
    `      ${N.raw}[${N.n}]=${N.sc}(${RLE_ESC}) ${N.n}=${N.n}+1 ${N.j}=${N.j}+2`,
    `    else`,
    `      local _v=${N.O}[${N.j}+2]`,
    `      for _k=1,_nx do ${N.raw}[${N.n}]=${N.sc}(_v) ${N.n}=${N.n}+1 end`,
    `      ${N.j}=${N.j}+3`,
    `    end`,
    `  else`,
    `    ${N.raw}[${N.n}]=${N.sc}(_b) ${N.n}=${N.n}+1 ${N.j}=${N.j}+1`,
    `  end`,
    `end end`,
  ];
  
  
  
  
  
  const a85body = ascii85Encode(cipher);
  const chunkCount = 2 + randInt(0, 1);
  const cuts = [];
  for (let q = 1; q < chunkCount; q++) cuts.push(Math.floor((a85body.length * q) / chunkCount));
  cuts.sort((a, b) => a - b);
  const chunks = []; let last = 0;
  for (const cut of cuts) { if (cut > last) chunks.push(luaQuoteA85(a85body.slice(last, cut))); last = cut; }
  chunks.push(luaQuoteA85(a85body.slice(last)));
  const chunkNames = chunks.map(() => randName('_chk'));
  const chunkAssigns = chunks.map((c, idx) => `local ${chunkNames[idx]}=${c}`);
  const blobAssemble = `local ${N.D}=${N.dec}(${chunkNames.join('..')})`;
  const primDecls = [
    ...shuffleLines([
      `local ${N.sc}=string.char`,
      `local ${N.sb}=string.byte`,
      `local ${N.ss}=string.sub`,
      `local ${N.sr}=string.rep`,
      `local ${N.tc}=table.concat`,
      `local ${N.tn}=tonumber`,
    ]),
    `local function ${N.sf}(a,b) local r,p=0,1 for _=1,8 do local x,y=a%2,b%2 if x~=y then r=r+p end a,b,p=(a-x)/2,(b-y)/2,p*2 end return r end`,
    `local ${N.bx}=bit32 and bit32.bxor or ${N.sf}`,
    luaA85Decoder(N.dec),
  ];
  const NAME_LS = [108,111,97,100,115,116,114,105,110,103];
  const NAME_LD = [108,111,97,100];
  const encLS = NAME_LS.map((b, i) => (b ^ ((k7 + i) & 0xff)) & 0xff);
  const encLD = NAME_LD.map((b, i) => (b ^ ((k8 + i) & 0xff)) & 0xff);
  const lsLit = bytesToLuaLiteral(encLS);
  const ldLit = bytesToLuaLiteral(encLD);
  
  
  
  
  
  const recvLD = randName('_pl');
  const ldResolveLines = [
    `local ${recvLD}=(...)`,
    `local _enLS=${N.dec}(${lsLit})`,
    `local _bufLS={}`,
    `for ${N.i}=1,#_enLS do _bufLS[${N.i}]=${N.sc}(${N.bx}(${N.sb}(_enLS,${N.i}),(${N.K7}+${N.i}-1)%256)) end`,
    `local _nmLS=${N.tc}(_bufLS)`,
    `local _enLD=${N.dec}(${ldLit})`,
    `local _bufLD={}`,
    `for ${N.i}=1,#_enLD do _bufLD[${N.i}]=${N.sc}(${N.bx}(${N.sb}(_enLD,${N.i}),(${N.K8}+${N.i}-1)%256)) end`,
    `local _nmLD=${N.tc}(_bufLD)`,
    `local _env=(getfenv and getfenv(1)) or _G`,
    `local ${N.ld}=(type(${recvLD})=="function" and ${recvLD}) or _env[_nmLS] or _env[_nmLD] or (getfenv and getfenv(0) and getfenv(0)[_nmLS]) or (getfenv and getfenv(0) and getfenv(0)[_nmLD]) or loadstring or load or (_G and (_G[_nmLS] or _G[_nmLD]))`,
  ];
  const preKeyItems = [];
  for (const code of sanityPool) preKeyItems.push({ code });
  for (const code of chunkAssigns) preKeyItems.push({ code });
  if (opts.tamperLock) preKeyItems.push(...anchorItems);
  const midItems = shuffleLines(preKeyItems);
  
  
  
  
  let EM = 0;
  if (opts.tamperLock) for (const it of midItems) if (it.mC !== undefined) EM = (EM * ANCHOR_MULT + it.mC) % ANCHOR_MOD;
  const mid = midItems.map(it => it.code);
  const postKeyJunk = shuffleLines(junkLines);
  const allLines = [];
  allLines.push(...primDecls);
  allLines.push(`local ${N.P}=0`);
  if (opts.tamperLock) { allLines.push(`local ${N.A}=0`); allLines.push(`local ${N.M}=0`); }
  allLines.push(...mid);
  allLines.push(blobAssemble);
  
  
  
  if (opts.tamperLock) {
    allLines.push(`local ${N.G}=${N.bx}(${N.A},${EA})`);
    allLines.push(`local ${N.Gm}=(${N.M}+${(ANCHOR_MOD - (EM % ANCHOR_MOD)) % ANCHOR_MOD})%${ANCHOR_MOD}`);
  }
  allLines.push(...keyDerivLines);
  allLines.push(...postKeyJunk);
  allLines.push(...sboxBlocks);
  allLines.push(...decryptLines);
  allLines.push(...rleLines);
  allLines.push(`local ${N.src}=${N.tc}(${N.raw})`);
  allLines.push(...ldResolveLines);
  allLines.push(`local _ok,${N.f}=pcall(${N.ld},${N.src})`);
  
  
  
  
  allLines.push(`if _ok and type(${N.f})=="function" then return ${N.f}(${N.ld}) end`);
  allLines.push(`return (function() end)()`);
  return allLines.join('\n');
}













const PROXY_GLOBALS = new Set([
  'game','workspace','script','shared','print','warn','pairs','ipairs','next',
  'select','type','typeof','tostring','tonumber','pcall','xpcall','error',
  'assert','setmetatable','getmetatable','rawget','rawset','rawequal','rawlen',
  'unpack','collectgarbage','math','table','string','coroutine','os','task',
  'wait','spawn','delay','tick','time','require','newproxy',
  'Instance','Vector3','Vector2','Vector3int16','Vector2int16','CFrame','Color3',
  'UDim2','UDim','Enum','Ray','Region3','Rect','BrickColor','TweenInfo','Faces',
  'NumberSequence','NumberSequenceKeypoint','ColorSequence','ColorSequenceKeypoint',
  'NumberRange','PhysicalProperties','Random','DateTime','Axes','bit32','utf8','buffer',
]);




const STD_GLOBALS = new Set([
  'print','warn','error','assert','pcall','xpcall','select','type','typeof',
  'tostring','tonumber','ipairs','pairs','next','unpack','rawget','rawset',
  'rawequal','rawlen','setmetatable','getmetatable','require','tick','time',
  'wait','spawn','delay','newproxy','collectgarbage','gcinfo','loadstring',
  'load','getfenv','setfenv','string','table','math','coroutine','os','debug',
  'utf8','bit32','task','game','workspace','script','shared','_G','_ENV',
  'buffer','vector','Enum','Instance','Vector2','Vector3','Vector2int16',
  'Vector3int16','CFrame','Color3','UDim','UDim2','Ray','Region3','Rect',
  'BrickColor','TweenInfo','Faces','Axes','Random','DateTime','PhysicalProperties',
  'NumberRange','NumberSequence','NumberSequenceKeypoint','ColorSequence',
  'ColorSequenceKeypoint','_VERSION','self',
]);











function sliceIsSelfContained(tokens, start, endIdx, provided) {
  const bound = collectBindingNames(tokens.slice(start, endIdx + 1));
  for (let k = start; k <= endIdx; k++) {
    const t = tokens[k];
    if (t.type !== 'identifier') continue;
    const v = t.value;
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(v)) continue; 
    const prev = prevSignificantToken(tokens, k);
    if (prev && prev.type === 'operator' && (prev.value === '.' || prev.value === ':')) continue; 
    if (bound.has(v)) continue;
    if (STD_GLOBALS.has(v) || PROXY_GLOBALS.has(v)) continue;
    if (provided && provided.has(v)) continue;
    return false; 
  }
  return true;
}



function collectBindingNames(tokens) {
  const bound = new Set();
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (t.type !== 'keyword') continue;
    if (t.value === 'local') {
      let j = i + 1;
      while (j < tokens.length && ['whitespace','comment','longcomment'].includes(tokens[j].type)) j++;
      if (tokens[j] && tokens[j].type === 'keyword' && tokens[j].value === 'function') {
        j++;
        while (j < tokens.length && ['whitespace','comment','longcomment'].includes(tokens[j].type)) j++;
        if (tokens[j] && tokens[j].type === 'identifier') bound.add(tokens[j].value);
        continue;
      }
      while (j < tokens.length) {
        const tj = tokens[j];
        if (['whitespace','comment','longcomment'].includes(tj.type)) { j++; continue; }
        if (tj.type === 'identifier') { bound.add(tj.value); j++; continue; }
        if (tj.type === 'operator' && tj.value === ',') { j++; continue; }
        break;
      }
      continue;
    }
    if (t.value === 'function') {
      let j = i + 1;
      while (j < tokens.length && tokens[j].value !== '(') {
        if (tokens[j].type === 'keyword' && ['end','function'].includes(tokens[j].value)) break;
        j++;
      }
      if (tokens[j] && tokens[j].value === '(') {
        j++;
        while (j < tokens.length && tokens[j].value !== ')') {
          if (tokens[j].type === 'identifier') bound.add(tokens[j].value);
          j++;
        }
      }
      continue;
    }
    if (t.value === 'for') {
      let j = i + 1;
      while (j < tokens.length) {
        const tj = tokens[j];
        if (['whitespace','comment','longcomment'].includes(tj.type)) { j++; continue; }
        if (tj.type === 'identifier') { bound.add(tj.value); j++; continue; }
        if (tj.type === 'operator' && tj.value === ',') { j++; continue; }
        break;
      }
      continue;
    }
  }
  return bound;
}
function proxifyGlobals(tokens, vault, proxyName) {
  const bound = collectBindingNames(tokens);
  let count = 0;
  const out = tokens.map((t, idx) => {
    if (t.type !== 'identifier') return t;
    if (!PROXY_GLOBALS.has(t.value)) return t;
    if (bound.has(t.value)) return t;              
    const prev = prevSignificantToken(tokens, idx);
    if (prev && prev.type === 'operator' && (prev.value === '.' || prev.value === ':')) return t; 
    const nxt = nextSignificantToken(tokens, idx);
    if (nxt && nxt.type === 'operator' && nxt.value === '=') return t; 
    if (isInTypePosition(tokens, idx)) return t;
    const id = vault.add(t.value);
    count++;
    
    
    
    return { type: 'identifier', value: `${proxyName}[${id}]` };
  });
  return { tokens: out, count };
}


function buildGlobalProxyDecl(proxyName, envName, accessorName) {
  
  
  
  
  return [
    `local ${envName}=(getfenv and getfenv(1)) or _G`,
    `local ${proxyName}=setmetatable({},{__index=function(_,id) return ${envName}[${accessorName}(id)] end})`,
  ].join('\n');
}




function obfuscate(src, opts) {
  if (!src.trim()) return '';
  const intensity = Math.min(Math.max(opts.intensity, 1), 5);
  seedRng((Date.now() ^ (src.length * 2654435761)) >>> 0);
  _nameCounter = 0;
  let tokens = tokenize(src);
  if (opts.removeComments) {
    tokens = tokens.map(t => (t.type === 'comment' || t.type === 'longcomment') ? { type: 'whitespace', value: ' ' } : t);
  }
  const vault = new StringVault();
  const vaultAccessor = randName('_V');
  const vaultName = randName('_vault');
  const loaderName = randName('_LD');
  const proxyName = randName('_G');
  const envName = randName('_E');
  let proxyUsed = false;
  if (opts.proxyGlobals) {
    const pr = proxifyGlobals(tokens, vault, proxyName);
    tokens = pr.tokens; proxyUsed = pr.count > 0;
  }
  if (opts.encryptStrings) tokens = replaceStringsWithVault(tokens, vault, vaultAccessor);
  if (opts.encFunc && intensity >= 3) tokens = encryptFunctionsPass(tokens, vault, vaultAccessor, loaderName, (opts.proxyGlobals && proxyUsed) ? proxyName : null);
  tokens = tokens.map((t, idx) => {
    if (t.type === 'number' && opts.obfuscateNumbers) {
      if (isInTypePosition(tokens, idx)) return t;
      return { type: 'identifier', value: obfuscateNumber(t.value, intensity) };
    }
    if (t.type === 'keyword' && opts.obfuscateBooleans && ['true','false','nil'].includes(t.value)) {
      if (isInTypePosition(tokens, idx)) return t;
      return { type: 'identifier', value: obfuscateBool(t.value) };
    }
    return t;
  });
  let body = tokens.map(t => t.value).join('');
  if (vault.size() > 0) {
    
    
    if (opts.encryptStrings || opts.proxyGlobals) {
      const decoyWords = ['GetService','HttpService','LocalPlayer','Character','Humanoid',
        'RemoteEvent','FireServer','WaitForChild','Parent','Value','__index','__namecall',
        'PlayerAdded','Heartbeat','RunService','userId','DataStore','_secret_key_','session'];
      const decoyCount = 3 + randInt(0, 6);
      for (let d = 0; d < decoyCount; d++) {
        let s = decoyWords[randInt(0, decoyWords.length - 1)];
        s += '_' + randInt(0, 0xffffff).toString(16);
        vault.add(s);
      }
    }
    const vaultDecl = vault.build(rng(), vaultAccessor, vaultName);
    const proxyDecl = (opts.proxyGlobals && proxyUsed)
      ? buildGlobalProxyDecl(proxyName, envName, vaultAccessor) + '\n' : '';
    const loaderDecl = opts.encFunc ? `local ${loaderName}=loadstring or load\n` : '';
    body = `${vaultDecl}\n${proxyDecl}${loaderDecl}${body}`;
  }
  if (opts.injectJunk) { const junk = generateJunk(intensity); body = `${junk}do\n${body}\nend`; }
  if (opts.controlFlow && intensity >= 2) body = flattenControlFlow(body, intensity);
  if (opts.vmWrap) {
    const layers = Math.max(1, Math.min(3, intensity - 1));
    for (let l = 0; l < layers; l++) body = buildVmLoader(body, l, { antiHook: opts.antiHook, tamperLock: opts.tamperLock });
  } else if (opts.tamperLock || opts.antiHook) {
    body = buildVmLoader(body, 0, { antiHook: opts.antiHook, tamperLock: opts.tamperLock });
  }
  return prettyLayout(body, opts);
}




  const OUTPUT_HEADER = '-- This file was protected using Luna Obfuscator v1.1 [https://luna.xephex.xyz/]';







  const DECOMP_LABEL = 'Luna';


















function somtankPack(str) {
  const bytes = Array.from(new TextEncoder().encode(str));
  while (bytes.length % 4 !== 0) bytes.push(0x20); 
  let out = '';
  for (let i = 0; i < bytes.length; i += 4) {
    let n = bytes[i] + bytes[i + 1] * 256 + bytes[i + 2] * 65536 + bytes[i + 3] * 16777216;
    if (n === 0) { out += 'z'; continue; }
    let chunk = '';
    for (let k = 0; k < 5; k++) { chunk = String.fromCharCode(33 + (n % 85)) + chunk; n = Math.floor(n / 85); }
    out += chunk;
  }
  return 'LPH%' + out;
}


function longBracket(s) {
  let eq = 1;
  while (s.indexOf(']' + '='.repeat(eq) + ']') !== -1) eq++;
  const pad = '='.repeat(eq);
  return { open: '[' + pad + '[', close: ']' + pad + ']' };
}






function somtankPackBytes(bytes) {
  const b = Array.from(bytes);
  while (b.length % 4 !== 0) b.push(0x20); 
  let out = '';
  for (let i = 0; i < b.length; i += 4) {
    let n = b[i] + b[i + 1] * 256 + b[i + 2] * 65536 + b[i + 3] * 16777216;
    if (n === 0) { out += 'z'; continue; }
    let chunk = '';
    for (let k = 0; k < 5; k++) { chunk = String.fromCharCode(33 + (n % 85)) + chunk; n = Math.floor(n / 85); }
    out += chunk;
  }
  return 'LPH%' + out;
}








function zstdRawFrame(input) {
  const bytes = Array.from(input);
  const size = bytes.length;
  const out = [0x28, 0xB5, 0x2F, 0xFD, 0xA0,
    size & 0xFF, (size >>> 8) & 0xFF, (size >>> 16) & 0xFF, (size >>> 24) & 0xFF];
  const MAX = 65536; 
  if (size === 0) {
    const v = (0 << 3) | 1; 
    out.push(v & 0xFF, (v >>> 8) & 0xFF, (v >>> 16) & 0xFF);
  } else {
    for (let i = 0; i < size; i += MAX) {
      const bs = Math.min(MAX, size - i);
      const last = (i + bs >= size) ? 1 : 0;
      const v = (bs << 3) | last; 
      out.push(v & 0xFF, (v >>> 8) & 0xFF, (v >>> 16) & 0xFF);
      for (let k = 0; k < bs; k++) out.push(bytes[i + k]);
    }
  }
  return out;
}
function prettyLayout(body, opts) {
  
  
  const chunk = body.split('\n').map(l => l.trim()).filter(Boolean).join('\n');

  
  
  
  
  
  
  const vmCode = 'local b=...;return(loadstring or load)(b)()';
  const enc = new TextEncoder();
  const rBytes = enc.encode(vmCode); 
  const pBytes = enc.encode(chunk);  
  const rBlob = somtankPackBytes(rBytes);
  const pBlob = somtankPackBytes(pBytes);
  const rB = longBracket(rBlob);
  const pB = longBracket(pBlob);
  const L = DECOMP_LABEL; 

  
  
  
  
  
  const loader =
    'local P,v,S,j,e,R,n,g,G,K,E,x=setmetatable,string.gsub,string.pack,type,pcall,{},string.byte,string.char,string.sub,5,loadstring,tostring;' +
    'for _=0,255 do R[_]=g(_);end;R=unpack;' +
    'do local _={46979,{0x1B,0x4C,0x75,0x61,0x50},x(E)};for N,k in _ do local _={e(E,N%2==0 and g(R(k))or k,nil,nil)};if _[1]and e(_[2])~=not _[3]then K=10.0;end;end;end;' +
    'g=function(_)_=G(_,K);_=v(_,"z","!!!!!");return v(_,".....",P({},{__index=function(P,v)local G,K,_,N,k=n(v,1,5);local n=(k-33)+(N-33)*85+(_-33)*7225+(K-33)*614125+(G-33)*52200625;N=S("<I4",n);P[v]=N;return N;end}));end;' +
    'R=g(' + rB.open + rBlob + rB.close + ');' +
    'P=g(' + pB.open + pBlob + pB.close + ');' +
    'local v=assert;' +
    'R=string.sub(R,1,' + rBytes.length + ');' +
    'P=string.sub(P,1,' + pBytes.length + ');' +
    'local n=R;' +
    'R=string.rep;' +
    'local G=P;' +
    'P,g=e(E,n,' + JSON.stringify(L) + '..R(" ",3),nil);' +
    'v(P and g and j(g)==\'function\',' + JSON.stringify(L + ' decompression error: ') + '..x(g)..' + JSON.stringify(' (does your environment support load/loadstring?)') + ');' +
    'return g(G);';
  return `${OUTPUT_HEADER}\n\nreturn(function()${loader}end)()(...);`;
}

// ---- Preset ระดับ (ตรงกับ intensity slider + DEFAULTS ของหน้าเว็บ) ----
const DEFAULTS = {
  removeComments: true, encryptStrings: true, obfuscateNumbers: true,
  obfuscateBooleans: true, injectJunk: true, vmWrap: true, tamperLock: true,
  stringVault: true, controlFlow: true, antiHook: true, proxyGlobals: true,
  encFunc: false, intensity: 4,
};

const INTENSITY_LABELS = ['MINIMAL', 'BASIC', 'PREMIUM', 'COMMERCIAL', 'ENTERPRISE'];

/**
 * สร้าง options สำหรับระดับที่เลือก (1-5 หรือชื่อ label)
 * ใช้ DEFAULTS ของหน้าเว็บทุกตัว เปลี่ยนแค่ intensity ตามระดับที่เลือก
 * (เหมือนกับตอนที่ผู้ใช้บนเว็บลาก slider โดยไม่แตะ toggle อื่นเลย)
 */
function optionsForLevel(level) {
  let intensity;
  if (typeof level === 'number') {
    intensity = level;
  } else {
    intensity = INTENSITY_LABELS.indexOf(String(level).toUpperCase()) + 1;
  }
  intensity = Math.min(Math.max(intensity, 1), 5);
  return { ...DEFAULTS, intensity };
}

module.exports = {
  obfuscate,
  DEFAULTS,
  INTENSITY_LABELS,
  optionsForLevel,
};
