# Authentication Flow Diagram

## 📊 Complete Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         EcuaCar App                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    ┌─────────────────────┐
                    │   ContentView.swift  │
                    │  (Main Entry Point)  │
                    └──────────┬──────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                  │
              ▼                                  ▼
   ┌─────────────────┐              ┌────────────────────┐
   │ OnboardingFlow   │              │    HomeView        │
   │  (Not logged in) │              │  (Logged in)       │
   └────────┬─────────┘              └──────────┬─────────┘
            │                                    │
            ▼                                    │
   ┌─────────────────┐                          │
   │ LoginPageView    │                          │
   │                  │                          │
   │  ┌──────────────┐│                          │
   │  │LoginViewModel││                          │
   │  └──────┬───────┘│                          │
   └─────────┼────────┘                          │
             │                                    │
             │ login()                            │
             ▼                                    │
   ┌──────────────────────────────────┐          │
   │  POST /api/public/login          │          │
   │  email + password                │          │
   └──────────┬───────────────────────┘          │
              │                                   │
              │ Response Headers:                 │
              │ - X-AUTH-TOKEN                    │
              │ - message-unique-id               │
              │ - Set-Cookie (XSRF-TOKEN)         │
              │ - Set-Cookie (cookies 0,1,2)      │
              │                                   │
              ▼                                   │
   ┌──────────────────────────────────┐          │
   │  AuthenticationStorage.swift      │          │
   │  (Keychain Manager)               │◄─────────┤
   │                                   │          │
   │  storeAuthenticationHeaders()     │          │
   │  ↓                                │          │
   │  Stores in Keychain:              │          │
   │  • authToken                      │          │
   │  • messageUniqueId                │          │
   │  • xsrfToken                      │          │
   │  • xXsrfToken                     │          │
   │  • cookie0, cookie1, cookie2      │          │
   │                                   │          │
   │  isAuthenticated = true           │          │
   └──────────┬────────────────────────┘          │
              │                                   │
              │                                   │
              │         ┌─────────────────────────┘
              │         │
              │         │ Any View needs API data
              │         ▼
              │    ┌────────────────────────┐
              │    │   APIService.swift      │
              │    │  (API Manager)          │
              │    │                         │
              │    │  fetchCars()            │
              │    │  fetchUserProfile()     │
              │    │  addToCart()            │
              │    │  etc...                 │
              │    └────────┬────────────────┘
              │             │
              │             │ Creates URLRequest
              │             ▼
              │    ┌────────────────────────┐
              └───►│ configureCookiesFor     │
                   │ Request(&request)       │
                   │                         │
                   │ Adds to request:        │
                   │ • X-AUTH-TOKEN          │
                   │ • X-XSRF-TOKEN          │
                   │ • message-unique-id     │
                   │ • Cookie: (all cookies) │
                   └────────┬────────────────┘
                            │
                            ▼
                   ┌────────────────────────┐
                   │  API Call with Auth     │
                   │  GET/POST/PUT/DELETE    │
                   └────────┬────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
      ┌─────────────┐            ┌───────────────┐
      │ 200 Success │            │ 401 Unauth    │
      │             │            │               │
      │ Return Data │            │ Clear Auth    │
      └─────────────┘            │ Logout User   │
                                 └───────────────┘
```

## 🔄 Login Flow (Step by Step)

```
1. User enters email/password
   ↓
2. LoginViewModel.login() called
   ↓
3. POST request to /api/public/login
   ↓
4. Server responds with headers:
   - X-AUTH-TOKEN: "eyJhbGci..."
   - message-unique-id: "12345"
   - Set-Cookie: XSRF-TOKEN=abc123...
   - Set-Cookie: ec-car-sales-int-uui-cookie-0=...
   - Set-Cookie: ec-car-sales-int-uui-cookie-1=...
   - Set-Cookie: ec-car-sales-int-uui-cookie-2=...
   ↓
5. AuthenticationStorage.storeAuthenticationHeaders(response)
   ↓
6. Extract all headers and cookies
   ↓
7. Save to iOS Keychain
   ↓
8. Set isAuthenticated = true
   ↓
9. ContentView updates → Shows HomeView
```

## 🔐 Keychain Storage Structure

```
iOS Keychain
└── com.ecuacar.auth (service)
    └── user-auth-data (account)
        └── JSON Data:
            {
              "authToken": "eyJhbGciOiJIUzI1NiI...",
              "messageUniqueId": "12345-67890",
              "xsrfToken": "XSRF-TOKEN=abc123; Path=/; ...",
              "xXsrfToken": "abc123",
              "cookie0": "ec-car-sales-int-uui-cookie-0=xyz; ...",
              "cookie1": "ec-car-sales-int-uui-cookie-1=xyz; ...",
              "cookie2": "ec-car-sales-int-uui-cookie-2=xyz; ...",
              "loginTimestamp": "2026-05-24T10:30:00Z"
            }
```

## 📡 API Request Flow

```
View
 │
 ├─ Task { 
 │    let cars = try await APIService.shared.fetchCars()
 │  }
 │
 ▼
APIService.authenticatedRequest()
 │
 ├─ Check isAuthenticated ✓
 │
 ├─ Create URLRequest
 │
 ├─ authStorage.configureCookiesForRequest(&request)
 │   │
 │   ├─ Add Header: X-AUTH-TOKEN: "eyJhbGci..."
 │   ├─ Add Header: X-XSRF-TOKEN: "abc123"
 │   ├─ Add Header: message-unique-id: "12345"
 │   └─ Add Header: Cookie: "cookie-0=...; cookie-1=...; XSRF-TOKEN=..."
 │
 ├─ URLSession.shared.data(for: request)
 │
 ├─ Check response status
 │   │
 │   ├─ 200-299: Decode and return data ✓
 │   ├─ 401: Clear auth, throw unauthorized ✗
 │   └─ Other: Throw error ✗
 │
 └─ Return decoded data
```

## 🎯 Request Headers Example

When you call `authStorage.configureCookiesForRequest(&request)`:

```http
GET /ec-car-sales/api/cars HTTP/1.1
Host: 172.20.96.1:5066
Content-Type: application/json
X-AUTH-TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
X-XSRF-TOKEN: abc123def456ghi789
message-unique-id: 12345-67890-abcde
Cookie: ec-car-sales-int-uui-cookie-0=xyz123; ec-car-sales-int-uui-cookie-1=xyz456; ec-car-sales-int-uui-cookie-2=xyz789; XSRF-TOKEN=abc123def456ghi789; Path=/; HttpOnly
```

## 📱 App State Flow

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│ AuthenticationStorage    │
│ .shared init()           │
│                          │
│ loadAuthData()           │
└────────┬─────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────┐   ┌──────────┐
│Found│   │Not Found │
│Token│   │in Keychain│
└──┬──┘   └────┬─────┘
   │           │
   │           │
   ▼           ▼
┌─────────┐ ┌──────────┐
│HomeView │ │Onboarding│
│         │ │LoginView │
└─────────┘ └──────────┘
```

## 🛡️ Security Features

```
┌──────────────────────────────────────────┐
│         Security Layers                   │
├──────────────────────────────────────────┤
│                                           │
│  1. HTTPS Transport (SSL/TLS)             │
│     └─ Encrypts network traffic           │
│                                           │
│  2. iOS Keychain Storage                  │
│     ├─ Hardware encryption                │
│     ├─ Secure Enclave (Face ID/Touch ID) │
│     └─ App-specific isolation             │
│                                           │
│  3. Token-Based Authentication            │
│     ├─ X-AUTH-TOKEN (JWT)                 │
│     └─ XSRF-TOKEN (CSRF protection)       │
│                                           │
│  4. Automatic Session Management          │
│     ├─ Auto-logout on 401                 │
│     └─ Token expiration handling          │
│                                           │
└──────────────────────────────────────────┘
```

## 📁 File Structure

```
EcuaCar/
├── ContentView.swift
│   ├── ContentView (entry point)
│   ├── OnboardingFlow
│   ├── LoginPageView
│   ├── LoginViewModel ⚡ Uses AuthenticationStorage
│   ├── HomeView
│   └── ProfileView ⚡ Uses AuthenticationStorage
│
├── AuthenticationStorage.swift ⭐
│   ├── AuthenticationData (model)
│   ├── AuthenticationStorage (manager)
│   │   ├── storeAuthenticationHeaders()
│   │   ├── loadAuthData()
│   │   ├── clearAuthData()
│   │   ├── configureCookiesForRequest()
│   │   └── Helper getters (getAuthToken, etc.)
│   │
│   └── Uses iOS Keychain API
│
├── APIService.swift ⭐
│   ├── APIService (singleton)
│   │   ├── authenticatedRequest() (generic)
│   │   ├── fetchUserProfile()
│   │   ├── fetchCars()
│   │   └── addToCart()
│   │
│   ├── APIError (enum)
│   └── Response Models (UserProfile, Car, etc.)
│
├── ExampleUsage.swift ⭐
│   ├── CarListExampleView
│   ├── CarListViewModel
│   ├── Manual request examples
│   └── Enhanced ProfileView
│
├── AUTHENTICATION_README.md 📚
│   └── Complete documentation
│
├── QUICK_START.md 📚
│   └── Getting started guide
│
└── ARCHITECTURE.md 📚 (this file)
    └── Visual diagrams and flows
```

## 🔄 Postman → iOS Translation

| Postman Script | iOS Implementation |
|----------------|-------------------|
| `pm.response` | `URLResponse` parameter |
| `response.headers.filter(...)` | `httpResponse.allHeaderFields` |
| `pm.collectionVariables.set("token", ...)` | `authData.authToken = ...` |
| `pm.collectionVariables.set("message-unique-id", ...)` | `authData.messageUniqueId = ...` |
| `configureCookies()` | `parseCookies(_ cookieString, into: &authData)` |
| `configureToken()` | Extract from `X-AUTH-TOKEN` header |
| `getUniqueId()` | Extract from `message-unique-id` header |
| Cookie parsing loop | `parseCookies()` method with components(separatedBy:) |
| Setting collection variables | Storing in Keychain with `SecItemAdd` |
| Getting variables for request | `configureCookiesForRequest(&request)` |

## 🎨 Data Flow Example

```swift
// User taps Login button
LoginPageView
    │
    ├─ Task {
    │    try await viewModel.login()
    │  }
    │
    ▼
LoginViewModel.login()
    │
    ├─ POST /api/public/login
    │    Body: { email, password }
    │
    ▼
Server Response
    │
    ├─ Status: 200 OK
    ├─ Headers:
    │    X-AUTH-TOKEN: "token123..."
    │    message-unique-id: "id456..."
    │    Set-Cookie: XSRF-TOKEN=csrf789...
    │    Set-Cookie: ec-car-sales-int-uui-cookie-0=...
    │    Set-Cookie: ec-car-sales-int-uui-cookie-1=...
    │    Set-Cookie: ec-car-sales-int-uui-cookie-2=...
    │
    ▼
authStorage.storeAuthenticationHeaders(httpResponse)
    │
    ├─ Parse all headers
    ├─ Extract cookie values
    ├─ Create AuthenticationData
    │
    ▼
saveToKeychain(authData)
    │
    ├─ Encode to JSON
    ├─ SecItemAdd to Keychain
    │
    ▼
isAuthenticated = true
    │
    ▼
ContentView updates
    │
    └─► Shows HomeView

// Later: User wants to fetch cars
HomeView
    │
    ├─ Task {
    │    let cars = try await APIService.shared.fetchCars()
    │  }
    │
    ▼
APIService.fetchCars()
    │
    ├─ authenticatedRequest(endpoint: "/cars")
    │    │
    │    ├─ Check isAuthenticated ✓
    │    ├─ Create URLRequest
    │    ├─ configureCookiesForRequest(&request)
    │    │    │
    │    │    ├─ Add X-AUTH-TOKEN: "token123..."
    │    │    ├─ Add X-XSRF-TOKEN: "csrf789"
    │    │    ├─ Add message-unique-id: "id456..."
    │    │    └─ Add Cookie: "cookie-0=...; cookie-1=...; ..."
    │    │
    │    └─ URLSession.shared.data(for: request)
    │
    ▼
Server Response
    │
    ├─ Status: 200 OK
    ├─ Body: { cars: [...], totalPages: 5, currentPage: 1 }
    │
    ▼
Decode CarListResponse
    │
    └─► Return to caller
```

---

**This architecture provides:**
- ✅ Secure token storage (Keychain, not SQLite)
- ✅ Automatic authentication header management
- ✅ Persistent login across app launches
- ✅ Type-safe API calls
- ✅ Automatic session expiration handling
- ✅ Clean separation of concerns
- ✅ Easy to use API
