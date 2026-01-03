(function(){
  const overlay = document.getElementById('langOverlay');
  const langButtons = document.querySelectorAll('[data-lang]');
  const stored = localStorage.getItem('mfm_lang');
  const browser = navigator.language || 'de';
  const defaultLang = stored || (browser.startsWith('en') ? 'en' : 'de');

  function setLang(lang){
    localStorage.setItem('mfm_lang', lang);
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });
    if (lang === 'en') {
      alert('English content is coming soon.');
    }
    if (overlay) { overlay.classList.remove('show'); overlay.setAttribute('aria-hidden', 'true'); }
  }

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
          explain.hidden = false;
          if (checked.value === answer) {
            explain.insertAdjacentText('afterbegin', 'Richtig: ');
          } else {
            explain.insertAdjacentText('afterbegin', 'Nicht ganz: ');
          }
        }
      });
    });
  });

  document.querySelectorAll('.tts').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tts');
      const target = document.getElementById(targetId);
      if (!target) return;
      const text = target.innerText;
      if ('speechSynthesis' in window) {
        const u = new SpeechSynthesisUtterance(text);
        u.lang = 'de-DE';
        speechSynthesis.cancel();
        speechSynthesis.speak(u);
      }
    });
  });
})();
