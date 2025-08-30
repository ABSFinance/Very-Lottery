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

// Add localStorage persistence
const STORAGE_KEY = 'wepin_global_state';

// Helper functions for localStorage
const saveToStorage = (state: any) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (error) {
    console.warn('Failed to save to localStorage:', error);
  }
};

const loadFromStorage = () => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : null;
  } catch (error) {
    console.warn('Failed to load from localStorage:', error);
    return null;
  }
};

// Load initial state from localStorage
const initializeFromStorage = () => {
  const storedState = loadFromStorage();
  if (storedState) {
    globalLoginState = storedState.loginState || null;
    // Note: We don't restore Wepin instances from storage as they need to be re-initialized
    console.log('🌍 Restored login state from localStorage:', globalLoginState);
  }
};

// Initialize on module load
initializeFromStorage();

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
  // Persist to localStorage
  saveToStorage({ loginState: state });
  console.log("🌍 Global login state set and persisted:", state);
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
  // Remove from localStorage
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch (error) {
    console.warn('Failed to remove from localStorage:', error);
  }
  console.log("🌍 Global Wepin state cleared and removed from storage");
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

// Check if user should be auto-logged in based on stored state
export const shouldAutoLogin = (): boolean => {
  const storedState = loadFromStorage();
  return !!(storedState?.loginState?.isLoggedIn && storedState?.loginState?.userInfo);
};

// Get stored user info for auto-login
export const getStoredUserInfo = () => {
  const storedState = loadFromStorage();
  return storedState?.loginState?.userInfo || null;
};

// Force refresh login state from storage
export const refreshLoginStateFromStorage = () => {
  const storedState = loadFromStorage();
  if (storedState?.loginState) {
    globalLoginState = storedState.loginState;
    console.log('🔄 Refreshed login state from storage:', globalLoginState);
    notifyStateChange();
    return true;
  }
  return false;
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