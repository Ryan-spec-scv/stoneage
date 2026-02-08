# 석기시대 2.5 서버 - 상세 아키텍처 문서

## 📋 목차

- [시스템 개요](#시스템-개요)
- [아키텍처 패턴](#아키텍처-패턴)
- [네트워크 아키텍처](#네트워크-아키텍처)
- [데이터 아키텍처](#데이터-아키텍처)
- [서브시스템 상세](#서브시스템-상세)
- [프로토콜 사양](#프로토콜-사양)
- [메모리 관리](#메모리-관리)
- [동시성 모델](#동시성-모델)
- [확장성 전략](#확장성-전략)
- [설계 의사결정 기록](#설계-의사결정-기록)

---

## 시스템 개요

### 전체 시스템 구조

```
┌─────────────────────────────────────────────────────────────────────┐
│                         클라이언트 계층                               │
│                  (석기시대 게임 클라이언트)                           │
│                                                                       │
│  - Windows 기반 게임 클라이언트                                       │
│  - DirectX 그래픽 렌더링                                             │
│  - LSS 프로토콜 통신 (바이너리)                                       │
└────────────────┬──────────────────────────────────────────────────┘
                 │ TCP/IP (Port 9065)
                 │ LSS Protocol (Binary)
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    GMSV (Game Server)                                │
│                   게임 월드 시뮬레이터                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌───────────────── 이벤트 루프 (메인 스레드) ──────────────────┐   │
│  │                                                                │   │
│  │  while(1) {                                                    │   │
│  │      netloop_faster()    ← 네트워크 I/O (select 기반)        │   │
│  │      NPC_generateLoop()  ← NPC AI 틱                          │   │
│  │      BATTLE_Loop()       ← 전투 처리                          │   │
│  │      CHAR_Loop()         ← 캐릭터 상태 업데이트              │   │
│  │      PETMAIL_proc()      ← 메일 시스템                       │   │
│  │      family_proc()       ← 가문 시스템                        │   │
│  │  }                                                             │   │
│  │                                                                │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │  Battle  │  │Character │  │   NPC    │  │  Magic   │           │
│  │  System  │  │  System  │  │  System  │  │  System  │           │
│  │          │  │          │  │          │  │          │           │
│  │ - AI     │  │ - Stats  │  │ - AI     │  │ - Casting│           │
│  │ - Damage │  │ - Inv    │  │ - Dialog │  │ - Effects│           │
│  │ - Turns  │  │ - Party  │  │ - Trade  │  │ - MP     │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│                                                                       │
│  ┌──────────┐  ┌──────────┐                                         │
│  │  Item    │  │   Map    │                                         │
│  │  System  │  │  System  │                                         │
│  │          │  │          │                                         │
│  │ - Gen    │  │ - Load   │                                         │
│  │ - Event  │  │ - Warp   │                                         │
│  └──────────┘  └──────────┘                                         │
│                                                                       │
└────────────────┬────────────────────────────────────────────────────┘
                 │ TCP/IP (Port 9300)
                 │ SAAC Protocol (Binary)
                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    SAAC (Account Server)                             │
│                   인증 및 영속성 서버                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐                │
│  │ 인증 모듈    │  │ 캐릭터 관리   │  │ 메일 시스템  │                │
│  │             │  │              │  │             │                │
│  │ - Login     │  │ - Load       │  │ - Send      │                │
│  │ - Verify    │  │ - Save       │  │ - Receive   │                │
│  │ - Lock      │  │ - Backup     │  │ - Delete    │                │
│  └─────────────┘  └──────────────┘  └─────────────┘                │
│                                                                       │
└──────┬─────────────────────┬──────────────────────────────────────┘
       │                     │
       │                     │
   ┌───▼──────┐       ┌──────▼──────┐
   │  MySQL   │       │ File System │
   │ Database │       │   Storage   │
   │          │       │             │
   │ - users  │       │ - char/     │
   │ - locks  │       │ - mail/     │
   └──────────┘       └─────────────┘
```

### 시스템 특성

| 특성 | 값 | 설명 |
|-----|---|------|
| **아키텍처 패턴** | 서비스 지향 모노리스 | 2개 서버 프로세스, 명확한 책임 분리 |
| **동시성 모델** | 단일 스레드 이벤트 루프 | select() 기반 비블로킹 I/O |
| **영속성 전략** | 하이브리드 (DB + 파일) | MySQL (인증) + 파일시스템 (캐릭터) |
| **통신 프로토콜** | 사용자 정의 바이너리 | LSS (클라-서버), SAAC (서버간) |
| **코드베이스** | 148,468 LOC (C) | GMSV: 135K, SAAC: 13K |
| **확장 전략** | 수평 확장 (다중 인스턴스) | 단일 인스턴스당 ~10명 동시 접속 |

---

## 아키텍처 패턴

### 1. 계층형 아키텍처 (Layered Architecture)

```
┌──────────────────────────────────────┐
│     프레젠테이션 계층                  │  ← lssproto_*.c (프로토콜 핸들러)
│  (Network & Protocol Handlers)       │
├──────────────────────────────────────┤
│       비즈니스 로직 계층               │  ← char/, battle/, npc/ (게임 로직)
│    (Game Logic Subsystems)           │
├──────────────────────────────────────┤
│       데이터 접근 계층                 │  ← CHAR_get/set, 파일 I/O
│    (Data Access Layer)               │
├──────────────────────────────────────┤
│        영속성 계층                     │  ← MySQL, 파일 시스템
│    (Persistence Layer)               │
└──────────────────────────────────────┘
```

**장점**:
- ✅ 명확한 책임 분리
- ✅ 계층별 독립적 테스트 가능
- ✅ 유지보수 용이

**단점**:
- ❌ 계층 간 성능 오버헤드
- ❌ 계층 경계 명확히 유지 필요

### 2. 이벤트 기반 아키텍처 (Event-Driven Architecture)

```c
// 메인 이벤트 루프
while (server_running) {
    // 1. 이벤트 수집
    events = collect_network_events();  // select()

    // 2. 이벤트 디스패치
    for (event in events) {
        dispatch_to_handler(event);
    }

    // 3. 게임 로직 틱
    tick_all_subsystems();

    // 4. 타이머 이벤트 처리
    process_scheduled_events();
}
```

**이벤트 타입**:
- **네트워크 이벤트**: 클라이언트 연결, 패킷 수신
- **게임 이벤트**: 전투 종료, 레벨업, 아이템 획득
- **타이머 이벤트**: 버프 만료, 주기적 저장, 크론 작업

### 3. 객체 풀 패턴 (Object Pool Pattern)

```c
// 캐릭터 객체 풀
#define MAX_CHARACTERS 10000
static CHARACTER characters[MAX_CHARACTERS];
static BOOL character_in_use[MAX_CHARACTERS];

int CHAR_getNewIndex(void) {
    for (int i = 0; i < MAX_CHARACTERS; i++) {
        if (!character_in_use[i]) {
            character_in_use[i] = TRUE;
            memset(&characters[i], 0, sizeof(CHARACTER));
            return i;
        }
    }
    return -1;  // 풀 고갈
}

void CHAR_releaseIndex(int index) {
    character_in_use[index] = FALSE;
}
```

**메모리 풀 시스템**:
- Characters: 10,000개
- NPCs: 8,192개
- Items: 10,000개
- Battles: 100개
- Objects: 12,000개

**총 메모리 할당**: ~305 MB (startup 시 고정)

### 4. 상태 머신 패턴 (State Machine Pattern)

```c
// 전투 상태 머신
enum BattlePhase {
    BATTLE_PHASE_COMMAND,   // 명령 입력 대기
    BATTLE_PHASE_EXECUTE,   // 명령 실행
    BATTLE_PHASE_RESULT,    // 결과 판정
    BATTLE_PHASE_ENDED      // 전투 종료
};

void BATTLE_Loop(void) {
    for (int i = 0; i < max_battles; i++) {
        switch (BATTLE_getPhase(i)) {
            case BATTLE_PHASE_COMMAND:
                if (all_commands_received(i)) {
                    BATTLE_setPhase(i, BATTLE_PHASE_EXECUTE);
                }
                break;

            case BATTLE_PHASE_EXECUTE:
                execute_all_commands(i);
                BATTLE_setPhase(i, BATTLE_PHASE_RESULT);
                break;

            case BATTLE_PHASE_RESULT:
                if (battle_finished(i)) {
                    BATTLE_setPhase(i, BATTLE_PHASE_ENDED);
                } else {
                    BATTLE_setPhase(i, BATTLE_PHASE_COMMAND);
                }
                break;
        }
    }
}
```

**상태 다이어그램**:
```
  [COMMAND] ─── 모든 명령 수신 ──→ [EXECUTE]
      ▲                               │
      │                               │
      │                           명령 실행
      │                               │
      │                               ▼
  계속 전투 ←─────────────────── [RESULT]
      │                               │
      │                          승리/패배
      │                               ▼
      └──────────────────────── [ENDED]
```

---

## 네트워크 아키텍처

### 연결 관리

```c
// 연결 구조체
typedef struct {
    int fd;              // 소켓 파일 디스크립터
    int use;             // 사용 중 플래그
    int state;           // 연결 상태
    char addr[16];       // IP 주소
    int charaindex;      // 캐릭터 인덱스

    // 버퍼
    char read_buf[8192]; // 수신 버퍼
    int read_len;        // 수신 데이터 길이
    char write_buf[8192];// 송신 버퍼
    int write_len;       // 송신 데이터 길이

    // 통계
    int packets_sent;    // 송신 패킷 수
    int packets_recv;    // 수신 패킷 수
    int errors;          // 에러 카운트
} CONNECTION;
```

### I/O 멀티플렉싱 (select 기반)

```c
void netloop_faster(void) {
    fd_set rfds, wfds, efds;
    struct timeval tmv = {0, 0};  // Non-blocking

    // 1. FD 세트 초기화
    FD_ZERO(&rfds);
    FD_ZERO(&wfds);
    FD_ZERO(&efds);

    int maxfd = 0;

    // 2. 리스닝 소켓 추가
    FD_SET(listen_fd, &rfds);
    maxfd = listen_fd;

    // 3. 모든 활성 연결 추가
    for (int i = 0; i < max_connections; i++) {
        if (connection_active[i]) {
            int fd = connections[i].fd;
            FD_SET(fd, &rfds);  // 읽기 준비 체크
            if (connections[i].write_len > 0) {
                FD_SET(fd, &wfds);  // 쓰기 준비 체크
            }
            if (fd > maxfd) maxfd = fd;
        }
    }

    // 4. select() 호출
    int ret = select(maxfd + 1, &rfds, &wfds, &efds, &tmv);

    if (ret < 0) {
        // 에러 처리
        return;
    }

    // 5. 새 연결 수락
    if (FD_ISSET(listen_fd, &rfds)) {
        int newfd = accept(listen_fd, ...);
        handle_new_connection(newfd);
    }

    // 6. 데이터 수신
    for (int i = 0; i < max_connections; i++) {
        if (connection_active[i]) {
            int fd = connections[i].fd;

            if (FD_ISSET(fd, &rfds)) {
                int bytes = read(fd, buffer, sizeof(buffer));
                process_received_data(i, buffer, bytes);
            }

            if (FD_ISSET(fd, &wfds)) {
                int bytes = write(fd, connections[i].write_buf,
                                 connections[i].write_len);
                // 송신 버퍼 업데이트
            }
        }
    }
}
```

**성능 특성**:
- **시간 복잡도**: O(n) where n = 활성 연결 수
- **비블로킹**: 타임아웃 = 0 (즉시 반환)
- **최대 FD**: 1024 (Linux 기본값, FD_SETSIZE)
- **대안**: epoll (Linux), kqueue (BSD) - O(1) 성능

### 패킷 처리 파이프라인

```
클라이언트 패킷 송신
        │
        ▼
   [네트워크 계층]
        │
        ▼
  select() 감지 → read()
        │
        ▼
   [프로토콜 계층]
        │
   패킷 헤더 파싱
   패킷 타입 식별
        │
        ▼
   [디스패처]
        │
   lssproto_*_recv() 호출
        │
        ▼
   [비즈니스 로직]
        │
   CHAR_*, BATTLE_* 등 호출
        │
        ▼
   [응답 생성]
        │
   lssproto_*_send() 호출
        │
        ▼
   [송신 버퍼]
        │
   write_buf에 추가
        │
        ▼
  select() 쓰기 준비 → write()
        │
        ▼
   [네트워크 계층]
        │
        ▼
  클라이언트 패킷 수신
```

---

## 데이터 아키텍처

### 하이브리드 영속성 모델

```
┌─────────────────────────────────────────────────────────────┐
│                     데이터 분류 전략                          │
├──────────────────────┬──────────────────────────────────────┤
│   MySQL (관계형 DB)  │      파일 시스템 (플랫 파일)         │
├──────────────────────┼──────────────────────────────────────┤
│                      │                                      │
│  ✓ 계정 정보          │  ✓ 캐릭터 데이터                     │
│    - 사용자명         │    - 레벨, 경험치                    │
│    - 비밀번호         │    - 스탯 (STR, VIT, AGI, DEX)       │
│    - 가입 시간        │    - 위치 (맵, X, Y)                │
│                      │    - HP, MP                         │
│  ✓ 계정 잠금          │    - 골드                           │
│    - 차단 목록        │                                      │
│    - 차단 사유        │  ✓ 인벤토리                          │
│                      │    - 아이템 28개 슬롯               │
│  ✓ 로그               │    - 장비 착용 상태                 │
│    - 로그인 이력      │                                      │
│    - 거래 기록        │  ✓ 펫 데이터                        │
│                      │    - 펫 5마리 정보                  │
│                      │    - 펫 스탯, 스킬                  │
│                      │                                      │
│                      │  ✓ 메일                             │
│                      │    - 받은 메일 목록                 │
│                      │                                      │
├──────────────────────┼──────────────────────────────────────┤
│  장점:                │  장점:                               │
│  • ACID 보장          │  • 빠른 읽기/쓰기                    │
│  • 관계형 쿼리        │  • 유연한 포맷                       │
│  • 데이터 무결성      │  • DB 오버헤드 없음                 │
│                      │                                      │
│  단점:                │  단점:                               │
│  • 대용량 느림        │  • 트랜잭션 없음                     │
│  • 스키마 변경 어려움 │  • 손상 위험                         │
└──────────────────────┴──────────────────────────────────────┘
```

### MySQL 스키마

```sql
-- 사용자 테이블
CREATE TABLE users (
    name VARCHAR(24) BINARY NOT NULL PRIMARY KEY,
    password VARCHAR(64) NOT NULL,  -- ⚠️ 평문 저장 (취약점!)
    RegTime DATETIME NOT NULL,
    Path VARCHAR(255) NOT NULL,
    INDEX idx_regtime (RegTime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 계정 잠금 테이블
CREATE TABLE user_lock (
    name VARCHAR(48) BINARY NOT NULL PRIMARY KEY,
    reason VARCHAR(255),
    lock_time DATETIME,
    INDEX idx_locktime (lock_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 파일 시스템 구조

```
saac/char/
├── 0x00/
│   ├── player1.txt
│   ├── player2.txt
│   └── ...
├── 0x01/
│   ├── player3.txt
│   └── ...
├── ...
└── 0xFF/
    └── player999.txt

# 해시 기반 디렉토리 분산
hash = getHash(username) & 0xFF;  // 0-255
path = sprintf("char/0x%02x/%s", hash, username);
```

**디렉토리 분산 이유**:
- 10,000명 플레이어 → 256개 폴더 = 각 폴더당 ~40개 파일
- 파일 시스템 성능 최적화 (디렉토리 엔트리 검색 시간 ↓)

### 캐릭터 파일 포맷 (예시)

```
name=플레이어1
level=45
exp=1234567
gold=500000
hp=150
maxhp=150
mp=80
maxmp=80
str=20
vit=25
agi=18
dex=15
floor=1000
x=125
y=230
item0=101234|1|0|0
item1=102345|5|0|0
...
pet0=name:토끼|level:10|hp:50|...
```

### 데이터 저장 주기

```c
// gmsv/setup.cf
CharSaveinterval=86400  // 86400초 = 24시간

// 주기적 저장 체크
void chardatasavecheck(void) {
    static time_t last_save = 0;
    time_t now = time(NULL);

    if (now - last_save > config.CharSavesendinterval) {
        for (int i = 0; i < max_chars; i++) {
            if (CHAR_getUse(i)) {
                CHAR_save(i);  // 파일에 저장
            }
        }
        last_save = now;
    }
}
```

**⚠️ 위험성**:
- 24시간 주기 = 최대 24시간 데이터 손실 가능
- 서버 크래시 시 마지막 저장 이후 진행 상황 소실
- **권장**: 300초 (5분) ~ 600초 (10분)

---

## 서브시스템 상세

### 1. 캐릭터 시스템 (char/)

**책임**:
- 캐릭터 상태 관리
- 인벤토리 시스템
- 파티 시스템
- 스탯 계산
- 레벨업 처리

**주요 함수**:

```c
// 접근자 (Accessor)
int CHAR_getInt(int index, int type);
void CHAR_setInt(int index, int type, int value);
char* CHAR_getString(int index, int type);

// 타입 상수
#define CHAR_HP         0
#define CHAR_MAXHP      1
#define CHAR_MP         2
#define CHAR_MAXMP      3
#define CHAR_GOLD       4
#define CHAR_LV         5
#define CHAR_EXP        6
#define CHAR_X          7
#define CHAR_Y          8
#define CHAR_FLOOR      9
// ... 100개 이상

// 비즈니스 로직
void CHAR_addGold(int index, int amount);
BOOL CHAR_canWalkTo(int index, int x, int y);
void CHAR_levelUp(int index);
void CHAR_joinParty(int index, int party_index);
```

**데이터 흐름**:
```
클라이언트 이동 요청
       ↓
lssproto_W_recv(fd, x, y)
       ↓
CHAR_canWalkTo(charaindex, x, y) → 검증
       ↓
CHAR_setInt(charaindex, CHAR_X, x)
CHAR_setInt(charaindex, CHAR_Y, y)
       ↓
CHAR_sendWalkPacketToNearby(charaindex)
       ↓
주변 플레이어에게 lssproto_W_send()
```

### 2. 전투 시스템 (battle/)

**책임**:
- 턴 기반 전투 관리
- AI 행동 결정
- 데미지 계산
- 전투 보상 지급

**전투 구조체**:

```c
typedef struct {
    int use;                    // 사용 중 플래그
    int phase;                  // 전투 단계

    // 참여자
    int player_indices[10];     // 플레이어들
    int enemy_indices[10];      // 적들
    int player_count;
    int enemy_count;

    // 명령
    int commands[10];           // 각 참여자 명령
    int targets[10];            // 타겟

    // 전투 상태
    int turn;                   // 현재 턴
    int result;                 // 전투 결과 (0=진행중, 1=승리, 2=패배)

    // 보상
    int exp_reward;
    int gold_reward;
    ITEM item_drops[5];
} BATTLE;
```

**전투 흐름**:

```
전투 시작
    ↓
BATTLE_create() → 전투 인덱스 할당
    ↓
[COMMAND 단계]
    클라이언트로부터 명령 수신
    (공격, 방어, 도망, 스킬, 아이템)
    ↓
    모든 참여자 명령 입력 완료?
    YES ↓ NO → 대기
    ↓
[EXECUTE 단계]
    턴 순서 결정 (속도 기반)
    ↓
    각 명령 실행:
        - 데미지 계산
        - HP 감소
        - 효과 적용
    ↓
[RESULT 단계]
    승리 조건 체크
    ↓
    YES → 보상 지급 → 전투 종료
    ↓
    NO → [COMMAND 단계]로 복귀
```

### 3. NPC 시스템 (npc/)

**설계 패턴**: 함수 객체 (Function Object)

```c
// NPC 템플릿
typedef struct {
    char *name;                             // NPC 타입 이름
    void (*init)(int npcindex);            // 초기화 함수
    void (*talk)(int npc, int player, char *msg);  // 대화 함수
    void (*loop)(int npcindex);            // 틱 함수
    void (*die)(int npcindex);             // 정리 함수
} NPC_TEMPLATE;

// 상점 NPC 예시
void NPC_ItemShopInit(int index) {
    NPC_setString(index, NPC_NAME, "무기상인");
    NPC_setInt(index, NPC_X, 150);
    NPC_setInt(index, NPC_Y, 200);
    NPC_setInt(index, NPC_FLOOR, 1000);

    // 판매 아이템 설정
    NPC_setWorkInt(index, 0, ITEM_SWORD);
    NPC_setWorkInt(index, 1, ITEM_SHIELD);
}

void NPC_ItemShopTalk(int npc, int player, char *msg) {
    if (strcmp(msg, "BUY") == 0) {
        // 구매 창 표시
        NPC_showItemList(npc, player);
    } else if (strncmp(msg, "BUY:", 4) == 0) {
        // 아이템 구매 처리
        int item_id = atoi(msg + 4);
        NPC_sellItem(npc, player, item_id);
    }
}

// 템플릿 등록
NPC_TEMPLATE itemshop_template = {
    .name = "itemshop",
    .init = NPC_ItemShopInit,
    .talk = NPC_ItemShopTalk,
    .loop = NULL,
    .die = NULL
};
```

**NPC 타입 (73종)**:
- 상점: itemshop, petshop, weaponshop
- 서비스: healer, banker, transerman
- 퀘스트: questgiver, storyteller
- 기능: warpman, savepoint, mailbox
- 특수: gamblemaster, petmaker, familyman

### 4. 아이템 시스템 (item/)

**아이템 구조**:

```c
typedef struct {
    int id;              // 아이템 ID
    int count;           // 개수
    int durability;      // 내구도
    int plus;            // 강화 수치 (+1, +2, ...)
    int flags;           // 플래그 (장착중, 거래불가 등)
    int create_time;     // 생성 시간
} ITEM;
```

**아이템 생성기**:

```c
// item_gen.c
int ITEM_generate(int level, int type) {
    int item_id;

    // 레벨 기반 아이템 풀 선택
    int pool = select_item_pool(level);

    // 랜덤 아이템 선택
    item_id = random_item_from_pool(pool, type);

    // 랜덤 옵션 부여
    int plus = random_plus(level);

    return create_item(item_id, 1, 100, plus);
}
```

### 5. 마법 시스템 (magic/)

**마법 구조**:

```c
typedef struct {
    int id;              // 마법 ID
    char name[24];       // 마법 이름
    int mp_cost;         // MP 소모량
    int target_type;     // 타겟 타입 (자신/아군/적/지역)
    int effect_type;     // 효과 타입 (데미지/힐/버프/디버프)
    int power;           // 위력
    int range;           // 범위
    int duration;        // 지속시간
} MAGIC;
```

---

## 프로토콜 사양

### LSS 프로토콜 (클라이언트 ↔ GMSV)

**패킷 구조**:

```
┌──────────┬─────────┬──────────────┬──────────┐
│  헤더    │ 패킷 ID │   페이로드    │ 체크섬   │
│ (4 byte) │(2 byte) │  (가변)      │(4 byte)  │
└──────────┴─────────┴──────────────┴──────────┘
```

**주요 패킷 타입**:

```c
// 로그인
lssproto_ClientLogin_send(fd, id, password);
lssproto_ClientLogin_recv(fd, char *id, char *password);

// 이동
lssproto_W_send(fd, x, y, direction);
lssproto_W_recv(fd, int x, int y, int direction);

// 대화
lssproto_TK_send(fd, message);
lssproto_TK_recv(fd, char *message);

// 전투
lssproto_BT_send(fd, command, target);
lssproto_BT_recv(fd, int command, int target);

// 상태 업데이트
lssproto_S_send(fd, type, value);
```

### SAAC 프로토콜 (GMSV ↔ SAAC)

**패킷 구조**:

```
┌──────────┬─────────┬──────────────┐
│ 패킷 ID  │ 세션 ID │   페이로드    │
│(2 byte)  │(4 byte) │  (가변)      │
└──────────┴─────────┴──────────────┘
```

**주요 함수**:

```c
// 로그인 요청
saacproto_ACLogin_send(fd, id, password, ip, mac);
saacproto_ACLogin_recv(fd, char *id, char *password,
                       char *ip, char *mac);

// 로그인 응답
saacproto_ACLoginResult_send(fd, result, character_data);

// 캐릭터 저장
saacproto_CharSave_send(fd, charaindex, data);

// 캐릭터 로드
saacproto_CharLoad_send(fd, charaindex);
saacproto_CharLoadResult_recv(fd, data);
```

---

## 메모리 관리

### 사전 할당 메모리 풀

```c
// gmsv/setup.cf
usememoryunit=128        // 128 바이트 단위
usememoryunitnum=2500000 // 2,500,000개 유닛

// 총 메모리 = 128 * 2,500,000 = 320,000,000 바이트 ≈ 305 MB
```

**메모리 구조**:

```
┌─────────────────────────────────────────┐
│         전역 메모리 풀 (305 MB)          │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐  ┌──────────┐           │
│  │ 유닛 0   │  │ 유닛 1   │  ...      │
│  │ 128 B    │  │ 128 B    │           │
│  └──────────┘  └──────────┘           │
│                                         │
│  사용 비트맵: [1,0,1,1,0,0,1, ...]    │
│                                         │
└─────────────────────────────────────────┘
```

**할당/해제**:

```c
void *allocate_memory(int size) {
    int units_needed = (size + 127) / 128;

    // 연속된 빈 유닛 찾기
    int start = find_free_units(units_needed);

    if (start == -1) {
        return NULL;  // 메모리 부족
    }

    // 비트맵 마킹
    mark_units_used(start, units_needed);

    return &memory_pool[start * 128];
}

void free_memory(void *ptr) {
    int unit = ((char*)ptr - (char*)memory_pool) / 128;
    mark_units_free(unit);
}
```

---

## 동시성 모델

### 단일 스레드 이벤트 루프

**장점**:
- ✅ 경쟁 조건 없음
- ✅ 데드락 불가능
- ✅ 디버깅 단순
- ✅ 메모리 동기화 불필요

**단점**:
- ❌ 단일 CPU 코어만 사용
- ❌ 블로킹 작업 시 전체 서버 정지
- ❌ 확장성 제한

**성능 계산**:
```
목표 루프 시간: 5ms
초당 루프 횟수: 200회
플레이어당 처리 시간: 5ms / 10명 = 0.5ms

각 서브시스템 할당 시간:
- netloop_faster: ~1ms
- BATTLE_Loop: ~1ms
- CHAR_Loop: ~1ms
- NPC_generateLoop: ~1ms
- 기타: ~1ms
```

### 대안: 다중 프로세스 (수평 확장)

```
              ┌─────────────┐
              │   로드밸런서  │
              │  (HAProxy)  │
              └──────┬──────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼────┐ ┌───▼─────┐ ┌──▼──────┐
    │ GMSV 1  │ │ GMSV 2  │ │ GMSV 3  │
    │ 10 users│ │ 10 users│ │ 10 users│
    └────┬────┘ └────┬────┘ └────┬────┘
         │           │           │
         └───────────┼───────────┘
                     │
              ┌──────▼──────┐
              │    SAAC     │
              │  (Shared)   │
              └─────────────┘
```

---

## 확장성 전략

### 수평 확장 (권장)

**단일 서버 용량**: 10명
**10개 서버**: 100명
**100개 서버**: 1,000명

**필요 인프라**:
- 로드 밸런서 (HAProxy, Nginx)
- 공유 SAAC 서버
- 공유 MySQL 클러스터
- NFS 또는 분산 파일 시스템

### 수직 확장 (멀티스레딩 개조 필요)

**개조 포인트**:
1. 네트워크 I/O 스레드 분리
2. 서브시스템별 스레드 풀
3. 락 프리 자료구조 도입

**예상 효과**: 코어 수 × 0.7배 성능 향상

---

## 설계 의사결정 기록 (ADR)

### ADR-001: 단일 스레드 이벤트 루프 채택

**상황**: 동시성 모델 결정 필요
**결정**: 단일 스레드 select() 기반 이벤트 루프
**근거**:
- 개발 복잡도 최소화
- 경쟁 조건 회피
- 2016년 하드웨어 제약
- 수평 확장으로 충분

**결과**: 단순하고 안정적이나 단일 인스턴스 확장성 제한

---

### ADR-002: 하이브리드 영속성 모델

**상황**: 데이터 저장 방식 선택
**결정**: MySQL (인증) + 파일 (캐릭터)
**근거**:
- MySQL: ACID 필요 (계정)
- 파일: 빠른 I/O (대용량 캐릭터 데이터)
- 비용 절감

**결과**: 성능과 안정성 균형, 백업 복잡도 증가

---

### ADR-003: 사전 할당 메모리 풀

**상황**: 메모리 관리 전략
**결정**: 시작 시 305MB 고정 할당
**근거**:
- malloc/free 오버헤드 제거
- 메모리 단편화 방지
- 예측 가능한 메모리 사용량

**결과**: 빠른 할당, 메모리 상한 고정

---

**문서 버전**: 1.0.0
**최종 업데이트**: 2025년 1월
