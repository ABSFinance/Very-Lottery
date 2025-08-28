import React from "react";
import { Card, CardContent } from "./ui/card";

export interface TotalEarningCardProps {
  amount: number; // VERY 단위
}

const formatNumber = (value: number): string =>
  new Intl.NumberFormat("ko-KR").format(value);

export const TotalEarningCard: React.FC<TotalEarningCardProps> = ({
  amount,
}) => {
  return (
    <Card className="relative w-[359px] h-full rounded-[7px] bg-[#00000033] border-transparent">
      <CardContent className="p-0 relative h-full flex flex-col items-center justify-center">
        <div className="flex justify-center w-full">
          <img
            className="w-[120px] h-[120px] -mb-9 ml-2"
            alt="Fruit color"
            src="/fruit-color-1-3.png"
          />
        </div>
        <div className="[font-family:'Pretendard-Bold'  zHelvetica] text-white text-[24px] leading-[24px]">
          최대 당첨금
        </div>
        <div className="[font-family:'Pretendard-Bold',Helvetica] text-[#ff6d75] text-[26px] leading-[28px] mt-1 whitespace-nowrap">
          {formatNumber(amount)} VERY
        </div>
      </CardContent>
    </Card>
  );
};

export default TotalEarningCard;
