import { useState, useCallback } from "react";
import { TicketInfo } from "../components/TicketPurchasePopup";

export interface PurchaseResult {
  success: boolean;
  error?: string;
  transactionHash?: string;
}

export const useTicketPurchase = (userBalance: number) => {
  const [isPopupOpen, setIsPopupOpen] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState<TicketInfo | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const openPurchasePopup = useCallback((ticket: TicketInfo) => {
    setSelectedTicket(ticket);
    setIsPopupOpen(true);
  }, []);

  const closePurchasePopup = useCallback(() => {
    setIsPopupOpen(false);
    setSelectedTicket(null);
  }, []);

  const handlePurchase = useCallback(async (
    ticketId: string, 
    quantity: number
  ): Promise<void> => {
    if (!selectedTicket) {
      throw new Error("No ticket selected");
    }

    const totalCost = quantity * selectedTicket.price;
    
    // Validate balance
    if (userBalance < totalCost) {
      throw new Error("잔액이 부족합니다.");
    }

    // Validate quantity
    if (quantity <= 0 || quantity > selectedTicket.maxQuantity) {
      throw new Error("유효하지 않은 수량입니다.");
    }

    setIsLoading(true);

    try {
      // Here you would integrate with your smart contract
      // Example:
      // const result = await purchaseTicket(ticketId, quantity);
      
      // For now, we'll simulate the purchase
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Success - close popup
      closePurchasePopup();
      
    } catch (error: any) {
      // Handle different types of errors
      if (error.message?.includes("네트워크") || error.message?.includes("서버")) {
        throw new Error("일시적인 오류로 결제에 실패했어요. 다시 시도해주세요.");
      } else if (error.message?.includes("가격")) {
        throw new Error("가격이 변경되어 총액을 업데이트했어요.");
      } else {
        throw error;
      }
    } finally {
      setIsLoading(false);
    }
  }, [selectedTicket, userBalance, closePurchasePopup]);

  return {
    isPopupOpen,
    selectedTicket,
    isLoading,
    openPurchasePopup,
    closePurchasePopup,
    handlePurchase,
  };
}; 