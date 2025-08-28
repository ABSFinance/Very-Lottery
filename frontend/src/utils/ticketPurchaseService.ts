import {
  sendTransactionWithWepin,
  GameType,
} from "./contracts";
import {
  getLastWepinInstances,
  getAccounts,
  areWepinInstancesAvailable,
  forceWepinInitialization,
} from "./wepin";

/**
 * Parameters for purchasing tickets
 */
export interface PurchaseTicketParams {
  /** The type of game (e.g., "daily-lucky", "weekly-jackpot") */
  gameType: GameType;
  /** Whether the user is currently logged in */
  isLoggedIn: boolean;
  /** User's wallet address */
  account: string;
  /** Wepin instances (can be null, will fallback to global instances) */
  wepin: any | null;
  /** Very network provider for blockchain transactions */
  veryNetworkProvider: any;
  /** Contract information including ABI and address */
  contractInfo: any;
  /** Number of tickets to purchase (must be > 0) */
  ticketCount: number;
  /** Optional referrer address (defaults to zero address if not provided) */
  referrer?: string;
}

/**
 * Result of a ticket purchase operation
 */
export interface PurchaseTicketResult {
  /** Whether the purchase was successful */
  success: boolean;
  /** Number of tickets purchased */
  ticketCount?: number;
  /** The referrer address used in the transaction */
  referrer?: string;
  /** Error message if purchase failed */
  error?: string;
  /** Transaction ID from the blockchain */
  transactionId?: string;
}

export class TicketPurchaseService {
  private static forceInitAttempted = false;

  /**
   * Purchase a ticket for the specified game type
   */
  static async purchaseTicket(params: PurchaseTicketParams): Promise<PurchaseTicketResult> {
    const { gameType, isLoggedIn, account, wepin, veryNetworkProvider, contractInfo, ticketCount, referrer } = params;

    try {
      // Validate basic requirements
      if (!isLoggedIn) {
        throw new Error("로그인이 필요합니다. 홈으로 돌아가서 로그인해주세요.");
      }

      if (contractInfo.address === "0x0000000000000000000000000000000000000000") {
        throw new Error("컨트랙트 주소가 설정되지 않았습니다.");
      }

      // Validate ticket count
      if (ticketCount <= 0) {
        throw new Error("티켓 수량은 1개 이상이어야 합니다.");
      }

      // You can add more validation here based on your game rules
      // For example, check against maxTicketsPerDay, user balance, etc.

      // Get Wepin instances with fallback
      let wepinInstances = wepin;
      if (!wepinInstances) {
        wepinInstances = getLastWepinInstances();
      }

      // If still no wepin instances, throw error
      if (!wepinInstances) {
        throw new Error("Wepin 인스턴스를 찾을 수 없습니다. 다시 로그인해주세요.");
      }

      // Check if Wepin instances are available
      if (!areWepinInstancesAvailable()) {
        if (this.forceInitAttempted) {
          throw new Error("Wepin이 초기화되지 않았습니다. 페이지를 새로고침하거나 다시 시도해주세요.");
        }

        console.log("No Wepin instances available, attempting force initialization once...");
        this.forceInitAttempted = true;
        
        const forceInitSuccess = await forceWepinInitialization();
        if (!forceInitSuccess) {
          throw new Error("Wepin이 초기화되지 않았습니다. 페이지를 새로고침하거나 다시 시도해주세요.");
        }
      }

      // Validate Wepin instances
      if (!wepinInstances?.sdk || !wepinInstances?.provider) {
        throw new Error("Wepin 인스턴스가 사용할 수 없습니다.");
      }

      // Verify login state with Wepin SDK
      const accounts = await this.getWepinAccounts(wepinInstances.sdk);
      
      if (!accounts || accounts.length === 0) {
        throw new Error("Wepin 계정을 찾을 수 없습니다. 다시 로그인해주세요.");
      }

      const userAccount = accounts[0];
      console.log("Using account:", userAccount);

      // Prepare transaction parameters
      const finalReferrer = referrer || "0x0000000000000000000000000000000000000000"; // Use provided referrer or default

      console.log("Preparing to send transaction:", {
        account: userAccount,
        gameType,
        ticketCount,
        referrer: finalReferrer,
      });

      // Send transaction using the provider
      if (!veryNetworkProvider) {
        throw new Error("Very network provider not available for transaction");
      }

      const result = await sendTransactionWithWepin(
        userAccount,
        gameType,
        veryNetworkProvider,
        ticketCount,
        finalReferrer
      );

      console.log("Transaction sent successfully:", result);

      return {
        success: true,
        ticketCount,
        referrer: finalReferrer,
        transactionId: result.txId,
      };

    } catch (error) {
      console.error("Error purchasing ticket:", error);
      
      const errorMessage = this.getErrorMessage(error);
      
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  /**
   * Get Wepin accounts with retry mechanism
   */
  private static async getWepinAccounts(sdk: any): Promise<any[]> {
    let retryCount = 0;
    const maxRetries = 2;

    while (retryCount < maxRetries) {
      try {
        console.log(`Attempt ${retryCount + 1}: Getting Wepin accounts...`);

        if (!sdk) {
          throw new Error("Wepin SDK not available");
        }

        console.log(`Attempt ${retryCount + 1}: Calling getAccounts with:`, {
          sdk,
          sdkType: typeof sdk,
          hasGetAccounts: typeof sdk.getAccounts === "function",
          sdkMethods: Object.getOwnPropertyNames(sdk),
          options: { withEoa: true },
        });

        // Try first without networks parameter
        let accounts;
        try {
          accounts = await getAccounts(sdk, { withEoa: true });
          console.log("Successfully got accounts without networks parameter");
        } catch (noNetworksError) {
          console.log("Failed without networks parameter, trying with networks...");
          accounts = await getAccounts(sdk, { networks: ["Ethereum"], withEoa: true });
          console.log("Successfully got accounts with networks parameter");
        }

        console.log(`Attempt ${retryCount + 1} successful - Wepin accounts:`, accounts);

        // Validate that we got valid accounts
        if (accounts && Array.isArray(accounts) && accounts.length > 0) {
          console.log("Accounts validation passed");
          return accounts;
        } else {
          console.warn("Accounts validation failed - accounts:", accounts);
          throw new Error("Invalid accounts returned from Wepin");
        }

      } catch (error) {
        retryCount++;
        console.error(`Failed to get Wepin accounts (attempt ${retryCount}):`, error);

        if (retryCount < maxRetries) {
          // Wait a bit before retrying
          await new Promise((resolve) => setTimeout(resolve, 1000));
        } else {
          throw new Error("Wepin 로그인 상태를 확인할 수 없습니다. 다시 로그인해주세요.");
        }
      }
    }

    throw new Error("Failed to get Wepin accounts after all retries");
  }

  /**
   * Get user-friendly error message from error object
   */
  private static getErrorMessage(error: any): string {
    if (error instanceof Error) {
      const message = error.message;
      
      if (message.includes("Only if you're logged in to the wepin")) {
        return "Wepin 로그인이 필요합니다. 홈으로 돌아가서 다시 로그인해주세요.";
      } else if (message.includes("fail/requireFee")) {
        return "수수료 요구사항을 충족하지 못했습니다. 티켓 가격을 확인해주세요.";
      } else if (message.includes("Wepin")) {
        return message;
      } else {
        return message;
      }
    }
    
    return "알 수 없는 오류가 발생했습니다.";
  }

  /**
   * Reset force initialization flag (useful for testing or when user manually refreshes)
   */
  static resetForceInitFlag(): void {
    this.forceInitAttempted = false;
  }
} 