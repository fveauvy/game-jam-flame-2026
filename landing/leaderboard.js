const LEADERBOARD_URL =
  'https://game-jam-flame-2026-gamma.vercel.app/api/leaderboard?limit=15';

function formatTime(timeMs) {
  const totalSeconds = Math.max(0, Math.floor(timeMs / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  const milliseconds = Math.floor((timeMs % 1000) / 10);
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(milliseconds).padStart(2, '0')}`;
}

function setStatus(message) {
  const status = document.getElementById('leaderboard-status');
  if (!status) {
    return;
  }
  status.textContent = message;
}

function renderRows(entries) {
  const body = document.getElementById('leaderboard-rows');
  if (!body) {
    return;
  }

  body.innerHTML = '';
  if (!Array.isArray(entries) || entries.length === 0) {
    const row = document.createElement('tr');
    const cell = document.createElement('td');
    cell.colSpan = 3;
    cell.textContent = 'No scores yet.';
    row.appendChild(cell);
    body.appendChild(row);
    return;
  }

  for (const entry of entries) {
    const row = document.createElement('tr');

    const rankCell = document.createElement('td');
    rankCell.textContent = `#${entry.rank}`;

    const nameCell = document.createElement('td');
    nameCell.textContent = entry.name;

    const timeCell = document.createElement('td');
    timeCell.textContent = formatTime(entry.timeMs);

    row.appendChild(rankCell);
    row.appendChild(nameCell);
    row.appendChild(timeCell);
    body.appendChild(row);
  }
}

let isFetching = false;

async function loadLeaderboard() {
  if (isFetching) {
    return;
  }
  isFetching = true;
  setStatus('Loading latest scores...');

  try {
    const response = await fetch(LEADERBOARD_URL, {
      method: 'GET',
      mode: 'cors',
      cache: 'no-store',
    });

    if (!response.ok) {
      throw new Error(`status=${response.status}`);
    }

    const payload = await response.json();
    renderRows(payload.entries);
    setStatus('Updated leaderboard.');
  } catch (_) {
    renderRows([]);
    setStatus('Leaderboard unavailable right now.');
  } finally {
    isFetching = false;
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const refresh = document.getElementById('leaderboard-refresh');
  if (refresh) {
    refresh.addEventListener('click', () => {
      void loadLeaderboard();
    });
  }

  void loadLeaderboard();
});
