# APIService Integration Guide

This guide demonstrates how to use the `LoginViewModel` with the `APIService` class to make authenticated API requests in your EcuaCar app.

## Overview

The architecture consists of:
- **AuthenticationStorage**: Manages authentication tokens and session data (expires after 5 minutes)
- **APIService**: Handles authenticated API requests
- **LoginViewModel**: Manages login flow and consumes APIService for data fetching

## Key Features

### 1. Automatic Session Expiration (5 minutes)
All authentication data expires after 5 minutes and is automatically cleared.

### 2. Automatic Session Validation
All API methods automatically validate the session before making requests.

### 3. Centralized Error Handling
Handle common API errors like unauthorized (401), forbidden (403), etc.

## Usage Examples

### Basic Login Flow

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var authStorage = AuthenticationStorage.shared
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some View {
        if authStorage.isAuthenticated {
            DashboardView()
                .environmentObject(authStorage)
        } else {
            LoginPageView()
                .environmentObject(authStorage)
        }
    }
}
```

### 1. Login and Fetch Initial Data

```swift
// In your login button action
Task {
    do {
        try await viewModel.login()
        // Initial data is automatically fetched after successful login
        // via fetchInitialData() which calls:
        // - fetchUserProfile()
        // - fetchCars()
    } catch {
        // Handle login error
        print("Login failed: \(error.localizedDescription)")
    }
}
```

### 2. Fetch User Profile

```swift
// Fetch user profile manually
Task {
    let success = await viewModel.fetchUserProfile()
    if success {
        // Profile loaded successfully
        if let profile = viewModel.userProfile {
            print("Welcome, \(profile.name)!")
        }
    } else {
        // Failed to load profile (check viewModel.errorMessage)
        print(viewModel.errorMessage ?? "Unknown error")
    }
}
```

### 3. Fetch Cars with Pagination

```swift
// Fetch first page (default: page 1, limit 20)
Task {
    await viewModel.fetchCars()
}

// Fetch specific page
Task {
    await viewModel.fetchCars(page: 2, limit: 10)
}

// Access the cars
ForEach(viewModel.cars) { car in
    Text("\(car.name) - $\(car.price)")
}
```

### 4. Add Item to Cart

```swift
// Add a car to the cart
Task {
    let success = await viewModel.addToCart(carId: "car-123")
    if success {
        print("Added to cart!")
    }
}
```

### 5. Check Authentication Status

```swift
// Check remaining session time
viewModel.checkAuthStatus()

// Or access directly
if let remainingTime = authStorage.remainingTime() {
    let minutes = Int(remainingTime / 60)
    print("Session expires in \(minutes) minutes")
}
```

### 6. Logout

```swift
// Clear all authentication data and user data
viewModel.logout()
```

## Custom API Requests

You can extend `APIService` to add more endpoints:

```swift
// In APIService.swift

// MARK: - Custom Endpoints
extension APIService {
    
    // Get order history
    func fetchOrderHistory() async throws -> OrderHistoryResponse {
        return try await authenticatedRequest(endpoint: "/orders/history")
    }
    
    // Update user profile
    func updateProfile(name: String, email: String) async throws -> UserProfile {
        let body = ["name": name, "email": email]
        return try await authenticatedRequest(
            endpoint: "/user/profile",
            method: "PUT",
            body: body
        )
    }
    
    // Delete account
    func deleteAccount() async throws -> DeleteAccountResponse {
        return try await authenticatedRequest(
            endpoint: "/user/account",
            method: "DELETE"
        )
    }
}
```

Then use them in your ViewModel:

```swift
// In LoginViewModel or a separate ViewModel

@Published var orderHistory: [Order] = []

func loadOrderHistory() async {
    do {
        let response: OrderHistoryResponse = try await apiService.fetchOrderHistory()
        self.orderHistory = response.orders
    } catch APIError.unauthorized {
        errorMessage = "Session expired"
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

## Error Handling

### Handle Specific API Errors

```swift
Task {
    do {
        try await viewModel.fetchUserProfile()
    } catch APIError.unauthorized {
        // Session expired - show login
        print("Please log in again")
    } catch APIError.notFound {
        // Resource not found
        print("Profile not found")
    } catch APIError.serverError(let statusCode, let message) {
        // Server error
        print("Server error \(statusCode): \(message)")
    } catch {
        // Other errors
        print("Error: \(error.localizedDescription)")
    }
}
```

### Automatic Session Expiration Handling

All API methods automatically handle session expiration:

```swift
// This will automatically clear auth data and set isAuthenticated = false
// when the 5-minute expiration time is reached
let profile = try await apiService.fetchUserProfile()
```

## Session Management

### Configure Expiration Duration

```swift
// Change expiration time (default is 5 minutes)
AuthenticationStorage.shared.expirationDuration = 10 * 60 // 10 minutes
```

### Monitor Session State

```swift
struct AuthMonitorView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    
    var body: some View {
        VStack {
            if authStorage.isAuthenticated {
                if let remaining = authStorage.remainingTime() {
                    let minutes = Int(remaining / 60)
                    let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
                    
                    Text("Session expires in \(minutes)m \(seconds)s")
                        .foregroundColor(remaining < 60 ? .red : .green)
                }
            } else {
                Text("Not authenticated")
                    .foregroundColor(.red)
            }
        }
    }
}
```

## Published Properties in LoginViewModel

The `LoginViewModel` provides several `@Published` properties you can bind to in your views:

```swift
// Authentication state
@Published var isLoading: Bool              // Login in progress
@Published var errorMessage: String?        // Latest error message

// User data
@Published var userProfile: UserProfile?    // Current user profile
@Published var isLoadingProfile: Bool       // Profile fetch in progress

// Cars data
@Published var cars: [Car]                  // List of cars
@Published var isLoadingCars: Bool          // Cars fetch in progress
```

## Complete Example: Car List View

```swift
struct CarListView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoadingCars {
                ProgressView("Loading cars...")
            } else {
                ForEach(viewModel.cars) { car in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(car.name)
                                .font(.headline)
                            Text(car.brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Add to Cart") {
                            Task {
                                await viewModel.addToCart(carId: car.id)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchCars()
        }
        .refreshable {
            await viewModel.fetchCars()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

## Best Practices

1. **Always use Task for async operations**
   ```swift
   Task {
       await viewModel.fetchCars()
   }
   ```

2. **Handle errors appropriately**
   ```swift
   do {
       try await viewModel.login()
   } catch {
       // Show error to user
   }
   ```

3. **Check authentication before sensitive operations**
   ```swift
   guard authStorage.isAuthenticated else {
       // Redirect to login
       return
   }
   ```

4. **Monitor session expiration**
   - Use `remainingTime()` to warn users before session expires
   - Implement auto-refresh logic if needed

5. **Clear sensitive data on logout**
   ```swift
   viewModel.logout() // Clears auth data and user data
   ```

## Testing

```swift
import Testing

@Suite("API Service Tests")
struct APIServiceTests {
    
    @Test("Login stores authentication data")
    func testLogin() async throws {
        let viewModel = LoginViewModel()
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        try await viewModel.login()
        
        #expect(AuthenticationStorage.shared.isAuthenticated == true)
        #expect(AuthenticationStorage.shared.getAuthToken() != nil)
    }
    
    @Test("Session expires after configured duration")
    func testSessionExpiration() async throws {
        // Set very short expiration for testing
        AuthenticationStorage.shared.expirationDuration = 1 // 1 second
        
        let viewModel = LoginViewModel()
        try await viewModel.login()
        
        // Wait for expiration
        try await Task.sleep(for: .seconds(2))
        
        // Should be expired
        #expect(AuthenticationStorage.shared.validateAuthData() == false)
    }
}
```

## Troubleshooting

### Issue: "Not authenticated" error when making API calls
**Solution**: Check if the session has expired. The default is 5 minutes. You may need to login again or increase the expiration duration.

### Issue: API returns 401 Unauthorized
**Solution**: This typically means the session has expired or the authentication headers are incorrect. The app should automatically clear auth data and redirect to login.

### Issue: Data not loading after login
**Solution**: Check that `fetchInitialData()` is being called after successful login. Also verify network connectivity and API endpoint URLs.

### Issue: Session expires too quickly
**Solution**: Increase the expiration duration:
```swift
AuthenticationStorage.shared.expirationDuration = 15 * 60 // 15 minutes
```
