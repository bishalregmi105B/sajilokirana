# SajiloKirana — Customer App Audit (Part A, Section 0.1)

**Source app:** Blinkit-style open-source clone, package name `ecom`, located at `customer_app/`.
**Audit date:** 2026-06-29 · **Flutter SDK on machine:** 3.41.2 (Dart 3.11.0) · **Node:** v22.20.0
**Scope:** every screen, every reusable widget, every hardcoded `Color(...)`/`TextStyle(...)` in `lib/`. This document is the prerequisite for the Part A redesign — nothing in `lib/theme/` or `lib/widgets/` may be written until it exists.

---

## 1. Project Skeleton

```
customer_app/lib/
├── main.dart                         # MaterialApp, theme = AppTheme.appTHeme, initialRoute '/'
├── route_generator.dart              # AppRouter + ScalePageRoute (slide/scale transitions)
├── app_colors.dart                   # ⚠️ only 5 tokens exist today (see §5)
├── app_theme.dart                    # ThemeData, fontFamily 'Catamaran'
├── constants.dart                    # ₹ symbol, dummy products, dummy coupons, category titles
├── Screens/                          # 15 screens (see §2)
│   ├── Auth/                         #   login_screen, otp_verification_screen
│   ├── home_screen.dart
│   ├── products_screen.dart
│   ├── user_cart_screen.dart
│   ├── user_orders_screen.dart
│   ├── order_summary_screen.dart
│   ├── order_confirmation_screen.dart
│   ├── user_address_screen.dart
│   ├── profile_screen.dart
│   ├── coupons_screeen.dart          # (sic — typo in filename)
│   ├── cart_gift_screen.dart
│   ├── app_about_screen.dart
│   ├── pdf_view_screen.dart          #   ViewOrderInvoiceScreen (pdfx)
│   └── error_screen.dart             #   ErrorScreem (sic — typo in classname)
├── UI/
│   ├── custom_search_delegate.dart   # ProductsSearchDelegate over kDummyProducts
│   ├── custom_sliver_delegate.dart   # SliverAppBarDelegate (pinned header helper)
│   └── Widgets/
│       ├── Atoms/                    # 17 (see §3)
│       └── Organisms/                # 18 (see §3)
├── Infrastructure/
│   ├── AsyncAction/async_actions.dart
│   └── HttpMethods/requesting_methods.dart   # ApiService (Dio singleton, baseUrl='')
└── Services/
    ├── Providers/auth.provider.dart          # AuthProvider (Provider, FlutterSecureStorage)
    └── Exceptions/api_exception.dart
```

**Architecture observed:** Atomic-ish UI (Atoms/Organisms), `Provider` for state, `Dio` for HTTP, named routes via `onGenerateRoute`. No repository/use-case layer, no DI.

> ⚠️ The app is currently a **static UI demo** — `ApiService.baseUrl = ''`, all data is hardcoded (`kDummyProducts`, `chargeslissst`, fixed `itemCount: 4`/`6`/`2` in list builders), and `AuthProvider.getAuthToken` is never wired into the login flow. OTP "verify" just navigates to `/home`. The redesign keeps the *visual* layer; the data-binding is a separate workstream.

---

## 2. Screens Inventory (15)

| # | Route | Screen class | File | Notes for redesign |
|---|---|---|---|---|
| 1 | `/` | `LoginScreen` | `Auth/login_screen.dart` | Lottie `auth.json` + splash logo; bottom sheet collects phone. Becomes **Splash → Onboarding → Login/OTP**. |
| 2 | `/otp/verify` | `OTPVerificationScreen` | `Auth/otp_verification_screen.dart` | 30s resend timer; uses `customTextField`. Keep logic. |
| 3 | `/home` | `HomeScreen` | `home_screen.dart` | Slivers: app bar, search, carousel, categories, category×products rows, sticky cart bar + FAB nav. |
| 4 | `/products` | `ProductsScreen` | `products_screen.dart` | Sub-cat rail (flex 1) + product grid (flex 4). |
| 5 | `/cart` | `CartScreen` | `user_cart_screen.dart` | Checkout: items, coupon, bill, address+payment pinned bottom. |
| 6 | `/orders` | `OrdersScreen` | `user_orders_screen.dart` | Order list (4 dummy rows). → needs **OrderStatusBadge**, empty/error states. |
| 7 | `/order` | `OrderSummaryScreen` | `order_summary_screen.dart` | Items + bill + details + repeat-order CTA. |
| 8 | `/order/confirm` | `OrderConfirmationScreen` | `order_confirmation_screen.dart` | Lottie packing animation, auto-redirect to `/home` after 5s. |
| 9 | `/order/invoice` | `ViewOrderInvoiceScreen` | `pdf_view_screen.dart` | `pdfx` view of a bundled invoice PDF. |
| 10 | `/user/address` | `UserAddressScreen` | `user_address_screen.dart` | Add-address card + one static address card. |
| 11 | `/profile` | `ProfileScreen` | `profile_screen.dart` | Wallet/Support/Payments row + list tiles; logout via Cupertino dialog. |
| 12 | `/coupons` | `CouponsSelectionScreen` | `coupons_screeen.dart` | Apply field + coupon cards from `kDummyCoupons`. |
| 13 | `/cart/gift` | `CartGiftScreen` | `cart_gift_screen.dart` | Gift steps; "Continue" button. |
| 14 | `/app/about` | `AppAboutScreen` | `app_about_screen.dart` | Static `introParagraph` (still says "Blinkit"). |
| 15 | *(fallback)* | `ErrorScreem` | `error_screen.dart` | Bare "Error" text. → becomes a real **error/empty state** widget. |

**Gaps vs. Part A screen list:** no dedicated **Search results** screen (only a `SearchDelegate`), no **Product detail** screen (only a bottom-sheet modal), no **Checkout/address-selection** step distinct from cart, no **Order tracking (live map)**, no **Wishlist**, no **Notifications**. These are new screens to build, not just restyle.

---

## 3. Reusable Widgets Inventory (35)

### Atoms (17) — `UI/Widgets/Atoms/`
| Widget / function | File | Signature shape | Redesign action |
|---|---|---|---|
| `customTextButton()` | `custom_button.dart` | top-level fn → `ElevatedButton`; color param, **defaults to `redAccent`** | → `AppButton` (primary/secondary/text) |
| `customTextField()` | `custom_text_field.dart` | fn → `TextFormField`; hardcodes `+91` prefix | → theme-driven text field, Nepal `+977` prefix |
| `ProductCard` | `card_product.dart` | `{index}`; image/name/price + add | → `ProductCard` (real data, stock badge, stepper) |
| `buildAddToCartButton()` | `add_to_cart_button.dart` | fn; toast on tap | → `QuantityStepper` (+/-) |
| `CategoryWidget` | `category_widget.dart` | `{index}` into `kCategoriesTitles` | → `CategoryChip` |
| `ProductCardForList` | `card_product_list.dart` | horizontal-row variant | consolidate with `ProductCard` |
| `CartProductCard` | `card_product_cart_screen.dart` | cart line item w/ +/− | → stepper-based line item |
| `AddressCard` | `card_address_screen.dart` | static address | → `AppCard`-based, editable |
| `AddNewAddressCard` | `card_add_address.dart` | "+" CTA | → `AppCard` |
| `OrderDetailsCard` | `card_order_details.dart` | static key/value list | → `AppCard` |
| `buildIndividualPriceCard()` | `card_individual_price.dart` | fn over `chargeslissst` | → bill row component |
| `CartTimeandTotalItemCard`* | `card_cart_time_total_items.dart` | — | → `AppCard` |
| `CancellationPolicyCard`* | `card_cancellation_policy.dart` | — | → `AppCard` |
| `OrderGiftCard`* | `card_gift_cart_screen.dart` | — | → `AppCard` |
| `OrderSummaryProductsDetails`* | `card_product_order_summary.dart` | — | → `AppCard` |
| `customListTile()` | `list_tile.dart` | fn; icon/title/chevron | → `AppListTile` |
| `HomeScreenFloatingNavigationBar` | `home_screen_floating_button.dart` | FAB → category sheet | → `BottomNavBar` |
| `RepeatOrderContainer` | `repeat_order_cta.dart` | sticky CTA | → `AppButton` |

(*read by filename; structure consistent with siblings — `AppCard` migration.)

### Organisms (18) — `UI/Widgets/Organisms/`
`HomeScreenAppBar`, `HomeScreenSearchBar`, `HomeScreenCarousel`, `HomeScreenCateogoryWidget` (sic), `CatgorywithProducts` (sic), `BottomStickyContainer`, `LoginwithMobileWidget`, `buildProductsGrid()`, `buildSubCategory()`, `FloatingActionButtonWidget`, `ApplyCouponOnCartCard`, `CartPriceDetailWidget`, `CartScreenAddressContainer`, `CartScreenPaymentContainer`, `OrderSummaryProductsDetails`, `CupertinoLogoutDialog`, `openProductDescription()` (modal), `home_screen_floating_action_button_widget`.

All are screen-specific composites. Part A.2.4 introduces a shared **component library** (`AppButton`, `AppCard`, `ProductCard`, `CategoryChip`, `SearchBar`, `BottomNavBar`, `AppBarWidget`, `QuantityStepper`, `OrderStatusBadge`, `EmptyState`, `LoadingShimmer`, `ToastNotification`) that these organisms should be rebuilt on top of.

---

## 4. State · Networking · Routing

- **State:** `provider: ^6.0.5`. Only `AuthProvider` exists (token in `FlutterSecureStorage`); **not registered** in `main.dart` — no `MultiProvider` wrapper, so `AuthProvider.of` would throw today.
- **Networking:** `dio: ^5.3.0`, singleton `ApiService` with **empty `baseUrl`** and a `methodType` string switch. `ApiException` for errors. No interceptors, no auth header injection.
- **Routing:** `onGenerateRoute` switch on `settings.name`; all routes via custom `ScalePageRoute` (slide L↔R or scale-from-center, 300ms). Type-unsafe (`settings.arguments` is `dynamic`, cast per route).
- **Auth flow:** OTP entry → `_verifyOTP` just `pushNamedAndRemoveUntil('/home')`. No token exchange. The redesign keeps the UX; real auth comes with Part D backend.

---

## 5. Hardcoded Color Audit

**`lib/app_colors.dart` today (only 5 tokens):**
```dart
primaryYellowColor   = #FFE141   // the Blinkit yellow
primaryGreenColor    = #0C831F   // the Blinkit green (brand CTA everywhere)
scaffoldBackgroundColor = white
greyWhiteColor       = #EDF2F8   // scaffold tint
redAccentColor       = Colors.redAccent
```
Part A.1 replaces these wholesale with the terracotta/charcoal/gold palette.

**Hardcoded colors found via search (occurrences outside `app_colors.dart`):** ~110 hits across 31 files. Breakdown by category:

| Category | Representative occurrences | Count (approx) |
|---|---|---|
| `Colors.white` / `Colors.black` / `Colors.black87` / `Colors.black54` / `Colors.black45` | nearly every screen & widget (surfaces, text) | ~45 |
| `Colors.grey` / `.shade200` / `.shade300` / `[600]` | borders, muted text, dividers | ~22 |
| `AppColors.primaryGreenColor` (+ `.withOpacity(0.1)`) | the de-facto brand CTA/accent — buttons, badges, borders | ~16 |
| `AppColors.greyWhiteColor` | scaffold backgrounds | ~6 |
| `AppColors.redAccentColor` | `customTextButton` default + delete | 2 |
| One-off ARGB/hex literals (worst offenders — never reused): | | |
|  · `Color(0xffEEF5FF)` | `category_widget.dart:24` (category chip bg) | 1 |
|  · `Color(0xff313132)` | `home_screen_floating_action_button_widget.dart:48` (FAB) | 1 |
|  · `Color.fromARGB(255, 216, 237, 255)` | `profile_screen.dart:42` (light-blue card) | 1 |
|  · `Color.fromARGB(255, 0, 67, 183)` | `card_apply_coupon.dart:28` (coupon icon blue) | 1 |
|  · `Color.fromARGB(255, 223, 222, 222)` | `card_product_cart_screen.dart:26` (border) | 1 |
|  · `Colors.deepOrangeAccent` | `card_address_screen.dart:28` | 1 |
|  · `Colors.orangeAccent` | `cart_screen_*_container.dart` (×2) | 2 |
|  · `Colors.yellowAccent` | `card_gift_cart_screen.dart:22` | 1 |
|  · `Colors.blueAccent` | `list_tile.dart:28` | 1 |

**Verdict:** every semantic color is inlined. The five `AppColors` tokens are the *only* shared values, and even those are overridden by ~10 distinct ad-hoc literals. The acceptance criterion ("search `Color(0x` outside `app_colors.dart` → zero") requires touching all 31 files.

## 6. Inline `TextStyle` Audit

**~18 `TextStyle(fontSize:…/fontWeight:…/color:…)` constructions inlined directly in widgets** (search matched 11 files; additional unstyled `TextStyle(fontWeight:…)` without fontSize raise the true count higher). Examples: `home_screen.dart:44` (fontSize 25), `category_with_products.dart:20` (fontSize 35), `card_order_details.dart` (8 inlined styles, one per `Text`), `coupons_screeen.dart`, `profile_screen.dart`. Part A.1 mandates a single `AppTypography` class — every one of these becomes a named style.

## 7. Spacing & Shape (current)

No spacing system exists — values are ad-hoc per call site (`8.0`, `10.0`, `15`, `16`, `20`, `5`, `2`). Corner radii are almost universally `BorderRadius.circular(10.0)` (with a few `8.0`, `18.0` for sheets). Part A.1 imposes the 4/8/12/16/24/32 scale and radius 12 (cards) / 24 (pills).

## 8. Fonts & Assets

- **Font:** bundled `Catamaran` (7 weights in `Assets/Fonts/`). Part A.1 switches to **Lora (headings) + Inter (body)** via `google_fonts`.
- **Splash:** `flutter_native_splash` color `#FFE141` (Blinkit yellow) → retheme to terracotta.
- **Assets:** `Categories/` (20), `Products/` (6), `SubCategories/` (10), `cimgs/` (5 carousel), `Images/` (1 gift), Lottie `auth.json` + `cart_packing.json`, invoice PDF. All product/category imagery is placeholder (`Assets/Products/${index+1}.png`) — not Nepal-specific.
- **Currency:** `constants.dart` hardcodes `₹` (Indian rupee). Nepal uses `रु` / NPR — must change.

## 9. Known Bugs / Smells (surfaced, not yet fixed)

1. `AuthProvider` is never provided in the widget tree (`main.dart` has no `MultiProvider`) → `AuthProvider.of(context)` throws.
2. Filename/classname typos: `coupons_screeen.dart`, `ErrorScreem`, `HomeScreenCateogoryWidget`, `CatgorywithProducts`.
3. `withOpacity` is deprecated in current Flutter in favor of `.withValues(alpha:)` — will surface as lint warnings on SDK 3.41.
4. `introParagraph` and splash still say "Blinkit".
5. `home_screen.dart` sets an `AppBar` with `toolbarHeight: 3` purely as a status-bar spacer — fragile.

---

## 10. Redesign Approach (informs the plan)

- **Keep:** route generator shape, Atomic folder convention, `Provider`+`Dio`+`FlutterSecureStorage` choices, screen responsibilities.
- **Build first:** `lib/theme/` (`app_colors`, `app_typography`, `app_spacing`, `app_theme`) → `lib/widgets/` component library → then migrate screens in dependency order (Login/OTP → Home → Products → Cart → Orders → …).
- **Add (new):** Splash, Onboarding, Search-results, Product-detail, Order-tracking, Wishlist, Notifications; plus `EmptyState`/`LoadingShimmer`/error on **every** list screen.
- **Defer (out of Part A scope):** real API wiring, live map tiles, payment SDKs — those depend on Parts B–E.
