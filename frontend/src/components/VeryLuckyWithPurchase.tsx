import React, { useState, useEffect } from "react";
import { VeryLucky } from "../screens/Games/VeryLucky";
import { TicketPurchasePopup, TicketInfo } from "./TicketPurchasePopup";
import { TicketPurchaseService } from "../utils/ticketPurchaseService";
import {
  GameType,
  GameConfig,
  GAME_CONFIGS,
  getGameContractInfo,
} from "../utils/contracts";

interface VeryLuckyWithPurchaseProps {
  gameType?: GameType;
  gameConfig: GameConfig; // Required game configuration
  userBalance?: number;
  showPurchaseButton?: boolean; // Whether to show the floating purchase button
  onPurchaseSuccess?: (ticketId: string, quantity: number) => void; // Callback when purchase succeeds
  onPurchaseError?: (error: string) => void; // Callback when purchase fails
}

export const VeryLuckyWithPurchase: React.FC<VeryLuckyWithPurchaseProps> = ({
  gameType = "daily-lucky",
  gameConfig, // Required game configuration
  userBalance = 5000, // Default balance, you can pass this from your app state
  showPurchaseButton = true, // Default to showing the purchase button
  onPurchaseSuccess,
  onPurchaseError,
}) => {
  const [isPopupOpen, setIsPopupOpen] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState<TicketInfo | null>(null);
  const [contractInfo, setContractInfo] = useState<any>(null);

  // Update contract info when gameType changes
  useEffect(() => {
    const contract = getGameContractInfo(gameType);
    setContractInfo(contract);
  }, [gameType]);

  // Define ticket info based on passed game configuration
  const getTicketInfo = (): TicketInfo => {
    // Use the passed gameConfig prop instead of static GAME_CONFIGS

    // Extract price from ticketPrice string (e.g., "1 VERY" -> 1)
    const priceMatch = gameConfig.ticketPrice.match(/(\d+)/);
    const price = priceMatch ? parseInt(priceMatch[1]) : 0;

    return {
      id: gameType,
      name: gameConfig.title,
      price: price,
      maxQuantity: gameConfig.maxTicketsPerPlayer,
      deadline: gameType === "weekly-jackpot" ? "매주" : "매일",
      image: gameConfig.image,
      gameConfig: gameConfig, // Pass the full game configuration
    };
  };

  const handlePurchase = async (ticketId: string, quantity: number) => {
    try {
      console.log(`Purchasing ${quantity} tickets for ${ticketId}`);

      // Use the TicketPurchaseService with the passed gameConfig
      const result = await TicketPurchaseService.purchaseTicket({
        gameType,
        isLoggedIn: true, // You'll need to get this from your app state
        account: "", // You'll need to get this from your app state
        wepin: null, // You'll need to get this from your app state
        veryNetworkProvider: null, // You'll need to get this from your app state
        contractInfo: contractInfo, // Use the contract info from state
        ticketCount: quantity,
        referrer: "0x0000000000000000000000000000000000000000", // Default referrer
      });

      if (result.success) {
        console.log("Purchase successful!", result);

        // Close popup on success
        setIsPopupOpen(false);

        // Call success callback if provided
        if (onPurchaseSuccess) {
          onPurchaseSuccess(ticketId, quantity);
        }
      } else {
        throw new Error(result.error || "구매에 실패했습니다.");
      }

      // You could also refresh the parent component's data here
      // For example, trigger a refresh of ticket counts, etc.
    } catch (error) {
      console.error("Purchase failed:", error);

      // Call error callback if provided
      if (onPurchaseError) {
        onPurchaseError(
          error instanceof Error ? error.message : "Unknown error"
        );
      }

      throw error; // Re-throw to let the popup handle the error
    }
  };

  const openPurchasePopup = () => {
    const ticketInfo = getTicketInfo();
    setSelectedTicket(ticketInfo);
    setIsPopupOpen(true);
  };

  const closePurchasePopup = () => {
    setIsPopupOpen(false);
    setSelectedTicket(null);
  };

  return (
    <>
      {/* Render the original VeryLucky component */}
      <VeryLucky gameType={gameType} />

      {/* Add a floating purchase button - only show when enabled and for paid games */}
      {showPurchaseButton && gameConfig.ticketPrice !== "0 VERY" && (
        <div className="fixed bottom-4 right-4 z-40">
          <button
            onClick={openPurchasePopup}
            className="text-white px-6 py-3 rounded-lg shadow-lg font-semibold transition-all duration-200 transform hover:scale-105 hover:shadow-xl"
            style={{ backgroundColor: gameConfig.color }}
            title={`${gameConfig.title} 티켓 구매`}
          >
            {gameConfig.ticketPrice === "0 VERY"
              ? "무료 티켓 받기"
              : `${gameConfig.ticketPrice}로 구매`}
          </button>
        </div>
      )}

      {/* Ticket Purchase Popup */}
      {selectedTicket && (
        <TicketPurchasePopup
          isOpen={isPopupOpen}
          onClose={closePurchasePopup}
          onPurchase={handlePurchase}
          ticket={selectedTicket}
          userBalance={userBalance}
        />
      )}
    </>
  );
};

export default VeryLuckyWithPurchase;
