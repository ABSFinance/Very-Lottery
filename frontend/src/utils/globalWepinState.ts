import { WepinSDKLike, WepinLoginLike, WepinProviderLike, WepinInstances } from './wepin';

// Global Wepin instances state
let globalWepinInstances: WepinInstances | null = null;
let globalLoginState: {
  isLoggedIn: boolean;
  userInfo: any;
  walletAddress: string | null;
} | null = null;

// Event listeners for state changes
const stateChangeListeners: Array<() => void> = [];

// Notify all listeners of state changes
const notifyStateChange = () => {
  stateChangeListeners.forEach(listener => listener());
};

// Set global Wepin instances
export const setGlobalWepinInstances = (instances: WepinInstances) => {
  globalWepinInstances = instances;
  console.log("🌍 Global Wepin instances set:", instances);
  notifyStateChange();
};

// Get global Wepin instances
export const getGlobalWepinInstances = (): WepinInstances | null => {
  return globalWepinInstances;
};

// Set global login state
export const setGlobalLoginState = (state: {
  isLoggedIn: boolean;
  userInfo: any;
  walletAddress: string | null;
}) => {
  globalLoginState = state;
  console.log("🌍 Global login state set:", state);
  notifyStateChange();
};

// Get global login state
export const getGlobalLoginState = () => {
  return globalLoginState;
};

// Clear global state (for logout)
export const clearGlobalWepinState = () => {
  globalWepinInstances = null;
  globalLoginState = null;
  console.log("🌍 Global Wepin state cleared");
  notifyStateChange();
};

// Check if global instances are available
export const areGlobalWepinInstancesAvailable = (): boolean => {
  return !!globalWepinInstances?.sdk && !!globalWepinInstances?.provider;
};

// Subscribe to state changes
export const subscribeToWepinStateChanges = (listener: () => void) => {
  stateChangeListeners.push(listener);
  
  // Return unsubscribe function
  return () => {
    const index = stateChangeListeners.indexOf(listener);
    if (index > -1) {
      stateChangeListeners.splice(index, 1);
    }
  };
};

// Initialize global state from existing instances (if any)
export const initializeGlobalStateFromExisting = () => {
  // Try to get from localStorage or other sources if needed
  console.log("🌍 Initializing global state from existing sources");
};

// Get a specific component from global instances
export const getGlobalWepinSDK = (): WepinSDKLike | null => {
  return globalWepinInstances?.sdk || null;
};

export const getGlobalWepinLogin = (): WepinLoginLike | null => {
  return globalWepinInstances?.login || null;
};

export const getGlobalWepinProvider = (): WepinProviderLike | null => {
  return globalWepinInstances?.provider || null;
}; 