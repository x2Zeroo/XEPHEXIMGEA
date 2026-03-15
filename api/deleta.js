module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method not allowed' }); return; }

  var GITHUB_TOKEN  = process.env.GITHUB_TOKEN  || '';
  var GITHUB_OWNER  = process.env.GITHUB_OWNER  || '';
  var GITHUB_REPO   = process.env.GITHUB_REPO   || '';
  var GITHUB_BRANCH = process.env.GITHUB_BRANCH || 'main';

  if (!GITHUB_TOKEN || !GITHUB_OWNER || !GITHUB_REPO) {
    res.status(500).json({ error: 'Server misconfigured' }); return;
  }

  var body = await new Promise(function(resolve, reject) {
    var chunks = [];
    req.on('data', function(c) { chunks.push(c); });
    req.on('end', function() { resolve(Buffer.concat(chunks).toString('utf8')); });
    req.on('error', reject);
  });

  var data;
  try { data = JSON.parse(body); } catch(e) {
    res.status(400).json({ error: 'Invalid JSON' }); return;
  }

  var filePath = (data.path || '').replace(/\.\./g, '').replace(/^\/+/, '');
  if (!filePath) { res.status(400).json({ error: 'Missing path' }); return; }

  var apiUrl = 'https://api.github.com/repos/' + GITHUB_OWNER + '/' + GITHUB_REPO + '/contents/' + filePath;

  var sha;
  try {
    var chk = await fetch(apiUrl, {
      headers: {
        'Authorization': 'Bearer ' + GITHUB_TOKEN,
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      }
    });
    if (!chk.ok) {
      if (chk.status === 404) { res.status(404).json({ error: 'ไม่พบไฟล์บนเซิฟเวอร์' }); return; }
      res.status(chk.status).json({ error: 'Server error ' + chk.status }); return;
    }
    sha = (await chk.json()).sha;
  } catch(err) {
    res.status(502).json({ error: 'เชื่อมต่อไม่ได้: ' + err.message }); return;
  }

  var delRes;
  try {
    delRes = await fetch(apiUrl, {
      method: 'DELETE',
      headers: {
        'Authorization': 'Bearer ' + GITHUB_TOKEN,
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message: 'Delete ' + filePath, sha: sha, branch: GITHUB_BRANCH }),
    });
  } catch(err) {
    res.status(502).json({ error: 'เชื่อมต่อไม่ได้: ' + err.message }); return;
  }

  if (!delRes.ok) {
    var e = await delRes.json().catch(function() { return {}; });
    res.status(502).json({ error: e.message || 'Delete error ' + delRes.status }); return;
  }

  try {
    var metaUrl = 'https://api.github.com/repos/' + GITHUB_OWNER + '/' + GITHUB_REPO + '/contents/' + filePath + '.meta.json';
    var metaChk = await fetch(metaUrl, {
      headers: { 'Authorization': 'Bearer ' + GITHUB_TOKEN, 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28' }
    });
    if (metaChk.ok) {
      var metaSha = (await metaChk.json()).sha;
      await fetch(metaUrl, {
        method: 'DELETE',
        headers: { 'Authorization': 'Bearer ' + GITHUB_TOKEN, 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: 'Delete meta ' + filePath, sha: metaSha, branch: GITHUB_BRANCH }),
      });
    }
  } catch(_) {}

  res.status(200).json({ success: true, deleted: filePath });
};
