# ETH-Lottery Project Complete System Diagram

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
            CR2[ContractRegistry]
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

## 🏗️ **System Architecture Overview**

```mermaid
graph LR
    subgraph "Frontend Layer"
        REACT[React + TypeScript]
        TAILWIND[Tailwind CSS]
        WEPIN_INT[WEPIN SDK Integration]
        RESPONSIVE[Responsive Design]
    end

    subgraph "Smart Contract Layer"
        LOTTERY[Lottery Contracts]
        TREASURY[Treasury System]
        REFERRAL[Referral System]
        ANALYTICS[Analytics Engine]
    end

    subgraph "Blockchain Layer"
        VERYNETWORK[VeryNetwork Chain ID: 4613]
        SOLIDITY[Solidity Contracts]
        GAS_OPT[Gas Optimization]
    end

    subgraph "Data Layer"
        BLOCKCHAIN[Blockchain Storage]
        LOCAL_STORAGE[Local Storage]
        SESSION[Session Storage]
    end

    REACT --> LOTTERY
    WEPIN_INT --> TREASURY
    LOTTERY --> VERYNETWORK
    TREASURY --> BLOCKCHAIN
    ANALYTICS --> LOCAL_STORAGE
```

## 🎯 **Core Components Breakdown**

```mermaid
graph TD
    subgraph "🎮 Game Types"
        DL[Daily LUCKY<br/>1 Day Cycle]
        WJ[Weekly JACKPOT<br/>7 Day Cycle]
        AL[ADS LUCKY<br/>Ad-based Tokens]
    end

    subgraph "💰 Token System"
        VERY[VERY Token<br/>Main Currency]
        AD[AD Token<br/>Ad Rewards]
    end

    subgraph "🔗 Referral System"
        REF_LINK[Referral Links]
        REF_REWARDS[Referral Rewards]
        REF_STATS[Referral Statistics]
    end

    subgraph "🏆 Reward System"
        WINNER[Winner Selection]
        DISTRIBUTION[Reward Distribution]
        FEES[10% Fee Structure]
    end

    subgraph "🔐 Authentication"
        OAUTH_PROVIDERS[OAuth Providers]
        WEPIN_SDK[WEPIN SDK]
        WALLET_MGMT[Wallet Management]
    end

    DL --> VERY
    WJ --> VERY
    AL --> AD
    REF_LINK --> REF_REWARDS
    WINNER --> DISTRIBUTION
    DISTRIBUTION --> FEES
    OAUTH_PROVIDERS --> WEPIN_SDK
    WEPIN_SDK --> WALLET_MGMT
```

## 📊 **Data Flow Architecture**

```mermaid
flowchart TD
    USER[👤 User Input] --> FRONTEND[🌐 Frontend App]
    FRONTEND --> AUTH[🔐 Authentication]
    AUTH --> WEPIN[💼 WEPIN Wallet]
    WEPIN --> CONTRACTS[⛓️ Smart Contracts]
    CONTRACTS --> BLOCKCHAIN[🔗 VeryNetwork]
    
    BLOCKCHAIN --> EVENTS[📝 Event Logs]
    EVENTS --> ANALYTICS[📊 Analytics Engine]
    ANALYTICS --> STATS[📈 Statistics]
    STATS --> DASHBOARD[🎯 User Dashboard]
    
    CONTRACTS --> TREASURY[💰 Treasury Manager]
    TREASURY --> REWARDS[🏆 Reward Distribution]
    REWARDS --> USER
    
    CONTRACTS --> REFERRAL[🔗 Referral System]
    REFERRAL --> REF_STATS[📊 Referral Stats]
    REF_STATS --> DASHBOARD
    
    style USER fill:#e1f5fe
    style FRONTEND fill:#f3e5f5
    style CONTRACTS fill:#fce4ec
    style BLOCKCHAIN fill:#e0f2f1
    style ANALYTICS fill:#fff3e0
    style DASHBOARD fill:#f1f8e9
```

## 🚀 **Deployment & Infrastructure**

```mermaid
graph TB
    subgraph "Development Environment"
        LOCAL[Local Development]
        TEST[Testing Suite]
        BUILD[Build Process]
    end

    subgraph "Deployment Pipeline"
        GITHUB[GitHub Repository]
        ACTIONS[GitHub Actions]
        DEPLOY[Deploy Scripts]
    end

    subgraph "Production Environment"
        VERYCHAIN[VeryNetwork Blockchain]
        FRONTEND_HOST[Frontend Hosting]
        MONITORING[System Monitoring]
    end

    LOCAL --> TEST
    TEST --> BUILD
    BUILD --> GITHUB
    GITHUB --> ACTIONS
    ACTIONS --> DEPLOY
    DEPLOY --> VERYCHAIN
    DEPLOY --> FRONTEND_HOST
    VERYCHAIN --> MONITORING
    FRONTEND_HOST --> MONITORING
```

---

**💡 To convert these diagrams to images:**
1. Copy the mermaid code blocks
2. Use online Mermaid editors like:
   - [Mermaid Live Editor](https://mermaid.live/)
   - [Mermaid Chart](https://www.mermaidchart.com/)
3. Export as PNG, SVG, or PDF
4. Or use GitHub's built-in Mermaid rendering in markdown files
