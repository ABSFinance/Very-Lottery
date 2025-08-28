# Ticket Purchase Refactoring

This document explains how the `handlePurchase` function was refactored from the `VeryLucky.tsx` component into a separate service.

## What Was Refactored

### Before: Complex handlePurchase in VeryLucky.tsx

The original `handlePurchase` function was:

- **250+ lines** of complex logic
- Mixed concerns (UI state, business logic, error handling)
- Hard to test and maintain
- Difficult to reuse in other components

### After: Clean Service-Based Architecture

- **TicketPurchaseService**: Handles all purchase logic
- **VeryLucky.tsx**: Only handles UI state and calls the service
- **Separation of concerns**: Business logic separated from UI logic
- **Reusable**: Can be used by any component

## New File Structure

```
src/
├── utils/
│   ├── ticketPurchaseService.ts     # New: Purchase business logic
│   └── README_Refactoring.md        # This file
├── components/
│   ├── TicketPurchasePopup.tsx      # Ticket purchase popup
│   ├── VeryLuckyWithPurchase.tsx   # Wrapper with popup integration
│   └── PromoLuckyCardWithPurchase.tsx # Card with popup
└── screens/
    └── Games/
        └── VeryLucky.tsx            # Refactored: Simplified handlePurchase
```

## How to Use

### Option 1: Use the Service Directly

```typescript
import { TicketPurchaseService } from "../utils/ticketPurchaseService";

const handlePurchase = async () => {
  const result = await TicketPurchaseService.purchaseTicket({
    gameType: "daily-lucky",
    isLoggedIn: true,
    account: "0x...",
    wepin: wepinInstances,
    veryNetworkProvider: provider,
    contractInfo: contractInfo,
  });

  if (result.success) {
    console.log("Purchase successful:", result.transactionId);
  } else {
    console.error("Purchase failed:", result.error);
  }
};
```

### Option 2: Use the Popup Component

```typescript
import {
  TicketPurchasePopup,
  TicketInfo,
} from "../components/TicketPurchasePopup";

const [isPopupOpen, setIsPopupOpen] = useState(false);
const [selectedTicket, setSelectedTicket] = useState<TicketInfo | null>(null);

const ticket: TicketInfo = {
  id: "daily-lucky",
  name: "Daily LUCKY",
  price: 1,
  maxQuantity: 100,
  deadline: "매일",
};

return (
  <TicketPurchasePopup
    isOpen={isPopupOpen}
    onClose={() => setIsPopupOpen(false)}
    onPurchase={handlePurchase}
    ticket={ticket}
    userBalance={5000}
  />
);
```

### Option 3: Use the Wrapper Component

```typescript
import { VeryLuckyWithPurchase } from "../components/VeryLuckyWithPurchase";

// This automatically includes the ticket purchase popup
<VeryLuckyWithPurchase gameType="daily-lucky" userBalance={5000} />;
```

## Benefits of the Refactoring

### 1. **Maintainability**

- Purchase logic is centralized in one place
- Easier to update business rules
- Clear separation of concerns

### 2. **Testability**

- Service can be unit tested independently
- UI logic can be tested separately
- Mock the service for component testing

### 3. **Reusability**

- Service can be used by multiple components
- Popup can be used anywhere in the app
- Consistent purchase experience across the app

### 4. **Error Handling**

- Centralized error handling in the service
- Consistent error messages
- Better error categorization

### 5. **Code Organization**

- Smaller, focused functions
- Easier to understand and debug
- Better adherence to Single Responsibility Principle

## Integration with Existing Code

### Current VeryLucky.tsx

The component now has a much simpler `handlePurchase`:

```typescript
const handlePurchase = async () => {
  setIsProcessingPurchase(true);

  try {
    const result = await TicketPurchaseService.purchaseTicket({
      gameType,
      isLoggedIn,
      account,
      wepin,
      veryNetworkProvider,
      contractInfo,
    });

    if (result.success) {
      alert(`티켓 구매 성공! 트랜잭션 ID: ${result.transactionId}`);
      // Refresh ticket count...
    } else {
      alert(`티켓 구매 실패: ${result.error}`);
    }
  } catch (error) {
    console.error("Unexpected error:", error);
    alert("티켓 구매 중 예상치 못한 오류가 발생했습니다.");
  } finally {
    setIsProcessingPurchase(false);
  }
};
```

### Adding the Popup to Existing Components

To add the ticket purchase popup to your existing components:

1. **Import the popup**:

   ```typescript
   import {
     TicketPurchasePopup,
     TicketInfo,
   } from "../components/TicketPurchasePopup";
   ```

2. **Add state**:

   ```typescript
   const [isPopupOpen, setIsPopupOpen] = useState(false);
   const [selectedTicket, setSelectedTicket] = useState<TicketInfo | null>(
     null
   );
   ```

3. **Add the popup to your JSX**:
   ```typescript
   {
     selectedTicket && (
       <TicketPurchasePopup
         isOpen={isPopupOpen}
         onClose={() => setIsPopupOpen(false)}
         onPurchase={handlePurchase}
         ticket={selectedTicket}
         userBalance={userBalance}
       />
     );
   }
   ```

## Migration Guide

### Step 1: Replace handlePurchase

Replace your existing `handlePurchase` function with a call to the service.

### Step 2: Add Popup (Optional)

If you want the popup UI, add the `TicketPurchasePopup` component.

### Step 3: Update Imports

Remove unused imports and add the new service import.

### Step 4: Test

Test the purchase flow to ensure everything works correctly.

## Future Enhancements

The service-based architecture makes it easy to add new features:

- **Multiple payment methods**
- **Bulk purchase discounts**
- **Purchase history tracking**
- **Referral system integration**
- **Analytics and monitoring**

## Troubleshooting

### Common Issues

1. **Import errors**: Make sure all imports are correct
2. **Type errors**: Check that your data matches the expected interfaces
3. **Service not found**: Verify the service file path is correct

### Debug Mode

The service includes extensive logging. Check the console for detailed information about the purchase process.

## Support

If you encounter issues with the refactored code:

1. Check the console logs for error details
2. Verify all imports and dependencies
3. Ensure your data structures match the expected interfaces
4. Test with the demo components first
