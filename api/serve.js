module.exports = async function handler(req, res) {
  var SUPABASE_URL    = process.env.SUPABASE_URL || '';
  var SUPABASE_BUCKET = process.env.SUPABASE_BUCKET || 'cloudzone';

  if (!SUPABASE_URL) { res.status(500).send('Server misconfigured'); return; }

  var rawPath = req.query.path;
  if (Array.isArray(rawPath)) rawPath = rawPath.join('/');
  var filePath = (rawPath || '').replace(/\.\./g, '').replace(/^\/+/, '');
  if (!filePath) { res.status(400).send('Missing path'); return; }

  var base = SUPABASE_URL.replace(/\/+$/, '');
  var publicUrl = base + '/storage/v1/object/public/' + SUPABASE_BUCKET + '/' + filePath;

  var accept = req.headers['accept'] || '';
  var ua = (req.headers['user-agent'] || '').toLowerCase();
  var isBot = /discordbot|facebookexternalhit|twitterbot|telegrambot|slackbot|whatsapp|linkedinbot|line poker/.test(ua);
  var wantsHtml = accept.indexOf('text/html') !== -1 && !isBot;

  if (!wantsHtml) {
    try {
      var fileRes = await fetch(publicUrl);
      if (!fileRes.ok) { res.status(404).send('Not found'); return; }
      res.setHeader('Content-Type', fileRes.headers.get('content-type') || 'application/octet-stream');
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      var buf = Buffer.from(await fileRes.arrayBuffer());
      res.status(200).send(buf);
    } catch(err) {
      res.status(502).send('Fetch error: ' + err.message);
    }
    return;
  }

  var headRes;
  try {
    headRes = await fetch(publicUrl, { method: 'HEAD' });
  } catch(err) {
    res.status(502).send('Fetch error: ' + err.message); return;
  }
  if (!headRes.ok) { res.status(404).send('ไม่พบไฟล์'); return; }

  var mime = headRes.headers.get('content-type') || 'application/octet-stream';
  var sizeHeader = headRes.headers.get('content-length');
  var fileName = filePath.split('/').pop();
  var isImage = mime.indexOf('image/') === 0;
  var isVideo = mime.indexOf('video/') === 0;
  var textExts = ['.lua','.js','.ts','.txt','.json','.md','.css','.html','.xml','.yml','.yaml','.log','.csv','.py','.sh','.c','.cpp','.java','.rb','.go','.rs'];
  var fileExt = (fileName.match(/\.[^.]+$/) || [''])[0].toLowerCase();
  var isText = mime.indexOf('text/') === 0 || mime === 'application/json' || textExts.indexOf(fileExt) !== -1;

  var mediaHtml;
  if (isImage) {
    mediaHtml = '<img src="' + escAttr(publicUrl) + '" alt="' + escAttr(fileName) + '">';
  } else if (isVideo) {
    mediaHtml = '<video src="' + escAttr(publicUrl) + '" controls playsinline autoplay muted loop></video>';
  } else if (isText) {
    var textRes = await fetch(publicUrl);
    var textContent = await textRes.text();
    var textHtml = '<!DOCTYPE html><html><head><meta charset="UTF-8">'
      + '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
      + '<title>' + esc(fileName) + '</title>'
      + '<style>'
      + '*{box-sizing:border-box}'
      + 'body{margin:0;padding:0}'
      + 'pre{margin:0;padding:16px;padding-top:52px;font-family:monospace;font-size:13px;white-space:pre-wrap;word-break:break-word}'
      + '.dl-btn{position:fixed;top:10px;right:10px;width:38px;height:38px;display:flex;align-items:center;justify-content:center;background:#fff;border:1px solid #ccc;border-radius:8px;color:#333;text-decoration:none;box-shadow:0 1px 4px rgba(0,0,0,.2)}'
      + '.dl-btn:hover{background:#f0f0f0}'
      + '</style></head><body>'
      + '<a class="dl-btn" href="' + escAttr(publicUrl) + '" download="' + escAttr(fileName) + '" title="ดาวน์โหลด">'
      + '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="18" height="18"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>'
      + '</a>'
      + '<pre>' + esc(textContent) + '</pre>'
      + '</body></html>';
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(textHtml);
    return;
  } else {
    mediaHtml = '<div class="file-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="72" height="72"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg><div class="file-name-big">' + esc(fileName) + '</div></div>';
  }

  var html = '<!DOCTYPE html><html lang="th"><head><meta charset="UTF-8">'
    + '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
    + '<title>' + esc(fileName) + ' — CloudZone</title>'
    + '<meta property="og:type" content="website">'
    + '<meta property="og:title" content="' + escAttr(fileName) + '">'
    + '<meta property="og:site_name" content="CloudZone">'
    + (isImage
        ? '<meta property="og:image" content="' + escAttr(publicUrl) + '">'
          + '<meta name="twitter:card" content="summary_large_image">'
          + '<meta name="twitter:image" content="' + escAttr(publicUrl) + '">'
        : '')
    + (isVideo
        ? '<meta property="og:video" content="' + escAttr(publicUrl) + '">'
          + '<meta property="og:video:secure_url" content="' + escAttr(publicUrl) + '">'
          + '<meta property="og:video:type" content="' + escAttr(mime) + '">'
          + '<meta property="og:video:width" content="1280">'
          + '<meta property="og:video:height" content="720">'
          + '<meta name="twitter:card" content="player">'
          + '<meta name="twitter:player" content="' + escAttr(publicUrl) + '">'
          + '<meta name="twitter:player:width" content="1280">'
          + '<meta name="twitter:player:height" content="720">'
        : '')
    + '<style>'
    + ':root{--bg:#00060f;--card:#00111f;--border:#0a4060;--accent:#00d4ff;--text:#c8eeff}'
    + '*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}'
    + 'body{background:var(--bg);color:var(--text);font-family:Sarabun,sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}'
    + '.stage{position:relative;width:min(92vw,1100px);max-width:1100px;max-height:92vh;background:var(--card);border:1px solid var(--border);border-radius:14px;overflow:hidden;box-shadow:0 0 40px rgba(0,212,255,.15)}'
    + '.stage img,.stage video{display:block;max-width:100%;max-height:88vh;width:auto;height:auto;margin:0 auto}'
    + '.file-icon{display:flex;flex-direction:column;align-items:center;gap:16px;padding:60px 40px;color:var(--accent)}'
    + '.file-name-big{font-size:1rem;color:var(--text);word-break:break-all;text-align:center}'
    + '.dl-btn{position:absolute;top:12px;right:12px;width:42px;height:42px;display:flex;align-items:center;justify-content:center;background:rgba(0,20,35,.85);border:1px solid var(--accent);border-radius:10px;color:var(--accent);text-decoration:none;backdrop-filter:blur(6px);box-shadow:0 0 14px rgba(0,212,255,.3);transition:transform .15s,box-shadow .15s}'
    + '.dl-btn:hover{transform:translateY(-2px);box-shadow:0 0 20px rgba(0,212,255,.5)}'
    + '</style></head><body>'
    + '<div class="stage">'
    + mediaHtml
    + '<a class="dl-btn" href="' + escAttr(publicUrl) + '" download="' + escAttr(fileName) + '" title="ดาวน์โหลด">'
    + '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="20" height="20"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>'
    + '</a></div></body></html>';

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.status(200).send(html);
};

function esc(str) {
  return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function escAttr(str) {
  return esc(str).replace(/"/g,'&quot;');
}
