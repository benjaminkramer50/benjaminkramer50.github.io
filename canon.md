---
layout: page
title: Global Literature Canon
description: A global literature progress tracker.
permalink: /canon/
wide: true
---

{% assign canon_scope = site.data.canon_scope %}
{% assign canon_path = site.data.canon_path %}
{% assign quick_path = site.data.canon_quick_path %}
<p class="page-intro">A progress tracker through the {{ quick_path.title | default: canon_scope.official_title }}. This is the usable checklist version: a Bloom-style literature canon widened beyond the West, with novels, epics, poems, plays, story cycles, oral-literary traditions, and major scripture or mythic texts treated as literature. Philosophy, law, history, art objects, music recordings, films, and textbooks are intentionally outside this default path.</p>

{% assign canon_lifetime = quick_path.items | where_exp: "item", "item.lifetime_path == true" %}
{% assign canon_items = canon_lifetime %}
{% assign canon_core = canon_lifetime | where_exp: "item", "item.tier == 'core'" %}
{% assign canon_reviewed = canon_lifetime | where_exp: "item", "item.source == 'accepted_record'" %}
{% assign canon_candidates = canon_lifetime | where_exp: "item", "item.source != 'accepted_record'" %}
{% assign canon_source_accepted = canon_lifetime | where_exp: "item", "item.source_status == 'accepted'" %}
{% assign canon_source_backed = canon_lifetime | where_exp: "item", "item.source_status == 'source_backed'" %}
{% assign canon_source_reviewed_count = canon_source_accepted.size | plus: canon_source_backed.size %}
{% assign canon_source_needs_review_count = canon_lifetime.size | minus: canon_source_reviewed_count %}
{% assign canon_completed = canon_lifetime | where_exp: "item", "item.progress_status == 'completed'" %}
{% assign canon_progress = canon_lifetime | where_exp: "item", "item.progress_status == 'in_progress'" %}
{% assign canon_planned = canon_lifetime | where_exp: "item", "item.progress_status == 'planned'" %}
{% assign canon_not_started_count = canon_planned.size %}
{% assign canon_target = quick_path.target_count | default: 3000 %}
{% assign canon_remaining = canon_target | minus: canon_lifetime.size %}

{% if canon_remaining > 0 %}
<p class="canon-status-note">Status: {{ canon_lifetime.size }} texts published toward the {{ canon_target }}-text lifetime path. The remaining {{ canon_remaining }} expansion slots are tracked in the planning backlog and should be source-reviewed before publication.</p>
{% else %}
<p class="canon-status-note">Status: {{ canon_lifetime.size }} texts published. This is a usable provisional path: {{ canon_source_reviewed_count }} entries are reviewed or source-backed, and {{ canon_source_needs_review_count }} still need source review before the list should be described as a locked academic canon.</p>
{% endif %}

<div class="canon-summary" aria-label="Canon progress summary">
  <div class="canon-stat">
    <span class="canon-stat-number" id="canon-total-stat">{{ canon_lifetime.size }}</span>
    <span class="canon-stat-label">Texts</span>
  </div>
  <div class="canon-stat canon-stat-lifetime">
    <span class="canon-stat-number">{{ canon_target }}</span>
    <span class="canon-stat-label">Target</span>
  </div>
  <div class="canon-stat canon-stat-completed">
    <span class="canon-stat-number" id="canon-completed-stat">{{ canon_completed.size }}</span>
    <span class="canon-stat-label">Completed</span>
  </div>
  <div class="canon-stat canon-stat-progress">
    <span class="canon-stat-number" id="canon-progress-stat">{{ canon_progress.size }}</span>
    <span class="canon-stat-label">In Progress</span>
  </div>
  <div class="canon-stat canon-stat-reviewed">
    <span class="canon-stat-number">{{ canon_source_reviewed_count }}</span>
    <span class="canon-stat-label">Reviewed</span>
  </div>
  <div class="canon-stat canon-stat-source-review">
    <span class="canon-stat-number">{{ canon_source_needs_review_count }}</span>
    <span class="canon-stat-label">Needs Source Review</span>
  </div>
  <div class="canon-stat canon-stat-planned">
    <span class="canon-stat-number" id="canon-planned-stat">{{ canon_not_started_count }}</span>
    <span class="canon-stat-label">Not Started</span>
  </div>
</div>

<div class="canon-filters" aria-label="Canon filters">
  <select id="canon-progress-filter" aria-label="Filter by personal progress">
    <option value="">All Progress</option>
    <option value="planned">Planned</option>
    <option value="in_progress">In Progress</option>
    <option value="completed">Completed</option>
    <option value="sampled">Sampled</option>
    <option value="deferred">Deferred</option>
  </select>
  <select id="canon-source-filter" aria-label="Filter by source review status">
    <option value="">All Source Status</option>
    <option value="reviewed">Reviewed / Source-Backed</option>
    <option value="needs_review">Needs Source Review</option>
  </select>
  <input id="canon-search" type="search" placeholder="Search title, author, tradition..." aria-label="Search canon">
</div>

<details class="canon-progress-actions" aria-label="Progress data controls">
  <summary>Progress Data</summary>
  <div class="canon-progress-action-row">
    <button type="button" id="canon-export-progress">Export</button>
    <label class="canon-import-label" for="canon-import-progress">Import</label>
    <input id="canon-import-progress" type="file" accept="application/json">
    <button type="button" id="canon-clear-progress">Clear</button>
  </div>
</details>

<div class="canon-visible-count" id="canon-visible-count"></div>

{% if canon_items.size == 0 %}
<div class="canon-empty-state">
  <strong>No canon records yet.</strong>
  <p>The canon list has not been published yet. Once it is set, this page will show the full progress tracker.</p>
</div>
{% endif %}

<div class="canon-list" id="canon-list">
  {% for item in canon_items %}
  {% assign review_status = item.review_status | default: "candidate" %}
  {% assign progress_status = item.progress_status | default: "planned" %}
  {% assign source_status = item.source_status | default: "manual_only" %}
  {% if source_status == "accepted" or source_status == "source_backed" %}
  {% assign source_bucket = "reviewed" %}
  {% assign source_label = source_status | replace: "_", " " %}
  {% else %}
  {% assign source_bucket = "needs_review" %}
  {% assign source_label = "needs source review" %}
  {% endif %}
  {% assign section = item.section | default: "unsectioned" %}
  {% assign primary_domain = item.group | default: "" %}
  {% assign display_title = item.title %}
  {% assign creator_names = item.creators | join: ", " %}
  {% capture search_text %}{{ display_title }} {{ creator_names }} {{ section }} {{ item.group }} {{ item.topic }} {{ item.medium }} {{ item.unit_type }} {{ item.rationale }}{% endcapture %}
  <article class="canon-item canon-progress-{{ progress_status | replace: '_', '-' }} canon-review-{{ review_status | replace: '_', '-' }}"
           {% unless item.lifetime_path %}hidden{% endunless %}
           data-canon-id="{{ item.id | escape }}"
           data-title="{{ display_title | downcase | escape }}"
           data-creator="{{ creator_names | downcase | escape }}"
           data-section="{{ section | escape }}"
           data-primary-domain="{{ primary_domain | escape }}"
           data-medium="{{ item.medium | escape }}"
           data-canon-tier="{{ item.tier | escape }}"
           data-source="{{ item.source | escape }}"
           data-source-status="{{ source_status | escape }}"
           data-source-review-bucket="{{ source_bucket }}"
           data-review-status="{{ review_status | escape }}"
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
        {% if item.date_label %}<span class="canon-date">{{ item.date_label }}</span>{% endif %}
      </div>
      <h2 class="canon-title">{% if item.url %}<a href="{{ item.url }}">{{ display_title }}</a>{% else %}{{ display_title }}{% endif %}</h2>
      {% if creator_names != "" %}<div class="canon-creator">{{ creator_names }}</div>{% endif %}
      <div class="canon-meta">
        {% if item.topic %}<span>{{ item.topic | replace: "_", " " | replace: "-", " " }}</span>{% endif %}
        {% if item.tier %}<span>{{ item.tier | replace: "_", " " }}</span>{% endif %}
        <span class="canon-source-chip canon-source-{{ source_bucket | replace: "_", "-" }}">{{ source_label }}</span>
      </div>
    </div>
    <div class="canon-item-actions">
      <span class="canon-status-label">{{ progress_status | replace: "_", " " }}</span>
      <select class="canon-progress-control" aria-label="Set progress for {{ display_title | escape }}">
        <option value="planned"{% if progress_status == "planned" %} selected{% endif %}>Planned</option>
        <option value="in_progress"{% if progress_status == "in_progress" %} selected{% endif %}>In Progress</option>
        <option value="completed"{% if progress_status == "completed" %} selected{% endif %}>Completed</option>
        <option value="sampled"{% if progress_status == "sampled" %} selected{% endif %}>Sampled</option>
        <option value="deferred"{% if progress_status == "deferred" %} selected{% endif %}>Deferred</option>
      </select>
    </div>
  </article>
  {% endfor %}
</div>

<div id="canon-no-results" class="diary-no-results" style="display:none;">No canon texts match your filters.</div>

<script>
(function () {
  var rows = Array.prototype.slice.call(document.querySelectorAll('.canon-item'));
  var layerButtons = Array.prototype.slice.call(document.querySelectorAll('[data-canon-layer]'));
  var modeButtons = Array.prototype.slice.call(document.querySelectorAll('[data-canon-mode]'));
  var phaseButtons = Array.prototype.slice.call(document.querySelectorAll('[data-canon-phase]'));
  var activeLayer = 'path';
  var activeMode = 'guided';
  var activePhase = '';
  var storageKey = 'humanitiesCanonProgress:v1';
  var progressStatuses = ['planned', 'queued', 'in_progress', 'completed', 'sampled', 'paused', 'deferred', 'abandoned'];
  var sectionFilter = document.getElementById('canon-section-filter');
  var subjectFilter = document.getElementById('canon-subject-filter');
  var mediumFilter = document.getElementById('canon-medium-filter');
  var progressFilter = document.getElementById('canon-progress-filter');
  var sourceStatusFilter = document.getElementById('canon-source-filter');
  var searchInput = document.getElementById('canon-search');
  var visibleCount = document.getElementById('canon-visible-count');
  var noResults = document.getElementById('canon-no-results');
  var list = document.getElementById('canon-list');
  var exportButton = document.getElementById('canon-export-progress');
  var importInput = document.getElementById('canon-import-progress');
  var clearButton = document.getElementById('canon-clear-progress');
  var completedStat = document.getElementById('canon-completed-stat');
  var progressStat = document.getElementById('canon-progress-stat');
  var plannedStat = document.getElementById('canon-planned-stat');
  var savedProgress = {};

  try {
    savedProgress = JSON.parse(localStorage.getItem(storageKey) || '{}') || {};
  } catch (error) {
    savedProgress = {};
  }

  function titleCase(value) {
    return value.replace(/[_-]/g, ' ').replace(/\b\w/g, function (letter) {
      return letter.toUpperCase();
    });
  }

  function addOptions(select, attr) {
    var values = {};
    rows.forEach(function (row) {
      var value = row.getAttribute(attr);
      if (value) values[value] = true;
    });
    Object.keys(values).sort().forEach(function (value) {
      var option = document.createElement('option');
      option.value = value;
      option.textContent = titleCase(value);
      select.appendChild(option);
    });
  }

  function addMultiOptions(select, attr) {
    var values = {};
    rows.forEach(function (row) {
      (row.getAttribute(attr) || '').split(/\s+/).forEach(function (value) {
        if (value) values[value] = true;
      });
    });
    Object.keys(values).sort().forEach(function (value) {
      var option = document.createElement('option');
      option.value = value;
      option.textContent = titleCase(value);
      select.appendChild(option);
    });
  }

  if (sectionFilter) addOptions(sectionFilter, 'data-section');
  if (subjectFilter) addMultiOptions(subjectFilter, 'data-subjects');
  if (mediumFilter) addOptions(mediumFilter, 'data-medium');

  function numberAttr(row, attr, fallback) {
    var value = parseInt(row.getAttribute(attr), 10);
    return isNaN(value) ? fallback : value;
  }

  function compareText(a, b, attr) {
    return (a.getAttribute(attr) || '').localeCompare(b.getAttribute(attr) || '');
  }

  function compareRows(a, b) {
    if (activeMode === 'chronological') {
      var yearDiff = numberAttr(a, 'data-sort-year', 999999) - numberAttr(b, 'data-sort-year', 999999);
      if (yearDiff !== 0) return yearDiff;
    }
    if (activeMode === 'domain') {
      var sectionDiff = compareText(a, b, 'data-section');
      if (sectionDiff !== 0) return sectionDiff;
      var domainDiff = compareText(a, b, 'data-primary-domain');
      if (domainDiff !== 0) return domainDiff;
    }
    if (activeMode === 'guided') {
      var phaseDiff = numberAttr(a, 'data-lifetime-phase', 9999) - numberAttr(b, 'data-lifetime-phase', 9999);
      if (phaseDiff !== 0) return phaseDiff;
      var rankDiff = numberAttr(a, 'data-lifetime-rank', 999999) - numberAttr(b, 'data-lifetime-rank', 999999);
      if (rankDiff !== 0) return rankDiff;
    }
    return compareText(a, b, 'data-title');
  }

  function matches(row) {
    var section = sectionFilter ? sectionFilter.value : '';
    var subject = subjectFilter ? subjectFilter.value : '';
    var medium = mediumFilter ? mediumFilter.value : '';
    var progress = progressFilter ? progressFilter.value : '';
    var sourceStatus = sourceStatusFilter ? sourceStatusFilter.value : '';
    var search = searchInput ? searchInput.value.toLowerCase().trim() : '';

    if (activeLayer === 'reference' && row.getAttribute('data-lifetime-path') === 'true') return false;
    if (activeLayer !== 'reference' && row.getAttribute('data-lifetime-path') !== 'true') return false;
    if (activeLayer === 'core' && row.getAttribute('data-canon-tier') !== 'core') return false;
    if (activeLayer === 'reviewed' && row.getAttribute('data-source') !== 'accepted_record') return false;
    if (activeLayer === 'candidate' && row.getAttribute('data-source') === 'accepted_record') return false;
    if (activeLayer !== 'reference' && activePhase && row.getAttribute('data-lifetime-phase') !== activePhase) return false;
    if (section && row.getAttribute('data-section') !== section) return false;
    if (subject && (row.getAttribute('data-subjects') || '').split(/\s+/).indexOf(subject) === -1) return false;
    if (medium && row.getAttribute('data-medium') !== medium) return false;
    if (progress && row.getAttribute('data-progress-status') !== progress) return false;
    if (sourceStatus && row.getAttribute('data-source-review-bucket') !== sourceStatus) return false;
    if (search && (row.getAttribute('data-search') || '').indexOf(search) === -1) return false;
    return true;
  }

  function statusLabel(status) {
    return titleCase(status || 'planned');
  }

  function saveProgress() {
    localStorage.setItem(storageKey, JSON.stringify(savedProgress));
  }

  function setRowProgress(row, status, persist) {
    var previous = row.getAttribute('data-progress-status') || 'planned';
    row.classList.remove('canon-progress-' + previous.replace(/_/g, '-'));
    progressStatuses.forEach(function (value) {
      row.classList.remove('canon-progress-' + value.replace(/_/g, '-'));
      row.classList.remove('canon-status-' + value.replace(/_/g, '-'));
    });
    row.setAttribute('data-progress-status', status);
    row.classList.add('canon-progress-' + status.replace(/_/g, '-'));
    var label = row.querySelector('.canon-status-label');
    var control = row.querySelector('.canon-progress-control');
    if (label) label.textContent = statusLabel(status);
    if (control && control.value !== status) control.value = status;
    if (persist) {
      var id = row.getAttribute('data-canon-id');
      if (id) savedProgress[id] = status;
      saveProgress();
    }
  }

  function updateSummary() {
    var counts = { planned: 0, in_progress: 0, completed: 0 };
    rows.forEach(function (row) {
      if (row.getAttribute('data-lifetime-path') !== 'true') return;
      var status = row.getAttribute('data-progress-status') || 'planned';
      if (status === 'completed') counts.completed++;
      else if (status === 'in_progress') counts.in_progress++;
      else counts.planned++;
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
    visibleCount.textContent = shown + ' of ' + rows.length + ' texts';
    noResults.style.display = rows.length > 0 && shown === 0 ? '' : 'none';
    updateSummary();
  }

  rows.forEach(function (row) {
    var id = row.getAttribute('data-canon-id');
    if (id && savedProgress[id]) {
      setRowProgress(row, savedProgress[id], false);
    }
    var control = row.querySelector('.canon-progress-control');
    if (control) {
      control.addEventListener('change', function () {
        setRowProgress(row, control.value, true);
        render();
      });
    }
  });

  layerButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      activeLayer = button.getAttribute('data-canon-layer') || 'path';
      layerButtons.forEach(function (option) {
        var isActive = option === button;
        option.classList.toggle('active', isActive);
        option.setAttribute('aria-pressed', isActive ? 'true' : 'false');
      });
      render();
    });
  });

  modeButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      activeMode = button.getAttribute('data-canon-mode') || 'guided';
      modeButtons.forEach(function (option) {
        var isActive = option === button;
        option.classList.toggle('active', isActive);
        option.setAttribute('aria-pressed', isActive ? 'true' : 'false');
      });
      render();
    });
  });

  phaseButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      activePhase = button.getAttribute('data-canon-phase') || '';
      phaseButtons.forEach(function (option) {
        option.classList.toggle('active', option === button);
      });
      render();
    });
  });

  [sectionFilter, subjectFilter, mediumFilter, progressFilter, sourceStatusFilter].forEach(function (select) {
    if (select) select.addEventListener('change', render);
  });
  if (searchInput) searchInput.addEventListener('input', render);

  if (exportButton) {
    exportButton.addEventListener('click', function () {
      var payload = JSON.stringify(savedProgress, null, 2);
      var blob = new Blob([payload], { type: 'application/json' });
      var link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = 'canon-progress.json';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(link.href);
    });
  }

  if (importInput) {
    importInput.addEventListener('change', function () {
      var file = importInput.files && importInput.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function () {
        try {
          savedProgress = JSON.parse(reader.result || '{}') || {};
          rows.forEach(function (row) {
            var id = row.getAttribute('data-canon-id');
            setRowProgress(row, savedProgress[id] || row.getAttribute('data-base-progress-status') || 'planned', false);
          });
          saveProgress();
          render();
        } catch (error) {
          window.alert('Could not import progress JSON.');
        }
      };
      reader.readAsText(file);
      importInput.value = '';
    });
  }

  if (clearButton) {
    clearButton.addEventListener('click', function () {
      if (!window.confirm('Clear local canon progress in this browser?')) return;
      savedProgress = {};
      localStorage.removeItem(storageKey);
      rows.forEach(function (row) {
        setRowProgress(row, row.getAttribute('data-base-progress-status') || 'planned', false);
      });
      render();
    });
  }

  render();
})();
</script>
