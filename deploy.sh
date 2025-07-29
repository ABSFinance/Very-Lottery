#!/bin/bash

# Load Foundry environment
source ~/.zshenv

# Set your private key (replace with your actual private key)
export PRIVATE_KEY="7a59e8b8c5d7bd277e77b328caf092c5900c2c5da5c2f4462642bfa03717b055"

# Set RPC URL for network verynet
RPC_URL="https://rpc.verylabs.io"

echo "Deploying Cryptolotto contracts to network verynet..."

# Deploy Ownable
echo "Deploying Ownable..."
OWNABLE=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast contracts/Ownable.sol:Ownable)
echo "Ownable deployed at: $OWNABLE"

# Deploy Referral
echo "Deploying CryptolottoReferral..."
REFERRAL=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast contracts/CryptolottoReferral.sol:CryptolottoReferral --constructor-args $OWNABLE)
echo "Referral deployed at: $REFERRAL"

# Deploy Stats Aggregator
echo "Deploying StatsAggregator..."
STATS=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast contracts/StatsAggregator.sol:StatsAggregator)
echo "Stats deployed at: $STATS"

# Deploy Funds Distributor
echo "Deploying FundsDistributor..."
DISTRIBUTOR=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast contracts/FundsDistributor.sol:FundsDistributor)
echo "Distributor deployed at: $DISTRIBUTOR"

# Deploy Cryptolotto7Days
echo "Deploying Cryptolotto7Days..."
GAME7DAYS=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast contracts/games/Cryptolotto7Days.sol:Cryptolotto7Days --constructor-args $OWNABLE $DISTRIBUTOR $STATS $REFERRAL)
echo "Cryptolotto7Days deployed at: $GAME7DAYS"

# Deploy Cryptolotto1Day
echo "Deploying Cryptolotto1Day..."
GAME1DAY=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast contracts/games/Cryptolotto1Day.sol:Cryptolotto1Day --constructor-args $OWNABLE $DISTRIBUTOR $STATS $REFERRAL)
echo "Cryptolotto1Day deployed at: $GAME1DAY"

echo "Deployment completed!"
echo "Contract addresses:"
echo "Ownable: $OWNABLE"
echo "Referral: $REFERRAL"
echo "Stats: $STATS"
echo "Distributor: $DISTRIBUTOR"
echo "Cryptolotto7Days: $GAME7DAYS"
echo "Cryptolotto1Day: $GAME1DAY" 