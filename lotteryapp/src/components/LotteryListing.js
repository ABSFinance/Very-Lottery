import React, { useState, useEffect, useCallback } from "react";
import {
  Box,
  Flex,
  Text,
  Button,
  Badge,
  Icon,
  SimpleGrid,
  Stack,
  useToast,
  Link,
  HStack,
  VStack,
  useColorModeValue,
  Heading,
  Alert,
  AlertIcon
} from "@chakra-ui/react";
import { FaEthereum } from "react-icons/fa";
import { ethers } from "ethers";
import { useMetaMaskAccount } from "../context/AccountContext";
import Spinner from "./Spinner";
import ToastMessage from './ToastMessage';
import {getEMessage, eventMessage} from '../errorMessages';
import useGameContract from "../hooks/useGameContract";

const backgrounds = [
  `url("data:image/svg+xml, %3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'560\' height=\'185\' viewBox=\'0 0 560 185\' fill=\'none\'%3E%3Cellipse cx=\'102.633\' cy=\'61.0737\' rx=\'102.633\' ry=\'61.0737\' fill=\'%23ED64A6\' /%3E%3Cellipse cx=\'399.573\' cy=\'123.926\' rx=\'102.633\' ry=\'61.0737\' fill=\'%23F56565\' /%3E%3Cellipse cx=\'366.192\' cy=\'73.2292\' rx=\'193.808\' ry=\'73.2292\' fill=\'%2338B2AC\' /%3E%3Cellipse cx=\'222.705\' cy=\'110.585\' rx=\'193.808\' ry=\'73.2292\' fill=\'%23ED8936\' /%3E%3C/svg%3E")`,
  `url("data:image/svg+xml, %3Csvg xmlns='http://www.w3.org/2000/svg' width='560' height='185' viewBox='0 0 560 185' fill='none'%3E%3Cellipse cx='457.367' cy='123.926' rx='102.633' ry='61.0737' transform='rotate(-180 457.367 123.926)' fill='%23ED8936'/%3E%3Cellipse cx='160.427' cy='61.0737' rx='102.633' ry='61.0737' transform='rotate(-180 160.427 61.0737)' fill='%2348BB78'/%3E%3Cellipse cx='193.808' cy='111.771' rx='193.808' ry='73.2292' transform='rotate(-180 193.808 111.771)' fill='%230BC5EA'/%3E%3Cellipse cx='337.295' cy='74.415' rx='193.808' ry='73.2292' transform='rotate(-180 337.295 74.415)' fill='%23ED64A6'/%3E%3C/svg%3E")`,
  `url("data:image/svg+xml, %3Csvg xmlns='http://www.w3.org/2000/svg' width='560' height='185' viewBox='0 0 560 185' fill='none'%3E%3Cellipse cx='102.633' cy='61.0737' rx='102.633' ry='61.0737' fill='%23ED8936'/%3E%3Cellipse cx='399.573' cy='123.926' rx='102.633' ry='61.0737' fill='%2348BB78'/%3E%3Cellipse cx='366.192' cy='73.2292' rx='193.808' ry='73.2292' fill='%230BC5EA'/%3E%3Cellipse cx='222.705' cy='110.585' rx='193.808' ry='73.2292' fill='%23ED64A6'/%3E%3C/svg%3E")`,
  `url("data:image/svg+xml, %3Csvg xmlns='http://www.w3.org/2000/svg' width='560' height='185' viewBox='0 0 560 185' fill='none'%3E%3Cellipse cx='457.367' cy='123.926' rx='102.633' ry='61.0737' transform='rotate(-180 457.367 123.926)' fill='%23ECC94B'/%3E%3Cellipse cx='160.427' cy='61.0737' rx='102.633' ry='61.0737' transform='rotate(-180 160.427 61.0737)' fill='%239F7AEA'/%3E%3Cellipse cx='193.808' cy='111.771' rx='193.808' ry='73.2292' transform='rotate(-180 193.808 111.771)' fill='%234299E1'/%3E%3Cellipse cx='337.295' cy='74.415' rx='193.808' ry='73.2292' transform='rotate(-180 337.295 74.415)' fill='%2348BB78'/%3E%3C/svg%3E")`,
];

function Lottery(props) {
  const { index, lotteryId, enterLotteryHandler, entryBtnLoaders, selectedGame, localGameInfo, loading, transactionHashes } = props;
  const contractAddress = selectedGame?.address;



 
  return (
    <Flex
      boxShadow={"lg"}
      maxW={"640px"}
      direction={{ base: "column-reverse", md: "row" }}
      width={"full"}
      rounded={"xl"}
      p={10}
      justifyContent={"space-between"}
      position={"relative"}
      bg={useColorModeValue("white", "gray.800")}
      _before={{
        content: '""',
        position: "absolute",
        zIndex: "-1",
        height: "full",
        maxW: "640px",
        width: "full",
        filter: "blur(40px)",
        transform: "scale(0.98)",
        backgroundRepeat: "no-repeat",
        backgroundSize: "cover",
        top: 0,
        left: 0,
        backgroundImage: backgrounds[index % 4],
      }}
    >
      <Flex
        direction={"column"}
        textAlign={"left"}
        justifyContent={"space-between"}
      >
        <Heading fontSize={"1xl"} fontWeight={300} fontFamily={"body"}>
          {selectedGame?.title || 'Cryptolotto'}
        </Heading>
        <Text color={"gray.500"}>
          <Badge variant="solid" colorScheme="green">
            Game: {lotteryId.toString()}
          </Badge>
        </Text>

        {loading ? <Spinner/> :
            <>
              {localGameInfo ?
                <>
                  <Text fontSize={"sm"} color={"gray.500"} pt={4}>
                    Active Players: {localGameInfo.players || "0"}
                  </Text>
                  <Text fontSize={"sm"} color={"gray.500"}>
                    Ticket Price: {localGameInfo.ticketPrice || "0.01"} VERY
                  </Text>
                  <Text fontSize={"sm"} color={"gray.500"}>
                    Jackpot: {localGameInfo.jackpot || "0"} VERY
                  </Text>
                </>
                : 
                <Text fontSize={"sm"} color={"gray.500"} pt={4}>
                  <Badge variant="outline" colorScheme="blue">
                    🎯 No games started yet - Buy the first ticket to begin the lottery!
                  </Badge>
                </Text>
              }
            </>
        }
       

       {localGameInfo ?
        <Box pt={4}>
          {localGameInfo.isActive && 
              <>
                <Text fontSize={"sm"} color={"gray.500"} mb={2}>
                  Ticket Price: {localGameInfo.ticketPrice} VERY
                </Text>
                <Button
                  size="sm"
                  w={"full"}
                  mt={3}
                  bg={"#3182ce"}
                  color={"white"}
                  rounded={"md"}
                  _hover={{
                    transform: "translateY(-2px)",
                    boxShadow: "lg",
                  }}
                  onClick={() => {
                    enterLotteryHandler(lotteryId, localGameInfo.ticketPrice)
                  }}
                  isLoading={entryBtnLoaders[lotteryId]}
                  id={`enterBtn${lotteryId}`}
                >
                  Buy Ticket for {localGameInfo.ticketPrice} VERY
                </Button>
                
                {/* Show transaction hash if available */}
                {transactionHashes[lotteryId] && (
                  <Box mt={2} p={2} bg="blue.50" borderRadius="md">
                    <Text fontSize="xs" color="gray.600" mb={1}>
                      Last Transaction:
                    </Text>
                    <Link 
                      href={`https://veryscan.io/tx/${transactionHashes[lotteryId]}`}
                      isExternal
                      fontSize="xs"
                      color="blue.500"
                      _hover={{ textDecoration: "underline" }}
                    >
                      {transactionHashes[lotteryId].substring(0, 10)}...{transactionHashes[lotteryId].substring(transactionHashes[lotteryId].length - 8)}
                    </Link>
                  </Box>
                )}
              </>
          }
          {
            !localGameInfo.isActive &&  
            <>
              <Text as='i' pr="2">Game Ended</Text>
              <Badge variant='solid' colorScheme='red'>
                Inactive
              </Badge>
            </>
          }
        </Box>
        : <Spinner />}
      </Flex>
      <Icon as={FaEthereum} boxSize="50" />
    </Flex>
  );
}

export default function LotteryListing({ selectedGame }) {
  const toast = useToast();
  const { connected, connectedAddr } = useMetaMaskAccount();
  const [entryBtnLoaders, setEntryBtnLoaders] = useState({})
  const [transactionHashes, setTransactionHashes] = useState({})
  const [processedTransactions, setProcessedTransactions] = useState(new Set())
  const [referralInfo, setReferralInfo] = useState(null)
  const [loading, setLoading] = useState(false)
  const [localGameInfo, setLocalGameInfo] = useState(null)

  // Use new game contract hook
  const gameContract = useGameContract(selectedGame?.gameType);

  // Get referral address from localStorage
  const getReferralAddress = () => {
    const stored = localStorage.getItem('referralAddress');
    return stored && stored.startsWith('0x') && stored.length === 42 ? stored : '0x0000000000000000000000000000000000000000';
  };

  // Buy ticket function with new contract structure
  const buyTicket = useCallback(async (ticketCount = 1) => {
    if (!connected || !selectedGame?.address) {
      toast({
        title: 'Error',
        description: 'Please connect your wallet and select a game',
        status: 'error',
        isClosable: true,
      });
      return;
    }

    try {
      setEntryBtnLoaders(prev => ({ ...prev, [selectedGame.id]: true }));
      
      const referralAddress = getReferralAddress();
      
      // Use localGameInfo instead of gameInfo, with fallback to contract
      let ticketPrice = '0.01'; // Default fallback
      
      if (localGameInfo?.ticketPrice) {
        ticketPrice = localGameInfo.ticketPrice;
      } else if (gameContract.contract) {
        try {
          const gameConfig = await gameContract.contract.getGameConfig();
          ticketPrice = ethers.utils.formatEther(gameConfig[0]);
        } catch (error) {
          console.error('Error getting ticket price from contract:', error);
          // Use default ticket price if contract call fails
          ticketPrice = "0.01";
        }
      }
      
      const value = ethers.utils.parseEther(ticketPrice).mul(ticketCount);
      
      console.log('Buying ticket:', {
        referrer: referralAddress,
        ticketCount,
        value: ethers.utils.formatEther(value),
        gameType: selectedGame.gameType,
        ticketPrice
      });

      const tx = await gameContract.buyTicket(referralAddress, ticketCount, value);
      
      console.log('Transaction sent:', tx.hash);
      
      // Wait for transaction
      const receipt = await tx.wait();
      console.log('Transaction confirmed:', receipt);
      
      toast({
        title: 'Success!',
        description: `Ticket purchased successfully! Transaction: ${tx.hash}`,
        status: 'success',
        isClosable: true,
      });
      
      // Update transaction hashes
      setTransactionHashes(prev => ({
        ...prev,
        [selectedGame.id]: tx.hash
      }));
      
    } catch (error) {
      console.error('Error buying ticket:', error);
      toast({
        title: 'Error',
        description: error.message || 'Failed to buy ticket',
        status: 'error',
        isClosable: true,
      });
    } finally {
      setEntryBtnLoaders(prev => ({ ...prev, [selectedGame.id]: false }));
    }
  }, [connected, selectedGame, localGameInfo, gameContract, toast]);

  //enter lottery action

  // Check for referral information
  useEffect(() => {
    // Flag to track if component is still mounted
    let isMounted = true;
    
    const loadReferralInfo = async () => {
      if (connected && connectedAddr && gameContract.contract) {
        try {
          // Get referral info from contract if available
          const referralAddress = getReferralAddress();
          if (referralAddress !== '0x0000000000000000000000000000000000000000') {
            if (isMounted) {
              setReferralInfo({
                address: referralAddress,
                code: referralAddress.slice(2, 8).toUpperCase()
              });
            }
          }
        } catch (error) {
          console.error('Error loading referral info:', error);
        }
      }
    };

    loadReferralInfo();
    
    // Cleanup function
    return () => {
      isMounted = false;
    };
  }, [connected, connectedAddr, gameContract.contract]);

  // Handle transaction events - TEMPORARILY DISABLED TO PREVENT ERRORS
  /*
  useEffect(() => {
    if (gameContract.contract) {
      const handleTicketPurchased = (player, gameNumber, ticketIndex, timestamp) => {
        console.log('Ticket purchased:', { player, gameNumber, ticketIndex, timestamp });
        toast({
          title: 'Ticket Purchased!',
          description: `Game #${gameNumber}, Ticket #${ticketIndex}`,
          status: 'success',
          isClosable: true,
        });
      };

      const handleWinnerSelected = (winner, gameNumber, amount, timestamp) => {
        console.log('Winner selected:', { winner, gameNumber, amount, timestamp });
        toast({
          title: 'Winner Selected!',
          description: `Game #${gameNumber} - Winner: ${winner.slice(0, 6)}...${winner.slice(-4)}`,
          status: 'success',
          isClosable: true,
        });
      };

      const handleGameEnded = (gameNumber, totalPlayers, totalJackpot, timestamp) => {
        console.log('Game ended:', { gameNumber, totalPlayers, totalJackpot, timestamp });
        toast({
          title: 'Game Ended!',
          description: `Game #${gameNumber} - Total Players: ${totalPlayers}, Jackpot: ${ethers.utils.formatEther(totalJackpot)} VERY`,
          status: 'info',
          isClosable: true,
        });
      };

      // Listen for events using correct event names
      gameContract.contract.on('TicketPurchased', handleTicketPurchased);
      gameContract.contract.on('WinnerSelected', handleWinnerSelected);
      gameContract.contract.on('GameEnded', handleGameEnded);

      // Cleanup
      return () => {
        gameContract.contract.off('TicketPurchased', handleTicketPurchased);
        gameContract.contract.off('WinnerSelected', handleWinnerSelected);
        gameContract.contract.off('GameEnded', handleGameEnded);
      };
    }
  }, [gameContract.contract, toast]);
  */
  
  console.log('Event listening temporarily disabled to prevent errors');

  // Load initial game data when component mounts
  useEffect(() => {
    // Flag to track if component is still mounted
    let isMounted = true;
    
    const loadInitialGameData = async () => {
      if (!selectedGame?.address || !gameContract.contract) {
        console.log('No game selected or contract not available');
        return;
      }

      console.log('🔄 Loading initial game data for:', selectedGame.title);
      if (isMounted) {
        setLoading(true);
      }
      
      try {
        const [gameNumber, playerCount, jackpot, gameConfig] = await Promise.all([
          gameContract.contract.getCurrentGameNumber(),
          gameContract.contract.getCurrentGamePlayerCount(),
          gameContract.contract.getCurrentGameJackpot(),
          gameContract.contract.getGameConfig()
        ]);
        
        console.log('✅ Game data loaded:', { gameNumber, playerCount, jackpot, gameConfig });
        
        if (isMounted) {
          setLocalGameInfo({
            game: gameNumber.toString(),
            ticketPrice: ethers.utils.formatEther(gameConfig[0]),
            isActive: gameConfig[3],
            playerCount: playerCount.toString(),
            currentJackpot: ethers.utils.formatEther(jackpot)
          });
        }
      } catch (error) {
        console.error('❌ Error loading initial game data:', error);
        // Set default values when contract call fails
        if (isMounted) {
          setLocalGameInfo({
            game: "0",
            ticketPrice: "0.01",
            isActive: false,
            playerCount: "0",
            currentJackpot: "0"
          });
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    loadInitialGameData();
    
    // Cleanup function
    return () => {
      isMounted = false;
    };
  }, [selectedGame?.address, gameContract.contract]); // Only run when game or contract changes

  //enter lottery action






  return (
   <>
     <Flex
      textAlign={"center"}
      pt={3}
      justifyContent={"center"}
      direction={"column"}
      width={"full"}
      >

        {/* Referral Information */}
        {referralInfo && (
          <Alert status="info" mb={4} borderRadius="md">
            <AlertIcon />
            <Box>
              <Text fontWeight="bold">{referralInfo.message}</Text>
              <Text fontSize="sm" color="gray.600">
                The referrer will earn commission from your ticket purchase
              </Text>
            </Box>
          </Alert>
        )}
        
        {loading ? (
          <Spinner loading size={40} applyPadding/>
        ) : (
          <>
            <SimpleGrid
              p={4}
              columns={{ base: 1, xl: 3 }}
              spacing={"8"}
              mt={8}
              ml={4}
            >
              <Lottery 
                index={0} 
                key={0} 
                lotteryId={localGameInfo?.game || "0"} 
                enterLotteryHandler={buyTicket} 
                entryBtnLoaders={entryBtnLoaders} 
                selectedGame={selectedGame}
                localGameInfo={localGameInfo || {
                  game: "0",
                  ticketPrice: "0.01",
                  isActive: false,
                  players: "0",
                  jackpot: "0.0"
                }}
                loading={loading}
                transactionHashes={transactionHashes}
              />
            </SimpleGrid>
          </>
        )}
    </Flex>
   </>
  );
}
