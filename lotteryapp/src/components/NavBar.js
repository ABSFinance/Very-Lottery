import React, { useEffect } from "react";
import {
  Box,
  Flex,
  VStack,
  Button,
  Badge,
  Image,
  Spacer,
  useToast,
  HStack
} from "@chakra-ui/react";
import logo from "../eth-bg.png";
import { useMetaMaskAccount } from "../context/AccountContext";

const NavBar = ({ onViewChange, currentView }) => {
  const toast = useToast();
  const { connectedAddr, connected, connectToMetaMask, disconnect, loading, netWorkName, accountErrorMessage } =
    useMetaMaskAccount();

  useEffect(() => {
    if(accountErrorMessage !== ""){
      toast({
        title: accountErrorMessage,
        position: 'bottom-right',
        isClosable: true,
      })
    }
  },[toast, accountErrorMessage]);

  const navItems = [
    { key: 'games', label: '🎮 Games', color: 'blue' },
    { key: 'lottery', label: '🎯 Lottery', color: 'green' },
    { key: 'referrals', label: '🔗 Referrals', color: 'purple' }
  ];

  return (
    <VStack p={3}>
      <Flex w="100%" align="center">
        <Box w="100%" p={4} color="white">
          <Image src={logo} htmlWidth="300px" /> 
        </Box>
        <Spacer />
        
        {/* Navigation Menu */}
        <HStack spacing={4} mr={4}>
          {navItems.map((item) => (
            <Button
              key={item.key}
              size="sm"
              colorScheme={item.color}
              variant={currentView === item.key ? "solid" : "outline"}
              onClick={() => onViewChange(item.key)}
              _hover={{
                transform: "translateY(-2px)",
                boxShadow: "lg"
              }}
              transition="all 0.3s"
            >
              {item.label}
            </Button>
          ))}
        </HStack>

        {/* Account Info */}
        <Box p={5}>
          <Badge colorScheme="green">{connectedAddr}</Badge>
        </Box>
        
        <Box p={3} color="white">
          {!connected ? (
            <Button
              size="sm"
              colorScheme="blue"
              onClick={connectToMetaMask}
              isLoading={loading}
            >
              Connect to MetaMask
            </Button>
          ) : (
            <Button
              size="sm"
              colorScheme="red"
              onClick={disconnect}
              isLoading={loading}
            >
              {(netWorkName !== "") && (netWorkName)} Disconnect
            </Button>
          )}
        </Box>
      </Flex>
    </VStack>
  );
};

export default NavBar;
