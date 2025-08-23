import React from "react";
import ReactDOM from "react-dom";
import { ColorModeScript, ChakraProvider } from "@chakra-ui/react";
import App from "./App";
import { providers } from "ethers";
import { Provider as WagmiProvider, defaultChains } from "wagmi";
import { AccountProvider } from "./context/AccountContext";
import { InjectedConnector } from 'wagmi/connectors/injected'
import {Provider as RProvider} from 'react-redux';
import store from "./redux/store";

// Provider that will be used when no wallet is connected (aka no signer)
const provider = new providers.JsonRpcProvider(
  process.env.REACT_APP_RPC_URL || 'https://rpc.verylabs.io',
  {
    name: 'Verychain',
    chainId: 4613
  }
);

// Validate that we're connected to the right network
provider.getNetwork().then(network => {
  if (network.chainId !== 4613) {
    console.error(`❌ WRONG NETWORK DETECTED: ${network.chainId}, expected 4613 (Verychain)`);
    console.error('Please ensure you are connected to Verychain network');
  } else {
    console.log('✅ Connected to Verychain network (Chain ID: 4613)');
  }
}).catch(error => {
  console.error('❌ Failed to get network information:', error);
});

// Define Verychain network configuration
const verychainNetwork = {
  id: 4613,
  name: 'Verychain',
  network: 'verychain',
  nativeCurrency: {
    decimals: 18,
    name: 'VERY',
    symbol: 'VERY',
  },
  rpcUrls: {
    default: process.env.REACT_APP_RPC_URL || 'https://rpc.verylabs.io',
  },
  blockExplorers: {
    default: { name: 'VeryScan', url: 'https://veryscan.io' },
  },
};

const connector = [
  new InjectedConnector({
    chains: [verychainNetwork],
    //options: { shimDisconnect: true }
  })
]


ReactDOM.render(
  <React.StrictMode>
    <WagmiProvider /* autoConnect */ provider={provider} connectors={connector}>
      <AccountProvider>
        <RProvider store={store}>
          <ChakraProvider>
            <ColorModeScript initialColorMode="light"></ColorModeScript>
            <App />
          </ChakraProvider>
        </RProvider>
      </AccountProvider>
    </WagmiProvider>
  </React.StrictMode>,
  document.getElementById("root")
);
