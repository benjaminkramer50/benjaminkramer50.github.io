---
layout: page
title: Quizbowl Literature Reading List
description: A searchable quizbowl-derived reading list built from repeated literary works in raw answerlines and clue text.
permalink: /quizbowl-canon/
wide: true
---

{% assign qb_items = site.data.quizbowl_literature_canon %}
{% assign qb_core = qb_items | where: "tier", "qb_core" %}
{% assign qb_major = qb_items | where: "tier", "qb_major" %}
{% assign qb_contextual = qb_items | where: "tier", "qb_contextual" %}
{% assign qb_accepted = qb_items | where: "review_status", "accepted_likely_work" %}

<section class="quizbowl-canon-hero" aria-label="Quizbowl literature reading list overview">
  <p class="quizbowl-kicker">Quizbowl Literature</p>
  <p class="page-intro">A searchable reading list of literary works that recur across quizbowl questions. Strength is based on how often a title appears in raw answerlines and clue text, so the list works as a practical map of what quizbowl repeatedly treats as canonical.</p>
  <p class="canon-status-note">This is not a universal canon and it is not a hand-ranked syllabus. It is an evidence-first browser for quizbowl recurrence, with non-literary hits filtered out of the public list.</p>
</section>

<div class="canon-summary quizbowl-summary" aria-label="Quizbowl canon summary">
  <div class="canon-stat canon-stat-accepted">
    <span class="canon-stat-number">{{ qb_accepted.size }}</span>
    <span class="canon-stat-label">Public Works</span>
  </div>
  <div class="canon-stat canon-stat-accepted">
    <span class="canon-stat-number">{{ qb_core.size }}</span>
    <span class="canon-stat-label">Core</span>
  </div>
  <div class="canon-stat canon-stat-reviewed">
    <span class="canon-stat-number">{{ qb_major.size }}</span>
    <span class="canon-stat-label">Major</span>
  </div>
  <div class="canon-stat canon-stat-planned">
    <span class="canon-stat-number">{{ qb_contextual.size }}</span>
    <span class="canon-stat-label">Contextual</span>
  </div>
</div>

<div class="quizbowl-method-strip" aria-label="Build method">
  <span>Source: parsed quizbowl archive</span>
  <span>Included: repeated literary works</span>
  <span>Evidence: answerlines and clue text</span>
  <span>View: paginated for speed</span>
</div>

<div class="quizbowl-quick-filters" aria-label="Quick tier filters">
  <button class="quizbowl-filter-button" type="button" data-tier-button="" aria-pressed="true">All</button>
  <button class="quizbowl-filter-button" type="button" data-tier-button="qb_core" aria-pressed="false">Core</button>
  <button class="quizbowl-filter-button" type="button" data-tier-button="qb_major" aria-pressed="false">Major</button>
  <button class="quizbowl-filter-button" type="button" data-tier-button="qb_contextual" aria-pressed="false">Contextual</button>
</div>

<div class="canon-filters quizbowl-primary-filters" aria-label="Primary quizbowl literature filters">
  <label class="canon-filter-field canon-search-field" for="qb-search">
    <span>Search</span>
    <input id="qb-search" type="search" placeholder="Title, form, tradition, set, clue sample..." aria-label="Search quizbowl literature reading list">
  </label>
  <label class="canon-filter-field" for="qb-unit-filter">
    <span>Reading Unit</span>
    <select id="qb-unit-filter" aria-label="Filter by reading unit">
      <option value="">Any Unit</option>
      <option value="ancient_epic_scripture_myth">Ancient Epic / Scripture</option>
      <option value="classical_drama">Classical Drama</option>
      <option value="medieval_romance_saga">Medieval Romance / Saga</option>
      <option value="early_modern_drama">Early Modern Drama</option>
      <option value="early_modern_world_literature">Early Modern World Lit</option>
      <option value="eighteenth_century_prose_and_drama">18th-Century Prose / Drama</option>
      <option value="nineteenth_century_fiction">19th-Century Fiction</option>
      <option value="nineteenth_century_poetry_and_drama">19th-Century Poetry / Drama</option>
      <option value="modernism">Modernism</option>
      <option value="postwar_literature">Postwar Literature</option>
      <option value="postwar_global_literature">Postwar Global Literature</option>
      <option value="contemporary_global_literature">Contemporary Global</option>
      <option value="poetry">Poetry</option>
      <option value="short_fiction">Short Fiction</option>
      <option value="drama">Drama</option>
      <option value="literary_nonfiction">Literary Nonfiction</option>
      <option value="fiction_and_narrative">Fiction / Narrative</option>
      <option value="collections_and_cycles">Collections / Cycles</option>
      <option value="epic_romance_or_oral_tradition">Epic / Oral Tradition</option>
      <option value="scripture_myth_hymn">Scripture / Myth / Hymn</option>
      <option value="unclassified_unit">Unclassified</option>
    </select>
  </label>
  <label class="canon-filter-field" for="qb-sort">
    <span>Sort</span>
    <select id="qb-sort" aria-label="Sort quizbowl literature reading list">
      <option value="rank">Salience Rank</option>
      <option value="questions">Question Count</option>
      <option value="title">Title</option>
    </select>
  </label>
  <label class="canon-filter-field" for="qb-page-size">
    <span>Per Page</span>
    <select id="qb-page-size" aria-label="Works shown per page">
      <option value="25">25</option>
      <option value="50" selected>50</option>
      <option value="100">100</option>
    </select>
  </label>
</div>

<details class="quizbowl-advanced-filters">
  <summary>More filters</summary>
  <div class="canon-filters quizbowl-secondary-filters" aria-label="Additional quizbowl literature filters">
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
    <label class="canon-filter-field" for="qb-form-filter">
      <span>Form</span>
      <select id="qb-form-filter" aria-label="Filter by inferred work form">
        <option value="">Any Form</option>
        <option value="long_fiction">Long Fiction</option>
        <option value="drama">Drama</option>
        <option value="poetry">Poetry</option>
        <option value="short_fiction">Short Fiction</option>
        <option value="epic_or_romance">Epic / Romance</option>
        <option value="essay_memoir_nonfiction">Essay / Memoir</option>
        <option value="collection_or_cycle">Collection / Cycle</option>
        <option value="scripture_myth_hymn">Scripture / Myth / Hymn</option>
        <option value="unknown_form">Unknown</option>
      </select>
    </label>
    <label class="canon-filter-field" for="qb-evidence-filter">
      <span>Evidence</span>
      <select id="qb-evidence-filter" aria-label="Filter by evidence profile">
        <option value="">Any Evidence</option>
        <option value="answerline_and_clue">Answerline + Clue</option>
        <option value="answerline_only">Answerline Only</option>
        <option value="clue_only">Clue Only</option>
      </select>
    </label>
    <label class="canon-filter-field" for="qb-era-filter">
      <span>Era</span>
      <select id="qb-era-filter" aria-label="Filter by inferred era">
        <option value="">Any Era</option>
        <option value="ancient_classical">Ancient / Classical</option>
        <option value="medieval">Medieval</option>
        <option value="early_modern">Early Modern</option>
        <option value="eighteenth_century">18th Century</option>
        <option value="long_19th_century">Long 19th Century</option>
        <option value="modernist">Modernist</option>
        <option value="postwar_modern">Postwar / Late 20th</option>
        <option value="contemporary">Contemporary</option>
        <option value="unknown_era">Unknown</option>
      </select>
    </label>
    <label class="canon-filter-field" for="qb-region-filter">
      <span>Tradition</span>
      <select id="qb-region-filter" aria-label="Filter by inferred region or tradition">
        <option value="">Any Tradition</option>
        <option value="african">African</option>
        <option value="american">American</option>
        <option value="arabic_persian_turkic">Arabic / Persian / Turkic</option>
        <option value="biblical_religious">Biblical / Religious</option>
        <option value="caribbean">Caribbean</option>
        <option value="chinese">Chinese</option>
        <option value="english_british_irish">English / British / Irish</option>
        <option value="french">French / Francophone</option>
        <option value="germanic_scandinavian">Germanic / Scandinavian</option>
        <option value="greek">Greek</option>
        <option value="iberian_lusophone">Iberian / Lusophone</option>
        <option value="indigenous_oceania">Indigenous / Oceania</option>
        <option value="italian">Italian</option>
        <option value="japanese_korean">Japanese / Korean</option>
        <option value="latin_american">Latin American</option>
        <option value="roman_latin">Roman / Latin</option>
        <option value="russian_eastern_european">Russian / Eastern European</option>
        <option value="south_asian">South Asian</option>
        <option value="unknown_region">Unknown</option>
      </select>
    </label>
    <label class="canon-filter-field" for="qb-context-filter">
      <span>Context</span>
      <select id="qb-context-filter" aria-label="Filter by dominant quizbowl context">
        <option value="">Any Context</option>
        <option value="literature_dominant">Literature Dominant</option>
        <option value="cross_category_literary">Cross-Category Literary</option>
        <option value="non_literature_context">Non-Literature Context</option>
      </select>
    </label>
    <label class="canon-filter-field" for="qb-route-filter">
      <span>Routing</span>
      <select id="qb-route-filter" aria-label="Filter by curation route">
        <option value="">Any Routing</option>
        <option value="accepted_clean">Accepted</option>
        <option value="protected_title_collision">Protected Collision</option>
        <option value="author_split_needed">Author Split Needed</option>
      </select>
    </label>
  </div>
</details>

<div class="quizbowl-canon-toolbar" aria-live="polite">
  <div class="canon-visible-count" id="qb-visible-count">Loading literature list...</div>
  <div class="quizbowl-pagination" id="qb-pagination-top">
    <button class="quizbowl-page-btn" type="button" data-page-action="prev">Previous</button>
    <span class="quizbowl-page-status" data-page-status>Page 1 of 1</span>
    <button class="quizbowl-page-btn" type="button" data-page-action="next">Next</button>
  </div>
</div>

<div class="canon-list quizbowl-canon-list" id="qb-canon-list">
  <div class="quizbowl-loading">Loading works...</div>
</div>

<div id="qb-no-results" class="diary-no-results" hidden>No quizbowl literature works match those filters.</div>

<div class="quizbowl-pagination quizbowl-pagination-bottom" id="qb-pagination-bottom" aria-label="Quizbowl literature pages">
  <button class="quizbowl-page-btn" type="button" data-page-action="prev">Previous</button>
  <span class="quizbowl-page-status" data-page-status>Page 1 of 1</span>
  <button class="quizbowl-page-btn" type="button" data-page-action="next">Next</button>
</div>

<script>
(function () {
  var dataUrl = '{{ "/quizbowl-canon-data.json" | relative_url }}';
  var items = [];
  var filteredItems = [];
  var currentPage = 1;

  var list = document.getElementById('qb-canon-list');
  var tierFilter = document.getElementById('qb-tier-filter');
  var formFilter = document.getElementById('qb-form-filter');
  var evidenceFilter = document.getElementById('qb-evidence-filter');
  var unitFilter = document.getElementById('qb-unit-filter');
  var eraFilter = document.getElementById('qb-era-filter');
  var regionFilter = document.getElementById('qb-region-filter');
  var contextFilter = document.getElementById('qb-context-filter');
  var routeFilter = document.getElementById('qb-route-filter');
  var sortSelect = document.getElementById('qb-sort');
  var searchInput = document.getElementById('qb-search');
  var pageSizeSelect = document.getElementById('qb-page-size');
  var visibleCount = document.getElementById('qb-visible-count');
  var noResults = document.getElementById('qb-no-results');
  var pageButtons = Array.prototype.slice.call(document.querySelectorAll('[data-page-action]'));
  var pageStatuses = Array.prototype.slice.call(document.querySelectorAll('[data-page-status]'));
  var tierButtons = Array.prototype.slice.call(document.querySelectorAll('[data-tier-button]'));

  var labels = {
    tier: {
      qb_core: 'Core',
      qb_major: 'Major',
      qb_contextual: 'Contextual',
      qb_candidate: 'Review Candidate'
    },
    form: {
      long_fiction: 'Long Fiction',
      drama: 'Drama',
      poetry: 'Poetry',
      short_fiction: 'Short Fiction',
      epic_or_romance: 'Epic / Romance',
      essay_memoir_nonfiction: 'Essay / Memoir',
      collection_or_cycle: 'Collection / Cycle',
      scripture_myth_hymn: 'Scripture / Myth / Hymn',
      unknown_form: 'Unknown Form'
    },
    evidence: {
      answerline_and_clue: 'Answerline + Clue',
      answerline_only: 'Answerline Only',
      clue_only: 'Clue Only'
    },
    unit: {
      ancient_epic_scripture_myth: 'Ancient Epic / Scripture',
      classical_drama: 'Classical Drama',
      medieval_romance_saga: 'Medieval Romance / Saga',
      early_modern_drama: 'Early Modern Drama',
      early_modern_world_literature: 'Early Modern World Lit',
      eighteenth_century_prose_and_drama: '18th-Century Prose / Drama',
      nineteenth_century_fiction: '19th-Century Fiction',
      nineteenth_century_poetry_and_drama: '19th-Century Poetry / Drama',
      modernism: 'Modernism',
      postwar_literature: 'Postwar Literature',
      postwar_global_literature: 'Postwar Global Literature',
      contemporary_global_literature: 'Contemporary Global',
      poetry: 'Poetry',
      short_fiction: 'Short Fiction',
      drama: 'Drama',
      literary_nonfiction: 'Literary Nonfiction',
      fiction_and_narrative: 'Fiction / Narrative',
      collections_and_cycles: 'Collections / Cycles',
      epic_romance_or_oral_tradition: 'Epic / Oral Tradition',
      scripture_myth_hymn: 'Scripture / Myth / Hymn',
      unclassified_unit: 'Unclassified Unit'
    },
    era: {
      ancient_classical: 'Ancient / Classical',
      medieval: 'Medieval',
      early_modern: 'Early Modern',
      eighteenth_century: '18th Century',
      long_19th_century: 'Long 19th Century',
      modernist: 'Modernist',
      postwar_modern: 'Postwar / Late 20th',
      contemporary: 'Contemporary',
      unknown_era: 'Unknown Era'
    },
    region: {
      african: 'African',
      american: 'American',
      arabic_persian_turkic: 'Arabic / Persian / Turkic',
      biblical_religious: 'Biblical / Religious',
      caribbean: 'Caribbean',
      chinese: 'Chinese',
      english_british_irish: 'English / British / Irish',
      french: 'French / Francophone',
      germanic_scandinavian: 'Germanic / Scandinavian',
      greek: 'Greek',
      iberian_lusophone: 'Iberian / Lusophone',
      indigenous_oceania: 'Indigenous / Oceania',
      italian: 'Italian',
      japanese_korean: 'Japanese / Korean',
      latin_american: 'Latin American',
      roman_latin: 'Roman / Latin',
      russian_eastern_european: 'Russian / Eastern European',
      south_asian: 'South Asian',
      unknown_region: 'Unknown Tradition'
    },
    context: {
      literature_dominant: 'Literature Dominant',
      cross_category_literary: 'Cross-Category Literary',
      non_literature_context: 'Non-Literature Context'
    },
    routing: {
      accepted_clean: 'Accepted',
      protected_title_collision: 'Protected Collision',
      author_split_needed: 'Author Split Needed'
    }
  };

  function escapeHtml(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function label(group, value) {
    if (!value) return '';
    return labels[group] && labels[group][value] ? labels[group][value] : String(value).replace(/_/g, ' ');
  }

  function numberValue(value, fallback) {
    var parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  function selectedValue(control) {
    return control ? control.value : '';
  }

  function buildSearchText(item) {
    return [
      item.title,
      item.tier,
      item.work_form,
      item.evidence_profile,
      item.reading_unit,
      item.era,
      item.region_or_tradition,
      item.dominant_quizbowl_track,
      item.quizbowl_track_profile,
      item.routing_status,
      item.example && item.example.set_title,
      item.example && item.example.snippet
    ].join(' ').toLowerCase();
  }

  function matches(item) {
    var search = selectedValue(searchInput).toLowerCase().trim();

    if (selectedValue(tierFilter) && item.tier !== selectedValue(tierFilter)) return false;
    if (selectedValue(formFilter) && item.work_form !== selectedValue(formFilter)) return false;
    if (selectedValue(evidenceFilter) && item.evidence_profile !== selectedValue(evidenceFilter)) return false;
    if (selectedValue(unitFilter) && item.reading_unit !== selectedValue(unitFilter)) return false;
    if (selectedValue(eraFilter) && item.era !== selectedValue(eraFilter)) return false;
    if (selectedValue(regionFilter) && item.region_or_tradition !== selectedValue(regionFilter)) return false;
    if (selectedValue(contextFilter) && item.quizbowl_track_profile !== selectedValue(contextFilter)) return false;
    if (selectedValue(routeFilter) && item.routing_status !== selectedValue(routeFilter)) return false;
    if (search && item.searchText.indexOf(search) === -1) return false;
    return true;
  }

  function compareItems(a, b) {
    var sort = selectedValue(sortSelect) || 'rank';
    if (sort === 'questions') {
      return numberValue(b.total_question_count, 0) - numberValue(a.total_question_count, 0);
    }
    if (sort === 'title') {
      return String(a.title || '').localeCompare(String(b.title || ''));
    }
    return numberValue(a.rank, 999999) - numberValue(b.rank, 999999);
  }

  function currentPageSize() {
    return numberValue(selectedValue(pageSizeSelect), 50);
  }

  function pageCount() {
    return Math.max(1, Math.ceil(filteredItems.length / currentPageSize()));
  }

  function syncTierButtons() {
    var selectedTier = selectedValue(tierFilter);
    tierButtons.forEach(function (button) {
      button.setAttribute('aria-pressed', button.getAttribute('data-tier-button') === selectedTier ? 'true' : 'false');
    });
  }

  function renderItem(item) {
    var article = document.createElement('article');
    article.className = 'canon-item quizbowl-canon-item';
    article.setAttribute('data-tier', item.tier || '');

    var firstLast = item.first_year && item.last_year
      ? '<span class="canon-date">' + escapeHtml(item.first_year) + '-' + escapeHtml(item.last_year) + '</span>'
      : '';
    var region = item.region_or_tradition && item.region_or_tradition !== 'unknown_region'
      ? '<span class="canon-chip">' + escapeHtml(label('region', item.region_or_tradition)) + '</span>'
      : '';
    var era = item.era && item.era !== 'unknown_era'
      ? '<span class="canon-chip">' + escapeHtml(label('era', item.era)) + '</span>'
      : '';
    var route = item.routing_status && item.routing_status !== 'accepted_clean'
      ? '<span class="canon-chip quizbowl-routing-chip">' + escapeHtml(label('routing', item.routing_status)) + '</span>'
      : '';
    var example = item.example && item.example.snippet
      ? '<details class="quizbowl-evidence"><summary>Evidence sample</summary><p><span>' +
          escapeHtml(item.example.set_title || 'Quizbowl clue') +
          (item.example.year ? ', ' + escapeHtml(item.example.year) : '') +
        '</span>' + escapeHtml(item.example.snippet) + '</p></details>'
      : '';

    article.innerHTML =
      '<div class="canon-status-mark quizbowl-tier-mark" aria-hidden="true"></div>' +
      '<div class="canon-item-body">' +
        '<div class="canon-item-topline">' +
          '<span class="canon-sequence-badge">#' + escapeHtml(item.rank) + '</span>' +
          '<span class="canon-era-badge">' + escapeHtml(label('tier', item.tier)) + '</span>' +
          '<span class="canon-date">' + escapeHtml(label('unit', item.reading_unit)) + '</span>' +
          '<span class="canon-date">' + escapeHtml(item.total_question_count) + ' questions</span>' +
          '<span class="canon-date">' + escapeHtml(item.distinct_set_count) + ' sets</span>' +
          firstLast +
        '</div>' +
        '<h2 class="canon-title">' + escapeHtml(item.title) + '</h2>' +
        '<div class="canon-meta">' +
          '<span class="canon-chip canon-level-chip">' + escapeHtml(label('form', item.work_form)) + '</span>' +
          '<span class="canon-chip">' + escapeHtml(label('evidence', item.evidence_profile)) + '</span>' +
          region +
          era +
          '<span class="canon-chip">' + escapeHtml(label('context', item.quizbowl_track_profile)) + '</span>' +
          route +
          '<span class="canon-chip">' + escapeHtml(label('', item.dominant_quizbowl_track)) + '</span>' +
          '<span class="canon-chip">' + escapeHtml(item.tossup_count) + ' tossups</span>' +
          '<span class="canon-chip">' + escapeHtml(item.bonus_count) + ' bonuses</span>' +
        '</div>' +
        example +
      '</div>' +
      '<div class="canon-item-actions quizbowl-score-block">' +
        '<span class="quizbowl-score-label">Score</span>' +
        '<span class="canon-status-label">' + escapeHtml(item.quizbowl_salience_score) + '</span>' +
      '</div>';
    return article;
  }

  function renderPagination() {
    var pages = pageCount();
    pageStatuses.forEach(function (status) {
      status.textContent = 'Page ' + currentPage + ' of ' + pages;
    });
    pageButtons.forEach(function (button) {
      var action = button.getAttribute('data-page-action');
      button.disabled = action === 'prev' ? currentPage <= 1 : currentPage >= pages;
    });
  }

  function render() {
    var size = currentPageSize();
    var start = (currentPage - 1) * size;
    var pageItems = filteredItems.slice(start, start + size);

    list.innerHTML = '';
    pageItems.forEach(function (item) {
      list.appendChild(renderItem(item));
    });

    if (visibleCount) {
      var startLabel = filteredItems.length ? start + 1 : 0;
      var endLabel = Math.min(start + size, filteredItems.length);
      visibleCount.textContent = 'Showing ' + startLabel + '-' + endLabel + ' of ' + filteredItems.length + ' works';
    }
    if (noResults) noResults.hidden = filteredItems.length !== 0;
    renderPagination();
  }

  function applyFilters() {
    filteredItems = items.filter(matches).sort(compareItems);
    currentPage = 1;
    syncTierButtons();
    render();
  }

  function setLoadingError() {
    list.innerHTML = '<div class="canon-empty-state"><strong>Could not load the reading list.</strong><p>Refresh the page and try again.</p></div>';
    if (visibleCount) visibleCount.textContent = 'The literature list did not load.';
  }

  [tierFilter, formFilter, evidenceFilter, unitFilter, eraFilter, regionFilter, contextFilter, routeFilter, sortSelect, pageSizeSelect].forEach(function (filter) {
    if (filter) filter.addEventListener('change', applyFilters);
  });
  if (searchInput) searchInput.addEventListener('input', applyFilters);
  tierButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      if (!tierFilter) return;
      tierFilter.value = button.getAttribute('data-tier-button') || '';
      applyFilters();
    });
  });
  pageButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      var pages = pageCount();
      if (button.getAttribute('data-page-action') === 'prev') currentPage = Math.max(1, currentPage - 1);
      if (button.getAttribute('data-page-action') === 'next') currentPage = Math.min(pages, currentPage + 1);
      render();
    });
  });

  fetch(dataUrl)
    .then(function (response) {
      if (!response.ok) throw new Error('Canon data request failed');
      return response.json();
    })
    .then(function (data) {
      items = data.map(function (item) {
        item.searchText = buildSearchText(item);
        return item;
      });
      filteredItems = items.slice().sort(compareItems);
      render();
    })
    .catch(setLoadingError);
})();
</script>
