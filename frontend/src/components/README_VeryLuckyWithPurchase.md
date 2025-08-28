# VeryLuckyWithPurchase Component

This component is a wrapper around the existing `VeryLucky` component that adds ticket purchase functionality with a beautiful popup interface.

## Features

✅ **Automatic Game Configuration**: Uses the actual game config from your contracts  
✅ **Smart Purchase Button**: Only shows for paid games, uses game colors  
✅ **Integrated Popup**: Beautiful ticket purchase interface  
✅ **Flexible Integration**: Easy to customize and extend  
✅ **Callbacks**: Success and error handling callbacks

## Basic Usage

```typescript
import { VeryLuckyWithPurchase } from "../components/VeryLuckyWithPurchase";

// Simple usage with default settings
<VeryLuckyWithPurchase gameType="daily-lucky" userBalance={5000} />;
```

## Advanced Usage

```typescript
import { VeryLuckyWithPurchase } from "../components/VeryLuckyWithPurchase";

const MyComponent = () => {
  const handlePurchaseSuccess = (ticketId: string, quantity: number) => {
    console.log(`Successfully purchased ${quantity} tickets for ${ticketId}`);
    // Refresh your data, show success message, etc.
  };

  const handlePurchaseError = (error: string) => {
    console.error("Purchase failed:", error);
    // Show error message, log error, etc.
  };

  return (
    <VeryLuckyWithPurchase
      gameType="weekly-jackpot"
      userBalance={10000}
      showPurchaseButton={true}
      onPurchaseSuccess={handlePurchaseSuccess}
      onPurchaseError={handlePurchaseError}
    />
  );
};
```

## Props

| Prop                 | Type                                           | Default         | Description                                  |
| -------------------- | ---------------------------------------------- | --------------- | -------------------------------------------- |
| `gameType`           | `GameType`                                     | `"daily-lucky"` | The type of game to display                  |
| `userBalance`        | `number`                                       | `5000`          | User's VERY balance for the popup            |
| `showPurchaseButton` | `boolean`                                      | `true`          | Whether to show the floating purchase button |
| `onPurchaseSuccess`  | `(ticketId: string, quantity: number) => void` | `undefined`     | Callback when purchase succeeds              |
| `onPurchaseError`    | `(error: string) => void`                      | `undefined`     | Callback when purchase fails                 |

## Game Types Supported

- **`daily-lucky`**: Daily LUCKY game (1 VERY per ticket)
- **`weekly-jackpot`**: Weekly JACKPOT game (5 VERY per ticket)
- **`ads-lucky`**: ADS LUCKY game (Free tickets)

## Purchase Button Behavior

The purchase button automatically:

- **Shows only for paid games** (hides for free games like ADS LUCKY)
- **Uses game-specific colors** from your configuration
- **Displays appropriate text** based on ticket price
- **Positioned as floating button** in bottom-right corner

## Integration Examples

### 1. Basic Integration

```typescript
// Simply wrap your existing VeryLucky component
<VeryLuckyWithPurchase gameType="daily-lucky" />
```

### 2. With Callbacks

```typescript
<VeryLuckyWithPurchase
  gameType="weekly-jackpot"
  onPurchaseSuccess={(ticketId, quantity) => {
    // Refresh ticket count
    // Update user balance
    // Show success notification
  }}
  onPurchaseError={(error) => {
    // Show error notification
    // Log error for analytics
  }}
/>
```

### 3. Conditional Display

```typescript
<VeryLuckyWithPurchase
  gameType="daily-lucky"
  showPurchaseButton={userIsLoggedIn && hasEnoughBalance}
/>
```

### 4. Custom Styling

The component automatically uses your game configuration:

- Button color matches the game theme
- Button text shows the actual ticket price
- Images and descriptions come from your config

## How It Works

1. **Renders VeryLucky**: Shows your existing game interface
2. **Adds Purchase Button**: Floating button for ticket purchases
3. **Manages Popup State**: Handles popup open/close
4. **Integrates with Service**: Ready to connect with TicketPurchaseService
5. **Provides Callbacks**: Notifies parent component of purchase events

## Future Enhancements

The component is designed to easily integrate with:

- **Real purchase logic** via TicketPurchaseService
- **User authentication state**
- **Real-time balance updates**
- **Purchase history tracking**
- **Analytics and monitoring**

## Styling

The component automatically adapts to your game configuration:

- Uses game-specific colors and images
- Responsive design that works on all screen sizes
- Smooth animations and hover effects
- Consistent with your existing design system

## Troubleshooting

### Purchase Button Not Showing

- Check if `showPurchaseButton` is `true`
- Verify the game has a non-zero ticket price
- Ensure `gameType` is valid

### Popup Not Opening

- Check if `selectedTicket` state is set correctly
- Verify the `TicketPurchasePopup` component is imported
- Check console for any JavaScript errors

### Integration Issues

- Ensure all required props are passed
- Check that game configuration exists for the game type
- Verify callback functions are properly defined
