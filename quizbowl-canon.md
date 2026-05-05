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
{% assign qb_author_split = qb_items | where: "routing_status", "author_split_needed" %}
{% assign qb_title_collision = qb_items | where: "routing_status", "protected_title_collision" %}
{% assign qb_watch_count = qb_author_split.size | plus: qb_title_collision.size %}

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
    <span class="canon-stat-number">{{ qb_watch_count }}</span>
    <span class="canon-stat-label">Title Watch</span>
  </div>
</div>

<div class="quizbowl-method-strip" aria-label="Build method">
  <span>Corpus: full parsed quizbowl archive</span>
  <span>Threshold: 4+ quizbowl questions</span>
  <span>Evidence: raw answerlines and clue text</span>
  <span>Categories: evidence-derived</span>
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
  <label class="canon-filter-field" for="qb-unit-filter">
    <span>Unit</span>
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
  {% assign form_label = item.work_form | replace: "_", " " | capitalize %}
  {% if item.work_form == "long_fiction" %}
    {% assign form_label = "Long Fiction" %}
  {% elsif item.work_form == "short_fiction" %}
    {% assign form_label = "Short Fiction" %}
  {% elsif item.work_form == "epic_or_romance" %}
    {% assign form_label = "Epic / Romance" %}
  {% elsif item.work_form == "essay_memoir_nonfiction" %}
    {% assign form_label = "Essay / Memoir" %}
  {% elsif item.work_form == "collection_or_cycle" %}
    {% assign form_label = "Collection / Cycle" %}
  {% elsif item.work_form == "scripture_myth_hymn" %}
    {% assign form_label = "Scripture / Myth / Hymn" %}
  {% elsif item.work_form == "unknown_form" %}
    {% assign form_label = "Unknown Form" %}
  {% endif %}
  {% assign evidence_label = item.evidence_profile | replace: "_", " " | capitalize %}
  {% if item.evidence_profile == "answerline_and_clue" %}
    {% assign evidence_label = "Answerline + Clue" %}
  {% elsif item.evidence_profile == "answerline_only" %}
    {% assign evidence_label = "Answerline Only" %}
  {% elsif item.evidence_profile == "clue_only" %}
    {% assign evidence_label = "Clue Only" %}
  {% endif %}
  {% assign unit_label = item.reading_unit | replace: "_", " " | capitalize %}
  {% if item.reading_unit == "ancient_epic_scripture_myth" %}
    {% assign unit_label = "Ancient Epic / Scripture" %}
  {% elsif item.reading_unit == "classical_drama" %}
    {% assign unit_label = "Classical Drama" %}
  {% elsif item.reading_unit == "medieval_romance_saga" %}
    {% assign unit_label = "Medieval Romance / Saga" %}
  {% elsif item.reading_unit == "early_modern_drama" %}
    {% assign unit_label = "Early Modern Drama" %}
  {% elsif item.reading_unit == "early_modern_world_literature" %}
    {% assign unit_label = "Early Modern World Lit" %}
  {% elsif item.reading_unit == "eighteenth_century_prose_and_drama" %}
    {% assign unit_label = "18th-Century Prose / Drama" %}
  {% elsif item.reading_unit == "nineteenth_century_fiction" %}
    {% assign unit_label = "19th-Century Fiction" %}
  {% elsif item.reading_unit == "nineteenth_century_poetry_and_drama" %}
    {% assign unit_label = "19th-Century Poetry / Drama" %}
  {% elsif item.reading_unit == "postwar_global_literature" %}
    {% assign unit_label = "Postwar Global Literature" %}
  {% elsif item.reading_unit == "postwar_literature" %}
    {% assign unit_label = "Postwar Literature" %}
  {% elsif item.reading_unit == "contemporary_global_literature" %}
    {% assign unit_label = "Contemporary Global" %}
  {% elsif item.reading_unit == "literary_nonfiction" %}
    {% assign unit_label = "Literary Nonfiction" %}
  {% elsif item.reading_unit == "fiction_and_narrative" %}
    {% assign unit_label = "Fiction / Narrative" %}
  {% elsif item.reading_unit == "collections_and_cycles" %}
    {% assign unit_label = "Collections / Cycles" %}
  {% elsif item.reading_unit == "epic_romance_or_oral_tradition" %}
    {% assign unit_label = "Epic / Oral Tradition" %}
  {% elsif item.reading_unit == "scripture_myth_hymn" %}
    {% assign unit_label = "Scripture / Myth / Hymn" %}
  {% elsif item.reading_unit == "unclassified_unit" %}
    {% assign unit_label = "Unclassified Unit" %}
  {% endif %}
  {% assign era_label = item.era | replace: "_", " " | capitalize %}
  {% if item.era == "ancient_classical" %}
    {% assign era_label = "Ancient / Classical" %}
  {% elsif item.era == "eighteenth_century" %}
    {% assign era_label = "18th Century" %}
  {% elsif item.era == "long_19th_century" %}
    {% assign era_label = "Long 19th Century" %}
  {% elsif item.era == "postwar_modern" %}
    {% assign era_label = "Postwar / Late 20th" %}
  {% elsif item.era == "unknown_era" %}
    {% assign era_label = "Unknown Era" %}
  {% endif %}
  {% assign region_label = item.region_or_tradition | replace: "_", " " | capitalize %}
  {% if item.region_or_tradition == "arabic_persian_turkic" %}
    {% assign region_label = "Arabic / Persian / Turkic" %}
  {% elsif item.region_or_tradition == "biblical_religious" %}
    {% assign region_label = "Biblical / Religious" %}
  {% elsif item.region_or_tradition == "english_british_irish" %}
    {% assign region_label = "English / British / Irish" %}
  {% elsif item.region_or_tradition == "germanic_scandinavian" %}
    {% assign region_label = "Germanic / Scandinavian" %}
  {% elsif item.region_or_tradition == "iberian_lusophone" %}
    {% assign region_label = "Iberian / Lusophone" %}
  {% elsif item.region_or_tradition == "indigenous_oceania" %}
    {% assign region_label = "Indigenous / Oceania" %}
  {% elsif item.region_or_tradition == "japanese_korean" %}
    {% assign region_label = "Japanese / Korean" %}
  {% elsif item.region_or_tradition == "latin_american" %}
    {% assign region_label = "Latin American" %}
  {% elsif item.region_or_tradition == "roman_latin" %}
    {% assign region_label = "Roman / Latin" %}
  {% elsif item.region_or_tradition == "russian_eastern_european" %}
    {% assign region_label = "Russian / Eastern European" %}
  {% elsif item.region_or_tradition == "south_asian" %}
    {% assign region_label = "South Asian" %}
  {% elsif item.region_or_tradition == "unknown_region" %}
    {% assign region_label = "Unknown Tradition" %}
  {% endif %}
  {% assign context_label = item.quizbowl_track_profile | replace: "_", " " | capitalize %}
  {% if item.quizbowl_track_profile == "literature_dominant" %}
    {% assign context_label = "Literature Dominant" %}
  {% elsif item.quizbowl_track_profile == "cross_category_literary" %}
    {% assign context_label = "Cross-Category Literary" %}
  {% elsif item.quizbowl_track_profile == "non_literature_context" %}
    {% assign context_label = "Non-Literature Context" %}
  {% endif %}
  {% assign routing_label = item.routing_status | replace: "_", " " | capitalize %}
  {% if item.routing_status == "accepted_clean" %}
    {% assign routing_label = "Accepted" %}
  {% elsif item.routing_status == "protected_title_collision" %}
    {% assign routing_label = "Protected Collision" %}
  {% elsif item.routing_status == "author_split_needed" %}
    {% assign routing_label = "Author Split Needed" %}
  {% endif %}
  {% assign first_example = item.examples | first %}
  {% capture search_text %}{{ item.title }} {{ item.tier }} {{ item.work_form }} {{ item.evidence_profile }} {{ item.reading_unit }} {{ item.era }} {{ item.region_or_tradition }} {{ item.dominant_quizbowl_track }} {{ item.quizbowl_track_profile }} {{ item.routing_status }} {{ first_example.set_title }} {{ first_example.snippet }}{% endcapture %}
  <article class="canon-item quizbowl-canon-item"
           data-rank="{{ item.rank }}"
           data-title="{{ item.title | downcase | escape }}"
           data-tier="{{ item.tier | escape }}"
           data-form="{{ item.work_form | escape }}"
           data-evidence="{{ item.evidence_profile | escape }}"
           data-unit="{{ item.reading_unit | escape }}"
           data-era="{{ item.era | escape }}"
           data-region="{{ item.region_or_tradition | escape }}"
           data-context="{{ item.quizbowl_track_profile | escape }}"
           data-route="{{ item.routing_status | escape }}"
           data-question-count="{{ item.total_question_count }}"
           data-search="{{ search_text | strip_newlines | downcase | escape }}">
    <div class="canon-status-mark quizbowl-tier-mark" aria-hidden="true"></div>
    <div class="canon-item-body">
      <div class="canon-item-topline">
        <span class="canon-sequence-badge">#{{ item.rank }}</span>
        <span class="canon-era-badge">{{ tier_label }}</span>
        <span class="canon-date">{{ unit_label }}</span>
        <span class="canon-date">{{ item.total_question_count }} questions</span>
        <span class="canon-date">{{ item.distinct_set_count }} sets</span>
        {% if item.first_year and item.last_year %}
        <span class="canon-date">{{ item.first_year }}-{{ item.last_year }}</span>
        {% endif %}
      </div>
      <h2 class="canon-title">{{ item.title }}</h2>
      <div class="canon-meta">
        <span class="canon-chip canon-level-chip">{{ form_label }}</span>
        <span class="canon-chip">{{ evidence_label }}</span>
        {% if item.region_or_tradition != "unknown_region" %}
        <span class="canon-chip">{{ region_label }}</span>
        {% endif %}
        {% if item.era != "unknown_era" %}
        <span class="canon-chip">{{ era_label }}</span>
        {% endif %}
        <span class="canon-chip">{{ context_label }}</span>
        {% if item.routing_status != "accepted_clean" %}
        <span class="canon-chip quizbowl-routing-chip">{{ routing_label }}</span>
        {% endif %}
        <span class="canon-chip">{{ item.dominant_quizbowl_track | replace: "_", " " }}</span>
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
  var formFilter = document.getElementById('qb-form-filter');
  var evidenceFilter = document.getElementById('qb-evidence-filter');
  var unitFilter = document.getElementById('qb-unit-filter');
  var eraFilter = document.getElementById('qb-era-filter');
  var regionFilter = document.getElementById('qb-region-filter');
  var contextFilter = document.getElementById('qb-context-filter');
  var routeFilter = document.getElementById('qb-route-filter');
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
    var form = formFilter ? formFilter.value : '';
    var evidence = evidenceFilter ? evidenceFilter.value : '';
    var unit = unitFilter ? unitFilter.value : '';
    var era = eraFilter ? eraFilter.value : '';
    var region = regionFilter ? regionFilter.value : '';
    var context = contextFilter ? contextFilter.value : '';
    var route = routeFilter ? routeFilter.value : '';
    var search = searchInput ? searchInput.value.toLowerCase().trim() : '';

    if (tier && row.getAttribute('data-tier') !== tier) return false;
    if (form && row.getAttribute('data-form') !== form) return false;
    if (evidence && row.getAttribute('data-evidence') !== evidence) return false;
    if (unit && row.getAttribute('data-unit') !== unit) return false;
    if (era && row.getAttribute('data-era') !== era) return false;
    if (region && row.getAttribute('data-region') !== region) return false;
    if (context && row.getAttribute('data-context') !== context) return false;
    if (route && row.getAttribute('data-route') !== route) return false;
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

  [tierFilter, formFilter, evidenceFilter, unitFilter, eraFilter, regionFilter, contextFilter, routeFilter, sortSelect].forEach(function (filter) {
    if (filter) filter.addEventListener('change', render);
  });
  if (searchInput) searchInput.addEventListener('input', render);

  render();
})();
</script>
