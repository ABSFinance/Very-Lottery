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
import useLotteryAction from "../hooks/useLotteryActions";
import useLotteryContract from "../hooks/useLotteryContract";
import Spinner from "./Spinner";
import ToastMessage from './ToastMessage';
import {getEMessage, eventMessage} from '../errorMessages';

const backgrounds = [
  `url("data:image/svg+xml, %3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'560\' height=\'185\' viewBox=\'0 0 560 185\' fill=\'none\'%3E%3Cellipse cx=\'102.633\' cy=\'61.0737\' rx=\'102.633\' ry=\'61.0737\' fill=\'%23ED64A6\' /%3E%3Cellipse cx=\'399.573\' cy=\'123.926\' rx=\'102.633\' ry=\'61.0737\' fill=\'%23F56565\' /%3E%3Cellipse cx=\'366.192\' cy=\'73.2292\' rx=\'193.808\' ry=\'73.2292\' fill=\'%2338B2AC\' /%3E%3Cellipse cx=\'222.705\' cy=\'110.585\' rx=\'193.808\' ry=\'73.2292\' fill=\'%23ED8936\' /%3E%3C/svg%3E")`,
  `url("data:image/svg+xml, %3Csvg xmlns='http://www.w3.org/2000/svg' width='560' height='185' viewBox='0 0 560 185' fill='none'%3E%3Cellipse cx='457.367' cy='123.926' rx='102.633' ry='61.0737' transform='rotate(-180 457.367 123.926)' fill='%23ED8936'/%3E%3Cellipse cx='160.427' cy='61.0737' rx='102.633' ry='61.0737' transform='rotate(-180 160.427 61.0737)' fill='%2348BB78'/%3E%3Cellipse cx='193.808' cy='111.771' rx='193.808' ry='73.2292' transform='rotate(-180 193.808 111.771)' fill='%230BC5EA'/%3E%3Cellipse cx='337.295' cy='74.415' rx='193.808' ry='73.2292' transform='rotate(-180 337.295 74.415)' fill='%23ED64A6'/%3E%3C/svg%3E")`,
  `url("data:image/svg+xml, %3Csvg xmlns='http://www.w3.org/2000/svg' width='560' height='185' viewBox='0 0 560 185' fill='none'%3E%3Cellipse cx='102.633' cy='61.0737' rx='102.633' ry='61.0737' fill='%23ED8936'/%3E%3Cellipse cx='399.573' cy='123.926' rx='102.633' ry='61.0737' fill='%2348BB78'/%3E%3Cellipse cx='366.192' cy='73.2292' rx='193.808' ry='73.2292' fill='%230BC5EA'/%3E%3Cellipse cx='222.705' cy='110.585' rx='193.808' ry='73.2292' fill='%23ED64A6'/%3E%3C/svg%3E")`,
  `url("data:image/svg+xml, %3Csvg xmlns='http://www.w3.org/2000/svg' width='560' height='185' viewBox='0 0 560 185' fill='none'%3E%3Cellipse cx='457.367' cy='123.926' rx='102.633' ry='61.0737' transform='rotate(-180 457.367 123.926)' fill='%23ECC94B'/%3E%3Cellipse cx='160.427' cy='61.0737' rx='102.633' ry='61.0737' transform='rotate(-180 160.427 61.0737)' fill='%239F7AEA'/%3E%3Cellipse cx='193.808' cy='111.771' rx='193.808' ry='73.2292' transform='rotate(-180 193.808 111.771)' fill='%234299E1'/%3E%3Cellipse cx='337.295' cy='74.415' rx='193.808' ry='73.2292' transform='rotate(-180 337.295 74.415)' fill='%2348BB78'/%3E%3C/svg%3E")`,
];

function Lottery(props) {
  const { index, lotteryId, enterLotteryHandler, entryBtnLoaders, selectedGame, gameInfo, loading, transactionHashes } = props;
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
              {gameInfo ?
                <>
                  <Text fontSize={"sm"} color={"gray.500"} pt={4}>
                    Active Players: {gameInfo.players}
                  </Text>
                  <Text fontSize={"sm"} color={"gray.500"}>
                    Ticket Price: {gameInfo.ticketPrice} VERY
                  </Text>
                  <Text fontSize={"sm"} color={"gray.500"}>
                    Jackpot: {gameInfo.jackpot} VERY
                  </Text>
                </>
                : ''
              }
            </>
        }
       

       {gameInfo ?
        <Box pt={4}>
          {gameInfo.isActive && 
              <>
                <Text fontSize={"sm"} color={"gray.500"} mb={2}>
                  Ticket Price: {gameInfo.ticketPrice} VERY
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
                    enterLotteryHandler(lotteryId, gameInfo.ticketPrice)
                  }}
                  isLoading={entryBtnLoaders[lotteryId]}
                  id={`enterBtn${lotteryId}`}
                >
                  Buy Ticket for {gameInfo.ticketPrice} VERY
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
            !gameInfo.isActive &&  
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
  const contractAddress = selectedGame?.address;

  const {
    txnError, 
    callContract,
    waitData:entryLWaitData, waitLoading:entryLWaitLoading, wait
  } = useLotteryAction('buyTicket', contractAddress);

  const {
    txnError: startLError,
    callContract:startLottery, waitData:startLWaitResult, waitLoading:startLWaitLoading } = useLotteryAction('start', contractAddress);

  const { contract } = useLotteryContract(contractAddress);

  // Initialize contract if not already initialized
  const initializeContract = useCallback(async () => {
    if (contract && selectedGame) {
      try {
        const ownableAddress = await contract.ownable();
        if (ownableAddress === "0x0000000000000000000000000000000000000000") {
          console.log('Contract not initialized, attempting to initialize...');
          
          // Get addresses from environment variables
          const ownableContract = process.env.REACT_APP_OWNABLE;
          const distributorContract = process.env.REACT_APP_FUNDS_DISTRIBUTOR;
          const statsContract = process.env.REACT_APP_STATS_AGGREGATOR;
          const referralContract = process.env.REACT_APP_REFERRAL_CONTRACT;
          
          console.log('Initialization addresses:', {
            ownable: ownableContract,
            distributor: distributorContract,
            stats: statsContract,
            referral: referralContract
          });
          
          // Show warning that contract needs initialization
          toast({
            title: 'Contract not initialized',
            description: `The lottery contract at ${selectedGame.address} needs to be initialized. Please contact the contract owner.`,
            status: 'warning',
            isClosable: true,
            duration: 10000,
          });
          
          // Disable ticket purchase
          setGameInfo(prev => prev ? { ...prev, isActive: false } : null);
        }
      } catch (error) {
        console.error('Contract initialization check failed:', error);
      }
    }
  }, [contract, selectedGame, toast]);

  // Check if contract is initialized
  const checkContractInitialization = useCallback(async () => {
    if (contract && selectedGame) {
      try {
        // Check if ownable contract is set
        const ownableAddress = await contract.ownable();
        console.log('Ownable address:', ownableAddress);
        
        // Check if stats contract is set
        const statsAddress = await contract.stats();
        console.log('Stats address:', statsAddress);
        
        // Check if referral contract is set
        const referralAddress = await contract.referralInstance();
        console.log('Referral address:', referralAddress);
        
        // Check if funds distributor is set
        const distributorAddress = await contract.fundsDistributor();
        console.log('Funds distributor address:', distributorAddress);
        
        // Check if game is active
        const isActive = await contract.isActive();
        console.log('Game is active:', isActive);
        
        // Check ticket price
        const ticketPrice = await contract.ticketPrice();
        console.log('Ticket price:', ethers.utils.formatEther(ticketPrice));
        
        // Check if contract is properly initialized
        if (ownableAddress === "0x0000000000000000000000000000000000000000" ||
            statsAddress === "0x0000000000000000000000000000000000000000" ||
            referralAddress === "0x0000000000000000000000000000000000000000" ||
            distributorAddress === "0x0000000000000000000000000000000000000000") {
          console.error('Contract is not properly initialized!');
          toast({
            title: 'Contract not initialized',
            description: 'The lottery contract needs to be initialized with proper addresses',
            status: 'error',
            isClosable: true,
          });
        }
        
      } catch (error) {
        console.error('Contract initialization check failed:', error);
        toast({
          title: 'Contract error',
          description: 'Failed to check contract initialization',
          status: 'error',
          isClosable: true,
        });
      }
    }
  }, [contract, selectedGame, toast]);
  const [gameInfo, setGameInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  //start Lottery Event 
  useEffect(() => {
    if((typeof startLWaitResult !== "undefined") && (!startLWaitLoading)){
      handleEvents(startLWaitResult, 'LotteryCreated')
    }
  },[startLWaitResult, startLWaitLoading]);

  //enter Lottery
  useEffect(() => {
    console.log('entryLWaitData changed:', entryLWaitData);
    console.log('entryLWaitLoading:', entryLWaitLoading);
    
    if((typeof entryLWaitData !== "undefined") && (!entryLWaitLoading)){
      console.log('Processing entryLWaitData:', entryLWaitData);
      
      // Check if this transaction has already been processed
      const txHash = entryLWaitData.transactionHash;
      if (processedTransactions.has(txHash)) {
        console.log('Transaction already processed in useEffect, skipping');
        return;
      }
      
      handleEvents(entryLWaitData, 'Ticket')
    }
  },[entryLWaitData, entryLWaitLoading, processedTransactions]);




  //event handler
  const handleEvents = async (eventData, eventType) => {
    console.log('handleEvents called with:', { eventData, eventType });
    
    if(eventData.events){
      console.log('Events found:', eventData.events);
      console.log('Looking for event type:', eventType);
      
      // Log all event names to see what's available
      eventData.events.forEach((evt, index) => {
        console.log(`Event ${index}:`, evt);
      });
      
      const e = eventData.events.find(eve => eve.event === eventType);
      console.log('Found event:', e);
      
      if(typeof e !== "undefined"){
        // Get transaction hash for scan link
        let txHash = eventData.transactionHash || eventData.hash;
        console.log('Event data for txHash:', eventData);
        console.log('Extracted txHash from event:', txHash);
        
        if (!txHash) {
          console.error('Could not find transaction hash in event data');
          return;
        }
        
        // Check if this transaction has already been processed
        if (processedTransactions.has(txHash)) {
          console.log('Transaction already processed in event handler, skipping');
          return;
        }
        
        console.log('Processing Ticket event for transaction:', txHash);
        
        // Mark transaction as processed
        setProcessedTransactions(prev => new Set([...prev, txHash]));
        
        const scanUrl = `https://veryscan.io/tx/${txHash}`;
        
        console.log('Showing toast from event handler for transaction:', txHash);
        // Temporarily disable toast from event handler to prevent duplicates
        // toast({
        //   title: eventMessage(e.event),
        //   description: (
        //     <VStack spacing={2} align="start">
        //       <Text fontSize="sm">Transaction completed successfully!</Text>
        //       <Link href={scanUrl} isExternal color="blue.500" fontWeight="bold">
        //         🔍 View on Very Scan →
        //       </Link>
        //     </VStack>
        //   ),
        //   status: 'success',
        //   isClosable: true,
        //   duration: 15000,
        // });
  
        if(e.event === 'Ticket'){
          // Reset button loader for this specific lottery
          setEntryBtnLoaders(prevS => {
            return {
              ...prevS,
              [e.args[1].toString()]: false  // e.args[1] is the game number
            }
          });
          
          // Store transaction hash for this lottery
          setTransactionHashes(prev => ({
            ...prev,
            [e.args[1].toString()]: txHash  // e.args[1] is the game number
          }));
          
          // Refresh game info after successful transaction
          if(contract && selectedGame) {
            const fetchGameInfo = async () => {
              try {
                const [game, ticketPrice, isActive, players, jackpot] = await Promise.all([
                  contract.game(),
                  contract.ticketPrice(),
                  contract.isActive(),
                  contract.getPlayedGamePlayers(),
                  contract.getPlayedGameJackpot()
                ]);
                
                setGameInfo({
                  game: game.toString(),
                  ticketPrice: ethers.utils.formatEther(ticketPrice),
                  isActive,
                  players: players.toString(),
                  jackpot: ethers.utils.formatEther(jackpot)
                });
              } catch (error) {
                console.error('Error fetching game info after transaction:', error);
              }
            };
            
            fetchGameInfo();
          }
        }

        if(e.event === 'LotteryCreated') {
          // Refresh game info
          if(contract && selectedGame) {
            const fetchGameInfo = async () => {
              setLoading(true);
              try {
                const [game, ticketPrice, isActive, players, jackpot] = await Promise.all([
                  contract.game(),
                  contract.ticketPrice(),
                  contract.isActive(),
                  contract.getPlayedGamePlayers(),
                  contract.getPlayedGameJackpot()
                ]);
                
                setGameInfo({
                  game: game.toString(),
                  ticketPrice: ethers.utils.formatEther(ticketPrice),
                  isActive,
                  players: players.toString(),
                  jackpot: ethers.utils.formatEther(jackpot)
                });
              } catch (error) {
                console.error('Error fetching game info:', error);
              }
              setLoading(false);
            };
            
            fetchGameInfo();
          }
        }
  

      }

    }
  }

  useEffect(() => {
    if (txnError) {
      handlerTxnErrors(txnError);
      // Reset all button loaders on error
      setEntryBtnLoaders({});
    }
  },[txnError])

  useEffect(() => {
    if (startLError) {
      handlerTxnErrors(startLError);
    }
  },[startLError])

  const handlerTxnErrors = async(err) => {
    if(typeof err !== "undefined"){
      console.error('Transaction error:', err);
      
      if(err?.name && err.name === "UserRejectedRequestError"){
        toast({
          title: 'User rejected the transaction',
          status: 'error',
          isClosable: true,
        });
        return;
      }
      
      // Log detailed error information
      if(err?.data?.message) {
        console.error('Error message:', err.data.message);
        toast({
          title: `Transaction failed: ${err.data.message}`,
          status: 'error',
          isClosable: true,
        });
      } else if(err?.message) {
        console.error('Error message:', err.message);
        toast({
          title: `Transaction failed: ${err.message}`,
          status: 'error',
          isClosable: true,
        });
      } else {
        toast({
          title: 'Transaction failed - check console for details',
          status: 'error',
          isClosable: true,
        });
      }
    } 
  }


  useEffect(() => {
      if (contract && selectedGame) {
        // Check contract initialization first
        checkContractInitialization();
        initializeContract();
        
        const fetchGameInfo = async () => {
          setLoading(true);
          try {
            const [game, ticketPrice, isActive, players, jackpot] = await Promise.all([
              contract.game(),
              contract.ticketPrice(),
              contract.isActive(),
              contract.getPlayedGamePlayers(),
              contract.getPlayedGameJackpot()
            ]);
            
            setGameInfo({
              game: game.toString(),
              ticketPrice: ethers.utils.formatEther(ticketPrice),
              isActive,
              players: players.toString(),
              jackpot: ethers.utils.formatEther(jackpot)
            });
          } catch (error) {
            console.error('Error fetching game info:', error);
          }
          setLoading(false);
        };
        
        fetchGameInfo();
      }
  },[contract, selectedGame, checkContractInitialization, initializeContract])

  // Check for referral information
  useEffect(() => {
    const referralAddress = localStorage.getItem('referralAddress');
    if (referralAddress && referralAddress !== "0x0000000000000000000000000000000000000000") {
      setReferralInfo({
        address: referralAddress,
        message: `You were referred by: ${referralAddress.substring(0, 6)}...${referralAddress.substring(38)}`
      });
    } else {
      setReferralInfo(null);
    }
  }, []);


  //enter lottery action
  const enterLotteryHandler = useCallback(async(lotteryId, ethValue) => {
    if(ethValue === "") return;
    if(!connected){
      toast({
        title: 'Please Connect to MetaMask',
        status: 'error',
        isClosable: true,
      });
      return;
    }
    
    // Check if game is active
    if(gameInfo && !gameInfo.isActive) {
      toast({
        title: 'Game is not active',
        status: 'error',
        isClosable: true,
      });
      return;
    }
    
    // Verify contract is properly initialized before attempting to buy
    try {
      const [ownableAddress, statsAddress, referralAddress, distributorAddress] = await Promise.all([
        contract.ownable(),
        contract.stats(),
        contract.referralInstance(),
        contract.fundsDistributor()
      ]);
      
      if (ownableAddress === "0x0000000000000000000000000000000000000000" ||
          statsAddress === "0x0000000000000000000000000000000000000000" ||
          referralAddress === "0x0000000000000000000000000000000000000000" ||
          distributorAddress === "0x0000000000000000000000000000000000000000") {
        toast({
          title: 'Contract not initialized',
          description: 'The lottery contract needs to be properly initialized',
          status: 'error',
          isClosable: true,
        });
        return;
      }
    } catch (error) {
      console.error('Contract verification failed:', error);
      toast({
        title: 'Contract verification failed',
        description: 'Unable to verify contract initialization',
        status: 'error',
        isClosable: true,
      });
      return;
    }
    
    // Use exact ticket price from contract
    const ticketPrice = gameInfo ? gameInfo.ticketPrice : "0.02";
    const exactPrice = ethers.utils.parseEther(ticketPrice);
    
    // Get referral address from localStorage
    const referralAddress = localStorage.getItem('referralAddress') || 
                           "0x0000000000000000000000000000000000000000";
    
    console.log('Attempting to buy ticket with:', {
      ticketPrice,
      exactPrice: exactPrice.toString(),
      isActive: gameInfo?.isActive,
      partner: referralAddress,
      userAddress: connectedAddr
    });
    
    setEntryBtnLoaders(prevS => {
      return {
        ...prevS,
        [lotteryId]: true
      }
    });
    
    try {
      console.log('Calling contract with args:', [referralAddress]);
      console.log('Value:', exactPrice.toString());
      
      const txn = await callContract({
        args: [referralAddress], // Use referral address instead of user address
        overrides: {
          value: exactPrice
        }
      });
      
      console.log('Transaction result:', txn);
      
      if(typeof txn.data !== 'undefined'){
        console.log('Transaction data:', txn.data);
        
        // Show pending transaction toast
        toast({
          title: 'Transaction submitted',
          description: '⏳ Waiting for confirmation...',
          status: 'info',
          isClosable: true,
          duration: 8000,
        });
        
        console.log('Waiting for transaction confirmation...');
        const waitResult = await wait({wait: txn.data.wait});
        console.log('Wait result:', waitResult);
        
        // If no events are detected, show a simple success message
        if (waitResult && (!waitResult.events || waitResult.events.length === 0)) {
          console.log('No events detected, showing simple success message');
          console.log('Wait result for txHash:', waitResult);
          
          // Try to get transaction hash from different sources
          let txHash = waitResult.transactionHash || waitResult.hash || txn.data.hash || txn.data.transactionHash;
          console.log('Extracted txHash:', txHash);
          console.log('txn.data:', txn.data);
          console.log('waitResult:', waitResult);
          
          if (!txHash) {
            console.error('Could not find transaction hash');
            toast({
              title: 'Transaction completed successfully!',
              description: 'Your ticket has been purchased!',
              status: 'success',
              isClosable: true,
              duration: 15000,
            });
            return;
          }
          
          // Check if this transaction has already been processed
          if (!processedTransactions.has(txHash)) {
            // Mark transaction as processed
            setProcessedTransactions(prev => new Set([...prev, txHash]));
            
            const scanUrl = `https://veryscan.io/tx/${txHash}`;
            
            console.log('Showing toast from fallback handler for transaction:', txHash);
            toast({
              title: 'Transaction completed successfully!',
              description: (
                <VStack spacing={2} align="start">
                  <Text fontSize="sm">Your ticket has been purchased!</Text>
                  <Link href={scanUrl} isExternal color="blue.500" fontWeight="bold">
                    🔍 View on Very Scan →
                  </Link>
                </VStack>
              ),
              status: 'success',
              isClosable: true,
              duration: 15000,
            });
            
            // Store transaction hash
            setTransactionHashes(prev => ({
              ...prev,
              [lotteryId]: txHash
            }));
            
            // Clear referral address after successful transaction
            localStorage.removeItem('referralAddress');
            
            // Refresh game info
            if(contract && selectedGame) {
              const fetchGameInfo = async () => {
                try {
                  const [game, ticketPrice, isActive, players, jackpot] = await Promise.all([
                    contract.game(),
                    contract.ticketPrice(),
                    contract.isActive(),
                    contract.getPlayedGamePlayers(),
                    contract.getPlayedGameJackpot()
                  ]);
                  
                  setGameInfo({
                    game: game.toString(),
                    ticketPrice: ethers.utils.formatEther(ticketPrice),
                    isActive,
                    players: players.toString(),
                    jackpot: ethers.utils.formatEther(jackpot)
                  });
                } catch (error) {
                  console.error('Error fetching game info after transaction:', error);
                }
              };
              
              fetchGameInfo();
            }
          }
          
          // Always reset button loader
          setEntryBtnLoaders(prevS => ({
            ...prevS,
            [lotteryId]: false
          }));
        }
      }
    } catch (error) {
      console.error('Buy ticket error:', error);
      // Reset button loader on error
      setEntryBtnLoaders(prevS => {
        return {
          ...prevS,
          [lotteryId]: false
        }
      });
      
      // Show error toast
      toast({
        title: 'Transaction failed',
        description: error.message || 'Failed to buy ticket',
        status: 'error',
        isClosable: true,
      });
    }
  },[connected, callContract, toast, wait, connectedAddr, gameInfo, contract]);

  //start lottery action






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
            {gameInfo ? (
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
                  lotteryId={gameInfo.game} 
                  enterLotteryHandler={enterLotteryHandler} 
                  entryBtnLoaders={entryBtnLoaders} 
                  selectedGame={selectedGame}
                  gameInfo={gameInfo}
                  loading={loading}
                  transactionHashes={transactionHashes}
                />
              </SimpleGrid>
            ) : (
              <Stack direction="row" alignItems="center" justifyContent={'center'} pt="8">
                <Text p="10">No Game Selected</Text>
              </Stack>
            )}
          </>
        )}
    </Flex>
   </>
  );
}
