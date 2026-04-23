---
layout: page
title: Paper Log
---

<p class="page-intro">Scientific papers I have read and found worth noting.</p>

{% assign sorted_papers = site.data.papers | reverse | sort: "date_read" | reverse %}
{% assign fav_papers = sorted_papers | where: "favorite", true %}

{% if sorted_papers.size > 0 %}
<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="false">Favorites</button>
    <button class="shelf-toggle-btn" data-mode="recents" aria-pressed="true">Recents</button>
  </div>

  <div class="shelf-section" id="shelf-favorites">
    {% if fav_papers.size > 0 %}
    <div class="shelf-row">
      {% for item in fav_papers limit:12 %}
      {% assign spine_w = item.title | size | divided_by: 3 | plus: 24 | at_most: 48 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 31 | modulo: 360 }}; --spine-width: {{ spine_w }}px;">
        <span class="spine-title">{{ item.title }}</span>
      </span>
      {% endfor %}
    </div>
    <div class="shelf-board"></div>
    {% else %}
    <p class="shelf-empty">No favorites yet.</p>
    {% endif %}
  </div>

  <div class="shelf-section" id="shelf-recents">
    <div class="shelf-row">
      {% for item in sorted_papers limit:12 %}
      {% assign spine_w = item.title | size | divided_by: 3 | plus: 24 | at_most: 48 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 31 | modulo: 360 }}; --spine-width: {{ spine_w }}px;">
        <span class="spine-title">{{ item.title }}</span>
      </span>
      {% endfor %}
    </div>
    <div class="shelf-board"></div>
  </div>
</div>

<div class="diary-filters">
  <select id="filter-field" aria-label="Filter by field">
    <option value="">All Fields</option>
  </select>
  <select id="filter-year" aria-label="Filter by year published">
    <option value="">All Years</option>
  </select>
  <input type="text" id="filter-search" placeholder="Search title, authors, journal..." aria-label="Search papers">
</div>

<div class="diary-table" id="paper-diary">
  {% assign current_month = "" %}
  {% for item in sorted_papers %}
    {% assign item_month = item.date_read | date: "%B %Y" %}
    {% if item_month != current_month %}
      {% assign current_month = item_month %}
      <div class="diary-month-header" data-month="{{ item_month }}">{{ item_month }}</div>
    {% endif %}
    <div class="diary-row"
         data-title="{{ item.title | downcase }}"
         data-authors="{{ item.authors | downcase }}"
         data-journal="{{ item.journal | downcase }}"
         data-field="{{ item.field }}"
         data-year="{{ item.year }}"
         data-month="{{ item_month }}">
      <span class="diary-date">{{ item.date_read | date: "%b %-d" }}</span>
      <span class="diary-title">{{ item.title }}</span>
      <span class="diary-meta">{{ item.authors }}</span>
      <span class="diary-meta"><em>{{ item.journal }}</em> ({{ item.year }})</span>
      {% if item.notes %}
      <div class="diary-review">{{ item.notes }}</div>
      {% endif %}
    </div>
  {% endfor %}
</div>

<button class="diary-show-more" id="show-more-btn" style="display:none;">Show More</button>

<script>
(function() {
  var PAGE_SIZE = 20;
  var shown = PAGE_SIZE;

  var rows = Array.prototype.slice.call(document.querySelectorAll('#paper-diary .diary-row'));
  var monthHeaders = Array.prototype.slice.call(document.querySelectorAll('#paper-diary .diary-month-header'));
  var fieldFilter = document.getElementById('filter-field');
  var yearFilter = document.getElementById('filter-year');
  var searchFilter = document.getElementById('filter-search');
  var showMoreBtn = document.getElementById('show-more-btn');

  // Build field dropdown
  var fields = {};
  rows.forEach(function(r) { var f = r.getAttribute('data-field'); if (f) fields[f] = true; });
  Object.keys(fields).sort().forEach(function(f) {
    var opt = document.createElement('option'); opt.value = f; opt.textContent = f;
    fieldFilter.appendChild(opt);
  });

  // Build year dropdown
  var years = {};
  rows.forEach(function(r) { var y = r.getAttribute('data-year'); if (y) years[y] = true; });
  Object.keys(years).sort().reverse().forEach(function(y) {
    var opt = document.createElement('option'); opt.value = y; opt.textContent = y;
    yearFilter.appendChild(opt);
  });

  // Click to expand/collapse
  rows.forEach(function(row) {
    row.addEventListener('click', function() {
      var wasOpen = row.classList.contains('expanded');
      rows.forEach(function(r) { r.classList.remove('expanded'); });
      if (!wasOpen) row.classList.add('expanded');
    });
  });

  function getFiltered() {
    var field = fieldFilter.value;
    var year = yearFilter.value;
    var search = searchFilter.value.toLowerCase().trim();

    return rows.filter(function(r) {
      if (field && r.getAttribute('data-field') !== field) return false;
      if (year && r.getAttribute('data-year') !== year) return false;
      if (search) {
        var hay = r.getAttribute('data-title') + ' ' + r.getAttribute('data-authors') + ' ' + r.getAttribute('data-journal');
        if (hay.indexOf(search) === -1) return false;
      }
      return true;
    });
  }

  function render() {
    var filtered = getFiltered();
    var visibleMonths = {};

    rows.forEach(function(r) { r.style.display = 'none'; });
    filtered.forEach(function(r, i) {
      if (i < shown) { r.style.display = ''; visibleMonths[r.getAttribute('data-month')] = true; }
    });
    monthHeaders.forEach(function(h) {
      h.style.display = visibleMonths[h.getAttribute('data-month')] ? '' : 'none';
    });
    showMoreBtn.style.display = filtered.length > shown ? '' : 'none';
  }

  fieldFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  yearFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  searchFilter.addEventListener('input', function() { shown = PAGE_SIZE; render(); });
  showMoreBtn.addEventListener('click', function() { shown += PAGE_SIZE; render(); });

  render();
})();
</script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'papers' });</script>
{% endif %}
