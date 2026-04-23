---
layout: page
title: Food Log
---

<p class="page-intro">Restaurants and dishes worth remembering.</p>

{% assign sorted_food = site.data.food | reverse | sort: "last_visit" | reverse %}
{% assign fav_food = sorted_food | where: "favorite", true | sort: "rating" | reverse %}

{% if sorted_food.size > 0 %}
<div class="shelf">
  <div class="shelf-toggle" id="shelf-toggle" role="group" aria-label="Shelf view mode">
    <button class="shelf-toggle-btn" data-mode="favorites" aria-pressed="false">Favorites</button>
    <button class="shelf-toggle-btn" data-mode="recents" aria-pressed="true">Recents</button>
  </div>

  <div class="shelf-section" id="shelf-favorites">
    {% if fav_food.size > 0 %}
    <div class="ticket-row">
      {% for item in fav_food limit:6 %}
      <span class="ticket" style="--ticket-hue: {{ item.restaurant | size | times: 47 | modulo: 360 }};">
        <span class="ticket-name">{{ item.restaurant }}</span>
        <span class="ticket-dish">{{ item.cuisine }}</span>
        <span class="ticket-rating">{{ item.rating }}/10</span>
      </span>
      {% endfor %}
    </div>
    {% else %}
    <p class="shelf-empty">No favorites yet.</p>
    {% endif %}
  </div>

  <div class="shelf-section" id="shelf-recents">
    <div class="ticket-row">
      {% for item in sorted_food limit:6 %}
      <span class="ticket" style="--ticket-hue: {{ item.restaurant | size | times: 47 | modulo: 360 }};">
        <span class="ticket-name">{{ item.restaurant }}</span>
        <span class="ticket-dish">{{ item.cuisine }}</span>
        <span class="ticket-rating">{{ item.rating }}/10</span>
      </span>
      {% endfor %}
    </div>
  </div>
</div>
{% endif %}

<!-- Filter bar -->
<div class="diary-filters">
  <select id="filter-cuisine" onchange="applyFilters()">
    <option value="">All Cuisines</option>
  </select>
  <select id="filter-price" onchange="applyFilters()">
    <option value="">All Prices</option>
    <option value="1">$</option>
    <option value="2">$$</option>
    <option value="3">$$$</option>
    <option value="4">$$$$</option>
    <option value="5">$$$$$</option>
  </select>
  <select id="filter-rating" onchange="applyFilters()">
    <option value="">All Ratings</option>
    <option value="10">10/10</option>
    <option value="9">9/10 &amp; up</option>
    <option value="8">8/10 &amp; up</option>
    <option value="7">7/10 &amp; up</option>
    <option value="6">6/10 &amp; up</option>
    <option value="5">5/10 &amp; up</option>
    <option value="4">4/10 &amp; up</option>
    <option value="3">3/10 &amp; up</option>
    <option value="2">2/10 &amp; up</option>
    <option value="1">1/10 &amp; up</option>
  </select>
  <input type="text" id="filter-search" placeholder="Search restaurants, dishes..." oninput="applyFilters()" />
</div>

<!-- Diary table (rows rendered by Liquid, controlled by JS) -->
<div class="diary-table" id="food-diary">
  {% for item in sorted_food %}
  <div class="diary-row"
       id="food-{{ forloop.index }}"
       data-cuisine="{{ item.cuisine }}"
       data-price="{{ item.price }}"
       data-rating="{{ item.rating }}"
       data-restaurant="{{ item.restaurant | downcase }}"
       data-neighborhood="{{ item.neighborhood | downcase }}"
       data-dishes="{% for d in item.dishes %}{{ d.name | downcase }}{% unless forloop.last %},{% endunless %}{% endfor %}"
       data-notes="{{ item.notes | downcase }}"
       onclick="toggleRow(this)">
    <span class="diary-date">{{ item.last_visit }}</span>
    <span class="diary-title">{{ item.restaurant }}</span>
    <span class="diary-meta">{{ item.neighborhood }}</span>
    <span class="diary-meta">{{ item.cuisine }}</span>
    <span class="food-price">{% for i in (1..5) %}{% if i <= item.price %}${% endif %}{% endfor %}</span>
    <span class="diary-rating">
      <span class="rating-value">{{ item.rating }}</span><span class="rating-scale">/10</span>
    </span>
    <div class="diary-review">
      {% if item.notes %}
      <p>{{ item.notes }}</p>
      {% endif %}
      {% if item.dishes.size > 0 %}
      <div class="dishes-section">
        <p class="dishes-heading">Dishes</p>
        {% for dish in item.dishes %}
        <div class="dish-item">
          <span class="dish-name">{{ dish.name }}</span>
          <span class="dish-rating">
            {% assign d_full = dish.rating | floor %}
            {% assign d_half = dish.rating | modulo: 1 %}
            {% assign d_half_pos = d_full | plus: 1 %}
            {% for i in (1..5) %}{% if i <= d_full %}<span class="star-full">&#9733;</span>{% elsif d_half != 0 and i == d_half_pos %}<span class="star-half">&#9733;</span>{% else %}<span class="star-empty">&#9734;</span>{% endif %}{% endfor %}
          </span>
          {% if dish.notes %}
          <span class="dish-notes">{{ dish.notes }}</span>
          {% endif %}
        </div>
        {% endfor %}
      </div>
      {% endif %}
    </div>
  </div>
  {% endfor %}
</div>

<button class="diary-show-more" id="show-more-btn" onclick="showMore()">Show More</button>

<script>
(function () {
  var PAGE_SIZE = 20;
  var visible = PAGE_SIZE;
  var rows = Array.prototype.slice.call(document.querySelectorAll('#food-diary .diary-row'));
  var btn = document.getElementById('show-more-btn');
  var cuisineSelect = document.getElementById('filter-cuisine');

  // Build cuisine dropdown from data
  var cuisines = {};
  rows.forEach(function (r) {
    var c = r.getAttribute('data-cuisine');
    if (c) cuisines[c] = true;
  });
  Object.keys(cuisines).sort().forEach(function (c) {
    var opt = document.createElement('option');
    opt.value = c;
    opt.textContent = c;
    cuisineSelect.appendChild(opt);
  });

  // Filtered subset (indices into rows)
  var filtered = [];

  function getFiltered() {
    var cuisine = cuisineSelect.value;
    var price = document.getElementById('filter-price').value;
    var rating = document.getElementById('filter-rating').value;
    var search = document.getElementById('filter-search').value.toLowerCase().trim();

    var result = [];
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      if (cuisine && r.getAttribute('data-cuisine') !== cuisine) continue;
      if (price && r.getAttribute('data-price') !== price) continue;
      if (rating && parseFloat(r.getAttribute('data-rating')) < parseFloat(rating)) continue;
      if (search) {
        var hay = r.getAttribute('data-restaurant') + ' ' +
                  r.getAttribute('data-neighborhood') + ' ' +
                  r.getAttribute('data-cuisine').toLowerCase() + ' ' +
                  r.getAttribute('data-dishes') + ' ' +
                  r.getAttribute('data-notes');
        if (hay.indexOf(search) === -1) continue;
      }
      result.push(i);
    }
    return result;
  }

  function render() {
    filtered = getFiltered();
    var shown = 0;
    for (var i = 0; i < rows.length; i++) {
      var idx = filtered.indexOf(i);
      if (idx === -1) {
        rows[i].style.display = 'none';
      } else if (idx < visible) {
        rows[i].style.display = '';
        shown++;
      } else {
        rows[i].style.display = 'none';
      }
    }
    btn.style.display = (visible < filtered.length) ? '' : 'none';
  }

  window.applyFilters = function () {
    visible = PAGE_SIZE;
    render();
  };

  window.showMore = function () {
    visible += PAGE_SIZE;
    render();
  };

  window.toggleRow = function (row) {
    var review = row.querySelector('.diary-review');
    if (!review) return;
    var isOpen = row.classList.contains('expanded');
    // Close all others
    rows.forEach(function (r) { r.classList.remove('expanded'); });
    if (!isOpen) row.classList.add('expanded');
  };

  // Initial render
  render();
})();
</script>
<script src="/assets/js/shelf-toggle.js"></script>
<script>new ShelfToggle({ page: 'food', modes: ['favorites', 'recents'], defaultMode: 'recents' });</script>
