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
    const message = document.body.dataset.lockMessage || (currentLang === 'en' ? 'This day unlocks at 00:00 local time.' : 'Dieser Tag wird am n\\u00e4chsten Tag um 00:00 Uhr freigeschaltet.');
    const title = document.body.dataset.lockTitle || (currentLang === 'en' ? 'Day locked' : 'Tag gesperrt');
    const button = document.body.dataset.lockButton || (currentLang === 'en' ? 'Back to course' : 'Zur Kurs\\u00fcbersicht');
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
  function initDayTabs(){
    if (!pageId.startsWith('day-')) return;
    const tabs = document.querySelectorAll('.day-tabs .tab-btn');
    const sections = document.querySelectorAll('.day-section');
    if (!tabs.length || !sections.length) return;
    const show = (tab) => {
      sections.forEach(sec => { sec.style.display = (sec.dataset.tab === tab) ? 'block' : 'none'; });
      tabs.forEach(btn => { btn.classList.toggle('active', btn.dataset.tab === tab); });
    };
    tabs.forEach(btn => { btn.addEventListener('click', () => show(btn.dataset.tab)); });
    show(tabs[0].dataset.tab);
  }
  updateCourseLocks();
  guardDayPage();
  initDayTabs();
  initCourseTour();
  initDayIntroTour();
  initCourseTools();

  function initCourseTour(){
    if (pageId !== 'kurs') return;
    if (localStorage.getItem('mfm_tour_done')) return;
    const steps = [
      {
        title: { de: 'Willkommen', en: 'Welcome' },
        body: { de: 'Hier findest du die Kurs\u00fcbersicht. Wir zeigen dir kurz die wichtigsten Bereiche.', en: 'This is your course overview. Here are the most important areas.' }
      },
      {
        selector: '.lang-switch',
        title: { de: 'Sprache', en: 'Language' },
        body: { de: 'Wechsle hier jederzeit zwischen Deutsch und Englisch.', en: 'Switch between German and English anytime.' }
      },
      {
        selector: '.progress-wrap',
        title: { de: 'Fortschritt', en: 'Progress' },
        body: { de: 'Hier siehst du, wie viele Tage du schon abgeschlossen hast.', en: 'Here you can see how many days you have completed.' }
      },
      {
        selector: '.grid.three',
        title: { de: 'Tage', en: 'Days' },
        body: { de: 'Jeder Tag ist eine eigene Einheit mit Aufgaben, Bonuswissen und Reflexion.', en: 'Each day is a standalone unit with tasks, bonus knowledge, and reflection.' }
      },
      {
        selector: '.day-card',
        title: { de: 'Starten', en: 'Start' },
        body: { de: 'Klicke auf Tag 1, um zu starten. Neue Tage werden um 00:00 Uhr freigeschaltet.', en: 'Click Day 1 to start. New days unlock at 00:00 local time.' }
      }
    ];

    const overlay = document.createElement('div');
    overlay.className = 'tour-overlay show';
    overlay.innerHTML = '<div class="tour-card"><h3></h3><p></p><div class="tour-actions"><button class="btn ghost" data-action="back">Back</button><button class="btn ghost" data-action="skip">Skip</button><button class="btn primary" data-action="next">Next</button></div></div>';
    document.body.appendChild(overlay);

    const card = overlay.querySelector('.tour-card');
    const titleEl = card.querySelector('h3');
    const bodyEl = card.querySelector('p');
    const backBtn = card.querySelector('[data-action="back"]');
    const skipBtn = card.querySelector('[data-action="skip"]');
    const nextBtn = card.querySelector('[data-action="next"]');
    let index = 0;

    const textFor = (obj) => currentLang === 'en' ? obj.en : obj.de;

    function clearHighlight(){
      document.querySelectorAll('.tour-highlight').forEach(el => el.classList.remove('tour-highlight'));
    }

    function positionCard(target){
      const padding = 12;
      card.style.transform = '';
      if (!target) {
        card.style.top = '20%';
        card.style.left = '50%';
        card.style.transform = 'translateX(-50%)';
        return;
      }
      const rect = target.getBoundingClientRect();
      const cardRect = card.getBoundingClientRect();
      let top = rect.bottom + padding;
      if (top + cardRect.height > window.innerHeight) {
        top = Math.max(padding, rect.top - cardRect.height - padding);
      }
      let left = rect.left;
      if (left + cardRect.width > window.innerWidth) {
        left = Math.max(padding, window.innerWidth - cardRect.width - padding);
      }
      if (left < padding) left = padding;
      card.style.top = top + 'px';
      card.style.left = left + 'px';
    }

    function findStep(i){
      let idx = i;
      while (idx < steps.length) {
        const step = steps[idx];
        if (!step.selector) return { step, idx, target: null };
        const target = document.querySelector(step.selector);
        if (target) return { step, idx, target };
        idx++;
      }
      return null;
    }

    function finish(){
      clearHighlight();
      overlay.remove();
      localStorage.setItem('mfm_tour_done', '1');
      window.location.href = 'onboarding.html';
    }

    function render(i){
      const result = findStep(i);
      if (!result) { finish(); return; }
      index = result.idx;
      titleEl.textContent = textFor(result.step.title);
      bodyEl.textContent = textFor(result.step.body);
      backBtn.textContent = currentLang === 'en' ? 'Back' : 'Zur\u00fcck';
      skipBtn.textContent = currentLang === 'en' ? 'Skip' : '\u00dcberspringen';
      nextBtn.textContent = index === steps.length - 1 ? (currentLang === 'en' ? 'Go to questions' : 'Zu den Fragen') : (currentLang === 'en' ? 'Next' : 'Weiter');
      backBtn.style.display = index === 0 ? 'none' : 'inline-flex';
      clearHighlight();
      if (result.target) result.target.classList.add('tour-highlight');
      positionCard(result.target);
    }

    backBtn.addEventListener('click', () => render(index - 1));
    nextBtn.addEventListener('click', () => {
      if (index >= steps.length - 1) { finish(); return; }
      render(index + 1);
    });
    skipBtn.addEventListener('click', () => {
      clearHighlight();
      overlay.remove();
      localStorage.setItem('mfm_tour_done', '1');
    });

    render(0);
  }

  function initCourseTools(){
    if (pageId !== 'kurs') return;
    document.querySelectorAll('[data-reset]').forEach(btn => {
      btn.addEventListener('click', () => {
        const action = btn.getAttribute('data-reset');
        if (action === 'tour') {
          localStorage.removeItem('mfm_tour_done');
          localStorage.removeItem('mfm_day1_tour_done');
          initCourseTour();
          return;
        }
        if (action === 'course') {
          localStorage.removeItem('mfm_start_date');
          localStorage.removeItem('mfm_day1_tour_done');
          updateCourseLocks();
        }
      });
    });
  }
  function initDayIntroTour(){
    if (pageId !== 'day-1') return;
    if (localStorage.getItem('mfm_day1_tour_done')) return;

    const tabs = Array.from(document.querySelectorAll('.day-tabs .tab-btn'));
    const sections = Array.from(document.querySelectorAll('.day-section'));
    const setTab = (tab) => {
      if (!tabs.length || !sections.length) return;
      sections.forEach(sec => { sec.style.display = (sec.dataset.tab === tab) ? 'block' : 'none'; });
      tabs.forEach(btn => { btn.classList.toggle('active', btn.dataset.tab === tab); });
    };

    const steps = [
      {
        title: { de: 'So funktioniert Tag 1', en: 'How Day 1 works' },
        body: { de: 'Wir zeigen dir kurz, was Aufgaben, Bonuswissen und Reflexion bedeuten.', en: 'A quick tour of tasks, bonus knowledge, and reflection.' }
      },
      {
        selector: '.day-tabs',
        title: { de: 'Reiter oben', en: 'Top tabs' },
        body: { de: 'Wechsle hier zwischen Aufgaben, Bonuswissen und Reflexion.', en: 'Switch between tasks, bonus knowledge, and reflection here.' },
        tab: 'tasks'
      },
      {
        selector: '.day-section[data-tab="tasks"] .rich-text',
        title: { de: 'Kurztext', en: 'Short intro' },
        body: { de: 'Hier findest du die kurze Einf\u00fchrung f\u00fcr den Tag.', en: 'This is the short introduction for the day.' },
        tab: 'tasks'
      },
      {
        selector: '.day-section[data-tab="tasks"] .task-grid',
        title: { de: 'Aufgaben', en: 'Tasks' },
        body: { de: 'Hier sind deine Aufgaben. Nimm sie Schritt f\u00fcr Schritt.', en: 'Here are your tasks. Take them step by step.' },
        tab: 'tasks'
      },
      {
        selector: '#bonus-1',
        title: { de: 'Bonuswissen', en: 'Bonus knowledge' },
        body: { de: 'Hier findest du den langen Hintergrundtext.', en: 'Here is the deeper background text.' },
        tab: 'bonus'
      },
      {
        selector: '.day-section[data-tab="bonus"] .quiz',
        title: { de: 'Quiz', en: 'Quiz' },
        body: { de: 'Teste dich direkt im Quiz unter dem Bonuswissen.', en: 'Check your understanding in the quiz below.' },
        tab: 'bonus'
      },
      {
        selector: '.day-section[data-tab="reflex"] .reflex',
        title: { de: 'Reflexion', en: 'Reflection' },
        body: { de: 'Zum Schluss reflektierst du deinen Tag.', en: 'Finish by reflecting on your day.' },
        tab: 'reflex'
      }
    ];

    const overlay = document.createElement('div');
    overlay.className = 'tour-overlay show';
    overlay.innerHTML = '<div class="tour-card"><h3></h3><p></p><div class="tour-actions"><button class="btn ghost" data-action="back">Back</button><button class="btn ghost" data-action="skip">Skip</button><button class="btn primary" data-action="next">Next</button></div></div>';
    document.body.appendChild(overlay);

    const card = overlay.querySelector('.tour-card');
    const titleEl = card.querySelector('h3');
    const bodyEl = card.querySelector('p');
    const backBtn = card.querySelector('[data-action="back"]');
    const skipBtn = card.querySelector('[data-action="skip"]');
    const nextBtn = card.querySelector('[data-action="next"]');
    let index = 0;

    const textFor = (obj) => currentLang === 'en' ? obj.en : obj.de;

    function clearHighlight(){
      document.querySelectorAll('.tour-highlight').forEach(el => el.classList.remove('tour-highlight'));
    }

    function positionCard(target){
      const padding = 12;
      card.style.transform = '';
      if (!target) {
        card.style.top = '20%';
        card.style.left = '50%';
        card.style.transform = 'translateX(-50%)';
        return;
      }
      const rect = target.getBoundingClientRect();
      const cardRect = card.getBoundingClientRect();
      let top = rect.bottom + padding;
      if (top + cardRect.height > window.innerHeight) {
        top = Math.max(padding, rect.top - cardRect.height - padding);
      }
      let left = rect.left;
      if (left + cardRect.width > window.innerWidth) {
        left = Math.max(padding, window.innerWidth - cardRect.width - padding);
      }
      if (left < padding) left = padding;
      card.style.top = top + 'px';
      card.style.left = left + 'px';
    }

    function findStep(i){
      let idx = i;
      while (idx < steps.length) {
        const step = steps[idx];
        if (!step.selector) return { step, idx, target: null };
        if (step.tab) setTab(step.tab);
        const target = document.querySelector(step.selector);
        if (target) return { step, idx, target };
        idx++;
      }
      return null;
    }

    function finish(){
      clearHighlight();
      overlay.remove();
      localStorage.setItem('mfm_day1_tour_done', '1');
    }

    function render(i){
      const result = findStep(i);
      if (!result) { finish(); return; }
      index = result.idx;
      titleEl.textContent = textFor(result.step.title);
      bodyEl.textContent = textFor(result.step.body);
      backBtn.textContent = currentLang === 'en' ? 'Back' : 'Zur\u00fcck';
      skipBtn.textContent = currentLang === 'en' ? 'Skip' : '\u00dcberspringen';
      nextBtn.textContent = index === steps.length - 1 ? (currentLang === 'en' ? 'Done' : 'Fertig') : (currentLang === 'en' ? 'Next' : 'Weiter');
      backBtn.style.display = index === 0 ? 'none' : 'inline-flex';
      clearHighlight();
      if (result.target) {
        result.target.classList.add('tour-highlight');
        result.target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
      positionCard(result.target);
    }

    backBtn.addEventListener('click', () => render(index - 1));
    nextBtn.addEventListener('click', () => {
      if (index >= steps.length - 1) { finish(); return; }
      render(index + 1);
    });
    skipBtn.addEventListener('click', () => {
      clearHighlight();
      overlay.remove();
      localStorage.setItem('mfm_day1_tour_done', '1');
    });

    render(0);
  }
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
