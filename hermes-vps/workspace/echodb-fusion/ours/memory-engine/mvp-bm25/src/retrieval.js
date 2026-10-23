"use strict";

function shouldRetrieve(query, context = {}) {
  if (context.forceRetrieve) return { retrieve: true, reason: "forced" };
  const q = (query || "").trim().toLowerCase();
  if (!q) return { retrieve: false, reason: "empty-query" };
  const shortTalk = [/^你好[呀吗呢]?([!！。？?])?$/, /^hi+$/i, /^hello$/i, /^ok(ay)?$/i, /^收到$/, /^嗯+$/, /^谢谢(你)?$/];
  if (q.length <= 4 || shortTalk.some((r) => r.test(q))) {
    return { retrieve: false, reason: "small-talk-or-confirmation" };
  }
  return { retrieve: true, reason: "default" };
}

function scoreRecency(createdAt, halfLifeDays = 30) {
  const ts = Date.parse(createdAt || "") || Date.now();
  const ageDays = Math.max(0, (Date.now() - ts) / 86400000);
  return Math.exp((-Math.log(2) * ageDays) / Math.max(1, halfLifeDays));
}

function scoreLengthNorm(preview, ideal = 180) {
  const len = (preview || "").length || 1;
  const ratio = Math.min(len, ideal) / Math.max(len, ideal);
  return Math.max(0.2, ratio);
}

function mmrSelect(results, lambda = 0.7, topK = 20) {
  const selected = [];
  const rest = [...results];
  const tokenSets = new Map(rest.map((r) => [r.id, new Set((r.preview || "").toLowerCase().split(/\s+/).filter(Boolean))]));

  const sim = (a, b) => {
    const A = tokenSets.get(a.id) || new Set();
    const B = tokenSets.get(b.id) || new Set();
    let overlap = 0;
    for (const t of A) if (B.has(t)) overlap++;
    return overlap / Math.max(1, Math.min(A.size, B.size));
  };

  while (selected.length < topK && rest.length) {
    let bestI = 0;
    let best = -Infinity;
    for (let i = 0; i < rest.length; i++) {
      const r = rest[i];
      const rel = r.finalScore || r.score || 0;
      let red = 0;
      for (const s of selected) red = Math.max(red, sim(r, s));
      const v = lambda * rel - (1 - lambda) * red;
      if (v > best) {
        best = v;
        bestI = i;
      }
    }
    selected.push(rest.splice(bestI, 1)[0]);
  }
  return selected;
}

function normalizeByMax(v, max) {
  return max > 0 ? v / max : 0;
}

function fuseResults({ bm25 = [], vector = [], strategy = "rrf", bm25Weight = 0.6, vectorWeight = 0.4, topK = 20, recencyHalfLifeDays = 30 }) {
  const byId = new Map();
  const maxB = Math.max(0, ...bm25.map((x) => x.score || 0));
  const maxV = Math.max(0, ...vector.map((x) => x.score || 0));

  bm25.forEach((r, idx) => {
    const item = byId.get(r.id) || { ...r, debug: {} };
    item.debug.bm25 = r.score;
    item.debug.bm25Rank = idx + 1;
    byId.set(r.id, item);
  });
  vector.forEach((r, idx) => {
    const item = byId.get(r.id) || { ...r, debug: {} };
    item.debug.vector = r.score;
    item.debug.vectorRank = idx + 1;
    if (!item.preview) item.preview = r.preview;
    if (!item.source) item.source = r.source;
    if (!item.scope) item.scope = r.scope;
    if (!item.type) item.type = r.type;
    if (!item.createdAt) item.createdAt = r.createdAt;
    byId.set(r.id, item);
  });

  const arr = [...byId.values()].map((x) => {
    const b = x.debug.bm25 || 0;
    const v = x.debug.vector || 0;
    let base = 0;
    if (strategy === "weighted") {
      base = bm25Weight * normalizeByMax(b, maxB) + vectorWeight * normalizeByMax(v, maxV);
    } else {
      const k = 60;
      base = (x.debug.bm25Rank ? 1 / (k + x.debug.bm25Rank) : 0) + (x.debug.vectorRank ? 1 / (k + x.debug.vectorRank) : 0);
    }
    const recency = scoreRecency(x.createdAt, recencyHalfLifeDays);
    const lengthNorm = scoreLengthNorm(x.preview);
    x.debug.recency = recency;
    x.debug.lengthNorm = lengthNorm;
    x.baseScore = base;
    x.finalScore = base * (0.85 + 0.15 * recency) * (0.8 + 0.2 * lengthNorm);
    return x;
  });

  return arr.sort((a, b) => b.finalScore - a.finalScore).slice(0, topK);
}

module.exports = { shouldRetrieve, fuseResults, mmrSelect };
