#!/bin/bash
# Stone Age 8.5 - Linux 프로덕션 서버 빌드 스크립트

set -e  # 오류 발생 시 중단

echo "========================================"
echo "Stone Age 8.5 Server Build (Linux)"
echo "========================================"
echo

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# 색상 출력
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. 필수 도구 확인
echo "${YELLOW}[1/5] 필수 도구 확인 중...${NC}"

if ! command -v gcc &> /dev/null; then
    echo "${RED}ERROR: GCC가 설치되어 있지 않습니다.${NC}"
    echo "다음 명령어로 설치하세요:"
    echo "  sudo apt-get install build-essential"
    exit 1
fi

if ! command -v mysql_config &> /dev/null; then
    echo "${RED}ERROR: MySQL 개발 패키지가 설치되어 있지 않습니다.${NC}"
    echo "다음 명령어로 설치하세요:"
    echo "  sudo apt-get install libmysqlclient-dev"
    exit 1
fi

echo "${GREEN}✓ GCC 발견: $(gcc --version | head -1)${NC}"
echo "${GREEN}✓ MySQL 발견: $(mysql_config --version)${NC}"
echo

# 2. MySQL 라이브러리 경로 설정
echo "${YELLOW}[2/5] MySQL 라이브러리 경로 설정 중...${NC}"

MYSQL_INCLUDE=$(mysql_config --include)
MYSQL_LIBS=$(mysql_config --libs)

echo "MySQL Include: $MYSQL_INCLUDE"
echo "MySQL Libs: $MYSQL_LIBS"
echo

# 3. SAAC 빌드
echo "${YELLOW}[3/5] SAAC 서버 빌드 중...${NC}"

cd "$PROJECT_ROOT/石器时代服务器端最新完整源代码/saac"

# Makefile 수정 (MySQL 경로 추가)
if [ -f Makefile ]; then
    # 백업
    cp Makefile Makefile.bak

    # MySQL 경로를 Makefile에 추가 (Linux sed syntax)
    sed -i "s|CFLAGS.*=|CFLAGS = -O2 -Wall $MYSQL_INCLUDE|g" Makefile
    sed -i "s|LDFLAGS.*=|LDFLAGS = $MYSQL_LIBS|g" Makefile
fi

# 빌드
make clean 2>/dev/null || true
if make; then
    echo "${GREEN}✓ SAAC 빌드 성공${NC}"
else
    echo "${RED}✗ SAAC 빌드 실패${NC}"
    exit 1
fi

# 실행 권한 부여
chmod +x saac

echo

# 4. GMSV 빌드
echo "${YELLOW}[4/5] GMSV 서버 빌드 중...${NC}"

cd "$PROJECT_ROOT/石器时代服务器端最新完整源代码/gmsv"

# Makefile 수정
if [ -f Makefile ]; then
    cp Makefile Makefile.bak
    sed -i "s|CFLAGS.*=|CFLAGS = -O2 -Wall $MYSQL_INCLUDE|g" Makefile
    sed -i "s|LDFLAGS.*=|LDFLAGS = $MYSQL_LIBS|g" Makefile
fi

# 빌드
make clean 2>/dev/null || true
if make; then
    echo "${GREEN}✓ GMSV 빌드 성공${NC}"
else
    echo "${RED}✗ GMSV 빌드 실패${NC}"
    exit 1
fi

# 실행 권한 부여
chmod +x gmsv

echo

# 5. 필수 디렉토리 생성
echo "${YELLOW}[5/5] 필수 디렉토리 생성 중...${NC}"

cd "$PROJECT_ROOT"

mkdir -p data log lock char char_sleep data/wklog mail \
         data/family data/fmpointdir data/fmsmemodir \
         石器时代服务器端最新完整源代码/gmsv/log

echo "${GREEN}✓ 디렉토리 생성 완료${NC}"
echo

# 완료
echo "========================================"
echo "${GREEN}✓ 빌드 완료!${NC}"
echo "========================================"
echo
echo "다음 명령어로 서버를 실행하세요:"
echo "  ./scripts/start-production-linux.sh"
echo
