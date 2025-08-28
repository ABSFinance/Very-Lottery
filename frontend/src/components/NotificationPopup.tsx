import React from "react";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";

interface NotificationPopupProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NotificationPopup: React.FC<NotificationPopupProps> = ({
  isOpen,
  onClose,
}) => {
  if (!isOpen) return null;

  const winningsData = [
    {
      round: "6회차",
      result: "당첨",
      amount: "10,000VERY",
    },
    {
      round: "5회차",
      result: "미당첨",
      amount: "-",
    },
    {
      round: "3회차",
      result: "미당첨",
      amount: "-",
    },
    {
      round: "3회차",
      result: "당첨",
      amount: "10,000VERY",
    },
    {
      round: "2회차",
      result: "미당첨",
      amount: "-",
    },
    {
      round: "2회차",
      result: "미당첨",
      amount: "-",
    },
    {
      round: "1회차",
      result: "당첨",
      amount: "10,000VERY",
    },
  ];

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <Card className="w-[350px] max-h-[600px] bg-[#222222] border-[#444] relative">
        <CardContent className="p-0 relative">
          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 text-white hover:text-gray-300 z-10"
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M18 6L6 18M6 6L18 18"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>

          {/* Header with Icon and Title */}
          <div className="text-center pt-6 pb-4">
            <div className="w-20 h-20 mx-auto mb-3">
              <img
                src="/congrate.png"
                alt="Congratulations"
                className="w-full h-full object-contain"
              />
            </div>
            <h2 className="text-white text-2xl font-bold mb-2">당첨</h2>
            <p className="text-white text-sm mb-1">축하합니다!</p>
            <p className="text-gray-300 text-xs">익일 지급됩니다.</p>
          </div>

          {/* Winnings List */}
          <div className="px-4 pb-4 max-h-[300px] overflow-y-auto">
            {winningsData.map((item, index) => (
              <div
                key={index}
                className="bg-[#333] rounded-lg p-4 mb-3 flex items-center justify-between min-h-[60px]"
              >
                <div className="flex-1">
                  <div className="text-white text-sm font-medium">
                    {item.round}
                  </div>
                </div>
                <div className="flex-1 text-center">
                  <div className="text-white text-sm font-medium">
                    {item.result}
                  </div>
                </div>
                <div className="flex-1 text-right">
                  <div className="text-white text-sm font-semibold">
                    {item.amount}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Footer */}
          <div className="px-4 pb-4 text-center">
            <p className="text-gray-400 text-xs">최근 8건만 기록됩니다.</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
