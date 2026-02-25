"use strict";

const { tokenize } = require("./bm25");

function hashToken(token, dim) {
  let h = 2166136261;
  for (let i = 0; i < token.length; i++) {
    h ^= token.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return Math.abs(h) % dim;
}

function localEmbedding(text, dim = 128) {
  const vec = new Array(dim).fill(0);
  const terms = tokenize(text);
  for (const t of terms) vec[hashToken(t, dim)] += 1;
  const norm = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
  return vec.map((v) => v / norm);
}

function cosine(a, b) {
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (let i = 0; i < a.length; i++) {
    dot += (a[i] || 0) * (b[i] || 0);
    na += (a[i] || 0) ** 2;
    nb += (b[i] || 0) ** 2;
  }
  return dot / ((Math.sqrt(na) || 1) * (Math.sqrt(nb) || 1));
}

function buildVectorIndex(docs, opts = {}) {
  const dim = Number(opts.dim || 128);
  return {
    version: "vector-mvp-v1",
    createdAt: new Date().toISOString(),
    provider: opts.provider || "local-hash",
    dim,
    docs: docs.map((d) => ({
      id: d.id,
      source: d.source,
      title: d.title,
      scope: d.scope,
      type: d.type,
      createdAt: d.createdAt,
      preview: (d.content || "").slice(0, 220).replace(/\s+/g, " ").trim(),
      vector: localEmbedding(d.content || "", dim),
    })),
  };
}

function searchVector(index, query, topK = 20) {
  if (!index || !Array.isArray(index.docs)) return [];
  const qv = localEmbedding(query || "", index.dim || 128);
  return index.docs
    .map((d) => ({
      id: d.id,
      source: d.source,
      title: d.title,
      scope: d.scope,
      type: d.type,
      createdAt: d.createdAt,
      score: cosine(qv, d.vector || []),
      preview: d.preview,
    }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);
}

module.exports = { buildVectorIndex, searchVector };
