import React from "react";
import { Card, CardContent } from "./ui/card";

export interface PromoCardProps {
  onSelect?: () => void;
  disabled?: boolean;
}

export const PromoDropCard: React.FC<PromoCardProps> = ({
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
      <Card className="relative w-[359px] h-[101px] bg-[#00000033] border-[#aaaaaa] rounded-[7px]">
        <CardContent className="p-0 relative h-full">
          <div className="w-[359px] h-[101px] absolute left-0" />

          <img
            className="w-[23px] h-[23px] top-[45px] left-[312px] absolute object-cover"
            alt="Fruit color"
            src="/fruit-color-1-2.png"
          />
          <img
            className="w-[23px] h-[23px] top-[55px] left-[270px] absolute object-cover"
            alt="Fruit color"
            src="/fruit-color-1-2.png"
          />
          <img
            className="absolute w-[76px] h-[76px] top-0 left-[281px] object-cover"
            alt="Fruit color"
            src="/fruit-color-1-2.png"
          />
          <div className="absolute h-[41px] top-[30px] left-[29px] [font-family:'Pretendard-Regular',Helvetica] font-normal text-transparent text-[22px] tracking-[-0.22px] leading-[25px]">
            <span className="text-white tracking-[-0.05px]">
              Weekly JACKPOT
              <br />
              이번주, 단 1명의 잭팟 주인공
            </span>
          </div>
          <img
            className="absolute w-4 h-4 top-3.5 left-[9px]"
            alt="Symbol"
            src="/symbol.svg"
          />
          <img
            className="h-[22px] top-[39px] left-[242px] absolute w-[22px]"
            alt="Chatgpt image"
            src="/chatgpt-image-2025----7----3---------11-38-00-5.png"
          />
        </CardContent>
      </Card>
    </div>
  );
};

export default PromoDropCard;
