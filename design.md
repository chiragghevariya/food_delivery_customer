# Food Delivery — Customer App Design System & Guidelines

This document details the design system, typography, color palette, and component design patterns implemented in the customer app. It also lists UI/UX recommendations for the next development phase.

---

## 🎨 Color Palette & Semantics

The customer app uses a high-contrast, warm color scheme curated for food delivery and user engagement.

| Token Name | Hex Code | Visual Swatch | Intent & Usage |
| :--- | :--- | :--- | :--- |
| `primary` | `#FF5722` | ![#FF5722](https://placehold.co/15x15/FF5722/FF5722.png) | Brand primary, action buttons, active navigation, price indicators, key brand icons. |
| `primaryDark` | `#E64A19` | ![#E64A19](https://placehold.co/15x15/E64A19/E64A19.png) | Pressed button states, deep accents. |
| `background` | `#F8F9FC` | ![#F8F9FC](https://placehold.co/15x15/F8F9FC/F8F9FC.png) | Soft gray canvas background. Reduces eye strain. |
| `card` | `#FFFFFF` | ![#FFFFFF](https://placehold.co/15x15/FFFFFF/FFFFFF.png) | Flat white panels, menu tiles, and dialog sheets. |
| `text` | `#1E2022` | ![#1E2022](https://placehold.co/15x15/1E2022/1E2022.png) | Soft black for primary text, headers, and navigation titles. |
| `textLight` | `#75828D` | ![#75828D](https://placehold.co/15x15/75828D/75828D.png) | Subtitles, helper text, inactive states, and timestamps. |

### Semantic State Colors (Backend Sync)
* **Pending**: Orange (`#D97706` / Amber) — indicates order awaiting verification.
* **Accepted / Preparing / Ready**: Indigo/Blue — indicators for kitchen operations.
* **Delivered**: Green (`#059669`) — order completed successfully.
* **Cancelled**: Red (`#DC2626`) — order cancelled by customer or vendor.

---

## 📐 Layout & Dimensions

To maintain visual cohesion, the application applies consistent structural rules:
* **Base Spacing**: Multiples of `4` (`4px`, `8px`, `12px`, `16px`, `24px`).
* **Outer Padding**: `16px` or `20px` standard padding for screens.
* **Border Radius**: 
  * `16.0` for text input fields, secondary cards, dialogs, and primary buttons.
  * `12.0` for small chips, badges, and quick-action items.
  * `8.0` for status tags.

---

## 🔤 Typography & Font Hierarchy

The app currently inherits system fonts via Material 3. Recommended text styles match the hierarchy below:

```
AppBar Title   ──> 18px (Bold, Color: text)
Screen Header  ──> 22px (Bold, Color: text)
Section Title  ──> 18px (Bold, Color: text)
Body (Main)    ──> 14px (Regular, Color: text)
Subtitle/Cap   ──> 13px/12px (Regular, Color: textLight)
Button Text    ──> 16px (Bold, Color: white)
```

---

## 📦 Key Component Designs

### 1. Restaurant Card (`restaurant_card.dart`)
* **Layout**: Stack containing banner/logo network image, status badge ("Open Now" / "Closed"), rating row, title, address and category.
* **Visuals**: Soft shadow, border radius 16, card color `#FFFFFF`.

### 2. Category Selector Chips (`category_chip.dart`)
* **Layout**: Horizontal list view containing image icon, text, and active highlight board.
* **Visuals**: Animated background fill on selection, matching primary orange theme.

### 3. Menu Item Tile (`menu_item_tile.dart`)
* **Layout**: Flat tile containing name, sub-description, price, and add action.
* **Visuals**: Divider separation, rounded edges, prompt animations on action click.

### 4. Status History Timeline (`order_detail_screen.dart`)
* **Layout**: Custom vertical timeline.
* **Visuals**:
  * Dot icon matched to the event type.
  * Dashed vertical line indicator connecting status stages.
  * Highlighted active status state representing the current checkpoint.

---

## 🚀 Design Roadmap & Enhancement Steps

### Phase A: Typography & Theme
* **Google Fonts**: Load `Outfit` or `Inter` in `buildAppTheme()` (`lib/config/app_theme.dart`).
* **Micro-interaction Feedbacks**: Implement scale transitions on click/tap events for restaurant cards and categories.

### Phase B: Real-Time Map Optimization
* **GPS Tracking**: Update the map in `order_detail_screen.dart` to show a route polyline between the restaurant and customer coordinates, and render a rider marker showing the courier's location updating in real-time.
* **Shimmer Effects**: Add custom shimmer overlays (`shimmer` package) during API loads on home and restaurant detail pages.
