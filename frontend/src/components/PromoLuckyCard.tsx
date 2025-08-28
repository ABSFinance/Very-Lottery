import React from "react";
import { Card, CardContent } from "./ui/card";

export interface PromoCardProps {
  onSelect?: () => void;
  disabled?: boolean;
}

export const PromoLuckyCard: React.FC<PromoCardProps> = ({
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
      <Card className="relative w-[359px] h-[101px] rounded-[7px] bg-[#00000033] border-[#999999]">
        <CardContent className="p-0 relative h-full">
          <img
            className="absolute w-32 h-[101px] top-0 left-[230px]"
            alt="Background"
            src="/f7.png"
          />
          <img
            className="w-7 h-7 top-[29px] left-[219px] absolute object-cover"
            alt="Fruit color"
            src="/fruit-color-1-2.png"
          />
          <img
            className="w-7 h-7 top-[29px] left-[233px] absolute object-cover"
            alt="Fruit color"
            src="/fruit-color-1-2.png"
          />
          <div className="absolute h-[41px] top-[30px] left-[29px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-transparent text-[22px] tracking-[-0.22px] leading-[25px]">
            <span className="text-white tracking-[-0.05px]">
              Daily LUCKY
              <br />
              매일 응모하고{" "}
            </span>
            <span className="text-[#ff6c74] tracking-[-0.05px]">
              10,000 VERY
            </span>
            <span className="text-white tracking-[-0.05px]"> 받자!</span>
          </div>
          <img
            className="absolute w-4 h-4 top-3.5 left-[9px]"
            alt="Symbol"
            src="/symbol.svg"
          />
        </CardContent>
      </Card>
    </div>
  );
};

export default PromoLuckyCard;
