import React from "react";
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
          `1 AD로 하루 최대 ${maxTicketsPerPlayer}개의 티켓을 구매가능`,
          "광고 시청 후 당첨자 발표 및 전송",
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
                나의 토큰 수: 25 개
              </span>
            </div>

            {/* Exchange Button */}
            <button className="w-full h-10 bg-[#F0D050] text-[#28282D] font-semibold rounded-lg hover:bg-[#E8C840] transition-colors">
              티켓으로 교환
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
    </div>
  );
};

export default MyTicketsCard;
