import React from "react";
import { Card, CardContent } from "./ui/card";
import { Button } from "./ui/button";

export interface ReferralCardProps {
  totalReferrals: number;
  totalEarnings: number; // VERY 단위
  onInvite: () => void;
}

const formatNumber = (value: number): string => {
  // For very small numbers, use more decimal places
  if (value > 0 && value < 0.01) {
    return value.toFixed(4); // Show exactly 4 decimal places for small values
  } else if (value > 0 && value < 1) {
    return value.toFixed(4); // Show up to 4 decimal places for values less than 1
  } else {
    return new Intl.NumberFormat("ko-KR").format(value);
  }
};

export const ReferralCard: React.FC<ReferralCardProps> = ({
  totalReferrals,
  totalEarnings,
  onInvite,
}) => {
  return (
    <Card className="relative w-[359px] h-[120px] rounded-[7px] bg-[#00000033] border-[#febc2f]">
      <CardContent className="p-0 relative h-full">
        {/* 좌측 텍스트 영역 */}
        <div className="absolute inset-y-0 left-4 right-[120px] text-white flex flex-col justify-center">
          <div className="[font-family:'Pretendard-Bold',Helvetica] text-[22px] leading-[24px] whitespace-nowrap">
            초대한 친구{" "}
            <span className="text-[#ff6d75]">
              {formatNumber(totalReferrals)}
            </span>
            명
          </div>
          <div className="mt-1 text-[20px] leading-[22px] whitespace-nowrap">
            받은 리워드 :{" "}
            <span className="text-[#ff6d75]">
              {formatNumber(totalEarnings)} VERY
            </span>
          </div>

          <div className="mt-2 text-[#8c8c8c] text-xs underline flex items-center gap-2 whitespace-nowrap">
            <img
              src="/exclamation-circle.svg"
              alt="info"
              className="w-[14px] h-[14px]"
            />
            <span>친구가 당첨되면 나도같이 VERY를 받아요!</span>
          </div>
        </div>

        {/* 우측 고정 컬럼: 이미지(상단) + 버튼(하단) */}
        <div className="absolute inset-y-0 right-0 w-[132px]">
          <img
            className="absolute top-2 right-3 w-[96px] h-[80px]"
            alt="Love letter"
            src="/love-letter-1.png"
          />
          <div className="absolute bottom-2 right-3">
            <Button
              onClick={onInvite}
              className="inline-flex items-center justify-center px-5 h-[40px] rounded-xl overflow-hidden bg-[linear-gradient(90deg,rgba(255,109,117,1)_0%,rgba(156,134,255,1)_100%)] text-white text-[15px] shadow"
            >
              친구초대
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default ReferralCard;
