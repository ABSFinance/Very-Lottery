import React, { useState, useEffect } from 'react';
import { getContractAddress, GAME_TYPES } from '../utils/contractAddresses';
import './GameSelector.css';

const GameCard = ({ title, price, duration, contract, onClick, gameInfo, loading }) => {
  return (
    <div className="game-card" onClick={onClick}>
      <div className="game-card-header">
        <h3>{title}</h3>
        <div className="game-type-badge">{contract}</div>
      </div>
      <div className="game-card-content">
        <div className="game-price">
          <span className="price-label">Ticket Price:</span>
          <span className="price-value">
            {loading ? 'Loading...' : gameInfo?.ticketPrice || price}
          </span>
        </div>
        <div className="game-duration">
          <span className="duration-label">Duration:</span>
          <span className="duration-value">{duration}</span>
        </div>
        {gameInfo && (
          <div className="game-stats">
            <div className="game-jackpot">
              <span className="jackpot-label">Current Jackpot:</span>
              <span className="jackpot-value">{gameInfo.currentJackpot} VERY</span>
            </div>
            <div className="game-players">
              <span className="players-label">Players:</span>
              <span className="players-value">{gameInfo.playerCount}</span>
            </div>
          </div>
        )}
      </div>
      <div className="game-card-footer">
        <button className="select-game-btn">Select Game</button>
      </div>
    </div>
  );
};

const GameSelector = ({ onGameSelect }) => {
  const [gameInfos, setGameInfos] = useState({});
  const [loading, setLoading] = useState({});

  const games = [
    {
      id: 1,
      title: "Cryptolotto 1 Day",
      description: "Daily lottery with transparent blockchain technology",
      price: "0.01 VERY",
      duration: "24 hours",
      gameType: GAME_TYPES.CRYPTOLOTTO_1DAY,
      address: getContractAddress(GAME_TYPES.CRYPTOLOTTO_1DAY)
    },
    {
      id: 2,
      title: "Cryptolotto 7 Days",
      description: "Weekly lottery with bigger prizes",
      price: "0.02 VERY",
      duration: "7 days",
      gameType: GAME_TYPES.CRYPTOLOTTO_7DAYS,
      address: getContractAddress(GAME_TYPES.CRYPTOLOTTO_7DAYS)
    },
    {
      id: 3,
      title: "Cryptolotto Ad",
      description: "Ad-supported lottery with token rewards",
      price: "0.01 VERY",
      duration: "24 hours",
      gameType: GAME_TYPES.CRYPTOLOTTO_AD,
      address: getContractAddress(GAME_TYPES.CRYPTOLOTTO_AD)
    }
  ];

  // Load game information for each game
  useEffect(() => {
    const loadGameInfos = async () => {
      for (const game of games) {
        if (game.address) {
          setLoading(prev => ({ ...prev, [game.id]: true }));
          try {
            // Create contract instance manually instead of using hook in loop
            const { ethers } = require('ethers');
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            
            // Use actual contract functions that exist
            const contractInterface = [
              "function getCurrentGameNumber() view returns (uint256)",
              "function getCurrentGamePlayerCount() view returns (uint256)",
              "function getCurrentGameJackpot() view returns (uint256)",
              "function getGameConfig() view returns (uint256 ticketPrice, uint256 gameDuration, uint256 maxTicketsPerPlayer, bool isActive)"
            ];
            
            const contract = new ethers.Contract(game.address, contractInterface, provider);
            
            // Get game info using actual functions
            const [gameNumber, playerCount, jackpot, gameConfig] = await Promise.all([
              contract.getCurrentGameNumber(),
              contract.getCurrentGamePlayerCount(),
              contract.getCurrentGameJackpot(),
              contract.getGameConfig()
            ]);
            
            setGameInfos(prev => ({
              ...prev,
              [game.id]: {
                currentGameNumber: gameNumber.toString(),
                ticketPrice: ethers.utils.formatEther(gameConfig[0]),
                isActive: gameConfig[3],
                playerCount: playerCount.toString(),
                currentJackpot: ethers.utils.formatEther(jackpot)
              }
            }));
          } catch (error) {
            console.error(`Error loading game info for ${game.title}:`, error);
          } finally {
            setLoading(prev => ({ ...prev, [game.id]: false }));
          }
        }
      }
    };

    loadGameInfos();
  }, []);

  return (
    <div className="game-selector">
      <div className="game-selector-header">
        <h2>Choose Your Game</h2>
        <p>Select from our variety of lottery games with different durations and prizes</p>
      </div>
      <div className="game-cards-grid">
        {games.map((game, index) => (
          <GameCard
            key={index}
            title={game.title}
            price={game.price}
            duration={game.duration}
            contract={game.gameType}
            gameInfo={gameInfos[game.id]}
            loading={loading[game.id]}
            onClick={() => onGameSelect(game)}
          />
        ))}
      </div>
    </div>
  );
};

export default GameSelector; 