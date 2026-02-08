# 석기시대 2.5 서버 - 종합 문서

## 📋 목차

- [프로젝트 개요](#프로젝트-개요)
- [시스템 요구사항](#시스템-요구사항)
- [빠른 시작 가이드](#빠른-시작-가이드)
- [아키텍처 개요](#아키텍처-개요)
- [빌드 가이드](#빌드-가이드)
- [설치 및 구성](#설치-및-구성)
- [운영 가이드](#운영-가이드)
- [보안 가이드](#보안-가이드)
- [문제 해결](#문제-해결)
- [개발자 가이드](#개발자-가이드)

---

## 프로젝트 개요

**석기시대 2.5 서버**는 2016년에 개발된 대규모 다중 사용자 온라인 롤플레잉 게임(MMORPG) 서버 구현체입니다. 약 148,000줄의 C 코드로 작성되었으며, 게임 세계 시뮬레이션, 플레이어 인증, 전투 시스템, NPC 관리 등 완전한 MMORPG 백엔드 기능을 제공합니다.

### 주요 특징

- ✅ **완전한 MMORPG 구현**: 전투, 퀘스트, NPC, 아이템, 파티 시스템 등
- ✅ **듀얼 서버 아키텍처**: 게임 로직(GMSV)과 인증(SAAC) 분리
- ✅ **확장 가능한 구조**: 모듈식 서브시스템 설계
- ✅ **방대한 설정 옵션**: 522줄의 설정 파일로 게임 밸런스 조정 가능
- ⚠️ **레거시 코드베이스**: 2016년 코드, 현대화 필요

### 기술 스택

| 구성 요소 | 기술 |
|---------|------|
| **언어** | C (ANSI C + GNU 확장) |
| **데이터베이스** | MySQL 9.4+ |
| **빌드 시스템** | GNU Make 3.81+ |
| **컴파일러** | GCC 또는 Clang |
| **플랫폼** | Linux (주), macOS (개발 가능) |
| **네트워크** | TCP/IP, 사용자 정의 바이너리 프로토콜 |

### 프로젝트 구조

```
stone-age-master/
├── gmsv/              # 게임 서버 (135,019 LOC)
│   ├── battle/        # 전투 시스템
│   ├── char/          # 캐릭터 시스템
│   ├── magic/         # 마법 시스템
│   ├── item/          # 아이템 시스템
│   ├── map/           # 맵 시스템
│   ├── npc/           # NPC 시스템 (73개 파일)
│   └── include/       # 헤더 파일 (132개)
│
├── saac/              # 계정 서버 (13,449 LOC)
│   ├── char/          # 캐릭터 영속성
│   ├── mail/          # 메일 시스템
│   └── db/            # 데이터베이스 계층
│
└── README.md          # 영문 문서
```

---

## 시스템 요구사항

### 최소 요구사항

#### 하드웨어
- **CPU**: 1 코어 (단일 스레드 아키텍처)
- **RAM**: 512 MB (기본 설정 기준 305 MB)
- **디스크**: 100 MB (바이너리) + 1 GB (데이터)
- **네트워크**: 10 Mbps 업링크

#### 소프트웨어
- **운영체제**: Linux (Ubuntu 20.04+, CentOS 7+, Debian 10+)
- **GCC**: 7.0 이상 또는 Clang 10.0 이상
- **GNU Make**: 3.81 이상
- **MySQL**: 5.7 이상 (9.4 권장)
- **libmysqlclient-dev**: MySQL 클라이언트 라이브러리

### 권장 사양

#### 하드웨어
- **CPU**: 2+ 코어 (여러 서버 인스턴스 실행 시)
- **RAM**: 2 GB
- **디스크**: SSD (캐릭터 데이터 I/O 성능 향상)
- **네트워크**: 100 Mbps 전용 연결

#### 소프트웨어
- **운영체제**: Ubuntu Server 22.04 LTS
- **데이터베이스**: MySQL 9.4+ (성능 최적화)
- **모니터링**: htop, iftop, mysql-workbench

### 플랫폼별 고려사항

#### Linux (프로덕션 권장)
✅ 네이티브 지원
✅ 최적의 성능
✅ 모든 기능 정상 작동

#### macOS (개발 전용)
⚠️ MySQL 경로 수정 필요
⚠️ 크로스 플랫폼 이슈 가능
✅ 로컬 개발 및 테스트 가능

#### Windows
❌ 네이티브 미지원
⚠️ WSL2 사용 가능 (Linux 가상화)

---

## 빠른 시작 가이드

### 1. 저장소 클론

```bash
git clone https://github.com/yourusername/stone-age-master.git
cd stone-age-master
```

### 2. 의존성 설치

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y gcc make libmysqlclient-dev
```

#### CentOS/RHEL
```bash
sudo yum install -y gcc make mysql-devel
```

#### macOS
```bash
brew install mysql gcc make
```

### 3. MySQL 데이터베이스 설정

```bash
# MySQL 접속
mysql -u root -p

# 데이터베이스 생성
CREATE DATABASE stoneage CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 사용자 생성 및 권한 부여
CREATE USER 'saac'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON stoneage.* TO 'saac'@'localhost';
FLUSH PRIVILEGES;

# 테이블 생성 (예시 - sasql.c 참조하여 실제 스키마 작성)
USE stoneage;
CREATE TABLE users (
    name VARCHAR(24) BINARY NOT NULL PRIMARY KEY,
    password VARCHAR(64) NOT NULL,
    RegTime DATETIME NOT NULL,
    Path VARCHAR(255) NOT NULL
);

CREATE TABLE user_lock (
    name VARCHAR(48) BINARY NOT NULL PRIMARY KEY,
    reason VARCHAR(255),
    lock_time DATETIME
);
```

### 4. 설정 파일 편집

#### GMSV 설정 (gmsv/setup.cf)
```ini
# 계정 서버 정보
acserv=127.0.0.1
acservport=9300
acpasswd=your_saac_password

# 게임 서버 정보
gameservname=석기시대 서버
gameservid=server1
port=9065

# 최대 동시 접속자 수
fdnum=10

# 캐릭터 저장 간격 (초) - 기본 24시간은 너무 길어서 300초(5분) 권장
CharSaveinterval=300
```

#### SAAC 설정 (saac/acserv.cf)
```ini
# MySQL 설정
sql_IP=127.0.0.1
sql_Port=3306
sql_ID=saac
sql_PS=your_password_here
sql_DataBase=stoneage
sql_Table=users
sql_LOCK=user_lock
sql_NAME=name
sql_PASS=password

# 자동 회원가입 (0=비활성, 1=활성)
AutoReg=1
```

### 5. 빌드 실행

```bash
# SAAC makefile 수정 (macOS의 경우)
# saac/makefile:28 라인을 다음과 같이 수정:
# MYSQL= $(shell mysql_config --libs)

# GMSV 빌드
cd gmsv
make clean
make -j$(nproc)
cd ..

# SAAC 빌드
cd saac
make clean
make MYSQL="$(mysql_config --libs 2>/dev/null || echo '-lmysqlclient')"
cd ..
```

### 6. 서버 실행

```bash
# 터미널 1: SAAC 실행
cd saac
./saacjt.exe

# 터미널 2: GMSV 실행
cd gmsv
./gmsvjt.exe
```

### 7. 서버 상태 확인

```bash
# 프로세스 확인
ps aux | grep -E 'saac|gmsv'

# 포트 확인
netstat -tuln | grep -E '9065|9300'

# 로그 확인
tail -f gmsv/log/*.log
tail -f saac/log/*.log
```

---

## 아키텍처 개요

### 시스템 아키텍처

석기시대 서버는 **서비스 지향 아키텍처(SOA)**를 채택하여 두 개의 독립적인 서버 프로세스로 구성됩니다.

```
┌─────────────────────────────────────────────────────────┐
│                   클라이언트 계층                          │
│          (석기시대 게임 클라이언트 - LSS 프로토콜)          │
└────────────────────┬────────────────────────────────────┘
                     │ TCP 9065
                     ▼
┌─────────────────────────────────────────────────────────┐
│            GMSV (게임 서버) - 135,019 LOC                │
├─────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  전투    │  │ 캐릭터   │  │   NPC    │  │  마법   │ │
│  │ 시스템   │  │ 시스템   │  │  시스템  │  │ 시스템  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
│  ┌──────────┐  ┌──────────┐                             │
│  │ 아이템   │  │   맵     │                             │
│  │ 시스템   │  │ 시스템   │                             │
│  └──────────┘  └──────────┘                             │
│                                                          │
│  이벤트 루프: select() + 단일 스레드 처리                 │
└────────────────────┬────────────────────────────────────┘
                     │ SAAC 프로토콜 (TCP 9300)
                     ▼
┌─────────────────────────────────────────────────────────┐
│          SAAC (계정 서버) - 13,449 LOC                    │
├─────────────────────────────────────────────────────────┤
│   인증 시스템  │  캐릭터 영속성  │  메일 시스템          │
└────────────────┬──────────────┬──────────────────────────┘
                 │              │
          ┌──────▼──────┐  ┌───▼────────┐
          │    MySQL    │  │ 파일 시스템 │
          │  데이터베이스│  │ (캐릭터)   │
          └─────────────┘  └────────────┘
```

### 핵심 설계 결정

#### 1. 듀얼 서버 분리

**왜 두 개의 서버로 분리했는가?**

- **보안 강화**: 게임 로직 취약점이 계정 DB에 직접 접근 불가
- **확장성**: 여러 GMSV 인스턴스가 하나의 SAAC 공유 가능
- **안정성**: GMSV 재시작 시 플레이어 로그아웃 불필요
- **역할 분리**:
  - SAAC = "누구인가" (인증, 계정 관리)
  - GMSV = "무엇을 하는가" (게임 로직, 전투, NPC)

#### 2. 단일 스레드 이벤트 루프

**왜 멀티스레딩을 사용하지 않았는가?**

**장점**:
- ✅ 경쟁 조건 없음 (race condition 불가)
- ✅ 디버깅 단순화
- ✅ 예측 가능한 성능
- ✅ 락(lock) 관리 불필요

**단점**:
- ❌ 다중 CPU 코어 활용 불가
- ❌ 플레이어 수에 따른 선형적 성능 저하
- ❌ 하드 캡 존재 (~10명 동시 접속)

**설계 철학**: 수직 확장(더 많은 플레이어)보다 수평 확장(더 많은 서버 인스턴스) 선호

#### 3. 하이브리드 영속성 모델

| 저장소 | 용도 | 장점 | 단점 |
|-------|-----|-----|-----|
| **MySQL** | 계정 정보, 비밀번호, 로그 | ACID 보장, 관계형 쿼리 | 느린 대용량 데이터 |
| **파일 시스템** | 캐릭터 데이터, 인벤토리 | 빠른 읽기/쓰기, 유연한 포맷 | 트랜잭션 없음, 손상 위험 |

### 이벤트 루프 상세

```c
// gmsv/main.c의 핵심 루프
void mainloop(void) {
    while(1) {
        // CPU 스로틀링 (부하 제어)
        if (getCpuUse() != -1) {
            usleep(1);  // 1 마이크로초 대기
        }

        // 게임 서브시스템 순차 처리
        netloop_faster();      // 네트워크 I/O
        NPC_generateLoop(0);   // NPC AI 업데이트
        BATTLE_Loop();         // 전투 처리
        CHAR_Loop();           // 캐릭터 업데이트
        PETMAIL_proc();        // 메일 시스템
        family_proc();         // 가문/길드 시스템
        chardatasavecheck();   // 주기적 저장
    }
}
```

**성능 특성**:
- 목표 루프 시간: 5ms (초당 200회)
- 각 서브시스템 할당 시간: ~500μs
- 10명의 플레이어 처리: 각 플레이어당 초당 200회 업데이트

---

## 빌드 가이드

### 빌드 전 체크리스트

- [ ] GCC 또는 Clang 설치 확인
- [ ] GNU Make 설치 확인
- [ ] MySQL 클라이언트 라이브러리 설치 확인
- [ ] Perl 설치 확인 (프로토콜 생성용)
- [ ] 디스크 여유 공간 1GB 이상

### 상세 빌드 프로세스

#### 1. 환경 변수 설정 (선택사항)

```bash
# CPU 최적화 (Intel Pentium 4)
export CFLAGS="-march=pentium4 -O3 -pipe -fomit-frame-pointer"

# CPU 최적화 (AMD Athlon XP)
export CFLAGS="-march=athlon-xp -O3 -pipe -fomit-frame-pointer"

# CPU 최적화 (현대 프로세서 - 권장)
export CFLAGS="-march=native -O3 -pipe -fomit-frame-pointer"
```

#### 2. GMSV 빌드

```bash
cd gmsv

# 이전 빌드 아티팩트 제거
make clean

# 서브시스템별 빌드 (자동으로 수행됨)
# - char/libchar.a (캐릭터 시스템)
# - npc/libnpc.a (NPC 시스템)
# - map/libmap.a (맵 시스템)
# - item/libitem.a (아이템 시스템)
# - magic/libmagic.a (마법 시스템)
# - battle/libbattle.a (전투 시스템)

# 병렬 빌드 (권장 - 빌드 시간 3-5배 단축)
make -j$(nproc)

# 단일 스레드 빌드 (디버깅 시)
make

# 빌드 성공 확인
ls -lh gmsvjt.exe
```

#### 3. SAAC 빌드

**중요**: macOS 사용 시 MySQL 경로 수정 필수!

```bash
cd saac

# macOS: saac/makefile:28 라인 수정
# 변경 전: MYSQL= -lz -L/usr/lib64/mysql -lmysqlclient
# 변경 후: MYSQL= $(shell mysql_config --libs)

# 또는 명령줄에서 직접 지정
make clean
make MYSQL="$(mysql_config --libs)"

# 빌드 성공 확인
ls -lh saacjt.exe
```

#### 4. 빌드 검증

```bash
# 바이너리 타입 확인 (Linux)
file gmsv/gmsvjt.exe saac/saacjt.exe

# 예상 출력:
# gmsvjt.exe: ELF 64-bit LSB executable, x86-64
# saacjt.exe: ELF 64-bit LSB executable, x86-64

# 라이브러리 의존성 확인 (Linux)
ldd gmsv/gmsvjt.exe
ldd saac/saacjt.exe

# macOS의 경우
otool -L gmsv/gmsvjt.exe
otool -L saac/saacjt.exe

# MySQL 링크 확인
ldd saac/saacjt.exe | grep mysql
# 예상 출력: libmysqlclient.so.21 => ...
```

### 빌드 최적화

#### 개발 빌드 (디버깅 정보 포함)

```bash
make clean
make CFLAGS="-O0 -g3 -Wall -Wextra"
```

#### 프로덕션 빌드 (최적화 + 스트립)

```bash
make clean
make CFLAGS="-O3 -march=native -DNDEBUG"
strip gmsv/gmsvjt.exe saac/saacjt.exe
```

#### 보안 강화 빌드

```bash
make CFLAGS="-O2 -D_FORTIFY_SOURCE=2 -fstack-protector-strong \
             -Wformat -Wformat-security -fPIE -pie"
```

### 빌드 문제 해결

#### 문제: "mysql.h: No such file or directory"

**원인**: MySQL 헤더 파일 미설치

**해결**:
```bash
# Ubuntu/Debian
sudo apt-get install libmysqlclient-dev

# CentOS/RHEL
sudo yum install mysql-devel

# macOS
brew install mysql
```

#### 문제: "undefined reference to `pthread_create`"

**원인**: pthread 라이브러리 링크 누락

**해결**: `gmsv/makefile:73`에 `-lpthread` 이미 포함되어 있음. Clean build 시도.

#### 문제: 컴파일 경고 폭주

**원인**: `-w` 플래그가 모든 경고 억제

**해결**:
```bash
# 경고 활성화하여 재빌드 (권장)
make CFLAGS="-O3 -Wall -Wextra -Wno-unused-parameter"
```

---

## 설치 및 구성

### 디렉토리 구조 설정

```bash
# 서버 루트 디렉토리 생성
sudo mkdir -p /opt/stone-age
sudo chown $USER:$USER /opt/stone-age

# 서버 파일 복사
cp -r gmsv saac /opt/stone-age/

# 데이터 디렉토리 생성
mkdir -p /opt/stone-age/saac/char
mkdir -p /opt/stone-age/saac/mail
mkdir -p /opt/stone-age/gmsv/log
mkdir -p /opt/stone-age/saac/log

# 권한 설정
chmod 755 /opt/stone-age/gmsv/gmsvjt.exe
chmod 755 /opt/stone-age/saac/saacjt.exe
chmod 700 /opt/stone-age/saac/char  # 캐릭터 데이터 보호
```

### 설정 파일 상세

#### GMSV 설정 (gmsv/setup.cf)

**필수 설정 항목**:

```ini
# ==================== 네트워크 설정 ====================
# SAAC 서버 주소
acserv=127.0.0.1
acservport=9300
acpasswd=강력한_비밀번호_입력

# GMSV 서버 설정
gameservname=나의_서버_이름
gameservid=server1
port=9065

# ==================== 성능 설정 ====================
# 최대 동시 접속자 수 (기본: 10)
fdnum=50

# 최대 펫 수
petnum=500

# 최대 캐릭터 수 (NPC 포함)
othercharnum=10000

# ==================== 데이터 영속성 ====================
# 캐릭터 저장 간격 (초)
# 기본값 86400 (24시간)은 매우 위험!
# 권장값: 300 (5분) ~ 600 (10분)
CharSaveinterval=300

# 캐릭터 데이터 디렉토리
storedir=../saac/char

# ==================== 게임 밸런스 ====================
# 전투 경험치 배율 (기본: 300배)
battleexp=300

# 전투 후 골드 획득 (레벨 × 배수)
BATTLEGOLD=10

# 시작 레벨
LV=1

# 시작 골드
GOLD=1000000

# ==================== 보안 설정 ====================
# GM 비밀번호
chatmagicpasswd=매우_강력한_GM_비밀번호

# 같은 IP 동시 접속 제한 (0=무제한)
SAMEIPLOGIN=3

# 금지된 IP 목록 파일
LOCKIP=lockip.txt
```

#### SAAC 설정 (saac/acserv.cf)

```ini
# ==================== MySQL 데이터베이스 ====================
sql_IP=127.0.0.1
sql_Port=3306
sql_ID=saac_user
sql_PS=강력한_DB_비밀번호
sql_DataBase=stoneage
sql_Table=users
sql_LOCK=user_lock
sql_NAME=name
sql_PASS=password

# ==================== 기능 설정 ====================
# 자동 회원가입 활성화 (0=비활성, 1=활성)
AutoReg=0
```

### 방화벽 설정

```bash
# UFW (Ubuntu)
sudo ufw allow 9065/tcp comment 'Stone Age GMSV'
sudo ufw allow 9300/tcp comment 'Stone Age SAAC'
sudo ufw enable

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=9065/tcp
sudo firewall-cmd --permanent --add-port=9300/tcp
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 9065 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9300 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

---

## 운영 가이드

### 서버 시작

#### 수동 시작

```bash
# 터미널 1: SAAC 시작
cd /opt/stone-age/saac
./saacjt.exe

# 터미널 2: GMSV 시작 (SAAC 시작 후)
cd /opt/stone-age/gmsv
./gmsvjt.exe
```

#### systemd 서비스 등록 (권장)

```bash
# SAAC 서비스 파일 생성
sudo tee /etc/systemd/system/stone-age-saac.service <<EOF
[Unit]
Description=Stone Age SAAC Server
After=network.target mysql.service

[Service]
Type=simple
User=stoneage
WorkingDirectory=/opt/stone-age/saac
ExecStart=/opt/stone-age/saac/saacjt.exe
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# GMSV 서비스 파일 생성
sudo tee /etc/systemd/system/stone-age-gmsv.service <<EOF
[Unit]
Description=Stone Age GMSV Server
After=network.target stone-age-saac.service

[Service]
Type=simple
User=stoneage
WorkingDirectory=/opt/stone-age/gmsv
ExecStart=/opt/stone-age/gmsv/gmsvjt.exe
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 서비스 활성화 및 시작
sudo systemctl daemon-reload
sudo systemctl enable stone-age-saac stone-age-gmsv
sudo systemctl start stone-age-saac
sleep 5  # SAAC 초기화 대기
sudo systemctl start stone-age-gmsv

# 상태 확인
sudo systemctl status stone-age-saac
sudo systemctl status stone-age-gmsv
```

### 모니터링

#### 프로세스 모니터링

```bash
# 프로세스 상태 확인
ps aux | grep -E 'saac|gmsv'

# CPU 및 메모리 사용량
top -p $(pgrep -d',' -f 'saacjt|gmsvjt')

# 자세한 리소스 사용량
htop -p $(pgrep -d',' -f 'saacjt|gmsvjt')
```

#### 네트워크 모니터링

```bash
# 연결 상태 확인
netstat -tuln | grep -E '9065|9300'

# 활성 연결 수
netstat -an | grep -E ':9065|:9300' | grep ESTABLISHED | wc -l

# 네트워크 트래픽
iftop -f "port 9065 or port 9300"
```

#### 로그 모니터링

```bash
# 실시간 로그 확인
tail -f /opt/stone-age/gmsv/log/*.log
tail -f /opt/stone-age/saac/log/*.log

# 에러 로그 필터링
tail -f /opt/stone-age/gmsv/log/*.log | grep -i error

# 로그 파일 크기 확인
du -sh /opt/stone-age/*/log/
```

### 백업 전략

#### 자동 백업 스크립트

```bash
#!/bin/bash
# /opt/stone-age/scripts/backup.sh

BACKUP_DIR="/backup/stone-age"
DATE=$(date +%Y%m%d_%H%M%S)

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR/$DATE

# 캐릭터 데이터 백업
echo "Backing up character data..."
tar czf $BACKUP_DIR/$DATE/char_data.tar.gz /opt/stone-age/saac/char/

# 데이터베이스 백업
echo "Backing up MySQL database..."
mysqldump -u saac_user -p'DB비밀번호' stoneage > $BACKUP_DIR/$DATE/database.sql

# 설정 파일 백업
echo "Backing up configuration files..."
cp /opt/stone-age/gmsv/setup.cf $BACKUP_DIR/$DATE/
cp /opt/stone-age/saac/acserv.cf $BACKUP_DIR/$DATE/

# 로그 파일 백업
echo "Backing up logs..."
tar czf $BACKUP_DIR/$DATE/logs.tar.gz /opt/stone-age/*/log/

# 오래된 백업 삭제 (30일 이상)
find $BACKUP_DIR -type d -mtime +30 -exec rm -rf {} \;

echo "Backup completed: $BACKUP_DIR/$DATE"
```

#### Cron 작업 설정

```bash
# crontab 편집
crontab -e

# 매일 오전 3시 백업
0 3 * * * /opt/stone-age/scripts/backup.sh >> /var/log/stone-age-backup.log 2>&1

# 매시간 증분 백업 (캐릭터 데이터만)
0 * * * * tar czf /backup/stone-age/hourly/char_$(date +\%H).tar.gz /opt/stone-age/saac/char/
```

### 서버 재시작

```bash
# Graceful shutdown (플레이어에게 알림 후 종료)
# TODO: 구현 필요 - 현재는 즉시 종료만 가능

# GMSV 재시작
sudo systemctl restart stone-age-gmsv

# SAAC 재시작 (주의: 모든 플레이어 연결 끊김)
sudo systemctl restart stone-age-saac
sleep 5
sudo systemctl restart stone-age-gmsv

# 전체 재시작
sudo systemctl restart stone-age-saac stone-age-gmsv
```

---

## 보안 가이드

### 🚨 알려진 보안 취약점

이 서버는 2016년 코드로, **심각한 보안 취약점**이 존재합니다. 프로덕션 환경에서 사용 전 필수 수정 필요!

#### 1. SQL 인젝션 (CRITICAL - 치명적)

**위치**: `saac/sasql.c:146`

**취약한 코드**:
```c
sprintf(sqlstr, "select * from %s where %s=BINARY'%s'",
        config.sql_Table, config.sql_NAME, nm);
```

**공격 예시**:
```
사용자명: admin' OR '1'='1' --
생성된 쿼리: SELECT * FROM users WHERE name=BINARY'admin' OR '1'='1' --'
결과: 인증 우회!
```

**수정 방법**:
```c
// 파라미터화된 쿼리 사용
MYSQL_STMT *stmt = mysql_stmt_init(&mysql);
const char *query = "SELECT * FROM users WHERE name=?";
mysql_stmt_prepare(stmt, query, strlen(query));

MYSQL_BIND bind[1];
memset(bind, 0, sizeof(bind));
bind[0].buffer_type = MYSQL_TYPE_STRING;
bind[0].buffer = username;
bind[0].buffer_length = strlen(username);

mysql_stmt_bind_param(stmt, bind);
mysql_stmt_execute(stmt);
```

#### 2. 평문 비밀번호 저장 (CRITICAL - 치명적)

**위치**: `saac/sasql.c:155`

**취약한 코드**:
```c
if (strcmp(pas, mysql_row[1]) == 0) {
    return 1;  // 평문 비밀번호 직접 비교!
}
```

**수정 방법**:
```c
// bcrypt 해시 사용
#include <bcrypt.h>

// 회원가입 시
char hash[BCRYPT_HASHSIZE];
bcrypt_hashpw(password, bcrypt_gensalt(12), hash);
// DB에 hash 저장

// 로그인 시
if (bcrypt_checkpw(password, stored_hash) == 0) {
    return 1;  // 성공
}
```

#### 3. 버퍼 오버플로우 (CRITICAL - 치명적)

**통계**: 970개의 안전하지 않은 문자열 연산

**취약한 코드 예시**:
```c
char name[24];
strcpy(name, user_input);  // user_input이 24바이트 이상이면 오버플로우!
sprintf(buffer, "%s", long_string);  // 버퍼 크기 체크 없음
```

**수정 방법**:
```c
// 안전한 문자열 복사
strncpy(name, user_input, sizeof(name) - 1);
name[sizeof(name) - 1] = '\0';

// 안전한 포맷 출력
snprintf(buffer, sizeof(buffer), "%s", long_string);
```

### 보안 강화 체크리스트

#### 즉시 조치 필요 (우선순위: 최고)

- [ ] SQL 인젝션 수정 (파라미터화된 쿼리)
- [ ] 비밀번호 해싱 구현 (bcrypt/argon2)
- [ ] 버퍼 오버플로우 수정 (970개 인스턴스)
- [ ] 설정 파일의 평문 비밀번호 암호화
- [ ] 방화벽 규칙 설정 (포트 9065, 9300만 개방)

#### 단기 조치 (1-2주 내)

- [ ] TLS/SSL 암호화 추가
- [ ] 입력 검증 강화
- [ ] 접근 제어 목록 (ACL) 구현
- [ ] 로그 보안 강화 (민감 정보 마스킹)
- [ ] 정기 백업 자동화

#### 중기 조치 (1-2개월 내)

- [ ] 침입 탐지 시스템 (IDS) 설정
- [ ] 보안 감사 로그
- [ ] DDoS 방어 메커니즘
- [ ] 정기 보안 스캔 (Nessus, OpenVAS)

### 방화벽 및 네트워크 보안

```bash
# SSH 접근 제한 (특정 IP만 허용)
sudo ufw allow from 192.168.1.0/24 to any port 22

# 게임 포트는 모든 IP 허용 (필요시)
sudo ufw allow 9065/tcp
sudo ufw allow 9300/tcp

# 또는 특정 IP 대역만 허용 (권장)
sudo ufw allow from 10.0.0.0/8 to any port 9065
sudo ufw allow from 10.0.0.0/8 to any port 9300

# Rate limiting (DDoS 기본 방어)
sudo ufw limit 9065/tcp
sudo ufw limit 9300/tcp
```

### MySQL 보안 강화

```sql
-- 최소 권한 원칙
REVOKE ALL PRIVILEGES ON *.* FROM 'saac'@'localhost';
GRANT SELECT, INSERT, UPDATE ON stoneage.* TO 'saac'@'localhost';
FLUSH PRIVILEGES;

-- 원격 접속 차단
DELETE FROM mysql.user WHERE Host <> 'localhost';
FLUSH PRIVILEGES;

-- 강력한 비밀번호 정책
SET GLOBAL validate_password.policy=STRONG;
SET GLOBAL validate_password.length=12;
```

---

## 문제 해결

### 일반적인 문제

#### 서버가 시작되지 않음

**증상**: `./gmsvjt.exe` 실행 시 즉시 종료

**원인 1**: 설정 파일 오류
```bash
# 설정 파일 검증
cat gmsv/setup.cf | grep -v '^#' | grep -v '^$'

# 필수 항목 확인
grep -E 'acserv|port|gameservname' gmsv/setup.cf
```

**원인 2**: 포트 충돌
```bash
# 포트 사용 중 확인
netstat -tuln | grep 9065

# 프로세스 종료
sudo kill $(lsof -t -i:9065)
```

**원인 3**: 파일 권한
```bash
# 실행 권한 부여
chmod +x gmsv/gmsvjt.exe saac/saacjt.exe

# 데이터 디렉토리 권한
chmod 755 saac/char gmsv/log
```

#### MySQL 연결 실패

**증상**: SAAC 시작 시 "mysql_real_connect=fail" 오류

**해결**:
```bash
# MySQL 서비스 상태 확인
sudo systemctl status mysql

# MySQL 시작
sudo systemctl start mysql

# 접속 테스트
mysql -u saac_user -p stoneage

# 사용자 권한 확인
SHOW GRANTS FOR 'saac_user'@'localhost';
```

#### 캐릭터 데이터 로드 실패

**증상**: 로그인 후 캐릭터가 보이지 않음

**원인**: 파일 경로 불일치

**해결**:
```bash
# 캐릭터 데이터 디렉토리 확인
ls -la ../saac/char/

# 경로 권한 확인
namei -l ../saac/char/

# setup.cf에서 storedir 확인
grep storedir gmsv/setup.cf
```

#### 높은 CPU 사용률

**증상**: CPU 사용률 100%

**원인**: 무한 루프 또는 플레이어 과부하

**진단**:
```bash
# CPU 사용률 확인
top -p $(pgrep gmsvjt)

# 프로파일링 (gprof)
make CFLAGS="-pg"
./gmsvjt.exe
# 서버 종료 후
gprof gmsvjt.exe gmon.out > analysis.txt
```

**해결**:
- 플레이어 수 제한 (`fdnum` 감소)
- CPU 스로틀링 증가 (`CPUUSE` 증가)
- 서브시스템 최적화

### 로그 분석

```bash
# 에러 패턴 검색
grep -i "error\|fail\|crash" gmsv/log/*.log

# 연결 로그
grep "ClientLogin\|ClientLogout" gmsv/log/*.log

# 자주 발생하는 에러 Top 10
grep -h "ERROR" gmsv/log/*.log | sort | uniq -c | sort -rn | head -10
```

---

## 개발자 가이드

### 코드 구조

#### 서브시스템 개요

| 서브시스템 | 위치 | 역할 | 파일 수 |
|----------|-----|------|--------|
| **전투** | `gmsv/battle/` | 전투 로직, AI, 데미지 계산 | 6 |
| **캐릭터** | `gmsv/char/` | 플레이어 상태, 인벤토리, 파티 | 17 |
| **마법** | `gmsv/magic/` | 마법 시스템, 효과 | 4 |
| **아이템** | `gmsv/item/` | 아이템 생성, 이벤트 | 5 |
| **맵** | `gmsv/map/` | 맵 로딩, 워프 포인트 | 6 |
| **NPC** | `gmsv/npc/` | NPC AI, 상점, 퀘스트 | 73 |

#### 코딩 컨벤션

```c
// 함수 명명 규칙
SUBSYSTEM_functionName()   // 예: CHAR_getInt(), BATTLE_Loop()

// 상수 명명 규칙
SUBSYSTEM_CONSTANT         // 예: CHAR_GOLD, BATTLE_PHASE_COMMAND

// 파일 명명 규칙
subsystem_component.c      // 예: char_data.c, battle_ai.c
```

### 새로운 NPC 추가하기

```c
// 1. 헤더 파일 생성: gmsv/include/npc_myshop.h
#ifndef _NPC_MYSHOP_H_
#define _NPC_MYSHOP_H_

void NPC_MyShopInit(int meindex);
void NPC_MyShopTalk(int meindex, int toindex, char *msg, int msglen);

#endif

// 2. 구현 파일 생성: gmsv/npc/npc_myshop.c
#include "version.h"
#include "npcutil.h"
#include "npc_myshop.h"

void NPC_MyShopInit(int meindex) {
    // NPC 초기화
    NPC_setString(meindex, NPC_NAME, "상점주인");
    NPC_setInt(meindex, NPC_X, 100);
    NPC_setInt(meindex, NPC_Y, 100);
}

void NPC_MyShopTalk(int meindex, int toindex, char *msg, int msglen) {
    // 대화 처리
    if (strstr(msg, "구매") != NULL) {
        // 구매 로직
        CHAR_talkToCli(toindex, -1, "환영합니다!", CHAR_COLORYELLOW);
    }
}

// 3. function.c에 등록
#include "npc_myshop.h"

NPC_TEMPLATE npc_myshop_template = {
    "myshop",
    NPC_MyShopInit,
    NPC_MyShopTalk,
    NULL,  // loop 함수
    NULL   // die 함수
};
```

### 디버깅 팁

```bash
# GDB로 디버깅
gdb ./gmsvjt.exe
(gdb) run
(gdb) bt  # 스택 추적
(gdb) print variable_name  # 변수 값 확인

# Valgrind로 메모리 누수 체크
valgrind --leak-check=full ./gmsvjt.exe

# strace로 시스템 콜 추적
strace -f ./gmsvjt.exe

# 로그 레벨 증가
# setup.cf에서 debuglevel=3 설정
```

### 성능 프로파일링

```bash
# gprof 프로파일링
make CFLAGS="-pg -O2"
./gmsvjt.exe
# 종료 후
gprof gmsvjt.exe gmon.out > profile.txt

# perf 프로파일링 (Linux)
perf record -g ./gmsvjt.exe
perf report

# Flamegraph 생성
perf script | stackcollapse-perf.pl | flamegraph.pl > flamegraph.svg
```

---

## 기여 가이드

### 코드 기여 프로세스

1. **이슈 생성**: 버그 리포트 또는 기능 제안
2. **포크**: 저장소 포크
3. **브랜치 생성**: `feature/my-feature` 또는 `bugfix/issue-123`
4. **코드 작성**: 컨벤션 준수
5. **테스트**: 변경사항 테스트
6. **Pull Request**: 상세한 설명과 함께 PR 생성

### 코드 리뷰 체크리스트

- [ ] 버퍼 오버플로우 없음 (`strncpy`, `snprintf` 사용)
- [ ] SQL 인젝션 방지 (파라미터화된 쿼리)
- [ ] 메모리 누수 없음 (Valgrind 확인)
- [ ] 기존 코드 스타일 준수
- [ ] 주석 및 문서화
- [ ] 컴파일 경고 없음

---

## 라이선스

이 프로젝트는 교육 및 연구 목적으로 제공됩니다. 상업적 사용 전 법적 검토 필요.

---

## 연락처 및 지원

- **GitHub Issues**: [프로젝트 이슈 페이지]
- **이메일**: [관리자 이메일]
- **Discord**: [커뮤니티 Discord]

---

**마지막 업데이트**: 2025년 1월
**문서 버전**: 1.0.0
**서버 버전**: 2.5
