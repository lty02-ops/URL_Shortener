# MySQL 설정 가이드

## 1. MySQL 설치

### Windows
- [MySQL 다운로드](https://dev.mysql.com/downloads/mysql/)
- 설치 중 포트(기본 3306), 사용자명(root), 비밀번호 설정

### Mac
```bash
brew install mysql
brew services start mysql
```

### Linux (Ubuntu)
```bash
sudo apt-get install mysql-server
sudo mysql_secure_installation
```

**mysql_secure_installation 실행 중 질문에 대한 답변:**

```
Securing the MySQL server deployment.
Connecting to MySQL using a blank password.

✓ Press ENTER (빈 비밀번호로 계속)

Remove anonymous users? (y/n) → y (권장)
Normally, root should only be allowed to connect from 'localhost'...
Disallow root login remotely? (y/n) → y (권장)
Remove test database and access to it? (y/n) → y (권장)
Reload privilege tables now? (y/n) → y (권장)
```

완료 후 MySQL 재시작:
```bash
sudo systemctl restart mysql
```

## 2. 데이터베이스 생성

### Windows에서 MySQL 접속

1. MySQL Command Line Client 실행 또는:
```bash
# PowerShell/CMD에서
mysql -u root -p
```

암호 입력 (Windows 설치 시 설정한 비밀번호)

### Mac/Linux에서 MySQL 접속

```bash
# Linux: sudo 권한으로 접속 (암호 없음)
sudo mysql -u root

# 또는 암호로 접속
mysql -u root -p
```

### 데이터베이스 생성 (MySQL 프롬프트에서 실행)

MySQL 프롬프트에서 (`mysql>` 표시가 보임):
```sql
CREATE DATABASE url_shortener;
SHOW DATABASES;  -- 확인
EXIT;            -- 또는 \q (MySQL 프롬프트에서 나가기)
```

⚠️ **EXIT;** 또는 **\q** 입력 후 엔터를 눌러 MySQL을 완전히 종료해야 터미널 명령어(`cd backend` 등)를 사용할 수 있습니다.

```bash
# MySQL에서 나간 후 (일반 터미널 프롬프트로 돌아옴)
cd backend
npm install
npm start
```

## 3. 환경 변수 설정

### 💡 MySQL에서 나왔는지 확인

```
# ❌ MySQL 프롬프트 (아직 MySQL 안에 있음)
mysql> 

# ✅ 일반 터미널 프롬프트 (MySQL에서 나옴)
C:\Users\...>     # Windows
username@:~$      # Mac/Linux
```

### Windows 사용자
`backend/.env` 파일 생성 (텍스트 에디터로):
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=url_shortener
```
(MySQL 설치 시 설정한 root 비밀번호 입력)

### Mac/Linux 사용자 (sudo로 접속한 경우)
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=url_shortener
```
(sudo로 접속했으면 비밀번호 없음 - 빈 값 유지)

또는 기본값 사용 (로컬 환경):
- DB_HOST: localhost
- DB_USER: root
- DB_PASSWORD: password (또는 설정한 실제 비밀번호)
- DB_NAME: url_shortener

## 4. 의존성 설치 및 실행

```bash
cd backend
npm install
npm start
```

서버가 시작되면 자동으로 테이블이 생성됩니다.

## ⚡ 빠른 셋업 (Step by Step)

### 1단계: MySQL 시작 (터미널/CMD 또는 PowerShell)
```bash
# Windows (PowerShell/CMD)
mysql -u root -p

# Mac
brew services start mysql

# Linux
sudo systemctl start mysql
```

### 2단계: 데이터베이스 생성 (MySQL 프롬프트에서)
```bash
mysql> CREATE DATABASE url_shortener;
mysql> EXIT;
```
⚠️ **중요:** `EXIT;` 또는 `\q` 를 입력하여 **MySQL 프롬프트에서 나가기**

### 3단계: 환경 설정 (터미널/CMD로 돌아온 후)
`backend/.env` 파일 생성:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=설치시설정한비밀번호
DB_NAME=url_shortener
```

### 4단계: 서버 시작 (터미널/CMD)
```bash
cd backend
npm install
npm start
```

✅ 완료! `http://localhost:5000`에서 API 사용 가능

## 주요 변경사항

| 항목 | SQLite | MySQL |
|------|--------|-------|
| 패키지 | sqlite3 | mysql2/promise |
| 저장소 | 파일 기반 (.db) | 데이터베이스 서버 |
| 동시 연결 | 제한적 | 연결 풀 지원 |
| 성능 | 소규모 프로젝트 | 대규모 프로젝트 |

## MySQL 명령어

```bash
# MySQL 접속
mysql -u root -p

# 데이터베이스 목록
SHOW DATABASES;

# 테이블 확인
USE url_shortener;
SHOW TABLES;

# 데이터 확인
SELECT * FROM urls;

# 데이터베이스 삭제 (초기화)
DROP DATABASE url_shortener;
```

## 트러블슈팅

### "Access denied" 에러
- `.env` 파일의 DB_USER, DB_PASSWORD 확인
- MySQL 서버 실행 확인: `mysql -u root -p`
- Windows: 설치 시 설정한 비밀번호 맞는지 확인
- Linux: `sudo mysql -u root` (비밀번호 없음)로 테스트

### "Can't connect to MySQL server"
- MySQL 서버 실행 확인
  - Windows: Services에서 MySQL 실행 확인
  - Mac: `brew services list` 확인
  - Linux: `sudo systemctl status mysql` 확인
- 포트 3306이 사용 중인지 확인

### "Unknown database" 에러
- 데이터베이스가 생성되었는지 확인: `SHOW DATABASES;`
- URL_Shortener 데이터베이스 생성: `CREATE DATABASE url_shortener;`

### 테이블이 자동 생성되지 않음
- MySQL 서버가 실행 중인지 확인
- `.env` 파일의 데이터베이스 연결 정보 확인
- 서버 로그에서 에러 메시지 확인
- 데이터베이스가 존재하지 않으면 자동 생성되지 않음

### mysql_secure_installation 후 접속 안 됨
- 실행한 보안 설정 확인 (익명 사용자 제거 등)
- 올바른 사용자명과 비밀번호 사용
- 필요시 MySQL 재시작:
  - Windows: `net stop MySQL80 && net start MySQL80`
  - Mac: `brew services restart mysql`
  - Linux: `sudo systemctl restart mysql`
