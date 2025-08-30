# ETH LOTTERY - Smart Contract Lottery System

A comprehensive smart contract lottery system built with Foundry and React, featuring multiple lottery types and referral systems.

## 🚀 Project Overview

This project consists of two main components:
- **Smart Contracts**: Solidity contracts for lottery management, treasury, and referral systems
- **Frontend**: React-based web application for lottery interaction

## 🏗️ Project Structure

```
Eth-Lottery/
├── contracts/          # Smart contract source code
├── script/            # Foundry deployment scripts
├── test/              # Smart contract tests
├── frontend/          # React web application
├── lib/               # Foundry dependencies
└── docs/              # Project documentation
```

## 🔄 **Complete System Flow Diagram**

```mermaid
graph TB
    subgraph "🌐 User Interface Layer"
        U[👤 User]
        M[Mobile App]
        W[Web App]
        U --> M
        U --> W
    end

    subgraph "🔐 Authentication & Wallet"
        WEPIN[WEPIN SDK]
        OAUTH[OAuth Providers]
        WALLET[Wallet Management]
        OAUTH --> WEPIN
        WEPIN --> WALLET
    end

    subgraph "🎮 Game Logic Layer"
        DL[Daily LUCKY]
        WJ[Weekly JACKPOT]
        AL[ADS LUCKY]
        TICKET[Ticket Purchase]
        REF[Referral System]
    end

    subgraph "💰 Token & Payment System"
        VERY[VERY Token]
        AD[AD Token]
        TREASURY[Treasury Manager]
        PAYMENT[Payment Processing]
    end

    subgraph "⛓️ Smart Contract Layer"
        subgraph "Core Contracts"
            C1D[Cryptolotto1Day]
            C7D[Cryptolotto7Days]
            CAD[CryptolottoAd]
            TM[TreasuryManager]
            CR[CryptolottoReferral]
        end
        
        subgraph "Support Contracts"
            AT[AdToken]
            TR[TokenRegistry]
            SA[StatsAggregator]
            FD[FundsDistributor]
            CR[ContractRegistry]
        end
    end

    subgraph "📊 Analytics & Monitoring"
        AE[Analytics Engine]
        MS[Monitoring System]
        STATS[Statistics]
        LOGS[Event Logs]
    end

    subgraph "🎯 Reward & Distribution"
        WIN[Winner Selection]
        REWARD[Reward Distribution]
        FEE[Fee Management]
        CLAIM[Claim Process]
    end

    subgraph "💾 Data Storage"
        BC[Blockchain Storage]
        LOCAL[Local Storage]
        SESSION[Session Storage]
    end

    %% User Flow
    U --> WEPIN
    WEPIN --> TICKET
    TICKET --> PAYMENT
    PAYMENT --> VERY
    PAYMENT --> AD
    
    %% Game Flow
    TICKET --> DL
    TICKET --> WJ
    TICKET --> AL
    
    %% Contract Interaction
    DL --> C1D
    WJ --> C7D
    AL --> CAD
    PAYMENT --> TM
    
    %% Referral Flow
    REF --> CR
    CR --> REWARD
    
    %% Analytics Flow
    C1D --> AE
    C7D --> AE
    CAD --> AE
    AE --> STATS
    AE --> LOGS
    
    %% Reward Flow
    WIN --> REWARD
    REWARD --> FEE
    REWARD --> CLAIM
    CLAIM --> VERY
    
    %% Data Flow
    AE --> BC
    WEPIN --> LOCAL
    TICKET --> SESSION
    
    %% Styling
    classDef userLayer fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef authLayer fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef gameLayer fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef tokenLayer fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef contractLayer fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef analyticsLayer fill:#e0f2f1,stroke:#004d40,stroke-width:2px
    classDef rewardLayer fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    classDef storageLayer fill:#fafafa,stroke:#424242,stroke-width:2px
    
    class U,M,W userLayer
    class WEPIN,OAUTH,WALLET authLayer
    class DL,WJ,AL,TICKET,REF gameLayer
    class VERY,AD,TREASURY,PAYMENT tokenLayer
    class C1D,C7D,CAD,TM,CR,AT,TR,SA,FD contractLayer
    class AE,MS,STATS,LOGS analyticsLayer
    class WIN,REWARD,FEE,CLAIM rewardLayer
    class BC,LOCAL,SESSION storageLayer
```

## 🔄 **Detailed User Journey Flow**

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant W as WEPIN SDK
    participant SC as Smart Contracts
    participant BC as Blockchain
    participant T as Treasury

    Note over U,T: 🚀 User Registration & Login
    U->>F: Access Application
    F->>W: Initialize WEPIN SDK
    W->>F: SDK Ready
    U->>F: Choose OAuth Provider
    F->>W: Login Request
    W->>F: Authentication Success
    F->>U: Show Game Dashboard

    Note over U,T: 🎮 Game Selection & Ticket Purchase
    U->>F: Select Game Type
    F->>SC: Fetch Game Contract
    SC->>F: Game Information
    U->>F: Purchase Ticket
    F->>W: Transaction Request
    W->>BC: Send Transaction
    BC->>SC: Execute Contract
    SC->>T: Transfer Funds
    SC->>F: Transaction Success
    F->>U: Ticket Confirmation

    Note over U,T: 🔗 Referral System
    U->>F: Share Referral Link
    F->>U: Generate Referral URL
    U->>F: New User with Referral
    F->>SC: Register Referral
    SC->>F: Referral Recorded

    Note over U,T: 🏆 Winner Selection & Rewards
    SC->>SC: Execute Lottery Logic
    SC->>F: Winner Announcement
    F->>U: Show Results
    U->>F: Claim Rewards
    F->>SC: Claim Request
    SC->>T: Process Payout
    T->>W: Transfer Rewards
    W->>U: Rewards Received

    Note over U,T: 📊 Analytics & Monitoring
    SC->>SC: Log Events
    SC->>F: Update Statistics
    F->>U: Show Dashboard
```

## 🏗️ **System Architecture Components**

### **Frontend Layer** (`frontend/`)
- **React + TypeScript**: Modern web application framework
- **Tailwind CSS**: Utility-first CSS framework
- **WEPIN SDK Integration**: Blockchain wallet functionality
- **Responsive Design**: Mobile-first approach

### **Smart Contract Layer** (`contracts/`)
- **47 Total Contracts**: Comprehensive blockchain infrastructure
- **Modular Architecture**: Organized by functionality
- **Security Features**: Access control, circuit breakers, rate limiting
- **Upgradeable Design**: UUPS proxy pattern support

### **Blockchain Integration**
- **VeryNetwork**: Chain ID 4613
- **Ethereum Compatibility**: Solidity smart contracts
- **Gas Optimization**: Efficient transaction processing
- **Event Logging**: Comprehensive audit trail

### **Authentication & Security**
- **Multi-Provider OAuth**: Google, Apple, Discord, Naver, Facebook, Line, Kakao
- **Wallet Management**: WEPIN SDK integration
- **Session Persistence**: Local storage management
- **Access Control**: Role-based permissions

### **Game Logic & Economics**
- **Multiple Lottery Types**: Daily, Weekly, Advertisement-based
- **Token System**: VERY and AD tokens
- **Referral Rewards**: Multi-level referral system
- **Fee Management**: 10% fee structure

### **Data & Analytics**
- **Real-time Statistics**: Live game data
- **Performance Monitoring**: Gas usage, transaction success rates
- **User Analytics**: Player behavior tracking
- **Event Logging**: Comprehensive audit trail

## 🔧 Smart Contracts

### Core Contracts
- **Cryptolotto1Day**: Daily lottery system
- **Cryptolotto7Days**: Weekly jackpot system  
- **CryptolottoAd**: Advertisement-based lottery
- **TreasuryManager**: Treasury management system
- **CryptolottoReferral**: Referral and reward system

### Features
- Multiple lottery types (Daily, Weekly, Ads)
- Referral system with rewards
- Treasury management
- Circuit breaker functionality
- Comprehensive testing suite

## 🎯 Frontend Application

### Features
- **WEPIN Wallet Integration**: Blockchain wallet functionality
- **VeryNetwork Support**: Chain ID 4613 blockchain interaction
- **Social Login**: Google, Apple, Discord, Naver, Facebook, Line, Kakao
- **VERY Token System**: Prize management and participant tracking
- **Multi-language Support**: Korean, English, Japanese
- **Responsive Design**: Mobile-optimized UI

### Technology Stack
- **Frontend**: React + TypeScript
- **Styling**: Tailwind CSS
- **Wallet**: WEPIN SDK
- **Blockchain**: VeryNetwork (Chain ID: 4613)
- **Build Tool**: Vite

## 📋 Installation & Setup

### Prerequisites
- Node.js 18.x or higher
- Foundry (for smart contract development)
- Git

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Eth-Lottery
```

### 2. Smart Contract Setup
```bash
# Install Foundry dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### 3. Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

### 4. Environment Variables
Create a `.env` file in the frontend directory:

```env
# WEPIN Configuration
VITE_WEPIN_APP_KEY=your-wepin-app-key

# Network Configuration
VITE_RPC_URL=https://rpc.verylabs.io
VITE_EXPLORER_URL=https://veryscan.io

# Contract Addresses (NEW WORKING CONTRACTS!)
VITE_CONTRACT_CRYPTOLOTTO_1DAY=your-cryptolotto-1day-contract-address
VITE_CONTRACT_CRYPTOLOTTO_7DAYS=your-cryptolotto-7days-contract-address
VITE_CONTRACT_CRYPTOLOTTO_AD=your-cryptolotto-ad-contract-address

# Core Contract Addresses (from previous deployment)
VITE_CONTRACT_TREASURY_MANAGER=your-treasury-manager-contract-address
VITE_CONTRACT_REGISTRY=your-registry-contract-address
VITE_CONTRACT_STATS_AGGREGATOR=your-stats-aggregator-contract-address
VITE_CONTRACT_FUNDS_DISTRIBUTOR=your-funds-distributor-contract-address
VITE_CONTRACT_CRYPTOLOTTO_REFERRAL=your-cryptolotto-referral-contract-address
VITE_CONTRACT_AD_TOKEN=your-ad-token-contract-address
VITE_CONTRACT_OWNABLE=your-ownable-contract-address

# Deployer Address
VITE_DEPLOYER_ADDRESS=your-deployer-address
```

## 🏃‍♂️ Running the Project

### Smart Contracts
```bash
# Run all tests
forge test

# Run specific test suites
forge test --match-contract Cryptolotto -vv
forge test --match-contract CryptolottoIntegration -vv
forge test --match-contract CryptolottoSecurity -vv

# Generate coverage report
forge coverage --report lcov

# Build contracts
forge build
```

### Frontend
```bash
cd frontend

# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🌐 VeryNetwork Configuration

- **Chain ID**: 4613
- **Network Name**: VeryNetwork
- **Provider ID**: `verynetwork`
- **RPC URL**: https://rpc.verylabs.io
- **Explorer**: https://veryscan.io

## 🧪 Testing

### Smart Contract Tests
```bash
# Run all tests
forge test

# Run with verbose output
forge test -vv

# Run specific test file
forge test --match-path test/Cryptolotto.t.sol

# Run fuzzing tests
forge test --match-contract CryptolottoFuzz -vv
```

### Frontend Tests
```bash
cd frontend
npm test
```

## 📚 Documentation

- **Smart Contracts**: See `contracts/` directory for detailed contract documentation
- **Deployment**: Check `script/` directory for deployment scripts
- **Testing**: Review `test/` directory for comprehensive test coverage
- **CI/CD**: GitHub Actions workflow for automated testing and building

## 🚀 Deployment

### Smart Contracts
```bash
# Deploy to Verychain
forge script script/Deploy.s.sol --rpc-url https://rpc.verylabs.io --broadcast
```

### Frontend
```bash
cd frontend
npm run build
# Deploy dist/ folder to your hosting service
```

## ⚠️ Important Notes

- Environment variables must be properly configured
- WEPIN Workspace app registration required
- Designed specifically for VeryNetwork
- Secure private key management for deployment
- Comprehensive testing recommended before production

## 🐛 Troubleshooting

### Smart Contract Issues
- Check Foundry installation: `foundryup`
- Verify dependencies: `forge install`
- Review test output for specific errors

### Frontend Issues
- Verify environment variables
- Check WEPIN app registration status
- Ensure VeryNetwork provider is available
- Review browser console for errors

### Build Issues
- Verify Node.js version (18.x+ recommended)
- Clear cache: `rm -rf node_modules && npm install`
- Check Foundry version: `forge --version`

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📞 Support

For issues and questions:
- Check existing documentation
- Review test files for examples
- Open an issue on GitHub
- Check CI/CD logs for build issues 