---
layout: page
title: Movie Log
---

<p class="page-intro">Films I have watched and what I thought.</p>

{% assign sorted_movies = site.data.movies | reverse | sort: "date_watched" | reverse %}
{% assign fav_movies = sorted_movies | sort: "date_watched" | reverse %}
{% assign canon_movies = site.data.movie_canon %}
{% assign current_movie_year = site.time | date: "%Y" %}
{% assign movies_this_year = 0 %}
{% for item in sorted_movies %}
  {% assign watched_year = item.date_watched | date: "%Y" %}
  {% if watched_year == current_movie_year %}
    {% assign movies_this_year = movies_this_year | plus: 1 %}
  {% endif %}
{% endfor %}

{% if sorted_movies.size > 0 or canon_movies.size > 0 %}
<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="false">Favorites</button>
    <button class="shelf-toggle-btn" data-mode="recents" aria-pressed="true">Recents</button>
    <button class="shelf-toggle-btn" data-mode="canon" aria-pressed="false">Canon</button>
  </div>

  <div class="shelf-section" id="shelf-favorites" data-shelf-view-panel="favorites">
    {% assign favorite_count = 0 %}
    {% for item in fav_movies %}
      {% if item.favorite %}
        {% assign favorite_count = favorite_count | plus: 1 %}
      {% endif %}
    {% endfor %}
    {% if favorite_count > 0 %}
    <div class="favorite-poster-grid">
      {% for item in fav_movies %}
      {% if item.favorite %}
      {% assign movie_key = item.title | slugify | append: '-' | append: item.year %}
      {% assign poster = site.data.movie_posters[movie_key] %}
      <article class="favorite-poster-card">
        <a class="favorite-poster-link" href="#movie-{{ movie_key }}" data-target-row="movie-{{ movie_key }}">
          <div class="favorite-poster-frame">
            {% if poster and poster.poster_url %}
            <img class="favorite-poster-image" src="{{ poster.poster_url }}" alt="{{ item.title }} poster" loading="lazy">
            {% else %}
            <div class="favorite-poster-placeholder">
              <span>{{ item.title }}</span>
              <span>{{ item.year }}</span>
            </div>
            {% endif %}
          </div>
          <div class="favorite-poster-meta">
            <div class="favorite-poster-title">{{ item.title }}</div>
            <div class="favorite-poster-year">{{ item.year }}</div>
          </div>
        </a>
      </article>
      {% endif %}
      {% endfor %}
    </div>
    {% else %}
    <p class="shelf-empty">No favorites yet.</p>
    {% endif %}
  </div>

  <div data-shelf-view-panel="recents">
  <p class="movie-count-note">This year, I've watched <strong>{{ movies_this_year }}</strong> movies; all time, I've logged <strong>{{ sorted_movies.size }}</strong>.</p>
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

  <div class="recent-browser">
    <div class="recent-browser-list">
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

      <div class="diary-table" id="diary-table">
        {% assign current_month = "" %}
        {% for item in sorted_movies %}
          {% assign item_month = item.date_watched | date: "%B %Y" %}
          {% if item_month != current_month %}
            {% assign current_month = item_month %}
            <div class="diary-month-header" data-month="{{ item_month }}">{{ item_month }}</div>
          {% endif %}
          {% assign movie_key = item.title | slugify | append: '-' | append: item.year %}
          {% assign poster = site.data.movie_posters[movie_key] %}
          <div class="diary-row{% if item.review %} diary-row-has-review{% endif %}"
               id="movie-{{ movie_key }}"
               data-title="{{ item.title }}"
               data-year="{{ item.year }}"
               data-genre="{{ item.genre }}"
               data-rating="{{ item.rating }}"
               data-date="{{ item.date_watched }}"
               data-poster-url="{% if poster and poster.poster_url %}{{ poster.poster_url }}{% endif %}"
               data-month="{{ item.date_watched | date: '%B %Y' }}">
            <div class="diary-row-main"{% if item.review %} role="button" tabindex="0" aria-expanded="false"{% endif %}>
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
            <div class="diary-review" aria-hidden="true">
              <div class="diary-review-poster">
                {% if poster and poster.poster_url %}
                <img src="{{ poster.poster_url }}" alt="{{ item.title }} poster" loading="lazy">
                {% else %}
                <div class="diary-review-placeholder">
                  <span>{{ item.title }}</span>
                  <span>{{ item.year }}</span>
                </div>
                {% endif %}
              </div>
              <div class="diary-review-copy">
                <p>{{ item.review | newline_to_br }}</p>
              </div>
            </div>
            {% endif %}
          </div>
        {% endfor %}
      </div>

      <div id="diary-no-results" class="diary-no-results" style="display:none;">No movies match your filters.</div>

      <button class="diary-show-more" id="diary-show-more" style="display:none;">Show more</button>
    </div>
  </div>
  </div>

  <div class="canon-browser" id="canon-browser" data-shelf-view-panel="canon">
  <div class="canon-browser-topline">
    <div>
      <h2 class="canon-browser-title">Canon</h2>
      <p class="canon-browser-note">A searchable catalog of {{ canon_movies.size }} films sourced from the <a href="https://1001movies.fandom.com/wiki/By_Director" target="_blank" rel="noopener">1001 Movies You Must See Before You Die Wiki's By Director index</a>, with watched films marked where they overlap.</p>
    </div>
  </div>

  <div class="diary-filters canon-filters">
    <input type="search" id="canon-search" placeholder="Search canon titles, directors, years..." aria-label="Search canon titles">
    <select id="canon-status" aria-label="Filter canon status">
      <option value="">All Statuses</option>
      <option value="reviewed">Reviewed</option>
      <option value="favorite">Favorites</option>
      <option value="not-reviewed">Not reviewed</option>
    </select>
    <select id="canon-sort" aria-label="Sort canon titles">
      <option value="year" selected>Year</option>
      <option value="title">Title</option>
      <option value="director">Director</option>
      <option value="source">Source order</option>
    </select>
  </div>

  <div class="canon-list" id="canon-list"></div>
  <div class="canon-pagination" id="canon-pagination" aria-label="Canon pagination">
    <button type="button" class="canon-page-btn" id="canon-prev" aria-label="Previous canon page">Previous</button>
    <div class="canon-page-status" id="canon-page-status">Page 1 of 1</div>
    <button type="button" class="canon-page-btn" id="canon-next" aria-label="Next canon page">Next</button>
  </div>
  <div id="canon-no-results" class="diary-no-results" style="display:none;">No canon movies match your filters.</div>
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
    filtered.forEach(function(row, i) {
      if (i < visibleCount) {
        row.style.display = '';
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

  function openRecentRow(targetId) {
    var row = document.getElementById(targetId);
    if (!row) return;

    var main = row.querySelector('.diary-row-main');
    if (main && row.classList.contains('diary-row-has-review') && !row.classList.contains('diary-row-open')) {
      main.click();
    }

    if (row.scrollIntoView) {
      row.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }

  // Click to toggle inline review cards.
  rows.forEach(function(row) {
    var main = row.querySelector('.diary-row-main');
    if (main) {
      main.addEventListener('click', function(e) {
        e.preventDefault();
        if (!row.querySelector('.diary-review')) return;
        var isOpen = row.classList.toggle('diary-row-open');
        row.classList.toggle('expanded', isOpen);
        main.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      });
      if (row.querySelector('.diary-review')) {
        main.style.cursor = 'pointer';
        main.addEventListener('keydown', function (e) {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            main.click();
          }
        });
      }
    }
  });

  // Initial render
  render();

  var favoriteLinks = Array.prototype.slice.call(document.querySelectorAll('.favorite-poster-link'));
  var recentsButton = document.querySelector('.shelf-toggle-btn[data-mode="recents"]');

  favoriteLinks.forEach(function(link) {
    link.addEventListener('click', function(e) {
      var targetId = link.getAttribute('data-target-row');
      if (!targetId) return;

      e.preventDefault();

      if (recentsButton && !recentsButton.classList.contains('active')) {
        recentsButton.click();
      }

      window.location.hash = targetId;
      setTimeout(function() {
        openRecentRow(targetId);
      }, 0);
    });
  });
})();
</script>

<script type="application/json" id="canon-movies-data">{{ canon_movies | jsonify }}</script>
<script type="application/json" id="watched-movies-data">{{ sorted_movies | jsonify }}</script>
<script type="application/json" id="movie-posters-data">{{ site.data.movie_posters | jsonify }}</script>

<script>
(function () {
  var canonContainer = document.getElementById('canon-browser');
  var canonList = document.getElementById('canon-list');
  if (!canonContainer || !canonList) return;

  var canonDataEl = document.getElementById('canon-movies-data');
  var watchedDataEl = document.getElementById('watched-movies-data');
  var moviePostersEl = document.getElementById('movie-posters-data');
  var canonData = canonDataEl ? JSON.parse(canonDataEl.textContent || '[]') : [];
  var watchedData = watchedDataEl ? JSON.parse(watchedDataEl.textContent || '[]') : [];
  var moviePosters = moviePostersEl ? JSON.parse(moviePostersEl.textContent || '{}') : {};

  var searchInput = document.getElementById('canon-search');
  var statusSelect = document.getElementById('canon-status');
  var sortSelect = document.getElementById('canon-sort');
  var prevBtn = document.getElementById('canon-prev');
  var nextBtn = document.getElementById('canon-next');
  var pageStatus = document.getElementById('canon-page-status');
  var noResults = document.getElementById('canon-no-results');
  var pageSize = 36;
  var currentPage = 1;
  var canonOpenSlugs = {};

  function slugify(text) {
    return String(text || '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  function movieKey(title, year) {
    return slugify(title) + '-' + String(year || '');
  }

  function posterForMovie(item) {
    var key = item.slug || movieKey(item.title, item.year);
    return moviePosters[key] && moviePosters[key].poster_url ? moviePosters[key].poster_url : '';
  }

  function formatRating(value) {
    var rating = parseFloat(value);
    if (!isFinite(rating)) return '';
    return rating % 1 === 0 ? String(rating) : rating.toFixed(1);
  }

  function renderRatingHtml(value) {
    var rating = parseFloat(value);
    if (!isFinite(rating)) return '';

    var fullStars = Math.floor(rating);
    var hasHalf = rating % 1 !== 0;
    var halfPos = fullStars + 1;
    var stars = [];

    for (var i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.push('<span class="star-full">&#9733;</span>');
      } else if (hasHalf && i === halfPos) {
        stars.push('<span class="star-half">&#9733;</span>');
      } else {
        stars.push('<span class="star-empty">&#9734;</span>');
      }
    }

    return '<span class="canon-row-rating" aria-label="Rating: ' + escapeHtml(formatRating(rating)) + ' out of 5">' +
      stars.join('') +
      '<span class="canon-row-rating-value">' + escapeHtml(formatRating(rating)) + '/5</span>' +
    '</span>';
  }

  function parseDate(value) {
    if (!value) return null;
    var date = new Date(value);
    return isNaN(date.getTime()) ? null : date;
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
    if (filters.status === 'not-reviewed' && item.reviewed) return false;

    return true;
  }

  function render() {
    var filters = currentFilterValue();
    var filtered = canonItems.filter(function (item) {
      return matchesFilters(item, filters);
    }).slice().sort(function (a, b) {
      return compareBySort(a, b, filters.sort);
    });

    var totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    var start = (currentPage - 1) * pageSize;
    var end = start + pageSize;

    canonList.innerHTML = '';

    filtered.slice(start, end).forEach(function (item) {
      var row = document.createElement('div');
      var isOpen = !!canonOpenSlugs[item.slug];
      row.className = 'canon-row' +
        (item.reviewed ? ' canon-row-reviewed canon-row-has-review' : '') +
        (item.favorite ? ' canon-row-favorite' : '') +
        (isOpen ? ' canon-row-open expanded' : '');
      row.setAttribute('data-title', item.title);
      row.setAttribute('data-slug', item.slug);
      row.setAttribute('data-year', String(item.year));
      row.setAttribute('data-director', item.director);
      row.setAttribute('data-reviewed', item.reviewed ? 'true' : 'false');
      row.setAttribute('data-favorite', item.favorite ? 'true' : 'false');
      if (item.reviewed) {
        row.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      }

      var checkbox = item.reviewed ? '&#x2611;' : '&#x2610;';
      var statusPills = '';
      if (item.reviewed) {
        statusPills += '<span class="canon-pill canon-pill-status canon-pill-reviewed">Reviewed</span>';
      }
      if (item.favorite) {
        statusPills += '<span class="canon-pill canon-pill-favorite">Favorite</span>';
      }
      var posterUrl = posterForMovie(item);
      var ratingHtml = renderRatingHtml(item.rating);
      var reviewMetaHtml = ratingHtml ? '<div class="canon-row-review-meta">' + ratingHtml + '</div>' : '';
      var reviewHtml = item.reviewed ? (
        '<div class="canon-row-review">' +
          '<div class="canon-row-review-poster">' +
            (posterUrl
              ? '<img src="' + escapeHtml(posterUrl) + '" alt="' + escapeHtml(item.title) + ' poster" loading="lazy">'
              : '<div class="canon-row-review-placeholder"><span>' + escapeHtml(item.title) + '</span><span>(' + escapeHtml(item.year) + ')</span></div>') +
          '</div>' +
          '<div class="canon-row-review-copy">' + reviewMetaHtml + '<p>' + escapeHtml(item.review).replace(/\n/g, '<br>') + '</p></div>' +
        '</div>'
      ) : '';

      row.innerHTML =
        '<div class="canon-row-main">' +
          '<div class="canon-row-copy">' +
            '<div class="canon-row-title"><span class="canon-row-checkbox" aria-hidden="true">' + checkbox + '</span>' + escapeHtml(item.title) + ' <span class="canon-row-year">(' + escapeHtml(item.year) + ')</span></div>' +
            '<div class="canon-row-director">' + escapeHtml(item.director) + '</div>' +
          '</div>' +
          '<div class="canon-row-actions">' +
            ratingHtml +
            statusPills +
          '</div>' +
        '</div>' +
        reviewHtml;

      if (item.reviewed) {
        var main = row.querySelector('.canon-row-main');
        if (main) {
          main.setAttribute('role', 'button');
          main.setAttribute('tabindex', '0');
          main.style.cursor = 'pointer';
          main.addEventListener('click', function (e) {
            e.preventDefault();
            var openNow = !row.classList.contains('canon-row-open');
            canonOpenSlugs[item.slug] = openNow;
            row.classList.toggle('canon-row-open', openNow);
            row.classList.toggle('expanded', openNow);
            main.setAttribute('aria-expanded', openNow ? 'true' : 'false');
          });
          main.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault();
              main.click();
            }
          });
        }
      }

      canonList.appendChild(row);
    });

    if (pageStatus) {
      pageStatus.textContent = filtered.length === 0 ? 'Page 0 of 0' : 'Page ' + currentPage + ' of ' + totalPages;
    }

    if (prevBtn) {
      prevBtn.disabled = filtered.length === 0 || currentPage <= 1;
    }

    if (nextBtn) {
      nextBtn.disabled = filtered.length === 0 || currentPage >= totalPages;
    }

    if (noResults) {
      noResults.style.display = filtered.length === 0 ? '' : 'none';
    }

  }

  function resetPage() {
    currentPage = 1;
    render();
  }

  if (searchInput) searchInput.addEventListener('input', resetPage);
  if (statusSelect) statusSelect.addEventListener('change', resetPage);
  if (sortSelect) sortSelect.addEventListener('change', resetPage);
  if (prevBtn) {
    prevBtn.addEventListener('click', function () {
      if (currentPage > 1) {
        currentPage -= 1;
        render();
      }
    });
  }
  if (nextBtn) {
    nextBtn.addEventListener('click', function () {
      currentPage += 1;
      render();
    });
  }

  render();
})();
</script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'movies', modes: ['favorites', 'recents', 'canon'], defaultMode: 'recents' });</script>
