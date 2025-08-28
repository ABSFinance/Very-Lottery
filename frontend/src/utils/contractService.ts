import { ethers } from 'ethers';
import { getGameContractInfo, CONTRACT_ABIS, CONTRACT_ADDRESSES, GameType } from './contracts';

export class ContractService {
  private provider: ethers.BrowserProvider | null = null;

  constructor(provider?: ethers.BrowserProvider) {
    this.provider = provider || null;
  }

  setProvider(provider: ethers.BrowserProvider) {
    this.provider = provider;
  }

  // Get contract instance for a specific game type
  getGameContract(gameType: GameType) {
    if (!this.provider) {
      throw new Error('Provider not set');
    }

    const contractInfo = getGameContractInfo(gameType);
    return new ethers.Contract(contractInfo.address, contractInfo.abi, this.provider);
  }

  // Get contract instance by contract name
  getContract(contractName: keyof typeof CONTRACT_ABIS) {
    if (!this.provider) {
      throw new Error('Provider not set');
    }

    const address = CONTRACT_ADDRESSES[contractName];
    const abi = CONTRACT_ABIS[contractName];
    
    return new ethers.Contract(address, abi, this.provider);
  }

  // Get contract instance with signer for transactions
  getGameContractWithSigner(gameType: GameType, signer: ethers.Signer) {
    const contractInfo = getGameContractInfo(gameType);
    return new ethers.Contract(contractInfo.address, contractInfo.abi, signer);
  }

  // Get contract instance with signer by contract name
  getContractWithSigner(contractName: keyof typeof CONTRACT_ABIS, signer: ethers.Signer) {
    const address = CONTRACT_ADDRESSES[contractName];
    const abi = CONTRACT_ABIS[contractName];
    
    return new ethers.Contract(address, abi, signer);
  }

  // Example: Get current game jackpot
  async getCurrentGameJackpot(gameType: GameType): Promise<string> {
    try {
      const contract = this.getGameContract(gameType);
      const jackpot = await contract.getPlayedGameJackpot();
      return ethers.formatEther(jackpot);
    } catch (error) {
      console.error('Error getting jackpot:', error);
      return '0';
    }
  }

  // Example: Get ticket price
  async getTicketPrice(gameType: GameType): Promise<string> {
    try {
      const contract = this.getGameContract(gameType);
      const price = await contract.ticketPrice();
      return ethers.formatEther(price);
    } catch (error) {
      console.error('Error getting ticket price:', error);
      return '0';
    }
  }

  // Example: Get current game players count
  async getCurrentGamePlayers(gameType: GameType): Promise<number> {
    try {
      const contract = this.getGameContract(gameType);
      const players = await contract.getPlayedGamePlayers();
      return Number(players);
    } catch (error) {
      console.error('Error getting players count:', error);
      return 0;
    }
  }

  // Example: Check if game is active
  async isGameActive(gameType: GameType): Promise<boolean> {
    try {
      const contract = this.getGameContract(gameType);
      const gameConfig = await contract.getGameConfig();
      return gameConfig[3]; // isActive is the 4th element
    } catch (error) {
      console.error('Error checking game status:', error);
      return false;
    }
  }

  // Example: Buy ticket (for reference - actual implementation uses wepin)
  async buyTicket(gameType: GameType, signer: ethers.Signer, referrer: string, value: string) {
    try {
      const contract = this.getGameContractWithSigner(gameType, signer);
      const tx = await contract.buyTicket(referrer, { value });
      return await tx.wait();
    } catch (error) {
      console.error('Error buying ticket:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const contractService = new ContractService(); 