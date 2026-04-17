---
layout: page
title: TV Log
---

<p class="page-intro">Shows I have been watching and what I thought.</p>

{% assign sorted_tv = site.data.tv | sort: "date_watched" | reverse %}
{% assign fav_tv = sorted_tv | where: "favorite", true | sort: "rating" | reverse %}

{% if sorted_tv.size > 0 %}
<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="false">Favorites</button>
    <button class="shelf-toggle-btn" data-mode="recents" aria-pressed="true">Recents</button>
  </div>

  <div class="shelf-section" id="shelf-favorites">
    {% if fav_tv.size > 0 %}
    <div class="shelf-row">
      {% for item in fav_tv limit:12 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 41 | modulo: 360 }}; --spine-width: {{ item.rating | times: 6 | plus: 22 }}px;">
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
      {% for item in sorted_tv limit:12 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 41 | modulo: 360 }}; --spine-width: {{ item.rating | times: 6 | plus: 22 }}px;">
        <span class="spine-title">{{ item.title }}</span>
      </span>
      {% endfor %}
    </div>
    <div class="shelf-board"></div>
  </div>
</div>

<div class="diary-filters">
  <select id="genre-filter" aria-label="Filter by genre">
    <option value="">All Genres</option>
  </select>
  <select id="status-filter" aria-label="Filter by status">
    <option value="">All Statuses</option>
  </select>
  <select id="rating-filter" aria-label="Filter by rating">
    <option value="">All Ratings</option>
    <option value="5">&#9733;&#9733;&#9733;&#9733;&#9733;</option>
    <option value="4.5">&#9733;&#9733;&#9733;&#9733;&#9734;&frac12;</option>
    <option value="4">&#9733;&#9733;&#9733;&#9733;</option>
    <option value="3.5">&#9733;&#9733;&#9733;&frac12;</option>
    <option value="3">&#9733;&#9733;&#9733;</option>
    <option value="2.5">&#9733;&#9733;&frac12;</option>
    <option value="2">&#9733;&#9733;</option>
    <option value="1.5">&#9733;&frac12;</option>
    <option value="1">&#9733;</option>
  </select>
  <input type="text" id="search-filter" placeholder="Search titles..." aria-label="Search shows">
</div>

<div class="diary-table" id="tv-diary">
  {% assign current_month = "" %}
  {% for item in sorted_tv %}
    {% assign item_month = item.date_watched | date: "%B %Y" %}
    {% if item_month != current_month %}
      {% assign current_month = item_month %}
  <div class="diary-month-header" data-month="{{ item_month }}">{{ item_month }}</div>
    {% endif %}
  <div class="diary-row"
       data-title="{{ item.title | downcase }}"
       data-genre="{{ item.genre }}"
       data-status="{{ item.status }}"
       data-rating="{{ item.rating }}"
       data-month="{{ item_month }}">
    <span class="diary-date">{{ item.date_watched | date: "%b %-d" }}</span>
    <span class="diary-title">{{ item.title }} <span class="diary-meta">({{ item.season }})</span></span>
    <span class="diary-meta">{{ item.genre }}</span>
    <span class="diary-meta">{{ item.status }}</span>
    <span class="diary-rating">
      {% assign full_stars = item.rating | floor %}
      {% assign has_half = item.rating | modulo: 1 %}
      {% assign half_pos = full_stars | plus: 1 %}
      {% for i in (1..5) %}{% if i <= full_stars %}<span class="star-full">&#9733;</span>{% elsif has_half != 0 and i == half_pos %}<span class="star-half">&#9733;</span>{% else %}<span class="star-empty">&#9734;</span>{% endif %}{% endfor %}
    </span>
    {% if item.review %}
    <div class="diary-review">{{ item.review }}</div>
    {% endif %}
  </div>
  {% endfor %}
</div>

<button class="diary-show-more" id="show-more-btn" style="display:none;">Show More</button>

<script>
(function() {
  var PAGE_SIZE = 20;
  var shown = PAGE_SIZE;

  var rows = Array.prototype.slice.call(document.querySelectorAll('#tv-diary .diary-row'));
  var monthHeaders = Array.prototype.slice.call(document.querySelectorAll('#tv-diary .diary-month-header'));
  var genreFilter = document.getElementById('genre-filter');
  var statusFilter = document.getElementById('status-filter');
  var ratingFilter = document.getElementById('rating-filter');
  var searchFilter = document.getElementById('search-filter');
  var showMoreBtn = document.getElementById('show-more-btn');

  // Build genre dropdown from data
  var genres = {};
  rows.forEach(function(row) {
    var g = row.getAttribute('data-genre');
    if (g) genres[g] = true;
  });
  Object.keys(genres).sort().forEach(function(g) {
    var opt = document.createElement('option');
    opt.value = g;
    opt.textContent = g;
    genreFilter.appendChild(opt);
  });

  // Build status dropdown from data
  var statuses = {};
  rows.forEach(function(row) {
    var s = row.getAttribute('data-status');
    if (s) statuses[s] = true;
  });
  Object.keys(statuses).sort().forEach(function(s) {
    var opt = document.createElement('option');
    opt.value = s;
    opt.textContent = s;
    statusFilter.appendChild(opt);
  });

  // Click to expand/collapse review
  rows.forEach(function(row) {
    row.addEventListener('click', function() {
      row.classList.toggle('expanded');
    });
  });

  function getFiltered() {
    var genre = genreFilter.value;
    var status = statusFilter.value;
    var rating = ratingFilter.value;
    var search = searchFilter.value.toLowerCase().trim();

    return rows.filter(function(row) {
      if (genre && row.getAttribute('data-genre') !== genre) return false;
      if (status && row.getAttribute('data-status') !== status) return false;
      if (rating && row.getAttribute('data-rating') !== rating) return false;
      if (search) {
        var title = row.getAttribute('data-title') || '';
        if (title.indexOf(search) === -1) return false;
      }
      return true;
    });
  }

  function render() {
    var filtered = getFiltered();
    var visibleMonths = {};

    rows.forEach(function(row) { row.style.display = 'none'; });

    filtered.forEach(function(row, i) {
      if (i < shown) {
        row.style.display = '';
        visibleMonths[row.getAttribute('data-month')] = true;
      }
    });

    // Show/hide month headers based on visible rows
    monthHeaders.forEach(function(hdr) {
      hdr.style.display = visibleMonths[hdr.getAttribute('data-month')] ? '' : 'none';
    });

    showMoreBtn.style.display = filtered.length > shown ? '' : 'none';
  }

  genreFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  statusFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  ratingFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  searchFilter.addEventListener('input', function() { shown = PAGE_SIZE; render(); });

  showMoreBtn.addEventListener('click', function() {
    shown += PAGE_SIZE;
    render();
  });

  render();
})();
</script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'tv' });</script>
{% endif %}
