import React, { useEffect, useState, useMemo } from "react";
import { Button } from "../../components/ui/button";
import { Card, CardContent } from "../../components/ui/card";
import {
  updateGlobalLoginState,
  loginWithGoogle,
  getVeryNetworkProvider,
  initWepin,
  WepinSDKLike,
  WepinLoginLike,
  WepinUserInfo,
  checkAndUpdateGlobalLoginState,
  clearGlobalLoginState,
} from "../../utils/wepin";
import {
  getGlobalWepinInstances,
  getGlobalLoginState,
  subscribeToWepinStateChanges,
  setGlobalWepinInstances,
  setGlobalLoginState,
  clearGlobalWepinState,
  shouldAutoLogin,
  getStoredUserInfo,
  refreshLoginStateFromStorage,
} from "../../utils/globalWepinState";
import {
  getGameContractInfo,
  fetchRemainingTime,
  fetchUserTicketCount,
  fetchJackpot,
  createDynamicGameConfig,
  fetchReferralStats,
  fetchUserBalance,
  fetchAdTokenBalance,
  getAdTokenApproval,
  approveAdTokens,
  buyAdTicket,
  GameType,
  GameConfig,
  GAME_CONFIGS,
} from "../../utils/contracts";
import { TicketPurchaseService } from "../../utils/ticketPurchaseService";
import { MyTicketsCard } from "../../components/MyTicketsCard";
import ReferralCard from "../../components/ReferralCard";
import LoginCard from "../../components/LoginCard";
import {
  TicketPurchasePopup,
  TicketInfo,
} from "../../components/TicketPurchasePopup";
import { navigationItems } from "../../utils/layout";
import { AUTH_CONFIG, validateConfig } from "../../config/auth";
import {
  createLoginHandler,
  createLogoutHandler,
  createInviteShareHandler,
} from "../../utils/mobileHandlers";
import { NotificationPopup } from "../../components/NotificationPopup";
import { InfoPopup } from "../../components/InfoPopup";

interface VeryLuckyProps {
  gameType?: GameType;
}

export const VeryLucky: React.FC<VeryLuckyProps> = ({
  gameType = "daily-lucky",
}) => {
  const [gameConfig, setGameConfig] = useState<GameConfig>(
    GAME_CONFIGS[gameType]
  );
  const [jackpot, setJackpot] = useState<string>("10, 000");
  const [account, setAccount] = useState<string>("");
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(false);
  const [isCheckingLogin, setIsCheckingLogin] = useState<boolean>(true);
  const [isProcessingPurchase, setIsProcessingPurchase] =
    useState<boolean>(false);
  const [userTicketCount, setUserTicketCount] = useState<number>(0);
  const [remainingTime, setRemainingTime] = useState<string>("00:00:00");
  const [userBalance, setUserBalance] = useState<number>(0);
  const [userAdBalance, setUserAdBalance] = useState<number>(0);
  const [adTokenApproval, setAdTokenApproval] = useState<number>(0);

  // Wepin state
  const [wepinSdk, setWepinSdk] = useState<WepinSDKLike | null>(null);
  const [wepinLogin, setWepinLogin] = useState<WepinLoginLike | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [userInfo, setUserInfo] = useState<
    (WepinUserInfo & { walletAddress?: string }) | null
  >(null);
  
  // Flag to prevent state restoration after logout
  const [hasLoggedOut, setHasLoggedOut] = useState(false);

  // Use global Wepin instances
  const wepin = getGlobalWepinInstances();

  // Single provider instance to avoid repeated calls
  const [veryNetworkProvider, setVeryNetworkProvider] = useState<any>(null);

  // Referral state
  const [referralId, setReferralId] = useState<string>(
    "0x0000000000000000000000000000000000000000"
  );
  const [totalReferrals, setTotalReferrals] = useState<number>(0);
  const [totalEarnings, setTotalEarnings] = useState<number>(0);

  // Ticket purchase popup state
  const [isPurchasePopupOpen, setIsPurchasePopupOpen] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState<TicketInfo | null>(null);

  // Notification popup state
  const [isNotificationPopupOpen, setIsNotificationPopupOpen] = useState(false);

  // Info popup state
  const [isInfoPopupOpen, setIsInfoPopupOpen] = useState(false);

  // Subscribe to global Wepin state changes
  useEffect(() => {
    const unsubscribe = subscribeToWepinStateChanges(() => {
      console.log("🌍 Global Wepin state changed, updating component...");

      // Re-check login state when global state changes
      const globalState = getGlobalLoginState();
      if (globalState?.isLoggedIn !== isLoggedIn) {
        console.log("Login state mismatch detected, updating...");
        setIsLoggedIn(!!globalState?.isLoggedIn);
        setUserInfo(globalState?.userInfo || null);
      }
    });

    return unsubscribe;
  }, [isLoggedIn]);

  // Try to restore login state from storage on mount
  useEffect(() => {
    if (hasLoggedOut) {
      console.log("🚫 Skipping state restoration - user has logged out");
      return;
    }
    
    console.log("🔄 Attempting to restore login state from storage...");
    const restored = refreshLoginStateFromStorage();
    if (restored) {
      const globalState = getGlobalLoginState();
      if (globalState?.isLoggedIn && globalState?.userInfo) {
        console.log("✅ Successfully restored login state:", globalState);
        setIsLoggedIn(true);
        setUserInfo(globalState.userInfo);
        if (globalState.walletAddress) {
          setAccount(globalState.walletAddress);
        }
        setIsCheckingLogin(false);
      }
    }
  }, [hasLoggedOut]);

  // Update game config when gameType changes
  useEffect(() => {
    setGameConfig(GAME_CONFIGS[gameType]);
  }, [gameType]);

  // Capture referral ID from URL when component mounts
  useEffect(() => {
    // First check URL for referral parameter
    const url = new URL(window.location.href);
    const refParam = url.searchParams.get("ref");

    // Also check sessionStorage for referral data passed from main page
    try {
      const storedData = sessionStorage.getItem("game_data");
      if (storedData) {
        const parsedData = JSON.parse(storedData);
        if (parsedData.referralId && !refParam) {
          setReferralId(parsedData.referralId);
          console.log(
            "🎯 Referral ID captured from sessionStorage:",
            parsedData.referralId
          );
          return;
        }
      }
    } catch (e) {
      console.warn("Failed to parse game data:", e);
    }

    // If URL has referral parameter, use that
    if (refParam) {
      setReferralId(refParam);
      console.log("🎯 Referral ID captured from URL:", refParam);
    }
  }, []);

  // Debug logging
  useEffect(() => {
    console.log(
      "VeryLucky render - isLoggedIn:",
      isLoggedIn,
      "account:",
      account,
      "userInfo:",
      userInfo,
      "isInitialized:",
      isInitialized,
      "isCheckingLogin:",
      isCheckingLogin
    );
    
    // Debug localStorage state
    try {
      const stored = localStorage.getItem('wepin_global_state');
      console.log("🔍 localStorage state:", stored ? JSON.parse(stored) : "No stored state");
    } catch (e) {
      console.warn("Failed to read localStorage:", e);
    }
  }, [isLoggedIn, account, userInfo, isInitialized, isCheckingLogin]);

  // Create handlers using the same pattern as Mobile.tsx
  const handleLogin = useMemo(
    () => {
      const loginHandler = createLoginHandler({
        wepinLogin,
        wepinSdk,
        isInitialized,
        setIsLoading,
        setIsLoggedIn,
        setUserInfo,
        updateGlobalLoginState,
        checkAndUpdateGlobalLoginState,
        setGlobalLoginState,
      });
      
      return async () => {
        await loginHandler();
        // Reset logout flag when user logs in
        setHasLoggedOut(false);
        console.log("🔄 VeryLucky login completed, logout flag reset");
      };
    },
    [wepinLogin, wepinSdk, isInitialized]
  );

  const handleLogout = useMemo(
    () => {
      const logoutHandler = createLogoutHandler({
        wepinLogin,
        isInitialized,
        setIsLoggedIn,
        setUserInfo,
        clearGlobalLoginState,
        clearGlobalWepinState,
      });
      
      return async () => {
        await logoutHandler();
        // Additional cleanup for VeryLucky component
        setAccount("");
        setIsCheckingLogin(false);
        setHasLoggedOut(true); // Set flag to prevent state restoration
        console.log("🔄 VeryLucky logout completed, UI should show login component");
      };
    },
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

  // Get contract info for the current game type - memoized to prevent unnecessary recalculations
  const contractInfo = useMemo(() => getGameContractInfo(gameType), [gameType]);

  // Define ticket info for the popup
  const getTicketInfo = (): TicketInfo => {
    // Use the dynamic gameConfig state instead of static GAME_CONFIGS
    const config = gameConfig;

    // Extract price from ticketPrice string (e.g., "1 VERY" -> 1)
    const priceMatch = config.ticketPrice.match(/(\d+)/);
    const price = priceMatch ? parseInt(priceMatch[1]) : 0;

    return {
      id: gameType,
      name: config.title,
      price: price,
      maxQuantity: config.maxTicketsPerPlayer,
      deadline: gameType === "weekly-jackpot" ? "매주" : "매일",
      image: config.image,
      gameConfig: config, // Pass the full game configuration
    };
  };

  // Handle popup open/close
  const openPurchasePopup = () => {
    const ticketInfo = getTicketInfo();
    setSelectedTicket(ticketInfo);
    setIsPurchasePopupOpen(true);
  };

  const closePurchasePopup = () => {
    setIsPurchasePopupOpen(false);
    setSelectedTicket(null);
  };

  // Log contract info for debugging
  useEffect(() => {
    console.log("Contract Info for", gameType, ":", contractInfo);
  }, [gameType, contractInfo]);

  // Initialize Wepin like Mobile.tsx
  useEffect(() => {
    validateConfig();
    (async () => {
      try {
        // Check if global instances already exist
        const existingInstances = getGlobalWepinInstances();
        if (existingInstances) {
          console.log("🌍 Using existing global Wepin instances");
          setWepinSdk(existingInstances.sdk);
          setWepinLogin(existingInstances.login);
          setIsInitialized(true);

          // Get Very network provider once
          if (existingInstances.provider) {
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

          // Get Very network provider once
          try {
            const veryProvider = await getVeryNetworkProvider(provider);
            setVeryNetworkProvider(veryProvider);
            console.log("✅ Got Very network provider from new instances");
          } catch (error) {
            console.warn("Failed to get provider from new instances:", error);
          }
        }

        // Check if user was previously logged in
        const globalState = getGlobalLoginState();
        if (globalState?.isLoggedIn && globalState?.userInfo) {
          // Verify the login state is still valid by checking Wepin directly
          try {
            if (globalState.userInfo.walletAddress) {
              setAccount(globalState.userInfo.walletAddress);
            }
            setUserInfo(globalState.userInfo);
            setIsLoggedIn(true);
            console.log("Using global login state");
          } catch (e) {
            console.log("Global login state invalid, setting to logged out");
            setIsLoggedIn(false);
            setUserInfo(null);
          }
          setIsCheckingLogin(false);
        } else if (shouldAutoLogin()) {
          // Check if we have stored login state that we can restore
          const storedUserInfo = getStoredUserInfo();
          if (storedUserInfo) {
            console.log("🔄 Restoring login state from storage:", storedUserInfo);
            setUserInfo(storedUserInfo);
            if (storedUserInfo.walletAddress) {
              setAccount(storedUserInfo.walletAddress);
            }
            setIsLoggedIn(true);
            setIsCheckingLogin(false);
          } else {
            setIsLoggedIn(false);
            setUserInfo(null);
            setIsCheckingLogin(false);
          }
        } else {
          console.log("No global login state, user is logged out");
          setIsLoggedIn(false);
          setUserInfo(null);
          setIsCheckingLogin(false);
        }
      } catch (e) {
        console.error("WEPIN 초기화 실패:", e);
        setIsCheckingLogin(false);
      }
    })();
  }, []);

  // Fetch referral stats when logged in (only when user data changes)
  useEffect(() => {
    if (isLoggedIn && account && veryNetworkProvider) {
      const fetchUserData = async () => {
        try {
          // Fetch referral stats
          const referralStats = await fetchReferralStats(
            account,
            veryNetworkProvider
          );
          setTotalReferrals(referralStats.totalReferrals);
          setTotalEarnings(referralStats.totalRewards);

          // Fetch user's balance based on game type
          let balance: number;
          if (gameType === "ads-lucky") {
            // For ADS LUCKY, fetch AD token balance
            balance = await fetchAdTokenBalance(account, veryNetworkProvider);
            setUserAdBalance(balance);
            setUserBalance(0); // ETH balance is 0 for AD lottery
            
            // Also fetch AD token approval status
            const approval = await getAdTokenApproval(account, veryNetworkProvider);
            setAdTokenApproval(approval);
            console.log("🔐 AD Token approval status:", approval);
          } else {
            // For other games, fetch ETH balance
            balance = await fetchUserBalance(account, veryNetworkProvider);
            setUserBalance(balance);
            setUserAdBalance(0); // AD balance is 0 for other games
            setAdTokenApproval(0); // No approval needed for other games
          }
        } catch (e) {
          console.error("Failed to fetch user data:", e);
        }
      };

      fetchUserData();
    }
  }, [isLoggedIn, account, veryNetworkProvider, gameType]);

  useEffect(() => {
    if (hasLoggedOut) {
      console.log("🚫 Skipping sessionStorage restoration - user has logged out");
      return;
    }
    
    // Get data passed from Mobile.tsx
    try {
      const storedData = sessionStorage.getItem("game_data");
      if (storedData) {
        const parsedData = JSON.parse(storedData);

        // Use the passed login state
        if (parsedData.isLoggedIn) {
          setIsLoggedIn(true);
          setIsCheckingLogin(false);
          if (parsedData.userInfo?.walletAddress) {
            setAccount(parsedData.userInfo.walletAddress);
          }
          console.log("Using login state from Mobile.tsx");
        } else {
          setIsLoggedIn(false);
          setIsCheckingLogin(false);
          console.log("User not logged in from Mobile.tsx");
        }
      } else {
        // Fallback to WEPIN check if no data passed
        console.log("No game data found, checking WEPIN directly");
        if (wepin?.sdk) {
          // Try to check WEPIN login status directly
          (async () => {
            try {
              // Since we can't use getAccounts here, we'll assume user is not logged in
              // This is a fallback scenario anyway
              console.log(
                "WEPIN SDK available but can't check accounts directly"
              );
              setIsLoggedIn(false);
              setIsCheckingLogin(false);
            } catch (e) {
              console.log("WEPIN check failed:", e);
              setIsLoggedIn(false);
              setIsCheckingLogin(false);
            }
          })();
        } else {
          console.log("No WEPIN SDK available, user is logged out");
          setIsCheckingLogin(false);
          setIsLoggedIn(false);
        }
      }
    } catch (e) {
      console.warn("Failed to parse game data:", e);
      setIsCheckingLogin(false);
      setIsLoggedIn(false);
    }
  }, [wepin, hasLoggedOut]);

  useEffect(() => {
    // Load contract data if logged in and provider is available
    if (!isLoggedIn || !veryNetworkProvider) return;

    // Fetch jackpot using utility function
    const fetchJackpotData = async () => {
      try {
        console.log("fetchJackpotData - Using existing provider");
        const jackpotData = await fetchJackpot(gameType, veryNetworkProvider);
        setJackpot(jackpotData);
      } catch (e) {
        console.warn("컨트랙트 읽기 실패:", e);
      }
    };

    fetchJackpotData();
  }, [isLoggedIn, gameType, veryNetworkProvider]);

  // Debug: Log component state changes
  useEffect(() => {
    console.log("🔍 VeryLucky Component State:", {
      isLoggedIn,
      account,
      veryNetworkProvider: !!veryNetworkProvider,
      gameType,
      userTicketCount,
      userBalance,
      userAdBalance,
      adTokenApproval,
      needsApproval: needsAdTokenApproval(),
      isInitialized,
      isLoading,
    });
  }, [
    isLoggedIn,
    account,
    veryNetworkProvider,
    gameType,
    userTicketCount,
    userBalance,
    userAdBalance,
    adTokenApproval,
    isInitialized,
    isLoading,
  ]);

  // Fetch user ticket count when logged in
  useEffect(() => {
    console.log("🔍 fetchUserTicketCount useEffect triggered:", {
      isLoggedIn,
      account,
      veryNetworkProvider: !!veryNetworkProvider,
      gameType,
    });

    if (isLoggedIn && account && veryNetworkProvider) {
      console.log("✅ All conditions met, calling fetchUserTicketCount");
      const fetchTicketCount = async () => {
        try {
          console.log("�� fetchTicketCount - Starting...");
          console.log("📋 Parameters:", {
            gameType,
            account,
            providerType: veryNetworkProvider.constructor.name,
          });

          const ticketCount = await fetchUserTicketCount(
            gameType,
            account,
            veryNetworkProvider
          );
          console.log("🎫 Ticket count fetched successfully:", ticketCount);
          setUserTicketCount(ticketCount);
        } catch (e) {
          console.error("❌ Failed to fetch ticket count:", e);
          console.error("Error details:", {
            message: e instanceof Error ? e.message : String(e),
            stack: e instanceof Error ? e.stack : undefined,
          });
        }
      };

      fetchTicketCount();
    } else {
      console.log("❌ Conditions not met for fetchUserTicketCount:", {
        isLoggedIn,
        account: !!account,
        veryNetworkProvider: !!veryNetworkProvider,
        missingConditions: {
          isLoggedIn: !isLoggedIn ? "MISSING" : "OK",
          account: !account ? "MISSING" : "OK",
          veryNetworkProvider: !veryNetworkProvider ? "MISSING" : "OK",
        },
      });
    }
  }, [isLoggedIn, account, gameType, veryNetworkProvider]);

  // Fetch referral stats when logged in (only when user data changes)
  useEffect(() => {
    if (isLoggedIn && account && veryNetworkProvider) {
      const fetchReferralData = async () => {
        try {
          const referralStats = await fetchReferralStats(
            account,
            veryNetworkProvider
          );
          setTotalReferrals(referralStats.totalReferrals);
          setTotalEarnings(referralStats.totalRewards);
        } catch (e) {
          console.error("Failed to fetch referral stats:", e);
        }
      };

      fetchReferralData();
    }
  }, [isLoggedIn, account, veryNetworkProvider]); // Removed gameType to prevent loops

  // Fetch dynamic game config and remaining time when provider is available
  useEffect(() => {
    if (!veryNetworkProvider) return;

    const fetchGameData = async () => {
      try {
        // Fetch dynamic game config
        console.log("Fetching dynamic game config for:", gameType);
        const dynamicConfig = await createDynamicGameConfig(
          gameType,
          veryNetworkProvider
        );
        setGameConfig(dynamicConfig);
        console.log("Dynamic game config updated:", dynamicConfig);

        // Fetch remaining time
        console.log("fetchTime - Using existing provider");
        const time = await fetchRemainingTime(gameType, veryNetworkProvider);
        setRemainingTime(time);
      } catch (e) {
        console.warn("Failed to fetch game data:", e);
        // Fallback to static config if dynamic fetch fails
        setGameConfig(GAME_CONFIGS[gameType]);
      }
    };

    // Fetch once immediately
    fetchGameData();
  }, [gameType, veryNetworkProvider]);

  // Continuous countdown timer for remaining time
  useEffect(() => {
    if (!veryNetworkProvider || !isLoggedIn) return;

    // Parse the current remaining time to get seconds
    const parseTimeToSeconds = (timeString: string): number => {
      const parts = timeString.split(":").map(Number);
      if (parts.length === 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      }
      return 0;
    };

    // Convert seconds back to HH:MM:SS format
    const formatSecondsToTime = (seconds: number): string => {
      if (seconds <= 0) return "00:00:00";

      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const secs = seconds % 60;

      return `${hours.toString().padStart(2, "0")}:${minutes
        .toString()
        .padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
    };

    let contractRefreshCounter = 0;

    // Start countdown timer
    const interval = setInterval(async () => {
      try {
        // Only fetch from contract once when logging in, then use local countdown
        if (contractRefreshCounter === 0) {
          console.log("🔄 Fetching initial time from contract...");
          const freshTime = await fetchRemainingTime(
            gameType,
            veryNetworkProvider
          );
          setRemainingTime(freshTime);
          contractRefreshCounter = 1; // Mark as fetched
        } else {
          // Local countdown without contract calls
          setRemainingTime((prevTime) => {
            const currentSeconds = parseTimeToSeconds(prevTime);
            if (currentSeconds > 0) {
              const newSeconds = currentSeconds - 1;
              return formatSecondsToTime(newSeconds);
            }
            return prevTime;
          });
        }
      } catch (error) {
        console.warn("Failed to fetch initial remaining time:", error);
        // Continue with local countdown even if initial contract call fails
        setRemainingTime((prevTime) => {
          const currentSeconds = parseTimeToSeconds(prevTime);
          if (currentSeconds > 0) {
            const newSeconds = currentSeconds - 1;
            return formatSecondsToTime(newSeconds);
          }
          return prevTime;
        });
      }
    }, 1000); // Update every second

    return () => clearInterval(interval);
  }, [veryNetworkProvider, isLoggedIn, gameType]); // Removed remainingTime dependency

  // Handle ticket purchase using the service (for the existing button)
  const handlePurchase = async () => {
    setIsProcessingPurchase(true);

    try {
      console.log("🎯 handlePurchase - Using referral ID:", referralId);
      const result = await TicketPurchaseService.purchaseTicket({
        gameType,
        isLoggedIn,
        account,
        wepin,
        veryNetworkProvider,
        contractInfo,
        ticketCount: 1,
        referrer: referralId,
      });

      if (result.success) {
        // Show success message
        alert(`티켓 구매 성공! 트랜잭션 ID: ${result.transactionId}`);

        // Refresh all contract data after successful purchase
        await refreshAllContractData();
      } else {
        // Show error message
        alert(`티켓 구매 실패: ${result.error}`);
      }
    } catch (error) {
      console.error("Unexpected error in handlePurchase:", error);
      alert("티켓 구매 중 예상치 못한 오류가 발생했습니다.");
    } finally {
      setIsProcessingPurchase(false);
    }
  };

  // Check if AD token approval is needed
  const needsAdTokenApproval = (): boolean => {
    if (gameType !== "ads-lucky") return false;
    return adTokenApproval < 1; // Need at least 1 AD token approved to buy 1 ticket
  };

  // Handle AD token approval
  const handleAdTokenApproval = async () => {
    if (!account || !veryNetworkProvider) {
      throw new Error("User account or provider not available");
    }

    try {
      console.log("🔐 Approving AD tokens for Ad Lottery...");
      
      // Approve 100 AD tokens (enough for 100 tickets)
      const result = await approveAdTokens(account, veryNetworkProvider, 100);
      
      console.log("✅ AD token approval successful:", result);
      
      // Refresh approval status
      const newApproval = await getAdTokenApproval(account, veryNetworkProvider);
      setAdTokenApproval(newApproval);
      
      return {
        success: true,
        transactionId: result.txId,
        message: "AD 토큰 승인이 완료되었습니다!"
      };
    } catch (error) {
      console.error("❌ AD token approval failed:", error);
      throw error;
    }
  };

  // Handle Ad Lottery ticket purchase
  const handleAdTicketPurchase = async (quantity: number) => {
    if (!account || !veryNetworkProvider) {
      throw new Error("User account or provider not available");
    }

    try {
      console.log(`🎫 Purchasing ${quantity} Ad Lottery tickets...`);
      
      // Call buyAdTicket function from contracts.ts
      const result = await buyAdTicket(account, veryNetworkProvider, quantity);
      
      console.log("✅ Ad Lottery ticket purchase successful:", result);
      
      // Refresh all contract data after successful purchase
      await refreshAllContractData();
      
      return {
        success: true,
        transactionId: result.txId,
        message: `Ad Lottery 티켓 구매 성공! ${quantity}장 구매 완료.`
      };
    } catch (error) {
      console.error("❌ Ad Lottery ticket purchase failed:", error);
      throw error;
    }
  };

  // Handle popup ticket purchase
  const handlePopupPurchase = async (ticketId: string, quantity: number) => {
    try {
      console.log(`Popup: Purchasing ${quantity} tickets for ${ticketId}`);

      // Check if this is Ad Lottery and use the appropriate purchase method
      if (gameType === "ads-lucky") {
        const result = await handleAdTicketPurchase(quantity);
        
        // Close popup
        closePurchasePopup();

        // Show success message
        alert(result.message + ` 트랜잭션 ID: ${result.transactionId}`);
        return;
      }

      // Use the enhanced TicketPurchaseService with quantity and referrer for other games
      const result = await TicketPurchaseService.purchaseTicket({
        gameType,
        isLoggedIn,
        account,
        wepin,
        veryNetworkProvider,
        contractInfo,
        ticketCount: quantity,
        referrer: referralId,
      });

      if (result.success) {
        console.log("Popup purchase successful!", result);

        // Close popup
        closePurchasePopup();

        // Refresh all contract data after successful purchase
        await refreshAllContractData();

        // Show success message
        alert(
          `티켓 구매 성공! ${quantity}장 구매 완료. 트랜잭션 ID: ${result.transactionId}`
        );
      } else {
        throw new Error(result.error || "구매에 실패했습니다.");
      }
    } catch (error) {
      console.error("Popup purchase failed:", error);
      throw error; // Let the popup handle the error display
    }
  };

  // Function to refresh all contract data after successful purchase
  const refreshAllContractData = async () => {
    if (!isLoggedIn || !account || !veryNetworkProvider) {
      console.warn("Cannot refresh contract data: missing login state or provider");
      return;
    }

    try {
      console.log("🔄 Starting contract data refresh after purchase...");
      
      // Refresh ticket count
      console.log("🎫 Refreshing ticket count...");
      const newTicketCount = await fetchUserTicketCount(
        gameType,
        account,
        veryNetworkProvider
      );
      setUserTicketCount(newTicketCount);
      console.log("✅ Ticket count refreshed:", newTicketCount);

      // Refresh jackpot
      console.log("💰 Refreshing jackpot...");
      const newJackpot = await fetchJackpot(gameType, veryNetworkProvider);
      setJackpot(newJackpot);
      console.log("✅ Jackpot refreshed:", newJackpot);

      // Refresh remaining time
      console.log("⏰ Refreshing remaining time...");
      const newRemainingTime = await fetchRemainingTime(gameType, veryNetworkProvider);
      setRemainingTime(newRemainingTime);
      console.log("✅ Remaining time refreshed:", newRemainingTime);

      // Refresh user balance
      console.log("💎 Refreshing user balance...");
      if (gameType === "ads-lucky") {
        // For ADS LUCKY, fetch AD token balance
        const newAdBalance = await fetchAdTokenBalance(account, veryNetworkProvider);
        setUserAdBalance(newAdBalance);
        setUserBalance(0); // ETH balance is 0 for AD lottery
        console.log("✅ AD token balance refreshed:", newAdBalance);
      } else {
        // For other games, fetch ETH balance
        const newEthBalance = await fetchUserBalance(account, veryNetworkProvider);
        setUserBalance(newEthBalance);
        setUserAdBalance(0); // AD balance is 0 for other games
        console.log("✅ ETH balance refreshed:", newEthBalance);
      }

      // Refresh referral stats
      console.log("👥 Refreshing referral stats...");
      const referralStats = await fetchReferralStats(account, veryNetworkProvider);
      setTotalReferrals(referralStats.totalReferrals);
      setTotalEarnings(referralStats.totalRewards);
      console.log("✅ Referral stats refreshed:", referralStats);

      console.log("🎉 All contract data refreshed successfully after purchase!");
    } catch (error) {
      console.error("❌ Failed to refresh contract data after purchase:", error);
    }
  };

  return (
    <div className="bg-[#171b25] grid justify-items-center [align-items:start] w-screen min-h-screen">
      <div className="bg-[#171b25] w-[393px] min-h-screen relative">
        {/* Top Header Bar */}
        <div className="w-full h-16 bg-[#171b25] flex items-center justify-between px-4">
          {/* Left: Back Arrow */}
          <button
            onClick={() => {
              // Navigate directly to home instead of using history.back()
              window.history.pushState({}, "", "/");
              window.dispatchEvent(
                new CustomEvent("navigation", { detail: { path: "/" } })
              );
            }}
            className="text-white hover:text-gray-300 transition-colors"
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M15 18L9 12L15 6"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>

          {/* Center: Title */}
          <div className="flex items-center gap-2">
            <span className="text-white font-semibold text-lg">
              {gameType === "daily-lucky" && "Daily_LUCKY"}
              {gameType === "weekly-jackpot" && "Weekly_JACKPOT"}
              {gameType === "ads-lucky" && "ADS_LUCKY"}
            </span>
            <span className="text-gray-400 text-sm">3</span>
          </div>

          {/* Right: Icons */}
          <div className="flex items-center gap-4">
            {/* Notification Bell */}
            <div className="relative">
              <button
                onClick={() => setIsNotificationPopupOpen(true)}
                className="text-white hover:text-gray-300 transition-colors w-6 h-6 flex items-center justify-center"
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                  className="text-white"
                >
                  <path
                    d="M18 8A6 6 0 0 0 6 8C6 15 3 17 3 17H21C21 17 18 15 18 8Z"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <path
                    d="M13.73 21A2 2 0 0 1 10.27 21"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
            </div>

            {/* Info Icon */}
            <button
              onClick={() => setIsInfoPopupOpen(true)}
              className="text-white hover:text-gray-300 transition-colors w-6 h-6 flex items-center justify-center"
            >
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="text-white"
              >
                <circle
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="2"
                />
                <path
                  d="M12 16V12"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
                <path
                  d="M12 8H12.01"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </button>
          </div>
        </div>

        {/* Top Section - Login/Referral/User Profile */}
        <div className="w-[361px] ml-6 mt-5">
          {/* WEPIN Login Section (only before login) */}
          {!isLoggedIn && (
            <div className="w-full h-[80px] mb-5">
              <LoginCard
                isLoading={isLoading}
                isInitialized={isInitialized}
                onLogin={handleLogin}
              />
            </div>
          )}

          {/* Referral (Invite Friends) - only after login, replaces login position */}
          {isLoggedIn && (
            <div className="w-full h-[120px] mb-5">
              <ReferralCard
                totalReferrals={totalReferrals}
                totalEarnings={totalEarnings}
                onInvite={handleInviteShare}
              />
            </div>
          )}

          {/* Logged-in user box with logout (below referral) */}
          {isLoggedIn && (
            <div className="w-full h-[80px] mb-5">
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
        </div>

        {/* Game Section */}
        <div className="w-[361px] ml-6 mt-5">
          {/* Jackpot card */}
          <Card className="w-full h-[218px] mb-5 bg-[#00000033] rounded-[7px] border border-solid border-[#0088ff]">
            <CardContent className="relative w-full h-full p-0">
              <img
                className="absolute w-[118px] h-[108px] top-2 left-[139px]"
                alt="Game icon"
                src={gameConfig.image}
              />
              <div className="absolute w-[257px] h-[58px] top-[108px] left-[54px] text-white text-[32px] text-center">
                <div className="leading-[48px]">1회차 남은 시간</div>
                <div className="text-[56px] leading-[48px]">
                  {remainingTime}
                </div>
              </div>
              <div
                className="absolute w-[295px] h-7 top-[52px] left-[25px] text-[39px] text-center"
                style={{ color: gameConfig.color }}
              >
                {jackpot.replace(/\B(?=(\d{3})+(?!\d))/g, ",")} VERY
              </div>
            </CardContent>
          </Card>

          {/* Stats Card */}
          <Card className="w-full h-14 mb-5 bg-[#333941] rounded-xl overflow-hidden border-0">
            <CardContent className="w-full h-full flex items-center justify-center p-0">
              <div className="text-white text-[14px] text-center">
                누적 30,000 VERY
              </div>
            </CardContent>
          </Card>

          {/* Info + Buy */}
          <div className="w-full mb-5">
            {/* My Tickets Card */}
            <div className="w-full mb-5">
              <MyTicketsCard
                ticketCount={userTicketCount}
                gameType={gameType}
                maxTicketsPerPlayer={gameConfig.maxTicketsPerPlayer}
                userAccount={account}
                provider={veryNetworkProvider}
                onTokenCountUpdate={async (newCount) => {
                  // Fetch the real AD token balance from the blockchain when AD tokens are earned
                  if (gameType === "ads-lucky" && account && veryNetworkProvider) {
                    try {
                      console.log("🔄 Fetching updated AD token balance from blockchain...");
                      const realAdBalance = await fetchAdTokenBalance(account, veryNetworkProvider);
                      setUserAdBalance(realAdBalance);
                      console.log("✅ AD token balance updated from blockchain:", realAdBalance);
                    } catch (error) {
                      console.error("❌ Failed to fetch AD token balance:", error);
                      // Fallback to the passed count if blockchain fetch fails
                      setUserAdBalance(newCount);
                    }
                  }
                }}
              />
            </div>

            <Button
              className="w-full h-16 rounded-[12px] hover:opacity-90 flex items-center justify-center text-white text-2xl"
              style={{
                backgroundColor: isCheckingLogin
                  ? "#666"
                  : isLoggedIn
                  ? gameConfig.color
                  : "#ff6c74",
              }}
              disabled={isCheckingLogin || isProcessingPurchase}
              onClick={async () => {
                if (!isLoggedIn && !isCheckingLogin) {
                  // Redirect to home for login
                  window.history.pushState({}, "", "/");
                  window.dispatchEvent(
                    new CustomEvent("navigation", { detail: { path: "/" } })
                  );
                } else if (isLoggedIn) {
                  // For Ad Lottery, check if approval is needed first
                  if (gameType === "ads-lucky") {
                    setIsProcessingPurchase(true);
                    try {
                      if (needsAdTokenApproval()) {
                        // Need to approve AD tokens first
                        const result = await handleAdTokenApproval();
                        alert(result.message + ` 트랜잭션 ID: ${result.transactionId}`);
                      } else {
                        // Already approved, can buy tickets
                        const result = await handleAdTicketPurchase(1);
                        alert(result.message + ` 트랜잭션 ID: ${result.transactionId}`);
                      }
                    } catch (error) {
                      console.error("Ad Lottery operation failed:", error);
                      const operation = needsAdTokenApproval() ? "승인" : "구매";
                      alert(`Ad Lottery ${operation}에 실패했습니다: ` + (error instanceof Error ? error.message : String(error)));
                    } finally {
                      setIsProcessingPurchase(false);
                    }
                  } else {
                    // For other games, open the ticket purchase popup
                    openPurchasePopup();
                  }
                }
              }}
            >
              {isCheckingLogin
                ? "확인 중..."
                : isProcessingPurchase
                ? "처리 중..."
                : !isLoggedIn
                ? "로그인"
                : gameType === "ads-lucky" && needsAdTokenApproval()
                ? "승인"
                : gameConfig.ticketPrice === "0 VERY"
                ? "무료 티켓 받기"
                : "구매"}
            </Button>
          </div>
        </div>
      </div>

      {/* Ticket Purchase Popup */}
      {selectedTicket && (
        <TicketPurchasePopup
          isOpen={isPurchasePopupOpen}
          onClose={closePurchasePopup}
          onPurchase={handlePopupPurchase}
          ticket={selectedTicket}
          userBalance={gameType === "ads-lucky" ? userAdBalance : userBalance}
        />
      )}

      {/* Notification Popup */}
      <NotificationPopup
        isOpen={isNotificationPopupOpen}
        onClose={() => setIsNotificationPopupOpen(false)}
      />

      {/* Info Popup */}
      <InfoPopup
        isOpen={isInfoPopupOpen}
        onClose={() => setIsInfoPopupOpen(false)}
      />
    </div>
  );
};

export default VeryLucky;
