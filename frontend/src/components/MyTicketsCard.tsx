import React, { useState } from "react";
import { Card, CardContent } from "./ui/card";

export interface MyTicketsCardProps {
  ticketCount: number;
  gameType: "daily-lucky" | "weekly-jackpot" | "ads-lucky";
  maxTicketsPerPlayer?: number;
  className?: string;
}

export const MyTicketsCard: React.FC<MyTicketsCardProps> = ({
  ticketCount,
  gameType,
  maxTicketsPerPlayer = 100,
  className = "",
}) => {
  const [isVideoOpen, setIsVideoOpen] = useState(false);
  const [tokenCount, setTokenCount] = useState(0); // Default token count starts at 0

  const getGameTypeText = (type: string) => {
    switch (type) {
      case "daily-lucky":
        return "Daily LUCKY";
      case "weekly-jackpot":
        return "Weekly LUCKY";
      case "ads-lucky":
        return "Ads LUCKY";
      default:
        return "LUCKY";
    }
  };

  const getRules = (type: string) => {
    switch (type) {
      case "daily-lucky":
        return [
          `1 VERY로 이 최대 ${maxTicketsPerPlayer}개의 티켓을 구매가능`,
          "하루마다 당첨자 발표 및 전송 및 리셋",
          "10% 수수료",
        ];
      case "weekly-jackpot":
        return [
          `100 VERY로 주간 최대 ${maxTicketsPerPlayer}개의 티켓을 구매가능`,
          "일주일마다 당첨자 발표 및 전송 및 리셋",
          "10% 수수료",
        ];
      case "ads-lucky":
        return [
          "1 광고로 하루 최대 10 AD토큰 발행 가능",
          "1 AD토큰으로 1개의 티켓을 구매가능",
          `1 AD로 하루 최대 ${maxTicketsPerPlayer}개의 티켓을 구매가능`,
          "하루마다 당첨자 발표 및 전송 및 리셋",
          "10% 수수료",
        ];
      default:
        return [
          `1 VERY로 하루 최대 ${maxTicketsPerPlayer}개의 티켓을 구매가능`,
          "당첨자 발표 및 전송",
          "당첨시, 10% 수수료",
        ];
    }
  };

  const handleVideoOpen = () => {
    setIsVideoOpen(true);
  };

  const handleVideoClose = () => {
    setIsVideoOpen(false);
    // Increase token count by 1 when video is closed (after watching ad)
    setTokenCount(prev => prev + 1);
  };

  return (
    <div className={`space-y-3 ${className}`}>
      {/* Main Ticket Count Card */}
      <Card className="relative w-[358px] h-16 bg-[#00000033] rounded-[7px] border border-solid border-[#8B5CF6]">
        <CardContent className="p-0 relative h-full flex items-center">
          {/* Ticket Icon - Use actual image */}
          <div className="flex-shrink-0 ml-[17px]">
            <img
              className="w-[49px] h-[49px] object-cover"
              alt="Golden ticket"
              src="/golden-ticket-1.png"
              style={{ transform: "rotate(-15deg)" }}
            />
          </div>

          {/* Text Content - Single line */}
          <div className="flex-1 ml-4">
            <div className="text-lg text-center whitespace-nowrap">
              <span className="text-purple-300">
                내가 구매한 티켓 수: {ticketCount} 장
              </span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Token Exchange Section - Only for ADS LUCKY */}
      {gameType === "ads-lucky" && (
        <Card className="relative w-[358px] h-24 bg-[#28282D] rounded-[7px] border-0">
          <CardContent className="p-4 relative h-full">
            {/* Token Count Header */}
            <div className="flex items-center mb-3">
              <img
                className="w-6 h-6 mr-2"
                alt="Token symbol"
                src="/symbol-2.svg"
              />
              <span className="text-[#F08080] text-sm font-medium">
                나의 토큰 수: {tokenCount} 개
              </span>
            </div>

            {/* Exchange Button */}
            <button 
              onClick={handleVideoOpen}
              className="w-full h-10 bg-[#F0D050] text-[#28282D] font-semibold rounded-lg hover:bg-[#E8C840] transition-colors"
            >
              광고보기
            </button>
          </CardContent>
        </Card>
      )}

      {/* Rules Section */}
      <div className="w-[345px] text-[#ffffff87] text-sm space-y-1 mt-6">
        <div className="space-y-2">
          {getRules(gameType).map((rule, index) => (
            <div
              key={index}
              className="text-[#ffffff87] text-sm leading-relaxed"
            >
              * {rule}
            </div>
          ))}
        </div>
      </div>

      {/* Video Modal - Fullscreen */}
      {isVideoOpen && (
        <div className="fixed inset-0 z-50 bg-black flex items-center justify-center">
          {/* Close Button */}
          <button
            onClick={handleVideoClose}
            className="absolute top-4 right-4 z-10 bg-white bg-opacity-20 hover:bg-opacity-30 text-white rounded-full w-10 h-10 flex items-center justify-center transition-all"
          >
            <svg
              width="24"
              height="24"
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

          {/* Video Player */}
          <div className="w-full h-full flex items-center justify-center">
            <video
              className="w-full h-full object-contain"
              controls
              autoPlay
              onEnded={handleVideoClose}
            >
              <source src="/verylucky_ads.mp4" type="video/mp4" />
              Your browser does not support the video tag.
            </video>
          </div>
        </div>
      )}
    </div>
  );
};

export default MyTicketsCard;
