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

    // Cryptolotto contract interface - actual functions
    const contractInterface = [
        "function game() view returns (uint)",
        "function ticketPrice() view returns (uint)",
        "function isActive() view returns (bool)",
        "function getPlayedGamePlayers() view returns (uint)",
        "function getPlayedGameJackpot() view returns (uint)",
        "function getPlayersInGame(uint) view returns (uint)",
        "function getGameJackpot(uint) view returns (uint)",
        "function buyTicket(address) payable",
        "function start()",
        "function toogleActive()",
        "function changeTicketPrice(uint)",
        "function ownable() view returns (address)",
        "function stats() view returns (address)",
        "function referralInstance() view returns (address)",
        "function fundsDistributor() view returns (address)",
        "event Ticket(address indexed _address, uint indexed _game, uint _number, uint _time)",
        "event Game(uint _game, uint indexed _time)"
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