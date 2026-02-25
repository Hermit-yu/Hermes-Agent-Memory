"use strict";

function tokenize(text) {
  const normalized = (text || "")
    .toLowerCase()
    .replace(/[`~!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?，。！？；：（）【】、《》“”‘’]/g, " ");

  const words = normalized
    .split(/\s+/)
    .map((t) => t.trim())
    .filter(Boolean);

  // simple CJK bigram fallback for short Chinese queries/docs
  const cjk = normalized.replace(/\s+/g, "").match(/[\u4e00-\u9fff]/g) || [];
  for (let i = 0; i < cjk.length - 1; i++) {
    words.push(`${cjk[i]}${cjk[i + 1]}`);
  }
  return words;
}

function buildBm25(documents, options = {}) {
  const k1 = options.k1 ?? 1.5;
  const b = options.b ?? 0.75;

  const docs = documents.map((doc, idx) => {
    const terms = tokenize(doc.content);
    const tf = new Map();
    for (const term of terms) tf.set(term, (tf.get(term) || 0) + 1);
    return {
      id: doc.id || `doc-${idx}`,
      source: doc.source,
      title: doc.title,
      scope: doc.scope || "unknown",
      type: doc.type || "unknown",
      content: doc.content,
      terms,
      tf,
      length: terms.length,
      createdAt: doc.createdAt,
    };
  });

  const N = docs.length;
  const avgdl = N === 0 ? 0 : docs.reduce((sum, d) => sum + d.length, 0) / N;

  const df = new Map();
  for (const d of docs) for (const term of d.tf.keys()) df.set(term, (df.get(term) || 0) + 1);

  const idf = new Map();
  for (const [term, freq] of df.entries()) {
    idf.set(term, Math.log(1 + (N - freq + 0.5) / (freq + 0.5)));
  }

  return {
    version: "bm25-mvp-v2",
    createdAt: new Date().toISOString(),
    config: { k1, b },
    N,
    avgdl,
    df: Object.fromEntries(df),
    idf: Object.fromEntries(idf),
    docs: docs.map((d) => ({
      id: d.id,
      source: d.source,
      title: d.title,
      scope: d.scope,
      type: d.type,
      content: d.content,
      createdAt: d.createdAt,
      length: d.length,
      tf: Object.fromEntries(d.tf),
    })),
  };
}

function searchBm25(index, query, topK = 20) {
  if (!index || !Array.isArray(index.docs)) return [];
  const k1 = index.config?.k1 ?? 1.5;
  const b = index.config?.b ?? 0.75;
  const avgdl = index.avgdl || 0;
  const uniqueTerms = [...new Set(tokenize(query))];

  const results = [];
  for (const doc of index.docs) {
    let score = 0;
    for (const term of uniqueTerms) {
      const tf = doc.tf?.[term] || 0;
      if (!tf) continue;
      const idf = index.idf?.[term] || 0;
      const denom = tf + k1 * (1 - b + b * ((doc.length || 0) / (avgdl || 1)));
      score += idf * ((tf * (k1 + 1)) / (denom || 1));
    }
    if (score > 0) {
      results.push({
        id: doc.id,
        source: doc.source,
        title: doc.title,
        scope: doc.scope || "unknown",
        type: doc.type || "unknown",
        createdAt: doc.createdAt,
        score,
        preview: (doc.content || "").slice(0, 220).replace(/\s+/g, " ").trim(),
      });
    }
  }

  return results.sort((a, b) => b.score - a.score).slice(0, topK);
}

module.exports = { tokenize, buildBm25, searchBm25 };
