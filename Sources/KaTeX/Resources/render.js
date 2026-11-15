// KaTeX fonts load lazily; a PDF made before they arrive misses glyphs. Load every face first.
const katexFaces = ['KaTeX_AMS', 'KaTeX_Caligraphic', 'KaTeX_Fraktur', 'KaTeX_Main', 'KaTeX_Math', 'KaTeX_SansSerif',
  'KaTeX_Script', 'KaTeX_Size1', 'KaTeX_Size2', 'KaTeX_Size3', 'KaTeX_Size4', 'KaTeX_Typewriter'];
let fontsLoaded = null;
function loadFonts() {
  if (!fontsLoaded) {
    const loads = [];
    for (const f of katexFaces) {
      for (const style of ['', 'italic ', 'bold ', 'italic bold ']) { loads.push(document.fonts.load(style + '16px "' + f + '"', 'x')); }
    }
    fontsLoaded = Promise.allSettled(loads);
  }
  return fontsLoaded;
}

// Called with arguments only (callAsyncJavaScript); the TeX is never part of the script.
  window.renderTeX = async function (tex, display, fontPx, color) {
    await loadFonts();
    const box = document.getElementById('box');
    box.style.fontSize = fontPx + 'px';
    box.style.color = color;
    box.textContent = '';
    try {
      const host = document.createElement('span');
      katex.render(tex, host, { displayMode: display, throwOnError: true, trust: false, strict: 'ignore', output: 'html', maxSize: 50, maxExpand: 1000 });
      box.appendChild(host);
    } catch (e) {
      return { error: String(e && e.message ? e.message : e) };
    }
    const marker = document.createElement('span');
    marker.style.display = 'inline-block'; marker.style.width = '0'; marker.style.height = '0';
    box.appendChild(marker);
    void box.offsetWidth; // force layout so any remaining face starts loading
    await document.fonts.ready;
    const r = box.getBoundingClientRect();
    const m = marker.getBoundingClientRect();
    return { x: r.left, y: r.top, width: Math.ceil(r.width), height: Math.ceil(r.height), baseline: m.top - r.top };
  };
