(function(){
  const overlay = document.getElementById('langOverlay');
  const langButtons = document.querySelectorAll('[data-lang]');
  const stored = localStorage.getItem('mfm_lang');
  const browser = navigator.language || 'de';
  const defaultLang = stored || (browser.startsWith('en') ? 'en' : 'de');
  const isEn = window.location.pathname.toLowerCase().includes('/en/');
  const currentLang = isEn ? 'en' : 'de';
  const pageId = document.body.dataset.page || '';

  function toDateString(d){
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + day;
  }

  function parseDateString(value){
    if (!value) return null;
    const parts = value.split('-');
    if (parts.length !== 3) return null;
    const y = parseInt(parts[0], 10);
    const m = parseInt(parts[1], 10);
    const d = parseInt(parts[2], 10);
    if (!y || !m || !d) return null;
    return new Date(y, m - 1, d);
  }

  function hasAccess(){
    return document.body.classList.contains('has-access') || document.body.dataset.hasAccess === 'true';
  }

  function getStartDate(allowStart){
    const stored = localStorage.getItem('mfm_start_date');
    const parsed = parseDateString(stored);
    if (parsed) return parsed;
    if (!allowStart) return null;
    const now = new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    localStorage.setItem('mfm_start_date', toDateString(start));
    return start;
  }

  function getUnlockedDays(allowStart){
    const start = getStartDate(allowStart);
    if (!start) return 0;
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const diffMs = today - start;
    const days = Math.floor(diffMs / 86400000) + 1;
    if (days < 1) return 1;
    const maxDays = hasAccess() ? 20 : 5;
    if (days > maxDays) return maxDays;
    return days;
  }

  function updateCourseLocks(){
    if (pageId !== 'kurs') return;
    const unlocked = Math.max(getUnlockedDays(false), 1);
    const lockedLabel = document.body.dataset.lockedLabel || (currentLang === 'en' ? 'Locked' : 'Gesperrt');
    const openLabel = document.body.dataset.openLabel || (currentLang === 'en' ? 'Start' : 'Starten');
    document.querySelectorAll('.day-card').forEach(card => {
      const day = parseInt(card.dataset.day, 10);
      if (!day) return;
      const status = card.querySelector('.open, .lock') || card.querySelector('span');
      const isOpen = day <= unlocked;
      card.classList.toggle('locked', !isOpen);
      if (status) {
        status.className = isOpen ? 'open' : 'lock';
        status.textContent = isOpen ? openLabel : lockedLabel;
      }
    });
    document.querySelectorAll('.day-card').forEach(card => {
      card.addEventListener('click', (e) => {
        if (card.classList.contains('locked')) { e.preventDefault(); showLockedMessage({ hideMain: false }); }
      });
    });
  }

  function guardDayPage(){
    if (!pageId.startsWith('day-')) return;
    const day = parseInt(pageId.split('-')[1], 10);
    if (!day) return;
    const unlocked = getUnlockedDays(pageId === 'day-1');
    if (day > unlocked) { showLockedMessage({ hideMain: true }); }
  }
  function showLockedMessage(options){
    const opts = options || {};
    const hideMain = opts.hideMain === true;
    const message = document.body.dataset.lockMessage || (currentLang === 'en' ? 'This day unlocks at 00:00 local time.' : 'Dieser Tag wird am naechsten Tag um 00:00 Uhr freigeschaltet.');
    const title = document.body.dataset.lockTitle || (currentLang === 'en' ? 'Day locked' : 'Tag gesperrt');
    const button = document.body.dataset.lockButton || (currentLang === 'en' ? 'Back to course' : 'Zur Kursuebersicht');
    const existing = document.querySelector('.lock-overlay');
    if (existing) return;
    if (hideMain) {
      const main = document.querySelector('main');
      if (main) { Array.from(main.children).forEach(node => { node.style.display = 'none'; }); }
    }
    const overlay = document.createElement('div');
    overlay.className = 'lock-overlay';
    overlay.innerHTML = '<div class="lock-card"><h3>' + title + '</h3><p>' + message + '</p><a class="btn primary" href="kurs.html">' + button + '</a></div>';
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) { overlay.remove(); }
    });
    document.body.appendChild(overlay);
  }
  updateCourseLocks();
  guardDayPage();
  function langHref(lang){
    const file = window.location.pathname.split('/').pop() || 'index.html';
    if (lang === 'en') { return isEn ? file : 'en/' + file; }
    return isEn ? '../' + file : file;
  }

  function syncLangButtons(lang){
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });
  }

  function setLang(lang){
    localStorage.setItem('mfm_lang', lang);
    syncLangButtons(lang);
    if (overlay) { overlay.classList.remove('show'); overlay.setAttribute('aria-hidden', 'true'); }
    if (lang !== currentLang) { window.location.href = langHref(lang); }
  }

  syncLangButtons(currentLang);

  if (!stored && overlay) {
    overlay.classList.add('show');
    overlay.setAttribute('aria-hidden', 'false');
  }

  if (overlay) {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) setLang(defaultLang);
    });
  }

  langButtons.forEach(btn => {
    btn.addEventListener('click', () => setLang(btn.dataset.lang));
  });

  const form = document.getElementById('onboardingForm');
  if (form) {
    const steps = form.querySelectorAll('.step');
    let index = 0;
    const progress = document.getElementById('onboardingProgress');
    const show = (i) => {
      steps.forEach((s, idx) => s.classList.toggle('active', idx === i));
      if (progress) progress.style.width = ((i+1)/steps.length*100) + '%';
    };
    form.addEventListener('click', (e) => {
      if (e.target.classList.contains('next')) { index = Math.min(index+1, steps.length-1); show(index); }
      if (e.target.classList.contains('finish')) { window.location.href = 'vorwort.html'; }
    });
    show(index);
  }

  document.querySelectorAll('.quiz-check').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.quiz-card').forEach(card => {
        const answer = card.getAttribute('data-answer');
        const checked = card.querySelector('input:checked');
        const explain = card.querySelector('.quiz-explain');
        if (checked && explain) {
          const base = explain.getAttribute('data-base') || explain.textContent;
          explain.setAttribute('data-base', base);
          explain.hidden = false;
          const right = currentLang === 'en' ? 'Correct: ' : 'Richtig: ';
          const wrong = currentLang === 'en' ? 'Not quite: ' : 'Nicht ganz: ';
          explain.textContent = (checked.value === answer ? right : wrong) + base;
        }
      });
    });
  });

  const ttsLang = currentLang === 'en' ? 'en-US' : 'de-DE';
  let cachedVoices = [];
  const loadVoices = () => { cachedVoices = (window.speechSynthesis && speechSynthesis.getVoices) ? speechSynthesis.getVoices() : []; };
  if ('speechSynthesis' in window) {
    loadVoices();
    if (speechSynthesis.onvoiceschanged !== undefined) {
      speechSynthesis.onvoiceschanged = loadVoices;
    }
  }
  function pickVoice(lang){
    const prefix = lang.startsWith('en') ? 'en' : 'de';
    const voices = cachedVoices.length ? cachedVoices : ((window.speechSynthesis && speechSynthesis.getVoices) ? speechSynthesis.getVoices() : []);
    const byLang = voices.filter(v => v.lang && v.lang.toLowerCase().startsWith(prefix));
    return byLang.find(v => v.name && v.name.toLowerCase().includes('google')) ||
           byLang.find(v => v.default) ||
           byLang[0] || null;
  }
  function normalizeTts(text){
    return text.replace(/\s+/g, ' ').replace(/ÔÇó/g, '').trim();
  }
  function splitSentences(text){
    const parts = text.match(/[^.!?]+[.!?]+|[^.!?]+$/g);
    return parts ? parts.map(p => p.trim()).filter(Boolean) : [];
  }
  function speakTts(text){
    if (!('speechSynthesis' in window)) return;
    const norm = normalizeTts(text);
    if (!norm) return;
    speechSynthesis.cancel();
    const chunks = splitSentences(norm);
    const voice = pickVoice(ttsLang);
    let idx = 0;
    const rate = ttsLang.startsWith('de') ? 0.95 : 1.0;
    const speakNext = () => {
      if (idx >= chunks.length) return;
      const u = new SpeechSynthesisUtterance(chunks[idx]);
      u.lang = ttsLang;
      if (voice) u.voice = voice;
      u.rate = rate;
      u.pitch = 1;
      u.volume = 1;
      u.onend = () => { idx++; speakNext(); };
      speechSynthesis.speak(u);
    };
    speakNext();
  }
  document.querySelectorAll('.tts').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tts');
      const target = document.getElementById(targetId);
      if (!target) return;
      speakTts(target.innerText || target.textContent || '');
    });
  });

  const feedbackForm = document.querySelector('form.feedback');
  if (feedbackForm) {
    const endpoint = feedbackForm.dataset.endpoint || document.body.dataset.feedbackEndpoint;
    const status = feedbackForm.querySelector('.feedback-status');
    feedbackForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      if (!endpoint || endpoint.includes('PASTE-YOUR-APPS-SCRIPT-URL')) {
        if (status) { status.textContent = 'Endpoint fehlt. Bitte Apps Script URL eintragen.'; status.hidden = false; }
        return;
      }
      try {
        const data = new FormData(feedbackForm);
        data.append('page', window.location.pathname);
        await fetch(endpoint, { method: 'POST', body: data, mode: 'no-cors' });
        if (status) { status.textContent = currentLang === 'en' ? 'Thanks! Your feedback was sent.' : 'Danke! Dein Feedback wurde gesendet.'; status.hidden = false; }
        feedbackForm.reset();
      } catch (err) {
        if (status) { status.textContent = currentLang === 'en' ? 'Oops! We could not send your feedback.' : 'Ups! Das Feedback konnte nicht gesendet werden.'; status.hidden = false; }
      }
    });
  }
})();
