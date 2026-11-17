'use strict';

fetch('/version.json', { cache: 'no-store' })
  .then(response => {
    if (!response.ok) throw new Error('Version unavailable');
    return response.json();
  })
  .then(build => {
    document.getElementById('build-info').textContent =
      `Версия ${build.version} · ${build.revision.slice(0, 12)}`;
  })
  .catch(() => {
    document.getElementById('build-info').textContent = 'Версия недоступна';
  });
