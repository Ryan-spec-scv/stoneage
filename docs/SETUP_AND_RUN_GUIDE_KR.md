# Stone Age 2.5 Server 설치 및 실행 가이드

## 📋 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [개발 환경 설정 (macOS)](#개발-환경-설정-macos)
3. [프로덕션 환경 설정 (Linux)](#프로덕션-환경-설정-linux)
4. [클라이언트 실행 (Windows)](#클라이언트-실행-windows)
5. [전체 시스템 테스트](#전체-시스템-테스트)
6. [트러블슈팅](#트러블슈팅)

---

## 아키텍처 개요

### 시스템 구성

```
┌─────────────────────────────────────────────────────────────┐
│                      전체 시스템 구조                          │
└─────────────────────────────────────────────────────────────┘

Windows 클라이언트              Linux/macOS 서버
┌──────────────┐              ┌──────────────────────┐
│              │              │   SAAC (계정 서버)     │
│  StoneAge    │  ◄─────────►│   Port: 9300         │
│  Client      │   Login/     │   MySQL 연동          │
│  (.exe)      │   Auth       │                      │
│              │              └──────────────────────┘
│              │                        ▲
│              │                        │ IPC
│              │              ┌─────────▼────────────┐
│              │  ◄─────────► │   GMSV (게임 서버)    │
│              │   Game Data  │   Port: ?            │
│              │              │   게임 로직 처리       │
└──────────────┘              └──────────────────────┘
                                        │
                              ┌─────────▼────────────┐
                              │   MySQL Database     │
                              │   - 계정 정보         │
                              │   - 캐릭터 메타데이터  │
                              └──────────────────────┘
```

### 중요한 개념 정리

**🎮 Stone Age는 이미 완성된 상용 게임입니다**

```
┌──────────────────────────────────────────────────────────────┐
│ Stone Age = 완성된 MMORPG                                    │
├──────────────────────────────────────────────────────────────┤
│ • 2000년대 초반 일본/한국/중국에서 서비스                     │
│ • 게임 클라이언트는 완전히 개발되어 있음                      │
│ • 그래픽, UI, 캐릭터, NPC, 전투 시스템 모두 완성              │
│ • 이 저장소는 서버 소스코드만 제공                            │
└──────────────────────────────────────────────────────────────┘
```

**개발자가 할 일 vs 이미 완성된 것**

```
✅ 개발자가 할 일 (이 저장소)
  - 서버 소스코드 컴파일
  - 데이터베이스 설정
  - 서버 실행 및 운영
  - 클라이언트 다운로드 및 설정

❌ 개발할 필요 없는 것 (이미 완성됨)
  - 게임 그래픽/UI/사운드
  - 캐릭터 시스템/애니메이션
  - NPC/몬스터/맵 디자인
  - 게임 클라이언트 로직
```

### 플랫폼 제약사항

⚠️ **클라이언트는 Windows 전용**
- 클라이언트는 `.exe` 파일로만 배포됨
- 이미 완성된 게임 실행 파일
- Wine으로 macOS/Linux에서 실행 가능하나 불안정
- 개발/테스트는 Windows VM 또는 별도 Windows PC 필요
- 클라이언트는 별도 배포처에서 다운로드

✅ **서버는 Linux/macOS 지원**
- GMSV (게임 서버): Linux/macOS에서 컴파일 및 실행
- SAAC (계정 서버): Linux/macOS에서 컴파일 및 실행
- 이 저장소에서 소스코드 제공
- 프로덕션은 Linux 권장

---

## 개발 환경 설정 (macOS)

### 목적
- 로컬 macOS에서 서버 개발 및 디버깅
- 코드 수정 후 즉시 테스트
- 클라이언트는 별도 Windows 환경 필요

### 1. 필수 도구 설치

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 개발 도구 설치
brew install gcc make git mysql mysql-client

# 확인
gcc --version
make --version
mysql --version
```

---

### 2. MySQL 설정

**MySQL 서버 시작**:
```bash
# MySQL 서비스 시작
brew services start mysql

# 루트 비밀번호 설정 (처음 설치 시)
mysql_secure_installation
# - root 비밀번호 설정: your_password
# - anonymous user 제거: Y
# - 원격 root 로그인 금지: Y
# - test 데이터베이스 제거: Y
# - 권한 테이블 리로드: Y
```

**데이터베이스 및 사용자 생성**:
```bash
# MySQL 접속
mysql -u root -p
# 비밀번호 입력

# SQL 실행
CREATE DATABASE stoneage CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'saac'@'localhost' IDENTIFIED BY 'saac_password';
GRANT ALL PRIVILEGES ON stoneage.* TO 'saac'@'localhost';
FLUSH PRIVILEGES;

# 테이블 생성 (sasql.c 참고하여 스키마 작성)
USE stoneage;

-- 사용자 테이블
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    passwd VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_name (name)
);

-- 테스트 계정 생성
INSERT INTO users (name, passwd) VALUES ('testuser', 'testpass');

-- 확인
SELECT * FROM users;

exit;
```

---

### 3. 서버 빌드

**SAAC (계정 서버) 빌드**:

```bash
cd /Users/gwang/Desktop/StoneAge/stone-age-master/saac

# makefile 확인 및 수정 (macOS 환경)
# MySQL 경로를 mysql_config를 사용하도록 변경

# makefile 편집
vim makefile

# 다음 라인을 찾아 수정:
# MYSQL_CFLAGS=-I/usr/include/mysql
# MYSQL_LIBS=-L/usr/lib64/mysql -lmysqlclient

# 다음으로 변경:
# MYSQL_CFLAGS=$(shell mysql_config --cflags)
# MYSQL_LIBS=$(shell mysql_config --libs)

# 저장 후 빌드
make clean
make

# 빌드 성공 확인
ls -lh saac
# 출력 예시: -rwxr-xr-x  1 gwang  staff   245K Jan 22 10:00 saac
```

**GMSV (게임 서버) 빌드**:

```bash
cd /Users/gwang/Desktop/StoneAge/stone-age-master/gmsv

# makefile 수정 (SAAC과 동일)
vim makefile

# MySQL 경로 수정
# MYSQL_CFLAGS=$(shell mysql_config --cflags)
# MYSQL_LIBS=$(shell mysql_config --libs)

# 빌드
make clean
make

# 빌드 성공 확인
ls -lh gmsv
# 출력 예시: -rwxr-xr-x  1 gwang  staff   1.2M Jan 22 10:05 gmsv
```

---

### 4. 서버 설정 파일 수정

**SAAC 설정**:

```bash
cd /Users/gwang/Desktop/StoneAge/stone-age-master/saac

# 설정 파일 편집
vim saac.conf  # 또는 관련 설정 파일

# MySQL 접속 정보 설정
mysql_host=localhost
mysql_user=saac
mysql_password=saac_password
mysql_database=stoneage

# SAAC 포트 설정
port=9300
```

**GMSV 설정**:

```bash
cd /Users/gwang/Desktop/StoneAge/stone-age-master/gmsv

# setup.cf 편집
vim setup.cf

# SAAC 연결 정보 (중요!)
acserv=127.0.0.1        # SAAC IP (로컬)
acservport=9300         # SAAC 포트

# 게임 서버 포트
port=9400               # 클라이언트 접속 포트

# 최대 동시 접속자 수
fdnum=100               # 10 → 100으로 증가 권장

# 캐릭터 저장 주기 (초)
CharSaveinterval=300    # 24시간(86400) → 5분(300)으로 변경 권장

# 기타 중요 설정
charnum=10000           # 최대 캐릭터 수
itemnum=50000           # 최대 아이템 수
```

---

### 5. 서버 실행

**터미널 1: SAAC 실행**:

```bash
cd /Users/gwang/Desktop/StoneAge/stone-age-master/saac

# SAAC 실행 (포그라운드)
./saac

# 정상 실행 확인 (출력 예시)
# SAAC Server Starting...
# MySQL Connected: localhost
# Listening on port 9300
# Waiting for GMSV connection...
```

**터미널 2: GMSV 실행**:

```bash
cd /Users/gwang/Desktop/StoneAge/stone-age-master/gmsv

# GMSV 실행 (포그라운드)
./gmsv

# 정상 실행 확인 (출력 예시)
# GMSV Server Starting...
# Reading config file: setup.cf
# Connecting to SAAC at 127.0.0.1:9300...
# SAAC connection established
# Loading maps...
# Loading NPCs...
# Listening on port 9400
# Server ready!
```

**포트 확인**:

```bash
# 다른 터미널에서 포트 확인
netstat -an | grep LISTEN | grep -E "9300|9400"

# 출력 예시:
# tcp4       0      0  *.9300                 *.*                    LISTEN
# tcp4       0      0  *.9400                 *.*                    LISTEN
```

---

### 6. 개발 모드 실행 (디버깅)

**GDB로 디버깅**:

```bash
# GMSV를 GDB로 실행
cd /Users/gwang/Desktop/StoneAge/stone-age-master/gmsv

gdb ./gmsv

# GDB 명령어
(gdb) break main
(gdb) run
(gdb) continue
(gdb) print variable_name
(gdb) backtrace
```

**Valgrind로 메모리 체크**:

```bash
# Valgrind 설치
brew install valgrind

# 메모리 누수 탐지
valgrind --leak-check=full ./gmsv
```

---

## 프로덕션 환경 설정 (Linux)

### 목적
- 실제 서비스 운영
- 안정적인 24/7 운영
- 다수의 동시 접속자 지원

### 1. 서버 준비

**권장 스펙**:
- **OS**: Ubuntu Server 22.04 LTS
- **CPU**: 4 코어 이상
- **RAM**: 8GB 이상
- **디스크**: 100GB SSD
- **네트워크**: 고정 IP, 100Mbps 이상

**서버 접속**:

```bash
# SSH로 서버 접속
ssh root@your-server-ip

# 시스템 업데이트
apt update && apt upgrade -y
```

---

### 2. 필수 패키지 설치

```bash
# 개발 도구
apt install -y build-essential gcc make git vim

# MySQL 서버
apt install -y mysql-server mysql-client libmysqlclient-dev

# 모니터링 도구
apt install -y htop iftop nethogs

# 프로세스 관리
apt install -y supervisor screen tmux
```

---

### 3. MySQL 설정

**보안 설정**:

```bash
# MySQL 보안 설정
mysql_secure_installation

# 강력한 root 비밀번호 설정
# 원격 root 로그인 금지
# anonymous user 제거
```

**데이터베이스 생성**:

```bash
mysql -u root -p

CREATE DATABASE stoneage CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'saac'@'localhost' IDENTIFIED BY 'strong_password_here';
GRANT ALL PRIVILEGES ON stoneage.* TO 'saac'@'localhost';
FLUSH PRIVILEGES;

USE stoneage;

-- 테이블 생성 (스키마는 개발 환경과 동일)
-- ... (사용자, 캐릭터 테이블 등)

exit;
```

**MySQL 튜닝** (프로덕션용):

```bash
# /etc/mysql/mysql.conf.d/mysqld.cnf 편집
vim /etc/mysql/mysql.conf.d/mysqld.cnf

# 다음 설정 추가/수정
[mysqld]
max_connections = 500
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
query_cache_size = 128M

# MySQL 재시작
systemctl restart mysql
```

---

### 4. 프로젝트 배포

**Git으로 코드 가져오기**:

```bash
# 작업 디렉토리 생성
mkdir -p /opt/stoneage
cd /opt/stoneage

# Git 클론
git clone https://github.com/yourorg/stone-age-master.git
cd stone-age-master

# 빌드
cd saac
make clean && make

cd ../gmsv
make clean && make
```

---

### 5. 방화벽 설정

```bash
# UFW 방화벽 설정
ufw allow 22/tcp      # SSH
ufw allow 9300/tcp    # SAAC (내부 전용으로 제한 권장)
ufw allow 9400/tcp    # GMSV (클라이언트 접속)

# 방화벽 활성화
ufw enable

# 상태 확인
ufw status
```

**⚠️ 중요**: SAAC 포트(9300)는 GMSV와의 내부 통신용이므로 외부 접근 차단 권장

```bash
# SAAC 포트를 로컬호스트만 허용
ufw delete allow 9300/tcp
iptables -A INPUT -p tcp --dport 9300 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 9300 -j DROP
```

---

### 6. Supervisor로 자동 시작 설정

**Supervisor 설정 파일 생성**:

```bash
# SAAC 설정
cat > /etc/supervisor/conf.d/saac.conf << 'EOF'
[program:saac]
command=/opt/stoneage/stone-age-master/saac/saac
directory=/opt/stoneage/stone-age-master/saac
user=root
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/saac.err.log
stdout_logfile=/var/log/saac.out.log
EOF

# GMSV 설정
cat > /etc/supervisor/conf.d/gmsv.conf << 'EOF'
[program:gmsv]
command=/opt/stoneage/stone-age-master/gmsv/gmsv
directory=/opt/stoneage/stone-age-master/gmsv
user=root
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/gmsv.err.log
stdout_logfile=/var/log/gmsv.out.log
# SAAC 시작 후 5초 대기
startsecs=5
priority=100
EOF

# Supervisor 재로드
supervisorctl reread
supervisorctl update

# 서비스 시작
supervisorctl start saac
supervisorctl start gmsv

# 상태 확인
supervisorctl status
# 출력 예시:
# saac    RUNNING   pid 12345, uptime 0:00:10
# gmsv    RUNNING   pid 12346, uptime 0:00:05
```

---

### 7. 로그 모니터링

```bash
# 실시간 로그 확인
tail -f /var/log/saac.out.log
tail -f /var/log/gmsv.out.log

# 에러 로그 확인
tail -f /var/log/saac.err.log
tail -f /var/log/gmsv.err.log
```

---

### 8. 백업 설정

**일일 데이터베이스 백업**:

```bash
# 백업 스크립트 생성
cat > /opt/stoneage/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/stoneage/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 디렉토리 생성
mkdir -p $BACKUP_DIR

# MySQL 백업
mysqldump -u saac -p'strong_password_here' stoneage > $BACKUP_DIR/stoneage_$DATE.sql

# 캐릭터 데이터 백업
tar -czf $BACKUP_DIR/chardata_$DATE.tar.gz /opt/stoneage/stone-age-master/gmsv/chardata

# 7일 이상 된 백업 삭제
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/stoneage/backup.sh

# Cron에 등록 (매일 새벽 3시)
crontab -e

# 다음 라인 추가
0 3 * * * /opt/stoneage/backup.sh >> /var/log/backup.log 2>&1
```

---

## 클라이언트 실행 (Windows)

### 클라이언트 다운로드

**⚠️ 중요 개념 정리**:

```
┌─────────────────────────────────────────────────────────────────────┐
│ Stone Age는 이미 완성된 상용 MMORPG입니다                           │
├─────────────────────────────────────────────────────────────────────┤
│ ✅ 게임 클라이언트는 이미 완전히 개발되어 있음                       │
│    - 게임 그래픽, UI, 캐릭터, NPC, 몬스터 모두 포함                 │
│    - Windows 실행 파일 (.exe)로 배포                                │
│    - 처음부터 개발할 필요 없음                                       │
│                                                                     │
│ ❌ 이 GitHub 저장소에는 서버 소스코드만 포함                         │
│    - SAAC (계정 서버) 소스코드                                      │
│    - GMSV (게임 서버) 소스코드                                      │
│    - 클라이언트 실행 파일은 별도 배포                                │
└─────────────────────────────────────────────────────────────────────┘
```

**개발자가 해야 할 일**:

```
✅ 서버 컴파일 및 실행 (이 저장소)
✅ 클라이언트 다운로드 (별도 배포처)
✅ 클라이언트 설정 수정 (서버 IP 변경)
✅ 게임 실행 및 테스트

❌ 게임 그래픽/UI 개발 (이미 완성됨)
❌ 캐릭터 시스템 개발 (이미 완성됨)
❌ NPC/몬스터 개발 (이미 완성됨)
```

**클라이언트 구하는 방법**:

1. **원본 저장소 관리자의 클라이언트**:
   - README.md 참고: "下载的客户端默认连接我的石器时代服务器"
   - 원작자가 제공하는 클라이언트 활용

2. **사설 서버 커뮤니티**:
   - 중국/대만 석기시대 사설 서버 커뮤니티
   - 일본/한국 석기시대 커뮤니티
   - "石器時代 2.5 客户端" 검색

3. **개인 보관 버전**:
   - 과거에 석기시대를 플레이했던 사용자들이 보관한 클라이언트
   - 석기시대 애호가 커뮤니티에서 공유

---

### Windows 환경 준비

**방법 1: Windows PC 사용**
- Windows 7 이상
- 최소 RAM 2GB
- 네트워크: 서버 접속 가능한 환경

**방법 2: Windows VM (개발용)**
```bash
# macOS에서 Parallels 또는 VirtualBox 사용
# Windows 10 VM 설치
# 최소 할당: CPU 2코어, RAM 4GB
```

---

### 클라이언트 설정

**서버 주소 변경**:

클라이언트는 기본적으로 특정 서버에 연결되도록 하드코딩되어 있을 수 있습니다.

**설정 파일 수정** (클라이언트 폴더 내):

```
# 예상 파일명: config.ini, server.ini, stoneage.ini 등
[Server]
IP=your-server-ip        # 개발: 127.0.0.1 또는 macOS IP
Port=9400                # GMSV 포트

[Account]
IP=your-server-ip        # SAAC는 보통 GMSV를 통해 접근
Port=9300
```

**⚠️ 주의**:
- 클라이언트 설정 방법은 클라이언트 버전에 따라 다를 수 있음
- 일부 클라이언트는 바이너리 패치가 필요할 수 있음
- Hex Editor로 실행 파일 내 IP 주소를 직접 수정해야 할 수도 있음

---

### 클라이언트 실행

**1. 로컬 테스트 (macOS 서버 + Windows 클라이언트)**:

```
macOS (서버):
1. SAAC 실행: ./saac
2. GMSV 실행: ./gmsv
3. macOS IP 확인: ifconfig | grep "inet "
   예시: 192.168.1.100

Windows (클라이언트):
1. 클라이언트 설정에서 서버 IP를 192.168.1.100으로 변경
2. StoneAge.exe 실행
3. 로그인 (testuser / testpass)
```

**2. 프로덕션 테스트 (Linux 서버 + Windows 클라이언트)**:

```
Linux 서버:
1. Supervisor로 SAAC, GMSV 자동 실행 중
2. 공인 IP: xxx.xxx.xxx.xxx

Windows 클라이언트:
1. 서버 IP를 공인 IP로 설정
2. 포트: 9400 (GMSV)
3. StoneAge.exe 실행
```

---

### 네트워크 연결 확인

**Windows에서 서버 연결 테스트**:

```cmd
# 명령 프롬프트 (cmd) 실행

# 핑 테스트
ping your-server-ip

# 포트 테스트 (telnet)
telnet your-server-ip 9400

# PowerShell에서
Test-NetConnection -ComputerName your-server-ip -Port 9400
```

---

## 전체 시스템 테스트

### 테스트 시나리오

**1. 로그인 테스트**:
```
클라이언트 실행 → 계정 입력 → 로그인 버튼 클릭
→ SAAC에서 인증 → GMSV로 리다이렉트 → 게임 월드 진입
```

**서버 로그 확인**:
```bash
# SAAC 로그
tail -f /var/log/saac.out.log
# 출력 예시:
# [2025-01-22 10:30:15] Client connected: 192.168.1.200
# [2025-01-22 10:30:16] Login request: testuser
# [2025-01-22 10:30:16] Authentication successful: testuser
# [2025-01-22 10:30:16] Redirect to GMSV

# GMSV 로그
tail -f /var/log/gmsv.out.log
# 출력 예시:
# [2025-01-22 10:30:17] New client connection
# [2025-01-22 10:30:17] Character loaded: testuser
# [2025-01-22 10:30:17] Player entered world: Map 1000, Pos (100, 100)
```

---

**2. 캐릭터 생성 테스트**:
```
게임 진입 → 캐릭터 생성 → 이름 입력 → 스탯 배분
→ 생성 완료 → chardata/ 폴더에 파일 저장 확인
```

**확인**:
```bash
# 캐릭터 데이터 파일 확인
ls -lh /opt/stoneage/stone-age-master/gmsv/chardata/t/testuser
```

---

**3. 기본 게임플레이 테스트**:
```
- 캐릭터 이동
- NPC와 대화
- 아이템 획득
- 전투 시스템
- 파티 구성
```

---

**4. 동시 접속 테스트**:
```
여러 클라이언트로 동시 접속하여 서버 안정성 확인
```

---

### 성능 모니터링

**서버 리소스 확인**:

```bash
# CPU 사용률
htop

# 메모리 사용량
free -h

# 네트워크 트래픽
iftop

# 프로세스별 네트워크 사용
nethogs

# 디스크 I/O
iostat -x 1
```

---

**MySQL 상태 확인**:

```bash
mysql -u root -p

SHOW PROCESSLIST;
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Queries';

exit;
```

---

## 트러블슈팅

### 1. 서버가 시작되지 않음

**증상**: `./gmsv` 실행 시 즉시 종료

**원인 및 해결**:

```bash
# 1. MySQL 연결 실패
# 확인
mysql -u saac -p
# 비밀번호가 맞는지 확인

# 2. 포트가 이미 사용 중
lsof -i :9400
# 다른 프로세스가 사용 중이면 종료

# 3. 설정 파일 오류
# setup.cf 확인
cat gmsv/setup.cf | grep -E "acserv|port"

# 4. 라이브러리 누락
ldd ./gmsv
# libmysqlclient.so가 있는지 확인
```

---

### 2. 클라이언트가 서버에 연결되지 않음

**증상**: "서버에 연결할 수 없습니다" 오류

**원인 및 해결**:

```bash
# 1. 방화벽 차단
# 서버에서
ufw status
ufw allow 9400/tcp

# 2. 서버가 실행 중이 아님
supervisorctl status
# 또는
ps aux | grep gmsv

# 3. 네트워크 문제
# 클라이언트 PC에서
ping server-ip
telnet server-ip 9400

# 4. 잘못된 서버 주소
# 클라이언트 설정 파일 확인
```

---

### 3. 로그인 실패

**증상**: 계정/비밀번호 입력 후 로그인 실패

**원인 및 해결**:

```bash
# 1. 데이터베이스에 계정 없음
mysql -u saac -p
USE stoneage;
SELECT * FROM users WHERE name='testuser';

# 없으면 생성
INSERT INTO users (name, passwd) VALUES ('testuser', 'testpass');

# 2. SAAC와 GMSV 연결 실패
# GMSV 로그 확인
tail -f /var/log/gmsv.err.log
# "SAAC connection failed" 메시지 확인

# SAAC 재시작
supervisorctl restart saac
sleep 3
supervisorctl restart gmsv
```

---

### 4. 캐릭터 데이터가 저장되지 않음

**증상**: 재접속 시 캐릭터 정보 초기화

**원인 및 해결**:

```bash
# 1. chardata 디렉토리 권한 문제
ls -ld gmsv/chardata
chmod -R 755 gmsv/chardata

# 2. 디스크 공간 부족
df -h

# 3. 저장 주기가 너무 김
# setup.cf 확인
grep CharSaveinterval gmsv/setup.cf
# 86400 (24시간) → 300 (5분)으로 변경

# 4. 수동 저장 테스트
# 게임 내 명령어 또는 서버 강제 저장
```

---

### 5. 서버 크래시

**증상**: Segmentation fault, 서버 종료

**디버깅**:

```bash
# 1. 코어 덤프 활성화
ulimit -c unlimited

# 2. GDB로 크래시 분석
./gmsv
# 크래시 발생 시 core 파일 생성

gdb ./gmsv core
(gdb) backtrace
(gdb) frame 0
(gdb) print variable_name

# 3. Valgrind로 메모리 오류 탐지
valgrind --leak-check=full ./gmsv

# 4. 로그 분석
tail -100 /var/log/gmsv.err.log
```

---

### 6. macOS 빌드 오류

**증상**: `mysql.h: No such file or directory`

**해결**:

```bash
# MySQL 경로 확인
mysql_config --cflags
mysql_config --libs

# makefile 수정
cd gmsv
vim makefile

# 다음으로 변경:
MYSQL_CFLAGS=$(shell mysql_config --cflags)
MYSQL_LIBS=$(shell mysql_config --libs)

# 재빌드
make clean
make
```

---

## 추가 팁

### 개발 워크플로우

**1. 로컬 개발 (macOS)**:
```
코드 수정 → 빌드 → 로컬 서버 실행 → Windows VM으로 테스트
```

**2. 프로덕션 배포**:
```
Git에 푸시 → Linux 서버에서 pull → 빌드 → Supervisor 재시작
```

---

### 성능 튜닝

**동시 접속자 100명 이상 지원**:

```bash
# 1. setup.cf 수정
fdnum=500
charnum=20000
itemnum=100000

# 2. 시스템 리소스 증설
# CPU: 4코어 → 8코어
# RAM: 8GB → 16GB

# 3. MySQL 최적화
# innodb_buffer_pool_size = 4G

# 4. 수평 확장 (다중 서버)
# GMSV 인스턴스 여러 개 실행
# 로드 밸런서 (HAProxy) 설정
```

---

### 보안 강화

```bash
# 1. 방화벽 강화
# SAAC 포트 외부 차단
iptables -A INPUT -p tcp --dport 9300 ! -s 127.0.0.1 -j DROP

# 2. DDoS 방지
# fail2ban 설정
apt install fail2ban

# 3. SSL/TLS 적용 (선택사항)
# 클라이언트-서버 암호화 통신
```

---

## 결론

이제 다음 환경에서 Stone Age 2.5 Server를 실행할 수 있습니다:

✅ **개발 환경 (macOS)**:
- 서버: macOS에서 빌드 및 실행
- 클라이언트: Windows VM 또는 별도 PC

✅ **프로덕션 환경 (Linux)**:
- 서버: Ubuntu Server에서 24/7 운영
- 클라이언트: Windows PC에서 접속

✅ **테스트**:
- 로그인, 캐릭터 생성, 게임플레이 확인
- 성능 모니터링 및 최적화

---

**문서 버전**: 1.0
**최종 업데이트**: 2025-01-22
**작성자**: Claude Code SuperClaude
