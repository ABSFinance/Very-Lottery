// WEPIN 인증 설정
interface ViteEnv {
  VITE_WEPIN_APP_ID?: string;
  VITE_WEPIN_APP_KEY?: string;
  [key: string]: unknown;
}

export const AUTH_CONFIG = {
  // WEPIN 설정
  WEPIN: {
    APP_ID: (import.meta as unknown as { env: ViteEnv }).env?.VITE_WEPIN_APP_ID || 'your-wepin-app-id',
    APP_KEY: (import.meta as unknown as { env: ViteEnv }).env?.VITE_WEPIN_APP_KEY || 'your-wepin-app-key',
    DEFAULT_LANGUAGE: 'ko'
  }
};

// 환경 변수 확인
export const validateConfig = () => {
  const requiredVars = [
    'VITE_WEPIN_APP_ID', 
    'VITE_WEPIN_APP_KEY'
  ];
  
  const env = (import.meta as unknown as { env: ViteEnv }).env || {};
  const missingVars = requiredVars.filter(varName => !env?.[varName]);
  
  if (missingVars.length > 0) {
    console.warn('다음 환경 변수가 설정되지 않았습니다:', missingVars);
    console.warn('기본값을 사용합니다. 프로덕션 환경에서는 반드시 설정해주세요.');
  }
  
  return missingVars.length === 0;
}; 