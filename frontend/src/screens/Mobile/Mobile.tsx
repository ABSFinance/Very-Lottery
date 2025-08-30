import { useEffect, useState, useMemo } from "react";
import { Button } from "../../components/ui/button";
import { Card, CardContent } from "../../components/ui/card";
import { AUTH_CONFIG, validateConfig } from "../../config/auth";
import ReferralCard from "../../components/ReferralCard";
import PromoLuckyCard from "../../components/PromoLuckyCard";
import PromoDropCard from "../../components/PromoDropCard";
import PromoAdsCard from "../../components/PromoAdsCard";
import LoginCard from "../../components/LoginCard";
import TotalEarningCard from "../../components/TotalEarningCard";
import {
  initWepin,
  WepinSDKLike,
  WepinLoginLike,
  WepinUserInfo,
  updateGlobalLoginState,
  checkAndUpdateGlobalLoginState,
  clearGlobalLoginState,
  getGlobalLoginState,
  getVeryNetworkProvider,
} from "../../utils/wepin";
import {
  setGlobalWepinInstances,
  getGlobalWepinInstances,
  setGlobalLoginState,
  getGlobalLoginState as getGlobalWepinLoginState,
  clearGlobalWepinState,
  subscribeToWepinStateChanges,
  shouldAutoLogin,
  getStoredUserInfo,
  refreshLoginStateFromStorage,
} from "../../utils/globalWepinState";
import { captureInboundRef } from "../../utils/referral";
import {
  createLoginHandler,
  createLogoutHandler,
  createInviteShareHandler,
} from "../../utils/mobileHandlers";
import { fetchReferralStats } from "../../utils/contracts";

export const Mobile = (): JSX.Element => {
  const [wepinSdk, setWepinSdk] = useState<WepinSDKLike | null>(null);
  const [wepinLogin, setWepinLogin] = useState<WepinLoginLike | null>(null);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userInfo, setUserInfo] = useState<
    (WepinUserInfo & { walletAddress?: string }) | null
  >(null);
  const [isInitialized, setIsInitialized] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Referral 상태
  const [referralId] = useState<string>("");
  const [totalReferrals, setTotalReferrals] = useState<number>(0);
  const [totalEarnings, setTotalEarnings] = useState<number>(0);

  // Provider state for contract calls
  const [veryNetworkProvider, setVeryNetworkProvider] = useState<any>(null);

  // Game mapping placeholder (you can replace with router navigation)
  const openGame = (gameKey: string) => {
    const routeMap: Record<string, string> = {
      CRYPTOLOTTO_1DAY: "/games/daily-lucky",
      CRYPTOLOTTO_7DAYS: "/games/weekly-jackpot",
      CRYPTOLOTTO_AD: "/games/ads-lucky",
    };

    // Get the base path
    let path = routeMap[gameKey] || "/games";

    // Check if there's a referral parameter in the current URL
    const currentUrl = new URL(window.location.href);
    const refParam = currentUrl.searchParams.get("ref");

    // If there's a referral parameter, add it to the new path
    if (refParam) {
      path += `?ref=${encodeURIComponent(refParam)}`;
      console.log("🔗 Preserving referral parameter:", refParam, "->", path);
    }

    // Pass only essential data (avoid circular references)
    const gameData = {
      isLoggedIn,
      userInfo: userInfo
        ? {
            email: userInfo.email,
            provider: userInfo.provider,
            walletAddress: userInfo.walletAddress,
          }
        : null,
      gameType: gameKey,
      referralId: refParam, // Pass referral ID to game page
    };

    // Store in sessionStorage for the game page to access
    sessionStorage.setItem("game_data", JSON.stringify(gameData));

    // Update URL and trigger immediate navigation
    if (window && window.history && window.history.pushState) {
      window.history.pushState({}, "", path);
      // Dispatch custom navigation event to trigger React re-render
      window.dispatchEvent(new CustomEvent("navigation", { detail: { path } }));
    } else {
      window.location.href = path;
    }
  };

  useEffect(() => {
    validateConfig();
    (async () => {
      try {
        // First, try to restore login state from storage
        console.log("🔄 Attempting to restore login state from storage in Mobile...");
        const restored = refreshLoginStateFromStorage();
        if (restored) {
          const globalState = getGlobalWepinLoginState();
          if (globalState?.isLoggedIn && globalState?.userInfo) {
            console.log("✅ Successfully restored login state in Mobile:", globalState);
            setIsLoggedIn(true);
            setUserInfo(globalState.userInfo);
          }
        }

        // Check if global instances already exist
        const existingInstances = getGlobalWepinInstances();
        if (existingInstances) {
          console.log("🌍 Using existing global Wepin instances");
          setWepinSdk(existingInstances.sdk);
          setWepinLogin(existingInstances.login);
          setIsInitialized(true);
        } else {
          console.log("🌍 Initializing new Wepin instances");
          const { sdk, login, provider } = await initWepin(
            AUTH_CONFIG.WEPIN.APP_ID,
            AUTH_CONFIG.WEPIN.APP_KEY,
            { language: "ko", currency: "KRW" }
          );

          // Set local state
          setWepinSdk(sdk);
          setWepinLogin(login);
          setIsInitialized(true);

          // Set global state
          const instances = { sdk, login, provider };
          setGlobalWepinInstances(instances);
        }

        // Check if user was previously logged in
        const globalState = getGlobalWepinLoginState();
        if (globalState?.isLoggedIn && globalState?.userInfo) {
          setIsLoggedIn(true);
          setUserInfo(globalState.userInfo);

          // Get Very network provider for contract calls
          if (existingInstances?.provider) {
            try {
              const provider = await getVeryNetworkProvider(
                existingInstances.provider
              );
              setVeryNetworkProvider(provider);
              console.log(
                "✅ Got Very network provider from existing instances"
              );
            } catch (error) {
              console.warn(
                "Failed to get provider from existing instances:",
                error
              );
            }
          }
        } else if (shouldAutoLogin()) {
          // Check if we have stored login state that we can restore
          const storedUserInfo = getStoredUserInfo();
          if (storedUserInfo) {
            console.log("🔄 Restoring login state from storage in Mobile:", storedUserInfo);
            setUserInfo(storedUserInfo);
            setIsLoggedIn(true);
          }
        }
      } catch (e) {
        console.error("WEPIN 초기화 실패:", e);
      }
    })();

    captureInboundRef();
  }, []);

  // Fetch referral stats when logged in
  useEffect(() => {
    if (isLoggedIn && veryNetworkProvider) {
      const fetchReferralData = async () => {
        try {
          // Get user wallet address from global state
          const globalState = getGlobalLoginState();
          const walletAddress = globalState?.walletAddress;

          if (walletAddress) {
            const referralStats = await fetchReferralStats(
              walletAddress,
              veryNetworkProvider
            );
            setTotalReferrals(referralStats.totalReferrals);
            setTotalEarnings(referralStats.totalRewards);
          }
        } catch (e) {
          console.error("Failed to fetch referral stats:", e);
        }
      };

      fetchReferralData();
    }
  }, [isLoggedIn, veryNetworkProvider]);

  const handleLogin = useMemo(
    () =>
      createLoginHandler({
        wepinLogin,
        wepinSdk,
        isInitialized,
        setIsLoading,
        setIsLoggedIn,
        setUserInfo,
        updateGlobalLoginState,
        checkAndUpdateGlobalLoginState,
        setGlobalLoginState, // Add global state update
      }),
    [wepinLogin, wepinSdk, isInitialized]
  );

  const handleLogout = useMemo(
    () =>
      createLogoutHandler({
        wepinLogin,
        isInitialized,
        setIsLoggedIn,
        setUserInfo,
        clearGlobalLoginState,
        clearGlobalWepinState,
      }),
    [wepinLogin, isInitialized]
  );

  const handleInviteShare = useMemo(
    () =>
      createInviteShareHandler({
        isLoggedIn,
        userInfo,
        referralId,
      }),
    [isLoggedIn, userInfo, referralId]
  );

  return (
    <div className="bg-[#171b25] grid justify-items-center [align-items:start] w-screen">
      <div className="bg-[#171b25] w-[393px] h-[100vh] relative">
        {/* Main Content Area */}
        <div className="w-[394px] h-full">
          {/* Scrollable Content */}
          <div className="w-[394px] h-full overflow-y-auto">
            <div className="relative w-[406px] min-h-full top-0 -left-2">
              <div className="w-[397px] min-h-full left-[9px] bg-[#171b25]" />

              {/* WEPIN Login Section (only before login) */}
              {!isLoggedIn && (
                <div className="w-[361px] h-[80px] mt-5 ml-6 mb-5">
                  <LoginCard
                    isLoading={isLoading}
                    isInitialized={isInitialized}
                    onLogin={handleLogin}
                  />
                </div>
              )}

              {/* Referral (Invite Friends) - only after login, replaces login position */}
              {isLoggedIn && (
                <div className="w-[361px] h-[120px] mt-5 ml-6 mb-5">
                  <ReferralCard
                    totalReferrals={totalReferrals}
                    totalEarnings={totalEarnings}
                    onInvite={handleInviteShare}
                  />
                </div>
              )}

              {/* Logged-in user box with logout (below referral) */}
              {isLoggedIn && (
                <div className="w-[361px] h-[80px] ml-6 mb-5">
                  <Card className="relative w-[359px] h-[80px] rounded-[7px] bg-[#00000033] border-[#666]">
                    <CardContent className="p-0 relative h-full">
                      <div className="absolute h-[60px] top-[10px] left-[20px] right-[20px] flex items-center gap-3">
                        <div className="w-8 h-8 bg-[#ff6c74] rounded-full flex items-center justify-center">
                          <span className="text-white text-sm font-bold">
                            {userInfo?.email?.charAt(0)?.toUpperCase() || "U"}
                          </span>
                        </div>
                        <div className="text-white flex-1">
                          <div className="font-semibold text-sm">
                            {userInfo?.email || "사용자"}
                          </div>
                          <div className="text-xs text-gray-300">
                            {userInfo?.provider || ""} 계정
                          </div>
                        </div>
                        <Button
                          onClick={handleLogout}
                          className="bg-[#666] hover:bg-[#555] text-white px-4 py-2 rounded-lg ml-auto"
                        >
                          로그아웃
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              )}

              {/* Total Earning Card */}
              <div className="w-[361px] ml-6 mb-5">
                <TotalEarningCard amount={10000} />
              </div>

              {/* Promotional Cards */}
              <div className="w-[361px] ml-6 mb-5">
                <PromoLuckyCard onSelect={() => openGame("CRYPTOLOTTO_1DAY")} />
              </div>

              <div className="w-[361px] ml-6 mb-5">
                <PromoDropCard onSelect={() => openGame("CRYPTOLOTTO_7DAYS")} />
              </div>

              <div className="w-[361px] ml-[23px] mb-5">
                <PromoAdsCard onSelect={() => openGame("CRYPTOLOTTO_AD")} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
