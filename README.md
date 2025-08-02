# 🎰 Cryptolotto - Decentralized Lottery Platform

## 📋 **프로젝트 개요**

Cryptolotto는 Verychain 블록체인 기반의 탈중앙화 복권 플랫폼입니다. 1일, 7일, Ad Lottery 게임을 지원하며, 안전하고 투명한 복권 시스템을 제공합니다.

## 🏗️ **아키텍처**

```
┌─────────────────────────────────────────────────────────────┐
│                    Cryptolotto Platform                    │
├─────────────────────────────────────────────────────────────┤
│  Lottery Games    │  Treasury System   │  Analytics      │
│  ├─ 1Day Game    │  ├─ Treasury Mgr   │  ├─ Stats Agg   │
│  ├─ 7Days Game   │  ├─ Funds Dist     │  ├─ Analytics   │
│  └─ Ad Lottery   │  └─ Referral Sys   │  └─ Monitoring  │
├─────────────────────────────────────────────────────────────┤
│  Security & Utils │  Storage System    │  Access Control │
│  ├─ Circuit Brkr  │  ├─ Storage Layout │  ├─ Ownable     │
│  ├─ Gas Optimizer │  ├─ Storage Access │  └─ Registry    │
│  └─ Security Utils│  └─ Storage Opt    │                 │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **CI/CD 파이프라인**

### **자동화된 워크플로우**

1. **테스트 자동화** ✅
   - 모든 테스트 자동 실행
   - 단위 테스트, 통합 테스트, Fuzzing 테스트
   - 성능 테스트 및 보안 테스트

2. **빌드 자동화** ✅
   - 컨트랙트 컴파일 및 검증
   - 아티팩트 자동 업로드

3. **배포 자동화** ✅
   - Verychain 자동 배포
   - Veryscan에서 무료 검증
   - 릴리즈 자동 생성

### **워크플로우 파일**

- `.github/workflows/ci.yml` - 메인 CI/CD 파이프라인
- `.github/workflows/deploy.yml` - 배포 전용 워크플로우

### **실행 방법**

```bash
# 로컬에서 테스트 실행
./test/run_tests.sh

# GitHub Actions에서 자동 실행
git push origin master
```

## 🧪 **테스트 스위트**

### **테스트 커버리지**
- **단위 테스트**: 42개 ✅
- **통합 테스트**: 17개 ✅
- **Fuzzing 테스트**: 8개 ✅
- **성능 테스트**: 5개 ✅
- **보안 테스트**: 5개 ✅

### **테스트 실행**

```bash
# 모든 테스트 실행
forge test

# 특정 테스트 실행
forge test --match-contract CryptolottoIntegration

# 가스 리포트 생성
forge test --gas-report

# 커버리지 리포트
forge coverage --report lcov
```

## 📦 **설치 및 실행**

### **필수 요구사항**
- Foundry
- Node.js 18+
- Git

### **설치**

```bash
# 저장소 클론
git clone https://github.com/your-username/cryptolotto.git
cd cryptolotto

# Foundry 설치 (이미 설치된 경우 생략)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 의존성 설치
forge install

# 환경 변수 설정
cp env.example .env
# .env 파일을 편집하여 필요한 값들을 설정
```

### **개발**

```bash
# 컨트랙트 빌드
forge build

# 테스트 실행
forge test

# Verychain 배포
forge script script/Deploy.s.sol --rpc-url https://rpc.verylabs.io --broadcast
```

## 🔧 **환경 변수**

`.env` 파일에 다음 변수들을 설정하세요:

```bash
# 공개 설정 (Public)
RPC_URL=https://rpc.verylabs.io
VERYCHAIN_CHAIN_ID=4613

# 비밀 설정 (Private) - GitHub Secrets에만 저장
PRIVATE_KEY=your_private_key_here
DEPLOYER_ADDRESS=your_deployer_address_here
```

### **GitHub Secrets 설정**
GitHub 저장소의 Settings > Secrets and variables > Actions에서 다음 secret만 설정하세요:

```
PRIVATE_KEY=your_private_key_here
```

**참고**: RPC URL은 공개되어도 안전하므로 GitHub Secrets에 저장할 필요가 없습니다.

## 📊 **주요 기능**

### **복권 게임**
- **1일 복권**: 매일 새로운 게임
- **7일 복권**: 주간 복권 게임
- **Ad Lottery**: AdToken을 사용한 광고 복권

### **수수료 구조**
- **총 수수료**: 10%
- **리퍼럴 수수료**: 2%
- **Ad Lottery 수수료**: 3%
- **개발자 수수료**: 5%

### **보안 기능**
- 재진입 공격 방지
- 오버플로우/언더플로우 방지
- 권한 검증 시스템
- 긴급 정지 기능

## 🌐 **Verychain 특별 기능**

### **네트워크 정보**
- **Network Name**: Verychain
- **Chain ID**: 4613
- **Mainnet RPC**: https://rpc.verylabs.io
- **Mainnet Explorer**: https://veryscan.io

### **Veryscan 사용**
- **API 키 불필요**: 무료로 사용 가능
- **자동 검증**: 배포 후 자동으로 블록 익스플로러에서 확인
- **무료 서비스**: 모든 기능을 무료로 제공

### **배포 명령어**
```bash
# Verychain 메인넷 배포
forge script script/Deploy.s.sol --rpc-url https://rpc.verylabs.io --broadcast
```

## 🤝 **기여하기**

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 **라이선스**

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 **연락처**

- 프로젝트 링크: [https://github.com/your-username/cryptolotto](https://github.com/your-username/cryptolotto)
- 이슈 리포트: [https://github.com/your-username/cryptolotto/issues](https://github.com/your-username/cryptolotto/issues)
- Verychain Explorer: [https://veryscan.io](https://veryscan.io)

---

**⭐ 이 프로젝트가 도움이 되었다면 스타를 눌러주세요!** 