# 🎮 Lottery Modules

## 📁 **디렉토리 구조**

```
lottery/
├── BaseGame.sol ─ 기본 게임 클래스
├── Cryptolotto1Day.sol ─ 1일 로또 게임
├── Cryptolotto7Days.sol ─ 7일 로또 게임
├── CryptolottoAd.sol ─ Ad Lottery 게임
├── AdToken.sol ─ Ad Lottery용 유틸리티 토큰
└── SimpleOwnable.sol ─ 간단한 소유권 관리
```

## 🎯 **주요 컨트랙트**

### **1. BaseGame.sol**
- 모든 게임의 기본 클래스
- 중앙화된 스토리지 아키텍처 사용
- 공통 게임 로직 구현
- 업그레이드 가능한 구조

### **2. Cryptolotto1Day.sol**
- 1일 로또 게임 구현
- BaseGame 상속
- 1일 주기로 게임 진행

### **3. Cryptolotto7Days.sol**
- 7일 로또 게임 구현
- BaseGame 상속
- 7일 주기로 게임 진행

### **4. CryptolottoAd.sol**
- Ad Lottery 게임 구현
- AdToken을 사용한 티켓 구매
- 1Day/7Days 게임의 수수료로 상금 지급

### **5. AdToken.sol**
- Ad Lottery 전용 유틸리티 토큰
- ERC20Burnable 구현
- 티켓 구매 시 소각됨

### **6. SimpleOwnable.sol**
- 간단한 소유권 관리
- 접근 제어 기능 