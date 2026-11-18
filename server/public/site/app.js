/* ═══════════════════════════════════════════════════════════════════════
   JEENI AI — Interactive Web Experience & Simulators
   Powers: 3D Fibonacci Thinking Orb, 6-Mode Explorer, Visual Learning Lab,
           Spotlight Borders, Scroll Choreography, FAQ & APK Modal
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
  'use strict';

  const GOLDEN_ANGLE = 2.39996322972865332;

  /* ── 1. Sticky Navbar & Scroll Progress ── */
  const navbar = document.getElementById('navbar');
  const progressBar = document.getElementById('scroll-progress');

  function handleScroll() {
    const scrollY = window.scrollY || window.pageYOffset;
    if (navbar) {
      navbar.classList.toggle('scrolled', scrollY > 18);
    }
    if (progressBar) {
      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const pct = docHeight > 0 ? Math.min(100, (scrollY / docHeight) * 100) : 0;
      progressBar.style.width = pct + '%';
    }
  }
  window.addEventListener('scroll', handleScroll, { passive: true });
  handleScroll();

  /* ── 2. Mobile Menu Drawer ── */
  const menuBtn = document.getElementById('mobile-menu-btn');
  const mobileDrawer = document.getElementById('mobile-drawer');
  if (menuBtn && mobileDrawer) {
    menuBtn.addEventListener('click', () => {
      const isOpen = mobileDrawer.classList.toggle('open');
      menuBtn.setAttribute('aria-expanded', String(isOpen));
    });
    mobileDrawer.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        mobileDrawer.classList.remove('open');
        menuBtn.setAttribute('aria-expanded', 'false');
      });
    });
  }

  /* ── 3. Reveal on Scroll & Cursor Spotlight Cards ── */
  const reveals = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('visible');
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: '0px 0px -40px 0px' }
    );
    reveals.forEach((el) => io.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add('visible'));
  }

  document.querySelectorAll('.bento-card').forEach((card) => {
    card.addEventListener('mousemove', (e) => {
      const rect = card.getBoundingClientRect();
      card.style.setProperty('--mouse-x', `${e.clientX - rect.left}px`);
      card.style.setProperty('--mouse-y', `${e.clientY - rect.top}px`);
    });
  });

  /* ── 4. Live 3D Fibonacci-Sphere Thinking Orb Engine ── */
  class ThinkingOrb {
    constructor(canvas, initialConfig) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d');
      this.color = initialConfig.color || '#6366f1';
      this.mode = initialConfig.mode || 'idle';
      this.speed = initialConfig.speed || 0.7;
      this.dotCount = initialConfig.dotCount || 68;
      this.phase = 0;
      this.lastTime = performance.now();
      this.resize();
      window.addEventListener('resize', () => this.resize());
    }

    setState(config) {
      if (config.color) this.color = config.color;
      if (config.mode) this.mode = config.mode;
      if (config.speed) this.speed = config.speed;
    }

    resize() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const cssSize = parseFloat(this.canvas.dataset.size || '36');
      this.cssSize = cssSize;
      this.canvas.width = cssSize * dpr;
      this.canvas.height = cssSize * dpr;
      this.canvas.style.width = `${cssSize}px`;
      this.canvas.style.height = `${cssSize}px`;
      this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }

    hexToRgb(hex) {
      const clean = hex.replace('#', '');
      const n = parseInt(clean, 16);
      return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
    }

    render(now) {
      const dt = Math.min(0.05, (now - this.lastTime) / 1000);
      this.lastTime = now;
      this.phase += dt * this.speed;

      const ctx = this.ctx;
      const size = this.cssSize;
      const cx = size / 2;
      const cy = size / 2;
      const baseRadius = size * 0.38;
      const rgb = this.hexToRgb(this.color);

      ctx.clearRect(0, 0, size, size);

      // Ambient halo
      const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, baseRadius * 1.45);
      grad.addColorStop(0, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, 0.28)`);
      grad.addColorStop(1, 'rgba(0, 0, 0, 0)');
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(cx, cy, baseRadius * 1.45, 0, Math.PI * 2);
      ctx.fill();

      const dots = [];
      const rotY = this.phase * 1.4;
      const rotX = Math.sin(this.phase * 0.7) * 0.45;
      const pulse = 1 + Math.sin(this.phase * 2.5) * (this.mode === 'solving' ? 0.14 : 0.06);

      for (let i = 0; i < this.dotCount; i++) {
        const phi = Math.acos(1 - (2 * (i + 0.5)) / this.dotCount);
        const theta = GOLDEN_ANGLE * i + rotY;

        let x = Math.sin(phi) * Math.cos(theta);
        let y = Math.cos(phi);
        let z = Math.sin(phi) * Math.sin(theta);

        // Tilt rotation
        const yTilt = y * Math.cos(rotX) - z * Math.sin(rotX);
        const zTilt = y * Math.sin(rotX) + z * Math.cos(rotX);
        y = yTilt;
        z = zTilt;

        if (this.mode === 'searching') {
          const wave = Math.sin(this.phase * 4 + i * 0.25) * 0.16;
          x *= 1 + wave;
          y *= 1 + wave;
        }

        const scale = (z + 2.0) / 3.0;
        dots.push({
          px: cx + x * baseRadius * pulse,
          py: cy + y * baseRadius * pulse,
          z,
          radius: Math.max(0.6, (size / 38) * (0.75 + scale * 0.95)),
          alpha: Math.max(0.18, Math.min(1, 0.25 + (z + 1) * 0.42)),
        });
      }

      dots.sort((a, b) => a.z - b.z);
      for (const d of dots) {
        ctx.fillStyle = `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${d.alpha.toFixed(2)})`;
        ctx.beginPath();
        ctx.arc(d.px, d.py, d.radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  const orbInstances = [];
  const heroOrbCanvas = document.getElementById('hero-orb-canvas');
  const heroOrbBtn = document.getElementById('hero-orb-btn');
  const heroOrbLabel = document.getElementById('hero-orb-label');

  const orbStates = [
    { label: 'Orb State: Learning Interactive', color: '#6366f1', mode: 'idle', speed: 0.75 },
    { label: 'Orb State: Searching Web Sources', color: '#0ea5e9', mode: 'searching', speed: 1.4 },
    { label: 'Orb State: Solving Equation', color: '#f97316', mode: 'solving', speed: 1.8 },
    { label: 'Orb State: Deep Mastery Synthesis', color: '#a855f7', mode: 'idle', speed: 1.1 },
    { label: 'Orb State: Guided Step Check', color: '#10b981', mode: 'searching', speed: 0.9 },
  ];
  let orbStateIndex = 0;

  let heroOrb = null;
  if (heroOrbCanvas) {
    heroOrb = new ThinkingOrb(heroOrbCanvas, orbStates[0]);
    orbInstances.push(heroOrb);
    if (heroOrbBtn && heroOrbLabel) {
      heroOrbBtn.addEventListener('click', () => {
        orbStateIndex = (orbStateIndex + 1) % orbStates.length;
        const st = orbStates[orbStateIndex];
        heroOrb.setState(st);
        heroOrbLabel.textContent = st.label;
      });
    }
  }

  const modeOrbCanvas = document.getElementById('mode-orb-canvas');
  let modeOrb = null;
  if (modeOrbCanvas) {
    modeOrb = new ThinkingOrb(modeOrbCanvas, { color: '#6366f1', mode: 'idle', speed: 1.0, dotCount: 54 });
    orbInstances.push(modeOrb);
  }

  function animateOrbs(now) {
    for (const inst of orbInstances) {
      inst.render(now);
    }
    requestAnimationFrame(animateOrbs);
  }
  if (orbInstances.length > 0) {
    requestAnimationFrame(animateOrbs);
  }

  /* ── 5. Interactive 6-Mode Explorer ── */
  const modesData = {
    learning: {
      name: 'Learning',
      color: '#6366f1',
      orbMode: 'idle',
      orbState: 'Generating interactive visual simulation...',
      prompt: 'Teach me how Area of a Circle works with an interactive intuition.',
      responseHtml:
        '<strong>Imagine slicing a pizza into paper-thin wedges.</strong> Arrange half pointing up and half pointing down to form a near-rectangle:<br><br>' +
        '• <strong>Width</strong> = half the circumference = <code>π · r</code><br>' +
        '• <strong>Height</strong> = radius = <code>r</code><br>' +
        '• <strong>Area</strong> = Width × Height = <strong><code>π · r²</code></strong><br><br>' +
        'Notice that doubling your radius quadruples the total area!',
      chips: ['⚡ Opens Live Geometry Slider Widget', '📐 5-Level Mastery Flow', '🎯 3 Quick Check Questions'],
    },
    deep_learning: {
      name: 'Deep Learning',
      color: '#a855f7',
      orbMode: 'solving',
      orbState: 'Synthesizing foundational proofs & mental models...',
      prompt: "Go deep into why F = m·a governs rocket propulsion and inertia.",
      responseHtml:
        '<strong>First-Principles Breakdown: Newton’s Second Law</strong><br><br>' +
        'Rather than memorizing symbols, trace momentum change <code>F = dp / dt</code>. For constant mass, acceleration scales inversely with inertia:<br><br>' +
        '1. Double the net thrust → acceleration doubles linearly.<br>' +
        '2. As fuel burns during launch, rocket <code>m</code> drops—causing acceleration <code>a = F/m</code> to surge skyward even at steady thrust.',
      chips: ['🧠 Deep Concept Derivation', '🧪 Real-World Edge Cases', '🗣️ Listen with Voice Narration'],
    },
    web_search: {
      name: 'Web Search',
      color: '#0ea5e9',
      orbMode: 'searching',
      orbState: 'Grounding response across live verified sources...',
      prompt: 'What are the latest breakthroughs in fusion energy milestones?',
      responseHtml:
        '<strong>Live Grounded Synthesis</strong><br><br>' +
        'Jeeni cross-checks current web publications and scientific journals to deliver up-to-date facts instead of outdated training cutoffs—citing every claim transparently so students can verify every number.',
      chips: ['🔎 Real-Time Web Grounding', '🛡️ Fact-Checked Citations', '⚡ Zero Hallucinated Links'],
    },
    guide: {
      name: 'Guide',
      color: '#10b981',
      orbMode: 'idle',
      orbState: 'Preparing Socratic step-by-step scaffolding...',
      prompt: 'Help me solve 3x + 7 = 22 without spoiling the answer right away.',
      responseHtml:
        '<strong>Step 1 of 2 (Socratic Hint):</strong><br><br>' +
        'To isolate <code>3x</code> on the left side, we need to undo the <code>+ 7</code>.<br><br>' +
        'What do you get if you subtract <strong>7</strong> from both sides of the equation? Reply with your step and I will guide you through Step 2!',
      chips: ['🧭 Socratic Hints First', '✍️ Checks Your Reasoning', '💡 Builds True Confidence'],
    },
    homework: {
      name: 'Homework',
      color: '#f97316',
      orbMode: 'solving',
      orbState: 'Analyzing uploaded worksheet & breaking down steps...',
      prompt: 'I uploaded a photo of Question 4 from my physics worksheet—walk me through it.',
      responseHtml:
        '<strong>Worksheet Question 4 Detected: Net Force with Friction</strong><br><br>' +
        '• Given: <code>Applied Force = 100 N</code>, <code>Friction = 20 N</code>, <code>Mass = 20 kg</code><br>' +
        '• <strong>Step 1:</strong> Subtract opposing friction: <code>F_net = 100 - 20 = 80 N</code><br>' +
        '• <strong>Step 2:</strong> Apply <code>a = F_net / m = 80 / 20 = 4 m/s²</code>.',
      chips: ['📷 Photo & File Upload Ready', '📝 Clear Formula Steps', '✅ Mistake Spotter'],
    },
    exam_prep: {
      name: 'Exam Prep',
      color: '#f59e0b',
      orbMode: 'solving',
      orbState: 'Building high-yield flashcard deck & rapid quiz...',
      prompt: 'Create a 10-minute high-yield revision sprint on DNA Replication.',
      responseHtml:
        '<strong>Exam Sprint: High-Yield Checkpoints</strong><br><br>' +
        '1. <strong>Helicase</strong> unzips hydrogen bonds at the replication fork.<br>' +
        '2. <strong>DNA Polymerase III</strong> synthesizes 5’ → 3’ continuously on the leading strand.<br>' +
        '3. Watch the trap: <strong>Okazaki fragments</strong> occur only on the lagging strand!',
      chips: ['🎯 Timed Mini-Quizzes', '🃏 Active Recall Flashcards', '📚 Syllabus & Board Aware'],
    },
  };

  const modeTabs = document.querySelectorAll('.mode-tab');
  const previewPill = document.getElementById('preview-mode-pill');
  const previewPrompt = document.getElementById('preview-user-prompt');
  const previewOrbState = document.getElementById('preview-orb-state');
  const previewResponse = document.getElementById('preview-ai-response');
  const previewChips = document.getElementById('preview-ai-chips');
  const previewCta = document.getElementById('preview-cta-link');

  function activateMode(modeKey) {
    const data = modesData[modeKey];
    if (!data) return;

    modeTabs.forEach((tab) => {
      const isMatch = tab.dataset.mode === modeKey;
      tab.classList.toggle('active', isMatch);
      tab.setAttribute('aria-selected', String(isMatch));
    });

    if (modeOrb) {
      modeOrb.setState({ color: data.color, mode: data.orbMode, speed: 1.25 });
    }
    if (previewPill) {
      previewPill.textContent = `${data.name} Mode`;
      previewPill.style.color = data.color;
      previewPill.style.borderColor = data.color + '66';
      previewPill.style.background = data.color + '22';
    }
    if (previewPrompt) previewPrompt.textContent = data.prompt;
    if (previewOrbState) previewOrbState.textContent = data.orbState;
    if (previewResponse) previewResponse.innerHTML = data.responseHtml;
    if (previewChips) {
      previewChips.innerHTML = data.chips.map((c) => `<span class="sim-chip">${c}</span>`).join('');
    }
    if (previewCta) previewCta.textContent = `Try ${data.name} Mode in Web App →`;
  }

  modeTabs.forEach((tab) => {
    tab.addEventListener('click', () => activateMode(tab.dataset.mode));
  });
  activateMode('learning');

  /* ── 6. Live Visual Learning Lab (Circle Area, Physics Track, Quiz) ── */
  const labTabBtns = document.querySelectorAll('.lab-tab-btn');
  const labPanels = document.querySelectorAll('.lab-panel');

  labTabBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      const target = btn.dataset.lab;
      labTabBtns.forEach((b) => b.classList.toggle('active', b === btn));
      labPanels.forEach((p) => p.classList.toggle('active', p.id === `lab-${target}`));
      if (target === 'circle') drawCircleLab();
      if (target === 'physics') drawPhysicsLab();
    });
  });

  // 6A: Geometry — Circle Area Canvas
  const circleCanvas = document.getElementById('circle-canvas');
  const radiusSlider = document.getElementById('radius-slider');
  const radiusValLabel = document.getElementById('radius-val-label');
  const areaReadout = document.getElementById('area-readout');
  const circReadout = document.getElementById('circ-readout');
  const toggleGrid = document.getElementById('toggle-grid');
  const toggleCirc = document.getElementById('toggle-circ');

  function drawCircleLab() {
    if (!circleCanvas) return;
    const ctx = circleCanvas.getContext('2d');
    const r = parseFloat(radiusSlider ? radiusSlider.value : '5');
    const showGrid = toggleGrid ? toggleGrid.checked : true;
    const showCirc = toggleCirc ? toggleCirc.checked : true;

    const area = Math.PI * r * r;
    const circ = 2 * Math.PI * r;
    if (radiusValLabel) radiusValLabel.textContent = `r = ${r.toFixed(1)} u`;
    if (areaReadout) areaReadout.textContent = `${area.toFixed(2)} u²`;
    if (circReadout) circReadout.textContent = `${circ.toFixed(2)} u`;

    const w = circleCanvas.width;
    const h = circleCanvas.height;
    const cx = w / 2;
    const cy = h / 2;
    const unitPx = 14.5;
    const pxR = r * unitPx;

    ctx.clearRect(0, 0, w, h);

    // Grid lines
    if (showGrid) {
      ctx.strokeStyle = 'rgba(255,255,255,0.06)';
      ctx.lineWidth = 1;
      for (let x = cx % unitPx; x < w; x += unitPx) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, h);
        ctx.stroke();
      }
      for (let y = cy % unitPx; y < h; y += unitPx) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(w, y);
        ctx.stroke();
      }
    }

    // Center axes
    ctx.strokeStyle = 'rgba(255,255,255,0.12)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(cx, 12);
    ctx.lineTo(cx, h - 12);
    ctx.moveTo(12, cy);
    ctx.lineTo(w - 12, cy);
    ctx.stroke();

    // Glowing fill
    const fillGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, pxR);
    fillGrad.addColorStop(0, 'rgba(99, 102, 241, 0.42)');
    fillGrad.addColorStop(1, 'rgba(34, 211, 238, 0.16)');
    ctx.fillStyle = fillGrad;
    ctx.beginPath();
    ctx.arc(cx, cy, pxR, 0, Math.PI * 2);
    ctx.fill();

    // Circumference ring
    ctx.strokeStyle = showCirc ? '#22d3ee' : 'rgba(255,255,255,0.5)';
    ctx.lineWidth = showCirc ? 3 : 1.5;
    ctx.beginPath();
    ctx.arc(cx, cy, pxR, 0, Math.PI * 2);
    ctx.stroke();

    // Radius line & dot
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + pxR, cy);
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(cx, cy, 4, 0, Math.PI * 2);
    ctx.arc(cx + pxR, cy, 4, 0, Math.PI * 2);
    ctx.fill();

    ctx.font = '600 13px Inter, sans-serif';
    ctx.fillStyle = '#ffffff';
    ctx.fillText(`r = ${r.toFixed(1)}`, cx + pxR / 2 - 18, cy - 10);
  }

  if (radiusSlider) radiusSlider.addEventListener('input', drawCircleLab);
  if (toggleGrid) toggleGrid.addEventListener('change', drawCircleLab);
  if (toggleCirc) toggleCirc.addEventListener('change', drawCircleLab);
  drawCircleLab();

  // 6B: Physics — Newton's 2nd Law (F = m * a)
  const physicsCanvas = document.getElementById('physics-canvas');
  const forceSlider = document.getElementById('force-slider');
  const massSlider = document.getElementById('mass-slider');
  const forceValLabel = document.getElementById('force-val-label');
  const massValLabel = document.getElementById('mass-val-label');
  const accelReadout = document.getElementById('accel-readout');
  const velReadout = document.getElementById('vel-readout');
  const playPhysicsBtn = document.getElementById('play-physics-btn');
  const resetPhysicsBtn = document.getElementById('reset-physics-btn');

  let physRunning = false;
  let physTime = 0;
  let physRaf = null;
  let physLastTs = 0;

  function drawPhysicsLab() {
    if (!physicsCanvas) return;
    const ctx = physicsCanvas.getContext('2d');
    const F = parseFloat(forceSlider ? forceSlider.value : '40');
    const m = parseFloat(massSlider ? massSlider.value : '5');
    const a = F / m;
    const v = a * physTime;

    if (forceValLabel) forceValLabel.textContent = `${F.toFixed(0)} N`;
    if (massValLabel) massValLabel.textContent = `${m.toFixed(0)} kg`;
    if (accelReadout) accelReadout.textContent = `${a.toFixed(2)} m/s²`;
    if (velReadout) velReadout.textContent = `${v.toFixed(2)} m/s`;

    const w = physicsCanvas.width;
    const h = physicsCanvas.height;
    ctx.clearRect(0, 0, w, h);

    // Floor track
    const floorY = 175;
    ctx.strokeStyle = 'rgba(255,255,255,0.22)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(28, floorY);
    ctx.lineTo(w - 28, floorY);
    ctx.stroke();

    // Distance markers
    ctx.strokeStyle = 'rgba(255,255,255,0.12)';
    ctx.lineWidth = 1;
    for (let x = 40; x <= w - 40; x += 40) {
      ctx.beginPath();
      ctx.moveTo(x, floorY);
      ctx.lineTo(x, floorY + 7);
      ctx.stroke();
    }

    // Displacement scaled cleanly across track
    const disp = 0.5 * a * physTime * physTime;
    const maxTrackPx = w - 165;
    const blockSize = 44 + (m / 20) * 26;
    const blockX = Math.min(48 + disp * 4.2, maxTrackPx);
    const blockY = floorY - blockSize;

    // Mass Block
    const boxGrad = ctx.createLinearGradient(blockX, blockY, blockX + blockSize, floorY);
    boxGrad.addColorStop(0, '#6366f1');
    boxGrad.addColorStop(1, '#4f46e5');
    ctx.fillStyle = boxGrad;
    ctx.strokeStyle = '#a5b4fc';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.roundRect(blockX, blockY, blockSize, blockSize, 8);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.font = '700 13px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`${m.toFixed(0)}kg`, blockX + blockSize / 2, blockY + blockSize / 2 + 5);

    // Force Vector Arrow
    const arrowLen = 28 + (F / 100) * 65;
    const ay = blockY + blockSize / 2;
    const axStart = blockX + blockSize + 8;
    const axEnd = axStart + arrowLen;

    ctx.strokeStyle = '#f97316';
    ctx.fillStyle = '#f97316';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(axStart, ay);
    ctx.lineTo(axEnd, ay);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(axEnd + 8, ay);
    ctx.lineTo(axEnd - 2, ay - 6);
    ctx.lineTo(axEnd - 2, ay + 6);
    ctx.closePath();
    ctx.fill();

    ctx.font = '600 12px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(`F = ${F.toFixed(0)}N`, axStart + 4, ay - 11);

    // Mini Velocity-Time HUD bottom left
    ctx.fillStyle = 'rgba(255,255,255,0.6)';
    ctx.font = '500 12px Inter, sans-serif';
    ctx.fillText(`t = ${physTime.toFixed(2)}s   |   v = ${(a * physTime).toFixed(1)} m/s   |   x = ${disp.toFixed(1)} m`, 32, 224);

    if (blockX >= maxTrackPx) {
      physRunning = false;
      if (playPhysicsBtn) playPhysicsBtn.textContent = 'Run Simulation';
    }
  }

  function stepPhysics(ts) {
    if (!physRunning) return;
    const dt = Math.min(0.05, (ts - physLastTs) / 1000);
    physLastTs = ts;
    physTime += dt;
    drawPhysicsLab();
    if (physRunning) {
      physRaf = requestAnimationFrame(stepPhysics);
    }
  }

  if (playPhysicsBtn) {
    playPhysicsBtn.addEventListener('click', () => {
      if (physRunning) {
        physRunning = false;
        playPhysicsBtn.textContent = 'Run Simulation';
        return;
      }
      if (physTime >= 2.5) physTime = 0;
      physRunning = true;
      playPhysicsBtn.textContent = 'Pause';
      physLastTs = performance.now();
      physRaf = requestAnimationFrame(stepPhysics);
    });
  }

  if (resetPhysicsBtn) {
    resetPhysicsBtn.addEventListener('click', () => {
      physRunning = false;
      if (physRaf) cancelAnimationFrame(physRaf);
      physTime = 0;
      if (playPhysicsBtn) playPhysicsBtn.textContent = 'Run Simulation';
      drawPhysicsLab();
    });
  }

  if (forceSlider) forceSlider.addEventListener('input', drawPhysicsLab);
  if (massSlider) massSlider.addEventListener('input', drawPhysicsLab);
  drawPhysicsLab();

  // 6C: Interactive Mini Quiz
  const quizOptions = document.querySelectorAll('.quiz-option');
  const quizFeedback = document.getElementById('quiz-feedback');
  quizOptions.forEach((opt) => {
    opt.addEventListener('click', () => {
      const isCorrect = opt.dataset.correct === 'true';
      quizOptions.forEach((o) => {
        o.classList.remove('correct', 'wrong');
        if (o.dataset.correct === 'true') o.classList.add('correct');
      });
      if (!isCorrect) opt.classList.add('wrong');
      if (quizFeedback) {
        quizFeedback.textContent = isCorrect
          ? 'Correct! Radius is half the diameter (r = 10 / 2 = 5 cm), so A = π × 5² = 3.14 × 25 = 78.5 cm².'
          : 'Not quite — remember to divide the diameter by 2 first to get r = 5 cm, then compute A = π · r² = 78.5 cm².';
        quizFeedback.classList.add('visible');
      }
    });
  });

  /* ── 7. FAQ Accordion ── */
  document.querySelectorAll('.faq-item').forEach((item) => {
    const btn = item.querySelector('.faq-question');
    const ans = item.querySelector('.faq-answer');
    if (!btn || !ans) return;
    btn.addEventListener('click', () => {
      const isOpen = item.classList.contains('open');
      document.querySelectorAll('.faq-item').forEach((other) => {
        other.classList.remove('open');
        const oa = other.querySelector('.faq-answer');
        const ob = other.querySelector('.faq-question');
        if (oa) oa.style.maxHeight = null;
        if (ob) ob.setAttribute('aria-expanded', 'false');
      });
      if (!isOpen) {
        item.classList.add('open');
        btn.setAttribute('aria-expanded', 'true');
        ans.style.maxHeight = ans.scrollHeight + 'px';
      }
    });
  });

  /* ── 8. Android APK Modal ── */
  const apkModal = document.getElementById('apk-modal');
  const apkTriggers = document.querySelectorAll('[data-open-apk-modal]');
  const apkClose = document.getElementById('apk-modal-close');

  function openApkModal(e) {
    if (e) e.preventDefault();
    if (apkModal) apkModal.classList.add('open');
  }
  function closeApkModal() {
    if (apkModal) apkModal.classList.remove('open');
  }

  apkTriggers.forEach((el) => el.addEventListener('click', openApkModal));
  if (apkClose) apkClose.addEventListener('click', closeApkModal);
  if (apkModal) {
    apkModal.addEventListener('click', (e) => {
      if (e.target === apkModal) closeApkModal();
    });
  }
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeApkModal();
  });
})();
