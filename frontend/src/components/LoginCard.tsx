import React from "react";
import { Card, CardContent } from "./ui/card";
import { Button } from "./ui/button";

export interface LoginCardProps {
  isLoading: boolean;
  isInitialized: boolean;
  onLogin: () => void;
}

export const LoginCard: React.FC<LoginCardProps> = ({
  isLoading,
  isInitialized,
  onLogin,
}) => {
  return (
    <Card className="relative w-[359px] h-[80px] rounded-[7px] bg-[#00000033] border-[#ff6c74]">
      <CardContent className="p-0 relative h-full">
        <div className="absolute h-[60px] top-[10px] left-[16px] flex items-center gap-3">
          <Button
            onClick={onLogin}
            disabled={isLoading || !isInitialized}
            className={`px-4 py-2 text-sm rounded-lg ${
              isLoading || !isInitialized
                ? "bg-gray-400 cursor-not-allowed"
                : "bg-[#ff6c74] hover:bg-[#ff5a63]"
            } text-white`}
          >
            {isLoading ? (
              <div className="flex items-center gap-2">
                <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                로그인 중...
              </div>
            ) : !isInitialized ? (
              "초기화 중..."
            ) : (
              "WEPIN 로그인"
            )}
          </Button>
          <div className="text-white text-sm">
            {isLoading
              ? "Google 계정으로 로그인 중..."
              : "소셜 계정으로 간편 로그인"}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default LoginCard;
