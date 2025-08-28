# Contract ABIs for very-bolt-1

This directory contains the contract ABIs copied from the `lotteryapp` project. These ABIs are used to interact with the deployed smart contracts.

## Environment Variables

The project uses environment variables for configuration. Create a `.env` file in the root directory with the following variables:

```env
# Wepin Configuration
VITE_WEPIN_APP_ID=your_wepin_app_id_here
VITE_WEPIN_APP_KEY=your_wepin_app_key_here

# Verychain Network Configuration
VITE_CHAIN_ID=4613
VITE_NETWORK_NAME=Verychain
VITE_RPC_URL=https://rpc.verylabs.io
VITE_EXPLORER_URL=https://veryscan.io

# Contract Addresses
VITE_CONTRACT_CRYPTOLOTTO_1DAY=0x3428C1cf278700a8C1c74a18AA17F4AFB0fc05aa
VITE_CONTRACT_CRYPTOLOTTO_7DAYS=0xFC27CA8a59b4273e8a90202F8F4bB2155f7BcA2B
VITE_CONTRACT_CRYPTOLOTTO_AD=0x637C4061A04762632874E5194CA0E2F73F0e2E3d
VITE_CONTRACT_TREASURY_MANAGER=0x72385DaFD88e6Aaa1119ebEAef55F021fFD771d4
VITE_CONTRACT_REGISTRY=0x2DE8b38AC32Df8bC7BB0b5419ED8B0FaF0F84C5A
VITE_CONTRACT_STATS_AGGREGATOR=0x8b5f18a38cc923Db86c2481e948D6543dc0d22e1
VITE_CONTRACT_FUNDS_DISTRIBUTOR=0x7742c6200196560Ae97C7E3840dbADAce8F70506
VITE_CONTRACT_CRYPTOLOTTO_REFERRAL=0xc562E45DDf33bC61020776c6947Fa99704e3B296
VITE_CONTRACT_AD_TOKEN=0x4D845A313c4C8d1b16585694C80508dE13F8a190
VITE_CONTRACT_OWNABLE=0x0BeEf6fB26E0C0831729Cca46Ff78dA2B0cf5Fa1

# Deployer Address
VITE_DEPLOYER_ADDRESS=0x01EE2C5d56b6aC505dcc9C1702C49304A0b82066
```

## Contract Files

- `Cryptolotto1Day.json` - ABI for the 1-day lottery contract
- `Cryptolotto7Days.json` - ABI for the 7-day lottery contract
- `CryptolottoReferral.json` - ABI for the referral system contract
- `FundsDistributor.json` - ABI for the funds distributor contract

## Usage

### 1. Using Contract Utilities (`src/utils/contracts.ts`)

```typescript
import {
  getGameContractInfo,
  getGameABI,
  getGameContractAddress,
  NETWORK_CONFIG,
  WEPIN_CONFIG,
} from "../utils/contracts";

// Get contract info for a game type
const contractInfo = getGameContractInfo("daily-lucky");
console.log(contractInfo.abi); // Contract ABI
console.log(contractInfo.address); // Contract address from environment

// Get network configuration
console.log(NETWORK_CONFIG.chainId); // '4613'
console.log(NETWORK_CONFIG.networkName); // 'Verychain'

// Get Wepin configuration
console.log(WEPIN_CONFIG.appId); // From environment variable
```

### 2. Using Contract Service (`src/utils/contractService.ts`)

```typescript
import { contractService } from "../utils/contractService";
import { ethers } from "ethers";

// Set up provider
const provider = new ethers.BrowserProvider(window.ethereum);
contractService.setProvider(provider);

// Get contract instance
const contract = contractService.getGameContract("daily-lucky");

// Call contract functions
const jackpot = await contractService.getCurrentGameJackpot("daily-lucky");
const ticketPrice = await contractService.getTicketPrice("daily-lucky");
const isActive = await contractService.isGameActive("daily-lucky");
```

### 3. Direct Contract Usage

```typescript
import { ethers } from "ethers";
import { getGameContractInfo } from "../utils/contracts";

const contractInfo = getGameContractInfo("daily-lucky");
const contract = new ethers.Contract(
  contractInfo.address, // Uses environment variable
  contractInfo.abi,
  provider
);

// Call contract functions
const jackpot = await contract.getPlayedGameJackpot();
const ticketPrice = await contract.ticketPrice();
```

### 4. Using Wepin with Environment Variables

```typescript
import { initWepin } from "../utils/wepin";

// Initialize Wepin with environment variables (no need to pass appId/appKey)
const wepinInstances = await initWepin();

// Or override with custom values
const wepinInstances = await initWepin("custom_app_id", "custom_app_key");
```

## Game Type Mapping

- `daily-lucky` → `Cryptolotto1Day` contract
- `weekly-jackpot` → `Cryptolotto7Days` contract
- `ads-lucky` → `Cryptolotto1Day` contract (can be updated later)

## Environment Variables Reference

### Contract Addresses

- `VITE_CONTRACT_CRYPTOLOTTO_1DAY` - 1-day lottery contract address
- `VITE_CONTRACT_CRYPTOLOTTO_7DAYS` - 7-day lottery contract address
- `VITE_CONTRACT_CRYPTOLOTTO_REFERRAL` - Referral system contract address
- `VITE_CONTRACT_FUNDS_DISTRIBUTOR` - Funds distributor contract address
- `VITE_CONTRACT_TREASURY_MANAGER` - Treasury manager contract address
- `VITE_CONTRACT_REGISTRY` - Contract registry address
- `VITE_CONTRACT_STATS_AGGREGATOR` - Stats aggregator contract address
- `VITE_CONTRACT_AD_TOKEN` - Ad token contract address
- `VITE_CONTRACT_OWNABLE` - Ownable contract address

### Network Configuration

- `VITE_CHAIN_ID` - Blockchain chain ID (4613 for Verychain)
- `VITE_NETWORK_NAME` - Network name (Verychain)
- `VITE_RPC_URL` - RPC endpoint URL
- `VITE_EXPLORER_URL` - Blockchain explorer URL

### Wepin Configuration

- `VITE_WEPIN_APP_ID` - Wepin application ID
- `VITE_WEPIN_APP_KEY` - Wepin application key

## Key Contract Functions

### Cryptolotto1Day/Cryptolotto7Days

- `buyTicket(address partner)` - Buy a ticket (payable)
- `getPlayedGameJackpot()` - Get current game jackpot
- `getPlayedGamePlayers()` - Get current game players count
- `ticketPrice()` - Get ticket price
- `isActive()` - Check if game is active

### CryptolottoReferral

- `getPartnerByReferral(address player)` - Get partner by referral
- `getPartnerPercent(address partner)` - Get partner percentage
- `addReferral(address partner, address referral)` - Add new referral

### FundsDistributor

- `getBalance()` - Get contract balance
- `withdrawFunds()` - Withdraw funds to owner
- `withdrawAmount(uint256 amount)` - Withdraw specific amount

## Integration with Wepin

The contract ABIs are integrated with the Wepin wallet system. See `src/screens/Games/VeryLucky.tsx` for an example of how to use the ABIs with Wepin's send method.

## Updating ABIs

When the contracts are updated, you can replace the JSON files in this directory with the new ABIs from the `lotteryapp` project.

## TypeScript Support

The project includes TypeScript declarations for environment variables in `src/types/vite-env.d.ts`. This provides full type safety when accessing environment variables.
