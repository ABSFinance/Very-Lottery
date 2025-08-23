import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
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

  // Load game information
  useEffect(() => {
    // Prevent infinite reloading by checking if we already have data
    if (Object.keys(gameInfos).length > 0 && Object.values(loading).every(l => !l)) {
      console.log('🛑 Already have game infos, skipping reload');
      return;
    }
    
    const loadGameInfos = async () => {
      console.log('🔄 Loading game infos...');
      
      for (const game of games) {
        console.log(`Loading game info for ${game.title}:`);
        console.log(`- Game Type: ${game.gameType}`);
        console.log(`- Contract Address: ${game.address}`);
        console.log(`- Environment Variable: ${game.address}`);
        
        // Set loading state for this game
        setLoading(prev => ({ ...prev, [game.id]: true }));
        
        // Add timeout for this specific game
        const timeoutId = setTimeout(() => {
          console.warn(`Timeout reached for ${game.title}, setting loading to false`);
          setLoading(prev => ({ ...prev, [game.id]: false }));
        }, 10000); // 10 second timeout per game
        
        try {
          // Force use of Verychain RPC provider to ensure correct network connection
          const provider = new ethers.providers.JsonRpcProvider(
            process.env.REACT_APP_RPC_URL || 'https://rpc.verylabs.io',
            {
              name: 'Verychain',
              chainId: 4613
            }
          );
          
          console.log(`- Using Verychain RPC provider: ${process.env.REACT_APP_RPC_URL || 'https://rpc.verylabs.io'}`);
          
          // Test provider connection
          try {
            const network = await provider.getNetwork();
            console.log(`- Provider network: ${network.name} (Chain ID: ${network.chainId})`);
            
            const blockNumber = await provider.getBlockNumber();
            console.log(`- Current block number: ${blockNumber}`);
            
            // Test RPC connection by getting a recent block
            const block = await provider.getBlock(blockNumber);
            console.log(`- Latest block hash: ${block.hash}`);
            console.log(`- Latest block timestamp: ${new Date(block.timestamp * 1000).toISOString()}`);
            
          } catch (error) {
            console.error(`- Error testing provider:`, error);
          }
          
          // Use actual contract functions that exist
          const contractInterface = [
            "function getCurrentGameNumber() view returns (uint256)",
            "function getCurrentGamePlayerCount() view returns (uint256)",
            "function getCurrentGameJackpot() view returns (uint256)",
            "function getGameConfig() view returns (uint256 ticketPrice, uint256 gameDuration, uint256 maxTicketsPerPlayer, bool isActive)"
          ];
          
          const contract = new ethers.Contract(game.address, contractInterface, provider);
          console.log(`- Contract instance created for address: ${contract.address}`);
          console.log(`- Game: ${game.title}, Address: ${game.address}`);
          
          // Test if contract is accessible
          try {
            const code = await provider.getCode(game.address);
            console.log(`- Contract code exists: ${code !== '0x'}`);
            if (code === '0x') {
              console.warn(`- WARNING: No contract code at address ${game.address}`);
            }
          } catch (error) {
            console.error(`- Error checking contract code:`, error);
          }
          
          // Get game info using actual functions
          try {
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
            // Set default values when contract call fails (likely no games started)
            setGameInfos(prev => ({
              ...prev,
              [game.id]: {
                currentGameNumber: "0",
                ticketPrice: "0.01",
                isActive: false,
                playerCount: "0",
                currentJackpot: "0",
                status: "No games started yet - Buy first ticket to begin!"
              }
            }));
          } finally {
            setLoading(prev => ({ ...prev, [game.id]: false }));
            clearTimeout(timeoutId); // Clear timeout on successful load
          }
        } catch (error) {
          console.error(`Error loading game info for ${game.title}:`, error);
          // Set default values and reset loading even on outer error
          setGameInfos(prev => ({
            ...prev,
            [game.id]: {
              currentGameNumber: "0",
              ticketPrice: "0.01",
              isActive: false,
              playerCount: "0",
              currentJackpot: "0",
              status: "No games started yet - Buy first ticket to begin!"
            }
          }));
          setLoading(prev => ({ ...prev, [game.id]: false }));
          clearTimeout(timeoutId); // Clear timeout on error
        }
      }
    };

    loadGameInfos();
    
    // Cleanup function to reset loading states
    return () => {
      setLoading({});
      setGameInfos({});
    };
  }, []); // Empty dependency array - only run once on mount

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