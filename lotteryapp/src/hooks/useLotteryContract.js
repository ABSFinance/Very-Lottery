import { useCallback, useMemo } from 'react';
import * as wagmi from 'wagmi';
import {useProvider, useSigner,} from 'wagmi';
import {useDispatch} from 'react-redux';
import {ethers} from 'ethers';
import { startAction, stopAction, errorAction } from '../redux/reducers/uiActions';
import { 
    FETCHING_LOTTERY_DETAIL,
    FETCHING_LOTTERY_DETAIL_SUCCESS,
    FETCHING_ALLOWED_COUNT, 
    FETCHING_ALLOWED_COUNT_SUCCESS,
    FETCH_LOTTERY_MANAGER,
    FETCH_LOTTERY_MANAGER_SUCCESS,
    FETCH_LOTTERY_IDS,
    FETCH_LOTTERY_IDS_SUCCESS

} from '../redux/actionConstants';


const useLotteryContract = (contractAddress = null) => {
    const  dispatch = useDispatch();

    const [signer] = useSigner();

    const provider = useProvider();

    // Use provided contract address
    const address = contractAddress || "0x0000000000000000000000000000000000000000";

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
        addressOrName: address,
        contractInterface: contractInterface,
        signerOrProvider: signer.data || provider
    }), [address, signer.data, provider]);

    const contract = wagmi.useContract(contractConfig);


      
    const getLotteryDetail = useCallback(async(_lotteryId) => {
        dispatch(startAction(FETCHING_LOTTERY_DETAIL));
        try {
            const data = await contract.getLotteryDetails(_lotteryId);
        
            dispatch({
                type:FETCHING_LOTTERY_DETAIL_SUCCESS,
                payload: {
                    id: _lotteryId,
                    data :{
                        ticketPrice: ethers.utils.formatEther(data[1].toString()),
                        pricePool: ethers.utils.formatEther(data[2].toString()),
                        players: data[3].length,
                        playersData: data[3],
                        winner: data[4],
                        active: data[5]
                    }
                }
            });
        } catch (e) {
            console.log('error fetching lottery detail', e);
            dispatch(errorAction(FETCHING_LOTTERY_DETAIL, 'Error while fetching allowed count'));
        }
        dispatch(stopAction(FETCHING_LOTTERY_DETAIL))

    },[contract, dispatch])

    const getLotteryAllowedCount = useCallback(async() => {
        dispatch(startAction(FETCHING_ALLOWED_COUNT));
        try {
            const allowedPlayerCount = await contract.totalAllowedPlayers();
            dispatch({
                type:FETCHING_ALLOWED_COUNT_SUCCESS,
                payload: allowedPlayerCount.toString()
            });
        } catch (e) {
            console.log('fetching lottery allowed count failed', e);
            dispatch(errorAction(FETCHING_ALLOWED_COUNT, 'Error while fetching allowed count'));
        }
        dispatch(stopAction(FETCHING_ALLOWED_COUNT))

    },[contract, dispatch])

    const getLotteryManagerAddress = useCallback(async() => {
        dispatch(startAction(FETCH_LOTTERY_MANAGER));
        try {
            const manager = await contract.lotteryManager();
            dispatch({
                type:FETCH_LOTTERY_MANAGER_SUCCESS,
                payload: manager
            });
        } catch (e) {
            console.log('fetching lottery manager failed', e);
            dispatch(errorAction(FETCH_LOTTERY_MANAGER, 'Error while fetching lottery manager'));
        }
        dispatch(stopAction(FETCH_LOTTERY_MANAGER))
    },[contract, dispatch])

    const fetchAllLotteryIds = useCallback(async () => {
        dispatch(startAction(FETCH_LOTTERY_IDS));
        try{
            const lotteries = await contract.getAllLotteryIds();
            dispatch({
                type:FETCH_LOTTERY_IDS_SUCCESS,
                payload: lotteries
            });
        }catch(e){
            console.log('fetching all lotteryIds failed', e);
            dispatch(errorAction(FETCH_LOTTERY_IDS, 'Error while fetching all lotteryIds'));

        }
        dispatch(stopAction(FETCH_LOTTERY_IDS))
    },[contract, dispatch]);



    return {
        contract,
        fetchAllLotteryIds,
        getLotteryManagerAddress,
        getLotteryAllowedCount,
        getLotteryDetail
    }
}

export default useLotteryContract;