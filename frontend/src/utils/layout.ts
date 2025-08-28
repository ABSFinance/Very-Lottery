export interface MobileLayout {
  prizeTop: number;
  prizeHeight: number;
  promo1Top: number;
  promo2Top: number;
  promo3Top: number;
}

export const computeMobileLayout = (isLoggedIn: boolean): MobileLayout => {
  const prizeTop = isLoggedIn ? 300 : 170;
  const prizeHeight = 127; // total earning card
  const gap = 12;
  const promo1Top = prizeTop + prizeHeight + gap;
  const promo2Top = promo1Top + 118 + gap; // second promo card height
  const promo3Top = promo2Top + 101 + gap; // third promo card height
  return { prizeTop, prizeHeight, promo1Top, promo2Top, promo3Top };
};

// Navigation items for the bottom navigation bar
export const navigationItems = [
  {
    icon: "/group-6498.png",
    label: "홈",
    hasNotification: false,
    notificationCount: 0,
  },
  {
    icon: "/vector-1.svg",
    unionIcon: "/union-2.svg",
    label: "채팅",
    hasNotification: true,
    notificationCount: 3,
  },
  {
    icon: "/vector.svg",
    unionIcon: "/union.svg",
    label: "채널",
    hasNotification: true,
    notificationCount: 2,
  },
  {
    icon: "/symbol.svg",
    label: "채굴",
    hasNotification: false,
    notificationCount: 0,
  },
  {
    icon: "/union-1.svg",
    label: "지갑",
    hasNotification: false,
    notificationCount: 0,
  },
];