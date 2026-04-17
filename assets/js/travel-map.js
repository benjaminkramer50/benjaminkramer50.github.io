(function () {
  'use strict';

  var container = document.querySelector('.travel-map-container');
  if (!container) return;

  var visitedCountries = (container.getAttribute('data-visited-countries') || '')
    .split(',').filter(Boolean);
  var visitedStates = (container.getAttribute('data-visited-states') || '')
    .split(',').filter(Boolean);

  // Mark visited countries
  visitedCountries.forEach(function (code, i) {
    var el = document.getElementById(code);
    if (el) {
      el.classList.add('visited');
      el.style.setProperty('--reveal-delay', (i * 0.05) + 's');
    }
  });

  // Mark visited states (IDs are "US-XX" in the SVG)
  visitedStates.forEach(function (code, i) {
    var el = document.getElementById('US-' + code);
    if (el) {
      el.classList.add('visited');
      el.style.setProperty('--reveal-delay', (i * 0.03) + 's');
    }
  });

  // Update stats
  var countryStat = document.getElementById('country-stat');
  var stateStat = document.getElementById('state-stat');
  if (countryStat) {
    countryStat.innerHTML = '<strong>' + visitedCountries.length + '</strong> / 195 countries';
  }
  if (stateStat) {
    stateStat.innerHTML = '<strong>' + visitedStates.length + '</strong> / 50 states';
  }

  // Tooltip
  var tooltip = document.getElementById('map-tooltip');
  if (!tooltip) return;

  var allRegions = container.querySelectorAll('.map-region');
  allRegions.forEach(function (region) {
    region.addEventListener('mouseenter', function () {
      var name = region.getAttribute('data-name') || region.id;
      tooltip.textContent = name;
      tooltip.classList.add('visible');
    });

    region.addEventListener('mousemove', function (e) {
      var rect = container.getBoundingClientRect();
      tooltip.style.left = (e.clientX - rect.left + 12) + 'px';
      tooltip.style.top = (e.clientY - rect.top - 8) + 'px';
    });

    region.addEventListener('mouseleave', function () {
      tooltip.classList.remove('visible');
    });
  });
})();
