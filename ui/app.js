// Update driver for the blank template shell.
// Uses the global Tauri API (app.withGlobalTauri = true in tauri.conf.json):
// no bundler and no npm packages are needed for the interface.
const { getVersion } = window.__TAURI__.app;
const { check } = window.__TAURI__.updater;
const { relaunch } = window.__TAURI__.process;

const el = (id) => document.getElementById(id);
let pendingUpdate = null;

function setState(text) {
  el('upd-state').textContent = text;
}

function logLine(text) {
  const log = el('upd-log');
  const time = new Date().toLocaleTimeString();
  log.textContent += `[${time}] ${text}\n`;
  log.scrollTop = log.scrollHeight;
}

async function init() {
  try {
    el('version').textContent = 'v' + (await getVersion());
  } catch (err) {
    logLine('Could not read the app version: ' + err);
  }
}

async function checkNow() {
  el('btn-check').disabled = true;
  setState('checking...');
  try {
    const update = await check();
    if (!update) {
      setState('up to date');
      logLine('No update available. You are on the newest version.');
      el('btn-check').disabled = false;
      return;
    }
    pendingUpdate = update;
    setState('update available: ' + update.version);
    logLine(`Update found: ${update.version} (current: ${update.currentVersion}).`);
    el('btn-download').disabled = false;
  } catch (err) {
    setState('check failed');
    logLine('Update check failed: ' + err);
    el('btn-check').disabled = false;
  }
}

async function downloadAndInstall() {
  if (!pendingUpdate) return;
  el('btn-download').disabled = true;
  setState('downloading...');
  let downloaded = 0;
  let total = 0;
  try {
    await pendingUpdate.downloadAndInstall((event) => {
      if (event.event === 'Started') {
        total = event.data.contentLength || 0;
        logLine(`Download started (${total} bytes).`);
      } else if (event.event === 'Progress') {
        downloaded += event.data.chunkLength;
        if (total > 0) {
          el('upd-bar').style.width = Math.round((downloaded / total) * 100) + '%';
        }
      } else if (event.event === 'Finished') {
        el('upd-bar').style.width = '100%';
        logLine('Download finished.');
      }
    });
    setState('update installed - restart to apply');
    logLine('Update installed. Restart the app to apply it.');
    el('btn-restart').classList.remove('hidden');
  } catch (err) {
    setState('install failed');
    logLine('Download/install failed: ' + err);
    el('btn-download').disabled = false;
  }
}

el('btn-check').addEventListener('click', checkNow);
el('btn-download').addEventListener('click', downloadAndInstall);
el('btn-restart').addEventListener('click', () => relaunch());
init();
