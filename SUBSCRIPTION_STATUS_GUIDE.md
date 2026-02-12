# Subscription Status Implementation Guide

## Overview

This guide documents the implementation of subscription status tracking to display "Active Plan" on packages that the user is currently subscribed to.

## Changes Made

### 1. Updated User Profile Models

**File**: `Broccoli/Networking/Models/UserProfileModels.swift`

#### Added Subscription Model

```swift
public struct Subscription: Codable, Identifiable {
    public let id: Int
    public let type: String
    public let stripeStatus: String
    public let stripePrice: String
    public let endsAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, type
        case stripeStatus = "stripe_status"
        case stripePrice = "stripe_price"
        case endsAt = "ends_at"
    }
}
```

#### Updated UserProfileData

Added `subscriptions` array to store user's active subscriptions:

```swift
public let subscriptions: [Subscription]?
```

### 2. Updated Packages View

**File**: `Broccoli/Features/Patient/PackagesView.swift`

#### Added UserGlobalViewModel

```swift
@EnvironmentObject private var userViewModel: UserGlobalViewModel
```

#### Added Helper Function

```swift
private func isPackageActive(_ package: Package) -> Bool {
    guard let subscriptions = userViewModel.profileData?.subscriptions else {
        return false
    }

    return subscriptions.contains { subscription in
        subscription.stripePrice == package.stripePriceId && subscription.stripeStatus == "active"
    }
}
```

#### Updated PackageCard Component

- Added `isActive` parameter to PackageCard
- Shows `OutlinePackageButton` with "Active Plan" text for active subscriptions
- Shows `PrimaryPackageButton` with "Buy Now" for inactive packages

#### Added Automatic Refresh

```swift
.task {
    await packageViewModel.loadPackages()
    await userViewModel.fetchUserProfile() // Refresh to get latest subscriptions
}
```

After successful payment:

```swift
await userViewModel.fetchUserProfile() // Refresh to update active subscriptions
```

## How It Works

### 1. Data Flow

```
API Response → UserProfileData → Subscription Array → Local Storage (via UserGlobalViewModel)
                                                    ↓
                                              PackagesView checks active subscriptions
                                                    ↓
                                              Shows "Active Plan" or "Buy Now"
```

### 2. Subscription Matching

- Each package has a `stripePriceId` (e.g., "price_1Qj7q8P9kM3MnI2lYf1JtlbX")
- Each subscription has a `stripePrice` field with the same format
- PackagesView compares `package.stripePriceId == subscription.stripePrice`
- Only shows "Active Plan" if `subscription.stripeStatus == "active"`

### 3. Button Display Logic

```swift
if isProcessing {
    // Show processing indicator
} else if isActive {
    // Show "Active Plan" button (outline style, non-clickable)
} else {
    // Show "Buy Now" button (primary style, clickable)
}
```

## API Response Structure

### User Profile Subscriptions Array

```json
{
  "status": true,
  "message": "User profile",
  "data": {
    "id": 123,
    "name": "John Doe",
    "subscriptions": [
      {
        "id": 1,
        "type": "Quaterly",
        "stripe_status": "active",
        "stripe_price": "price_1Qj7q8P9kM3MnI2lYf1JtlbX",
        "ends_at": "2025-04-08"
      }
    ]
  }
}
```

## Testing

### Verify Active Subscription Display

1. Log in as a user with active subscriptions
2. Navigate to Packages view
3. Verify packages with matching `stripe_price` show "Active Plan" button
4. Verify non-subscribed packages show "Buy Now" button

### Verify Purchase Flow

1. Purchase a new package
2. Verify payment success
3. Verify user profile is refreshed automatically
4. Verify the newly purchased package now shows "Active Plan"

### Verify Subscription Status

- Check that only `stripe_status == "active"` subscriptions are considered active
- Check that expired or cancelled subscriptions don't show as active

## Notes

- **Automatic Caching**: UserGlobalViewModel automatically caches user profile data (including subscriptions) to secure storage
- **Offline Support**: Cached subscription data is available even when offline
- **Multiple Subscriptions**: Users can have multiple active subscriptions simultaneously
- **Status Values**: Common Stripe subscription statuses include:
  - `active` - Subscription is active
  - `canceled` - Subscription has been cancelled
  - `past_due` - Payment failed
  - `incomplete` - Initial payment pending
  - `trialing` - In trial period

## Future Enhancements

### Potential Features

1. **Show Expiry Date**: Display `ends_at` date on active plan button
2. **Cancel Subscription**: Add ability to cancel active subscriptions
3. **Renewal Management**: Show renewal date and update payment method
4. **Multiple Tiers**: Handle upgrades/downgrades between subscription tiers
5. **Grace Period**: Show different status for past_due subscriptions
6. **Trial Status**: Show special indicator for subscriptions in trial period

### Example Enhancement: Show Expiry Date

```swift
if isActive, let subscription = getActiveSubscription(for: package) {
    VStack(spacing: 4) {
        OutlinePackageButton(title: "Active Plan")
        if let endsAt = subscription.endsAt {
            Text("Renews: \(formatDate(endsAt))")
                .font(theme.typography.regular12)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
```

## Troubleshooting

### "Active Plan" Not Showing

1. Check if user profile contains subscriptions array
2. Verify `stripe_price` matches `package.stripePriceId` exactly
3. Verify `stripe_status` is "active"
4. Check console logs for profile fetch success

### Stale Subscription Data

1. Force refresh: Pull down to refresh in packages view
2. Clear app data and re-login
3. Verify backend returns updated subscription data

### Multiple Active Plans

- This is expected behavior if user has multiple active subscriptions
- Each matching package will show "Active Plan"
