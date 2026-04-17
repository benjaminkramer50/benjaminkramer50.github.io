---
layout: page
title: Research
---

<style>
.research-card {
  display: flex;
  gap: 1.5rem;
  align-items: flex-start;
  padding: 1.1rem 1.25rem;
  margin-bottom: 0.9rem;
  border-radius: 6px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  transition: border-color 0.2s ease;
  overflow-wrap: break-word;
  word-wrap: break-word;
}
.research-card:hover { border-color: var(--color-muted); }
.research-diagram {
  flex: 0 0 120px;
  width: 120px;
  height: 120px;
  color: var(--color-accent);
  display: flex;
  align-items: center;
  justify-content: center;
}
.research-diagram svg { width: 100%; height: 100%; display: block; }
.research-body { flex: 1 1 320px; min-width: 0; }
.research-body p { margin: 0.3rem 0; line-height: 1.55; }
.research-title {
  font-weight: 700;
  color: var(--color-text);
  line-height: 1.4;
  margin: 0 0 0.25rem 0 !important;
}
.research-collab {
  color: var(--color-muted);
  font-size: 0.9rem;
  font-style: italic;
}
.research-body .entry-link { margin-top: 0.55rem; margin-right: 0.35rem; }
@media (max-width: 560px) {
  .research-card { flex-direction: column; gap: 0.75rem; }
  .research-diagram { flex: 0 0 auto; width: 100px; height: 100px; }
}
</style>

<p class="page-intro">My research is in computational biology and epidemiology, with most of my current work using large-scale health records to study how diseases develop, cluster, and change over time. A smaller part of my work is in single-cell genomics. The projects below are grouped by collaboration.</p>

<div class="section-header">Rzhetsky Lab, University of Chicago</div>

<p>I work with a de-identified insurance claims dataset of over 200 million US patients (Merative MarketScan, 2003 to 2024). Claims data records what clinicians billed for rather than what a patient truly had, which introduces noise, however the scale allows population-level questions that cohort studies cannot answer.</p>

<div class="research-card">
  <div class="research-diagram" aria-hidden="true">
    <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="34" cy="34" r="14" fill="currentColor" fill-opacity="0.2"/>
      <circle cx="34" cy="30" r="5" fill="currentColor" stroke="none"/>
      <path d="M26,44 Q34,38 42,44 L42,54 L26,54 Z" fill="currentColor" stroke="none"/>
      <circle cx="86" cy="34" r="14" fill="currentColor" fill-opacity="0.35"/>
      <circle cx="86" cy="30" r="5" fill="currentColor" stroke="none"/>
      <path d="M78,44 Q86,38 94,44 L94,54 L78,54 Z" fill="currentColor" stroke="none"/>
      <line x1="18" y1="98" x2="110" y2="98"/>
      <rect x="26" y="82" width="14" height="16" fill="currentColor" fill-opacity="0.35" stroke="none"/>
      <rect x="50" y="74" width="14" height="24" fill="currentColor" fill-opacity="0.55" stroke="none"/>
      <rect x="74" y="78" width="14" height="20" fill="currentColor" fill-opacity="0.45" stroke="none"/>
      <rect x="98" y="70" width="10" height="28" fill="currentColor" fill-opacity="0.65" stroke="none"/>
    </svg>
  </div>
  <div class="research-body">
    <p class="research-title">Birth Order and Disease Risk Across the Phenome</p>
    <p class="research-collab">with Steven Kushner and Andrey Rzhetsky</p>
    <p>Older studies of birth order typically rely on a few thousand families and test a handful of outcomes. I ran a phenome-wide scan on 10.3 million individuals from 5.1 million two-child MarketScan families, testing 569 diseases with two complementary designs: a between-family matched cohort and a within-family sibling comparison. 150 diseases show Bonferroni-significant birth-order associations, with later-borns at elevated risk for most of them (including several psychiatric, metabolic, and immunological conditions). The within-family design rules out most family-level confounders, which is the part I believe matters most methodologically.</p>
    <a class="entry-link" href="https://www.medrxiv.org/content/10.1101/2026.03.26.26349438" target="_blank" rel="noopener">medRxiv</a>
  </div>
</div>

<div class="research-card">
  <div class="research-diagram" aria-hidden="true">
    <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
      <line x1="10" y1="60" x2="110" y2="60" stroke-opacity="0.25"/>
      <path d="M10,60 L18,58 L24,66 L30,52 L36,70 L42,40 L48,82 L54,30 L60,90 L66,36 L72,74 L78,48 L84,66 L90,54 L96,62 L102,58 L110,60"/>
      <rect x="80" y="14" width="28" height="18" rx="3" fill="currentColor" fill-opacity="0.15"/>
      <line x1="86" y1="23" x2="102" y2="23"/>
      <line x1="94" y1="17" x2="94" y2="29"/>
    </svg>
  </div>
  <div class="research-body">
    <p class="research-title">Accelerometry for Frailty Prediction</p>
    <p class="research-collab">with Yanan Long, Megan Huisingh-Scheetz, and Andrey Rzhetsky</p>
    <p>I worked with roughly a week of free-living hip and wrist accelerometer data from older adults enrolled in a longitudinal aging study, and trained a set of models to classify frailty status at baseline and to predict 12-month frailty decline. The free-living signal carries more information than I initially expected, and a small set of engineered features (activity fragmentation, intensity bout structure) accounts for most of it. The clinical point of the project is whether a wearable stream can substitute for a clinic-based frailty phenotype, which matters for large epidemiological studies where in-person assessment is infeasible.</p>
    <a class="entry-link" href="https://doi.org/10.1101/2025.07.09.25330372" target="_blank" rel="noopener">medRxiv</a>
  </div>
</div>

<div class="section-header">Bryson Lab, MIT</div>

<p>Outside of the Rzhetsky Lab, I work on single-cell RNA-sequencing in the <a class="about-link" href="https://be.mit.edu/directory/bryan-bryson" target="_blank">Bryson Lab</a> at MIT, where I have contributed to a cross-disease atlas of human skin immune cells and to granuloma myeloid analysis in tuberculosis.</p>

<div class="research-card">
  <div class="research-diagram" aria-hidden="true">
    <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
      <g fill="currentColor" stroke="none">
        <circle cx="30" cy="34" r="2.2" fill-opacity="0.85"/>
        <circle cx="36" cy="30" r="2.2" fill-opacity="0.85"/>
        <circle cx="34" cy="40" r="2.2" fill-opacity="0.85"/>
        <circle cx="42" cy="36" r="2.2" fill-opacity="0.85"/>
        <circle cx="28" cy="42" r="2.2" fill-opacity="0.85"/>
        <circle cx="38" cy="44" r="2.2" fill-opacity="0.85"/>
      </g>
      <g fill="currentColor" stroke="none" fill-opacity="0.55">
        <circle cx="80" cy="28" r="2.2"/>
        <circle cx="86" cy="34" r="2.2"/>
        <circle cx="78" cy="36" r="2.2"/>
        <circle cx="90" cy="28" r="2.2"/>
        <circle cx="84" cy="42" r="2.2"/>
        <circle cx="92" cy="38" r="2.2"/>
      </g>
      <g fill="currentColor" stroke="none" fill-opacity="0.4">
        <circle cx="62" cy="70" r="2.2"/>
        <circle cx="70" cy="74" r="2.2"/>
        <circle cx="66" cy="80" r="2.2"/>
        <circle cx="74" cy="66" r="2.2"/>
        <circle cx="58" cy="78" r="2.2"/>
        <circle cx="72" cy="82" r="2.2"/>
      </g>
      <g fill="currentColor" stroke="none" fill-opacity="0.7">
        <circle cx="28" cy="88" r="2.2"/>
        <circle cx="36" cy="94" r="2.2"/>
        <circle cx="34" cy="82" r="2.2"/>
        <circle cx="40" cy="88" r="2.2"/>
        <circle cx="26" cy="96" r="2.2"/>
        <circle cx="42" cy="96" r="2.2"/>
      </g>
      <g fill="currentColor" stroke="none" fill-opacity="0.3">
        <circle cx="94" cy="82" r="2.2"/>
        <circle cx="100" cy="88" r="2.2"/>
        <circle cx="88" cy="90" r="2.2"/>
        <circle cx="96" cy="96" r="2.2"/>
      </g>
    </svg>
  </div>
  <div class="research-body">
    <p class="research-title">Cross-Disease Atlas of Human Skin Immune Cells</p>
    <p class="research-collab">with Bryan Bryson and Robert Modlin</p>
    <p>I have been assembling a harmonized single-cell atlas of human skin across 22 diseases and roughly 341,000 immune cells, split into a myeloid compartment of 16 clusters and a T/NK compartment of 21 clusters. The aim is to identify cell states that are genuinely disease-specific rather than disease-biased (these are very different things, and I have learned the hard way how easy it is to confuse them). Current findings include cancer-specific expansion of intermediate monocytes, cross-disease expansion of CXCL13+ T peripheral helper cells, and a shared Treg signature across autoimmune skin conditions. Manuscript in preparation.</p>
  </div>
</div>

<div class="research-card">
  <div class="research-diagram" aria-hidden="true">
    <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="60" cy="60" r="34" fill="currentColor" fill-opacity="0.08"/>
      <circle cx="60" cy="60" r="24" fill="currentColor" fill-opacity="0.12"/>
      <circle cx="60" cy="60" r="14" fill="currentColor" fill-opacity="0.25"/>
      <g fill="currentColor" stroke="none">
        <circle cx="52" cy="54" r="2"/>
        <circle cx="66" cy="58" r="2"/>
        <circle cx="58" cy="66" r="2"/>
        <circle cx="72" cy="50" r="2"/>
        <circle cx="48" cy="62" r="2"/>
        <circle cx="80" cy="70" r="2"/>
      </g>
    </svg>
  </div>
  <div class="research-body">
    <p class="research-title">Myeloid Signaling in Tuberculosis Granulomas</p>
    <p class="research-collab">with Joshua Peters, Bryan Bryson, and collaborators</p>
    <p>I contributed to a study of myeloid cell signaling in non-human primate tuberculosis granulomas, where we reconstructed conserved myeloid states across a time course of infection and associated them with IFN-&gamma; and TGF-&beta; signaling. My work was on applying CellTypist-based annotation to the granuloma compartments and on downstream comparative analysis. Authorship was offered after the preprint was posted.</p>
    <a class="entry-link" href="https://doi.org/10.1101/2024.05.24.595747" target="_blank" rel="noopener">bioRxiv</a>
  </div>
</div>

<div class="section-header">Earlier Work</div>

<p>Before UChicago and MIT, my research was in renal physiology at <a class="about-link" href="https://case.edu/" target="_blank">Case Western Reserve</a> with <a class="about-link" href="https://physiology.case.edu/people/faculty/agustin-gonzalez-vicente/" target="_blank">Agustin Gonzalez-Vicente</a> and Jeffrey Garvin, and in satellite-based air pollution analysis during a Berkeley REU with <a class="about-link" href="https://publichealth.berkeley.edu/people/misbath-daouda" target="_blank">Misbath Daouda</a>. A list of the resulting publications and abstracts is on the <a href="/publications">Publications</a> page.</p>
