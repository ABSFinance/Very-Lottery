import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { GameConfig } from "../utils/contracts";

export interface TicketInfo {
  id: string;
  name: string;
  price: number; // Price in VERY per ticket
  maxQuantity: number;
  deadline: string;
  image?: string;
  gameConfig: GameConfig; // Required game configuration
}

export interface TicketPurchasePopupProps {
  isOpen: boolean;
  onClose: () => void;
  onPurchase: (ticketId: string, quantity: number) => Promise<void>;
  ticket: TicketInfo;
  userBalance: number; // User's VERY balance
}

export const TicketPurchasePopup: React.FC<TicketPurchasePopupProps> = ({
  isOpen,
  onClose,
  onPurchase,
  ticket,
  userBalance,
}) => {
  const [quantity, setQuantity] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showNumberPad, setShowNumberPad] = useState(false);
  const [inputValue, setInputValue] = useState("");

  // Check if this is an ADS LUCKY game
  const isAdsLucky = ticket.id === "ads-lucky";
  
  // Calculate total price based on game config or fallback to ticket.price
  const pricePerTicket = isAdsLucky 
    ? "1 AD" 
    : (ticket.gameConfig?.ticketPrice || `${ticket.price} VERY`);
  const pricePerTicketNumber = isAdsLucky 
    ? 1 
    : (ticket.gameConfig?.ticketPrice
        ? parseFloat(ticket.gameConfig.ticketPrice.replace(/ (AD|VERY)/, ""))
        : ticket.price);
  const totalPrice = quantity * pricePerTicketNumber;
  const canAfford = userBalance >= totalPrice;
  const isValidQuantity = quantity > 0 && quantity <= ticket.maxQuantity;

  // Get the currency symbol for display
  const getCurrencySymbol = () => {
    if (isAdsLucky) return "AD";
    return "VERY";
  };

  // Get the currency name for display
  const getCurrencyName = () => {
    if (isAdsLucky) return "AD 토큰";
    return "VERY";
  };

  useEffect(() => {
    if (isOpen) {
      setQuantity(1);
      setError(null);
      setShowNumberPad(false);
      setInputValue("");
    }
  }, [isOpen]);

  // Add ESC key listener to close popup
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener("keydown", handleEsc);
      return () => document.removeEventListener("keydown", handleEsc);
    }
  }, [isOpen, onClose]);

  const handleQuantityChange = (newQuantity: number) => {
    if (newQuantity >= 1 && newQuantity <= ticket.maxQuantity) {
      setQuantity(newQuantity);
      setError(null);
    }
  };

  const handleQuantityInput = () => {
    setShowNumberPad(true);
    setInputValue(quantity.toString());
  };

  const handleNumberPadInput = (value: string) => {
    setInputValue(value);
  };

  const handleNumberPadConfirm = () => {
    const newQuantity = parseInt(inputValue);
    if (newQuantity >= 1 && newQuantity <= ticket.maxQuantity) {
      setQuantity(newQuantity);
      setError(null);
    } else {
      setError("유효하지 않은 수량입니다.");
    }
    setShowNumberPad(false);
    setInputValue("");
  };

  const handleNumberPadCancel = () => {
    setShowNumberPad(false);
    setInputValue("");
  };

  const handlePurchase = async () => {
    if (!isValidQuantity) {
      setError("유효하지 않은 수량입니다.");
      return;
    }

    if (!canAfford) {
      setError("잔액이 부족합니다.");
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      await onPurchase(ticket.id, quantity);
      onClose();
    } catch (err: any) {
      if (err.message?.includes("네트워크") || err.message?.includes("서버")) {
        setError("일시적인 오류로 결제에 실패했어요. 다시 시도해주세요.");
      } else if (err.message?.includes("가격")) {
        setError("가격이 변경되어 총액을 업데이트했어요.");
      } else {
        setError("구매 중 오류가 발생했습니다. 다시 시도해주세요.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      onClick={(e) => {
        // Close popup when clicking on backdrop
        if (e.target === e.currentTarget) {
          onClose();
        }
      }}
    >
      <Card className="w-full max-w-md bg-[#282828] border-[#444] text-white">
        <CardHeader className="text-center pb-4 relative">
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="absolute top-2 right-2 w-8 h-8 text-gray-400 hover:text-white hover:bg-gray-700"
          >
            ✕
          </Button>
          <CardTitle className="text-xl font-semibold text-white">
            티켓을 구매하시겠습니까?
          </CardTitle>
          <p className="text-gray-300 text-sm">{ticket.name}</p>
        </CardHeader>

        <CardContent className="space-y-6">
          {/* Ticket Image */}
          <div className="flex justify-center">
            <img
              src="/golden-ticket-1.png"
              alt="Golden Ticket"
              className="w-24 h-32 object-contain transform rotate-0"
              style={{ transform: "rotate(-15deg)" }}
            />
          </div>

          {/* Quantity Selector */}
          <div className="flex items-center justify-center space-x-3">
            <Button
              variant="outline"
              size="icon"
              onClick={() => handleQuantityChange(quantity - 1)}
              disabled={quantity <= 1}
              className="w-10 h-10 bg-gray-600 border-gray-500 text-white hover:bg-gray-700"
            >
              -
            </Button>

            <div
              className="w-20 h-10 bg-gray-700 rounded-md flex items-center justify-center cursor-pointer border border-gray-500"
              onClick={handleQuantityInput}
            >
              <span className="text-white font-medium">{quantity} 장</span>
            </div>

            <Button
              variant="outline"
              size="icon"
              onClick={() => handleQuantityChange(quantity + 1)}
              disabled={quantity >= ticket.maxQuantity}
              className="w-10 h-10 bg-gray-600 border-gray-500 text-white hover:bg-gray-700"
            >
              +
            </Button>
          </div>

          {/* Ticket Details */}
          <div className="bg-gray-800 rounded-lg p-4 space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-300">가격:</span>
              <span className="text-white">{pricePerTicket} / 장당</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-300">총 가격:</span>
              <span className="text-white font-semibold">
                {totalPrice} {getCurrencySymbol()}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-300">최대수량:</span>
              <span className="text-white">
                {ticket.gameConfig?.maxTicketsPerPlayer || ticket.maxQuantity}개
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-300">구매기한:</span>
              <span className="text-white">
                {ticket.id === "weekly-jackpot" ? "매주" : "매일"}
              </span>
            </div>
          </div>

          {/* Error Message */}
          {error && (
            <div className="bg-red-900 border border-red-700 rounded-lg p-3">
              <p className="text-red-200 text-sm text-center">{error}</p>
            </div>
          )}

          {/* Purchase Button */}
          <Button
            onClick={handlePurchase}
            disabled={!isValidQuantity || !canAfford || isLoading}
            className="w-full h-12 bg-[#F07878] hover:bg-[#E06868] text-white font-semibold text-lg rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? "처리중..." : `${totalPrice} ${getCurrencySymbol()}로 구매`}
          </Button>

          {/* User Balance */}
          <p className="text-center text-gray-400 text-sm">
            {userBalance.toLocaleString()} {getCurrencyName()} 보유중
          </p>
        </CardContent>
      </Card>

      {/* Number Input Pad */}
      {showNumberPad && (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-60">
          <div className="bg-[#282828] rounded-lg p-6 w-80">
            <h3 className="text-white text-lg font-semibold mb-4 text-center">
              수량 입력
            </h3>

            <input
              type="number"
              value={inputValue}
              onChange={(e) => handleNumberPadInput(e.target.value)}
              className="w-full h-12 bg-gray-700 border border-gray-500 rounded-lg px-4 text-white text-center text-lg mb-4"
              placeholder="수량을 입력하세요"
              min="1"
              max={ticket.maxQuantity}
            />

            <div className="flex space-x-3">
              <Button
                onClick={handleNumberPadCancel}
                variant="outline"
                className="flex-1 bg-gray-600 border-gray-500 text-white hover:bg-gray-700"
              >
                취소
              </Button>
              <Button
                onClick={handleNumberPadConfirm}
                className="flex-1 bg-[#F07878] hover:bg-[#E06868] text-white"
              >
                확인
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TicketPurchasePopup;
