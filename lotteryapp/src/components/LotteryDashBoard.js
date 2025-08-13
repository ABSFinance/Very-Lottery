import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { Box, VStack, Heading, Text, Badge, Button, Spinner } from "@chakra-ui/react";
import { getContractAddress, GAME_TYPES } from '../utils/contractAddresses';
import useGameContract from '../hooks/useGameContract';
import LotteryListing from "./LotteryListing";
import LotteryStats from "./LotteryStats";
import ReferralSystem from "./ReferralSystem";

const LotteryDashBoard = ({ selectedGame }) => {
  const [gameInfo, setGameInfo] = useState(null);
  const [gameConfig, setGameConfig] = useState(null);
  const [loading, setLoading] = useState(true);

  // Get game contract hook
  const gameContract = useGameContract(selectedGame?.gameType);

  // Load game information
  useEffect(() => {
    const loadGameData = async () => {
      if (selectedGame?.address && gameContract.contract) {
        setLoading(true);
        try {
          const info = await gameContract.getCurrentGameInfo();
          const config = await gameContract.getGameConfiguration();
          
          setGameInfo(info);
          setGameConfig(config);
        } catch (error) {
          console.error('Error loading game data:', error);
        } finally {
          setLoading(false);
        }
      }
    };

    loadGameData();
  }, [selectedGame, gameContract.contract]);

  return (
    <VStack spacing={6} p={4} maxW="1200px" mx="auto">
      {/* Selected Game Info */}
      {selectedGame && (
        <Box 
          bg="white" 
          p={6} 
          borderRadius="15px" 
          boxShadow="0 10px 30px rgba(0,0,0,0.1)"
          w="100%"
        >
          <VStack spacing={4}>
            <Heading size="lg" color="gray.700">
              {selectedGame.title}
            </Heading>
            
            {loading ? (
              <Spinner size="lg" />
            ) : (
              <>
                <Box display="flex" gap={4} flexWrap="wrap">
                  <Badge colorScheme="green" p={2} borderRadius="md">
                    Price: {gameConfig?.ticketPrice || selectedGame.price}
                  </Badge>
                  <Badge colorScheme="blue" p={2} borderRadius="md">
                    Duration: {selectedGame.duration}
                  </Badge>
                  <Badge colorScheme="purple" p={2} borderRadius="md">
                    Game Type: {selectedGame.gameType}
                  </Badge>
                </Box>
                
                {gameInfo && (
                  <Box display="flex" gap={4} flexWrap="wrap">
                    <Badge colorScheme="orange" p={2} borderRadius="md">
                      Current Jackpot: {gameInfo.currentJackpot} VERY
                    </Badge>
                    <Badge colorScheme="teal" p={2} borderRadius="md">
                      Players: {gameInfo.playerCount}
                    </Badge>
                    <Badge colorScheme="cyan" p={2} borderRadius="md">
                      Game #{gameInfo.currentGameNumber}
                    </Badge>
                    <Badge colorScheme={gameInfo.isActive ? "green" : "red"} p={2} borderRadius="md">
                      Status: {gameInfo.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </Box>
                )}
                
                <Text color="gray.600" textAlign="center">
                  Ready to play? Buy your ticket and join the game!
                </Text>
              </>
            )}
          </VStack>
        </Box>
      )}

      {/* Referral System */}
      <ReferralSystem />

      {/* Lottery Stats */}
      <LotteryStats selectedGame={selectedGame} gameInfo={gameInfo} />

      {/* Lottery Listing */}
      <LotteryListing selectedGame={selectedGame} gameInfo={gameInfo} />
    </VStack>
  );
};

export default LotteryDashBoard;
