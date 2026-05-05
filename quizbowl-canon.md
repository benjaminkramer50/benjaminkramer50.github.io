---
layout: page
title: Quizbowl Literature Canon
description: A quizbowl-derived literature canon built from raw quizbowl answerlines and clue text.
permalink: /quizbowl-canon/
wide: true
---

{% assign qb_items = site.data.quizbowl_literature_canon %}
{% assign qb_core = qb_items | where: "tier", "qb_core" %}
{% assign qb_major = qb_items | where: "tier", "qb_major" %}
{% assign qb_contextual = qb_items | where: "tier", "qb_contextual" %}
{% assign qb_candidates = qb_items | where: "tier", "qb_candidate" %}
{% assign qb_accepted = qb_items | where: "review_status", "accepted_likely_work" %}
{% assign qb_needs_review = qb_items.size | minus: qb_accepted.size %}

<p class="page-intro">A quizbowl-only literature canon built directly from the raw parsed quizbowl archive. Work candidates come from raw answerlines when the question asks for a literary work, plus repeated title mentions in clue text.</p>

<p class="canon-status-note">This is evidence-first, not hand-curated. It is useful for finding what quizbowl repeatedly treats as canonical, measuring salience by recurrence, and separating strong automatic hits from review candidates. Rejected non-literary titles, such as operas and social-science works, are kept in the audit files rather than shown here.</p>

<div class="canon-summary quizbowl-summary" aria-label="Quizbowl canon summary">
  <div class="canon-stat canon-stat-accepted">
    <span class="canon-stat-number">{{ qb_accepted.size }}</span>
    <span class="canon-stat-label">Accepted</span>
  </div>
  <div class="canon-stat canon-stat-accepted">
    <span class="canon-stat-number">{{ qb_core.size }}</span>
    <span class="canon-stat-label">Core</span>
  </div>
  <div class="canon-stat canon-stat-reviewed">
    <span class="canon-stat-number">{{ qb_major.size }}</span>
    <span class="canon-stat-label">Major</span>
  </div>
  <div class="canon-stat canon-stat-source-review">
    <span class="canon-stat-number">{{ qb_needs_review }}</span>
    <span class="canon-stat-label">Needs Review</span>
  </div>
</div>

<div class="quizbowl-method-strip" aria-label="Build method">
  <span>Corpus: full parsed quizbowl archive</span>
  <span>Threshold: 4+ quizbowl questions</span>
  <span>Evidence: raw answerlines and clue text</span>
  <span>Sort: quizbowl salience rank</span>
</div>

<div class="canon-filters" aria-label="Quizbowl canon filters">
  <label class="canon-filter-field" for="qb-tier-filter">
    <span>Tier</span>
    <select id="qb-tier-filter" aria-label="Filter by quizbowl salience tier">
      <option value="">Any Tier</option>
      <option value="qb_core">Core</option>
      <option value="qb_major">Major</option>
      <option value="qb_contextual">Contextual</option>
      <option value="qb_candidate">Review Candidate</option>
    </select>
  </label>
  <label class="canon-filter-field" for="qb-review-filter">
    <span>Review</span>
    <select id="qb-review-filter" aria-label="Filter by review status">
      <option value="">Any Review Status</option>
      <option value="accepted" selected>Accepted Likely Work</option>
      <option value="needs-review">Needs Review</option>
      <option value="needs_review_common_or_short_title">Common / Short Title</option>
      <option value="needs_review_possible_character_or_person">Possible Person / Character</option>
      <option value="needs_review_possible_combined_title">Possible Combined Title</option>
      <option value="needs_review_fragment_title">Fragment Title</option>
      <option value="needs_review_section_or_subwork_title">Section / Subwork Title</option>
    </select>
  </label>
  <label class="canon-filter-field" for="qb-source-filter">
    <span>Source</span>
    <select id="qb-source-filter" aria-label="Filter by extraction source">
      <option value="">Any Source</option>
      <option value="answerline+clue">Answerline + Clue</option>
      <option value="answerline">Answerline Only</option>
      <option value="clue">Clue Only</option>
    </select>
  </label>
  <label class="canon-filter-field" for="qb-sort">
    <span>Sort</span>
    <select id="qb-sort" aria-label="Sort quizbowl canon">
      <option value="rank">Salience Rank</option>
      <option value="questions">Question Count</option>
      <option value="title">Title</option>
    </select>
  </label>
  <label class="canon-filter-field canon-search-field" for="qb-search">
    <span>Search</span>
    <input id="qb-search" type="search" placeholder="Title, snippet, set..." aria-label="Search quizbowl literature canon">
  </label>
</div>

<div class="canon-visible-count" id="qb-visible-count"></div>

<div class="canon-list quizbowl-canon-list" id="qb-canon-list">
  {% for item in qb_items %}
  {% assign tier_label = item.tier | replace: "qb_", "" | replace: "_", " " | capitalize %}
  {% if item.tier == "qb_candidate" %}{% assign tier_label = "Review Candidate" %}{% endif %}
  {% assign review_group = "needs-review" %}
  {% assign review_label = item.review_status | replace: "_", " " | capitalize %}
  {% if item.review_status == "accepted_likely_work" %}
    {% assign review_group = "accepted" %}
    {% assign review_label = "Accepted" %}
  {% elsif item.review_status == "needs_review_common_or_short_title" %}
    {% assign review_label = "Common / Short" %}
  {% elsif item.review_status == "needs_review_possible_character_or_person" %}
    {% assign review_label = "Person / Character" %}
  {% elsif item.review_status == "needs_review_possible_combined_title" %}
    {% assign review_label = "Combined Title" %}
  {% elsif item.review_status == "needs_review_fragment_title" %}
    {% assign review_label = "Fragment" %}
  {% elsif item.review_status == "needs_review_section_or_subwork_title" %}
    {% assign review_label = "Section / Subwork" %}
  {% elsif item.review_status == "needs_review_low_evidence" %}
    {% assign review_label = "Low Evidence" %}
  {% endif %}
  {% assign source_group = "clue" %}
  {% assign source_label = "Clue Only" %}
  {% if item.answerline_question_count > 0 and item.clue_mention_question_count > 0 %}
    {% assign source_group = "answerline+clue" %}
    {% assign source_label = "Answerline + Clue" %}
  {% elsif item.answerline_question_count > 0 %}
    {% assign source_group = "answerline" %}
    {% assign source_label = "Answerline Only" %}
  {% endif %}
  {% assign first_example = item.examples | first %}
  {% capture search_text %}{{ item.title }} {{ item.tier }} {{ item.review_status }} {{ item.form_hint }} {{ first_example.set_title }} {{ first_example.snippet }}{% endcapture %}
  <article class="canon-item quizbowl-canon-item"
           data-rank="{{ item.rank }}"
           data-title="{{ item.title | downcase | escape }}"
           data-tier="{{ item.tier | escape }}"
           data-review="{{ item.review_status | escape }}"
           data-review-group="{{ review_group }}"
           data-source="{{ source_group }}"
           data-question-count="{{ item.total_question_count }}"
           data-search="{{ search_text | strip_newlines | downcase | escape }}">
    <div class="canon-status-mark quizbowl-tier-mark" aria-hidden="true"></div>
    <div class="canon-item-body">
      <div class="canon-item-topline">
        <span class="canon-sequence-badge">#{{ item.rank }}</span>
        <span class="canon-era-badge">{{ tier_label }}</span>
        <span class="canon-date">{{ item.total_question_count }} questions</span>
        <span class="canon-date">{{ item.answerline_question_count }} answers</span>
        <span class="canon-date">{{ item.clue_mention_question_count }} clues</span>
        <span class="canon-date">{{ item.distinct_set_count }} sets</span>
        {% if item.first_year and item.last_year %}
        <span class="canon-date">{{ item.first_year }}-{{ item.last_year }}</span>
        {% endif %}
      </div>
      <h2 class="canon-title">{{ item.title }}</h2>
      <div class="canon-meta">
        <span class="canon-chip canon-level-chip">{{ review_label }}</span>
        <span class="canon-chip">{{ source_label }}</span>
        <span class="canon-chip">{{ item.tossup_count }} tossups</span>
        <span class="canon-chip">{{ item.bonus_count }} bonuses</span>
      </div>
      {% if first_example %}
      <details class="quizbowl-evidence">
        <summary>Evidence sample</summary>
        <p>
          <span>{{ first_example.set_title }}{% if first_example.year %}, {{ first_example.year }}{% endif %}</span>
          {{ first_example.snippet | truncate: 230 }}
        </p>
      </details>
      {% endif %}
    </div>
    <div class="canon-item-actions quizbowl-score-block">
      <span class="quizbowl-score-label">Score</span>
      <span class="canon-status-label">{{ item.quizbowl_salience_score }}</span>
    </div>
  </article>
  {% endfor %}
</div>

<div id="qb-no-results" class="diary-no-results" style="display:none;">No quizbowl canon titles match your filters.</div>

<script>
(function () {
  var rows = Array.prototype.slice.call(document.querySelectorAll('.quizbowl-canon-item'));
  var list = document.getElementById('qb-canon-list');
  var tierFilter = document.getElementById('qb-tier-filter');
  var reviewFilter = document.getElementById('qb-review-filter');
  var sourceFilter = document.getElementById('qb-source-filter');
  var sortSelect = document.getElementById('qb-sort');
  var searchInput = document.getElementById('qb-search');
  var visibleCount = document.getElementById('qb-visible-count');
  var noResults = document.getElementById('qb-no-results');

  function numberAttr(row, attr, fallback) {
    var value = parseFloat(row.getAttribute(attr));
    return isNaN(value) ? fallback : value;
  }

  function matches(row) {
    var tier = tierFilter ? tierFilter.value : '';
    var review = reviewFilter ? reviewFilter.value : '';
    var source = sourceFilter ? sourceFilter.value : '';
    var search = searchInput ? searchInput.value.toLowerCase().trim() : '';

    if (tier && row.getAttribute('data-tier') !== tier) return false;
    if (review === 'accepted' && row.getAttribute('data-review-group') !== 'accepted') return false;
    if (review === 'needs-review' && row.getAttribute('data-review-group') !== 'needs-review') return false;
    if (review && review !== 'accepted' && review !== 'needs-review' && row.getAttribute('data-review') !== review) return false;
    if (source && row.getAttribute('data-source') !== source) return false;
    if (search && (row.getAttribute('data-search') || '').indexOf(search) === -1) return false;
    return true;
  }

  function compareRows(a, b) {
    var sort = sortSelect ? sortSelect.value : 'rank';
    if (sort === 'questions') {
      return numberAttr(b, 'data-question-count', 0) - numberAttr(a, 'data-question-count', 0);
    }
    if (sort === 'title') {
      return (a.getAttribute('data-title') || '').localeCompare(b.getAttribute('data-title') || '');
    }
    return numberAttr(a, 'data-rank', 999999) - numberAttr(b, 'data-rank', 999999);
  }

  function render() {
    var shown = 0;
    rows.sort(compareRows).forEach(function (row) {
      list.appendChild(row);
      var isVisible = matches(row);
      row.hidden = !isVisible;
      if (isVisible) shown++;
    });
    if (visibleCount) visibleCount.textContent = 'Showing ' + shown + ' of ' + rows.length + ' titles';
    if (noResults) noResults.style.display = rows.length > 0 && shown === 0 ? '' : 'none';
  }

  [tierFilter, reviewFilter, sourceFilter, sortSelect].forEach(function (filter) {
    if (filter) filter.addEventListener('change', render);
  });
  if (searchInput) searchInput.addEventListener('input', render);

  render();
})();
</script>
