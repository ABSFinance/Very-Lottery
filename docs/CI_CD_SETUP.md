# 🚀 CI/CD 파이프라인 설정 가이드

## 📋 **개요**

이 문서는 Cryptolotto 프로젝트의 CI/CD 파이프라인을 Verychain과 Veryscan에 맞게 설정하는 방법을 설명합니다.

## 🔧 **GitHub Secrets 설정**

### **필수 Secrets**

GitHub 저장소의 Settings > Secrets and variables > Actions에서 다음 secrets를 설정하세요:

#### **개인 키 (Private)**
```
PRIVATE_KEY=your_private_key_here
```

#### **공개 설정 (Public)**
```
RPC_URL=https://rpc.verylabs.io
VERYCHAIN_CHAIN_ID=4613
```

### **Veryscan 설정**
- **API 키 불필요**: Veryscan은 무료로 사용 가능
- **검증**: 자동으로 블록 익스플로러에서 확인 가능

### **Secrets 설정 방법**

1. GitHub 저장소로 이동
2. Settings 탭 클릭
3. Secrets and variables > Actions 클릭
4. "New repository secret" 클릭
5. `PRIVATE_KEY`만 추가 (RPC URL은 공개)

## 🔄 **워크플로우 설명**

### **ci.yml (메인 CI/CD 파이프라인)**

#### **트리거 조건**
- `main` 또는 `develop` 브랜치에 push
- `main` 브랜치로의 Pull Request

#### **실행 단계**
1. **테스트 (test)**
   - Foundry 설정
   - 의존성 설치
   - 모든 테스트 실행
   - 커버리지 리포트 생성

2. **빌드 (build)**
   - 컨트랙트 컴파일
   - 아티팩트 업로드

3. **보안 (security)**
   - 보안 테스트 실행
   - Fuzzing 테스트 실행

4. **성능 (performance)**
   - 성능 테스트 실행
   - 가스 리포트 생성

5. **린트 (lint)**
   - Solhint 실행
   - 코드 포맷팅 검사

6. **배포 (deploy)** - main 브랜치에서만 실행
   - Verychain 배포
   - 릴리즈 생성

### **deploy.yml (수동 배포)**

#### **트리거 조건**
- GitHub Actions에서 수동 실행
- 네트워크 선택 가능 (verychain)

#### **실행 단계**
1. 코드 체크아웃
2. Foundry 설정
3. 의존성 설치
4. 테스트 실행
5. 선택된 네트워크에 배포
6. 배포 요약 생성

## 🧪 **테스트 자동화**

### **실행되는 테스트**
- **단위 테스트**: 42개
- **통합 테스트**: 17개
- **Fuzzing 테스트**: 8개
- **성능 테스트**: 5개
- **보안 테스트**: 5개

### **테스트 명령어**
```bash
# 모든 테스트
forge test

# 특정 테스트
forge test --match-contract CryptolottoIntegration

# 가스 리포트
forge test --gas-report

# 커버리지
forge coverage --report lcov
```

## 📊 **모니터링 및 알림**

### **성공 시**
- ✅ 모든 테스트 통과
- ✅ 빌드 성공
- ✅ Verychain 배포 완료
- ✅ 릴리즈 생성

### **실패 시**
- ❌ 테스트 실패 시 배포 중단
- ❌ 빌드 실패 시 배포 중단
- ❌ 보안 테스트 실패 시 배포 중단

## 🔐 **보안 고려사항**

### **Secrets 보안**
- **PRIVATE_KEY만 비밀**: Private key는 반드시 안전하게 보관
- **RPC URL 공개**: RPC URL은 공개되어도 안전
- **정기적 로테이션**: Private key 정기적으로 교체

### **배포 보안**
- main 브랜치에서만 자동 배포
- 테스트 통과 후에만 배포
- 배포 전 보안 검사 필수

## 🛠️ **문제 해결**

### **일반적인 문제**

#### **1. Foundry 설치 실패**
```bash
# Foundry 재설치
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

#### **2. 의존성 설치 실패**
```bash
# 캐시 클리어
forge build --force
forge install --force
```

#### **3. 테스트 실패**
```bash
# 상세 로그 확인
forge test -vvv

# 특정 테스트만 실행
forge test --match-test testName
```

#### **4. Verychain 배포 실패**
```bash
# 네트워크 연결 확인
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://rpc.verylabs.io
```

## 📈 **성능 최적화**

### **CI/CD 최적화**
- 병렬 테스트 실행
- 캐시 활용
- 불필요한 단계 제거

### **가스 최적화**
- 정기적인 가스 리포트 생성
- 가스 사용량 모니터링
- 최적화 기회 식별

## 🌐 **Verychain 특별 설정**

### **네트워크 정보**
- **Network Name**: Verychain
- **Chain ID**: 4613
- **Mainnet RPC**: https://rpc.verylabs.io
- **Mainnet Explorer**: https://veryscan.io

### **Veryscan 사용**
- API 키 불필요
- 무료 사용
- 자동 컨트랙트 검증

### **배포 명령어**
```bash
# Verychain 메인넷 배포
forge script script/Deploy.s.sol --rpc-url https://rpc.verylabs.io --broadcast
```

## 📞 **지원**

문제가 발생하면 다음을 확인하세요:

1. **GitHub Issues**: [프로젝트 이슈 페이지](https://github.com/your-username/cryptolotto/issues)
2. **문서**: [프로젝트 README](../README.md)
3. **테스트**: 로컬에서 테스트 실행
4. **Verychain Explorer**: [https://veryscan.io](https://veryscan.io)

---

**🚀 Verychain CI/CD 파이프라인이 성공적으로 설정되었습니다!** 