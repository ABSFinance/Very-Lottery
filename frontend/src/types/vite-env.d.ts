/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_WEPIN_APP_ID: string
  readonly VITE_WEPIN_APP_KEY: string
  readonly VITE_CHAIN_ID: string
  readonly VITE_NETWORK_NAME: string
  readonly VITE_RPC_URL: string
  readonly VITE_EXPLORER_URL: string
  readonly VITE_CONTRACT_CRYPTOLOTTO_1DAY: string
  readonly VITE_CONTRACT_CRYPTOLOTTO_7DAYS: string
  readonly VITE_CONTRACT_CRYPTOLOTTO_AD: string
  readonly VITE_CONTRACT_TREASURY_MANAGER: string
  readonly VITE_CONTRACT_REGISTRY: string
  readonly VITE_CONTRACT_STATS_AGGREGATOR: string
  readonly VITE_CONTRACT_FUNDS_DISTRIBUTOR: string
  readonly VITE_CONTRACT_CRYPTOLOTTO_REFERRAL: string
  readonly VITE_CONTRACT_AD_TOKEN: string
  readonly VITE_CONTRACT_OWNABLE: string
  readonly VITE_DEPLOYER_ADDRESS: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
} 