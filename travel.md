---
layout: page
title: Travel Log
---

<p class="page-intro">Places I have been for work, conferences, and the occasional trip that has nothing to do with either.</p>

{% assign sorted_trips = site.data.travel | reverse | sort: "trip_date" | reverse %}

{% comment %}── Merge visited country codes from travel.yml + visited.yml ──{% endcomment %}
{% assign all_country_codes = "" %}
{% for c in site.data.visited.countries %}{% assign all_country_codes = all_country_codes | append: c.code | append: "," %}{% endfor %}
{% for trip in site.data.travel %}{% if trip.country_code %}{% assign all_country_codes = all_country_codes | append: trip.country_code | append: "," %}{% endif %}{% endfor %}
{% assign visited_countries = all_country_codes | split: "," | uniq | join: "," %}

{% comment %}── Merge visited state codes from travel.yml + visited.yml ──{% endcomment %}
{% assign all_state_codes = "" %}
{% for s in site.data.visited.states %}{% assign all_state_codes = all_state_codes | append: s.code | append: "," %}{% endfor %}
{% for trip in site.data.travel %}{% if trip.state_code %}{% assign all_state_codes = all_state_codes | append: trip.state_code | append: "," %}{% endif %}{% endfor %}
{% assign visited_states = all_state_codes | split: "," | uniq | join: "," %}

<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="map" aria-pressed="false">Map</button>
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="true">Favorites</button>
  </div>

  <div class="shelf-section" id="shelf-map">
    <div class="travel-map-container" data-visited-countries="{{ visited_countries }}" data-visited-states="{{ visited_states }}">
      <div class="map-stats">
        <span id="country-stat"><strong>0</strong> / 195 countries</span>
        <span id="state-stat"><strong>0</strong> / 50 states</span>
      </div>
      <div class="map-wrapper">
        {% include map-world.svg %}
      </div>
      <div class="map-wrapper map-wrapper--us">
        {% include map-us-states.svg %}
      </div>
      <div class="map-tooltip" id="map-tooltip"></div>
    </div>
  </div>

  {% assign fav_trips = sorted_trips | where: "favorite", true %}
  <div class="shelf-section" id="shelf-favorites">
    {% if fav_trips.size > 0 %}
    <div class="stamp-row">
      {% for trip in fav_trips limit:8 %}
      <span class="stamp" style="--stamp-hue: {{ trip.destination | size | times: 47 | modulo: 360 }}; --stamp-rotate: {{ forloop.index | modulo: 3 | minus: 1 | times: 3 }}deg;">
        <span class="stamp-dest">{{ trip.destination }}</span>
        <span class="stamp-country">{{ trip.country }}</span>
      </span>
      {% endfor %}
    </div>
    {% else %}
    <p class="shelf-empty">No favorites yet.</p>
    {% endif %}
  </div>
</div>

{% if sorted_trips.size > 0 %}

<style>
#travel-diary .diary-row {
  display: grid;
  grid-template-columns: 5rem 1fr auto auto;
  align-items: center;
  gap: 0.5rem;
  padding: 0.55rem 0.25rem;
  cursor: pointer;
  transition: background-color 0.1s ease;
}
#travel-diary .diary-row:hover {
  background: var(--color-surface);
}
#travel-diary .diary-row > .diary-review {
  grid-column: 1 / -1;
  padding: 0.4rem 0.25rem 0.75rem 0;
}
@media (max-width: 640px) {
  #travel-diary .diary-row {
    grid-template-columns: 1fr;
    gap: 0.15rem;
    padding: 0.6rem 0.25rem;
  }
  #travel-diary .diary-row > .diary-review {
    padding-left: 0.25rem;
  }
}
</style>

<div class="diary-filters">
  <select id="country-filter" aria-label="Filter by country">
    <option value="">All Countries</option>
  </select>
  <select id="purpose-filter" aria-label="Filter by purpose">
    <option value="">All Purposes</option>
  </select>
  <input type="text" id="search-filter" placeholder="Search destination or highlights..." aria-label="Search trips">
</div>

<div class="diary-table" id="travel-diary">
  {% assign current_month = "" %}
  {% for trip in sorted_trips %}
    {% assign trip_month = trip.trip_date | date: "%B %Y" %}
    {% if trip_month != current_month %}
      {% assign current_month = trip_month %}
  <div class="diary-month-header" data-month="{{ trip_month }}">{{ trip_month }}</div>
    {% endif %}
  <div class="diary-row"
       data-destination="{{ trip.destination | downcase }}"
       data-country="{{ trip.country }}"
       data-purpose="{{ trip.purpose }}"
       data-highlights="{{ trip.highlights | downcase }}"
       data-month="{{ trip_month }}">
    <span class="diary-date">{{ trip.trip_date | date: "%b %-d" }}</span>
    <span class="diary-title">{{ trip.destination }}</span>
    <span class="diary-meta">{{ trip.country }}</span>
    <span class="diary-meta">{{ trip.purpose }}</span>
    {% if trip.highlights or trip.notes %}
    <div class="diary-review">
      {% if trip.highlights %}<strong>Highlights:</strong> {{ trip.highlights }}{% endif %}
      {% if trip.notes %}<br><strong>Notes:</strong> {{ trip.notes }}{% endif %}
    </div>
    {% endif %}
  </div>
  {% endfor %}
</div>

<button class="diary-show-more" id="show-more-btn" style="display:none;">Show More</button>

<script>
(function() {
  var PAGE_SIZE = 20;
  var shown = PAGE_SIZE;

  var rows = Array.prototype.slice.call(document.querySelectorAll('#travel-diary .diary-row'));
  var monthHeaders = Array.prototype.slice.call(document.querySelectorAll('#travel-diary .diary-month-header'));
  var countryFilter = document.getElementById('country-filter');
  var purposeFilter = document.getElementById('purpose-filter');
  var searchFilter = document.getElementById('search-filter');
  var showMoreBtn = document.getElementById('show-more-btn');

  // Build country dropdown from data
  var countries = {};
  rows.forEach(function(row) {
    var c = row.getAttribute('data-country');
    if (c) countries[c] = true;
  });
  Object.keys(countries).sort().forEach(function(c) {
    var opt = document.createElement('option');
    opt.value = c;
    opt.textContent = c;
    countryFilter.appendChild(opt);
  });

  // Build purpose dropdown from data
  var purposes = {};
  rows.forEach(function(row) {
    var p = row.getAttribute('data-purpose');
    if (p) purposes[p] = true;
  });
  Object.keys(purposes).sort().forEach(function(p) {
    var opt = document.createElement('option');
    opt.value = p;
    opt.textContent = p;
    purposeFilter.appendChild(opt);
  });

  // Click to expand/collapse review
  rows.forEach(function(row) {
    row.addEventListener('click', function() {
      row.classList.toggle('expanded');
    });
  });

  function getFiltered() {
    var country = countryFilter.value;
    var purpose = purposeFilter.value;
    var search = searchFilter.value.toLowerCase().trim();

    return rows.filter(function(row) {
      if (country && row.getAttribute('data-country') !== country) return false;
      if (purpose && row.getAttribute('data-purpose') !== purpose) return false;
      if (search) {
        var dest = row.getAttribute('data-destination') || '';
        var highlights = row.getAttribute('data-highlights') || '';
        if (dest.indexOf(search) === -1 && highlights.indexOf(search) === -1) return false;
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

    monthHeaders.forEach(function(hdr) {
      hdr.style.display = visibleMonths[hdr.getAttribute('data-month')] ? '' : 'none';
    });

    showMoreBtn.style.display = filtered.length > shown ? '' : 'none';
  }

  countryFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  purposeFilter.addEventListener('change', function() { shown = PAGE_SIZE; render(); });
  searchFilter.addEventListener('input', function() { shown = PAGE_SIZE; render(); });

  showMoreBtn.addEventListener('click', function() {
    shown += PAGE_SIZE;
    render();
  });

  render();
})();
</script>
{% endif %}

<script src="/assets/js/travel-map.js"></script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'travel', modes: ['map', 'favorites'] });</script>
