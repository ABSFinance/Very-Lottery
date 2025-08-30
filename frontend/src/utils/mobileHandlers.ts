import {
  loginWithGoogle,
  logoutWepin,
  getVeryNetworkProvider,
  getAccounts,
  WepinLoginLike,
  WepinSDKLike,
  WepinProviderLike,
  WepinUserInfo,
  AccountInfo,
  getGlobalLoginState,
  getWepinStatus,
  needsWepinRegistration,
  registerUserToWepin
} from "./wepin";
import { buildReferralLink, shareReferralLink } from "./referral";

export const createLoginHandler = ({
  wepinLogin,
  wepinSdk,
  isInitialized,
  setIsLoading,
  setIsLoggedIn,
  setUserInfo,
  updateGlobalLoginState,
  checkAndUpdateGlobalLoginState,
  setGlobalLoginState,
}: {
  wepinLogin: WepinLoginLike | null;
  wepinSdk: WepinSDKLike | null;
  isInitialized: boolean;
  setIsLoading: (v: boolean) => void;
  setIsLoggedIn: (v: boolean) => void;
  setUserInfo: (v: (WepinUserInfo & { walletAddress?: string }) | null) => void;
  updateGlobalLoginState: (state: any) => void;
  checkAndUpdateGlobalLoginState: (sdk: WepinSDKLike) => Promise<boolean>;
  setGlobalLoginState: (state: any) => void;
}) => {
  return async () => {
    if (!wepinLogin || !wepinSdk || !isInitialized) return;
    
    setIsLoading(true);
    
    try {
      console.log("🚀 Starting login process...");
      
      // Step 1: OAuth Login with Google
      console.log("📱 Step 1: OAuth login with Google...");
      const result = await loginWithGoogle(wepinLogin);
      
      if (result.status === "success") {
        console.log("✅ OAuth login successful, checking Wepin status...");
        
        // Step 2: Check if user needs to register with Wepin
        const wepinStatus = await getWepinStatus(wepinSdk);
        console.log("🔍 Current Wepin status:", wepinStatus);
        
        if (wepinStatus === "login_before_register") {
          console.log("📝 User needs to complete Wepin registration...");
          
          // Step 3: Automatic Registration
          try {
            console.log("🔄 Starting automatic Wepin registration...");
            const registrationResult = await registerUserToWepin(wepinSdk);
            
            if (registrationResult.status === "success") {
              console.log("🎉 Wepin registration completed successfully!");
              
              // Verify final status after registration
              const finalStatus = await getWepinStatus(wepinSdk);
              console.log("🔍 Final Wepin status after registration:", finalStatus);
              
              if (finalStatus === "login") {
                console.log("✅ User is now fully logged in and registered");
              } else {
                console.warn("⚠️ Registration completed but status is still:", finalStatus);
              }
            } else {
              console.error("❌ Wepin registration failed with status:", registrationResult.status);
              alert("Wepin 등록에 실패했습니다. 다시 시도해주세요.");
              setIsLoading(false);
              return;
            }
          } catch (registrationError) {
            console.error("❌ Wepin registration process failed:", registrationError);
            alert("Wepin 등록 과정에서 오류가 발생했습니다. 다시 시도해주세요.");
            setIsLoading(false);
            return;
          }
        } else if (wepinStatus === "login") {
          console.log("✅ User is already fully logged in and registered");
        } else {
          console.log("⚠️ Unexpected Wepin status:", wepinStatus);
        }
        
        // Step 4: Get wallet accounts and complete login
        console.log("💳 Getting wallet accounts...");
        let walletAddress: string | undefined;
        
        try {
          const accounts = await getAccounts(wepinSdk);
          const very = (accounts || []).find((a: AccountInfo) =>
            (a?.network || "").toLowerCase().includes("very")
          ) || accounts?.[0];
          
          walletAddress = very?.address;
          console.log("✅ Wallet address obtained:", walletAddress);
        } catch (accountError) {
          console.warn("⚠️ Failed to get accounts:", accountError);
        }
        
        // Update both local and global login state
        const loginState = {
          isLoggedIn: true,
          userInfo: result.userInfo,
          walletAddress: walletAddress,
        };
        
        console.log("🔄 Updating login state:", loginState);
        updateGlobalLoginState(loginState);
        setGlobalLoginState(loginState);
        
        // Update local component state
        setIsLoggedIn(true);
        setUserInfo({ ...result.userInfo, walletAddress });
        
        console.log("🎉 Login process completed successfully!");
        
      } else {
        console.error("❌ OAuth login failed:", result.message);
        alert(`로그인에 실패했습니다: ${result.message}`);
      }
      
    } catch (error) {
      console.error("❌ Login process failed:", error);
      const errorMessage = error instanceof Error ? error.message : "알 수 없는 오류";
      alert(`로그인 과정에서 오류가 발생했습니다: ${errorMessage}`);
    } finally {
      setIsLoading(false);
    }
  };
};

export const createLogoutHandler = ({
  wepinLogin,
  isInitialized,
  setIsLoggedIn,
  setUserInfo,
  clearGlobalLoginState,
  clearGlobalWepinState,
}: {
  wepinLogin: WepinLoginLike | null;
  isInitialized: boolean;
  setIsLoggedIn: (v: boolean) => void;
  setUserInfo: (v: WepinUserInfo | null) => void;
  clearGlobalLoginState: () => void;
  clearGlobalWepinState: () => void;
}) => {
  return async () => {
    if (!wepinLogin || !isInitialized) return;
    const ok = await logoutWepin(wepinLogin);
    if (ok) {
      setIsLoggedIn(false);
      setUserInfo(null);
      clearGlobalLoginState();
      clearGlobalWepinState();
    }
  };
};

export const createProviderHandler = ({
  wepinProvider,
  isInitialized,
  setProviderStatus,
}: {
  wepinProvider: WepinProviderLike | null;
  isInitialized: boolean;
  setProviderStatus: (v: string) => void;
}) => {
  return async () => {
    if (!wepinProvider || !isInitialized) return;
    setProviderStatus("Ethereum Provider 가져오는 중...");
    try {
      const provider = await getVeryNetworkProvider(wepinProvider);
      if (provider) {
        setProviderStatus("Ethereum Provider 연결 성공!");
        try {
          // optional: EIP-1193에는 표준 getNetwork가 없을 수 있음. 필요한 경우 제거/대체
          // console.log("Ethereum provider ready");
        } catch {}
      } else {
        setProviderStatus("Ethereum Provider 가져오기 실패");
      }
    } catch (e: unknown) {
      const message = e instanceof Error ? e.message : "알 수 없는 오류";
      setProviderStatus(
        `Ethereum Provider 가져오기 실패: ${message}`
      );
    }
  };
};

export const createInviteShareHandler = ({
  isLoggedIn,
  userInfo,
  referralId,
}: {
  isLoggedIn: boolean;
  userInfo: (WepinUserInfo & { walletAddress?: string }) | null;
  referralId: string;
}) => {
  return async () => {
    if (!isLoggedIn) {
      alert("먼저 로그인 해주세요.");
      return;
    }
    
    // Get wallet address from global state or userInfo
    const globalState = getGlobalLoginState();
    const walletAddress = globalState?.walletAddress || userInfo?.walletAddress;
    
    // Check if we have a valid wallet address
    if (!walletAddress || walletAddress === "0x0000000000000000000000000000000000000000") {
      alert("지갑 주소를 가져올 수 없습니다. 잠시 후 다시 시도해주세요.");
      return;
    }
    
    // Use wallet address for referral
    const referralUser = {
      walletAddress: walletAddress
    };
    const link = buildReferralLink(window.location.origin, referralUser);
    await shareReferralLink(link);
  };
};