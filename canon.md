---
layout: page
title: Global Literature Canon
description: A global literature progress tracker.
permalink: /canon/
wide: true
---

{% assign quick_path = site.data.canon_quick_path %}
{% assign canon_progress_data = site.data.canon_progress.items %}
<p class="page-intro">A working reading tracker for a broad global literature path: ancient ritual texts and epics, classical drama and poetry, modern novels, oral traditions, speculative work, testimony, scripture read as literature, and contemporary writing.</p>

{% assign canon_lifetime = quick_path.items | where_exp: "item", "item.lifetime_path == true" %}
{% assign canon_items = canon_lifetime %}
{% assign canon_completed = canon_lifetime | where_exp: "item", "item.progress_status == 'completed'" %}
{% assign canon_progress = canon_lifetime | where_exp: "item", "item.progress_status == 'in_progress'" %}
{% assign canon_planned = canon_lifetime | where_exp: "item", "item.progress_status == 'planned'" %}
{% assign canon_not_started_count = canon_planned.size %}

<p class="canon-status-note">This is a provisional path, not a final claim of completeness. I am using it to track progress while continuing to audit omissions, chronology, duplicates, and over- or under-represented traditions. I am also building a separate <a href="/quizbowl-canon/">quizbowl-derived canon</a> from raw quizbowl answerlines and clue text.</p>

<div class="canon-summary" aria-label="Canon progress summary">
  <div class="canon-stat">
    <span class="canon-stat-number" id="canon-total-stat">{{ canon_lifetime.size }}</span>
    <span class="canon-stat-label">Works</span>
  </div>
  <div class="canon-stat canon-stat-completed">
    <span class="canon-stat-number" id="canon-completed-stat">{{ canon_completed.size }}</span>
    <span class="canon-stat-label">Completed</span>
  </div>
  <div class="canon-stat canon-stat-progress">
    <span class="canon-stat-number" id="canon-progress-stat">{{ canon_progress.size }}</span>
    <span class="canon-stat-label">In Progress</span>
  </div>
  <div class="canon-stat canon-stat-planned">
    <span class="canon-stat-number" id="canon-planned-stat">{{ canon_not_started_count }}</span>
    <span class="canon-stat-label">Not Started</span>
  </div>
</div>

<div class="canon-filters" aria-label="Canon filters">
  <label class="canon-filter-field" for="canon-progress-filter">
    <span>Progress</span>
    <select id="canon-progress-filter" aria-label="Filter by personal progress">
      <option value="">Any Progress</option>
      <option value="planned">Not Started</option>
      <option value="in_progress">In Progress</option>
      <option value="completed">Completed</option>
      <option value="sampled">Sampled</option>
      <option value="deferred">Deferred</option>
    </select>
  </label>
  <label class="canon-filter-field" for="canon-era-filter">
    <span>Period</span>
    <select id="canon-era-filter" aria-label="Filter by period">
      <option value="">Any Period</option>
      <option value="Ancient Foundations">Ancient Foundations</option>
      <option value="Classical &amp; Late Antique">Classical &amp; Late Antique</option>
      <option value="Medieval Worlds">Medieval Worlds</option>
      <option value="Early Modern">Early Modern</option>
      <option value="Nineteenth Century">Nineteenth Century</option>
      <option value="Modernism &amp; World Wars">Modernism &amp; World Wars</option>
      <option value="Postwar &amp; Decolonization">Postwar &amp; Decolonization</option>
      <option value="Contemporary">Contemporary</option>
    </select>
  </label>
  <label class="canon-filter-field" for="canon-region-filter">
    <span>Tradition</span>
    <select id="canon-region-filter" aria-label="Filter by tradition or region">
      <option value="">Any Tradition</option>
      <option value="Africa">Africa</option>
      <option value="Americas">Americas</option>
      <option value="East Asia">East Asia</option>
      <option value="Europe">Europe</option>
      <option value="Middle East &amp; Central Asia">Middle East &amp; Central Asia</option>
      <option value="Oceania &amp; Arctic">Oceania &amp; Arctic</option>
      <option value="South Asia">South Asia</option>
      <option value="Southeast Asia">Southeast Asia</option>
      <option value="Genre / Cross-Regional">Genre / Cross-Regional</option>
    </select>
  </label>
  <label class="canon-filter-field" for="canon-form-filter">
    <span>Form</span>
    <select id="canon-form-filter" aria-label="Filter by form">
      <option value="">Any Form</option>
      <option value="Fiction &amp; Narrative Prose">Fiction &amp; Narrative Prose</option>
      <option value="Poetry">Poetry</option>
      <option value="Drama &amp; Performance">Drama &amp; Performance</option>
      <option value="Epic, Oral &amp; Folk">Epic, Oral &amp; Folk</option>
      <option value="Sacred, Myth &amp; Ritual">Sacred, Myth &amp; Ritual</option>
      <option value="Essays, Memoir &amp; Testimony">Essays, Memoir &amp; Testimony</option>
      <option value="Graphic &amp; Visual Narrative">Graphic &amp; Visual Narrative</option>
      <option value="Children's &amp; Young Adult">Children's &amp; Young Adult</option>
      <option value="Speculative &amp; Genre">Speculative &amp; Genre</option>
    </select>
  </label>
  <label class="canon-filter-field canon-search-field" for="canon-search">
    <span>Search</span>
    <input id="canon-search" type="search" placeholder="Title, author, tradition..." aria-label="Search literature canon">
  </label>
</div>

<div class="canon-visible-count" id="canon-visible-count"></div>

{% if canon_items.size == 0 %}
<div class="canon-empty-state">
  <strong>No canon records yet.</strong>
  <p>The canon list has not been published yet. Once it is set, this page will show the full progress tracker.</p>
</div>
{% endif %}

<div class="canon-list" id="canon-list">
  {% for item in canon_items %}
  {% assign progress_status = item.progress_status | default: "planned" %}
  {% assign section = item.section | default: "unsectioned" %}
  {% assign primary_domain = item.group | default: "" %}
  {% assign display_title = item.title %}
  {% assign creator_names = item.creators | join: ", " %}
  {% if item.aliases %}{% assign alias_names = item.aliases | join: " " %}{% else %}{% assign alias_names = "" %}{% endif %}
  {% capture subject_text_raw %}{{ creator_names }} {{ section }} {{ item.group }} {{ item.topic }} {{ item.medium }} {{ item.unit_type }}{% endcapture %}
  {% assign subject_text = subject_text_raw | downcase | replace: "_", " " | replace: "-", " " %}
  {% assign title_text = display_title | downcase | replace: "_", " " | replace: "-", " " %}
  {% assign sort_year = item.sort_year | default: 999999 | plus: 0 %}
  {% if sort_year < -500 %}
    {% assign era_label = "Ancient Foundations" %}
  {% elsif sort_year < 500 %}
    {% assign era_label = "Classical & Late Antique" %}
  {% elsif sort_year < 1500 %}
    {% assign era_label = "Medieval Worlds" %}
  {% elsif sort_year < 1800 %}
    {% assign era_label = "Early Modern" %}
  {% elsif sort_year < 1900 %}
    {% assign era_label = "Nineteenth Century" %}
  {% elsif sort_year < 1946 %}
    {% assign era_label = "Modernism & World Wars" %}
  {% elsif sort_year < 1990 %}
    {% assign era_label = "Postwar & Decolonization" %}
  {% else %}
    {% assign era_label = "Contemporary" %}
  {% endif %}

  {% assign region_label = "Genre / Cross-Regional" %}
  {% if subject_text contains "aboriginal" or subject_text contains "maori" or subject_text contains "pacific" or subject_text contains "oceanian" or subject_text contains "polynesian" or subject_text contains "arctic" or subject_text contains "inuit" or subject_text contains "hawaiian" %}
    {% assign region_label = "Oceania & Arctic" %}
  {% elsif subject_text contains "american" or subject_text contains "canadian" or subject_text contains "caribbean" or subject_text contains "brazilian" or subject_text contains "maya" or subject_text contains "kiche" or subject_text contains "quechua" or subject_text contains "nahuatl" or subject_text contains "mapuche" or subject_text contains "zapotec" or subject_text contains "kichwa" or subject_text contains "mephaa" or subject_text contains "black atlantic" or subject_text contains "native" or subject_text contains "indigenous" %}
    {% assign region_label = "Americas" %}
  {% elsif subject_text contains "african" or subject_text contains "swahili" or subject_text contains "yoruba" or subject_text contains "somali" or subject_text contains "amharic" or subject_text contains "zulu" or subject_text contains "ghanaian" or subject_text contains "kenyan" or subject_text contains "horn of africa" or subject_text contains "amazigh" %}
    {% assign region_label = "Africa" %}
  {% elsif subject_text contains "chinese" or subject_text contains "japanese" or subject_text contains "korean" or subject_text contains "taiwanese" or subject_text contains "mongolian" or subject_text contains "tibetan" %}
    {% assign region_label = "East Asia" %}
  {% elsif subject_text contains "sanskrit" or subject_text contains "pali" or subject_text contains "prakrit" or subject_text contains "tamil" or subject_text contains "telugu" or subject_text contains "malayalam" or subject_text contains "bengali" or subject_text contains "hindi" or subject_text contains "urdu" or subject_text contains "punjabi" or subject_text contains "marathi" or subject_text contains "kannada" or subject_text contains "odia" or subject_text contains "nepali" or subject_text contains "sinhala" or subject_text contains "south asian" or subject_text contains "indian" or subject_text contains "jain" or subject_text contains "sikh" %}
    {% assign region_label = "South Asia" %}
  {% elsif subject_text contains "thai" or subject_text contains "vietnamese" or subject_text contains "khmer" or subject_text contains "burmese" or subject_text contains "malay" or subject_text contains "indonesian" or subject_text contains "filipino" or subject_text contains "southeast asian" or subject_text contains "lao" %}
    {% assign region_label = "Southeast Asia" %}
  {% elsif subject_text contains "arabic" or subject_text contains "persian" or subject_text contains "turkic" or subject_text contains "turkish" or subject_text contains "kurdish" or subject_text contains "hebrew" or subject_text contains "syriac" or subject_text contains "armenian" or subject_text contains "georgian" or subject_text contains "central asian" or subject_text contains "egyptian" or subject_text contains "mesopotamian" or subject_text contains "sumerian" or subject_text contains "akkadian" or subject_text contains "ugaritic" or subject_text contains "hittite" or subject_text contains "zoroastrian" or subject_text contains "ancient near east" or subject_text contains "islamic" or subject_text contains "hadith" %}
    {% assign region_label = "Middle East & Central Asia" %}
  {% elsif subject_text contains "greek" or subject_text contains "roman" or subject_text contains "latin" or subject_text contains "italian" or subject_text contains "french" or subject_text contains "francophone" or subject_text contains "spanish" or subject_text contains "portuguese" or subject_text contains "german" or subject_text contains "austrian" or subject_text contains "british" or subject_text contains "english" or subject_text contains "irish" or subject_text contains "scottish" or subject_text contains "welsh" or subject_text contains "dutch" or subject_text contains "scandinavian" or subject_text contains "norwegian" or subject_text contains "swedish" or subject_text contains "danish" or subject_text contains "icelandic" or subject_text contains "russian" or subject_text contains "polish" or subject_text contains "czech" or subject_text contains "hungarian" or subject_text contains "romanian" or subject_text contains "balkan" or subject_text contains "baltic" or subject_text contains "bulgarian" or subject_text contains "slovenian" or subject_text contains "albanian" or subject_text contains "europe" %}
    {% assign region_label = "Europe" %}
  {% endif %}

  {% assign form_label = "Fiction & Narrative Prose" %}
  {% if subject_text contains "children" or subject_text contains "young adult" %}
    {% assign form_label = "Children's & Young Adult" %}
  {% elsif subject_text contains "graphic" or subject_text contains "comic" %}
    {% assign form_label = "Graphic & Visual Narrative" %}
  {% elsif subject_text contains "science fiction" or subject_text contains "fantasy" or subject_text contains "horror" or subject_text contains "weird" or subject_text contains "crime" or subject_text contains "gothic" or subject_text contains "adventure" or subject_text contains "surrealist" %}
    {% assign form_label = "Speculative & Genre" %}
  {% elsif subject_text contains "play" or subject_text contains "drama" or subject_text contains "theater" or subject_text contains "tragedy" or subject_text contains "comedy" or subject_text contains "noh" or subject_text contains "bunraku" or subject_text contains "performance" %}
    {% assign form_label = "Drama & Performance" %}
  {% elsif subject_text contains "scripture" or subject_text contains "religion" or subject_text contains "religious" or subject_text contains "myth" or subject_text contains "ritual" or subject_text contains "funerary" or subject_text contains "liturgical" or subject_text contains "sutra" or subject_text contains "bible" or subject_text contains "qur" or subject_text contains "hadith" or subject_text contains "buddhist" or subject_text contains "hindu" or subject_text contains "jain" or subject_text contains "sikh" or subject_text contains "zoroastrian" %}
    {% assign form_label = "Sacred, Myth & Ritual" %}
  {% elsif subject_text contains "epic" or subject_text contains "oral" or subject_text contains "saga" or subject_text contains "legend" or subject_text contains "folklore" or subject_text contains "fable" or subject_text contains "fairy tale" or subject_text contains "ballad" or subject_text contains "trickster" or title_text contains "epic of" %}
    {% assign form_label = "Epic, Oral & Folk" %}
  {% elsif subject_text contains "poem" or subject_text contains "poetry" or subject_text contains "poetic" or subject_text contains "lyric" or subject_text contains "hymn" or subject_text contains "ghazal" or subject_text contains "haiku" or subject_text contains "song" or subject_text contains "verse" %}
    {% assign form_label = "Poetry" %}
  {% elsif subject_text contains "memoir" or subject_text contains "autobiography" or subject_text contains "testimonio" or subject_text contains "essay" or subject_text contains "confession" or subject_text contains "diary" or subject_text contains "travel" or subject_text contains "chronicle" or subject_text contains "history" or subject_text contains "dialogue" or subject_text contains "wisdom" or subject_text contains "letter" or subject_text contains "philosophy" %}
    {% assign form_label = "Essays, Memoir & Testimony" %}
  {% endif %}

  {% if item.tier == "core" %}
    {% assign canon_level = "Essential" %}
  {% elsif item.tier == "major" %}
    {% assign canon_level = "Major" %}
  {% elsif item.tier == "contextual" %}
    {% assign canon_level = "Context" %}
  {% else %}
    {% assign canon_level = item.tier | default: "Review" | replace: "_", " " | replace: "-", " " | capitalize %}
  {% endif %}

  {% capture search_text %}{{ display_title }} {{ alias_names }} {{ creator_names }} {{ section }} {{ item.group }} {{ item.topic }} {{ item.medium }} {{ item.unit_type }} {{ era_label }} {{ region_label }} {{ form_label }} {{ canon_level }}{% endcapture %}
  <article class="canon-item canon-progress-{{ progress_status | replace: '_', '-' }}"
           {% unless item.lifetime_path %}hidden{% endunless %}
           data-canon-id="{{ item.id | escape }}"
           data-title="{{ display_title | downcase | escape }}"
           data-creator="{{ creator_names | downcase | escape }}"
           data-era="{{ era_label | escape }}"
           data-region="{{ region_label | escape }}"
           data-form="{{ form_label | escape }}"
           data-canon-level="{{ canon_level | escape }}"
           data-section="{{ section | escape }}"
           data-primary-domain="{{ primary_domain | escape }}"
           data-medium="{{ item.medium | escape }}"
           data-canon-tier="{{ item.tier | escape }}"
           data-progress-status="{{ progress_status | escape }}"
           data-base-progress-status="{{ progress_status | escape }}"
           data-lifetime-path="{% if item.lifetime_path %}true{% else %}false{% endif %}"
           data-lifetime-phase="{{ item.phase | default: 9999 }}"
           data-lifetime-rank="{{ item.rank | default: 999999 }}"
           data-sort-year="{{ item.sort_year | default: 999999 }}"
           data-subjects="{{ item.group }} {{ item.topic }} {{ item.medium }} {{ item.unit_type }}"
           data-search="{{ search_text | strip_newlines | downcase | escape }}">
    <div class="canon-status-mark" aria-hidden="true"></div>
    <div class="canon-item-body">
      <div class="canon-item-topline">
        {% if item.lifetime_path and item.phase and item.rank %}
        <span class="canon-sequence-badge">#{{ item.rank }}</span>
        {% endif %}
        <span class="canon-era-badge">{{ era_label }}</span>
        {% if item.date_label %}<span class="canon-date">{{ item.date_label }}</span>{% endif %}
      </div>
      <h2 class="canon-title">{% if item.url %}<a href="{{ item.url }}">{{ display_title }}</a>{% else %}{{ display_title }}{% endif %}</h2>
      {% if creator_names != "" %}<div class="canon-creator">{{ creator_names }}</div>{% endif %}
      <div class="canon-meta">
        <span class="canon-chip">{{ region_label }}</span>
        <span class="canon-chip">{{ form_label }}</span>
        <span class="canon-chip canon-level-chip">{{ canon_level }}</span>
      </div>
    </div>
    <div class="canon-item-actions">
      <span class="canon-status-label">{% if progress_status == "planned" %}Not Started{% else %}{{ progress_status | replace: "_", " " }}{% endif %}</span>
    </div>
  </article>
  {% endfor %}
</div>

<div id="canon-no-results" class="diary-no-results" style="display:none;">No canon texts match your filters.</div>

<script>
(function () {
  var rows = Array.prototype.slice.call(document.querySelectorAll('.canon-item'));
  var progressStatuses = ['planned', 'queued', 'in_progress', 'completed', 'sampled', 'paused', 'deferred', 'abandoned'];
  var progressData = {{ canon_progress_data | jsonify }} || {};
  var progressFilter = document.getElementById('canon-progress-filter');
  var eraFilter = document.getElementById('canon-era-filter');
  var regionFilter = document.getElementById('canon-region-filter');
  var formFilter = document.getElementById('canon-form-filter');
  var searchInput = document.getElementById('canon-search');
  var visibleCount = document.getElementById('canon-visible-count');
  var noResults = document.getElementById('canon-no-results');
  var list = document.getElementById('canon-list');
  var completedStat = document.getElementById('canon-completed-stat');
  var progressStat = document.getElementById('canon-progress-stat');
  var plannedStat = document.getElementById('canon-planned-stat');

  function titleCase(value) {
    return value.replace(/[_-]/g, ' ').replace(/\b\w/g, function (letter) {
      return letter.toUpperCase();
    });
  }

  function numberAttr(row, attr, fallback) {
    var value = parseInt(row.getAttribute(attr), 10);
    return isNaN(value) ? fallback : value;
  }

  function compareText(a, b, attr) {
    return (a.getAttribute(attr) || '').localeCompare(b.getAttribute(attr) || '');
  }

  function compareRows(a, b) {
    var rankDiff = numberAttr(a, 'data-lifetime-rank', 999999) - numberAttr(b, 'data-lifetime-rank', 999999);
    if (rankDiff !== 0) return rankDiff;
    var yearDiff = numberAttr(a, 'data-sort-year', 999999) - numberAttr(b, 'data-sort-year', 999999);
    if (yearDiff !== 0) return yearDiff;
    return compareText(a, b, 'data-title');
  }

  function matches(row) {
    var progress = progressFilter ? progressFilter.value : '';
    var era = eraFilter ? eraFilter.value : '';
    var region = regionFilter ? regionFilter.value : '';
    var form = formFilter ? formFilter.value : '';
    var search = searchInput ? searchInput.value.toLowerCase().trim() : '';

    if (row.getAttribute('data-lifetime-path') !== 'true') return false;
    if (progress && row.getAttribute('data-progress-status') !== progress) return false;
    if (era && row.getAttribute('data-era') !== era) return false;
    if (region && row.getAttribute('data-region') !== region) return false;
    if (form && row.getAttribute('data-form') !== form) return false;
    if (search && (row.getAttribute('data-search') || '').indexOf(search) === -1) return false;
    return true;
  }

  function statusLabel(status) {
    if (status === 'planned') return 'Not Started';
    return titleCase(status || 'planned');
  }

  function setRowProgress(row, status) {
    var previous = row.getAttribute('data-progress-status') || 'planned';
    row.classList.remove('canon-progress-' + previous.replace(/_/g, '-'));
    progressStatuses.forEach(function (value) {
      row.classList.remove('canon-progress-' + value.replace(/_/g, '-'));
      row.classList.remove('canon-status-' + value.replace(/_/g, '-'));
    });
    row.setAttribute('data-progress-status', status);
    row.classList.add('canon-progress-' + status.replace(/_/g, '-'));
    var label = row.querySelector('.canon-status-label');
    if (label) label.textContent = statusLabel(status);
  }

  function updateSummary() {
    var counts = { planned: 0, in_progress: 0, completed: 0 };
    rows.forEach(function (row) {
      if (row.getAttribute('data-lifetime-path') !== 'true') return;
      var status = row.getAttribute('data-progress-status') || 'planned';
      if (status === 'completed') counts.completed++;
      else if (status === 'in_progress') counts.in_progress++;
      else if (status === 'planned') counts.planned++;
    });
    if (completedStat) completedStat.textContent = counts.completed;
    if (progressStat) progressStat.textContent = counts.in_progress;
    if (plannedStat) plannedStat.textContent = counts.planned;
  }

  function render() {
    var shown = 0;
    rows.sort(compareRows).forEach(function (row) {
      list.appendChild(row);
      var isVisible = matches(row);
      row.hidden = !isVisible;
      if (isVisible) shown++;
    });
    visibleCount.textContent = 'Showing ' + shown + ' of ' + rows.length + ' works';
    noResults.style.display = rows.length > 0 && shown === 0 ? '' : 'none';
    updateSummary();
  }

  rows.forEach(function (row) {
    var id = row.getAttribute('data-canon-id');
    var progressRecord = id && progressData ? progressData[id] : null;
    if (progressRecord && progressRecord.status) {
      setRowProgress(row, progressRecord.status);
    } else {
      setRowProgress(row, row.getAttribute('data-base-progress-status') || 'planned');
    }
  });

  [progressFilter, eraFilter, regionFilter, formFilter].forEach(function (filter) {
    if (filter) filter.addEventListener('change', render);
  });
  if (searchInput) searchInput.addEventListener('input', render);

  render();
})();
</script>
