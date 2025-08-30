import { WepinSDK } from "@wepin/sdk-js";
import { ethers } from "ethers";
import type { Eip1193Provider } from "ethers";

export interface WepinUserInfo {
  email?: string;
  provider?: string;
  [key: string]: unknown;
}

export interface GetAccountsOptions {
  networks?: string[];
  withEoa?: boolean;
}

export interface AccountInfo {
  address: string;
  network: string;
  contract?: string;
  isAA?: boolean;
}

export interface WepinSDKLike {
  init(): Promise<void>;
  getAccounts(options?: GetAccountsOptions): Promise<AccountInfo[]>;
  getStatus(): Promise<string>; // WepinSDK lifecycle status
  register(): Promise<IWepinUser>; // Register user to Wepin
  send(params: {
    account: {
      address: string;
      network: string;
    };
    txData: {
      to: string;
      amount: string;
      data?: string;
      value?: string;
    };
  }): Promise<{ txId: string }>;
}

export interface WepinLoginLike {
  init(language: string): Promise<void>;
  loginWithOauthProvider(args: {
    provider: OauthProvider;
    withLogout?: boolean;
  }): Promise<unknown>;
  loginWepin(args: {
    provider: OauthProvider;
    token: OAuthToken;
  }): Promise<{ status: "success" | "error"; userInfo?: WepinUserInfo } | unknown>;
  logout(): Promise<boolean | { status: "success" | "error" }>;
}

export interface WepinProviderLike {
  init(options: { defaultLanguage?: string; defaultCurrency?: string }): Promise<void>;
  getProvider(network: string): Promise<Eip1193Provider>;
}

export interface WepinInstances {
  sdk: WepinSDKLike;
  login: WepinLoginLike;
  provider: WepinProviderLike;
}

let lastInstances: WepinInstances | null = null;
export const getLastWepinInstances = (): WepinInstances | null => lastInstances;

// Update the last instances (called when Wepin is initialized)
export const updateLastWepinInstances = (instances: WepinInstances) => {
  lastInstances = instances;
  console.log("Updated last Wepin instances:", instances);
};

// Get Wepin instances from current component state if available
export const getCurrentWepinInstances = (): WepinInstances | null => {
  // First try to get from last instances
  if (lastInstances) {
    console.log("Using last Wepin instances");
    return lastInstances;
  }
  
  // If no last instances, try to get from global state or return null
  console.log("No last Wepin instances available");
  return null;
};

// Check if we can restore Wepin instances from stored state
export const canRestoreWepinInstances = (): boolean => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      return !!(parsed.isLoggedIn && parsed.userInfo);
    }
  } catch (error) {
    console.warn('Failed to check stored Wepin state:', error);
  }
  return false;
};

// Global login state management with localStorage persistence
const STORAGE_KEY = 'wepin_login_state';

interface GlobalLoginState {
  isLoggedIn: boolean;
  userInfo: WepinUserInfo | null;
  walletAddress: string | null;
  lastChecked: number;
}

// Get initial state from localStorage or default
const getInitialState = (): GlobalLoginState => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      return {
        isLoggedIn: parsed.isLoggedIn || false,
        userInfo: parsed.userInfo || null,
        walletAddress: parsed.walletAddress || null,
        lastChecked: parsed.lastChecked || 0,
      };
    }
  } catch (error) {
    console.warn('Failed to parse stored login state:', error);
  }
  
  return {
    isLoggedIn: false,
    userInfo: null,
    walletAddress: null,
    lastChecked: 0,
  };
};

let globalLoginState: GlobalLoginState = getInitialState();

// Update global login state
export const updateGlobalLoginState = (state: Partial<GlobalLoginState>) => {
  globalLoginState = { ...globalLoginState, ...state, lastChecked: Date.now() };
  
  // Persist to localStorage
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(globalLoginState));
  } catch (error) {
    console.warn('Failed to save login state to localStorage:', error);
  }
};

// Get global login state
export const getGlobalLoginState = (): GlobalLoginState => globalLoginState;

// Clear global login state (for logout)
export const clearGlobalLoginState = () => {
  globalLoginState = {
    isLoggedIn: false,
    userInfo: null,
    walletAddress: null,
    lastChecked: Date.now(),
  };
  
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch (error) {
    console.warn('Failed to clear login state from localStorage:', error);
  }
};

// Check and update global login state
export const checkAndUpdateGlobalLoginState = async (sdk: WepinSDKLike): Promise<boolean> => {
  try {
    const accounts = await sdk.getAccounts({ withEoa: true });
    const isLoggedIn = accounts && accounts.length > 0;
    
    if (isLoggedIn) {
      const preferred = accounts.find((a) => 
        (a.network || "").toLowerCase().includes("evmvery")
      ) || accounts[0];
      
      updateGlobalLoginState({
        isLoggedIn: true,
        walletAddress: preferred?.address || null,
      });
    } else {
      updateGlobalLoginState({
        isLoggedIn: false,
        userInfo: null,
        walletAddress: null,
      });
    }
    
    return isLoggedIn;
  } catch (error) {
    updateGlobalLoginState({
      isLoggedIn: false,
      userInfo: null,
      walletAddress: null,
    });
    return false;
  }
};

export type OauthProvider =
  | "google"
  | "naver"
  | "discord"
  | "apple"
  | "line"
  | "facebook";

export interface OAuthToken {
  idToken: string;
  refreshToken?: string;
}

// Wepin User interface for registration
export interface IWepinUser {
  status: string; // 'success' | 'fail'
  userInfo?: {
    userId: string;
    email: string;
    provider: 'google' | 'apple' | 'naver' | 'discord' | 'email' | 'external_token';
    use2FA: boolean;
  };
  userStatus: {
    loginStatus: 'complete' | 'pinRequired' | 'registerRequired';
    pinRequired?: boolean;
    walletId: string;
  };
  token?: {
    accessToken: string;
    refreshToken: string;
  };
}

// WepinSDK Lifecycle status types
export type WepinLifeCycle = 
  | "not_initialized"    // WepinSDK이 초기화되지 않음
  | "initializing"       // WepinSDK초기화 진행 중
  | "initialized"        // WepinSDK초기화 완료
  | "before_login"       // WepinSDK은 초기화되었으나 사용자는 로그인되지 않음
  | "login"              // 사용자가 로그인 되었고 위핀에도 가입되어있음
  | "login_before_register"; // 사용자가 로그인하였으나 위핀에 가입되지 않음

// Utility function to get WepinSDK status
export const getWepinStatus = async (sdk: WepinSDKLike): Promise<WepinLifeCycle> => {
  try {
    const status = await sdk.getStatus();
    console.log("🔍 WepinSDK Status:", status);
    return status as WepinLifeCycle;
  } catch (error) {
    console.error("❌ Failed to get WepinSDK status:", error);
    return "not_initialized";
  }
};

// Function to check if WepinSDK is in a specific state
export const isWepinInState = async (sdk: WepinSDKLike, targetState: WepinLifeCycle): Promise<boolean> => {
  try {
    const currentStatus = await getWepinStatus(sdk);
    return currentStatus === targetState;
  } catch (error) {
    console.error("❌ Failed to check WepinSDK state:", error);
    return false;
  }
};

// Function to check if user is fully logged in and registered
export const isUserFullyLoggedIn = async (sdk: WepinSDKLike): Promise<boolean> => {
  try {
    const status = await getWepinStatus(sdk);
    return status === "login";
  } catch (error) {
    console.error("❌ Failed to check if user is fully logged in:", error);
    return false;
  }
};

// Function to check if user needs to register with Wepin
export const needsWepinRegistration = async (sdk: WepinSDKLike): Promise<boolean> => {
  try {
    const status = await getWepinStatus(sdk);
    return status === "login_before_register";
  } catch (error) {
    console.error("❌ Failed to check if user needs registration:", error);
    return false;
  }
};

// Function to register user to Wepin
export const registerUserToWepin = async (sdk: WepinSDKLike): Promise<IWepinUser> => {
  try {
    console.log("🔄 Starting Wepin user registration...");
    
    // Check if user is in the correct state for registration
    const status = await getWepinStatus(sdk);
    if (status !== "login_before_register") {
      throw new Error(`Cannot register user. Current status: ${status}. Expected: login_before_register`);
    }
    
    console.log("✅ User status is correct for registration, proceeding...");
    const userInfo = await sdk.register();
    
    console.log("🎉 User registration successful:", userInfo);
    return userInfo;
  } catch (error) {
    console.error("❌ Failed to register user to Wepin:", error);
    throw error;
  }
};

export interface LoginResult {
  provider: OauthProvider;
  token: OAuthToken;
}

export interface LoginErrorResult {
  error: string; // error message
  provider?: OauthProvider;
  idToken?: string;
  accessToken?: string;
}

// Get Wepin configuration from environment variables
const getWepinConfig = () => {
  const appId = import.meta.env.VITE_WEPIN_APP_ID;
  const appKey = import.meta.env.VITE_WEPIN_APP_KEY;
  
  if (!appId || !appKey) {
    console.warn('Wepin app ID or app key not found in environment variables');
    return { appId: '', appKey: '' };
  }
  
  return { appId, appKey };
};

export const initWepin = async (
  appId?: string,
  appKey?: string,
  options: { language?: string; currency?: string } = {}
): Promise<WepinInstances> => {
  const { language = "ko", currency = "KRW" } = options;
  
  // Use provided appId/appKey or fall back to environment variables
  const config = getWepinConfig();
  const finalAppId = appId || config.appId;
  const finalAppKey = appKey || config.appKey;

  if (!finalAppId || !finalAppKey) {
    throw new Error('Wepin app ID and app key are required');
  }

  const sdk = new WepinSDK({ appId: finalAppId, appKey: finalAppKey });

  const { WepinLogin } = await import("@wepin/login-js");
  const login = new WepinLogin({ appId: finalAppId, appKey: finalAppKey });

  const { WepinProvider } = await import("@wepin/provider-js");
  const provider = new WepinProvider({ appId: finalAppId, appKey: finalAppKey });

  await sdk.init();
  await login.init(language);
  await provider.init({ defaultLanguage: language, defaultCurrency: currency });

  lastInstances = { sdk: sdk as unknown as WepinSDKLike, login: login as unknown as WepinLoginLike, provider: provider as unknown as WepinProviderLike };
  return { sdk: sdk as unknown as WepinSDKLike, login: login as unknown as WepinLoginLike, provider: provider as unknown as WepinProviderLike };
};

export const getAccounts = async (
  sdk: WepinSDKLike,
  options?: GetAccountsOptions
): Promise<AccountInfo[]> => {
  return sdk.getAccounts(options || {});
};

export interface LoginSuccessResult {
  status: "success" | "error";
  provider?: OauthProvider;
  userInfo?: WepinUserInfo;
  idToken?: string;
  refreshToken?: string;
  message?: string;
}

export const loginWithOauth = async (
  login: WepinLoginLike,
  provider: OauthProvider = "google"
): Promise<LoginSuccessResult> => {
  try {
    const oauthUnknown = await login
      .loginWithOauthProvider({ provider, withLogout: false })
      .catch((error: unknown) => {
        const message =
          error && typeof error === "object" && "message" in error
            ? String((error as { message?: unknown }).message)
            : "";
        if (message.includes("Cross-Origin-Opener-Policy")) {
          throw new Error(
            "팝업 창이 차단되었습니다. 브라우저 설정을 확인해주세요."
          );
        }
        throw error as unknown;
      });
    const oauth = oauthUnknown as LoginResult | LoginErrorResult;

    if ((oauth as LoginResult)?.token) {
      const { token } = oauth as LoginResult;
      const wepinResultUnknown = await login.loginWepin({ provider, token });
      const wepinResult = wepinResultUnknown as { status: "success" | "error"; userInfo?: WepinUserInfo };
      if (wepinResult.status === "success") {
        return {
          status: "success",
          provider,
          userInfo: wepinResult.userInfo,
          idToken: token.idToken,
          refreshToken: token.refreshToken,
        };
      }
      return { status: "error", provider, message: "WEPIN 로그인 실패" };
    } else {
      const err = oauth as LoginErrorResult;
      return {
        status: "error",
        provider: err.provider,
        idToken: err.idToken,
        message: err.error || "OAuth 로그인 실패",
      };
    }
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : "알 수 없는 오류";
    return { status: "error", message };
  }
};

export const loginWithGoogle = async (login: WepinLoginLike): Promise<LoginSuccessResult> => {
  return loginWithOauth(login, "google");
};

export const logoutWepin = async (login: WepinLoginLike): Promise<boolean> => {
  const result = await login.logout();
  return typeof result === "boolean" ? result : result?.status === "success";
};

export const getVeryNetworkProvider = async (
  wepinProvider: WepinProviderLike
): Promise<Eip1193Provider> => {
  try {
    console.log("Getting Very network provider from Wepin provider interface...");
    const provider = await wepinProvider.getProvider("evmvery");
    
    if (!provider) {
      throw new Error("Failed to get Very network provider from Wepin");
    }
    
    console.log("✅ Successfully got Very network provider:", provider);
    return provider;
  } catch (error) {
    console.error("❌ Failed to get Very network provider:", error);
    throw error;
  }
};

// Function to get Wepin provider for contract interactions
export const getWepinProvider = async (): Promise<Eip1193Provider | null> => {
  try {
    // Try to get from last instances first
    if (lastInstances?.provider) {
      console.log("Using Wepin provider from last instances");
      try {
        const provider = await lastInstances.provider.getProvider("evmvery");
        if (provider) {
          console.log("✅ Successfully got Wepin provider from last instances");
          return provider;
        }
      } catch (providerError) {
        console.warn("Failed to get provider from last instances:", providerError);
      }
    }
    
    // If last instances failed, try to get from global state
    console.log("Trying to get Wepin instances from global state...");
    const globalInstances = getLastWepinInstances();
    
    if (globalInstances?.provider) {
      console.log("Found Wepin instances in global state");
      try {
        const provider = await globalInstances.provider.getProvider("evmvery");
        if (provider) {
          console.log("✅ Successfully got Wepin provider from global state");
          return provider;
        }
      } catch (globalProviderError) {
        console.warn("Failed to get provider from global instances:", globalProviderError);
      }
    }
    
    // If still no provider, return null
    console.log("No Wepin instances available for provider");
    return null;
  } catch (error) {
    console.error("Failed to get Wepin provider:", error);
    return null;
  }
};







// Function to check if Wepin instances are available
export const areWepinInstancesAvailable = (): boolean => {
  const hasLastInstances = !!lastInstances?.provider;
  const hasGlobalInstances = !!getLastWepinInstances()?.provider;
  
  console.log("Wepin instances availability check:", {
    hasLastInstances,
    hasGlobalInstances,
    lastInstances: !!lastInstances,
    globalInstances: !!getLastWepinInstances(),
    lastInstancesDetails: lastInstances ? {
      hasSDK: !!lastInstances.sdk,
      hasProvider: !!lastInstances.provider,
      hasLogin: !!lastInstances.login
    } : null,
    globalInstancesDetails: getLastWepinInstances() ? {
      hasSDK: !!getLastWepinInstances()?.sdk,
      hasProvider: !!getLastWepinInstances()?.provider,
      hasLogin: !!getLastWepinInstances()?.login
    } : null
  });
  
  return hasLastInstances || hasGlobalInstances;
};

// Function to force Wepin initialization if needed
export const forceWepinInitialization = async (): Promise<boolean> => {
  try {
    console.log("🔄 Force initializing Wepin...");
    
    // Check if we already have instances
    if (areWepinInstancesAvailable()) {
      console.log("✅ Wepin instances already available");
      return true;
    }
    
    // Try to initialize Wepin
    const { initWepin } = await import("./wepin");
    const instances = await initWepin();
    
    if (instances?.provider) {
      console.log("✅ Force initialization successful:", instances);
      updateLastWepinInstances(instances);
      return true;
    } else {
      console.log("❌ Force initialization failed - no provider");
      return false;
    }
  } catch (error) {
    console.error("❌ Force initialization error:", error);
    return false;
  }
};

// Function to get Very network RPC provider directly (for contract reads)
export const getVeryNetworkRPCProvider = (): ethers.Provider => {
  const rpcUrl = import.meta.env.VITE_RPC_URL || "https://rpc.verylabs.io";
  console.log("🌐 Using direct Very network RPC provider:", rpcUrl);
  return new ethers.JsonRpcProvider(rpcUrl);
};

// Function to get current provider status
export const getProviderStatus = async (): Promise<{
  hasWepinProvider: boolean;
  wepinNetwork?: any;
  fallbackRpcUrl: string;
  providerType: 'wepin' | 'rpc' | 'alternative-rpc';
}> => {
  try {
    const wepinProvider = await getWepinProvider();
    if (wepinProvider) {
      const testProvider = new ethers.BrowserProvider(wepinProvider);
      const network = await testProvider.getNetwork();
      return {
        hasWepinProvider: true,
        wepinNetwork: network,
        fallbackRpcUrl: import.meta.env.VITE_RPC_URL || "https://rpc.verylabs.io",
        providerType: 'wepin'
      };
    }
  } catch (error) {
    console.log("Wepin provider not available for status check");
  }
  
  return {
    hasWepinProvider: false,
    fallbackRpcUrl: import.meta.env.VITE_RPC_URL || "https://rpc.verylabs.io",
    providerType: 'rpc'
  };
};



// Check if user is logged in to WEPIN
export const isLoggedInToWepin = async (sdk: WepinSDKLike): Promise<boolean> => {
  try {
    const accounts = await sdk.getAccounts({ withEoa: true });
    return accounts && accounts.length > 0;
  } catch (error) {
    return false;
  }
};


