import React from "react";
import { useSelector } from "react-redux";
import { Box, VStack, Heading, Text, Badge, Button } from "@chakra-ui/react";
import LotteryListing from "./LotteryListing";
import LotteryStats from "./LotteryStats";
import ReferralSystem from "./ReferralSystem";

const LotteryDashBoard = ({ selectedGame }) => {
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
            <Box display="flex" gap={4} flexWrap="wrap">
              <Badge colorScheme="green" p={2} borderRadius="md">
                Price: {selectedGame.price}
              </Badge>
              <Badge colorScheme="blue" p={2} borderRadius="md">
                Duration: {selectedGame.duration}
              </Badge>
              <Badge colorScheme="purple" p={2} borderRadius="md">
                Contract: {selectedGame.contract}
              </Badge>
            </Box>
            <Text color="gray.600" textAlign="center">
              Ready to play? Buy your ticket and join the game!
            </Text>
          </VStack>
        </Box>
      )}

      {/* Referral System */}
      <ReferralSystem />

      {/* Lottery Stats */}
      <LotteryStats selectedGame={selectedGame} />

      {/* Lottery Listing */}
      <LotteryListing selectedGame={selectedGame} />
    </VStack>
  );
};

export default LotteryDashBoard;
