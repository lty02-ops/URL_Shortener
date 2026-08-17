const API_BASE_URL = '';
const AUTH_CONFIG = window.AUTH_CONFIG || {};
const TOKEN_KEY = 'urlShortenerAccessToken';
const TOKEN_EXPIRY_KEY = 'urlShortenerTokenExpiry';
const PKCE_VERIFIER_KEY = 'urlShortenerPkceVerifier';
const OAUTH_STATE_KEY = 'urlShortenerOauthState';

function base64Url(bytes) {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function randomBase64Url(byteLength = 32) {
  return base64Url(crypto.getRandomValues(new Uint8Array(byteLength)));
}

async function login() {
  if (!AUTH_CONFIG.domain || !AUTH_CONFIG.clientId) {
    showError('로그인 설정을 불러오지 못했습니다.');
    return;
  }
  const verifier = randomBase64Url(64);
  const state = randomBase64Url(32);
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
  sessionStorage.setItem(PKCE_VERIFIER_KEY, verifier);
  sessionStorage.setItem(OAUTH_STATE_KEY, state);
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: AUTH_CONFIG.clientId,
    redirect_uri: AUTH_CONFIG.redirectUri,
    scope: 'openid email',
    state,
    code_challenge_method: 'S256',
    code_challenge: base64Url(new Uint8Array(digest))
  });
  window.location.assign(`${AUTH_CONFIG.domain}/oauth2/authorize?${params}`);
}

function clearSession() {
  sessionStorage.removeItem(TOKEN_KEY);
  sessionStorage.removeItem(TOKEN_EXPIRY_KEY);
  sessionStorage.removeItem(PKCE_VERIFIER_KEY);
  sessionStorage.removeItem(OAUTH_STATE_KEY);
}

function logout() {
  clearSession();
  const params = new URLSearchParams({
    client_id: AUTH_CONFIG.clientId,
    logout_uri: AUTH_CONFIG.logoutUri
  });
  window.location.assign(`${AUTH_CONFIG.domain}/logout?${params}`);
}

function getAccessToken() {
  const token = sessionStorage.getItem(TOKEN_KEY);
  const expiry = Number(sessionStorage.getItem(TOKEN_EXPIRY_KEY));
  if (!token || !expiry || Date.now() >= expiry) {
    clearSession();
    return null;
  }
  return token;
}

async function handleLoginCallback() {
  const params = new URLSearchParams(window.location.search);
  if (params.has('error')) {
    history.replaceState({}, '', window.location.pathname);
    throw new Error(params.get('error_description') || params.get('error'));
  }
  const code = params.get('code');
  if (!code) return;

  const verifier = sessionStorage.getItem(PKCE_VERIFIER_KEY);
  const expectedState = sessionStorage.getItem(OAUTH_STATE_KEY);
  if (!verifier || !expectedState || params.get('state') !== expectedState) {
    clearSession();
    throw new Error('로그인 요청을 확인할 수 없습니다. 다시 로그인해 주세요.');
  }

  const response = await fetch(`${AUTH_CONFIG.domain}/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: AUTH_CONFIG.clientId,
      code,
      redirect_uri: AUTH_CONFIG.redirectUri,
      code_verifier: verifier
    })
  });
  const tokens = await response.json();
  if (!response.ok || !tokens.access_token) {
    clearSession();
    throw new Error(tokens.error_description || '로그인 토큰을 발급받지 못했습니다.');
  }
  sessionStorage.setItem(TOKEN_KEY, tokens.access_token);
  sessionStorage.setItem(TOKEN_EXPIRY_KEY, String(Date.now() + tokens.expires_in * 1000));
  sessionStorage.removeItem(PKCE_VERIFIER_KEY);
  sessionStorage.removeItem(OAUTH_STATE_KEY);
  history.replaceState({}, '', window.location.pathname);
}

function renderAuthentication() {
  const authenticated = Boolean(getAccessToken());
  document.getElementById('authStatus').textContent = authenticated
    ? '로그인됨 — 내 URL만 표시됩니다.'
    : '로그인이 필요합니다.';
  document.getElementById('loginButton').classList.toggle('hidden', authenticated);
  document.getElementById('logoutButton').classList.toggle('hidden', !authenticated);
  document.getElementById('randomButton').disabled = !authenticated;
  document.getElementById('customButton').disabled = !authenticated;
}

async function authenticatedFetch(path, options = {}) {
  const token = getAccessToken();
  if (!token) throw new Error('로그인이 필요합니다.');
  const headers = new Headers(options.headers || {});
  headers.set('Authorization', `Bearer ${token}`);
  const response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });
  if (response.status === 401) {
    clearSession();
    renderAuthentication();
    throw new Error('로그인이 만료되었습니다. 다시 로그인해 주세요.');
  }
  return response;
}

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

  if (!getAccessToken()) {
    showError('로그인 후 URL을 단축할 수 있습니다.');
    return;
  }

  if (!url) {
    showError('URL을 입력하세요.');
    return;
  }

  if (mode === 'custom' && !customCode) {
    showError('직접 생성하려면 코드를 입력하세요.');
    return;
  }

  try {
    const response = await authenticatedFetch('/api/shorten', {
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
  if (!getAccessToken()) {
    document.getElementById('urlList').innerHTML = '<p class="loading">로그인하면 본인이 만든 URL 목록을 볼 수 있습니다.</p>';
    return;
  }
  try {
    const response = await authenticatedFetch('/api/urls');

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
    const response = await authenticatedFetch(`/api/urls/${encodeURIComponent(id)}`, {
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

document.addEventListener('DOMContentLoaded', async () => {
  try {
    await handleLoginCallback();
  } catch (error) {
    showError(error.message);
  }
  renderAuthentication();
  await loadUrlList();
});
