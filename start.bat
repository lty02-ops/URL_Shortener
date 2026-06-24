@echo off
echo.
echo ============================================
echo   URL Shortener 시작
echo ============================================
echo.

echo 1. 백엔드 설치 및 실행 중...
cd backend
if not exist node_modules (
    echo   npm 패키지 설치 중...
    call npm install
)
echo   백엔드 서버 시작: http://localhost:5000
start cmd /k npm start

echo.
echo 2. 프론트엔드 실행 대기 중 (5초)...
timeout /t 5

cd ..
cd frontend
echo   프론트엔드 서버 시작: http://localhost:8000
start cmd /k python -m http.server 8000

echo.
echo ============================================
echo   응용 프로그램이 시작되었습니다!
echo   프론트엔드: http://localhost:8000
echo   백엔드: http://localhost:5000
echo ============================================
echo.
