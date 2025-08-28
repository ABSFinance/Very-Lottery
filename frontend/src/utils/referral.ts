export interface ReferralUser {
  walletAddress?: string;
  userId?: string;
  email?: string;
}

export const captureInboundRef = (storageKey = "referredBy"): string | null => {
  try {
    const url = new URL(window.location.href);
    const ref = url.searchParams.get("ref");
    if (ref) localStorage.setItem(storageKey, ref);
    return ref;
  } catch {
    return null;
  }
};

/**
 * Build referral link like ReferralSystem.js:
 * origin + '/?ref=' + referralId
 * Priority: walletAddress > userId > email
 */
export const buildReferralLink = (
  baseOrigin: string,
  user: ReferralUser
): string => {
  const origin = (baseOrigin || window.location.origin).replace(/\/$/, "");
  let id = user?.walletAddress?.toLowerCase();

  if (typeof id === "string") {
    id = id.trim();
  }

  // Only build link if we have a valid wallet address
  if (id && id !== "0x0000000000000000000000000000000000000000") {
    return `${origin}/?ref=${encodeURIComponent(id)}`;
  }
  
  // Return empty string or base URL if no valid wallet address
  return origin;
};

export const shareReferralLink = async (link: string): Promise<void> => {
  const shareData = {
    title: "VERY Lottery",
    text: "함께 참여하고 VERY 받아요! 제 링크로 가입하면 좋아요.",
    url: link,
  } as ShareData;

  if (navigator.share) {
    try {
      await navigator.share(shareData);
      return;
    } catch {
      // fallthrough to clipboard
    }
  }
  await navigator.clipboard.writeText(link);
  alert("링크가 클립보드에 복사되었습니다.");
};