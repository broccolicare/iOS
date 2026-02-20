# Agora Video Calling - Quick Start Guide

## 🎯 Quick Setup (3 Steps)

### 1. Install Agora SDK (5 minutes)

```
Xcode → File → Add Packages
URL: https://github.com/AgoraIO-Community/AgoraRtcEngine_iOS
Version: Latest
```

### 2. Add Agora App ID (2 minutes)

Get App ID from: https://console.agora.io/

Update `AppEnvironment.swift`:

```swift
agoraAppId: "YOUR_ACTUAL_AGORA_APP_ID"  // Replace in all 3 environments
```

### 3. Implement Backend Endpoints (30-60 minutes)

#### Endpoint 1: Generate Token

```
POST /api/bookings/{id}/generate-agora-token

Response:
{
  "success": true,
  "token": "007eJxSYBBb...",
  "channel_name": "booking_123_channel",
  "uid": 12345,
  "expires_at": "2026-02-16T15:30:00Z"
}
```

#### Endpoint 2: Start Call

```
POST /api/bookings/{id}/start-video-call

Response:
{
  "success": true,
  "booking": { /* booking data */ },
  "message": "Video call started"
}
```

#### Endpoint 3: End Call

```
POST /api/bookings/{id}/end-video-call
Body: { "notes": "Consultation notes here..." }

Response:
{
  "success": true,
  "booking": { /* booking with status "completed" */ },
  "message": "Call ended successfully"
}
```

---

## 🧪 Quick Test

### Test 1: Time-Gated Buttons

1. Create booking with time = now + 10 minutes
2. Check "Start Call" button is disabled
3. Wait (or change time to now + 4 minutes)
4. Button becomes enabled ✅

### Test 2: Doctor Start Call

1. Doctor taps "Start Call" on scheduled appointment
2. Should see own camera in small PiP
3. Timer shows 30:00 and counts down ✅

### Test 3: Patient Join Call

1. Patient opens appointment detail
2. Taps "Join Call" button
3. Should see doctor's video (if doctor is in call)
4. Both see each other's video ✅

### Test 4: End Call with Notes

1. Doctor taps red "End Call" button
2. Notes form appears
3. Type notes (minimum text required)
4. Tap "End Call" again
5. Booking status updates to "completed" ✅

---

## 📱 User Flow Summary

### Doctor Flow

```
DoctorHomeView
  → Scheduled Appointments Section
  → "Start Call" button (enabled 5 min before)
  → VideoCallView (30 min timer)
  → End Call
  → Doctor Notes Form (mandatory)
  → Submit Notes
  → Return to DoctorHomeView
```

### Patient Flow

```
MyAppointmentsView
  → Tap appointment
  → AppointmentDetailForPatientView
  → "Join Call" button (shows if not completed & within window)
  → VideoCallView
  → End Call
  → Return to AppointmentDetailForPatientView
```

---

## 🎨 UI Components

### VideoCallView

- **Remote Video**: Full screen background
- **Local Video**: 120x160 floating PiP (top-right)
- **Top Bar**: Timer (30:00) + Network quality dot
- **Bottom Bar**: Mute, Video Toggle, End Call buttons

### DoctorNotesFormView

- **TextEditor**: Multi-line notes input
- **End Call Button**: Disabled if notes empty
- **Rejoin Button**: Available if timer hasn't expired

---

## 🔑 Key Files Modified

| File                                    | What Changed                   |
| --------------------------------------- | ------------------------------ |
| `Info.plist`                            | Camera & mic permissions added |
| `AppEnvironment.swift`                  | `agoraAppId` property added    |
| `BookingEndpoint.swift`                 | 3 video call endpoints added   |
| `BookingService.swift`                  | 3 video call service methods   |
| `BookingGlobalViewModel.swift`          | Token generation & call flow   |
| `DoctorHomeView.swift`                  | Start call button logic        |
| `AppointmentDetailForPatientView.swift` | Join call button               |
| `ScheduledAppointmentCard.swift`        | Time-gated button display      |

---

## 🐛 Common Issues

❌ **"Module AgoraRtcKit not found"**  
✅ Install SDK via Swift Package Manager

❌ **"Failed to join channel"**  
✅ Check Agora App ID in AppEnvironment.swift

❌ **Camera not working**  
✅ Check Info.plist permissions & device settings

❌ **Remote video not showing**  
✅ Both users must be in same `channel_name`

---

## 📊 Backend Token Generation (Example)

### Node.js Example

```javascript
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

app.post("/api/bookings/:id/generate-agora-token", async (req, res) => {
  const bookingId = req.params.id;
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;
  const channelName = `booking_${bookingId}_channel`;
  const uid = req.user.id; // Use user ID as UID
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // 1 hour

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs,
  );

  res.json({
    success: true,
    token: token,
    channel_name: channelName,
    uid: uid,
    expires_at: new Date(privilegeExpiredTs * 1000).toISOString(),
  });
});
```

### Laravel Example

```php
use AgoraToken\RtcTokenBuilder;

Route::post('/api/bookings/{id}/generate-agora-token', function($id) {
    $appId = env('AGORA_APP_ID');
    $appCertificate = env('AGORA_APP_CERTIFICATE');
    $channelName = "booking_{$id}_channel";
    $uid = auth()->id();
    $role = RtcTokenBuilder::ROLE_PUBLISHER;
    $expireTimeInSeconds = 3600;

    $currentTimestamp = now()->timestamp;
    $privilegeExpiredTs = $currentTimestamp + $expireTimeInSeconds;

    $token = RtcTokenBuilder::buildTokenWithUid(
        $appId,
        $appCertificate,
        $channelName,
        $uid,
        $role,
        $privilegeExpiredTs
    );

    return response()->json([
        'success' => true,
        'token' => $token,
        'channel_name' => $channelName,
        'uid' => $uid,
        'expires_at' => now()->addSeconds($expireTimeInSeconds)->toIso8601String()
    ]);
});
```

---

## ⏱️ Call Duration Settings

Default: **30 minutes**

To change, update in `VideoCallGlobalViewModel.swift`:

```swift
@Published public var remainingTime: Int = 1800  // 30 min = 1800 seconds
```

Or in `DateExtensions.swift`:

```swift
Date.isWithinCallWindow(
    appointmentDate: booking.date,
    appointmentTime: booking.time,
    callDurationMinutes: 45,  // Change to 45 minutes
    advanceMinutes: 10         // Show button 10 min early
)
```

---

## 🚀 Ready to Test!

After completing 3 setup steps above:

1. Build & run on **real device** (simulator camera won't work)
2. Create a test booking with appointment time = now + 4 minutes
3. Wait for "Start Call" button to enable
4. Tap button and grant camera/mic permissions
5. See your video in small PiP ✅
6. Test with second device/user for full call experience

---

**Need Help?** See full documentation in `AGORA_VIDEO_CALLING_INTEGRATION.md`
