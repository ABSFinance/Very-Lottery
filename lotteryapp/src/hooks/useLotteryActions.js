import { useContractWrite, useWaitForTransaction } from 'wagmi';
import { useMemo } from 'react';

const useLotteryAction = (funcName, contractAddress = null) => {    

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