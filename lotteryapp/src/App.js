import React, { useState, useEffect } from "react";
import NavBar from "./components/NavBar";
import LotteryDashBoard from "./components/LotteryDashBoard";
import GameSelector from "./components/GameSelector";
import ReferralSystem from "./components/ReferralSystem";

function App() {
  const [selectedGame, setSelectedGame] = useState(null);
  const [currentView, setCurrentView] = useState('games'); // 'games', 'lottery', 'referrals'
  const [referralAddress, setReferralAddress] = useState(null);

  // URL 파라미터에서 추천 주소 읽어오기
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const ref = urlParams.get('ref');
    if (ref && ref.startsWith('0x') && ref.length === 42) {
      console.log('Referral address found:', ref);
      setReferralAddress(ref);
      localStorage.setItem('referralAddress', ref);
      
      // URL에서 추천 파라미터 제거 (선택사항)
      const newUrl = window.location.pathname;
      window.history.replaceState({}, document.title, newUrl);
    }
  }, []);

  const handleGameSelect = (game) => {
    console.log('Game selected:', game);
    setSelectedGame(game);
    setCurrentView('lottery');
  };

  const renderContent = () => {
    console.log('Current view:', currentView);
    switch (currentView) {
      case 'games':
        return <GameSelector onGameSelect={handleGameSelect} />;
      case 'lottery':
        return <LotteryDashBoard selectedGame={selectedGame} />;
      case 'referrals':
        return <ReferralSystem />;
      default:
        return <GameSelector onGameSelect={handleGameSelect} />;
    }
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
      <NavBar onViewChange={setCurrentView} currentView={currentView} />
      <div style={{ padding: '20px' }}>
        {renderContent()}
      </div>
    </div>
  );
}

export default App;
