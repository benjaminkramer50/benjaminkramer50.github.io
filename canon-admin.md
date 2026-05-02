---
layout: page
title: Canon Admin
description: Private progress editor for the literature canon.
permalink: /canon/admin/
wide: true
sitemap: false
robots: noindex, nofollow
---

{% assign quick_path = site.data.canon_quick_path %}
{% assign canon_items = quick_path.items | where_exp: "item", "item.lifetime_path == true" %}
{% assign canon_progress_data = site.data.canon_progress.items %}

<p class="page-intro">Private editor for my literature-canon progress. Use the controls here, then save once to GitHub. The YAML file is just the stored data behind the scenes.</p>

<div class="canon-admin-panel">
  <div class="canon-admin-toolbar">
    <input id="canon-admin-token" type="password" autocomplete="off" placeholder="GitHub token for saving">
    <button type="button" id="canon-admin-save">Save to GitHub</button>
  </div>
  <div class="canon-admin-note">Use a fine-grained GitHub token scoped to this repository with Contents read/write access. The token stays in this browser session and is not written into the site.</div>
  <div class="canon-admin-status" id="canon-admin-status" role="status"></div>
</div>

<div class="canon-admin-panel canon-admin-bulk-panel">
  <div class="canon-admin-bulk-grid">
    <button type="button" id="canon-admin-jump-next">Jump to First Not Started</button>
    <label for="canon-admin-through-rank">
      Mark through #
      <input id="canon-admin-through-rank" type="number" min="1" max="{{ canon_items.size }}" inputmode="numeric" placeholder="1000">
    </label>
    <button type="button" id="canon-admin-mark-through">Mark Through Completed</button>
    <label for="canon-admin-range-start">
      From #
      <input id="canon-admin-range-start" type="number" min="1" max="{{ canon_items.size }}" inputmode="numeric" placeholder="1">
    </label>
    <label for="canon-admin-range-end">
      To #
      <input id="canon-admin-range-end" type="number" min="1" max="{{ canon_items.size }}" inputmode="numeric" placeholder="100">
    </label>
    <select id="canon-admin-range-status" aria-label="Range status">
      <option value="completed">Completed</option>
      <option value="in_progress">In Progress</option>
      <option value="sampled">Sampled</option>
      <option value="deferred">Deferred</option>
      <option value="planned">Not Started</option>
    </select>
    <button type="button" id="canon-admin-apply-range">Apply Range</button>
  </div>
  <div class="canon-admin-note">Bulk changes are staged in this browser first. Press Save to GitHub when the counts look right.</div>
</div>

<div class="canon-summary" aria-label="Canon admin progress summary">
  <div class="canon-stat">
    <span class="canon-stat-number" id="canon-admin-total-stat">{{ canon_items.size }}</span>
    <span class="canon-stat-label">Works</span>
  </div>
  <div class="canon-stat canon-stat-completed">
    <span class="canon-stat-number" id="canon-admin-completed-stat">0</span>
    <span class="canon-stat-label">Completed</span>
  </div>
  <div class="canon-stat canon-stat-progress">
    <span class="canon-stat-number" id="canon-admin-progress-stat">0</span>
    <span class="canon-stat-label">In Progress</span>
  </div>
  <div class="canon-stat canon-stat-planned">
    <span class="canon-stat-number" id="canon-admin-planned-stat">{{ canon_items.size }}</span>
    <span class="canon-stat-label">Not Started</span>
  </div>
</div>

<div class="canon-filters" aria-label="Canon admin filters">
  <select id="canon-admin-progress-filter" aria-label="Filter by progress">
    <option value="">All Works</option>
    <option value="planned">Not Started</option>
    <option value="in_progress">In Progress</option>
    <option value="completed">Completed</option>
    <option value="sampled">Sampled</option>
    <option value="deferred">Deferred</option>
  </select>
  <input id="canon-admin-search" type="search" placeholder="Search title, author, tradition..." aria-label="Search canon admin">
</div>

<div class="canon-visible-count" id="canon-admin-visible-count"></div>
<div class="canon-list" id="canon-admin-list"></div>

<details class="canon-admin-advanced">
  <summary>Advanced Backup YAML</summary>
  <div class="canon-admin-note">You do not need this for normal tracking. It is here only as a manual backup/export view.</div>
  <button type="button" id="canon-admin-export">Export YAML</button>
  <textarea class="canon-admin-yaml" id="canon-admin-yaml" readonly aria-label="Generated canon progress YAML"></textarea>
</details>

<script>
(function () {
  var canonItems = [
    {% for item in canon_items %}
    {
      id: {{ item.id | jsonify }},
      title: {{ item.title | jsonify }},
      creators: {{ item.creators | jsonify }},
      date_label: {{ item.date_label | jsonify }},
      topic: {{ item.topic | jsonify }},
      tier: {{ item.tier | jsonify }},
      rank: {{ item.rank | jsonify }}
    }{% unless forloop.last %},{% endunless %}
    {% endfor %}
  ];
  var progressState = {{ canon_progress_data | jsonify }} || {};
  var repo = 'benjaminkramer50/benjaminkramer50.github.io';
  var branch = 'main';
  var path = '_data/canon_progress.yml';
  var statuses = [
    { value: 'planned', label: 'Not Started' },
    { value: 'in_progress', label: 'In Progress' },
    { value: 'completed', label: 'Completed' },
    { value: 'sampled', label: 'Sampled' },
    { value: 'deferred', label: 'Deferred' }
  ];
  var rows = [];
  var rowsById = {};
  var changed = false;

  var list = document.getElementById('canon-admin-list');
  var tokenInput = document.getElementById('canon-admin-token');
  var saveButton = document.getElementById('canon-admin-save');
  var exportButton = document.getElementById('canon-admin-export');
  var statusBox = document.getElementById('canon-admin-status');
  var filter = document.getElementById('canon-admin-progress-filter');
  var searchInput = document.getElementById('canon-admin-search');
  var visibleCount = document.getElementById('canon-admin-visible-count');
  var yamlOutput = document.getElementById('canon-admin-yaml');
  var completedStat = document.getElementById('canon-admin-completed-stat');
  var progressStat = document.getElementById('canon-admin-progress-stat');
  var plannedStat = document.getElementById('canon-admin-planned-stat');
  var jumpNextButton = document.getElementById('canon-admin-jump-next');
  var throughRankInput = document.getElementById('canon-admin-through-rank');
  var markThroughButton = document.getElementById('canon-admin-mark-through');
  var rangeStartInput = document.getElementById('canon-admin-range-start');
  var rangeEndInput = document.getElementById('canon-admin-range-end');
  var rangeStatusSelect = document.getElementById('canon-admin-range-status');
  var applyRangeButton = document.getElementById('canon-admin-apply-range');

  function today() {
    return new Date().toISOString().slice(0, 10);
  }

  function statusLabel(status) {
    var found = statuses.find(function (option) { return option.value === status; });
    return found ? found.label : 'Not Started';
  }

  function getStatus(id) {
    var record = progressState[id];
    return record && record.status ? record.status : 'planned';
  }

  function titleCase(value) {
    return String(value || '').replace(/[_-]/g, ' ').replace(/\b\w/g, function (letter) {
      return letter.toUpperCase();
    });
  }

  function setStatus(id, status, options) {
    if (status === 'planned') {
      delete progressState[id];
    } else {
      progressState[id] = { status: status, updated_on: today() };
    }
    changed = true;
    if (!options || !options.deferYaml) updateGeneratedYaml();
  }

  function applyRowStatus(row, status) {
    statuses.forEach(function (option) {
      row.classList.remove('canon-progress-' + option.value.replace(/_/g, '-'));
    });
    row.classList.add('canon-progress-' + status.replace(/_/g, '-'));
    row.setAttribute('data-progress-status', status);
  }

  function renderRows() {
    var fragment = document.createDocumentFragment();
    canonItems.forEach(function (item) {
      var row = document.createElement('article');
      var status = getStatus(item.id);
      var creators = Array.isArray(item.creators) ? item.creators.join(', ') : '';
      var topic = titleCase(item.topic || '');
      var tier = item.tier === 'core' ? 'Core Work' : item.tier === 'major' ? 'Major Work' : titleCase(item.tier || '');
      var searchText = [item.title, creators, item.date_label, topic, tier].join(' ').toLowerCase();

      row.className = 'canon-item';
      row.setAttribute('data-canon-id', item.id);
      row.setAttribute('data-progress-status', status);
      row.setAttribute('data-search', searchText);
      row.setAttribute('data-rank', item.rank || 999999);
      applyRowStatus(row, status);

      var mark = document.createElement('div');
      mark.className = 'canon-status-mark';
      mark.setAttribute('aria-hidden', 'true');
      row.appendChild(mark);

      var body = document.createElement('div');
      body.className = 'canon-item-body';

      var topLine = document.createElement('div');
      topLine.className = 'canon-item-topline';
      var rank = document.createElement('span');
      rank.className = 'canon-sequence-badge';
      rank.textContent = '#' + (item.rank || '');
      topLine.appendChild(rank);
      if (item.date_label) {
        var date = document.createElement('span');
        date.className = 'canon-date';
        date.textContent = item.date_label;
        topLine.appendChild(date);
      }
      body.appendChild(topLine);

      var title = document.createElement('h2');
      title.className = 'canon-title';
      title.textContent = item.title || '';
      body.appendChild(title);

      if (creators) {
        var creator = document.createElement('div');
        creator.className = 'canon-creator';
        creator.textContent = creators;
        body.appendChild(creator);
      }

      var meta = document.createElement('div');
      meta.className = 'canon-meta';
      if (topic) {
        var topicSpan = document.createElement('span');
        topicSpan.textContent = topic;
        meta.appendChild(topicSpan);
      }
      if (tier) {
        var tierSpan = document.createElement('span');
        tierSpan.textContent = tier;
        meta.appendChild(tierSpan);
      }
      body.appendChild(meta);
      row.appendChild(body);

      var actions = document.createElement('div');
      actions.className = 'canon-item-actions';
      var select = document.createElement('select');
      select.className = 'canon-progress-control';
      select.setAttribute('aria-label', 'Set progress for ' + (item.title || 'work'));
      statuses.forEach(function (option) {
        var choice = document.createElement('option');
        choice.value = option.value;
        choice.textContent = option.label;
        if (option.value === status) choice.selected = true;
        select.appendChild(choice);
      });
      select.addEventListener('change', function () {
        setStatus(item.id, select.value);
        applyRowStatus(row, select.value);
        updateSummary();
        render();
      });
      actions.appendChild(select);
      row.appendChild(actions);

      rows.push(row);
      rowsById[item.id] = row;
      fragment.appendChild(row);
    });
    list.appendChild(fragment);
  }

  function rankOf(item) {
    var rank = parseInt(item.rank, 10);
    return isNaN(rank) ? 999999 : rank;
  }

  function numberFromInput(input, label) {
    var value = parseInt(input.value, 10);
    if (isNaN(value) || value < 1 || value > canonItems.length) {
      setMessage(label + ' must be between 1 and ' + canonItems.length + '.', true);
      return null;
    }
    return value;
  }

  function applyItemStatus(item, status, options) {
    setStatus(item.id, status, options);
    var row = rowsById[item.id];
    if (!row) return;
    applyRowStatus(row, status);
    var select = row.querySelector('.canon-progress-control');
    if (select) select.value = status;
  }

  function applyBulkStatus(predicate, status, messagePrefix) {
    var changedCount = 0;
    canonItems.forEach(function (item) {
      if (!predicate(item)) return;
      if (getStatus(item.id) !== status) changedCount++;
      applyItemStatus(item, status, { deferYaml: true });
    });
    updateGeneratedYaml();
    updateSummary();
    render();
    if (changedCount === 0) {
      setMessage('No works needed that update.');
    } else {
      setMessage(messagePrefix + ' Updated ' + changedCount + ' works. Press Save to GitHub when ready.');
    }
  }

  function highlightRow(row) {
    row.classList.add('canon-admin-highlight');
    window.setTimeout(function () {
      row.classList.remove('canon-admin-highlight');
    }, 1800);
  }

  function jumpToFirstNotStarted() {
    var item = canonItems.slice().sort(function (a, b) {
      return rankOf(a) - rankOf(b);
    }).find(function (candidate) {
      return getStatus(candidate.id) === 'planned';
    });
    if (!item) {
      setMessage('No not-started works left.');
      return;
    }
    filter.value = '';
    searchInput.value = '';
    render();
    var row = rowsById[item.id];
    if (row) {
      row.scrollIntoView({ block: 'center' });
      highlightRow(row);
    }
    setMessage('First not-started work is #' + item.rank + ': ' + item.title + '.');
  }

  function updateSummary() {
    var counts = { planned: 0, in_progress: 0, completed: 0 };
    canonItems.forEach(function (item) {
      var status = getStatus(item.id);
      if (status === 'completed') counts.completed++;
      else if (status === 'in_progress') counts.in_progress++;
      else if (status === 'planned') counts.planned++;
    });
    completedStat.textContent = counts.completed;
    progressStat.textContent = counts.in_progress;
    plannedStat.textContent = counts.planned;
  }

  function render() {
    var progress = filter.value;
    var search = searchInput.value.toLowerCase().trim();
    var shown = 0;
    rows.sort(function (a, b) {
      return parseInt(a.getAttribute('data-rank'), 10) - parseInt(b.getAttribute('data-rank'), 10);
    }).forEach(function (row) {
      list.appendChild(row);
      var visible = true;
      if (progress && row.getAttribute('data-progress-status') !== progress) visible = false;
      if (search && row.getAttribute('data-search').indexOf(search) === -1) visible = false;
      row.hidden = !visible;
      if (visible) shown++;
    });
    visibleCount.textContent = 'Showing ' + shown + ' of ' + rows.length + ' works';
  }

  function yamlQuote(value) {
    return '"' + String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';
  }

  function buildYaml() {
    var ids = Object.keys(progressState).filter(function (id) {
      return progressState[id] && progressState[id].status && progressState[id].status !== 'planned';
    }).sort(function (a, b) {
      var aItem = canonItems.find(function (item) { return item.id === a; });
      var bItem = canonItems.find(function (item) { return item.id === b; });
      return (aItem && aItem.rank || 999999) - (bItem && bItem.rank || 999999);
    });
    var lines = ['---', 'schema_version: 1', "updated_on: '" + today() + "'"];
    if (ids.length === 0) {
      lines.push('items: {}');
    } else {
      lines.push('items:');
      ids.forEach(function (id) {
        var record = progressState[id];
        lines.push('  ' + yamlQuote(id) + ':');
        lines.push('    status: ' + record.status);
        lines.push("    updated_on: '" + (record.updated_on || today()) + "'");
      });
    }
    return lines.join('\n') + '\n';
  }

  function updateGeneratedYaml() {
    yamlOutput.value = buildYaml();
  }

  function setMessage(message, isError) {
    statusBox.textContent = message;
    statusBox.classList.toggle('canon-admin-status-error', !!isError);
  }

  function toBase64(text) {
    var bytes = new TextEncoder().encode(text);
    var binary = '';
    bytes.forEach(function (byte) { binary += String.fromCharCode(byte); });
    return btoa(binary);
  }

  async function saveToGitHub() {
    var token = tokenInput.value.trim();
    if (!token) {
      setMessage('Enter a GitHub token before saving.', true);
      return;
    }
    saveButton.disabled = true;
    setMessage('Saving progress to GitHub...');
    try {
      var apiUrl = 'https://api.github.com/repos/' + repo + '/contents/' + encodeURIComponent(path).replace(/%2F/g, '/') + '?ref=' + branch;
      var headers = {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer ' + token
      };
      var current = await fetch(apiUrl, { headers: headers });
      var sha = null;
      if (current.ok) {
        sha = (await current.json()).sha;
      } else if (current.status !== 404) {
        throw new Error('Could not read current progress file from GitHub.');
      }
      var yaml = buildYaml();
      var response = await fetch(apiUrl, {
        method: 'PUT',
        headers: Object.assign({ 'Content-Type': 'application/json' }, headers),
        body: JSON.stringify({
          message: 'Update canon progress',
          content: toBase64(yaml),
          sha: sha,
          branch: branch
        })
      });
      if (!response.ok) {
        var errorBody = await response.json().catch(function () { return {}; });
        throw new Error(errorBody.message || 'GitHub rejected the update.');
      }
      changed = false;
      setMessage('Saved. GitHub Pages will rebuild the public canon page shortly.');
    } catch (error) {
      setMessage(error.message || 'Could not save progress.', true);
    } finally {
      saveButton.disabled = false;
    }
  }

  function exportYaml() {
    var yaml = buildYaml();
    updateGeneratedYaml();
    var blob = new Blob([yaml], { type: 'text/yaml' });
    var link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'canon_progress.yml';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  }

  filter.addEventListener('change', render);
  searchInput.addEventListener('input', render);
  saveButton.addEventListener('click', saveToGitHub);
  exportButton.addEventListener('click', exportYaml);
  jumpNextButton.addEventListener('click', jumpToFirstNotStarted);
  markThroughButton.addEventListener('click', function () {
    var endRank = numberFromInput(throughRankInput, 'Mark-through rank');
    if (endRank === null) return;
    applyBulkStatus(function (item) {
      return rankOf(item) <= endRank;
    }, 'completed', 'Marked #1 through #' + endRank + ' completed.');
  });
  applyRangeButton.addEventListener('click', function () {
    var startRank = numberFromInput(rangeStartInput, 'Range start');
    var endRank = numberFromInput(rangeEndInput, 'Range end');
    var status = rangeStatusSelect.value;
    if (startRank === null || endRank === null) return;
    if (startRank > endRank) {
      var swap = startRank;
      startRank = endRank;
      endRank = swap;
    }
    applyBulkStatus(function (item) {
      var rank = rankOf(item);
      return rank >= startRank && rank <= endRank;
    }, status, 'Set #' + startRank + ' through #' + endRank + ' to ' + statusLabel(status) + '.');
  });
  window.addEventListener('beforeunload', function (event) {
    if (!changed) return;
    event.preventDefault();
    event.returnValue = '';
  });

  renderRows();
  updateSummary();
  updateGeneratedYaml();
  render();
})();
</script>
