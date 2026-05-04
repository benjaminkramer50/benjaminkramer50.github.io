---
layout: page
title: Movie Log
---

<p class="page-intro">Films I have watched and what I thought.</p>

{% assign sorted_movies = site.data.movies | reverse | sort: "date_watched" | reverse %}
{% assign fav_movies = sorted_movies | where: "favorite", true | sort: "rating" | reverse %}
{% assign canon_movies = site.data.movie_canon %}

{% if sorted_movies.size > 0 or canon_movies.size > 0 %}
<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="false">Favorites</button>
    <button class="shelf-toggle-btn" data-mode="recents" aria-pressed="true">Recents</button>
    <button class="shelf-toggle-btn" data-mode="canon" aria-pressed="false">Canon</button>
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

  <div data-shelf-view-panel="recents">
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
  </div>

  <div data-shelf-view-panel="canon">
  <div class="shelf-section" id="shelf-canon">
    {% if canon_movies.size > 0 %}
    <div class="shelf-row">
      {% for item in canon_movies limit:12 %}
      <span class="spine" style="--spine-hue: {{ item.title | size | times: 53 | modulo: 360 }}; --spine-width: {{ item.title | size | modulo: 18 | plus: 24 }}px;">
        <span class="spine-title">{{ item.title }}</span>
      </span>
      {% endfor %}
    </div>
    <div class="shelf-board"></div>
    {% else %}
    <p class="shelf-empty">Canon data is still loading.</p>
    {% endif %}
  </div>
  <div class="canon-browser" id="canon-browser">
  <div class="canon-browser-topline">
    <div>
      <h2 class="canon-browser-title">Canon</h2>
      <p class="canon-browser-note">The combined-editions canon holds {{ canon_movies.size }} films. This view is read-only; reviews live in admin and favorite canon entries surface in Favorites.</p>
    </div>
    <div class="canon-browser-summary" id="canon-summary"></div>
  </div>

  <div class="diary-filters canon-filters">
    <input type="search" id="canon-search" placeholder="Search canon titles, directors, years..." aria-label="Search canon titles">
    <select id="canon-status" aria-label="Filter canon status">
      <option value="">All Statuses</option>
      <option value="reviewed">Reviewed</option>
      <option value="favorite">Favorites</option>
      <option value="unreviewed">Unreviewed</option>
    </select>
    <select id="canon-sort" aria-label="Sort canon titles">
      <option value="year" selected>Year</option>
      <option value="title">Title</option>
      <option value="director">Director</option>
      <option value="source">Source order</option>
    </select>
  </div>

  <div class="canon-list" id="canon-list"></div>
  <div id="canon-no-results" class="diary-no-results" style="display:none;">No canon movies match your filters.</div>

  <button class="diary-show-more canon-show-more" id="canon-show-more" style="display:none;">Show more</button>
</div>
  </div>
</div>
{% endif %}

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

<script type="application/json" id="canon-movies-data">{{ canon_movies | jsonify }}</script>
<script type="application/json" id="watched-movies-data">{{ sorted_movies | jsonify }}</script>

<script>
(function () {
  var canonContainer = document.getElementById('canon-browser');
  var canonList = document.getElementById('canon-list');
  if (!canonContainer || !canonList) return;

  var canonDataEl = document.getElementById('canon-movies-data');
  var watchedDataEl = document.getElementById('watched-movies-data');
  var canonData = canonDataEl ? JSON.parse(canonDataEl.textContent || '[]') : [];
  var watchedData = watchedDataEl ? JSON.parse(watchedDataEl.textContent || '[]') : [];

  var searchInput = document.getElementById('canon-search');
  var statusSelect = document.getElementById('canon-status');
  var sortSelect = document.getElementById('canon-sort');
  var showMoreBtn = document.getElementById('canon-show-more');
  var summary = document.getElementById('canon-summary');
  var noResults = document.getElementById('canon-no-results');
  var pageSize = 36;
  var visibleCount = pageSize;

  function slugify(text) {
    return String(text || '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  function movieKey(title, year) {
    return slugify(title) + '-' + String(year || '');
  }

  function parseDate(value) {
    if (!value) return null;
    var date = new Date(value);
    return isNaN(date.getTime()) ? null : date;
  }

  function cleanReview(text) {
    return String(text || '').replace(/\s+/g, ' ').trim();
  }

  function escapeHtml(text) {
    return String(text || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  var watchedGroups = {};
  watchedData.forEach(function (entry) {
    var key = entry.canon_id || movieKey(entry.title, entry.year);
    if (!watchedGroups[key]) watchedGroups[key] = [];
    watchedGroups[key].push(entry);
  });

  function summarize(entries) {
    if (!entries || !entries.length) return null;
    var summaryEntry = entries[0];
    var favorite = false;

    entries.forEach(function (entry) {
      var entryDate = parseDate(entry.date_watched);
      var summaryDate = parseDate(summaryEntry.date_watched);
      if (entry.favorite) favorite = true;
      if (entryDate && (!summaryDate || entryDate > summaryDate)) {
        summaryEntry = entry;
      }
    });

    return {
      review: summaryEntry.review || '',
      rating: summaryEntry.rating,
      favorite: favorite || !!summaryEntry.favorite,
      date_watched: summaryEntry.date_watched || ''
    };
  }

  var canonItems = canonData.map(function (item) {
    var summaryEntry = summarize(watchedGroups[item.slug] || watchedGroups[movieKey(item.title, item.year)] || []);
    var reviewed = !!(summaryEntry && summaryEntry.review);
    var favorite = !!(summaryEntry && summaryEntry.favorite);
    return {
      slug: item.slug,
      title: item.title,
      year: item.year,
      director: item.director,
      source_index: item.source_index,
      source: item.source,
      reviewed: reviewed,
      favorite: favorite,
      review: summaryEntry ? summaryEntry.review : '',
      rating: summaryEntry ? summaryEntry.rating : '',
      date_watched: summaryEntry ? summaryEntry.date_watched : ''
    };
  });

  function buildSummary() {
    if (!summary) return;
    var reviewed = 0;
    var favorites = 0;
    canonItems.forEach(function (item) {
      if (item.reviewed) reviewed++;
      if (item.favorite) favorites++;
    });

    summary.innerHTML = '';

    var stats = [
      ['Films', canonItems.length],
      ['Reviewed', reviewed],
      ['Favorites', favorites],
      ['Unreviewed', canonItems.length - reviewed]
    ];

    stats.forEach(function (stat) {
      var node = document.createElement('div');
      node.className = 'canon-summary-stat';
      node.innerHTML = '<strong>' + stat[1] + '</strong><span>' + stat[0] + '</span>';
      summary.appendChild(node);
    });
  }

  function currentFilterValue() {
    return {
      search: (searchInput ? searchInput.value : '').toLowerCase().trim(),
      status: statusSelect ? statusSelect.value : '',
      sort: sortSelect ? sortSelect.value : 'year'
    };
  }

  function compareBySort(a, b, sortKey) {
    if (sortKey === 'year') return (a.year - b.year) || a.title.localeCompare(b.title);
    if (sortKey === 'director') return a.director.localeCompare(b.director) || a.title.localeCompare(b.title);
    if (sortKey === 'source') return (a.source_index - b.source_index) || a.title.localeCompare(b.title);
    return a.title.localeCompare(b.title) || (a.year - b.year);
  }

  function matchesFilters(item, filters) {
    if (filters.search) {
      var haystack = [item.title, item.year, item.director, item.review].join(' ').toLowerCase();
      if (haystack.indexOf(filters.search) === -1) return false;
    }

    if (filters.status === 'reviewed' && !item.reviewed) return false;
    if (filters.status === 'favorite' && !item.favorite) return false;
    if (filters.status === 'unreviewed' && item.reviewed) return false;

    return true;
  }

  function statusLabel(item) {
    if (item.reviewed && item.favorite) return 'Reviewed · Favorite';
    if (item.reviewed) return 'Reviewed';
    if (item.favorite) return 'Favorite';
    return 'Unreviewed';
  }

  function reviewExcerpt(review) {
    var text = cleanReview(review);
    if (!text) return '';
    return text.length > 220 ? text.slice(0, 217) + '...' : text;
  }

  function render() {
    var filters = currentFilterValue();
    var filtered = canonItems.filter(function (item) {
      return matchesFilters(item, filters);
    }).slice().sort(function (a, b) {
      return compareBySort(a, b, filters.sort);
    });

    canonList.innerHTML = '';

    filtered.forEach(function (item, index) {
      if (index >= visibleCount) return;

      var row = document.createElement('div');
      row.className = 'canon-row';
      row.setAttribute('data-title', item.title);
      row.setAttribute('data-year', String(item.year));
      row.setAttribute('data-director', item.director);
      row.setAttribute('data-reviewed', item.reviewed ? 'true' : 'false');
      row.setAttribute('data-favorite', item.favorite ? 'true' : 'false');

      var excerpt = reviewExcerpt(item.review);
      var checkbox = item.reviewed ? '&#x2611;' : '&#x2610;';

      row.innerHTML =
        '<div class="canon-row-main">' +
          '<div class="canon-row-copy">' +
            '<div class="canon-row-title"><span class="canon-row-checkbox" aria-hidden="true">' + checkbox + '</span>' + escapeHtml(item.title) + ' <span class="canon-row-year">(' + escapeHtml(item.year) + ')</span></div>' +
            '<div class="canon-row-director">' + escapeHtml(item.director) + '</div>' +
          '</div>' +
          '<div class="canon-row-actions">' +
            '<span class="canon-pill canon-pill-status">' + escapeHtml(statusLabel(item)) + '</span>' +
            (item.favorite ? '<span class="canon-pill canon-pill-favorite">Favorite</span>' : '') +
          '</div>' +
        '</div>' +
        (excerpt ? '<div class="canon-row-review">' + escapeHtml(excerpt) + '</div>' : '');

      canonList.appendChild(row);
    });

    if (showMoreBtn) {
      showMoreBtn.style.display = filtered.length > visibleCount ? '' : 'none';
    }

    if (noResults) {
      noResults.style.display = filtered.length === 0 ? '' : 'none';
    }

    if (filtered.length > visibleCount) {
      showMoreBtn.style.display = '';
    }

    if (summary) buildSummary();
  }

  function resetVisibleCount() {
    visibleCount = pageSize;
    render();
  }

  if (searchInput) searchInput.addEventListener('input', resetVisibleCount);
  if (statusSelect) statusSelect.addEventListener('change', resetVisibleCount);
  if (sortSelect) sortSelect.addEventListener('change', resetVisibleCount);
  if (showMoreBtn) {
    showMoreBtn.addEventListener('click', function () {
      visibleCount += pageSize;
      render();
    });
  }

  buildSummary();
  render();
})();
</script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'movies', modes: ['favorites', 'recents', 'canon'], defaultMode: 'recents' });</script>
