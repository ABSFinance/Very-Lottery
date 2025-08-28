import React from "react";
import { Card, CardContent } from "./ui/card";

export interface PromoCardProps {
  onSelect?: () => void;
  disabled?: boolean;
}

export const PromoAdsCard: React.FC<PromoCardProps> = ({
  onSelect,
  disabled,
}) => {
  const handleClick = () => {
    if (!disabled && onSelect) onSelect();
  };
  return (
    <div
      className={`relative ${disabled ? "opacity-60" : "cursor-pointer"}`}
      onClick={handleClick}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === "Enter") handleClick();
      }}
    >
      <Card className="relative w-[359px] h-[101px] rounded-[7px] bg-[#00000033] border-[#b3b3b3]">
        <CardContent className="p-0 relative h-full">
          <img
            className="absolute w-32 h-[101px] top-0 right-0"
            alt="Tree background"
            src="/f7-1.png"
          />
          <img
            className="absolute w-[22px] h-[22px] top-[35px] left-[160px] object-cover"
            alt="Fruit color"
            src="/fruit-color-1-2.png"
          />
          <div className="absolute h-[41px] top-[30px] left-[29px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-white text-[22px] tracking-[-0.22px] leading-[25px]">
            <span className="text-white tracking-[-0.05px]">
              ADS LUCKY
              <br />
              재미있는 광고보고{" "}
            </span>
            <span className="text-[#ff6c74] tracking-[-0.05px]">VERY</span>
            <span className="text-white tracking-[-0.05px]"> 받자!</span>
          </div>
          <img
            className="absolute w-4 h-4 top-3.5 left-[9px]"
            alt="Symbol"
            src="/symbol-2.svg"
          />
        </CardContent>
      </Card>
    </div>
  );
};

export default PromoAdsCard;
