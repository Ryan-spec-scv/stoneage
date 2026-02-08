#!/bin/bash
# Stone Age 8.5 - Linux 프로덕션 서버 중지 스크립트

echo "========================================"
echo "Stone Age 8.5 - 프로덕션 서버 중지"
echo "========================================"
echo

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# SAAC 프로세스 확인 및 종료
if pgrep -x "saac" > /dev/null; then
    echo "${YELLOW}SAAC 프로세스를 종료합니다...${NC}"
    pkill -x saac
    sleep 2

    if pgrep -x "saac" > /dev/null; then
        echo "${RED}SAAC 강제 종료 중...${NC}"
        pkill -9 -x saac
    fi
    echo "${GREEN}✓ SAAC 종료 완료${NC}"
else
    echo "${YELLOW}SAAC 프로세스가 실행 중이 아닙니다.${NC}"
fi

echo

# GMSV 프로세스 확인 및 종료
if pgrep -x "gmsv" > /dev/null; then
    echo "${YELLOW}GMSV 프로세스를 종료합니다...${NC}"
    pkill -x gmsv
    sleep 2

    if pgrep -x "gmsv" > /dev/null; then
        echo "${RED}GMSV 강제 종료 중...${NC}"
        pkill -9 -x gmsv
    fi
    echo "${GREEN}✓ GMSV 종료 완료${NC}"
else
    echo "${YELLOW}GMSV 프로세스가 실행 중이 아닙니다.${NC}"
fi

echo
echo "========================================"
echo "${GREEN}✓ 모든 서버 종료 완료!${NC}"
echo "========================================"
echo
