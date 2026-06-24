# 빠른 시작 가이드 (Quick Start Guide)

## 요구사항 (Requirements)

- Node.js (v14.0.0 이상)
- MySQL (v5.7 이상)
- Python (프론트엔드 서버 실행용, 선택사항)

## 1단계: MySQL 설정

1. MySQL 서버 실행
2. 데이터베이스 생성:
```sql
mysql -u root -p
CREATE DATABASE url_shortener;
```

3. `backend/.env` 파일 생성 (`.env.example` 참고):
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
DB_NAME=url_shortener
```

자세한 설정은 [MYSQL_SETUP.md](MYSQL_SETUP.md) 참고

## 2단계: 백엔드 설정

```bash
cd backend
npm install
npm start
```

✅ 백엔드는 포트 5000에서 실행됩니다.

## 3단계: 프론트엔드 실행

새로운 터미널을 열고:

```bash
cd frontend

# Windows/Mac에서
python -m http.server 8000

# Linux/WSL에서
python3 -m http.server 8000

# 또는 Node.js http-server (모든 OS)
npx http-server -p 8000
```

✅ 프론트엔드는 포트 8000에서 실행됩니다.

## 4단계: 브라우저에서 열기

http://localhost:8000 를 브라우저에서 열기

## 테스트해보기

### cURL을 사용한 API 테스트

```bash
# URL 단축
curl -X POST http://localhost:5000/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://github.com/microsoft/vscode"}'

# 모든 URL 조회
curl http://localhost:5000/api/urls

# 특정 URL 통계
curl http://localhost:5000/api/stats/abc123
```

## 트러블슈팅 (Troubleshooting)

### 포트가 이미 사용 중인 경우

**백엔드 포트 변경** (server.js):
```javascript
const PORT = 5001;  // 5000 대신 5001 사용
```

**프론트엔드 포트 변경**:
```bash
python -m http.server 8001
```

그 다음 `script.js`에서 API_BASE_URL 업데이트:
```javascript
const API_BASE_URL = 'http://localhost:5001';
```

### CORS 에러

프론트엔드와 백엔드가 다른 포트에서 실행 중이면 CORS 에러가 발생할 수 있습니다.
server.js의 CORS 설정을 확인하세요:

```javascript
app.use(cors());  // 모든 요청 허용
```

### 데이터베이스 에러

`backend/urls.db`를 삭제하고 서버를 다시 시작하면 새로운 데이터베이스가 생성됩니다.

## 파일 구조

```
backend/
├── server.js          # Express 서버 (API 구현)
└── package.json       # 의존성 정의

frontend/
├── index.html         # HTML 템플릿
├── style.css          # 스타일
└── script.js          # JavaScript (API 호출)
```

## 주요 코드

### 백엔드 - URL 단축
```javascript
app.post('/api/shorten', (req, res) => {
  const { url } = req.body;
  const shortCode = generateShortCode();
  // 데이터베이스에 저장
});
```

### 프론트엔드 - API 호출
```javascript
const response = await fetch(`${API_BASE_URL}/api/shorten`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ url })
});
```

## 다음 단계

- 더 많은 기능 추가 (QR 코드, 커스텀 코드, 등)
- 데이터베이스를 PostgreSQL로 업그레이드
- 인증 기능 추가
- Docker를 사용한 배포
