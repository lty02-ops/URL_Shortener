# URL 단축기 (URL Shortener)

긴 URL을 짧고 관리하기 쉬운 링크로 변환하는 웹 애플리케이션입니다.

## 기능 (Features)

- ✅ URL 단축하기
- ✅ 단축된 URL로 원본 URL로 리다이렉트
- ✅ URL 목록 조회
- ✅ 클릭 통계 추적
- ✅ URL 삭제
- ✅ 반응형 디자인

## 프로젝트 구조 (Project Structure)

```
URL_Shortener/
├── backend/
│   ├── server.js           # Express 서버
│   ├── package.json        # 의존성
│   ├── .env.example        # 환경 변수 샘플
│   └── .env               # 환경 변수 (실제)
├── frontend/
│   ├── index.html         # HTML
│   ├── style.css          # 스타일시트
│   └── script.js          # 자바스크립트
├── QUICK_START.md         # 빠른 시작 가이드
├── MYSQL_SETUP.md         # MySQL 설정 가이드
└── README.md             # 이 파일
```

## 설치 및 실행 (Installation & Running)

### 0. MySQL 설정

[MYSQL_SETUP.md](MYSQL_SETUP.md) 참고하여 MySQL 설정 완료

### 1. 백엔드 설정

```bash
cd backend
npm install
npm start
```

서버는 `http://localhost:5000`에서 실행됩니다.

### 2. 프론트엔드 실행

프론트엔드는 정적 파일이므로, 간단한 HTTP 서버로 실행할 수 있습니다:

```bash
cd frontend

# Windows/Mac에서
python -m http.server 8000

# Linux/WSL에서
python3 -m http.server 8000

# 또는 Node.js http-server (모든 OS)
npx http-server -p 8000
```

프론트엔드는 `http://localhost:8000`에서 열 수 있습니다.

## API 엔드포인트 (API Endpoints)

### 1. URL 단축 (POST)
```
POST /api/shorten
Body: { "url": "https://example.com/very/long/url" }
Response: {
  "id": "uuid",
  "original_url": "https://example.com/very/long/url",
  "short_code": "abc123",
  "short_url": "http://localhost:5000/s/abc123"
}
```

### 2. URL 리다이렉트 (GET)
```
GET /s/:shortCode
→ 원본 URL로 리다이렉트 (클릭 수 증가)
```

### 3. 모든 URL 조회 (GET)
```
GET /api/urls
Response: [
  {
    "id": "uuid",
    "original_url": "...",
    "short_code": "abc123",
    "short_url": "http://localhost:5000/s/abc123",
    "created_at": "2024-01-01 12:00:00",
    "clicks": 5
  }
]
```

### 4. URL 삭제 (DELETE)
```
DELETE /api/urls/:id
Response: { "message": "URL deleted successfully" }
```

### 5. 통계 조회 (GET)
```
GET /api/stats/:shortCode
Response: {
  "original_url": "...",
  "short_code": "abc123",
  "created_at": "2024-01-01 12:00:00",
  "clicks": 5
}
```

## 기술 스택 (Tech Stack)

### 백엔드
- **Node.js** - JavaScript 런타임
- **Express.js** - 웹 프레임워크
- **MySQL** - 관계형 데이터베이스
- **CORS** - 크로스-오리진 요청 처리
- **UUID** - 고유 ID 생성

### 프론트엔드
- **HTML5** - 마크업
- **CSS3** - 스타일링
- **Vanilla JavaScript** - 동작 구현
- **Fetch API** - API 통신

## 사용 예시 (Usage Example)

1. 프론트엔드에서 긴 URL 입력
2. "단축하기" 버튼 클릭
3. 단축된 URL 생성 및 표시
4. "복사" 버튼으로 클립보드에 복사
5. 단축된 URL 공유
6. 클릭 시 자동으로 원본 URL로 리다이렉트

## 개선 사항 (Future Improvements)

- [ ] 사용자 인증 기능
- [ ] QR 코드 생성
- [ ] URL 만료 설정
- [ ] 커스텀 단축 코드
- [ ] 상세 분석 페이지
- [ ] 데이터베이스를 PostgreSQL로 변경
- [ ] 캐싱 (Redis)
- [ ] 로그인/로그아웃

## 라이선스

MIT License

---

**작성일**: 2024년
**버전**: 1.0.0
