#!/bin/bash
# Stone Age 8.5 - Linux 프로덕션 서버 실행 스크립트

set -e

echo "========================================"
echo "Stone Age 8.5 - 프로덕션 서버 시작"
echo "========================================"
echo

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 서버 바이너리 확인
echo "${YELLOW}[1/6] 서버 바이너리 확인 중...${NC}"

SAAC_BIN="$PROJECT_ROOT/石器时代服务器端最新完整源代码/saac/saac"
GMSV_BIN="$PROJECT_ROOT/石器时代服务器端最新完整源代码/gmsv/gmsv"

if [ ! -f "$SAAC_BIN" ]; then
    echo "${RED}ERROR: SAAC 바이너리를 찾을 수 없습니다.${NC}"
    echo "먼저 빌드를 실행하세요:"
    echo "  ./scripts/build-server-linux.sh"
    exit 1
fi

if [ ! -f "$GMSV_BIN" ]; then
    echo "${RED}ERROR: GMSV 바이너리를 찾을 수 없습니다.${NC}"
    echo "먼저 빌드를 실행하세요:"
    echo "  ./scripts/build-server-linux.sh"
    exit 1
fi

echo "${GREEN}✓ 서버 바이너리 확인 완료${NC}"
echo

# 2. MySQL 확인
echo "${YELLOW}[2/6] MySQL 서비스 확인 중...${NC}"

if ! systemctl is-active --quiet mysql; then
    echo "${YELLOW}MySQL이 실행되고 있지 않습니다. 시작합니다...${NC}"
    sudo systemctl start mysql
    sleep 3
fi

# MySQL 접속 확인 (프로덕션 계정 사용)
if mysql -u stoneage_prod -p -e "SELECT 1;" > /dev/null 2>&1; then
    echo "${GREEN}✓ MySQL 연결 성공${NC}"
else
    echo "${RED}ERROR: MySQL에 연결할 수 없습니다.${NC}"
    echo "프로덕션 MySQL 계정(stoneage_prod)과 비밀번호를 확인하세요."
    exit 1
fi

# CSA 데이터베이스 확인
if ! mysql -u stoneage_prod -p -e "USE CSA;" > /dev/null 2>&1; then
    echo "${YELLOW}CSA 데이터베이스가 없습니다. 생성합니다...${NC}"
    mysql -u root -p < "$PROJECT_ROOT/CSA.sql"
    echo "${GREEN}✓ CSA 데이터베이스 생성 완료${NC}"
else
    echo "${GREEN}✓ CSA 데이터베이스 존재${NC}"
fi

echo

# 3. 설정 파일 복사 및 비밀번호 확인
echo "${YELLOW}[3/6] 프로덕션 환경 설정 파일 적용 중...${NC}"

cp "$PROJECT_ROOT/environments/production-linux/acserv.cf" "$PROJECT_ROOT/acserv.cf"
cp "$PROJECT_ROOT/environments/production-linux/setup.cf" "$PROJECT_ROOT/setup.cf"

# 비밀번호 플레이스홀더 확인
if grep -q "CHANGE_THIS" "$PROJECT_ROOT/acserv.cf" || grep -q "CHANGE_THIS" "$PROJECT_ROOT/setup.cf"; then
    echo "${RED}ERROR: 설정 파일에 비밀번호 플레이스홀더가 남아있습니다!${NC}"
    echo "다음 파일들의 'CHANGE_THIS_*' 항목을 실제 비밀번호로 변경하세요:"
    echo "  - environments/production-linux/acserv.cf"
    echo "  - environments/production-linux/setup.cf"
    exit 1
fi

echo "${GREEN}✓ 설정 파일 복사 완료${NC}"
echo

# 4. 기존 서버 프로세스 종료
echo "${YELLOW}[4/6] 기존 서버 프로세스 확인 중...${NC}"

if pgrep -x "saac" > /dev/null; then
    echo "${YELLOW}기존 SAAC 프로세스를 종료합니다...${NC}"
    pkill -x saac
    sleep 1
fi

if pgrep -x "gmsv" > /dev/null; then
    echo "${YELLOW}기존 GMSV 프로세스를 종료합니다...${NC}"
    pkill -x gmsv
    sleep 1
fi

echo "${GREEN}✓ 프로세스 정리 완료${NC}"
echo

# 5. SAAC 시작
echo "${YELLOW}[5/6] SAAC 서버 시작 중...${NC}"

cd "$PROJECT_ROOT"
nohup ./石器时代服务器端最新完整源代码/saac/saac -f acserv.cf > log/saac.log 2>&1 &
SAAC_PID=$!

# SAAC 시작 대기
sleep 3

if ps -p $SAAC_PID > /dev/null; then
    echo "${GREEN}✓ SAAC 시작 성공 (PID: $SAAC_PID)${NC}"

    # 포트 확인
    if netstat -tln | grep ":10001" > /dev/null 2>&1; then
        echo "${GREEN}✓ SAAC 포트 10001 리스닝 중${NC}"
    else
        echo "${RED}WARNING: SAAC 포트 10001이 리스닝 중이 아닙니다.${NC}"
    fi
else
    echo "${RED}ERROR: SAAC 시작 실패${NC}"
    echo "로그를 확인하세요: tail -f log/saac.log"
    exit 1
fi

echo

# 6. GMSV 시작
echo "${YELLOW}[6/6] GMSV 서버 시작 중...${NC}"

cd "$PROJECT_ROOT"
nohup ./石器时代服务器端最新完整源代码/gmsv/gmsv -f setup.cf > log/gmsv.log 2>&1 &
GMSV_PID=$!

# GMSV 시작 대기
sleep 3

if ps -p $GMSV_PID > /dev/null; then
    echo "${GREEN}✓ GMSV 시작 성공 (PID: $GMSV_PID)${NC}"

    # 포트 확인
    if netstat -tln | grep ":19065" > /dev/null 2>&1; then
        echo "${GREEN}✓ GMSV 포트 19065 리스닝 중${NC}"
    else
        echo "${RED}WARNING: GMSV 포트 19065가 리스닝 중이 아닙니다.${NC}"
    fi
else
    echo "${RED}ERROR: GMSV 시작 실패${NC}"
    echo "로그를 확인하세요: tail -f log/gmsv.log"
    exit 1
fi

echo
echo "========================================"
echo "${GREEN}✓ 프로덕션 서버 시작 완료!${NC}"
echo "========================================"
echo
echo "서버 정보:"
echo "  - SAAC PID: $SAAC_PID (포트 10001)"
echo "  - GMSV PID: $GMSV_PID (포트 19065)"
echo
echo "로그 확인:"
echo "  - SAAC: tail -f log/saac.log"
echo "  - GMSV: tail -f log/gmsv.log"
echo "  - GMSV 상세: tail -f 石器时代服务器端最新完整源代码/gmsv/log/proc.log"
echo
echo "서버 중지:"
echo "  ./scripts/stop-production-linux.sh"
echo
echo "⚠️  방화벽 설정:"
echo "  sudo ufw allow 10001/tcp"
echo "  sudo ufw allow 19065/tcp"
echo
