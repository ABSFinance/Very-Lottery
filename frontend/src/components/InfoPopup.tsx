import React from "react";
import { Card, CardContent } from "./ui/card";

interface InfoPopupProps {
  isOpen: boolean;
  onClose: () => void;
}

export const InfoPopup: React.FC<InfoPopupProps> = ({ isOpen, onClose }) => {
  if (!isOpen) return null;

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

          {/* Header with Info Icon */}
          <div className="text-center pt-6 pb-4">
            <div className="w-16 h-16 mx-auto mb-4 bg-white rounded-full flex items-center justify-center">
              <span className="text-black text-3xl font-bold">!</span>
            </div>
          </div>

          {/* Information Content */}
          <div className="px-6 pb-6 text-white text-sm leading-relaxed">
            <div className="space-y-3">
              <div className="flex items-start">
                <span className="text-white mr-2">*</span>
                <span>1 VERY 로 하루 최대 100개의 티켓을 구매가능</span>
              </div>

              <div className="flex items-start">
                <span className="text-white mr-2">*</span>
                <span>10% 수수료</span>
              </div>

              <div className="pt-2">
                <div className="flex items-start">
                  <span className="text-white mr-2">-</span>
                  <span>
                    비추천으로 접속: 3% 광고복권에 적립, 7% 관리(+3% 레퍼럴
                    포함)
                  </span>
                </div>

                <div className="flex items-start">
                  <span className="text-white mr-2">-</span>
                  <span>
                    추천으로 접속: 3% 레퍼럴, 3% 광고복권에 적립, 4% 관리
                  </span>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
