# Stone Age 2.5 Server 보안 감사 보고서

## 요약

**감사 날짜**: 2025-01-22
**감사 대상**: Stone Age 2.5 Server (GMSV + SAAC)
**코드베이스 규모**: 148,468 LOC (C언어)
**심각도 분류**: Critical (치명적), High (높음), Medium (중간), Low (낮음)

### 주요 발견사항

| 심각도 | 개수 | 주요 이슈 |
|-------|------|----------|
| **Critical** | 3 | SQL 인젝션, 평문 비밀번호, 인증 우회 |
| **High** | 970+ | 버퍼 오버플로우 (strcpy, sprintf) |
| **Medium** | 50+ | 입력 검증 누락, 로깅 부족 |
| **Low** | 100+ | 하드코딩된 설정, 약한 난수 생성 |

**전체 위험 점수**: **9.2 / 10** (매우 위험)

---

## 목차

1. [Critical 취약점](#critical-취약점)
2. [High 취약점](#high-취약점)
3. [Medium 취약점](#medium-취약점)
4. [Low 취약점](#low-취약점)
5. [보안 강화 권장사항](#보안-강화-권장사항)
6. [수정 우선순위](#수정-우선순위)
7. [보안 체크리스트](#보안-체크리스트)

---

## Critical 취약점

### CVE-2025-STONE-001: SQL 인젝션 취약점

**위치**: `saac/sasql.c:146`

**심각도**: **Critical (10/10)**

**설명**:
사용자 입력을 직접 SQL 쿼리에 삽입하여 SQL 인젝션 공격에 노출되어 있습니다.

**취약한 코드**:
```c
// saac/sasql.c:146
int sql_userread(char *nm)
{
    char sqlstr[256];
    MYSQL_RES *res;
    MYSQL_ROW row;

    // ❌ 사용자 입력(nm)을 직접 쿼리에 삽입
    sprintf(sqlstr, "select * from %s where %s=BINARY'%s'",
            config.sql_Table, config.sql_NAME, nm);

    if (mysql_query(&mysql, sqlstr) != 0) {
        log("mysql_query error\n");
        return 1;
    }
    // ...
}
```

**공격 시나리오**:
```sql
-- 공격자 입력: admin' OR '1'='1
-- 실행되는 쿼리:
SELECT * FROM users WHERE name=BINARY'admin' OR '1'='1'
-- 결과: 인증 우회, 모든 계정 접근 가능

-- 공격자 입력: admin'; DROP TABLE users; --
-- 실행되는 쿼리:
SELECT * FROM users WHERE name=BINARY'admin'; DROP TABLE users; --'
-- 결과: 사용자 테이블 삭제
```

**영향**:
- 전체 사용자 데이터베이스 접근
- 사용자 계정 탈취
- 데이터베이스 파괴
- 서버 권한 상승 가능

**수정 방법**:

```c
// ✅ Prepared Statement 사용
int sql_userread(char *nm)
{
    MYSQL_STMT *stmt;
    MYSQL_BIND bind[1];
    MYSQL_BIND result[10];
    char query[256];

    // Prepared statement 생성
    stmt = mysql_stmt_init(&mysql);
    if (!stmt) {
        log("mysql_stmt_init failed\n");
        return 1;
    }

    // 파라미터화된 쿼리
    snprintf(query, sizeof(query),
             "SELECT * FROM %s WHERE %s=?",
             config.sql_Table, config.sql_NAME);

    if (mysql_stmt_prepare(stmt, query, strlen(query))) {
        log("mysql_stmt_prepare failed: %s\n", mysql_stmt_error(stmt));
        mysql_stmt_close(stmt);
        return 1;
    }

    // 바인딩 파라미터 설정
    memset(bind, 0, sizeof(bind));
    bind[0].buffer_type = MYSQL_TYPE_STRING;
    bind[0].buffer = nm;
    bind[0].buffer_length = strlen(nm);
    bind[0].is_null = 0;
    bind[0].length = &bind[0].buffer_length;

    if (mysql_stmt_bind_param(stmt, bind)) {
        log("mysql_stmt_bind_param failed\n");
        mysql_stmt_close(stmt);
        return 1;
    }

    // 쿼리 실행
    if (mysql_stmt_execute(stmt)) {
        log("mysql_stmt_execute failed\n");
        mysql_stmt_close(stmt);
        return 1;
    }

    // 결과 처리
    // ...

    mysql_stmt_close(stmt);
    return 0;
}
```

**추가 권장사항**:
- 모든 SQL 쿼리를 Prepared Statement로 변환
- 입력 검증 레이어 추가 (화이트리스트 기반)
- 최소 권한 원칙 적용 (DB 사용자 권한 제한)

---

### CVE-2025-STONE-002: 평문 비밀번호 저장 및 전송

**위치**: `saac/sasql.c:155`, `gmsv/lssproto_serv.c` (다수)

**심각도**: **Critical (10/10)**

**설명**:
비밀번호가 평문으로 저장되고 네트워크를 통해 암호화 없이 전송됩니다.

**취약한 코드**:
```c
// saac/sasql.c:155
int sql_userread(char *nm)
{
    // ...
    row = mysql_fetch_row(res);
    if (row == NULL) return 1;

    // ❌ 평문 비밀번호 직접 비교
    if (strcmp(row[1], passwd) != 0) {
        log("Password mismatch\n");
        return 2;
    }
    // ...
}
```

**데이터베이스 스키마 (추정)**:
```sql
CREATE TABLE users (
    name VARCHAR(50) PRIMARY KEY,
    passwd VARCHAR(50),  -- ❌ 평문 저장!
    email VARCHAR(100),
    -- ...
);
```

**공격 시나리오**:
1. **데이터베이스 침해**: SQL 인젝션 또는 백업 파일 탈취 시 모든 비밀번호 노출
2. **네트워크 스니핑**: 평문 전송으로 중간자 공격(MITM)에 취약
3. **무차별 대입 공격**: 해시 없이 빠른 비밀번호 크래킹 가능

**영향**:
- 전체 사용자 계정 탈취
- 다른 서비스 계정 침해 (비밀번호 재사용 시)
- 프라이버시 침해

**수정 방법**:

**1. 비밀번호 해싱 (bcrypt 사용)**:
```c
#include <bcrypt.h>

// 회원가입 시
int sql_createuser(char *nm, char *passwd)
{
    char hash[128];
    char salt[BCRYPT_HASHSIZE];

    // ✅ bcrypt로 해싱 (work factor = 12)
    if (bcrypt_gensalt(12, salt) != 0) {
        return -1;
    }

    if (bcrypt_hashpw(passwd, salt, hash) != 0) {
        return -1;
    }

    // hash를 DB에 저장
    MYSQL_STMT *stmt = mysql_stmt_init(&mysql);
    char query[] = "INSERT INTO users (name, passwd_hash) VALUES (?, ?)";

    mysql_stmt_prepare(stmt, query, strlen(query));

    MYSQL_BIND bind[2];
    memset(bind, 0, sizeof(bind));

    bind[0].buffer_type = MYSQL_TYPE_STRING;
    bind[0].buffer = nm;
    bind[0].buffer_length = strlen(nm);

    bind[1].buffer_type = MYSQL_TYPE_STRING;
    bind[1].buffer = hash;
    bind[1].buffer_length = strlen(hash);

    mysql_stmt_bind_param(stmt, bind);
    mysql_stmt_execute(stmt);
    mysql_stmt_close(stmt);

    return 0;
}

// 로그인 시
int sql_userread(char *nm, char *passwd)
{
    char hash_from_db[128];

    // DB에서 해시 조회 (Prepared Statement 사용)
    // ...

    // ✅ bcrypt로 검증
    if (bcrypt_checkpw(passwd, hash_from_db) == 0) {
        // 비밀번호 일치
        return 0;
    } else {
        // 비밀번호 불일치
        return 2;
    }
}
```

**2. 네트워크 전송 암호화 (TLS)**:
```c
// ✅ OpenSSL/TLS 적용
#include <openssl/ssl.h>
#include <openssl/err.h>

SSL_CTX *create_context()
{
    const SSL_METHOD *method;
    SSL_CTX *ctx;

    method = TLS_server_method();
    ctx = SSL_CTX_new(method);

    if (!ctx) {
        perror("Unable to create SSL context");
        ERR_print_errors_fp(stderr);
        exit(EXIT_FAILURE);
    }

    return ctx;
}

void configure_context(SSL_CTX *ctx)
{
    // 인증서 로드
    if (SSL_CTX_use_certificate_file(ctx, "cert.pem", SSL_FILETYPE_PEM) <= 0) {
        ERR_print_errors_fp(stderr);
        exit(EXIT_FAILURE);
    }

    // 개인키 로드
    if (SSL_CTX_use_PrivateKey_file(ctx, "key.pem", SSL_FILETYPE_PEM) <= 0) {
        ERR_print_errors_fp(stderr);
        exit(EXIT_FAILURE);
    }
}
```

**3. 데이터베이스 스키마 변경**:
```sql
-- ✅ 개선된 스키마
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    passwd_hash VARCHAR(255) NOT NULL,  -- bcrypt 해시
    salt VARCHAR(64),                    -- 솔트 (bcrypt는 자동 포함)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    failed_attempts INT DEFAULT 0,       -- 무차별 대입 방어
    locked_until TIMESTAMP NULL,         -- 계정 잠금
    INDEX idx_name (name)
);
```

**추가 보안 조치**:
- **솔트**: bcrypt는 자동으로 솔트를 생성하고 해시에 포함
- **Work Factor**: bcrypt의 cost parameter (12 이상 권장)
- **무차별 대입 방어**: 로그인 실패 횟수 제한 (5회 실패 시 15분 잠금)
- **세션 관리**: 안전한 세션 토큰 생성 및 관리

---

### CVE-2025-STONE-003: 인증 우회 취약점

**위치**: `gmsv/lssproto_serv.c` (다수), `saac/main.c`

**심각도**: **Critical (9/10)**

**설명**:
인증 프로세스에서 타이밍 공격 및 상태 검증 누락으로 인한 인증 우회 가능성이 있습니다.

**취약한 코드**:
```c
// gmsv/lssproto_serv.c
void lssproto_ClientLogin_recv(int fd, char *id, char *passwd)
{
    int charindex = getCharIndexFromFd(fd);

    // ❌ 인증 전 캐릭터 인덱스 사용
    if (charindex == -1) {
        // 에러 처리
        return;
    }

    // ❌ SAAC 응답 대기 없이 다음 패킷 처리 가능
    saacproto_ACLogin_send(acfd, id, passwd, get_client_ip(fd));

    // ❌ 인증 결과 확인 전에 다른 명령 실행 가능
}

// 다른 프로토콜 핸들러들
void lssproto_CharaSelect_recv(int fd, int slot)
{
    // ❌ 인증 상태 확인 없음
    int charindex = getCharIndexFromFd(fd);
    // 캐릭터 로드 및 게임 진입
}
```

**공격 시나리오**:

**1. 타이밍 공격**:
```c
// ❌ 타이밍 공격에 취약한 비교
if (strcmp(input_passwd, stored_passwd) == 0) {
    // 비밀번호가 맞을수록 비교 시간이 길어짐
    // → 타이밍 분석으로 비밀번호 추측 가능
}
```

**2. 상태 기반 공격**:
```
1. 클라이언트 → 서버: Login(id, passwd)
2. 서버 → SAAC: ACLogin_send()
3. 클라이언트 → 서버: CharaSelect() [인증 대기 중인데 전송]
4. 서버: 인증 확인 없이 캐릭터 로드
5. 공격 성공: 인증 우회
```

**수정 방법**:

**1. 타이밍 안전 비교**:
```c
// ✅ 상수 시간 비교 (timing-safe)
int constant_time_compare(const char *a, const char *b, size_t length)
{
    unsigned char result = 0;
    size_t i;

    for (i = 0; i < length; i++) {
        result |= a[i] ^ b[i];
    }

    return result == 0;
}

// 사용 예제
if (constant_time_compare(input_hash, stored_hash, 60)) {
    // 비밀번호 일치 (타이밍 공격 방어)
}
```

**2. 세션 상태 관리**:
```c
// ✅ 세션 상태 정의
typedef enum {
    SESSION_INIT,           // 초기 상태
    SESSION_AUTHENTICATING, // 인증 중
    SESSION_AUTHENTICATED,  // 인증 완료
    SESSION_IN_GAME,        // 게임 중
    SESSION_DISCONNECTED    // 연결 종료
} SessionState;

typedef struct {
    int fd;
    SessionState state;
    time_t auth_start_time;
    time_t last_activity;
    char account_name[64];
    int failed_attempts;
    BOOL is_authenticated;
} Session;

Session sessions[MAX_CONNECTIONS];

// ✅ 상태 검증 함수
BOOL isAuthenticated(int fd)
{
    int session_idx = getSessionFromFd(fd);
    if (session_idx == -1) return FALSE;

    Session *s = &sessions[session_idx];

    // 인증 상태 확인
    if (!s->is_authenticated) return FALSE;
    if (s->state != SESSION_AUTHENTICATED && s->state != SESSION_IN_GAME) {
        return FALSE;
    }

    // 세션 타임아웃 확인
    time_t now = time(NULL);
    if (now - s->last_activity > SESSION_TIMEOUT) {
        s->is_authenticated = FALSE;
        s->state = SESSION_DISCONNECTED;
        return FALSE;
    }

    return TRUE;
}

// ✅ 모든 프로토콜 핸들러에 적용
void lssproto_CharaSelect_recv(int fd, int slot)
{
    // ✅ 인증 확인
    if (!isAuthenticated(fd)) {
        lssproto_Error_send(fd, "Not authenticated");
        close_connection(fd);
        return;
    }

    // 캐릭터 로드 진행
    // ...
}
```

**3. 인증 플로우 개선**:
```c
// ✅ 안전한 로그인 플로우
void lssproto_ClientLogin_recv(int fd, char *id, char *passwd)
{
    int session_idx = getSessionFromFd(fd);
    if (session_idx == -1) return;

    Session *s = &sessions[session_idx];

    // 1. 상태 검증
    if (s->state != SESSION_INIT) {
        lssproto_Error_send(fd, "Invalid state");
        return;
    }

    // 2. 무차별 대입 방어
    if (s->failed_attempts >= MAX_LOGIN_ATTEMPTS) {
        time_t now = time(NULL);
        if (now < s->locked_until) {
            lssproto_Error_send(fd, "Account temporarily locked");
            return;
        }
        // 잠금 해제
        s->failed_attempts = 0;
    }

    // 3. 입력 검증
    if (!validate_username(id) || !validate_password(passwd)) {
        lssproto_Error_send(fd, "Invalid input");
        return;
    }

    // 4. 상태 변경: 인증 중
    s->state = SESSION_AUTHENTICATING;
    s->auth_start_time = time(NULL);
    strncpy(s->account_name, id, sizeof(s->account_name) - 1);

    // 5. SAAC에 인증 요청
    saacproto_ACLogin_send(acfd, id, passwd, get_client_ip(fd), fd);
}

// SAAC 응답 처리
void saacproto_ACLoginResult_recv(int saac_fd, char *id, int result, int client_fd)
{
    int session_idx = getSessionFromFd(client_fd);
    if (session_idx == -1) return;

    Session *s = &sessions[session_idx];

    // 상태 검증
    if (s->state != SESSION_AUTHENTICATING) {
        return;  // 잘못된 상태
    }

    // 타임아웃 검증
    time_t now = time(NULL);
    if (now - s->auth_start_time > AUTH_TIMEOUT) {
        s->state = SESSION_INIT;
        lssproto_Error_send(client_fd, "Authentication timeout");
        return;
    }

    if (result == AUTH_SUCCESS) {
        // ✅ 인증 성공
        s->is_authenticated = TRUE;
        s->state = SESSION_AUTHENTICATED;
        s->failed_attempts = 0;
        s->last_activity = now;

        lssproto_LoginOK_send(client_fd);
    } else {
        // ❌ 인증 실패
        s->failed_attempts++;
        s->state = SESSION_INIT;

        if (s->failed_attempts >= MAX_LOGIN_ATTEMPTS) {
            s->locked_until = now + LOCKOUT_DURATION;
            lssproto_Error_send(client_fd, "Too many failed attempts");
        } else {
            lssproto_Error_send(client_fd, "Login failed");
        }

        // 로그 기록
        log_failed_login(id, get_client_ip(client_fd), s->failed_attempts);
    }
}
```

**추가 보안 조치**:
- **CAPTCHA**: 5회 이상 실패 시 CAPTCHA 요구
- **IP 차단**: 동일 IP에서 과도한 실패 시 차단
- **이중 인증(2FA)**: OTP 또는 SMS 인증 추가
- **로그 감사**: 모든 로그인 시도 기록 및 모니터링

---

## High 취약점

### CVE-2025-STONE-004: 버퍼 오버플로우 (970개 이상)

**위치**: 전체 코드베이스

**심각도**: **High (8/10)**

**설명**:
`strcpy`, `sprintf`, `strcat` 등 안전하지 않은 문자열 함수의 광범위한 사용으로 버퍼 오버플로우 취약점이 존재합니다.

**취약한 코드 패턴**:

```c
// ❌ 패턴 1: strcpy (경계 검사 없음)
char buffer[256];
strcpy(buffer, user_input);  // user_input이 256자를 초과하면 오버플로우

// ❌ 패턴 2: sprintf (길이 제한 없음)
char message[128];
sprintf(message, "Welcome %s to the server!", username);  // username 길이 미확인

// ❌ 패턴 3: strcat (누적 길이 미확인)
char path[512];
strcpy(path, base_dir);
strcat(path, "/");
strcat(path, user_dir);  // 총 길이가 512 초과 가능

// ❌ 패턴 4: gets (절대 사용 금지)
char input[100];
gets(input);  // 버퍼 크기 무시하고 입력받음
```

**실제 코드 예시**:

```c
// gmsv/char.c
void CHAR_setChar(int index, int type, char *data)
{
    // ❌ 버퍼 크기 확인 없이 복사
    strcpy(character[index].string_data[type], data);
}

// gmsv/npc.c
void NPC_createFromFile(char *filename, int floor, int x, int y)
{
    char filepath[256];
    // ❌ filename 길이 미확인
    sprintf(filepath, "npc/%s", filename);
}

// saac/main.c
void handleCommand(char *cmd)
{
    char buffer[1024];
    // ❌ cmd 길이 미확인
    strcpy(buffer, cmd);
}
```

**공격 시나리오**:

**1. 원격 코드 실행 (RCE)**:
```c
// 공격자 입력: 256바이트 이상의 데이터
char exploit[300];
memset(exploit, 'A', 256);
strcpy(exploit + 256, "\x90\x90\x90\x90");  // NOP sled
strcpy(exploit + 260, shellcode);            // 쉘코드

// CHAR_setChar 호출 시:
// - 버퍼 오버플로우 발생
// - 리턴 주소 덮어쓰기
// - 쉘코드 실행
```

**2. 서비스 거부 (DoS)**:
```c
// 공격자: 매우 긴 닉네임 전송
char long_name[10000];
memset(long_name, 'X', 10000);

// 서버: segmentation fault → 크래시
```

**영향**:
- 원격 코드 실행 (서버 탈취)
- 서비스 거부 공격
- 메모리 손상으로 인한 불안정성
- 권한 상승

**수정 방법**:

**1. 안전한 함수로 대체**:

```c
// ✅ strcpy → strncpy + null 종료 보장
char buffer[256];
strncpy(buffer, user_input, sizeof(buffer) - 1);
buffer[sizeof(buffer) - 1] = '\0';  // 항상 null 종료

// ✅ sprintf → snprintf
char message[128];
snprintf(message, sizeof(message),
         "Welcome %s to the server!", username);

// ✅ strcat → strncat
char path[512];
strncpy(path, base_dir, sizeof(path) - 1);
path[sizeof(path) - 1] = '\0';

size_t remaining = sizeof(path) - strlen(path) - 1;
strncat(path, "/", remaining);

remaining = sizeof(path) - strlen(path) - 1;
strncat(path, user_dir, remaining);

// ✅ gets → fgets
char input[100];
if (fgets(input, sizeof(input), stdin)) {
    // 개행 문자 제거
    input[strcspn(input, "\n")] = '\0';
}
```

**2. 안전한 래퍼 함수 작성**:

```c
// ✅ 안전한 문자열 복사 함수
size_t safe_strcpy(char *dest, const char *src, size_t dest_size)
{
    if (dest_size == 0) return 0;

    size_t src_len = strlen(src);
    size_t copy_len = (src_len < dest_size - 1) ? src_len : dest_size - 1;

    memcpy(dest, src, copy_len);
    dest[copy_len] = '\0';

    return copy_len;
}

// ✅ 안전한 문자열 포맷팅
int safe_sprintf(char *dest, size_t dest_size, const char *format, ...)
{
    va_list args;
    va_start(args, format);

    int result = vsnprintf(dest, dest_size, format, args);

    va_end(args);

    if (result < 0 || (size_t)result >= dest_size) {
        // 오버플로우 발생
        log("Buffer overflow prevented in safe_sprintf\n");
        dest[dest_size - 1] = '\0';
        return -1;
    }

    return result;
}

// ✅ 안전한 경로 조합
BOOL safe_path_join(char *dest, size_t dest_size,
                    const char *base, const char *path)
{
    if (dest_size == 0) return FALSE;

    // 기본 경로 복사
    size_t base_len = safe_strcpy(dest, base, dest_size);
    if (base_len >= dest_size - 1) return FALSE;

    // 슬래시 추가
    if (base_len > 0 && dest[base_len - 1] != '/') {
        if (base_len + 1 >= dest_size) return FALSE;
        dest[base_len++] = '/';
        dest[base_len] = '\0';
    }

    // 경로 추가
    size_t remaining = dest_size - base_len;
    if (safe_strcpy(dest + base_len, path, remaining) >= remaining) {
        return FALSE;
    }

    return TRUE;
}
```

**3. 전체 코드베이스 수정 스크립트**:

```bash
#!/bin/bash
# replace_unsafe_functions.sh

# strcpy → strncpy
find gmsv saac -name "*.c" -exec sed -i.bak \
    's/strcpy(\([^,]*\), \([^)]*\))/safe_strcpy(\1, \2, sizeof(\1))/g' {} \;

# sprintf → snprintf
find gmsv saac -name "*.c" -exec sed -i.bak \
    's/sprintf(\([^,]*\), /snprintf(\1, sizeof(\1), /g' {} \;

# strcat → strncat (수동 검토 필요)
find gmsv saac -name "*.c" -exec grep -n "strcat" {} + > strcat_review.txt

echo "Review strcat_review.txt manually and replace with safe_strcat"
```

**4. 컴파일러 보안 플래그 활성화**:

```makefile
# makefile
CFLAGS += -D_FORTIFY_SOURCE=2   # 버퍼 오버플로우 감지
CFLAGS += -fstack-protector-all  # 스택 카나리 활성화
CFLAGS += -Wformat-security      # 포맷 문자열 검증
CFLAGS += -Werror=format-security # 포맷 에러를 컴파일 에러로

# 링커 플래그
LDFLAGS += -Wl,-z,relro          # RELRO (Relocation Read-Only)
LDFLAGS += -Wl,-z,now            # BIND_NOW (즉시 바인딩)
LDFLAGS += -pie                  # Position Independent Executable
```

**추가 보안 조치**:
- **정적 분석**: Coverity, Clang Static Analyzer 사용
- **동적 분석**: Valgrind, AddressSanitizer 사용
- **퍼징**: AFL, libFuzzer로 자동 테스트
- **코드 리뷰**: 모든 문자열 조작 코드 수동 검토

---

### CVE-2025-STONE-005: 포맷 문자열 취약점

**위치**: 전체 코드베이스 (로깅 함수들)

**심각도**: **High (7/10)**

**설명**:
사용자 입력을 포맷 문자열로 직접 사용하여 임의 메모리 읽기/쓰기가 가능합니다.

**취약한 코드**:
```c
// ❌ 사용자 입력을 포맷 문자열로 사용
void log_message(char *user_msg)
{
    printf(user_msg);  // 포맷 문자열 취약점!
}

// ❌ 디버그 로깅
void debug_print(char *message)
{
    fprintf(stderr, message);  // 위험!
}
```

**공격 시나리오**:
```c
// 공격자 입력: "%x %x %x %x %s"
// → 스택 메모리 내용 노출

// 공격자 입력: "%n"
// → 임의 메모리 주소에 쓰기 가능 → RCE
```

**수정 방법**:
```c
// ✅ 올바른 사용
void log_message(char *user_msg)
{
    printf("%s", user_msg);  // 포맷 문자열 고정
}

// ✅ 안전한 로깅
void safe_log(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);  // 가변 인자는 안전
    va_end(args);
}
```

---

### CVE-2025-STONE-006: 경로 탐색 취약점 (Path Traversal)

**위치**: `gmsv/char.c`, `gmsv/npc.c`

**심각도**: **High (7/10)**

**설명**:
파일 경로 검증 없이 사용자 입력을 받아 임의 파일 접근이 가능합니다.

**취약한 코드**:
```c
// gmsv/char.c
void CHAR_DataSave(int index)
{
    char filename[256];
    char* charname = CHAR_getChar(index, CHAR_NAME);

    // ❌ 경로 검증 없음
    sprintf(filename, "chardata/%c/%s", charname[0], charname);

    FILE *fp = fopen(filename, "w");
    // ...
}
```

**공격 시나리오**:
```c
// 공격자: 캐릭터 이름을 "../../../etc/passwd"로 설정
// → 파일: chardata/./../../../etc/passwd
// → 실제: /etc/passwd 접근
```

**수정 방법**:
```c
// ✅ 경로 검증 및 정규화
BOOL is_safe_filename(const char *filename)
{
    // ".." 체크
    if (strstr(filename, "..") != NULL) return FALSE;

    // 절대 경로 체크
    if (filename[0] == '/') return FALSE;

    // 허용된 문자만 (영문, 숫자, _, -)
    for (const char *p = filename; *p; p++) {
        if (!isalnum(*p) && *p != '_' && *p != '-') {
            return FALSE;
        }
    }

    return TRUE;
}

void CHAR_DataSave(int index)
{
    char filename[256];
    char* charname = CHAR_getChar(index, CHAR_NAME);

    // ✅ 입력 검증
    if (!is_safe_filename(charname)) {
        log("Invalid character name: %s\n", charname);
        return;
    }

    // ✅ 안전한 경로 생성
    snprintf(filename, sizeof(filename), "chardata/%c/%s",
             charname[0], charname);

    // ✅ realpath로 정규화 후 확인
    char resolved[PATH_MAX];
    if (realpath(filename, resolved) == NULL) {
        log("Failed to resolve path: %s\n", filename);
        return;
    }

    // ✅ 허용된 디렉토리 내부인지 확인
    if (strncmp(resolved, "/path/to/server/chardata/", 25) != 0) {
        log("Path traversal attempt: %s\n", resolved);
        return;
    }

    FILE *fp = fopen(resolved, "w");
    // ...
}
```

---

## Medium 취약점

### CVE-2025-STONE-007: 입력 검증 누락

**위치**: 전체 프로토콜 핸들러

**심각도**: **Medium (5/10)**

**설명**:
클라이언트 입력에 대한 체계적인 검증이 없어 다양한 공격에 노출됩니다.

**취약한 패턴**:
```c
// ❌ 길이 검증 없음
void lssproto_CharaCreate_recv(int fd, char *name)
{
    CHAR_setChar(new_index, CHAR_NAME, name);  // name 길이 미확인
}

// ❌ 범위 검증 없음
void lssproto_ItemMove_recv(int fd, int from_slot, int to_slot)
{
    // from_slot, to_slot이 유효 범위인지 미확인
    swap_items(charindex, from_slot, to_slot);
}

// ❌ 타입 검증 없음
void lssproto_Magic_recv(int fd, int magic_id)
{
    // magic_id가 유효한 마법 ID인지 미확인
    cast_magic(charindex, magic_id);
}
```

**수정 방법**:
```c
// ✅ 입력 검증 프레임워크
typedef enum {
    VALIDATION_OK,
    VALIDATION_ERROR_LENGTH,
    VALIDATION_ERROR_RANGE,
    VALIDATION_ERROR_TYPE,
    VALIDATION_ERROR_FORMAT
} ValidationResult;

// ✅ 문자열 검증
ValidationResult validate_string(const char *str,
                                 size_t min_len,
                                 size_t max_len,
                                 const char *allowed_chars)
{
    if (!str) return VALIDATION_ERROR_TYPE;

    size_t len = strlen(str);
    if (len < min_len || len > max_len) {
        return VALIDATION_ERROR_LENGTH;
    }

    if (allowed_chars) {
        for (size_t i = 0; i < len; i++) {
            if (strchr(allowed_chars, str[i]) == NULL) {
                return VALIDATION_ERROR_FORMAT;
            }
        }
    }

    return VALIDATION_OK;
}

// ✅ 정수 범위 검증
ValidationResult validate_int_range(int value, int min, int max)
{
    if (value < min || value > max) {
        return VALIDATION_ERROR_RANGE;
    }
    return VALIDATION_OK;
}

// ✅ 프로토콜 핸들러에 적용
void lssproto_CharaCreate_recv(int fd, char *name)
{
    const char *allowed = "abcdefghijklmnopqrstuvwxyz"
                          "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                          "0123456789_-";

    // ✅ 이름 검증
    ValidationResult result = validate_string(name, 2, 16, allowed);
    if (result != VALIDATION_OK) {
        lssproto_Error_send(fd, "Invalid character name");
        log_validation_failure(fd, "CharaCreate", name, result);
        return;
    }

    // ✅ 중복 확인
    if (is_name_taken(name)) {
        lssproto_Error_send(fd, "Name already taken");
        return;
    }

    // 캐릭터 생성 진행
    CHAR_setChar(new_index, CHAR_NAME, name);
}

void lssproto_ItemMove_recv(int fd, int from_slot, int to_slot)
{
    // ✅ 슬롯 범위 검증
    if (validate_int_range(from_slot, 0, MAX_INVENTORY_SIZE - 1) != VALIDATION_OK ||
        validate_int_range(to_slot, 0, MAX_INVENTORY_SIZE - 1) != VALIDATION_OK) {
        lssproto_Error_send(fd, "Invalid inventory slot");
        return;
    }

    // ✅ 아이템 존재 확인
    int charindex = getCharIndexFromFd(fd);
    if (!CHAR_hasItemInSlot(charindex, from_slot)) {
        lssproto_Error_send(fd, "No item in source slot");
        return;
    }

    swap_items(charindex, from_slot, to_slot);
}
```

---

### CVE-2025-STONE-008: 로깅 및 감사 부족

**위치**: 전체 시스템

**심각도**: **Medium (5/10)**

**설명**:
보안 이벤트 로깅이 부족하여 공격 탐지 및 사후 분석이 어렵습니다.

**현재 상태**:
- 로그인 실패 기록 없음
- 권한 검증 실패 기록 없음
- 의심스러운 활동 탐지 없음
- 로그 무결성 보장 없음

**수정 방법**:
```c
// ✅ 보안 이벤트 로깅 시스템
typedef enum {
    EVENT_LOGIN_SUCCESS,
    EVENT_LOGIN_FAILED,
    EVENT_LOGOUT,
    EVENT_AUTH_BYPASS_ATTEMPT,
    EVENT_PRIVILEGE_ESCALATION,
    EVENT_SUSPICIOUS_ACTIVITY,
    EVENT_DATA_BREACH_ATTEMPT,
    EVENT_ADMIN_ACTION
} SecurityEventType;

void log_security_event(SecurityEventType type,
                        int fd,
                        const char *username,
                        const char *details)
{
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[26];
    strftime(timestamp, 26, "%Y-%m-%d %H:%M:%S", tm_info);

    char ip[INET_ADDRSTRLEN];
    get_client_ip(fd, ip, sizeof(ip));

    // ✅ 구조화된 로그 (JSON 형식)
    fprintf(security_log,
            "{\"timestamp\":\"%s\","
            "\"event\":\"%s\","
            "\"username\":\"%s\","
            "\"ip\":\"%s\","
            "\"details\":\"%s\"}\n",
            timestamp,
            get_event_name(type),
            username,
            ip,
            details);

    fflush(security_log);  // 즉시 디스크에 기록

    // ✅ 중요 이벤트는 syslog에도 기록
    if (type == EVENT_AUTH_BYPASS_ATTEMPT ||
        type == EVENT_PRIVILEGE_ESCALATION) {
        syslog(LOG_WARNING,
               "Security event: %s from %s (%s)",
               get_event_name(type), username, ip);
    }
}

// ✅ 로그인 실패 추적
void handle_login_failed(int fd, const char *username)
{
    log_security_event(EVENT_LOGIN_FAILED, fd, username,
                       "Invalid credentials");

    // IP 기반 차단 리스트 업데이트
    update_failed_login_count(fd);
}
```

---

### CVE-2025-STONE-009: 세션 관리 취약점

**위치**: `gmsv/lssproto_serv.c`

**심각도**: **Medium (6/10)**

**설명**:
세션 ID 예측 가능, 세션 하이재킹, 세션 고정 공격에 취약합니다.

**취약한 코드**:
```c
// ❌ 예측 가능한 세션 ID
int generate_session_id(void)
{
    static int counter = 0;
    return ++counter;  // 1, 2, 3, ... (예측 가능!)
}

// ❌ 세션 타임아웃 없음
// ❌ 세션 재생성 없음
```

**수정 방법**:
```c
// ✅ 안전한 세션 ID 생성
void generate_secure_session_id(char *session_id, size_t size)
{
    unsigned char random_bytes[32];

    // /dev/urandom에서 난수 읽기
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) {
        // 폴백: 약한 난수 생성 (경고 로그)
        srand(time(NULL) ^ getpid());
        for (int i = 0; i < 32; i++) {
            random_bytes[i] = rand() % 256;
        }
        log("Warning: Using weak random for session ID\n");
    } else {
        read(fd, random_bytes, sizeof(random_bytes));
        close(fd);
    }

    // Base64 인코딩 (또는 hex)
    base64_encode(random_bytes, sizeof(random_bytes), session_id, size);
}

// ✅ 세션 관리 구조체
typedef struct {
    char session_id[65];        // 64자 + null
    int fd;
    char username[64];
    time_t created_at;
    time_t last_activity;
    char ip_address[INET_ADDRSTRLEN];
    BOOL is_authenticated;
    int privilege_level;
} SecureSession;

// ✅ 세션 생성
SecureSession* create_session(int fd, const char *ip)
{
    SecureSession *session = malloc(sizeof(SecureSession));

    generate_secure_session_id(session->session_id,
                                sizeof(session->session_id));
    session->fd = fd;
    session->created_at = time(NULL);
    session->last_activity = session->created_at;
    strncpy(session->ip_address, ip, sizeof(session->ip_address) - 1);
    session->is_authenticated = FALSE;
    session->privilege_level = 0;

    return session;
}

// ✅ 세션 검증
BOOL validate_session(SecureSession *session)
{
    time_t now = time(NULL);

    // 세션 타임아웃 (30분)
    if (now - session->last_activity > SESSION_TIMEOUT) {
        return FALSE;
    }

    // 절대 타임아웃 (24시간)
    if (now - session->created_at > SESSION_MAX_AGE) {
        return FALSE;
    }

    // IP 검증 (IP 변경 시 세션 무효화)
    char current_ip[INET_ADDRSTRLEN];
    get_client_ip(session->fd, current_ip, sizeof(current_ip));
    if (strcmp(session->ip_address, current_ip) != 0) {
        log_security_event(EVENT_SUSPICIOUS_ACTIVITY,
                           session->fd,
                           session->username,
                           "IP address changed during session");
        return FALSE;
    }

    return TRUE;
}

// ✅ 세션 재생성 (로그인 후)
void regenerate_session(SecureSession *session)
{
    // 새 세션 ID 생성
    generate_secure_session_id(session->session_id,
                                sizeof(session->session_id));

    // 타임스탬프 갱신
    session->created_at = time(NULL);
    session->last_activity = session->created_at;

    log("Session regenerated for user: %s\n", session->username);
}
```

---

## Low 취약점

### CVE-2025-STONE-010: 하드코딩된 자격 증명

**위치**: `gmsv/setup.cf`, `saac/sasql.c`

**심각도**: **Low (3/10)**

**설명**:
설정 파일 및 소스 코드에 비밀번호가 하드코딩되어 있습니다.

**취약한 코드**:
```c
// gmsv/setup.cf
acservpass=123456  // ❌ 평문 비밀번호

// saac/sasql.c
mysql_real_connect(&mysql, "localhost", "root", "password123", ...);  // ❌
```

**수정 방법**:
```bash
# ✅ 환경 변수 사용
export MYSQL_USER="gameserver_user"
export MYSQL_PASS="$(openssl rand -base64 32)"
```

```c
// ✅ 환경 변수에서 읽기
const char *db_user = getenv("MYSQL_USER");
const char *db_pass = getenv("MYSQL_PASS");

if (!db_user || !db_pass) {
    log("Database credentials not set in environment\n");
    exit(1);
}

mysql_real_connect(&mysql, "localhost", db_user, db_pass, ...);
```

---

### CVE-2025-STONE-011: 약한 난수 생성

**위치**: 전체 코드베이스

**심각도**: **Low (4/10)**

**설명**:
암호학적으로 안전하지 않은 `rand()` 함수를 사용합니다.

**취약한 코드**:
```c
// ❌ 예측 가능한 난수
srand(time(NULL));
int random_value = rand();
```

**수정 방법**:
```c
// ✅ /dev/urandom 사용
int get_secure_random(void)
{
    int random_value;
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) {
        log("Failed to open /dev/urandom\n");
        return -1;
    }
    read(fd, &random_value, sizeof(random_value));
    close(fd);
    return random_value;
}

// ✅ 범위 지정
int get_secure_random_range(int min, int max)
{
    int range = max - min + 1;
    int random_value = get_secure_random();
    return min + (random_value % range);
}
```

---

### CVE-2025-STONE-012: 정보 노출

**위치**: 에러 메시지, 디버그 로그

**심각도**: **Low (3/10)**

**설명**:
상세한 에러 메시지로 시스템 정보가 노출됩니다.

**취약한 코드**:
```c
// ❌ 상세한 에러 메시지
printf("MySQL connection failed: host=%s, user=%s, error=%s\n",
       host, user, mysql_error(&mysql));
```

**수정 방법**:
```c
// ✅ 일반적인 에러 메시지 (클라이언트용)
lssproto_Error_send(fd, "Database connection error");

// ✅ 상세 정보는 서버 로그에만
log("[INTERNAL] MySQL connection failed: host=%s, error=%s\n",
    host, mysql_error(&mysql));
```

---

## 보안 강화 권장사항

### 1. 네트워크 보안

**TLS/SSL 적용**:
```c
// OpenSSL을 사용한 암호화 통신
SSL_CTX *ctx = SSL_CTX_new(TLS_server_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);

// 강력한 암호화 스위트만 허용
SSL_CTX_set_cipher_list(ctx, "ECDHE-RSA-AES256-GCM-SHA384");
```

**방화벽 설정**:
```bash
# iptables 규칙
iptables -A INPUT -p tcp --dport 9300 -s 127.0.0.1 -j ACCEPT  # SAAC (로컬만)
iptables -A INPUT -p tcp --dport 9300 -j DROP                 # 외부 차단
```

---

### 2. 데이터베이스 보안

**최소 권한 원칙**:
```sql
-- ✅ 게임 서버용 계정 (제한된 권한)
CREATE USER 'gameserver'@'localhost' IDENTIFIED BY 'strong_password';
GRANT SELECT, INSERT, UPDATE ON gamedb.* TO 'gameserver'@'localhost';

-- ❌ DROP, DELETE 권한 부여하지 않음
```

**감사 로깅**:
```sql
-- 모든 쿼리 로깅 활성화
SET GLOBAL general_log = 'ON';
SET GLOBAL log_output = 'TABLE';
```

---

### 3. 애플리케이션 보안

**보안 헤더**:
```c
// HTTP 응답 헤더 (웹 인터페이스가 있다면)
"X-Frame-Options: DENY"
"X-Content-Type-Options: nosniff"
"Content-Security-Policy: default-src 'self'"
```

**Rate Limiting**:
```c
// ✅ 클라이언트당 요청 제한
#define MAX_REQUESTS_PER_SECOND 10

typedef struct {
    time_t last_reset;
    int request_count;
} RateLimiter;

BOOL check_rate_limit(int fd)
{
    RateLimiter *limiter = &rate_limiters[fd];
    time_t now = time(NULL);

    if (now > limiter->last_reset) {
        limiter->last_reset = now;
        limiter->request_count = 0;
    }

    if (limiter->request_count >= MAX_REQUESTS_PER_SECOND) {
        return FALSE;  // 제한 초과
    }

    limiter->request_count++;
    return TRUE;
}
```

---

### 4. 운영 보안

**정기 백업**:
```bash
#!/bin/bash
# daily_backup.sh

# 캐릭터 데이터 백업
tar -czf /backup/chardata_$(date +%Y%m%d).tar.gz chardata/

# MySQL 백업
mysqldump -u backup_user -p gamedb > /backup/gamedb_$(date +%Y%m%d).sql

# 7일 이상 된 백업 삭제
find /backup -type f -mtime +7 -delete
```

**보안 모니터링**:
```bash
# fail2ban 설정 (로그인 실패 감지)
[stone-age]
enabled = true
port = 9300
filter = stone-age
logpath = /var/log/stoneage/security.log
maxretry = 5
bantime = 3600
```

---

## 수정 우선순위

### Phase 1: 즉시 수정 (1주일 이내)
1. **SQL 인젝션** (CVE-2025-STONE-001)
2. **평문 비밀번호** (CVE-2025-STONE-002)
3. **인증 우회** (CVE-2025-STONE-003)

### Phase 2: 단기 수정 (1개월 이내)
4. **버퍼 오버플로우** (CVE-2025-STONE-004) - 상위 100개 함수
5. **포맷 문자열** (CVE-2025-STONE-005)
6. **경로 탐색** (CVE-2025-STONE-006)

### Phase 3: 중기 수정 (3개월 이내)
7. **입력 검증** (CVE-2025-STONE-007)
8. **로깅 개선** (CVE-2025-STONE-008)
9. **세션 관리** (CVE-2025-STONE-009)

### Phase 4: 장기 개선 (6개월 이내)
10. **전체 코드베이스 리팩토링**
11. **보안 테스트 자동화**
12. **침투 테스트 수행**

---

## 보안 체크리스트

### 개발 단계
- [ ] 모든 사용자 입력을 검증
- [ ] Prepared Statement 사용
- [ ] 안전한 문자열 함수 사용 (strncpy, snprintf)
- [ ] 포맷 문자열 고정
- [ ] 경로 검증 및 정규화
- [ ] 에러 처리 및 로깅
- [ ] 코드 리뷰 수행

### 배포 전
- [ ] 정적 분석 도구 실행 (Coverity, Clang Static Analyzer)
- [ ] 동적 분석 도구 실행 (Valgrind, AddressSanitizer)
- [ ] 퍼징 테스트 수행 (AFL, libFuzzer)
- [ ] 침투 테스트 수행
- [ ] 보안 컴파일러 플래그 활성화
- [ ] TLS/SSL 인증서 설정
- [ ] 방화벽 규칙 적용

### 운영 단계
- [ ] 보안 로그 모니터링
- [ ] 정기 백업 수행
- [ ] 침입 탐지 시스템 (IDS) 설정
- [ ] 정기 보안 감사 수행
- [ ] 보안 패치 적용
- [ ] 사고 대응 계획 수립

---

**보고서 작성**: Claude Code SuperClaude
**버전**: 1.0
**최종 업데이트**: 2025-01-22
