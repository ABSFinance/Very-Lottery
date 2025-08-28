# VERY BOLT - WEPIN 로그인 통합 앱

VERY 토큰을 받을 수 있는 모바일 스타일 웹 애플리케이션입니다. WEPIN 지갑과 VeryNetwork(Chain ID: 4613) 블록체인 상호작용을 지원합니다.

## 🚀 주요 기능

- **WEPIN 지갑 연동**: 블록체인 지갑 기능
- **VeryNetwork 지원**: Chain ID 4613 전용 블록체인 상호작용
- **소셜 로그인**: Google, Apple, Discord, Naver, Facebook, Line, Kakao 등
- **VERY 토큰 시스템**: 당첨금, 참여자 관리
- **다국어 지원**: 한국어, 영어, 일본어
- **반응형 디자인**: 모바일 최적화 UI

## 📋 설치 및 설정

### 1. 의존성 설치

```bash
npm install
```

### 2. 환경 변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
# WEPIN 설정 (WEPIN Workspace에서 발급)
REACT_APP_WEPIN_APP_ID=your-wepin-app-id
REACT_APP_WEPIN_APP_KEY=your-wepin-app-key

# 환경 설정
REACT_APP_ENV=development
```

### 3. WEPIN 설정

1. [WEPIN Workspace](https://workspace.wepin.io/)에서 앱 등록
2. App ID와 App Key 발급
3. 환경 변수에 설정

## 🏃‍♂️ 실행

### 개발 서버 실행

```bash
npm run dev
```

브라우저에서 `http://localhost:5173`으로 접속

### 빌드

```bash
npm run build
```

## 🔧 기술 스택

- **Frontend**: React + TypeScript
- **Styling**: Tailwind CSS
- **Wallet**: WEPIN SDK (동적 import)
- **Blockchain**: VeryNetwork (Chain ID: 4613)
- **Authentication**: WEPIN OAuth
- **Build Tool**: Vite

## 📱 사용법

1. **로그인**: "WEPIN 로그인" 버튼 클릭
2. **소셜 계정 선택**: 지원되는 소셜 계정으로 로그인
3. **VERY 토큰 받기**: 로그인 후 토큰 수령 가능
4. **VeryNetwork Provider**: "Provider 가져오기" 버튼으로 블록체인 연결
5. **언어 변경**: 하단 언어 버튼으로 전환

## 🌐 VeryNetwork 정보

- **Chain ID**: 4613
- **Network Name**: VeryNetwork
- **Provider ID**: `verynetwork`
- **지원 기능**: EIP-1193 표준 Ethereum Provider

## ⚠️ 주의사항

- 환경 변수는 반드시 `.env` 파일에 설정
- WEPIN Workspace에서 앱 등록 필요
- VeryNetwork 전용으로 설계됨
- 프로덕션 환경에서는 보안 설정 강화

## 🐛 문제 해결

### 로그인 실패 시

- 환경 변수 설정 확인
- WEPIN 앱 등록 상태 확인

### VeryNetwork Provider 연결 실패 시

- WEPIN Provider 초기화 상태 확인
- 네트워크 연결 상태 확인

### 빌드 오류 시

- Node.js 버전 확인 (18.x 이상 권장)
- 의존성 재설치: `rm -rf node_modules && npm install`

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
