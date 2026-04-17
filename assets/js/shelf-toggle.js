(function () {
  'use strict';

  function ShelfToggle(opts) {
    this.page = opts.page;
    this.storageKey = 'shelf-mode-' + this.page;
    this.container = document.getElementById('shelf-toggle');

    this.modes = (opts.modes && opts.modes.length ? opts.modes : ['favorites', 'recents']).slice();
    this.defaultMode = opts.defaultMode || this.modes[this.modes.length - 1];
    this.sections = {};
    this.buttons = {};

    if (!this.container) return;

    for (var i = 0; i < this.modes.length; i++) {
      var mode = this.modes[i];
      var section = document.getElementById('shelf-' + mode);
      var button = this.container.querySelector('[data-mode="' + mode + '"]');
      if (!section || !button) return;
      this.sections[mode] = section;
      this.buttons[mode] = button;
    }

    var saved = localStorage.getItem(this.storageKey);
    this.mode = this.modes.indexOf(saved) !== -1 ? saved : this.defaultMode;
    if (this.modes.indexOf(this.mode) === -1) this.mode = this.modes[0];

    this.apply();
    this.bind();
  }

  ShelfToggle.prototype.apply = function () {
    for (var i = 0; i < this.modes.length; i++) {
      var mode = this.modes[i];
      var isActive = this.mode === mode;
      this.sections[mode].classList.toggle('shelf-active', isActive);
      this.buttons[mode].classList.toggle('active', isActive);
      this.buttons[mode].setAttribute('aria-pressed', isActive);
      this.sections[mode].setAttribute('aria-hidden', !isActive);
    }
  };

  ShelfToggle.prototype.bind = function () {
    var self = this;
    this.modes.forEach(function (mode) {
      self.buttons[mode].addEventListener('click', function () {
        self.mode = mode;
        localStorage.setItem(self.storageKey, mode);
        self.apply();
      });
    });
  };

  window.ShelfToggle = ShelfToggle;
})();
