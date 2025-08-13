import { useContractWrite, useWaitForTransaction } from 'wagmi';
import { useMemo } from 'react';

const useLotteryAction = (funcName, contractAddress = null) => {    

    // Cryptolotto contract interface - updated for new contract structure
    const contractInterface = [
        // Game functions
        "function buyTicket(address referrer, uint256 ticketCount) payable",
        "function getCurrentGameNumber() view returns (uint256)",
        "function getCurrentGamePlayerCount() view returns (uint256)",
        "function getCurrentGameJackpot() view returns (uint256)",
        "function getCurrentGameState() view returns (uint8)",
        "function getRemainingGameTime() view returns (uint256)",
        "function getCurrentGameEndTime() view returns (uint256)",
        "function getGameConfig() view returns (uint256 ticketPrice, uint256 gameDuration, uint256 maxTicketsPerPlayer, bool isActive)",
        "function getPlayerInfo(address player) view returns (uint256 ticketCount, uint256 lastPurchaseTime, uint256 totalSpent)",
        "function getContractBalance() view returns (uint256)",
        
        // Admin functions
        "function emergencyPause(string memory reason)",
        "function emergencyResume()",
        "function setTestMode(bool enabled)",
        "function setPurchaseCooldown(uint256 newCooldown)",
        "function resetPlayerCooldown(address player)",
        "function setRegistry(address registryAddress)",
        "function setTreasuryName(string memory _treasuryName)",
        
        // Game state functions
        "function checkAndEndGame()",
        "function autoEndGame()",
        "function isGameTimeExpired() view returns (bool)",
        "function getGameInfo() view returns (uint256 currentGameNumber, uint256 startTime, uint256 duration, uint256 remainingTime, bool timeExpired, uint256 playerCount, uint256 currentJackpot)",
        
        // Events
        "event TicketPurchased(address indexed player, uint256 indexed gameNumber, uint256 ticketIndex, uint256 timestamp)",
        "event WinnerSelected(address indexed winner, uint256 indexed gameNumber, uint256 jackpot, uint256 playerCount, uint256 timestamp)",
        "event GameEnded(uint256 indexed gameNumber, uint256 totalPlayers, uint256 totalJackpot, uint256 timestamp)",
        "event EmergencyPaused(address indexed by, string reason, uint256 timestamp)",
        "event EmergencyResumed(address indexed by, uint256 timestamp)"
    ];

    const contractConfig = useMemo(() => ({
        addressOrName: contractAddress,
        contractInterface: contractInterface
    }), [contractAddress]);

    const [{ data, error, loading }, write] = useContractWrite(
        contractConfig,
        funcName
    );

    const [{data:waitData, error:waitError, loading:waitLoading}, wait] = useWaitForTransaction({
        skip: true
    });
    
    return {
        txnData: data,
        txnError: error, 
        txnLoading: loading, 
        callContract: write,
        waitData,
        waitError,
        waitLoading,
        wait
    }
};

export default useLotteryAction;