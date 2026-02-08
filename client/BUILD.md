# Stone Age 8.5 클라이언트 빌드 가이드

## 개요

Stone Age 8.5 클라이언트는 Windows 기반 DirectX 애플리케이션입니다.

**빌드 환경**:
- **개발/빌드**: macOS (Visual Studio Code + Wine)
- **실행**: Windows 7/10/11

---

## 전제 조건

### macOS 빌드 환경 (개발용)

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Wine 설치 (Windows 바이너리 실행용)
brew install --cask wine-stable

# MinGW 크로스 컴파일러 (선택사항)
brew install mingw-w64
```

### Windows 실행 환경

- **OS**: Windows 7 이상 (64비트 권장)
- **DirectX**: DirectX 9.0c 이상
- **해상도**: 800x600 이상
- **RAM**: 최소 512MB

---

## 빌드 방법

### 방법 1: 기존 바이너리 사용 (권장)

프로젝트에 이미 컴파일된 클라이언트 바이너리가 포함되어 있습니다:

```bash
# 클라이언트 디렉토리로 이동
cd /Users/gwang/Desktop/StoneAge/stone-age-master/石器时代客户端最新完整源代码

# Windows 실행 파일 확인
ls -la *.exe

# 예상 파일:
# - Stoneage.exe (메인 클라이언트)
# - Setup.exe (설정 도구)
# - Patcher.exe (패처)
```

**배포 방법**:
1. 전체 `石器时代客户端最新完整源代码` 디렉토리를 압축
2. Windows 머신으로 전송
3. 압축 해제 후 `Stoneage.exe` 실행

### 방법 2: macOS에서 Wine으로 테스트

```bash
# Wine 설정 (최초 1회)
winecfg

# 클라이언트 실행 테스트
cd 石器时代客户端最新完整源代码
wine Stoneage.exe
```

⚠️ **주의**: Wine은 테스트용이며, 실제 플레이는 Windows 환경 권장

### 방법 3: 소스에서 리빌드 (고급)

현재 소스코드 구조:
```
石器时代客户端最新完整源代码/
├── src/              # C/C++ 소스 코드
├── include/          # 헤더 파일
├── resources/        # 리소스 파일 (이미지, 사운드)
└── build/            # 빌드 스크립트 (있는 경우)
```

**Windows Visual Studio에서 빌드**:
1. Windows 머신에 Visual Studio 2019/2022 설치
2. DirectX SDK 설치
3. 프로젝트 파일(`.sln` 또는 `.vcxproj`) 열기
4. Release 빌드 실행

**macOS MinGW 크로스 컴파일** (실험적):
```bash
# MinGW 컴파일 (소스 구조에 따라 수정 필요)
cd 石器时代客户端最新完整源代码
i686-w64-mingw32-gcc -o Stoneage.exe src/*.c -I include -mwindows
```

---

## 클라이언트 설정

### 서버 연결 설정

클라이언트가 로컬/프로덕션 서버에 연결하도록 설정:

**방법 1: 설정 파일 수정** (`config.ini` 또는 `server.ini`):
```ini
[Server]
IP=127.0.0.1        # 로컬: 127.0.0.1, 프로덕션: 실제 서버 IP
Port=19065           # GMSV 포트
LoginIP=127.0.0.1   # SAAC 서버 IP (경우에 따라)
LoginPort=10001     # SAAC 포트 (경우에 따라)
```

**방법 2: 게임 내 설정 UI** (있는 경우):
- 게임 실행 후 서버 목록에서 선택
- 직접 IP 입력 옵션 사용

### 그래픽 설정

`Setup.exe` 실행하여 설정:
- **해상도**: 800x600 (기본), 1024x768, 1280x720
- **컬러**: 16비트 또는 32비트
- **전체화면/창모드**: 선택 가능

---

## Windows 배포 패키지 생성

### macOS에서 배포 패키지 준비

```bash
# 1. 클라이언트 디렉토리로 이동
cd /Users/gwang/Desktop/StoneAge/stone-age-master

# 2. 배포용 디렉토리 생성
mkdir -p client/windows-release

# 3. 필요한 파일만 복사
cp -r 石器时代客户端最新完整源代码/*.exe client/windows-release/
cp -r 石器时代客户端最新完整源代码/*.dll client/windows-release/
cp -r 石器时代客户端最新完整源代码/data client/windows-release/
cp -r 石器时代客户端最新完整源代码/graphics client/windows-release/
cp -r 石器时代客户端最新完整源代码/music client/windows-release/
cp -r 石器时代客户端最新完整源代码/sound client/windows-release/

# 4. 설정 파일 복사 (있는 경우)
cp 石器时代客户端最新完整源代码/*.ini client/windows-release/ 2>/dev/null || true

# 5. 압축 (Windows 전송용)
cd client
zip -r StoneAge85_Client_Windows.zip windows-release/

echo "배포 패키지 생성 완료: client/StoneAge85_Client_Windows.zip"
```

### Windows에서 설치

1. `StoneAge85_Client_Windows.zip` 압축 해제
2. `Setup.exe` 실행하여 그래픽 설정
3. 서버 설정 (IP/Port) 확인
4. `Stoneage.exe` 실행

---

## 테스트 체크리스트

### 로컬 개발 환경 테스트

```bash
# 1. macOS에서 서버 시작
./scripts/start-local-macos.sh

# 2. Windows VM 또는 Wine에서 클라이언트 실행
wine client/windows-release/Stoneage.exe

# 3. 연결 확인
# - 서버 목록에서 "로컬개발서버" 선택
# - IP: 127.0.0.1 (또는 macOS 호스트 IP)
# - Port: 19065
```

### 테스트 시나리오

1. **회원가입**:
   - 클라이언트 실행 → "회원가입" 클릭
   - ID/PW 입력 → 가입 완료 확인

2. **로그인**:
   - 등록한 ID/PW로 로그인
   - 서버 선택 화면 표시 확인

3. **캐릭터 생성**:
   - 캐릭터 이름, 외형 선택
   - 생성 완료 → 캐릭터 목록에 표시 확인

4. **게임 진입**:
   - 캐릭터 선택 → 게임 월드 로딩
   - 마을 진입 및 NPC 상호작용 확인

---

## 트러블슈팅

### 클라이언트가 서버에 연결되지 않음

**증상**: "서버에 연결할 수 없습니다" 오류

**해결책**:
1. 서버가 실행 중인지 확인: `ps aux | grep -E 'saac|gmsv'`
2. 포트가 리스닝 중인지 확인: `lsof -i :19065` (macOS) 또는 `netstat -an | grep 19065` (Linux)
3. 방화벽 확인: `sudo ufw status` (Linux)
4. 클라이언트 설정 파일에서 IP/Port 재확인

### DirectX 관련 오류 (Windows)

**증상**: "d3d9.dll not found" 또는 DirectX 오류

**해결책**:
1. DirectX End-User Runtime 설치: https://www.microsoft.com/en-us/download/details.aspx?id=35
2. Visual C++ Redistributable 설치: https://aka.ms/vs/17/release/vc_redist.x86.exe

### Wine 실행 오류 (macOS)

**증상**: Wine에서 실행 안 됨

**해결책**:
1. Wine 재설치: `brew reinstall --cask wine-stable`
2. 32비트 환경 설정: `WINEARCH=win32 WINEPREFIX=~/.wine32 winecfg`
3. Windows 머신에서 실행 (Wine은 테스트용)

---

## 고급 설정

### 클라이언트 소스 수정

서버 IP 하드코딩 (재컴파일 필요):

```c
// src/network.c (예시)
#define DEFAULT_SERVER_IP "your.server.ip"
#define DEFAULT_SERVER_PORT 19065
```

### 커스텀 리소스

- **그래픽**: `graphics/` 디렉토리에서 PNG/BMP 교체
- **사운드**: `sound/` 디렉토리에서 WAV 교체
- **음악**: `music/` 디렉토리에서 MP3/MIDI 교체

---

## 참고 자료

- **원본 GitHub**: https://github.com/anson1788/stoneage
- **서버 빌드 가이드**: `../scripts/build-server-macos.sh`
- **서버 실행 가이드**: `../scripts/start-local-macos.sh`
