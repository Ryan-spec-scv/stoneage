# Stone Age 8.5 - 완전한 클라이언트-서버 패키지

![Stone Age Banner](https://ss2.baidu.com/6ONYsjip0QIZ8tyhnq/it/u=2467008736,3346972993&fm=58&s=47C4FD0E689A4FE34E96C26F0300A06F)

**Stone Age 8.5 MMORPG** - 서버, 클라이언트, Lua 스크립트, 데이터베이스를 포함한 완전한 게임 패키지

**원본 출처**: [anson1788/stoneage](https://github.com/anson1788/stoneage)

---

## 📋 목차

- [프로젝트 개요](#프로젝트-개요)
- [시스템 아키텍처](#시스템-아키텍처)
- [빠른 시작](#빠른-시작)
  - [로컬 개발 환경 (macOS)](#로컬-개발-환경-macos)
  - [프로덕션 환경 (Linux)](#프로덕션-환경-linux)
- [클라이언트 빌드 및 배포](#클라이언트-빌드-및-배포)
- [전체 테스트 플로우](#전체-테스트-플로우)
- [디렉토리 구조](#디렉토리-구조)
- [문서](#문서)
- [트러블슈팅](#트러블슈팅)
- [기여 및 라이선스](#기여-및-라이선스)

---

## 프로젝트 개요

Stone Age 8.5는 **완전한 MMORPG 시스템**으로 다음을 포함합니다:

- **SAAC 서버**: 계정 관리 서버 (Account Server)
- **GMSV 서버**: 게임 로직 서버 (Game Server)
- **클라이언트**: Windows 기반 DirectX 게임 클라이언트
- **데이터베이스**: MySQL 기반 계정/캐릭터 데이터
- **Lua 스크립트**: 게임 로직 및 NPC 시스템

**목적**: 서버 개발 기술 연구 및 학습 (비상업적 목적)

---

## 시스템 아키텍처

```
┌─────────────┐
│   Client    │ (Windows)
│  (19065)    │
└──────┬──────┘
       │
       ▼
┌─────────────┐         ┌─────────────┐
│    GMSV     │◄────────┤    SAAC     │
│  (19065)    │         │  (10001)    │
└──────┬──────┘         └──────┬──────┘
       │                       │
       ▼                       ▼
┌─────────────────────────────────┐
│          MySQL DB               │
│    (CSA / CSA_Dev)             │
└─────────────────────────────────┘
```

### 컴포넌트 설명

1. **SAAC (Account Server)**:
   - 포트: 10001
   - 역할: 계정 인증, 캐릭터 목록 관리
   - DB: `CSA` (프로덕션) / `CSA_Dev` (개발)

2. **GMSV (Game Server)**:
   - 포트: 19065
   - 역할: 게임 로직, 월드 관리, NPC 시스템
   - SAAC와 통신하여 계정 검증

3. **클라이언트**:
   - 플랫폼: Windows 7/10/11
   - DirectX 9.0c 이상 필요
   - GMSV(19065)에 직접 연결

4. **MySQL 데이터베이스**:
   - 계정 정보 (`CSAlogin` 테이블)
   - 캐릭터 데이터 (파일 기반 + DB 혼용)

---

## 빠른 시작

### 로컬 개발 환경 (macOS)

**환경 특징**:
- 디버그 모드 활성화 (debuglevel=3)
- 무제한 동일 IP 접속
- 10배 빠른 레벨업 (battleexp=10)
- 자동 회원가입 활성화
- 100명 동시 접속 (테스트용)

**필수 도구**:
```bash
# Xcode Command Line Tools
xcode-select --install

# MySQL
brew install mysql

# MySQL 서비스 시작
brew services start mysql
```

**빌드 및 실행**:
```bash
# 1. 서버 빌드
./scripts/build-server-macos.sh

# 2. 서버 시작
./scripts/start-local-macos.sh

# 3. 상태 확인
ps aux | grep -E 'saac|gmsv'
lsof -i :10001  # SAAC
lsof -i :19065  # GMSV

# 4. 로그 확인
tail -f log/saac.log
tail -f log/gmsv.log

# 5. 서버 중지
./scripts/stop-local-macos.sh
```

**설정 파일 위치**:
- `environments/local-macos/acserv.cf` - SAAC 설정
- `environments/local-macos/setup.cf` - GMSV 설정

---

### 프로덕션 환경 (Linux)

**환경 특징**:
- 디버그 비활성화 (성능 최적화)
- MD5 비밀번호 암호화
- IP당 2개 접속 제한
- 1000명 동시 접속 지원
- 자동 백업 (매일 새벽 3시)

**필수 도구** (Ubuntu/Debian):
```bash
# 빌드 도구
sudo apt-get update
sudo apt-get install build-essential

# MySQL 클라이언트 개발 패키지
sudo apt-get install libmysqlclient-dev

# MySQL 서버
sudo apt-get install mysql-server

# MySQL 서비스 시작
sudo systemctl start mysql
sudo systemctl enable mysql
```

**⚠️ 중요: 프로덕션 배포 전 필수 작업**

1. **비밀번호 설정**:
   ```bash
   # environments/production-linux/acserv.cf 수정
   pass YOUR_STRONG_PASSWORD           # SAAC 비밀번호
   sql_PS YOUR_MYSQL_PASSWORD          # MySQL 비밀번호

   # environments/production-linux/setup.cf 수정
   acpasswd=YOUR_STRONG_PASSWORD       # SAAC 연결 비밀번호
   chatmagicpasswd=YOUR_GM_PASSWORD    # GM 명령어 비밀번호
   serverip=YOUR_SERVER_PUBLIC_IP      # 서버 공인 IP
   ```

2. **MySQL 프로덕션 계정 생성**:
   ```sql
   CREATE USER 'stoneage_prod'@'localhost' IDENTIFIED BY 'YOUR_MYSQL_PASSWORD';
   CREATE DATABASE CSA CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   GRANT ALL PRIVILEGES ON CSA.* TO 'stoneage_prod'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **방화벽 설정**:
   ```bash
   sudo ufw allow 10001/tcp  # SAAC
   sudo ufw allow 19065/tcp  # GMSV
   sudo ufw enable
   ```

**빌드 및 실행**:
```bash
# 1. 서버 빌드
./scripts/build-server-linux.sh

# 2. 서버 시작 (비밀번호 설정 후)
./scripts/start-production-linux.sh

# 3. 상태 확인
ps aux | grep -E 'saac|gmsv'
netstat -tln | grep -E '10001|19065'

# 4. 서버 중지
./scripts/stop-production-linux.sh
```

---

## 클라이언트 빌드 및 배포

**빌드 환경**: macOS (개발) + Windows (실행)

**상세 가이드**: [client/BUILD.md](client/BUILD.md)

### 빠른 배포 (기존 바이너리 사용)

```bash
# 1. 배포 패키지 생성 (macOS)
cd /Users/gwang/Desktop/StoneAge/stone-age-master

mkdir -p client/windows-release
cp -r 石器时代客户端最新完整源代码/*.exe client/windows-release/
cp -r 石器时代客户端最新完整源代码/*.dll client/windows-release/
cp -r 石器时代客户端最新完整源代码/data client/windows-release/
cp -r 石器时代客户端最新完整源代码/graphics client/windows-release/

cd client
zip -r StoneAge85_Client_Windows.zip windows-release/

# 2. Windows로 전송 및 실행
# - StoneAge85_Client_Windows.zip을 Windows 머신에 복사
# - 압축 해제
# - Setup.exe로 그래픽 설정
# - Stoneage.exe 실행
```

### 서버 연결 설정

클라이언트의 `config.ini` 또는 `server.ini` 수정:
```ini
[Server]
IP=127.0.0.1        # 로컬 테스트
# IP=your.server.ip # 프로덕션 서버
Port=19065
```

---

## 전체 테스트 플로우

### 회원가입 → 로그인 → 캐릭터 생성 → 게임 진입

```bash
# 1. 서버 시작 (macOS 로컬)
./scripts/start-local-macos.sh

# 2. 클라이언트 실행 (Windows 또는 Wine)
cd client/windows-release
wine Stoneage.exe  # macOS Wine 테스트
# 또는 Windows에서 직접 실행

# 3. 회원가입
# - 클라이언트에서 "회원가입" 클릭
# - ID/PW 입력 (로컬 환경은 자동 등록 활성화)

# 4. 로그인
# - 등록한 ID/PW로 로그인
# - 서버 목록에서 "로컬개발서버" 선택

# 5. 캐릭터 생성
# - 캐릭터 이름, 외형 선택
# - 생성 완료 확인

# 6. 게임 진입
# - 캐릭터 선택
# - 게임 월드 로딩 및 마을 진입
```

### 데이터베이스 확인

```bash
# 생성된 계정 확인
mysql -u root CSA_Dev -e "SELECT * FROM CSAlogin;"

# 캐릭터 파일 확인
ls -la char/
```

---

## 디렉토리 구조

```
stone-age-master/
├── README.md                           # 이 파일
├── .gitignore                          # Git 제외 파일 목록
│
├── 石器时代服务器端最新完整源代码/       # 서버 소스코드
│   ├── saac/                           # SAAC 계정 서버
│   │   ├── saac.c                      # 메인 소스
│   │   ├── Makefile                    # 빌드 설정
│   │   └── saac                        # 컴파일된 바이너리
│   └── gmsv/                           # GMSV 게임 서버
│       ├── gmsv.c                      # 메인 소스
│       ├── Makefile                    # 빌드 설정
│       └── gmsv                        # 컴파일된 바이너리
│
├── 石器时代客户端最新完整源代码/         # 클라이언트 소스코드
│   ├── Stoneage.exe                    # 게임 실행 파일
│   ├── Setup.exe                       # 설정 도구
│   ├── data/                           # 게임 데이터
│   ├── graphics/                       # 그래픽 리소스
│   └── sound/                          # 사운드 리소스
│
├── environments/                       # 환경별 설정 파일
│   ├── local-macos/                    # macOS 로컬 개발
│   │   ├── acserv.cf                   # SAAC 설정
│   │   └── setup.cf                    # GMSV 설정
│   └── production-linux/               # Linux 프로덕션
│       ├── acserv.cf                   # SAAC 설정
│       └── setup.cf                    # GMSV 설정
│
├── scripts/                            # 자동화 스크립트
│   ├── build-server-macos.sh           # macOS 서버 빌드
│   ├── start-local-macos.sh            # macOS 서버 시작
│   ├── stop-local-macos.sh             # macOS 서버 중지
│   ├── build-server-linux.sh           # Linux 서버 빌드
│   ├── start-production-linux.sh       # Linux 서버 시작
│   └── stop-production-linux.sh        # Linux 서버 중지
│
├── client/                             # 클라이언트 빌드 관련
│   ├── BUILD.md                        # 클라이언트 빌드 가이드
│   └── windows-release/                # Windows 배포 패키지
│
├── data/                               # 서버 데이터 (런타임 생성)
├── log/                                # 서버 로그 (런타임 생성)
├── char/                               # 캐릭터 데이터 (런타임 생성)
└── CSA.sql                             # 데이터베이스 스키마
```

---

## 문서

### 한국어 문서 (Korean Docs)

프로젝트의 모든 주요 컴포넌트에 대한 상세한 한국어 문서:

1. **[01_프로젝트개요.md](docs/ko/01_프로젝트개요.md)** - 전체 프로젝트 소개
2. **[02_시스템아키텍처.md](docs/ko/02_시스템아키텍처.md)** - 시스템 구조 및 컴포넌트
3. **[03_서버구조_SAAC.md](docs/ko/03_서버구조_SAAC.md)** - SAAC 계정 서버 상세
4. **[04_서버구조_GMSV.md](docs/ko/04_서버구조_GMSV.md)** - GMSV 게임 서버 상세
5. **[05_클라이언트구조.md](docs/ko/05_클라이언트구조.md)** - 클라이언트 아키텍처
6. **[06_데이터베이스스키마.md](docs/ko/06_데이터베이스스키마.md)** - MySQL 데이터베이스 구조
7. **[07_Lua스크립트시스템.md](docs/ko/07_Lua스크립트시스템.md)** - Lua 게임 로직
8. **[08_빌드및배포가이드.md](docs/ko/08_빌드및배포가이드.md)** - 빌드/배포 절차
9. **[09_개발환경설정.md](docs/ko/09_개발환경설정.md)** - 개발 환경 구축

### 추가 문서

- **[client/BUILD.md](client/BUILD.md)** - 클라이언트 빌드 상세 가이드
- **[CHANGELOG.md](CHANGELOG.md)** - 버전별 변경 이력 (생성 예정)

---

## 트러블슈팅

### 서버 시작 실패

**증상**: `./scripts/start-local-macos.sh` 실행 시 오류

**해결책**:
1. **바이너리 미존재**:
   ```bash
   # 먼저 빌드 실행
   ./scripts/build-server-macos.sh
   ```

2. **MySQL 미실행**:
   ```bash
   brew services start mysql
   # 또는
   mysql.server start
   ```

3. **포트 충돌**:
   ```bash
   # 기존 프로세스 확인
   lsof -i :10001
   lsof -i :19065

   # 프로세스 종료
   ./scripts/stop-local-macos.sh
   ```

### 클라이언트 연결 실패

**증상**: "서버에 연결할 수 없습니다"

**해결책**:
1. **서버 상태 확인**:
   ```bash
   ps aux | grep -E 'saac|gmsv'
   lsof -i :19065
   ```

2. **로그 확인**:
   ```bash
   tail -f log/gmsv.log
   tail -f log/saac.log
   ```

3. **클라이언트 설정 확인**:
   - `config.ini` 또는 `server.ini`에서 IP/Port 확인
   - 로컬: `127.0.0.1:19065`
   - 프로덕션: 서버 공인 IP

### MySQL 연결 오류

**증상**: `Can't connect to MySQL server`

**해결책**:
1. **MySQL 서비스 확인**:
   ```bash
   # macOS
   brew services list | grep mysql

   # Linux
   sudo systemctl status mysql
   ```

2. **데이터베이스 존재 확인**:
   ```bash
   mysql -u root -e "SHOW DATABASES;"
   ```

3. **권한 확인**:
   ```sql
   SHOW GRANTS FOR 'root'@'localhost';
   SHOW GRANTS FOR 'stoneage_prod'@'localhost';
   ```

### 빌드 오류

**증상**: `mysql_config: command not found`

**해결책**:
```bash
# macOS
brew install mysql

# Ubuntu/Debian
sudo apt-get install libmysqlclient-dev
```

---

## 기여 및 라이선스

### 원본 출처

**GitHub**: [anson1788/stoneage](https://github.com/anson1788/stoneage)

이 프로젝트는 연구 및 학습 목적으로 제공됩니다.

### 목적 및 면책

- **목적**: 서버 개발 기술 연구 및 MMORPG 아키텍처 학습
- **비상업적 사용**: 상업적 이용 금지
- **교육 목적**: 게임 서버 개발 교육 및 기술 습득

### 기여 방법

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 연락처

**이메일 문의**: 데이터베이스 스키마 및 기술 지원

---

## 라이선스

**연구 및 학습 목적 전용** - 상업적 사용 금지

이 프로젝트는 석기시대 게임에 대한 향수와 서버 개발 기술 공유를 목적으로 합니다.

![Stone Age Nostalgia](http://img1.mydrivers.com/img/20160205/s_6b4d567fd95941759db8dc2b884c1975.jpg)

**© 2025 Stone Age 8.5 Community**
