import React, { useState } from 'react';
import './ReferralSystem.css';
import { useMetaMaskAccount } from '../context/AccountContext';

const ReferralSystem = () => {
  const { connected, connectedAddr } = useMetaMaskAccount();
  const [referralCode, setReferralCode] = useState('CRYPTO123');
  const [totalReferrals, setTotalReferrals] = useState(0);
  const [earnings, setEarnings] = useState('0');

  // Use actual wallet address if connected, otherwise use placeholder
  const referralAddress = connected && connectedAddr ? connectedAddr : '0x0000000000000000000000000000000000000000';

  const copyReferralLink = () => {
    if (!connected) {
      alert('Please connect your wallet first to generate a referral link!');
      return;
    }
    
    const link = `${window.location.origin}?ref=${referralAddress}`;
    navigator.clipboard.writeText(link);
    alert('Referral link copied to clipboard!');
  };

  const shareReferralLink = () => {
    if (!connected) {
      alert('Please connect your wallet first to generate a referral link!');
      return;
    }
    
    const link = `${window.location.origin}?ref=${referralAddress}`;
    const text = `Join me in the most transparent lottery on blockchain! Use my referral link: ${link}`;
    
    if (navigator.share) {
      navigator.share({
        title: 'Cryptolotto Referral',
        text: text,
        url: link
      });
    } else {
      copyReferralLink();
    }
  };

  return (
    <div className="referral-system">
      <div className="referral-header">
        <h3>🎯 Referral Program</h3>
        <p>Earn rewards by inviting friends to play!</p>
      </div>
      
      {!connected && (
        <div className="referral-warning">
          <p>⚠️ Please connect your wallet to generate your referral link</p>
        </div>
      )}
      
      <div className="referral-stats">
        <div className="stat-card">
          <div className="stat-icon">🔗</div>
          <div className="stat-content">
            <div className="stat-label">Your Referral Address</div>
            <div className="stat-value">
              {connected ? 
                `${referralAddress.substring(0, 6)}...${referralAddress.substring(38)}` : 
                'Connect Wallet'
              }
            </div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">👥</div>
          <div className="stat-content">
            <div className="stat-label">Total Referrals</div>
            <div className="stat-value">{totalReferrals}</div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">💰</div>
          <div className="stat-content">
            <div className="stat-label">Total Earnings</div>
            <div className="stat-value">{earnings} VERY</div>
          </div>
        </div>
      </div>
      
      <div className="referral-actions">
        <button 
          className={`referral-btn copy-btn ${!connected ? 'disabled' : ''}`} 
          onClick={copyReferralLink}
          disabled={!connected}
        >
          📋 Copy Link
        </button>
        <button 
          className={`referral-btn share-btn ${!connected ? 'disabled' : ''}`} 
          onClick={shareReferralLink}
          disabled={!connected}
        >
          📤 Share
        </button>
      </div>
      
      <div className="referral-info">
        <h4>How it works:</h4>
        <ul>
          <li>Connect your wallet to generate your unique referral link</li>
          <li>Share your referral link with friends</li>
          <li>Earn commission on their ticket purchases</li>
          <li>Get additional rewards for successful referrals</li>
          <li>Track your earnings in real-time</li>
        </ul>
      </div>
    </div>
  );
};

export default ReferralSystem; 