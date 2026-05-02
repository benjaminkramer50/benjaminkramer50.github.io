---
layout: page
title: Global Literature Canon
description: A global literature progress tracker.
permalink: /canon/
wide: true
---

{% assign quick_path = site.data.canon_quick_path %}
{% assign canon_progress_data = site.data.canon_progress.items %}
<p class="page-intro">My chronological reading path through 3,000 major works of world literature, from ancient ritual texts and epics to modern novels, poetry, drama, oral traditions, and scripture read as literature.</p>

{% assign canon_lifetime = quick_path.items | where_exp: "item", "item.lifetime_path == true" %}
{% assign canon_items = canon_lifetime %}
{% assign canon_completed = canon_lifetime | where_exp: "item", "item.progress_status == 'completed'" %}
{% assign canon_progress = canon_lifetime | where_exp: "item", "item.progress_status == 'in_progress'" %}
{% assign canon_planned = canon_lifetime | where_exp: "item", "item.progress_status == 'planned'" %}
{% assign canon_not_started_count = canon_planned.size %}

<p class="canon-status-note">This page shows my saved progress through the list.</p>

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
  <select id="canon-progress-filter" aria-label="Filter by personal progress">
    <option value="">All Works</option>
    <option value="planned">Not Started</option>
    <option value="in_progress">In Progress</option>
    <option value="completed">Completed</option>
    <option value="sampled">Sampled</option>
    <option value="deferred">Deferred</option>
  </select>
  <input id="canon-search" type="search" placeholder="Search title, author, tradition..." aria-label="Search literature canon">
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
  {% capture search_text %}{{ display_title }} {{ alias_names }} {{ creator_names }} {{ section }} {{ item.group }} {{ item.topic }} {{ item.medium }} {{ item.unit_type }}{% endcapture %}
  <article class="canon-item canon-progress-{{ progress_status | replace: '_', '-' }}"
           {% unless item.lifetime_path %}hidden{% endunless %}
           data-canon-id="{{ item.id | escape }}"
           data-title="{{ display_title | downcase | escape }}"
           data-creator="{{ creator_names | downcase | escape }}"
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
        {% if item.date_label %}<span class="canon-date">{{ item.date_label }}</span>{% endif %}
      </div>
      <h2 class="canon-title">{% if item.url %}<a href="{{ item.url }}">{{ display_title }}</a>{% else %}{{ display_title }}{% endif %}</h2>
      {% if creator_names != "" %}<div class="canon-creator">{{ creator_names }}</div>{% endif %}
      <div class="canon-meta">
        {% if item.topic %}<span>{{ item.topic | replace: "_", " " | replace: "-", " " }}</span>{% endif %}
        {% if item.tier == "core" %}<span>Core Work</span>{% elsif item.tier == "major" %}<span>Major Work</span>{% elsif item.tier %}<span>{{ item.tier | replace: "_", " " }}</span>{% endif %}
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
    var search = searchInput ? searchInput.value.toLowerCase().trim() : '';

    if (row.getAttribute('data-lifetime-path') !== 'true') return false;
    if (progress && row.getAttribute('data-progress-status') !== progress) return false;
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

  if (progressFilter) progressFilter.addEventListener('change', render);
  if (searchInput) searchInput.addEventListener('input', render);

  render();
})();
</script>
