import {useEffect, useState} from 'react';
import {
    Box,
    Flex,
    SimpleGrid,
    Stat,
    StatLabel,
    StatNumber,
    useColorModeValue
  } from '@chakra-ui/react';

import useLotteryContract from "../hooks/useLotteryContract";
import { ethers } from 'ethers';

  function StatsCard(props) {
    const { title, stat } = props;
    return (
      <Stat
        px={{ base: 2, md: 4 }}
        py={'5'}
        shadow={'xl'}
        border={'1px solid'}
        borderColor={useColorModeValue('gray.800', 'gray.500')}
        rounded={'lg'}>
        <Flex justifyContent={'space-between'}>
          <Box pl={{ base: 2, md: 4 }}>
            <StatLabel fontWeight={'bold'} isTruncated>
              {title}
            </StatLabel>
            <StatNumber fontSize={'sm'} fontWeight={'medium'} isTruncated>
              {stat}
            </StatNumber>
          </Box>
        </Flex>
      </Stat>
    );
  }
  
  export default function LotteryStats({ selectedGame }) {  
    const contractAddress = selectedGame?.address;
    const { contract } = useLotteryContract(contractAddress);
    const [gameInfo, setGameInfo] = useState(null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
      let isMounted = true;
      
      if (contract && selectedGame) {
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
            
            if (isMounted) {
              setGameInfo({
                game: game.toString(),
                ticketPrice: ethers.utils.formatEther(ticketPrice),
                isActive,
                players: players.toString(),
                jackpot: ethers.utils.formatEther(jackpot)
              });
            }
          } catch (error) {
            console.error('Error fetching game info:', error);
          }
          if (isMounted) {
            setLoading(false);
          }
        };
        
        fetchGameInfo();
      }
      
      return () => {
        isMounted = false;
      };
    }, [contract, selectedGame]);


    return (
      <>
        <Box maxW="7xl" mx={'auto'} pt={5} px={{ base: 2, sm: 12, md: 17 }}>
          <SimpleGrid columns={{ base: 1, md: 3 }} spacing={{ base: 5, lg: 8 }}>
            <StatsCard
              title={'Current Game'}
              stat={loading ? 'Loading...' : (gameInfo?.game || 'N/A')}
            />
            <StatsCard
              title={'Ticket Price'}
              stat={loading ? 'Loading...' : (gameInfo?.ticketPrice ? `${gameInfo.ticketPrice} VERY` : 'N/A')}
            />
            <StatsCard
              title={'Active Players'}
              stat={loading ? 'Loading...' : (gameInfo?.players || 'N/A')}
            />
            <StatsCard
              title={'Current Jackpot'}
              stat={loading ? 'Loading...' : (gameInfo?.jackpot ? `${gameInfo.jackpot} VERY` : 'N/A')}
            />
            <StatsCard
              title={'Game Status'}
              stat={loading ? 'Loading...' : (gameInfo?.isActive ? 'Active' : 'Inactive')}
            />
            <StatsCard
              title={'Contract Address'}
              stat={selectedGame?.address || 'N/A'}
            />
          </SimpleGrid>
        </Box>
      </>
    );
  }