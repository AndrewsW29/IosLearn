# EcuaCar Authentication Storage

## Overview

This implementation provides secure storage for authentication data using iOS Keychain, matching the functionality of your Postman authentication script.

## Architecture

### Files Created

1. **AuthenticationStorage.swift** - Secure Keychain-based storage manager
2. **APIService.swift** - Helper service for making authenticated API requests

### What Gets Stored

After a successful login, the following headers are automatically extracted and stored securely:

| Header | Storage Key | Description |
|--------|------------|-------------|
| `X-AUTH-TOKEN` | `authToken` | Main authentication token |
| `message-unique-id` | `messageUniqueId` | Unique message identifier |
| `XSRF-TOKEN` (Set-Cookie) | `xsrfToken` | Full XSRF cookie string |
| `X-XSRF-TOKEN` | `xXsrfToken` | Extracted XSRF token value |
| `ec-car-sales-int-uui-cookie-0` | `cookie0` | Session cookie 0 |
| `ec-car-sales-int-uui-cookie-1` | `cookie1` | Session cookie 1 |
| `ec-car-sales-int-uui-cookie-2` | `cookie2` | Session cookie 2 |

## Usage

### 1. Login (Automatic Storage)

The login process automatically stores all authentication data:

```swift
// In LoginViewModel
func login() async throws {
    // ... make login request ...
    
    // Headers are automatically stored after successful login
    authStorage.storeAuthenticationHeaders(from: httpResponse)
}
```

### 2. Making Authenticated API Requests

#### Option A: Using APIService (Recommended)

```swift
// Fetch user profile
let profile = try await APIService.shared.fetchUserProfile()

// Fetch cars with pagination
let cars = try await APIService.shared.fetchCars(page: 1, limit: 20)

// Add car to cart
let cartResponse = try await APIService.shared.addToCart(carId: "12345")
```

#### Option B: Manual Request Configuration

```swift
let authStorage = AuthenticationStorage.shared

guard authStorage.isAuthenticated else {
    print("User not logged in")
    return
}

var request = URLRequest(url: url)
request.httpMethod = "GET"

// This adds all authentication headers and cookies
authStorage.configureCookiesForRequest(&request)

let (data, response) = try await URLSession.shared.data(for: request)
```

### 3. Accessing Individual Values

```swift
let authStorage = AuthenticationStorage.shared

// Get auth token
if let token = authStorage.getAuthToken() {
    print("Token: \(token)")
}

// Get XSRF token
if let xsrfToken = authStorage.getXSRFToken() {
    print("XSRF: \(xsrfToken)")
}

// Get unique ID
if let uniqueId = authStorage.getMessageUniqueId() {
    print("ID: \(uniqueId)")
}

// Get all cookies as array
let cookies = authStorage.getAllCookies()
```

### 4. Logout

```swift
let authStorage = AuthenticationStorage.shared
authStorage.clearAuthData()
// This clears Keychain and updates isAuthenticated to false
```

### 5. Check Authentication Status

```swift
let authStorage = AuthenticationStorage.shared

if authStorage.isAuthenticated {
    // User is logged in with valid token
    print("Logged in!")
} else {
    // User needs to log in
    print("Not logged in")
}
```

## Request Headers Configuration

When you call `authStorage.configureCookiesForRequest(&request)`, it automatically adds:

```http
X-AUTH-TOKEN: <stored token>
X-XSRF-TOKEN: <extracted xsrf value>
message-unique-id: <stored unique id>
Cookie: ec-car-sales-int-uui-cookie-0=...; ec-car-sales-int-uui-cookie-1=...; XSRF-TOKEN=...
```

## Security Features

### Keychain Storage
- All authentication data is stored in iOS Keychain
- Uses `kSecAttrAccessibleAfterFirstUnlock` for security
- Data persists across app launches
- Automatically cleared when user logs out

### Why Keychain over SQLite?

1. **Purpose-built for credentials** - Designed for sensitive data
2. **Encrypted by default** - Hardware-level encryption
3. **System integration** - Works with Face ID/Touch ID
4. **Simple API** - No database management needed
5. **Apple recommended** - Best practice for tokens

## Data Model

```swift
struct AuthenticationData: Codable {
    var authToken: String?              // X-AUTH-TOKEN
    var messageUniqueId: String?        // message-unique-id
    var xsrfToken: String?              // Full XSRF-TOKEN cookie
    var xXsrfToken: String?             // Extracted XSRF value
    var cookie0: String?                // ec-car-sales-int-uui-cookie-0
    var cookie1: String?                // ec-car-sales-int-uui-cookie-1
    var cookie2: String?                // ec-car-sales-int-uui-cookie-2
    var loginTimestamp: Date?           // When user logged in
}
```

## Persistent Login

The app automatically checks authentication status on launch:

```swift
struct ContentView: View {
    @StateObject private var authStorage = AuthenticationStorage.shared
    
    var body: some View {
        if authStorage.isAuthenticated {
            HomeView()  // User has valid token
        } else {
            OnboardingFlow()  // Show login
        }
    }
}
```

## Error Handling

```swift
do {
    let result = try await APIService.shared.fetchCars()
    // Handle success
} catch APIError.unauthorized {
    // Token expired - user will be automatically logged out
    print("Session expired, please log in again")
} catch APIError.notAuthenticated {
    // User not logged in
    print("Please log in first")
} catch {
    // Other errors
    print("Error: \(error.localizedDescription)")
}
```

## Debugging

Enable debug logging to see stored data:

```swift
// Check what's stored (in ProfileView)
if let authData = authStorage.authData {
    print("Token: \(authData.authToken?.prefix(20) ?? "none")")
    print("Unique ID: \(authData.messageUniqueId ?? "none")")
    print("Logged in at: \(authData.loginTimestamp ?? Date())")
}
```

## Migration from Postman Script

Your Postman script logic has been translated as follows:

| Postman | iOS Implementation |
|---------|-------------------|
| `pm.collectionVariables.set("token", ...)` | Stored in Keychain as `authToken` |
| `pm.collectionVariables.set("message-unique-id", ...)` | Stored in Keychain as `messageUniqueId` |
| `configureCookies()` | `parseCookies()` method |
| `configureToken()` | Extracted from `X-AUTH-TOKEN` header |
| Cookie parsing logic | Handled in `parseCookies()` |
| Setting request headers | `configureCookiesForRequest()` method |

## Testing

### Test Login Flow
1. Enter email and password
2. Tap Login
3. Check console for: `✅ Authentication data stored successfully`
4. App should navigate to HomeView
5. Force close and reopen app
6. Should stay logged in (HomeView)

### Test Logout
1. Go to Profile tab
2. Tap Logout
3. Should return to login screen
4. Reopen app - should show login screen

### Test API Calls
1. After login, try making API calls:
```swift
Task {
    do {
        let cars = try await APIService.shared.fetchCars()
        print("Fetched \(cars.cars.count) cars")
    } catch {
        print("Error: \(error)")
    }
}
```

## Next Steps

1. **Update API models** - Modify `UserProfile`, `Car`, etc. to match your actual API responses
2. **Add more endpoints** - Add methods in `APIService` for your specific API calls
3. **Handle token refresh** - If your API has token refresh, implement in `APIService`
4. **Add biometric authentication** - Use Face ID/Touch ID for app launch
5. **Network monitoring** - Add connectivity checks before API calls

## Support

The implementation includes:
- ✅ Secure Keychain storage
- ✅ Automatic header/cookie extraction
- ✅ Request configuration helper
- ✅ Persistent login
- ✅ Automatic logout on 401
- ✅ Debug logging
- ✅ Error handling
- ✅ SwiftUI integration
