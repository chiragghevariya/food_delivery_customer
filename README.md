# Food Delivery — Customer App (Flutter)

Customer app for the multi-vendor food delivery demo. It talks to the Laravel
API (Phases 1–3) using Dio + JWT, manages state with Provider, and shows
restaurants, a cart, and live order tracking.

## What's inside

```
lib/
├── main.dart                  # app entry, providers + named routes
├── config/
│   ├── api_config.dart        # API base URL + headers
│   ├── app_theme.dart         # theme + dark-orange accent (#FF6B35)
│   └── routes.dart            # all named-route paths
├── models/                    # User, Restaurant, Category, MenuItem, CartItem, Order, OrderItem
├── services/
│   ├── api_service.dart       # shared Dio instance + JWT interceptor
│   ├── auth_service.dart      # login / register / logout (+ token in SharedPreferences)
│   ├── restaurant_service.dart
│   ├── order_service.dart
│   ├── notification_service.dart  # local notifications
│   └── location_service.dart      # geolocator helper
├── providers/                 # AuthProvider, CartProvider, RestaurantProvider
├── widgets/                   # RestaurantCard, MenuItemTile, CategoryChip, StatusBadge, PrimaryButton
└── screens/                   # Splash, Login, Register, Home, RestaurantDetail, Cart, Orders, OrderDetail
```

## 1. Create the platform folders

This repo contains the Dart source (`lib/`) and `pubspec.yaml`, but not the
generated `android/`, `ios/`, `web/` folders. Generate them once:

```bash
cd food_delivery_customer
flutter create --platforms=android,ios,web .   # adds platform folders only; keeps lib/ + pubspec
flutter pub get
```

> `flutter create` does not overwrite existing files (your `lib/`, `pubspec.yaml`
> and `test/` are kept). If you ever prefer a clean slate, create a fresh
> project elsewhere and copy this `lib/`, `pubspec.yaml` and `test/` over it.

## 2. Point the app at your backend

Edit `lib/config/api_config.dart` → `baseUrl`:

| Where you run the app | baseUrl |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (default) |
| iOS simulator / web | `http://127.0.0.1:8000/api` |
| Real phone (same wifi) | `http://<YOUR-PC-IP>:8000/api` |
| Laragon virtual host | `http://food-delivery.test/api` |

Run the backend first: `php artisan serve` (from the Laravel project).
Seed demo data so there's something to show: `php artisan migrate --seed`.

## 3. Android setup (important)

In `android/app/src/main/AndroidManifest.xml`:

**a) Allow plain HTTP** (the dev API uses `http://`, not `https://`). On the
`<application>` tag add:
```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

**b) Permissions** (above `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

**c) Google Maps API key** (inside `<application>`), required only for the map
on the order screen:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```
Get a key from Google Cloud Console → enable "Maps SDK for Android". Without a
key the rest of the app works fine; only the small map preview stays blank.

## 4. iOS setup (if you target iOS)

In `ios/Runner/Info.plist` add location + maps usage:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to set your delivery address.</string>
```
And add your Maps key in `ios/Runner/AppDelegate.swift` (see google_maps_flutter docs).

## 5. Run it

```bash
flutter run
```

Log in with the seeded admin (`admin@fooddelivery.test` / `password`) or tap
**Register** to create a new customer.

## Notes
- **Auth:** the JWT is saved in SharedPreferences and attached to every request
  by a Dio interceptor (`api_service.dart`). The splash screen auto-logs-in if a
  valid token exists.
- **Cart:** holds items from one restaurant at a time; the server is the source
  of truth for prices (the app only sends item id + quantity).
- **Live tracking:** the order detail screen re-fetches every 10 seconds until
  the order is delivered/cancelled, and raises a local notification when the
  status changes.
- **Push notifications:** this app uses *local* notifications. Real server push
  would add `firebase_messaging` (the backend already has the FCM v1 service).
