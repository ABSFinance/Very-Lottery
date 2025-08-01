#!/bin/bash

# 🧪 Cryptolotto Test Runner
echo "🚀 Starting Cryptolotto Test Suite..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 테스트 결과 카운터
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 함수: 테스트 실행
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -e "${BLUE}📋 Running $test_name...${NC}"
    
    if eval $test_command; then
        echo -e "${GREEN}✅ $test_name PASSED${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ $test_name FAILED${NC}"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    echo ""
}

# 메인 테스트 실행
echo -e "${YELLOW}🔧 Running Unit Tests...${NC}"
run_test "Unit Tests" "forge test --match-contract Cryptolotto -vv"

echo -e "${YELLOW}🔗 Running Integration Tests...${NC}"
run_test "Integration Tests" "forge test --match-contract CryptolottoIntegration -vv"

echo -e "${YELLOW}🎲 Running Fuzzing Tests...${NC}"
run_test "Fuzzing Tests" "forge test --match-contract CryptolottoFuzz -vv"

echo -e "${YELLOW}⚡ Running Performance Tests...${NC}"
run_test "Performance Tests" "forge test --match-contract CryptolottoPerformance -vv"

echo -e "${YELLOW}🔒 Running Security Tests...${NC}"
run_test "Security Tests" "forge test --match-contract CryptolottoSecurity -vv"

# 결과 출력
echo -e "${YELLOW}📊 Test Results Summary:${NC}"
echo -e "${GREEN}✅ Passed: $PASSED_TESTS${NC}"
echo -e "${RED}❌ Failed: $FAILED_TESTS${NC}"
echo -e "${BLUE}📈 Total: $TOTAL_TESTS${NC}"

# 가스 리포트 생성
echo -e "${YELLOW}⛽ Generating Gas Report...${NC}"
forge test --gas-report > gas_report.txt
echo -e "${GREEN}✅ Gas report saved to gas_report.txt${NC}"

# 성공/실패 판단
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}💥 Some tests failed!${NC}"
    exit 1
fi 