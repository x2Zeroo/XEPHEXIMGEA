"use strict";

/**
 * Luna Obfuscator - Lua / Luau obfuscation engine
 *
 * เทคนิค: onion-layered encoding
 *  - แต่ละ layer จะเข้ารหัสโค้ดทั้งไฟล์ด้วย rotating key (+key mod 256)
 *  - แล้ว emit ตัว loader ภาษา Lua ที่ decode กลับ + เรียก loadstring/load
 *  - หลาย layer = ห่อซ้อนกันหลายชั้น (ยิ่งระดับสูง ยิ่งหลายชั้น)
 *  - output เป็น Lua/Luau ที่รันได้จริงบน executor (loadstring or load)
 */

// ลำดับความแรงของระดับ (น้อย -> มาก)
const LEVEL_ORDER = ["MINIMAL", "BASIC", "PREMIUM", "COMMERCIAL", "ENTERPRISE"];

const LEVELS = {
  MINIMAL: { label: "Minimal", layers: 1, minify: false, junk: false },
  BASIC: { label: "Basic", layers: 1, minify: true, junk: false },
  PREMIUM: { label: "Premium", layers: 2, minify: true, junk: false },
  COMMERCIAL: { label: "Commercial", layers: 3, minify: true, junk: true },
  ENTERPRISE: { label: "Enterprise", layers: 4, minify: true, junk: true },
};

function randInt(max) {
  return Math.floor(Math.random() * max);
}

// สร้างชื่อตัวแปร Lua ที่ถูกต้อง (ขึ้นต้นด้วยตัวอักษร)
function randName(len = 6) {
  const first = "abcdefghijklmnopqrstuvwxyz";
  const rest = first + "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
  let s = first[randInt(first.length)];
  for (let i = 1; i < len; i++) s += rest[randInt(rest.length)];
  return s;
}

/**
 * ลบ comment ของ Lua อย่างปลอดภัย (เคารพ string literal และ long bracket)
 * ถ้ามีอะไรผิดปกติจะคืน source เดิม เพื่อไม่ให้สคริปต์พัง
 */
function safeMinify(src) {
  try {
    let out = "";
    let i = 0;
    const n = src.length;
    while (i < n) {
      const ch = src[i];

      // string literal " หรือ '
      if (ch === '"' || ch === "'") {
        const q = ch;
        out += ch;
        i++;
        while (i < n) {
          const c = src[i];
          out += c;
          if (c === "\\") {
            out += src[i + 1] || "";
            i += 2;
            continue;
          }
          i++;
          if (c === q) break;
        }
        continue;
      }

      // long bracket string [[ ]] / [=[ ]=]
      if (ch === "[") {
        const m = /^\[(=*)\[/.exec(src.slice(i));
        if (m) {
          const eq = m[1];
          const close = "]" + eq + "]";
          const end = src.indexOf(close, i + m[0].length);
          const seg = end === -1 ? src.slice(i) : src.slice(i, end + close.length);
          out += seg;
          i += seg.length;
          continue;
        }
      }

      // comment
      if (ch === "-" && src[i + 1] === "-") {
        const m = /^--\[(=*)\[/.exec(src.slice(i));
        if (m) {
          const eq = m[1];
          const close = "]" + eq + "]";
          const end = src.indexOf(close, i + m[0].length);
          i = end === -1 ? n : end + close.length;
          continue;
        } else {
          while (i < n && src[i] !== "\n") i++;
          continue;
        }
      }

      out += ch;
      i++;
    }

    // ตัดช่องว่างท้ายบรรทัด + รวมบรรทัดว่างซ้ำ
    out = out
      .split("\n")
      .map((l) => l.replace(/\s+$/, ""))
      .filter((l, idx, arr) => !(l.trim() === "" && (arr[idx - 1] || "").trim() === ""))
      .join("\n");

    return out;
  } catch (e) {
    return src;
  }
}

// junk / dead code (valid Lua, ไม่กระทบการทำงาน)
function generateJunk() {
  const lines = [];
  const count = 2 + randInt(3);
  for (let i = 0; i < count; i++) {
    const v = randName();
    const kind = randInt(3);
    if (kind === 0) lines.push(`local ${v}=function() return ${randInt(99999)} end`);
    else if (kind === 1) lines.push(`local ${v}=${randInt(999999)}*${randInt(999) + 1}`);
    else lines.push(`local ${v}="${randName(4 + randInt(8))}"`);
  }
  return lines.join("\n") + "\n";
}

// เข้ารหัส 1 ชั้น -> คืน loader Lua ที่ decode กลับได้
function encodeLayer(source) {
  const keyLen = 8 + randInt(8);
  const key = [];
  for (let i = 0; i < keyLen; i++) key.push(randInt(255) + 1); // 1..255

  const bytes = Buffer.from(source, "utf8");
  let encoded = "";
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i];
    const k = key[i % keyLen];
    const c = (b + k) % 256;
    encoded += "\\" + c; // decimal escape ของ Lua string
  }

  // สุ่มชื่อตัวแปรทุกครั้ง
  const vD = randName();
  const vK = randName();
  const vN = randName();
  const vO = randName();
  const vI = randName();
  const vC = randName();
  const vKK = randName();
  const vB = randName();

  return (
    `local ${vD}="${encoded}"\n` +
    `local ${vK}={${key.join(",")}}\n` +
    `local ${vN}=#${vK}\n` +
    `local ${vO}={}\n` +
    `for ${vI}=1,#${vD} do\n` +
    `local ${vC}=${vD}:byte(${vI})\n` +
    `local ${vKK}=${vK}[((${vI}-1)%${vN})+1]\n` +
    `${vO}[${vI}]=string.char((${vC}-${vKK})%256)\n` +
    `end\n` +
    `local ${vB}=table.concat(${vO})\n` +
    `return assert((loadstring or load)(${vB}))()`
  );
}

/**
 * obfuscate(source, levelKey)
 * @param {string} source - โค้ด Lua ต้นฉบับ
 * @param {string} levelKey - MINIMAL | BASIC | PREMIUM | COMMERCIAL | ENTERPRISE
 * @returns {string} โค้ดที่ obfuscate แล้ว
 */
function obfuscate(source, levelKey) {
  const lvl = LEVELS[levelKey];
  if (!lvl) throw new Error("Unknown level: " + levelKey);

  let code = String(source);
  if (lvl.minify) code = safeMinify(code);

  let out = code;
  for (let i = 0; i < lvl.layers; i++) {
    out = encodeLayer(out);
  }

  let header = `-- This file was protected using Luna Obfuscator [${lvl.label}]\n`;
  if (lvl.junk) header += generateJunk();

  return header + out;
}

module.exports = { obfuscate, LEVELS, LEVEL_ORDER };
