---
layout: page
title: Movie Log
---

<p class="page-intro">Films I have watched and what I thought.</p>

{% assign sorted_movies = site.data.movies | sort: "date_watched" | reverse %}
{% assign fav_movies = sorted_movies | where: "favorite", true | sort: "rating" | reverse %}

{% if sorted_movies.size > 0 %}
<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="false">Favorites</button>
    <button class="shelf-toggle-btn" data-mode="recents" aria-pressed="true">Recents</button>
  </div>

  <div class="shelf-section" id="shelf-favorites">
    {% if fav_movies.size > 0 %}
    <div class="shelf-row">
      {% for item in fav_movies limit:12 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 53 | modulo: 360 }}; --spine-width: {{ item.rating | times: 6 | plus: 22 }}px;">
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
      {% for item in sorted_movies limit:12 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 53 | modulo: 360 }}; --spine-width: {{ item.rating | times: 6 | plus: 22 }}px;">
        <span class="spine-title">{{ item.title }}</span>
      </span>
      {% endfor %}
    </div>
    <div class="shelf-board"></div>
  </div>
</div>
{% endif %}

<!-- Filter bar -->
<div class="diary-filters">
  <select id="filter-year" aria-label="Filter by year">
    <option value="">All Years</option>
  </select>
  <select id="filter-genre" aria-label="Filter by genre">
    <option value="">All Genres</option>
  </select>
  <select id="filter-rating" aria-label="Filter by rating">
    <option value="">All Ratings</option>
  </select>
  <input type="text" id="filter-search" placeholder="Search titles..." aria-label="Search titles">
</div>

<!-- Diary table -->
<div class="diary-table" id="diary-table">
  {% assign current_month = "" %}
  {% for item in sorted_movies %}
    {% assign item_month = item.date_watched | date: "%B %Y" %}
    {% if item_month != current_month %}
      {% assign current_month = item_month %}
      <div class="diary-month-header" data-month="{{ item_month }}">{{ item_month }}</div>
    {% endif %}
    <div class="diary-row"
         id="movie-{{ forloop.index }}"
         data-title="{{ item.title }}"
         data-year="{{ item.year }}"
         data-genre="{{ item.genre }}"
         data-rating="{{ item.rating }}"
         data-date="{{ item.date_watched }}"
         data-month="{{ item.date_watched | date: '%B %Y' }}">
      <div class="diary-row-main">
        <span class="diary-date">{{ item.date_watched | date: "%b %d" }}</span>
        <span class="diary-title">{{ item.title }} <span class="diary-year">({{ item.year }})</span></span>
        <span class="diary-director">{{ item.director }}</span>
        <span class="diary-rating">
          {% assign full_stars = item.rating | floor %}
          {% assign has_half = item.rating | modulo: 1 %}
          {% assign half_pos = full_stars | plus: 1 %}
          {% for i in (1..5) %}{% if i <= full_stars %}<span class="star-full">&#9733;</span>{% elsif has_half != 0 and i == half_pos %}<span class="star-half">&#9733;</span>{% else %}<span class="star-empty">&#9734;</span>{% endif %}{% endfor %}
        </span>
      </div>
      {% if item.review %}
      <div class="diary-review">{{ item.review }}</div>
      {% endif %}
    </div>
  {% endfor %}
</div>

<div id="diary-no-results" class="diary-no-results" style="display:none;">No movies match your filters.</div>

<button class="diary-show-more" id="diary-show-more" style="display:none;">Show more</button>

<script>
(function() {
  var PAGE_SIZE = 20;
  var visibleCount = PAGE_SIZE;

  var rows = Array.prototype.slice.call(document.querySelectorAll('.diary-row'));
  var monthHeaders = Array.prototype.slice.call(document.querySelectorAll('.diary-month-header'));
  var showMoreBtn = document.getElementById('diary-show-more');
  var noResults = document.getElementById('diary-no-results');

  var filterYear = document.getElementById('filter-year');
  var filterGenre = document.getElementById('filter-genre');
  var filterRating = document.getElementById('filter-rating');
  var filterSearch = document.getElementById('filter-search');

  // Populate dropdown options from data
  var years = [], genres = [], ratings = [];
  rows.forEach(function(row) {
    var y = row.getAttribute('data-year');
    var g = row.getAttribute('data-genre');
    var r = row.getAttribute('data-rating');
    if (y && years.indexOf(y) === -1) years.push(y);
    if (g && genres.indexOf(g) === -1) genres.push(g);
    if (r && ratings.indexOf(r) === -1) ratings.push(r);
  });

  years.sort().reverse();
  genres.sort();
  ratings.sort(function(a, b) { return parseFloat(b) - parseFloat(a); });

  years.forEach(function(y) {
    var opt = document.createElement('option');
    opt.value = y; opt.textContent = y;
    filterYear.appendChild(opt);
  });
  genres.forEach(function(g) {
    var opt = document.createElement('option');
    opt.value = g; opt.textContent = g;
    filterGenre.appendChild(opt);
  });
  ratings.forEach(function(r) {
    var opt = document.createElement('option');
    opt.value = r;
    // Format rating display with stars
    var num = parseFloat(r);
    var display = '';
    var full = Math.floor(num);
    var hasHalf = num % 1 !== 0;
    for (var i = 0; i < full; i++) display += '\u2605';
    if (hasHalf) display += '\u00BD';
    opt.textContent = display + ' (' + r + ')';
    filterRating.appendChild(opt);
  });

  function getFilteredRows() {
    var yearVal = filterYear.value;
    var genreVal = filterGenre.value;
    var ratingVal = filterRating.value;
    var searchVal = filterSearch.value.toLowerCase().trim();

    return rows.filter(function(row) {
      if (yearVal && row.getAttribute('data-year') !== yearVal) return false;
      if (genreVal && row.getAttribute('data-genre') !== genreVal) return false;
      if (ratingVal && row.getAttribute('data-rating') !== ratingVal) return false;
      if (searchVal && row.getAttribute('data-title').toLowerCase().indexOf(searchVal) === -1) return false;
      return true;
    });
  }

  function render() {
    var filtered = getFilteredRows();

    // Hide all rows first
    rows.forEach(function(row) { row.style.display = 'none'; });

    // Show filtered rows up to visibleCount
    var shown = 0;
    filtered.forEach(function(row, i) {
      if (i < visibleCount) {
        row.style.display = '';
        shown++;
      }
    });

    // Show/hide month headers based on visible rows
    monthHeaders.forEach(function(header) {
      var month = header.getAttribute('data-month');
      var hasVisible = filtered.some(function(row, i) {
        return i < visibleCount && row.getAttribute('data-month') === month && row.style.display !== 'none';
      });
      header.style.display = hasVisible ? '' : 'none';
    });

    // Show more button
    if (filtered.length > visibleCount) {
      showMoreBtn.style.display = '';
    } else {
      showMoreBtn.style.display = 'none';
    }

    // No results message
    noResults.style.display = filtered.length === 0 ? '' : 'none';
  }

  // Reset visible count on filter change
  function onFilter() {
    visibleCount = PAGE_SIZE;
    render();
  }

  filterYear.addEventListener('change', onFilter);
  filterGenre.addEventListener('change', onFilter);
  filterRating.addEventListener('change', onFilter);
  filterSearch.addEventListener('input', onFilter);

  showMoreBtn.addEventListener('click', function() {
    visibleCount += PAGE_SIZE;
    render();
  });

  // Click to expand/collapse review
  rows.forEach(function(row) {
    var main = row.querySelector('.diary-row-main');
    var review = row.querySelector('.diary-review');
    if (main && review) {
      main.addEventListener('click', function(e) {
        e.preventDefault();
        var isOpen = row.classList.contains('diary-row-open');
        // Close all others
        rows.forEach(function(r) { r.classList.remove('diary-row-open'); });
        if (!isOpen) {
          row.classList.add('diary-row-open');
        }
      });
    } else if (main) {
      main.style.cursor = 'default';
    }
  });

  // Initial render
  render();
})();
</script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'movies' });</script>
