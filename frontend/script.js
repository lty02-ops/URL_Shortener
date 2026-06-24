const API_BASE_URL = '';

document.getElementById('shortenForm').addEventListener('submit', (event) => {
  event.preventDefault();
});

async function shortenUrl(mode) {
  const urlInput = document.getElementById('urlInput');
  const customCodeInput = document.getElementById('customCodeInput');
  const errorDiv = document.getElementById('error');
  const url = urlInput.value.trim();
  const customCode = customCodeInput.value.trim();

  errorDiv.textContent = '';
  errorDiv.classList.remove('show');

  if (!url) {
    showError('URL을 입력하세요.');
    return;
  }

  if (mode === 'custom' && !customCode) {
    showError('직접 생성하려면 코드를 입력하세요.');
    return;
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/shorten`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        url,
        custom_code: mode === 'custom' ? customCode : null
      })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'URL 단축에 실패했습니다.');
    }

    displayResult(data);
    urlInput.value = '';
    customCodeInput.value = '';
    loadUrlList();
  } catch (error) {
    showError(error.message);
  }
}

function showError(message) {
  const errorDiv = document.getElementById('error');
  errorDiv.textContent = message;
  errorDiv.classList.add('show');
}

function displayResult(data) {
  document.getElementById('originalUrl').textContent = data.original_url;
  document.getElementById('shortUrl').textContent = data.short_url;
  document.getElementById('shortCode').textContent = data.short_code;
  document.getElementById('resultSection').classList.remove('hidden');
}

function copyToClipboard() {
  const shortUrl = document.getElementById('shortUrl').textContent;
  navigator.clipboard.writeText(shortUrl).then(() => {
    alert('복사했습니다.');
  });
}

async function loadUrlList() {
  try {
    const response = await fetch(`${API_BASE_URL}/api/urls`);

    if (!response.ok) {
      throw new Error('URL 목록을 불러오지 못했습니다.');
    }

    const urls = await response.json();
    displayUrlList(urls);
  } catch (error) {
    console.error('Error loading URLs:', error);
    document.getElementById('urlList').innerHTML = '<p class="loading">URL 목록을 불러오지 못했습니다.</p>';
  }
}

function displayUrlList(urls) {
  const urlList = document.getElementById('urlList');

  if (urls.length === 0) {
    urlList.innerHTML = '<p class="loading">아직 단축된 URL이 없습니다.</p>';
    return;
  }

  urlList.innerHTML = urls.map(url => `
    <div class="url-item">
      <div class="url-item-content">
        <div class="url-item-original">원본: ${truncateUrl(url.original_url)}</div>
        <div class="url-item-short">${url.short_url}</div>
        <div class="url-item-stats">
          <span>생성: ${formatDate(url.created_at)}</span>
          <span>클릭: ${url.clicks}</span>
        </div>
      </div>
      <div class="url-item-actions">
        <button onclick="copyUrl('${url.short_url}')" class="btn btn-small">복사</button>
        <button onclick="deleteUrl('${url.id}')" class="btn btn-danger">삭제</button>
      </div>
    </div>
  `).join('');
}

function copyUrl(url) {
  navigator.clipboard.writeText(url).then(() => {
    alert('복사했습니다.');
  });
}

async function deleteUrl(id) {
  if (!confirm('정말 삭제하시겠습니까?')) {
    return;
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/urls/${id}`, {
      method: 'DELETE'
    });

    if (!response.ok) {
      throw new Error('삭제에 실패했습니다.');
    }

    loadUrlList();
  } catch (error) {
    alert('URL 삭제 실패: ' + error.message);
  }
}

function truncateUrl(url) {
  return url.length > 50 ? url.substring(0, 50) + '...' : url;
}

function formatDate(dateString) {
  const date = new Date(dateString);
  return date.toLocaleDateString('ko-KR') + ' ' + date.toLocaleTimeString('ko-KR', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadUrlList();
});
