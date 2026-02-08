# Stone Age 2.5 Server 개발자 온보딩 가이드

## 환영합니다! 🎮

Stone Age 2.5 Server 개발팀에 오신 것을 환영합니다. 이 가이드는 신규 개발자가 최대한 빠르게 프로젝트에 기여할 수 있도록 돕기 위해 작성되었습니다.

**예상 온보딩 시간**: 3-5일
- **Day 1**: 개발 환경 설정 및 코드 탐색
- **Day 2**: 간단한 기능 구현 (NPC 추가)
- **Day 3**: 중간 난이도 기능 (아이템 시스템)
- **Day 4-5**: 실전 태스크 수행

---

## 목차

1. [시작하기 전에](#시작하기-전에)
2. [개발 환경 설정](#개발-환경-설정)
3. [코드베이스 구조](#코드베이스-구조)
4. [첫 번째 기능 구현](#첫-번째-기능-구현)
5. [개발 워크플로우](#개발-워크플로우)
6. [테스트 가이드](#테스트-가이드)
7. [디버깅 팁](#디버깅-팁)
8. [자주 묻는 질문](#자주-묻는-질문)
9. [추가 리소스](#추가-리소스)

---

## 시작하기 전에

### 필요한 사전 지식

**필수**:
- ✅ C 언어 기초 (포인터, 구조체, 메모리 관리)
- ✅ 리눅스 명령어 기초 (cd, ls, grep, vim/nano)
- ✅ Git 기본 사용법 (clone, commit, push, pull)

**권장**:
- 📚 네트워크 프로그래밍 (소켓, select/epoll)
- 📚 MySQL 기본 사용법 (SELECT, INSERT, UPDATE)
- 📚 멀티스레딩 개념

### 필독 문서

프로젝트를 시작하기 전에 다음 문서들을 읽어보세요:

1. **README_KR.md** - 프로젝트 개요 및 빠른 시작 가이드
2. **docs/ARCHITECTURE_KR.md** - 시스템 아키텍처 상세 설명
3. **docs/API_REFERENCE_KR.md** - API 함수 레퍼런스
4. **docs/SECURITY_AUDIT_KR.md** - 보안 이슈 및 주의사항

---

## 개발 환경 설정

### 1. 시스템 요구사항

**운영체제**:
- Ubuntu 20.04 LTS (권장)
- macOS 10.15+ (개발용)
- Windows 10 + WSL2 (개발용)

**하드웨어**:
- CPU: 2코어 이상
- RAM: 4GB 이상
- 디스크: 10GB 여유 공간

---

### 2. 개발 도구 설치

**Ubuntu/Linux**:
```bash
# 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc \
    make \
    git \
    vim \
    gdb \
    valgrind

# MySQL 클라이언트 및 개발 라이브러리
sudo apt-get install -y \
    mysql-client \
    libmysqlclient-dev

# 선택사항: 개발 도구
sudo apt-get install -y \
    clang \
    clang-format \
    cppcheck
```

**macOS**:
```bash
# Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 필수 패키지
brew install gcc make git vim gdb

# MySQL
brew install mysql mysql-client
```

---

### 3. 프로젝트 클론

```bash
# 저장소 클론
git clone https://github.com/yourorg/stone-age-server.git
cd stone-age-server

# 작업 브랜치 생성
git checkout -b feature/my-first-feature
```

---

### 4. 빌드 및 실행

**GMSV (게임 서버) 빌드**:
```bash
cd gmsv

# macOS인 경우 MySQL 경로 수정
# makefile의 MYSQL_LIBS를 다음과 같이 수정:
# MYSQL_LIBS=$(shell mysql_config --libs)

make clean
make

# 빌드 성공 확인
ls -lh gmsv
```

**SAAC (계정 서버) 빌드**:
```bash
cd ../saac

# makefile의 MYSQL 경로 수정 (필요 시)
make clean
make

ls -lh saac
```

**테스트 실행**:
```bash
# SAAC 먼저 실행
cd saac
./saac &

# GMSV 실행
cd ../gmsv
./gmsv

# 정상 실행 확인 (다른 터미널에서)
telnet localhost 9300
```

---

### 5. IDE/Editor 설정

**VS Code (권장)**:
```bash
# VS Code 설치 (Ubuntu)
sudo snap install --classic code

# 확장 기능 설치
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.cpptools-extension-pack
```

**c_cpp_properties.json** (IntelliSense 설정):
```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/include/mysql"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/gcc",
            "cStandard": "c11",
            "intelliSenseMode": "gcc-x64"
        }
    ],
    "version": 4
}
```

**tasks.json** (빌드 태스크):
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build GMSV",
            "type": "shell",
            "command": "make",
            "options": {
                "cwd": "${workspaceFolder}/gmsv"
            },
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

---

## 코드베이스 구조

### 디렉토리 구조

```
stone-age-server/
├── gmsv/                    # 게임 서버
│   ├── main.c               # 서버 엔트리 포인트
│   ├── char.c               # 캐릭터 시스템
│   ├── battle.c             # 전투 시스템
│   ├── npc.c                # NPC 시스템
│   ├── item.c               # 아이템 시스템
│   ├── magic.c              # 마법 시스템
│   ├── map.c                # 맵 시스템
│   ├── lssproto_serv.c      # 클라이언트 프로토콜
│   ├── saacproto_cli.c      # SAAC 프로토콜
│   ├── npcfunc/             # NPC 함수 객체들
│   │   ├── shop_potion.c
│   │   ├── quest_001.c
│   │   └── ...
│   ├── include/             # 헤더 파일
│   └── makefile
├── saac/                    # 계정 서버
│   ├── main.c               # 서버 엔트리 포인트
│   ├── sasql.c              # MySQL 인터페이스
│   ├── saacproto.c          # GMSV 프로토콜
│   └── makefile
├── docs/                    # 문서
│   ├── ARCHITECTURE_KR.md
│   ├── API_REFERENCE_KR.md
│   ├── SECURITY_AUDIT_KR.md
│   ├── PERFORMANCE_TUNING_KR.md
│   └── DEVELOPER_GUIDE_KR.md (이 문서)
├── chardata/                # 캐릭터 데이터 파일
├── data/                    # 게임 데이터
│   ├── npc/
│   ├── map/
│   └── item/
└── README_KR.md
```

---

### 주요 파일 설명

| 파일 | 역할 | 중요도 | 자주 수정 |
|------|------|--------|----------|
| **gmsv/main.c** | 서버 초기화 및 메인 루프 | ⭐⭐⭐ | ❌ |
| **gmsv/char.c** | 캐릭터 CRUD 및 속성 관리 | ⭐⭐⭐ | ✅ |
| **gmsv/battle.c** | 전투 로직 및 대미지 계산 | ⭐⭐⭐ | ✅ |
| **gmsv/npc.c** | NPC 생성 및 AI 관리 | ⭐⭐ | ✅ |
| **gmsv/item.c** | 아이템 생성 및 관리 | ⭐⭐ | ✅ |
| **gmsv/lssproto_serv.c** | 클라이언트 요청 처리 | ⭐⭐⭐ | ✅ |
| **gmsv/npcfunc/*.c** | 개별 NPC 함수 구현 | ⭐ | ✅ |
| **saac/sasql.c** | 데이터베이스 쿼리 | ⭐⭐ | ⚠️ (보안 주의) |

---

### 데이터 흐름 이해하기

**1. 플레이어 로그인 플로우**:
```
클라이언트
    ↓ [1] TCP 연결 (port 9300)
GMSV (gmsv/main.c:netloop_faster)
    ↓ [2] lssproto_ClientLogin_recv
    ↓ [3] saacproto_ACLogin_send
SAAC (saac/main.c)
    ↓ [4] sql_userread (MySQL 조회)
    ↓ [5] saacproto_ACLoginResult_send
GMSV
    ↓ [6] lssproto_LoginOK_send
클라이언트 (로그인 성공)
```

**2. 전투 플로우**:
```
클라이언트 (공격 명령)
    ↓ lssproto_BattleCommand_recv
GMSV (전투 큐에 추가)
    ↓ mainloop → BATTLE_Loop
    ↓ BATTLE_MakeAttack (대미지 계산)
    ↓ CHAR_setInt (HP 감소)
    ↓ lssproto_BattleResult_send
클라이언트 (결과 표시)
```

---

## 첫 번째 기능 구현

### 난이도 1: 새로운 NPC 추가 (30분)

**목표**: 간단한 인사 NPC를 만들어봅시다.

**Step 1: NPC 함수 작성**

파일 생성: `gmsv/npcfunc/npc_greeter.c`

```c
#include <stdio.h>
#include <string.h>
#include "../include/version.h"
#include "../include/char.h"

// NPC 함수 프로토타입
void npc_greeter(int npc_index, int char_index);

void npc_greeter(int npc_index, int char_index)
{
    // 플레이어가 NPC를 클릭했을 때 호출됨

    // 1. 플레이어 이름 가져오기
    char* player_name = CHAR_getChar(char_index, CHAR_NAME);

    // 2. 인사 메시지 생성
    char message[256];
    snprintf(message, sizeof(message),
             "안녕하세요 %s님! 석기시대에 오신 것을 환영합니다!",
             player_name);

    // 3. NPC가 말하기
    CHAR_Talk(npc_index, char_index, message, CHAR_COLORWHITE);

    // 4. 로그 출력
    log("NPC Greeter: Greeted player %s\n", player_name);
}
```

**Step 2: 함수 등록**

파일 수정: `gmsv/npcfunc.c`

```c
// 함수 테이블에 추가
#include "npcfunc/npc_greeter.c"

void NPC_InitFunctionTable(void)
{
    // 기존 NPC들...

    // 새 NPC 추가
    NPC_FunctionTable[NPC_COUNT].funcname = "npc_greeter";
    NPC_FunctionTable[NPC_COUNT].func = npc_greeter;
    NPC_COUNT++;
}
```

**Step 3: NPC 정의 파일 생성**

파일 생성: `data/npc/greeter.txt`

```
# NPC 정의 파일
Name=환영 NPC
Image=100
FuncName=npc_greeter
Talk1=안녕하세요!
Talk2=도움이 필요하신가요?
```

**Step 4: 맵에 NPC 배치**

파일 수정: `gmsv/map_init.c` (또는 맵 초기화 스크립트)

```c
void init_town_npcs(void)
{
    // 기존 NPC들...

    // 새 NPC 생성 (맵 1000번, 좌표 100, 100)
    int greeter_npc = NPC_createFromFile("npc/greeter.txt", 1000, 100, 100);
    if (greeter_npc == -1) {
        log("Failed to create greeter NPC\n");
    } else {
        log("Greeter NPC created at (100, 100)\n");
    }
}
```

**Step 5: 빌드 및 테스트**

```bash
# 빌드
cd gmsv
make clean
make

# 실행
./gmsv

# 테스트 (클라이언트에서 NPC 클릭)
# 또는 디버깅 모드로 함수 직접 호출
```

**기대 결과**:
- 맵 좌표 (100, 100)에 NPC 생성
- NPC 클릭 시 환영 메시지 표시
- 서버 로그에 "NPC Greeter: Greeted player [이름]" 출력

---

### 난이도 2: 새로운 아이템 추가 (1시간)

**목표**: 체력 회복 물약 아이템을 만들어봅시다.

**Step 1: 아이템 정의**

파일 수정: `gmsv/item_table.c`

```c
// 아이템 ID 정의
#define ITEM_ID_HEALTH_POTION 10001

// 아이템 정보 구조체
typedef struct {
    int id;
    char name[64];
    int type;
    int effect_value;
} ItemInfo;

ItemInfo item_table[] = {
    // 기존 아이템들...

    // 새 아이템: 체력 회복 물약
    {
        .id = ITEM_ID_HEALTH_POTION,
        .name = "체력 회복 물약",
        .type = ITEM_TYPE_CONSUMABLE,
        .effect_value = 100  // 100 HP 회복
    }
};
```

**Step 2: 아이템 사용 로직**

파일 수정: `gmsv/item.c`

```c
// 아이템 사용 함수
BOOL ITEM_use(int char_index, int item_index)
{
    int item_id = ITEM_getInt(item_index, ITEM_ID);

    switch (item_id) {
        case ITEM_ID_HEALTH_POTION:
            return use_health_potion(char_index, item_index);

        // 기타 아이템들...

        default:
            return FALSE;
    }
}

// 체력 회복 물약 사용
BOOL use_health_potion(int char_index, int item_index)
{
    // 1. 현재 HP 조회
    int current_hp = CHAR_getInt(char_index, CHAR_HP);
    int max_hp = CHAR_getInt(char_index, CHAR_MAXHP);

    // 2. 이미 최대 HP이면 사용 불가
    if (current_hp >= max_hp) {
        CHAR_Talk(-1, char_index, "이미 체력이 가득 찼습니다!", CHAR_COLORYELLOW);
        return FALSE;
    }

    // 3. HP 회복
    int heal_amount = 100;
    int new_hp = current_hp + heal_amount;
    if (new_hp > max_hp) {
        new_hp = max_hp;
        heal_amount = max_hp - current_hp;
    }

    CHAR_setInt(char_index, CHAR_HP, new_hp);

    // 4. 메시지 표시
    char message[128];
    snprintf(message, sizeof(message),
             "체력 회복 물약을 사용했습니다! (HP +%d)", heal_amount);
    CHAR_Talk(-1, char_index, message, CHAR_COLORGREEN);

    // 5. 아이템 소모
    int item_amount = ITEM_getInt(item_index, ITEM_AMOUNT);
    if (item_amount > 1) {
        ITEM_setInt(item_index, ITEM_AMOUNT, item_amount - 1);
    } else {
        ITEM_Delete(item_index);
    }

    // 6. 클라이언트에 업데이트 전송
    int fd = getfdFromCharaIndex(char_index);
    lssproto_C_send(fd, char_index);

    return TRUE;
}
```

**Step 3: 아이템 획득 방법 추가**

**방법 A: NPC 상점에서 판매**

파일 수정: `gmsv/npcfunc/shop_potion.c`

```c
void npc_shop_potion(int npc_index, int char_index)
{
    // 상점 아이템 목록에 추가
    ShopItem items[] = {
        {ITEM_ID_HEALTH_POTION, "체력 회복 물약", 50},  // 50 골드
        // 기타 아이템들...
    };

    // 상점 윈도우 열기
    open_shop_window(char_index, items, sizeof(items) / sizeof(ShopItem));
}
```

**방법 B: 몬스터 드롭**

파일 수정: `gmsv/battle.c`

```c
void BATTLE_onMonsterDeath(int monster_index, int killer_index)
{
    // 드롭 확률 10%
    if (util_randomInt(1, 100) <= 10) {
        int floor = CHAR_getInt(monster_index, CHAR_FLOOR);
        int x = CHAR_getInt(monster_index, CHAR_X);
        int y = CHAR_getInt(monster_index, CHAR_Y);

        // 체력 회복 물약 드롭
        ITEM_makeItemComplete(ITEM_ID_HEALTH_POTION, 1, floor, x, y);

        CHAR_Talk(-1, killer_index,
                  "몬스터가 체력 회복 물약을 떨어뜨렸습니다!",
                  CHAR_COLORGREEN);
    }
}
```

**Step 4: 테스트**

```bash
# 빌드
make clean && make

# 테스트 시나리오
# 1. NPC 상점에서 물약 구매
# 2. 인벤토리에서 물약 사용
# 3. HP 증가 확인
# 4. 물약 수량 감소 확인
```

---

### 난이도 3: 새로운 마법 추가 (2시간)

**목표**: 범위 공격 마법 "파이어볼"을 구현해봅시다.

**Step 1: 마법 정의**

파일 수정: `gmsv/magic_table.c`

```c
#define MAGIC_ID_FIREBALL 2001

typedef struct {
    int id;
    char name[64];
    int mp_cost;
    int type;           // MAGIC_TYPE_ATTACK, MAGIC_TYPE_HEAL, ...
    int target_type;    // MAGIC_TARGET_SINGLE, MAGIC_TARGET_AREA
    int range;          // 범위 (타일 수)
} MagicInfo;

MagicInfo magic_table[] = {
    // 기존 마법들...

    // 파이어볼
    {
        .id = MAGIC_ID_FIREBALL,
        .name = "파이어볼",
        .mp_cost = 30,
        .type = MAGIC_TYPE_ATTACK,
        .target_type = MAGIC_TARGET_AREA,
        .range = 2  // 2x2 범위
    }
};
```

**Step 2: 대미지 계산 로직**

파일 수정: `gmsv/magic.c`

```c
int MAGIC_calculateDamage(int caster_index, int target_index, int magic_id)
{
    if (magic_id == MAGIC_ID_FIREBALL) {
        return calculate_fireball_damage(caster_index, target_index);
    }

    // 기타 마법...
    return 0;
}

int calculate_fireball_damage(int caster_index, int target_index)
{
    // 1. 시전자 INT 스탯
    int caster_int = CHAR_getInt(caster_index, CHAR_INT);

    // 2. 대상 마법 방어력
    int target_mdef = CHAR_getInt(target_index, CHAR_MDEF);

    // 3. 대미지 공식: (INT * 3) - MDEF + 랜덤(50-100)
    int base_damage = caster_int * 3;
    int random_bonus = util_randomInt(50, 100);
    int total_damage = base_damage - target_mdef + random_bonus;

    // 4. 최소 대미지 보장
    if (total_damage < 10) {
        total_damage = 10;
    }

    return total_damage;
}
```

**Step 3: 범위 공격 로직**

```c
void MAGIC_cast_fireball(int caster_index, int target_x, int target_y)
{
    int floor = CHAR_getInt(caster_index, CHAR_FLOOR);

    // 1. MP 소모
    int current_mp = CHAR_getInt(caster_index, CHAR_MP);
    if (current_mp < 30) {
        CHAR_Talk(-1, caster_index, "MP가 부족합니다!", CHAR_COLORRED);
        return;
    }
    CHAR_setInt(caster_index, CHAR_MP, current_mp - 30);

    // 2. 범위 내 모든 적 찾기
    int affected_targets[10];
    int target_count = 0;

    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            int check_x = target_x + dx;
            int check_y = target_y + dy;

            // 해당 위치의 캐릭터 찾기
            int enemy_index = find_character_at(floor, check_x, check_y);
            if (enemy_index != -1 &&
                is_enemy(caster_index, enemy_index) &&
                target_count < 10) {

                affected_targets[target_count++] = enemy_index;
            }
        }
    }

    // 3. 모든 대상에게 대미지
    for (int i = 0; i < target_count; i++) {
        int enemy_index = affected_targets[i];
        int damage = MAGIC_calculateDamage(caster_index, enemy_index,
                                            MAGIC_ID_FIREBALL);

        // HP 감소
        int current_hp = CHAR_getInt(enemy_index, CHAR_HP);
        int new_hp = current_hp - damage;
        if (new_hp < 0) new_hp = 0;

        CHAR_setInt(enemy_index, CHAR_HP, new_hp);

        // 대미지 표시
        char message[128];
        snprintf(message, sizeof(message), "%d 대미지!",damage);
        CHAR_Talk(-1, enemy_index, message, CHAR_COLORRED);

        // 사망 처리
        if (new_hp == 0) {
            handle_character_death(enemy_index, caster_index);
        }
    }

    // 4. 이펙트 표시
    send_magic_effect_to_clients(MAGIC_ID_FIREBALL, target_x, target_y);

    // 5. 로그
    log("Magic: %s cast Fireball, hit %d targets\n",
        CHAR_getChar(caster_index, CHAR_NAME), target_count);
}
```

**Step 4: 프로토콜 핸들러 연결**

파일 수정: `gmsv/lssproto_serv.c`

```c
void lssproto_MagicCast_recv(int fd, int magic_id, int target_x, int target_y)
{
    int char_index = getCharIndexFromFd(fd);

    if (magic_id == MAGIC_ID_FIREBALL) {
        MAGIC_cast_fireball(char_index, target_x, target_y);
    } else {
        // 기타 마법...
    }
}
```

**Step 5: 테스트**

```bash
# 테스트 케이스
# 1. MP 30 이상인 캐릭터로 테스트
# 2. 범위 내 여러 적 배치
# 3. 마법 시전
# 4. 모든 적이 대미지를 받는지 확인
# 5. MP 소모 확인
```

---

## 개발 워크플로우

### Git 브랜치 전략

```
main (배포용, 항상 안정)
 ├── develop (개발용)
 │   ├── feature/add-npc-greeter (기능 개발)
 │   ├── feature/add-fireball-magic
 │   ├── bugfix/character-save-crash (버그 수정)
 │   └── hotfix/sql-injection (긴급 수정)
 └── release/v2.5.1 (릴리스 준비)
```

### 작업 프로세스

**1. 새 기능 시작**:
```bash
# develop 브랜치에서 최신 코드 가져오기
git checkout develop
git pull origin develop

# 새 feature 브랜치 생성
git checkout -b feature/add-fireball-magic

# 작업 진행...
```

**2. 커밋 작성**:
```bash
# 변경사항 확인
git status
git diff

# 스테이징
git add gmsv/magic.c gmsv/magic_table.c

# 커밋 (명확한 메시지)
git commit -m "feat: Add Fireball magic spell

- Add MAGIC_ID_FIREBALL definition
- Implement area damage calculation
- Add 2x2 range attack logic
- Add MP cost (30 MP)

Refs: #123"
```

**커밋 메시지 규칙**:
- `feat`: 새 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `docs`: 문서 수정
- `test`: 테스트 추가
- `chore`: 빌드/설정 변경

**3. 코드 리뷰 요청**:
```bash
# 푸시
git push origin feature/add-fireball-magic

# GitHub에서 Pull Request 생성
# 제목: [Feature] Add Fireball magic spell
# 본문:
# ## 변경사항
# - 파이어볼 마법 추가
# - 범위 공격 로직 구현
# - MP 소모 30
#
# ## 테스트
# - [x] 단일 적 대미지 확인
# - [x] 범위 내 다중 적 대미지 확인
# - [x] MP 소모 확인
#
# ## 스크린샷
# (게임 내 스크린샷 첨부)
```

**4. 머지 후 정리**:
```bash
# develop으로 돌아가기
git checkout develop
git pull origin develop

# 로컬 브랜치 삭제
git branch -d feature/add-fireball-magic
```

---

## 테스트 가이드

### 1. 단위 테스트

**테스트 프레임워크 설치**:
```bash
sudo apt-get install check
```

**테스트 작성 예제**:

파일 생성: `gmsv/tests/test_char.c`

```c
#include <check.h>
#include "../include/char.h"

// 테스트 케이스: 캐릭터 생성
START_TEST(test_char_create)
{
    int char_index = CHAR_getNewIndex();

    // 유효한 인덱스 반환
    ck_assert_int_ge(char_index, 0);

    // 초기 HP는 0
    int hp = CHAR_getInt(char_index, CHAR_HP);
    ck_assert_int_eq(hp, 0);

    // 정리
    CHAR_Delete(char_index);
}
END_TEST

// 테스트 케이스: HP 설정
START_TEST(test_char_set_hp)
{
    int char_index = CHAR_getNewIndex();

    // HP 설정
    CHAR_setInt(char_index, CHAR_HP, 100);

    // HP 확인
    int hp = CHAR_getInt(char_index, CHAR_HP);
    ck_assert_int_eq(hp, 100);

    CHAR_Delete(char_index);
}
END_TEST

// 테스트 스위트 생성
Suite* char_suite(void)
{
    Suite *s = suite_create("Character");

    TCase *tc_core = tcase_create("Core");
    tcase_add_test(tc_core, test_char_create);
    tcase_add_test(tc_core, test_char_set_hp);

    suite_add_tcase(s, tc_core);
    return s;
}

// 메인 함수
int main(void)
{
    int number_failed;
    Suite *s = char_suite();
    SRunner *sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    return (number_failed == 0) ? 0 : 1;
}
```

**테스트 실행**:
```bash
# 컴파일
gcc -o test_char test_char.c -lcheck -lpthread -lm

# 실행
./test_char

# 출력:
# Running suite(s): Character
#   Core:  100%: Checks: 2, Failures: 0, Errors: 0
```

---

### 2. 통합 테스트

**서버 자동화 테스트**:

파일 생성: `tests/integration_test.sh`

```bash
#!/bin/bash

# 서버 시작
cd gmsv
./gmsv &
GMSV_PID=$!

# 5초 대기 (서버 초기화)
sleep 5

# 테스트 1: 서버 연결 확인
echo "Test 1: Server connection"
if nc -z localhost 9300; then
    echo "✅ PASS: Server is listening on port 9300"
else
    echo "❌ FAIL: Server not responding"
    kill $GMSV_PID
    exit 1
fi

# 테스트 2: 로그인 패킷 전송
echo "Test 2: Login packet"
echo -e "LOGIN|testuser|testpass\n" | nc localhost 9300 > /tmp/login_response.txt
if grep -q "LOGIN_OK" /tmp/login_response.txt; then
    echo "✅ PASS: Login successful"
else
    echo "❌ FAIL: Login failed"
    kill $GMSV_PID
    exit 1
fi

# 서버 종료
kill $GMSV_PID
echo "All tests passed!"
```

**실행**:
```bash
chmod +x tests/integration_test.sh
./tests/integration_test.sh
```

---

## 디버깅 팁

### 1. GDB 사용법

**기본 사용**:
```bash
# GDB로 서버 실행
gdb ./gmsv

# GDB 명령어
(gdb) break main.c:100        # 브레이크포인트 설정
(gdb) run                      # 실행
(gdb) print variable_name      # 변수 출력
(gdb) next                     # 다음 줄
(gdb) step                     # 함수 내부로 들어가기
(gdb) continue                 # 계속 실행
(gdb) backtrace                # 콜 스택 확인
```

**크래시 디버깅**:
```bash
# 코어 덤프 활성화
ulimit -c unlimited

# 서버 실행 후 크래시 시 core 파일 생성됨
./gmsv
# ... 크래시 발생 ...

# 코어 덤프 분석
gdb ./gmsv core

(gdb) backtrace              # 크래시 위치 확인
(gdb) frame 3                # 특정 프레임으로 이동
(gdb) print *ptr             # 포인터 값 확인
```

---

### 2. 메모리 누수 탐지

**Valgrind 사용**:
```bash
# 메모리 누수 탐지
valgrind --leak-check=full --show-leak-kinds=all ./gmsv

# 출력 예시:
# ==12345== LEAK SUMMARY:
# ==12345==    definitely lost: 1,024 bytes in 10 blocks
# ==12345==    indirectly lost: 512 bytes in 5 blocks
# ==12345==    possibly lost: 0 bytes in 0 blocks
```

**누수 수정**:
```c
// ❌ 메모리 누수
char* get_character_name(int index)
{
    char* name = malloc(64);
    strcpy(name, characters[index].name);
    return name;  // 호출자가 free 안 하면 누수!
}

// ✅ 수정 1: 정적 버퍼 사용
char* get_character_name(int index)
{
    static char name[64];
    strcpy(name, characters[index].name);
    return name;
}

// ✅ 수정 2: 호출자가 버퍼 제공
void get_character_name(int index, char *out, size_t size)
{
    strncpy(out, characters[index].name, size - 1);
    out[size - 1] = '\0';
}
```

---

### 3. 로깅 활용

**로그 레벨 설정**:

파일 수정: `gmsv/log.c`

```c
typedef enum {
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR,
    LOG_FATAL
} LogLevel;

LogLevel current_log_level = LOG_INFO;

void set_log_level(LogLevel level)
{
    current_log_level = level;
}

void log_message(LogLevel level, const char *format, ...)
{
    if (level < current_log_level) {
        return;  // 현재 레벨보다 낮으면 무시
    }

    const char *level_str[] = {
        "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
    };

    time_t now = time(NULL);
    char timestamp[26];
    strftime(timestamp, 26, "%Y-%m-%d %H:%M:%S",
             localtime(&now));

    fprintf(stderr, "[%s] [%s] ", timestamp, level_str[level]);

    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}

// 사용 예제
log_message(LOG_DEBUG, "Character %d HP: %d\n", char_index, hp);
log_message(LOG_ERROR, "Failed to save character: %s\n", char_name);
```

**실행 시 로그 레벨 변경**:
```bash
# 디버그 모드로 실행
./gmsv --log-level debug

# 에러만 출력
./gmsv --log-level error
```

---

## 자주 묻는 질문

### Q1: 빌드 에러 - "mysql.h: No such file or directory"

**원인**: MySQL 개발 라이브러리가 설치되지 않음

**해결**:
```bash
# Ubuntu
sudo apt-get install libmysqlclient-dev

# macOS
brew install mysql-client

# makefile에서 경로 확인
MYSQL_CFLAGS=$(shell mysql_config --cflags)
MYSQL_LIBS=$(shell mysql_config --libs)
```

---

### Q2: 서버가 "Segmentation fault"로 크래시됨

**원인**: 메모리 접근 오류 (잘못된 포인터, 배열 범위 초과 등)

**해결 단계**:
1. 코어 덤프 활성화 후 재실행
2. GDB로 크래시 위치 확인
3. Valgrind로 메모리 오류 탐지

```bash
# 1. 코어 덤프
ulimit -c unlimited
./gmsv
# ... 크래시 ...

# 2. GDB 분석
gdb ./gmsv core
(gdb) backtrace

# 3. Valgrind
valgrind ./gmsv
```

**흔한 원인**:
```c
// ❌ NULL 포인터 역참조
char *name = CHAR_getChar(index, CHAR_NAME);
printf("%s\n", name);  // name이 NULL이면 크래시!

// ✅ NULL 체크
char *name = CHAR_getChar(index, CHAR_NAME);
if (name != NULL) {
    printf("%s\n", name);
}

// ❌ 배열 범위 초과
int array[10];
array[15] = 100;  // 크래시!

// ✅ 범위 확인
int index = 15;
if (index >= 0 && index < 10) {
    array[index] = 100;
}
```

---

### Q3: 클라이언트가 서버에 연결되지 않음

**원인**: 방화벽, 포트 설정, 서버 미실행 등

**확인 단계**:
```bash
# 1. 서버가 실행 중인지 확인
ps aux | grep gmsv

# 2. 포트가 열려있는지 확인
netstat -an | grep 9300
# 출력: tcp  0  0 0.0.0.0:9300  0.0.0.0:*  LISTEN

# 3. 방화벽 확인
sudo ufw status
sudo ufw allow 9300/tcp

# 4. 로컬에서 테스트
telnet localhost 9300
```

---

### Q4: 캐릭터 데이터가 저장되지 않음

**원인**: 저장 주기가 너무 길거나 권한 문제

**해결**:
```bash
# 1. 저장 주기 확인 (setup.cf)
CharSaveinterval=300  # 5분마다 저장 (권장)

# 2. chardata 디렉토리 권한 확인
ls -ld chardata/
# 출력: drwxr-xr-x 2 gameserver gameserver 4096 ...

chmod -R 755 chardata/

# 3. 디스크 공간 확인
df -h
```

**즉시 저장 테스트**:
```c
// 테스트 코드
void test_char_save(void)
{
    int char_index = CHAR_getNewIndex();
    CHAR_setChar(char_index, CHAR_NAME, "TestChar");
    CHAR_setInt(char_index, CHAR_LV, 10);

    // 즉시 저장
    if (CHAR_DataSave(char_index)) {
        log("✅ Save successful\n");
    } else {
        log("❌ Save failed\n");
    }
}
```

---

### Q5: 어떤 부분부터 공부해야 하나요?

**학습 로드맵**:

**Week 1: 코드 읽기**
- ✅ main.c 메인 루프 이해
- ✅ char.c 캐릭터 시스템 구조 파악
- ✅ lssproto_serv.c 프로토콜 핸들러 분석

**Week 2: 간단한 기능 추가**
- ✅ 새 NPC 추가
- ✅ 새 아이템 추가
- ✅ 간단한 버그 수정

**Week 3: 중급 기능**
- ✅ 새 마법 구현
- ✅ 전투 시스템 수정
- ✅ 데이터베이스 쿼리 작성

**Week 4: 고급 주제**
- ✅ 성능 최적화
- ✅ 보안 취약점 수정
- ✅ 멀티스레딩 이해

---

## 추가 리소스

### 내부 문서
- **ARCHITECTURE_KR.md** - 아키텍처 상세 설명
- **API_REFERENCE_KR.md** - 전체 API 레퍼런스
- **SECURITY_AUDIT_KR.md** - 보안 가이드
- **PERFORMANCE_TUNING_KR.md** - 성능 최적화

### 외부 리소스

**C 언어**:
- [The C Programming Language (K&R)](https://en.wikipedia.org/wiki/The_C_Programming_Language)
- [Beej's Guide to Network Programming](https://beej.us/guide/bgnet/)

**Linux 시스템 프로그래밍**:
- [The Linux Programming Interface](http://man7.org/tlpi/)
- [Advanced Programming in the UNIX Environment](https://www.amazon.com/Advanced-Programming-UNIX-Environment-3rd/dp/0321637739)

**게임 서버 개발**:
- [Game Programming Patterns](https://gameprogrammingpatterns.com/)
- [Multiplayer Game Programming](https://www.amazon.com/Multiplayer-Game-Programming-Architecting-Networked/dp/0134034309)

---

### 개발 도구

**코드 분석**:
- [Cppcheck](http://cppcheck.sourceforge.net/) - 정적 분석
- [Coverity](https://scan.coverity.com/) - 보안 취약점 탐지

**프로파일링**:
- [Valgrind](https://valgrind.org/) - 메모리 프로파일링
- [gprof](https://sourceware.org/binutils/docs/gprof/) - CPU 프로파일링
- [perf](https://perf.wiki.kernel.org/index.php/Main_Page) - 성능 분석

**버전 관리**:
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

## 연락처 및 지원

**팀 채널**:
- Discord: #stone-age-dev
- Slack: #server-development
- Email: dev-team@stone-age.com

**코드 리뷰 요청**:
- GitHub Pull Requests
- 리뷰어: @senior-dev-1, @senior-dev-2

**버그 리포트**:
- GitHub Issues
- 템플릿: Bug Report Template

---

## 마치며

석기시대 서버 개발팀에 합류하신 것을 다시 한 번 환영합니다! 이 가이드를 따라 학습하시면 빠르게 프로젝트에 기여하실 수 있을 것입니다.

**Remember**:
- 🐛 버그를 만나도 좌절하지 마세요 - 모든 개발자가 겪는 과정입니다
- 📚 문서를 꼼꼼히 읽어보세요 - 대부분의 답이 여기 있습니다
- 🤝 질문하는 것을 두려워하지 마세요 - 팀이 도와드립니다
- 🚀 작은 기여부터 시작하세요 - 큰 성과는 작은 단계에서 나옵니다

행운을 빕니다! 🎮

---

**문서 버전**: 1.0
**최종 업데이트**: 2025-01-22
**작성자**: Claude Code SuperClaude
