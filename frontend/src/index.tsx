import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { Mobile } from "./screens/Mobile/Mobile";
import VeryLucky from "./screens/Games/VeryLucky";

const AppRouter = () => {
  const [path, setPath] = useState<string>(window.location.pathname);

  useEffect(() => {
    const onPopState = () => setPath(window.location.pathname);
    const onNavigation = (e: CustomEvent) => setPath(e.detail.path);

    window.addEventListener("popstate", onPopState);
    window.addEventListener("navigation", onNavigation as EventListener);

    return () => {
      window.removeEventListener("popstate", onPopState);
      window.removeEventListener("navigation", onNavigation as EventListener);
    };
  }, []);

  if (path.startsWith("/games/daily-lucky")) {
    return <VeryLucky gameType="daily-lucky" />;
  }
  if (path.startsWith("/games/weekly-jackpot")) {
    return <VeryLucky gameType="weekly-jackpot" />;
  }
  if (path.startsWith("/games/ads-lucky")) {
    return <VeryLucky gameType="ads-lucky" />;
  }
  return <Mobile />;
};

createRoot(document.getElementById("app") as HTMLElement).render(
  <StrictMode>
    <AppRouter />
  </StrictMode>
);
