# Ticket Purchase Popup Components

This directory contains components for implementing a ticket purchase popup system that matches the design requirements.

## Components

### 1. TicketPurchasePopup

The main popup component that displays when a user wants to purchase tickets.

**Features:**

- ✅ Main title: "티켓을 구매하시겠습니까?"
- ✅ Subtitle: Raffle name
- ✅ Ticket image with stars and "TICKET" text
- ✅ Quantity selector with +/- buttons
- ✅ Clickable quantity display that opens number input pad
- ✅ Purchase button with dynamic VERY amount
- ✅ User balance display
- ✅ Error handling with priority: validation > insufficient balance > network/server
- ✅ Korean error messages as specified

**Props:**

```typescript
interface TicketPurchasePopupProps {
  isOpen: boolean;
  onClose: () => void;
  onPurchase: (ticketId: string, quantity: number) => Promise<void>;
  ticket: TicketInfo;
  userBalance: number;
}
```

### 2. useTicketPurchase Hook

Custom hook for managing ticket purchase state and logic.

**Returns:**

```typescript
{
  isPopupOpen: boolean;
  selectedTicket: TicketInfo | null;
  isLoading: boolean;
  openPurchasePopup: (ticket: TicketInfo) => void;
  closePurchasePopup: () => void;
  handlePurchase: (ticketId: string, quantity: number) => Promise<void>;
}
```

### 3. PromoLuckyCardWithPurchase

Enhanced version of PromoLuckyCard that integrates with the purchase popup.

### 4. TicketPurchaseDemo

Demo component showing how to use the popup system.

## Usage Examples

### Basic Usage

```typescript
import { TicketPurchasePopup, TicketInfo } from "./TicketPurchasePopup";

const MyComponent = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [userBalance, setUserBalance] = useState(5000);

  const ticket: TicketInfo = {
    id: "daily-lucky",
    name: "Daily LUCKY",
    price: 1,
    maxQuantity: 100,
    deadline: "매일",
  };

  const handlePurchase = async (ticketId: string, quantity: number) => {
    // Your purchase logic here
    console.log(`Buying ${quantity} tickets for ${ticketId}`);
  };

  return (
    <TicketPurchasePopup
      isOpen={isOpen}
      onClose={() => setIsOpen(false)}
      onPurchase={handlePurchase}
      ticket={ticket}
      userBalance={userBalance}
    />
  );
};
```

### Using the Hook

```typescript
import { useTicketPurchase } from "../hooks/useTicketPurchase";

const MyComponent = () => {
  const userBalance = 5000;
  const {
    isPopupOpen,
    selectedTicket,
    openPurchasePopup,
    closePurchasePopup,
    handlePurchase,
  } = useTicketPurchase(userBalance);

  const handleCardClick = () => {
    const ticket: TicketInfo = {
      id: "daily-lucky",
      name: "Daily LUCKY",
      price: 1,
      maxQuantity: 100,
      deadline: "매일",
    };
    openPurchasePopup(ticket);
  };

  return (
    <>
      <button onClick={handleCardClick}>Buy Tickets</button>

      {selectedTicket && (
        <TicketPurchasePopup
          isOpen={isPopupOpen}
          onClose={closePurchasePopup}
          onPurchase={handlePurchase}
          ticket={selectedTicket}
          userBalance={userBalance}
        />
      )}
    </>
  );
};
```

### Integration with Existing Cards

```typescript
import { PromoLuckyCardWithPurchase } from "./PromoLuckyCardWithPurchase";

const MyScreen = () => {
  const userBalance = 5000;

  return (
    <PromoLuckyCardWithPurchase
      userBalance={userBalance}
      onSelect={() => console.log("Card selected")}
    />
  );
};
```

## Error Handling

The popup handles errors in the following priority order:

1. **Validation Errors**: Invalid quantity
2. **Insufficient Balance**: User doesn't have enough VERY
3. **Network/Server Errors**: Connection or server issues

Error messages are displayed in Korean as specified:

- "잔액이 부족합니다." (Insufficient balance)
- "일시적인 오류로 결제에 실패했어요. 다시 시도해주세요." (Network error)
- "가격이 변경되어 총액을 업데이트했어요." (Price change)

## Styling

The popup uses the exact colors and styling from your requirements:

- Background: `#282828` (dark gray)
- Purchase button: `#F07878` (reddish-pink)
- Text: White for main content, gray for secondary
- Rounded corners and modern UI elements

## Smart Contract Integration

To integrate with your smart contracts, modify the `handlePurchase` function in the hook:

```typescript
const handlePurchase = async (ticketId: string, quantity: number) => {
  try {
    // Call your smart contract function
    const result = await contract.purchaseTicket(ticketId, quantity);

    // Handle success
    return result;
  } catch (error) {
    // Handle contract errors
    throw error;
  }
};
```

## Customization

You can easily customize:

- Ticket images by passing an `image` URL in the `TicketInfo`
- Maximum quantities per ticket type
- Price per ticket
- Deadline text
- Error messages
- Styling and colors
