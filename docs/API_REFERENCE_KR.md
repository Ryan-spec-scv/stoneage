# Stone Age 2.5 Server API Reference

## 목차
1. [개요](#개요)
2. [캐릭터 시스템 API](#캐릭터-시스템-api)
3. [전투 시스템 API](#전투-시스템-api)
4. [NPC 시스템 API](#npc-시스템-api)
5. [아이템 시스템 API](#아이템-시스템-api)
6. [마법 시스템 API](#마법-시스템-api)
7. [맵 시스템 API](#맵-시스템-api)
8. [네트워크 프로토콜 API](#네트워크-프로토콜-api)
9. [데이터베이스 API](#데이터베이스-api)
10. [유틸리티 함수](#유틸리티-함수)

---

## 개요

이 문서는 Stone Age 2.5 Server의 주요 API 함수들에 대한 상세한 레퍼런스를 제공합니다. 각 함수는 다음과 같은 형식으로 설명됩니다:

- **함수명**: 함수의 정확한 이름
- **프로토타입**: 함수 선언 형식
- **파라미터**: 입력 매개변수 설명
- **반환값**: 반환 값의 의미
- **설명**: 함수의 목적과 동작 방식
- **사용 예제**: 실제 코드 예제
- **주의사항**: 알려진 버그, 제약사항, 보안 이슈

### API 명명 규칙

```
[서브시스템]_[동작][대상]
예: CHAR_getInt()      // 캐릭터 시스템, get 동작, Integer 반환
    BATTLE_MakeAttack() // 전투 시스템, Make 동작, Attack 수행
    NPC_Func()          // NPC 시스템, 함수 객체
```

---

## 캐릭터 시스템 API

캐릭터의 생성, 관리, 삭제 및 속성 접근을 담당하는 API입니다.

### CHAR_getNewIndex

```c
int CHAR_getNewIndex(void);
```

**설명**: 캐릭터 객체 풀에서 사용 가능한 새로운 인덱스를 할당합니다.

**반환값**:
- 성공: 0 ~ MAX_CHARACTERS-1 범위의 유효한 인덱스
- 실패: -1 (풀이 가득 찬 경우)

**사용 예제**:
```c
int charindex = CHAR_getNewIndex();
if (charindex == -1) {
    // 에러 처리: 캐릭터 풀 고갈
    return FALSE;
}
// 캐릭터 초기화
CHAR_setInt(charindex, CHAR_WHICHTYPE, CHAR_TYPEPLAYER);
```

**주의사항**:
- 반드시 반환값이 -1인지 확인해야 합니다
- 풀이 가득 차면 새 캐릭터를 생성할 수 없습니다
- 기본 풀 크기: 10,000개 (setup.cf의 charnum 설정)

---

### CHAR_getInt / CHAR_setInt

```c
int CHAR_getInt(int index, int type);
BOOL CHAR_setInt(int index, int type, int data);
```

**파라미터**:
- `index`: 캐릭터 인덱스 (0 ~ MAX_CHARACTERS-1)
- `type`: 속성 타입 (CHAR_HP, CHAR_MAXHP, CHAR_LV 등)
- `data`: 설정할 값 (setInt만 해당)

**반환값**:
- `getInt`: 요청한 속성의 현재 값
- `setInt`: 성공 시 TRUE, 실패 시 FALSE

**사용 예제**:
```c
// 현재 HP 조회
int current_hp = CHAR_getInt(charindex, CHAR_HP);

// 최대 HP 설정
CHAR_setInt(charindex, CHAR_MAXHP, 1000);

// 레벨업
int current_level = CHAR_getInt(charindex, CHAR_LV);
CHAR_setInt(charindex, CHAR_LV, current_level + 1);
```

**주요 속성 타입**:
```c
CHAR_HP          // 현재 HP
CHAR_MAXHP       // 최대 HP
CHAR_MP          // 현재 MP
CHAR_MAXMP       // 최대 MP
CHAR_LV          // 레벨
CHAR_EXP         // 경험치
CHAR_STR         // 힘
CHAR_DEX         // 민첩
CHAR_VIT         // 체력
CHAR_INT         // 지능
CHAR_WORKINT     // 작업용 정수 (임시 데이터)
CHAR_GOLD        // 소지금
CHAR_WHICHTYPE   // 캐릭터 타입 (플레이어/NPC/펫)
```

**주의사항**:
- 인덱스 범위를 확인하지 않으므로 잘못된 인덱스 사용 시 segmentation fault 발생
- 데이터 변경 후 즉시 저장되지 않음 (명시적 save 필요)

---

### CHAR_getChar / CHAR_setChar

```c
char* CHAR_getChar(int index, int type);
BOOL CHAR_setChar(int index, int type, char* data);
```

**파라미터**:
- `index`: 캐릭터 인덱스
- `type`: 문자열 속성 타입
- `data`: 문자열 데이터 (setChar만 해당)

**반환값**:
- `getChar`: 문자열 포인터 (직접 수정 금지!)
- `setChar`: 성공 시 TRUE, 실패 시 FALSE

**사용 예제**:
```c
// 캐릭터 이름 조회
char* name = CHAR_getChar(charindex, CHAR_NAME);
printf("Character name: %s\n", name);

// 캐릭터 이름 설정
CHAR_setChar(charindex, CHAR_NAME, "NewPlayer");

// 메모 설정
CHAR_setChar(charindex, CHAR_FREEMEMO, "Test character");
```

**주요 문자열 속성 타입**:
```c
CHAR_NAME        // 캐릭터 이름
CHAR_DIRNAME     // 데이터 디렉토리 경로
CHAR_FREEMEMO    // 자유 메모
CHAR_TITLE       // 칭호
CHAR_CDKEY       // CD키
CHAR_ACCOUNTNAME // 계정명
```

**주의사항**:
- `getChar` 반환값을 직접 수정하면 안 됩니다 (읽기 전용)
- `setChar`는 내부적으로 strcpy 사용 → 버퍼 오버플로우 위험
- 최대 문자열 길이 제한 확인 필요

---

### CHAR_getWorkInt / CHAR_setWorkInt

```c
int CHAR_getWorkInt(int index, int type);
BOOL CHAR_setWorkInt(int index, int type, int data);
```

**설명**: 작업용 임시 정수 값 저장소 (비영구적 데이터). 주로 전투, 대화, 이벤트 처리 시 상태 추적에 사용됩니다.

**파라미터**:
- `index`: 캐릭터 인덱스
- `type`: 작업 변수 타입 (CHAR_WORK* 상수)
- `data`: 임시로 저장할 정수 값

**사용 예제**:
```c
// 전투 턴 카운터 설정
CHAR_setWorkInt(charindex, CHAR_WORKTURNCOUNT, 0);

// 대화 상태 저장
CHAR_setWorkInt(charindex, CHAR_WORKDIALOG, dialog_id);

// NPC 이벤트 플래그
CHAR_setWorkInt(charindex, CHAR_WORKEVENTFLAG, event_flag);
```

**주요 작업 변수**:
```c
CHAR_WORKINT         // 범용 작업 변수
CHAR_WORKTURNCOUNT   // 전투 턴 카운터
CHAR_WORKDIALOG      // 대화 상태
CHAR_WORKEVENTFLAG   // 이벤트 플래그
CHAR_WORKBATTLEMODE  // 전투 모드
CHAR_WORKPARTYMODE   // 파티 모드
```

**주의사항**:
- 서버 재시작 시 초기화됨 (비영구적)
- 파일/DB에 저장되지 않음
- 세션 간 상태 유지가 필요하면 일반 속성 사용 필요

---

### CHAR_sendCToArroundCharacter

```c
void CHAR_sendCToArroundCharacter(int fd, int index);
```

**설명**: 특정 캐릭터 정보를 주변 캐릭터들에게 브로드캐스트합니다.

**파라미터**:
- `fd`: 파일 디스크립터 (소켓)
- `index`: 브로드캐스트할 캐릭터 인덱스

**사용 예제**:
```c
// 캐릭터 외형 변경 후 주변에 알림
CHAR_setInt(charindex, CHAR_BASEBASEIMAGENUMBER, new_image);
CHAR_sendCToArroundCharacter(fd, charindex);

// 캐릭터 이동 후 주변 업데이트
CHAR_setInt(charindex, CHAR_X, new_x);
CHAR_setInt(charindex, CHAR_Y, new_y);
CHAR_sendCToArroundCharacter(fd, charindex);
```

**주의사항**:
- 네트워크 부하가 큰 함수 (주변 모든 클라이언트에 전송)
- 빈번한 호출 시 대역폭 소모 주의
- 시야 범위(VIEW_RANGE) 내의 캐릭터만 수신

---

### CHAR_Talk

```c
void CHAR_Talk(int fromindex, int toindex, char *message, int color);
```

**설명**: 캐릭터 간 대화 메시지 전송.

**파라미터**:
- `fromindex`: 발신자 캐릭터 인덱스
- `toindex`: 수신자 캐릭터 인덱스 (-1이면 브로드캐스트)
- `message`: 메시지 내용
- `color`: 메시지 색상 코드

**사용 예제**:
```c
// 일반 대화
CHAR_Talk(charindex, -1, "Hello everyone!", CHAR_COLORWHITE);

// 귓속말
CHAR_Talk(charindex, target_index, "Secret message", CHAR_COLORYELLOW);

// 시스템 메시지
CHAR_Talk(-1, charindex, "Welcome to the server", CHAR_COLORRED);
```

**색상 코드**:
```c
CHAR_COLORWHITE   // 흰색 (일반 대화)
CHAR_COLORYELLOW  // 노란색 (귓속말)
CHAR_COLORRED     // 빨간색 (시스템)
CHAR_COLORGREEN   // 초록색 (파티)
CHAR_COLORBLUE    // 파란색 (공지)
```

**주의사항**:
- 메시지 길이 제한: 최대 1024바이트
- 버퍼 오버플로우 위험 (strcpy 사용)
- HTML/스크립트 인젝션 방지 필터링 없음

---

### CHAR_DataSave

```c
BOOL CHAR_DataSave(int index);
```

**설명**: 캐릭터 데이터를 파일에 저장합니다.

**파라미터**:
- `index`: 저장할 캐릭터 인덱스

**반환값**:
- 성공: TRUE
- 실패: FALSE (파일 쓰기 실패)

**사용 예제**:
```c
// 캐릭터 정보 변경 후 저장
CHAR_setInt(charindex, CHAR_LV, new_level);
CHAR_setInt(charindex, CHAR_EXP, new_exp);
if (!CHAR_DataSave(charindex)) {
    // 저장 실패 처리
    print("Failed to save character data\n");
}
```

**저장 파일 위치**:
```
chardata/[첫글자]/[캐릭터명]
예: chardata/A/Alice
```

**주의사항**:
- 동기 I/O 작업 → 메인 루프 블로킹 발생
- 실패 시 데이터 손실 위험 (재시도 로직 없음)
- 기본 저장 주기: 24시간 (setup.cf의 CharSaveinterval) → 변경 권장

---

### CHAR_Delete

```c
void CHAR_Delete(int index);
```

**설명**: 캐릭터를 메모리에서 삭제하고 객체 풀에 반환합니다.

**파라미터**:
- `index`: 삭제할 캐릭터 인덱스

**사용 예제**:
```c
// 클라이언트 접속 종료 시
CHAR_Delete(charindex);

// 캐릭터 삭제 명령 처리
if (confirm_deletion) {
    CHAR_DataSave(charindex);  // 마지막 저장
    CHAR_Delete(charindex);     // 메모리에서 삭제
}
```

**주의사항**:
- 삭제 전 반드시 `CHAR_DataSave` 호출 권장
- 삭제된 인덱스 재사용 시 초기화 누락 주의
- 참조 중인 다른 시스템에서 dangling pointer 발생 가능

---

## 전투 시스템 API

턴제 전투 시스템의 초기화, 진행, 종료를 관리하는 API입니다.

### BATTLE_Init

```c
BOOL BATTLE_Init(void);
```

**설명**: 전투 시스템 초기화. 서버 시작 시 한 번 호출됩니다.

**반환값**:
- 성공: TRUE
- 실패: FALSE

**사용 예제**:
```c
// main.c에서 서버 초기화 시
if (!BATTLE_Init()) {
    print("Failed to initialize battle system\n");
    exit(1);
}
```

**초기화 작업**:
- 전투 테이블 메모리 할당
- 전투 기본 설정 로드
- 전투 AI 스크립트 초기화

---

### BATTLE_MakeAttackCommand

```c
BOOL BATTLE_MakeAttackCommand(int charindex, int target);
```

**설명**: 공격 명령을 전투 큐에 추가합니다.

**파라미터**:
- `charindex`: 공격자 캐릭터 인덱스
- `target`: 대상 캐릭터 인덱스 (전투 내 상대 위치)

**반환값**:
- 성공: TRUE
- 실패: FALSE (유효하지 않은 대상)

**사용 예제**:
```c
// 플레이어가 적 1번 위치 공격
if (!BATTLE_MakeAttackCommand(charindex, 1)) {
    CHAR_Talk(-1, charindex, "Invalid target!", CHAR_COLORRED);
    return FALSE;
}

// 일반 공격 명령 설정
CHAR_setWorkInt(charindex, CHAR_WORKBATTLECOM, BATTLE_COM_ATTACK);
BATTLE_MakeAttackCommand(charindex, target_pos);
```

**주의사항**:
- target은 절대 인덱스가 아닌 전투 내 상대 위치 (0~9)
- 명령 후 즉시 실행되지 않음 (턴 종료 시 일괄 처리)
- 이미 명령을 입력한 상태에서 재호출 시 덮어씀

---

### BATTLE_MagicCommand

```c
BOOL BATTLE_MagicCommand(int charindex, int magicindex, int target);
```

**설명**: 마법 사용 명령을 전투 큐에 추가합니다.

**파라미터**:
- `charindex`: 시전자 캐릭터 인덱스
- `magicindex`: 마법 ID
- `target`: 대상 (자신/아군/적)

**반환값**:
- 성공: TRUE
- 실패: FALSE (MP 부족, 유효하지 않은 마법)

**사용 예제**:
```c
// 회복 마법 시전
int heal_magic = MAGIC_ID_HEAL;
if (!BATTLE_MagicCommand(charindex, heal_magic, charindex)) {
    CHAR_Talk(-1, charindex, "Not enough MP!", CHAR_COLORRED);
    return FALSE;
}

// 공격 마법 시전
int fire_magic = MAGIC_ID_FIREBALL;
BATTLE_MagicCommand(charindex, fire_magic, enemy_target);
```

**주의사항**:
- MP 소모는 명령 입력 시가 아닌 실행 시 발생
- 마법 타겟팅 범위 검증 필요 (단일/광역/자신만)
- 마법 사용 가능 여부 사전 확인 권장

---

### BATTLE_ItemCommand

```c
BOOL BATTLE_ItemCommand(int charindex, int itemindex, int target);
```

**설명**: 아이템 사용 명령을 전투 큐에 추가합니다.

**파라미터**:
- `charindex`: 사용자 캐릭터 인덱스
- `itemindex`: 아이템 인벤토리 슬롯 번호
- `target`: 대상 캐릭터

**반환값**:
- 성공: TRUE
- 실패: FALSE (아이템 없음, 사용 불가)

**사용 예제**:
```c
// 물약 사용 (자신에게)
int potion_slot = 0;  // 인벤토리 첫 번째 슬롯
BATTLE_ItemCommand(charindex, potion_slot, charindex);

// 투척 아이템 사용 (적에게)
int bomb_slot = 5;
BATTLE_ItemCommand(charindex, bomb_slot, enemy_target);
```

**주의사항**:
- 아이템 소모는 명령 실행 시 발생
- 전투 중에만 사용 가능한 아이템 확인 필요
- 아이템 수량 확인 필요 (자동 차감)

---

### BATTLE_Loop

```c
void BATTLE_Loop(void);
```

**설명**: 메인 루프에서 매 이터레이션마다 호출되는 전투 처리 함수입니다.

**처리 단계**:
1. **COMMAND 페이즈**: 플레이어 명령 수집 대기
2. **EXECUTE 페이즈**: 모든 명령 실행 (속도순)
3. **RESULT 페이즈**: 결과 표시 및 전투 종료 확인

**사용 예제**:
```c
// main.c 메인 루프
void mainloop(void) {
    while(1) {
        usleep(1);
        netloop_faster();
        NPC_generateLoop(0);
        BATTLE_Loop();        // 전투 처리
        CHAR_Loop();
        // ...
    }
}
```

**주의사항**:
- 블로킹 없이 빠르게 반환해야 함
- 각 전투는 독립적으로 진행 (동시 다중 전투 가능)
- 전투 타임아웃 체크 포함 (무한 대기 방지)

---

### BATTLE_Watch

```c
BOOL BATTLE_Watch(int charindex, int battleindex);
```

**설명**: 캐릭터를 특정 전투의 관전자로 등록합니다.

**파라미터**:
- `charindex`: 관전할 캐릭터 인덱스
- `battleindex`: 전투 인덱스

**반환값**:
- 성공: TRUE
- 실패: FALSE (전투 없음, 관전 불가)

**사용 예제**:
```c
// 플레이어가 전투 관전 요청
if (BATTLE_Watch(charindex, battle_id)) {
    CHAR_Talk(-1, charindex, "Now watching battle", CHAR_COLORGREEN);
} else {
    CHAR_Talk(-1, charindex, "Cannot watch this battle", CHAR_COLORRED);
}
```

**주의사항**:
- 관전자는 전투에 영향을 줄 수 없음
- 관전자 수 제한 확인 필요
- 전투 종료 시 자동으로 관전 해제

---

## NPC 시스템 API

NPC 생성, AI 처리, 함수 객체 등록을 관리하는 API입니다.

### NPC_createFromFile

```c
int NPC_createFromFile(char *filename, int floor, int x, int y);
```

**설명**: 파일에서 NPC 정의를 읽어 생성합니다.

**파라미터**:
- `filename`: NPC 정의 파일 경로
- `floor`: 생성할 맵 층 번호
- `x`, `y`: 생성 좌표

**반환값**:
- 성공: NPC 캐릭터 인덱스
- 실패: -1

**사용 예제**:
```c
// 상점 NPC 생성
int shop_npc = NPC_createFromFile("npc/shop_potion.txt", 1000, 100, 100);
if (shop_npc == -1) {
    print("Failed to create shop NPC\n");
}

// 퀘스트 NPC 생성
int quest_npc = NPC_createFromFile("npc/quest_001.txt", 1000, 150, 120);
```

**NPC 정의 파일 예제**:
```
# npc/shop_potion.txt
Name=포션 상인
Image=100
FuncName=npc_shop_potion
Talk1=어서오세요!
Talk2=포션이 필요하신가요?
```

**주의사항**:
- 파일 경로는 상대 경로 (서버 실행 디렉토리 기준)
- 파일 파싱 실패 시 에러 메시지 없이 -1 반환
- 좌표 유효성 검사 필요 (맵 범위 내)

---

### NPC_generateLoop

```c
void NPC_generateLoop(int meflg);
```

**설명**: NPC AI 루프 실행. 모든 NPC의 AI 함수를 호출합니다.

**파라미터**:
- `meflg`: 측정 플래그 (0: 일반, 1: 성능 측정)

**사용 예제**:
```c
// main.c 메인 루프
void mainloop(void) {
    while(1) {
        usleep(1);
        netloop_faster();
        NPC_generateLoop(0);  // NPC AI 실행
        BATTLE_Loop();
        CHAR_Loop();
        // ...
    }
}
```

**AI 처리 순서**:
1. 모든 활성 NPC 순회
2. 각 NPC의 `generateProc` 함수 포인터 호출
3. NPC 상태 업데이트 (이동, 공격, 대화 등)

**주의사항**:
- 모든 NPC AI가 순차 실행 → 많은 NPC 시 성능 저하
- 각 AI 함수는 빠르게 반환해야 함 (블로킹 금지)
- 무한 루프 주의 (서버 전체 정지)

---

### NPC_Func (함수 객체 등록)

```c
typedef void (*NPCFUNC)(int, int);  // (npc_index, char_index)

struct {
    char *funcname;
    NPCFUNC func;
} NPC_FunctionTable[] = {
    {"npc_shop_potion", npc_shop_potion},
    {"npc_quest_001", npc_quest_001},
    // ...
};
```

**설명**: NPC 함수 객체를 이름으로 등록하여 동적 바인딩을 가능하게 합니다.

**사용 예제**:

**NPC 함수 구현**:
```c
// npcfunc/shop_potion.c
void npc_shop_potion(int npc_index, int char_index) {
    char* player_name = CHAR_getChar(char_index, CHAR_NAME);
    char message[256];

    snprintf(message, sizeof(message),
             "어서오세요 %s님! 포션을 구매하시겠습니까?", player_name);

    CHAR_Talk(npc_index, char_index, message, CHAR_COLORWHITE);

    // 상점 윈도우 열기
    lssproto_WN_send(getfdFromCharaIndex(char_index),
                     WINDOW_SHOP_POTION);
}
```

**NPC 등록**:
```c
// npcfunc.c
void NPC_InitFunctionTable(void) {
    NPC_FunctionTable[0].funcname = "npc_shop_potion";
    NPC_FunctionTable[0].func = npc_shop_potion;

    NPC_FunctionTable[1].funcname = "npc_quest_001";
    NPC_FunctionTable[1].func = npc_quest_001;
}
```

**주의사항**:
- 함수 이름과 실제 함수 포인터의 불일치 주의
- 등록되지 않은 함수명 사용 시 segmentation fault
- 함수 테이블 크기 제한 확인

---

### NPC_Talk

```c
void NPC_Talk(int npcindex, int charindex, char* message);
```

**설명**: NPC가 특정 플레이어에게 대화를 전송합니다.

**파라미터**:
- `npcindex`: NPC 캐릭터 인덱스
- `charindex`: 대화 대상 플레이어 인덱스
- `message`: 대화 내용

**사용 예제**:
```c
// NPC 인사
NPC_Talk(npc_index, char_index, "안녕하세요!");

// 퀘스트 대화
NPC_Talk(npc_index, char_index, "마을에 몬스터가 나타났습니다. 도와주시겠습니까?");
```

**주의사항**:
- `CHAR_Talk`의 래퍼 함수 (NPC 전용)
- 메시지 길이 제한 동일 (1024바이트)
- 대화창 UI와 연동됨

---

## 아이템 시스템 API

아이템 생성, 관리, 장착/해제를 처리하는 API입니다.

### ITEM_getNewIndex

```c
int ITEM_getNewIndex(void);
```

**설명**: 아이템 객체 풀에서 새로운 인덱스를 할당합니다.

**반환값**:
- 성공: 유효한 아이템 인덱스
- 실패: -1 (풀 고갈)

**사용 예제**:
```c
int itemindex = ITEM_getNewIndex();
if (itemindex == -1) {
    print("Item pool exhausted\n");
    return FALSE;
}
```

**주의사항**:
- 아이템 풀 크기: setup.cf의 `itemnum` 설정
- 아이템 누수 주의 (미사용 아이템 반환 필수)

---

### ITEM_makeItemComplete

```c
int ITEM_makeItemComplete(int itemid, int amount, int floor, int x, int y);
```

**설명**: 아이템을 생성하고 맵에 드롭합니다.

**파라미터**:
- `itemid`: 아이템 ID (아이템 데이터베이스 참조)
- `amount`: 수량
- `floor`: 드롭할 맵 층
- `x`, `y`: 드롭 좌표

**반환값**:
- 성공: 생성된 아이템 인덱스
- 실패: -1

**사용 예제**:
```c
// 몬스터 처치 시 아이템 드롭
int item_gold = ITEM_ID_GOLD;
ITEM_makeItemComplete(item_gold, 100, floor, monster_x, monster_y);

// 퀘스트 보상 아이템 생성
int item_sword = ITEM_ID_SWORD_RARE;
int item_index = ITEM_makeItemComplete(item_sword, 1, floor, x, y);
```

**주의사항**:
- 좌표 유효성 검사 필요
- 아이템이 겹치는 경우 처리 로직 확인
- 드롭된 아이템은 일정 시간 후 자동 삭제

---

### ITEM_setInt / ITEM_getInt

```c
BOOL ITEM_setInt(int index, int type, int data);
int ITEM_getInt(int index, int type);
```

**설명**: 아이템 속성 설정/조회.

**주요 속성 타입**:
```c
ITEM_ID          // 아이템 ID
ITEM_AMOUNT      // 수량
ITEM_DURABILITY  // 내구도
ITEM_EQUIPSLOT   // 장착 슬롯
ITEM_ITEMINDEX   // 아이템 인덱스
```

**사용 예제**:
```c
// 아이템 내구도 감소
int current_durability = ITEM_getInt(itemindex, ITEM_DURABILITY);
ITEM_setInt(itemindex, ITEM_DURABILITY, current_durability - 10);

// 아이템 수량 증가
int current_amount = ITEM_getInt(itemindex, ITEM_AMOUNT);
ITEM_setInt(itemindex, ITEM_AMOUNT, current_amount + 5);
```

---

### CHAR_PickUpItem

```c
BOOL CHAR_PickUpItem(int charindex, int itemindex);
```

**설명**: 캐릭터가 바닥의 아이템을 습득합니다.

**파라미터**:
- `charindex`: 습득할 캐릭터 인덱스
- `itemindex`: 습득할 아이템 인덱스

**반환값**:
- 성공: TRUE
- 실패: FALSE (인벤토리 가득 참)

**사용 예제**:
```c
// 플레이어가 아이템 습득 시도
if (!CHAR_PickUpItem(charindex, itemindex)) {
    CHAR_Talk(-1, charindex, "인벤토리가 가득 찼습니다!", CHAR_COLORRED);
    return FALSE;
}
```

**주의사항**:
- 거리 확인 필요 (플레이어와 아이템의 거리)
- 무게 제한 확인
- 아이템이 이미 다른 플레이어에게 습득된 경우 처리

---

### CHAR_EquipItem

```c
BOOL CHAR_EquipItem(int charindex, int itemslot);
```

**설명**: 인벤토리의 아이템을 장착합니다.

**파라미터**:
- `charindex`: 캐릭터 인덱스
- `itemslot`: 장착할 아이템의 인벤토리 슬롯 번호

**반환값**:
- 성공: TRUE
- 실패: FALSE (장착 불가 아이템, 레벨 부족)

**사용 예제**:
```c
// 무기 장착
if (!CHAR_EquipItem(charindex, weapon_slot)) {
    CHAR_Talk(-1, charindex, "장착할 수 없습니다!", CHAR_COLORRED);
}

// 방어구 장착
CHAR_EquipItem(charindex, armor_slot);
```

**주의사항**:
- 레벨 요구사항 확인
- 직업 제한 확인
- 기존 장착 아이템 자동 해제

---

## 마법 시스템 API

마법 시전, 효과 계산, MP 관리를 담당하는 API입니다.

### MAGIC_use

```c
BOOL MAGIC_use(int charindex, int magicid, int target);
```

**설명**: 마법을 즉시 시전합니다 (전투 외).

**파라미터**:
- `charindex`: 시전자 인덱스
- `magicid`: 마법 ID
- `target`: 대상 인덱스

**반환값**:
- 성공: TRUE
- 실패: FALSE (MP 부족, 시전 불가)

**사용 예제**:
```c
// 힐 마법 사용
if (!MAGIC_use(charindex, MAGIC_ID_HEAL, charindex)) {
    CHAR_Talk(-1, charindex, "MP가 부족합니다!", CHAR_COLORRED);
}

// 텔레포트 마법
MAGIC_use(charindex, MAGIC_ID_TELEPORT, 0);
```

**주의사항**:
- MP 소모는 함수 내에서 자동 처리
- 마법 쿨다운 확인 필요
- 대상 유효성 검증 필요

---

### MAGIC_calculateDamage

```c
int MAGIC_calculateDamage(int caster_index, int target_index, int magicid);
```

**설명**: 마법 대미지를 계산합니다.

**파라미터**:
- `caster_index`: 시전자 인덱스
- `target_index`: 대상 인덱스
- `magicid`: 마법 ID

**반환값**:
- 계산된 마법 대미지 값

**사용 예제**:
```c
// 마법 대미지 미리 계산
int damage = MAGIC_calculateDamage(charindex, enemy_index, MAGIC_ID_FIREBALL);
if (damage < 100) {
    // 대미지가 낮으면 다른 마법 선택
}
```

**대미지 계산 공식**:
```c
damage = (INT * magic_power * random_factor) - (target_MDEF * resistance)
```

---

### MAGIC_isMPEnough

```c
BOOL MAGIC_isMPEnough(int charindex, int magicid);
```

**설명**: 마법 시전에 필요한 MP가 충분한지 확인합니다.

**파라미터**:
- `charindex`: 캐릭터 인덱스
- `magicid`: 마법 ID

**반환값**:
- 충분: TRUE
- 부족: FALSE

**사용 예제**:
```c
// 마법 시전 전 MP 확인
if (!MAGIC_isMPEnough(charindex, MAGIC_ID_METEOR)) {
    CHAR_Talk(-1, charindex, "MP가 부족합니다!", CHAR_COLORRED);
    return FALSE;
}

MAGIC_use(charindex, MAGIC_ID_METEOR, target);
```

---

## 맵 시스템 API

맵 로딩, 이동 처리, 충돌 감지를 관리하는 API입니다.

### MAP_read

```c
BOOL MAP_read(int floor, char *filename);
```

**설명**: 맵 파일을 읽어 메모리에 로드합니다.

**파라미터**:
- `floor`: 맵 층 번호 (식별자)
- `filename`: 맵 파일 경로

**반환값**:
- 성공: TRUE
- 실패: FALSE

**사용 예제**:
```c
// 서버 초기화 시 맵 로딩
if (!MAP_read(1000, "map/town.map")) {
    print("Failed to load town map\n");
    exit(1);
}

if (!MAP_read(2000, "map/dungeon_1.map")) {
    print("Failed to load dungeon map\n");
}
```

**주의사항**:
- 맵 파일 포맷 확인 필요
- 메모리 부족 시 로딩 실패
- 동일 floor 번호로 재로딩 시 기존 맵 덮어씀

---

### MAP_walkAble

```c
BOOL MAP_walkAble(int floor, int x, int y);
```

**설명**: 특정 좌표가 이동 가능한지 확인합니다.

**파라미터**:
- `floor`: 맵 층 번호
- `x`, `y`: 확인할 좌표

**반환값**:
- 이동 가능: TRUE
- 이동 불가: FALSE (벽, 장애물)

**사용 예제**:
```c
// 캐릭터 이동 전 확인
int new_x = current_x + 1;
int new_y = current_y;

if (MAP_walkAble(floor, new_x, new_y)) {
    CHAR_setInt(charindex, CHAR_X, new_x);
    CHAR_setInt(charindex, CHAR_Y, new_y);
} else {
    CHAR_Talk(-1, charindex, "이동할 수 없습니다!", CHAR_COLORRED);
}
```

**주의사항**:
- 좌표 범위 초과 시 FALSE 반환
- 다른 캐릭터와의 충돌은 별도 확인 필요
- NPC 이동 시에도 사용

---

### MAP_getFloorData

```c
int MAP_getFloorData(int floor, int x, int y);
```

**설명**: 특정 좌표의 맵 타일 데이터를 반환합니다.

**파라미터**:
- `floor`: 맵 층 번호
- `x`, `y`: 좌표

**반환값**:
- 타일 데이터 (타일 ID, 속성 등)

**사용 예제**:
```c
// 특정 타일이 워프 존인지 확인
int tile_data = MAP_getFloorData(floor, x, y);
if (tile_data == TILE_WARP) {
    // 워프 처리
}

// 타일이 물인지 확인
if (tile_data == TILE_WATER) {
    // 물 위 이동 처리
}
```

---

### MAP_CharaWalk

```c
BOOL MAP_CharaWalk(int charindex, int dir);
```

**설명**: 캐릭터를 특정 방향으로 이동시킵니다.

**파라미터**:
- `charindex`: 캐릭터 인덱스
- `dir`: 방향 (0~7: 8방향)

**반환값**:
- 성공: TRUE
- 실패: FALSE (이동 불가)

**사용 예제**:
```c
// 북쪽으로 이동
if (!MAP_CharaWalk(charindex, DIR_NORTH)) {
    // 이동 실패 처리
}

// 랜덤 이동 (NPC AI)
int random_dir = rand() % 8;
MAP_CharaWalk(npc_index, random_dir);
```

**방향 상수**:
```c
DIR_NORTH     = 0
DIR_NORTHEAST = 1
DIR_EAST      = 2
DIR_SOUTHEAST = 3
DIR_SOUTH     = 4
DIR_SOUTHWEST = 5
DIR_WEST      = 6
DIR_NORTHWEST = 7
```

**주의사항**:
- 자동으로 `MAP_walkAble` 확인
- 이동 후 주변 캐릭터에게 자동 브로드캐스트
- 워프 존 체크 및 처리 포함

---

## 네트워크 프로토콜 API

클라이언트-서버 통신 프로토콜 함수들입니다.

### lssproto_WN_send (Window Notify)

```c
void lssproto_WN_send(int fd, int windowtype, int buttontype, int seqno, int objindex, char *data);
```

**설명**: 클라이언트에게 윈도우 열기 명령을 전송합니다.

**파라미터**:
- `fd`: 클라이언트 소켓 파일 디스크립터
- `windowtype`: 윈도우 타입 (상점, 인벤토리 등)
- `buttontype`: 버튼 타입
- `seqno`: 시퀀스 번호
- `objindex`: 관련 객체 인덱스
- `data`: 추가 데이터

**사용 예제**:
```c
// 상점 윈도우 열기
lssproto_WN_send(fd, WINDOW_SHOP, 0, 0, shop_npc_index, "");

// 인벤토리 윈도우 열기
lssproto_WN_send(fd, WINDOW_INVENTORY, 0, 0, charindex, "");

// 대화창 열기
lssproto_WN_send(fd, WINDOW_DIALOG, BUTTON_YES_NO, 0, npc_index,
                 "퀘스트를 수락하시겠습니까?");
```

**윈도우 타입**:
```c
WINDOW_SHOP       // 상점
WINDOW_INVENTORY  // 인벤토리
WINDOW_DIALOG     // 대화창
WINDOW_TRADE      // 거래창
WINDOW_BANK       // 창고
```

---

### lssproto_TK_send (Talk)

```c
void lssproto_TK_send(int fd, int index, char *message, int color);
```

**설명**: 클라이언트에게 대화 메시지를 전송합니다.

**파라미터**:
- `fd`: 클라이언트 소켓
- `index`: 발신자 캐릭터 인덱스
- `message`: 메시지 내용
- `color`: 메시지 색상

**사용 예제**:
```c
// 일반 대화
lssproto_TK_send(fd, charindex, "안녕하세요!", CHAR_COLORWHITE);

// 시스템 메시지
lssproto_TK_send(fd, -1, "서버 점검이 예정되어 있습니다.", CHAR_COLORRED);
```

---

### lssproto_C_send (Character Data)

```c
void lssproto_C_send(int fd, int index);
```

**설명**: 캐릭터 데이터를 클라이언트에 전송합니다.

**파라미터**:
- `fd`: 클라이언트 소켓
- `index`: 전송할 캐릭터 인덱스

**사용 예제**:
```c
// 캐릭터 정보 업데이트
CHAR_setInt(charindex, CHAR_LV, new_level);
lssproto_C_send(fd, charindex);  // 클라이언트에 전송

// 장비 변경 후 업데이트
CHAR_EquipItem(charindex, item_slot);
lssproto_C_send(fd, charindex);
```

**주의사항**:
- 대역폭 소모가 큼 (모든 캐릭터 데이터 전송)
- 필요한 경우에만 호출 (변경 사항 발생 시)
- 주변 캐릭터는 `CHAR_sendCToArroundCharacter` 사용

---

### lssproto_B_send (Battle Start)

```c
void lssproto_B_send(int fd, int battleindex);
```

**설명**: 전투 시작을 클라이언트에 알립니다.

**파라미터**:
- `fd`: 클라이언트 소켓
- `battleindex`: 전투 인덱스

**사용 예제**:
```c
// 전투 시작
int battle_index = BATTLE_CreateNew();
BATTLE_AddPlayer(battle_index, charindex);
BATTLE_AddEnemy(battle_index, monster_index);
lssproto_B_send(fd, battle_index);
```

---

## 데이터베이스 API

SAAC 서버와의 통신 및 MySQL 데이터베이스 접근을 담당합니다.

### saacproto_ACLogin_send

```c
void saacproto_ACLogin_send(int fd, char *id, char *passwd, char *ip);
```

**설명**: SAAC 서버에 로그인 인증 요청을 전송합니다.

**파라미터**:
- `fd`: SAAC 서버 소켓
- `id`: 계정 ID
- `passwd`: 비밀번호
- `ip`: 클라이언트 IP 주소

**사용 예제**:
```c
// 클라이언트 로그인 요청 처리
void lssproto_ClientLogin(int fd, char *id, char *passwd) {
    char client_ip[32];
    getpeername_ip(fd, client_ip, sizeof(client_ip));

    // SAAC에 인증 요청
    saacproto_ACLogin_send(acfd, id, passwd, client_ip);

    // 응답 대기...
}
```

**주의사항**:
- 비밀번호가 평문 전송됨 (보안 취약점!)
- 네트워크 실패 시 재시도 로직 필요
- 응답 타임아웃 처리 필요

---

### saacproto_ACLogout_send

```c
void saacproto_ACLogout_send(int fd, char *id);
```

**설명**: SAAC 서버에 로그아웃을 알립니다.

**파라미터**:
- `fd`: SAAC 서버 소켓
- `id`: 계정 ID

**사용 예제**:
```c
// 클라이언트 접속 종료 시
void handleClientDisconnect(int charindex) {
    char* account = CHAR_getChar(charindex, CHAR_ACCOUNTNAME);

    // 캐릭터 데이터 저장
    CHAR_DataSave(charindex);

    // SAAC에 로그아웃 알림
    saacproto_ACLogout_send(acfd, account);

    // 캐릭터 삭제
    CHAR_Delete(charindex);
}
```

---

### saacproto_CharaLoad_send

```c
void saacproto_CharaLoad_send(int fd, char *account, char *charname);
```

**설명**: SAAC에 캐릭터 데이터 로드 요청을 전송합니다.

**파라미터**:
- `fd`: SAAC 서버 소켓
- `account`: 계정명
- `charname`: 캐릭터 이름

**사용 예제**:
```c
// 캐릭터 선택 시
void handleCharacterSelect(int fd, char *account, char *charname) {
    // SAAC에 캐릭터 데이터 요청
    saacproto_CharaLoad_send(acfd, account, charname);

    // 응답 수신 대기 (비동기)
}
```

---

### saacproto_CharaSave_send

```c
void saacproto_CharaSave_send(int fd, char *account, char *chardata);
```

**설명**: SAAC에 캐릭터 데이터 저장 요청을 전송합니다.

**파라미터**:
- `fd`: SAAC 서버 소켓
- `account`: 계정명
- `chardata`: 직렬화된 캐릭터 데이터

**사용 예제**:
```c
// 주기적 저장
void periodicSave(void) {
    for (int i = 0; i < MAX_CHARACTERS; i++) {
        if (CHAR_getWorkInt(i, CHAR_WORKONLINE) == TRUE) {
            char chardata[8192];
            CHAR_serialize(i, chardata, sizeof(chardata));

            char* account = CHAR_getChar(i, CHAR_ACCOUNTNAME);
            saacproto_CharaSave_send(acfd, account, chardata);
        }
    }
}
```

**주의사항**:
- 직렬화된 데이터 크기 제한 (8KB)
- 저장 실패 시 데이터 손실 위험
- 동기화 문제 (여러 서버에서 동시 저장 시)

---

## 유틸리티 함수

범용 유틸리티 및 헬퍼 함수들입니다.

### getfdFromCharaIndex

```c
int getfdFromCharaIndex(int charindex);
```

**설명**: 캐릭터 인덱스로부터 소켓 파일 디스크립터를 얻습니다.

**파라미터**:
- `charindex`: 캐릭터 인덱스

**반환값**:
- 유효한 소켓 fd
- -1 (오프라인 캐릭터)

**사용 예제**:
```c
// 캐릭터에게 메시지 전송
int fd = getfdFromCharaIndex(charindex);
if (fd != -1) {
    lssproto_TK_send(fd, -1, "시스템 메시지", CHAR_COLORRED);
}
```

---

### makeEscapeString

```c
void makeEscapeString(char *source, char *destination, int size);
```

**설명**: SQL 인젝션 방지를 위해 특수 문자를 이스케이프합니다.

**파라미터**:
- `source`: 원본 문자열
- `destination`: 이스케이프된 결과 저장 버퍼
- `size`: 버퍼 크기

**사용 예제**:
```c
// 사용자 입력 이스케이프
char user_input[256] = "O'Reilly";
char escaped[512];
makeEscapeString(user_input, escaped, sizeof(escaped));

// SQL 쿼리 생성
char query[1024];
snprintf(query, sizeof(query),
         "SELECT * FROM users WHERE name='%s'", escaped);
```

**주의사항**:
- 완벽한 보호 불가 (prepared statement 사용 권장)
- 버퍼 크기 2배 이상 필요 (최악의 경우)
- MySQL 전용 (다른 DB는 다른 이스케이프 규칙)

---

### printMessage

```c
void printMessage(int level, char *format, ...);
```

**설명**: 로그 메시지를 출력합니다.

**파라미터**:
- `level`: 로그 레벨 (DEBUG, INFO, WARN, ERROR)
- `format`: printf 스타일 포맷 문자열
- `...`: 가변 인자

**사용 예제**:
```c
// 디버그 메시지
printMessage(LOG_DEBUG, "Character %d logged in", charindex);

// 에러 메시지
printMessage(LOG_ERROR, "Failed to save character: %s", char_name);

// 정보 메시지
printMessage(LOG_INFO, "Server started on port %d", port);
```

**로그 레벨**:
```c
LOG_DEBUG   // 디버그 정보
LOG_INFO    // 일반 정보
LOG_WARN    // 경고
LOG_ERROR   // 에러
LOG_FATAL   // 치명적 에러
```

---

### util_randomInt

```c
int util_randomInt(int min, int max);
```

**설명**: 지정 범위의 난수를 생성합니다.

**파라미터**:
- `min`: 최소값 (포함)
- `max`: 최대값 (포함)

**반환값**:
- `min` ~ `max` 범위의 정수

**사용 예제**:
```c
// 1~6 주사위
int dice = util_randomInt(1, 6);

// 크리티컬 확률 (10%)
if (util_randomInt(1, 100) <= 10) {
    // 크리티컬 히트
}

// 아이템 드롭 수량
int drop_amount = util_randomInt(1, 10);
```

**주의사항**:
- 암호학적으로 안전하지 않음 (게임 로직용)
- 시드 초기화 필요 (`srand()` 호출)

---

### util_validString

```c
BOOL util_validString(char *str);
```

**설명**: 문자열에 유효하지 않은 문자가 있는지 확인합니다.

**파라미터**:
- `str`: 검증할 문자열

**반환값**:
- 유효: TRUE
- 유효하지 않음: FALSE

**사용 예제**:
```c
// 캐릭터 이름 검증
if (!util_validString(char_name)) {
    CHAR_Talk(-1, charindex, "유효하지 않은 이름입니다!", CHAR_COLORRED);
    return FALSE;
}

// 채팅 메시지 필터링
if (!util_validString(chat_message)) {
    // 메시지 거부
    return FALSE;
}
```

**필터링되는 문자**:
- 제어 문자 (ASCII < 32)
- 특수 문자 (`'`, `"`, `\`, 등)
- SQL 인젝션 문자

---

## API 사용 가이드라인

### 1. 에러 처리

모든 API 함수는 반환값을 확인해야 합니다:

```c
// ❌ 잘못된 예
int charindex = CHAR_getNewIndex();
CHAR_setInt(charindex, CHAR_HP, 100);  // charindex가 -1일 수 있음!

// ✅ 올바른 예
int charindex = CHAR_getNewIndex();
if (charindex == -1) {
    printMessage(LOG_ERROR, "Failed to create character");
    return FALSE;
}
CHAR_setInt(charindex, CHAR_HP, 100);
```

### 2. 메모리 관리

객체 풀 사용 시 반드시 해제해야 합니다:

```c
// 캐릭터 생성
int charindex = CHAR_getNewIndex();
// ... 사용 ...
CHAR_Delete(charindex);  // 반드시 삭제

// 아이템 생성
int itemindex = ITEM_getNewIndex();
// ... 사용 ...
ITEM_Delete(itemindex);  // 반드시 삭제
```

### 3. 데이터 영속성

중요한 데이터는 주기적으로 저장해야 합니다:

```c
// setup.cf 설정 변경 권장
CharSaveinterval=300  // 5분마다 저장 (기본 24시간은 위험)

// 명시적 저장
CHAR_DataSave(charindex);
```

### 4. 보안

사용자 입력은 반드시 검증 및 이스케이프 처리:

```c
// SQL 인젝션 방지
char escaped[512];
makeEscapeString(user_input, escaped, sizeof(escaped));

// 문자열 검증
if (!util_validString(user_input)) {
    return FALSE;
}

// 버퍼 오버플로우 방지
strncpy(dest, src, sizeof(dest) - 1);
dest[sizeof(dest) - 1] = '\0';
```

### 5. 성능

빈번한 호출이 예상되는 코드는 최적화:

```c
// ❌ 비효율적
for (int i = 0; i < 1000; i++) {
    int hp = CHAR_getInt(charindex, CHAR_HP);
    // 반복마다 함수 호출
}

// ✅ 효율적
int hp = CHAR_getInt(charindex, CHAR_HP);
for (int i = 0; i < 1000; i++) {
    // 한 번만 조회
}
```

---

## 추가 참고 자료

- **소스 코드**: `gmsv/` 및 `saac/` 디렉토리
- **설정 파일**: `gmsv/setup.cf`
- **프로토콜 정의**: `gmsv/lssproto_serv.c`, `saac/saacproto.c`
- **보안 가이드**: `docs/SECURITY_AUDIT_KR.md`
- **아키텍처 문서**: `docs/ARCHITECTURE_KR.md`

---

**문서 버전**: 1.0
**최종 업데이트**: 2025-01-22
**작성자**: Claude Code SuperClaude
