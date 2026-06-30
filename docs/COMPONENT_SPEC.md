# SajiloKirana — Component Library Spec (Part A.2.4)

Shared contract for all `lib/widgets/` components. **Every component agent must
read this before writing code.** The theme layer (`lib/theme/`) is frozen —
do not edit it; depend on it.

## 1. Hard rules (enforced in Phase 5 verification)

1. **No hardcoded colors.** Never write `Color(0x...)`, `Colors.red`, `Color.fromARGB(...)`, or hex strings. Pull every color from `AppColors.*` (`package:ecom/theme/app_colors.dart`) or `Theme.of(context).colorScheme.*`. The ONLY file allowed to declare `Color` is `lib/theme/app_colors.dart`.
2. **No inline `TextStyle(fontSize:...)`.** Pull text styles from `AppTypography.*` (`package:ecom/theme/app_typography.dart`) or `Theme.of(context).textTheme.*`.
3. **Spacing via `AppSpacing`.** Use `AppSpacing.xs/sm/md/lg/xl/xxl` (4/8/12/16/24/32). No magic numbers like `15`, `10.0`, `5`.
4. **Radii via `AppRadius`.** `AppRadius.cardBorder` (12) for cards/containers; `AppRadius.pillBorder` (24) for buttons/pills.
5. **Shadows via `AppElevation.card(context)`.** Never `BoxShadow` with hardcoded blur/opacity inline.
6. **Package import prefix:** all app imports use `package:ecom/...` (the pubspec name is `ecom`).

## 2. Frozen theme API (depend on these exact signatures)

### `lib/theme/app_colors.dart` — `class AppColors`
```
static const Color primary        // #A8442C terracotta
static const Color primaryDark    // #2B2D3D charcoal
static const Color accent         // #E8A33D gold
static const Color surface        // #FFFFFF
static const Color surfaceTint    // #FBEEE8
static const Color textPrimary    // #2B2D3D
static const Color textMuted      // #6B6F7A
static const Color success        // #2E7D52
static const Color error          // #C0392B
static const Color warning        // #E8A33D
static const Color border         // #E7E5E2
static const Color scaffold       // #FCFAF8
static const Color shadow         // black @8%
static Color forOrderStatus(String status)  // → status color token
```

### `lib/theme/app_spacing.dart`
```
class AppSpacing  { xs=4, sm=8, md=12, lg=16, xl=24, xxl=32; pageHorizontal, page, card }
class AppRadius   { card=12, pill=24; cardBorder, pillBorder }
class AppElevation { static List<BoxShadow> card(BuildContext) }
```

### `lib/theme/app_typography.dart` — `class AppTypography`
```
displayLarge, displayMedium, headline   (Lora, headings)
body, bodyLarge, caption                (Inter, body)
button, label                           (Inter, UI)
static TextTheme get textTheme
```

### `lib/theme/app_theme.dart`
`AppTheme.light` — a complete `ThemeData` already wired into `main.dart`.
Component theme extensions (button/card/input/chip/appbar/bottomSheet/snackbar)
are already set, so plain `ElevatedButton`, `Card`, `TextField` etc. inherit
tokens automatically. **Prefer themed base widgets; only add a custom widget
when you need repeated composite structure.**

## 3. Constants available (`lib/constants.dart`)
```
appCurrencySymbol = "रु"      // NPR
appDialCode       = "+977"
appName           = "SajiloKirana"
kDummyProducts    : List<String>   (25 Nepal items)
kDummyCoupons     : List<Map>      (NPR amounts)
kCategoriesTitles : List<String>   (20 Nepal categories)
kFestivalCalendar : List<Map>
kSvgIcons         : List<String>
```

## 4. Target file layout

```
lib/widgets/
├── app_button.dart            // AppButton (primary/secondary/text variants)
├── app_card.dart              // AppCard
├── app_text_field.dart        // AppTextField
├── app_list_tile.dart         // AppListTile
├── product_card.dart          // ProductCard
├── category_chip.dart         // CategoryChip
├── search_bar.dart            // AppSearchBar (NOT a SearchDelegate wrapper)
├── app_bar_widget.dart        // AppBarWidget
├── bottom_nav_bar.dart        // AppBottomNavBar
├── quantity_stepper.dart      // QuantityStepper (+/-)
├── order_status_badge.dart    // OrderStatusBadge (color via forOrderStatus)
├── empty_state.dart           // EmptyState (icon/illustration + message + optional CTA)
├── loading_shimmer.dart       // LoadingShimmer (skeleton, NOT spinner)
└── toast_notification.dart    // ToastNotification (uses ScaffoldMessenger SnackBar)
```

## 5. Per-component contracts

### `AppButton` (`app_button.dart`)
```dart
enum AppButtonVariant { primary, secondary, text }
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,                 // optional leading IconData
    this.isLoading = false,    // shows a spinner, disables tap
    this.isFullWidth = false,
    this.isDestructive = false,// primary variant → error color
  });
}
```
- primary → `FilledButton` (terracotta); secondary → `OutlinedButton`; text → `TextButton`.
- `isLoading` swaps label for a `SizedBox(width/height:20)` `CircularProgressIndicator` (stroke 2, surface color).
- Respects the `minimumSize: Size.fromHeight(48)` already in theme.

### `AppCard` (`app_card.dart`)
```dart
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,   // default EdgeInsets.all(12)
    this.onTap,
    this.borderColor,                 // defaults to AppColors.border
    this.background = AppColors.surface,
  });
}
```
- `Container` with `AppRadius.cardBorder`, optional `AppElevation.card(context)`, 1px border.
- If `onTap != null`, wrap in `Material(type: transparent)` + `InkWell`.

### `AppTextField` (`app_text_field.dart`)
```dart
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixText,           // e.g. "+977" dial code
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofocus = false,
  });
}
```
- Thin wrapper over `TextFormField` using theme `inputDecorationTheme`.
- `prefixText` rendered via `InputDecoration.prefixText`.

### `ProductCard` (`product_card.dart`)
```dart
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.price,           // double, NPR
    this.unit,                     // e.g. "300gms"
    this.mrp,                      // optional strikethrough
    this.imageProvider,            // Network/Asset; fallback placeholder
    this.isInStock = true,
    this.initialQty = 0,
    this.onAdd,                    // first add
    this.onQtyChanged,            // (int qty) => increment/decrement
    this.onTap,                   // open detail
  });
}
```
- Image (fallback: a `Container` with `AppColors.surfaceTint` + an `Icons.image_outlined` muted icon).
- Name (1 line), unit (caption), price row with optional MRP strikethrough.
- Stock badge: if `!isInStock` → small `AppColors.error` chip "Out of stock", stepper hidden.
- Bottom: `QuantityStepper` when `initialQty>0` else an "Add" pill (`AppButton.secondary`-styled small).

### `CategoryChip` (`category_chip.dart`)
```dart
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.imageProvider,
    this.isSelected = false,
    this.onTap,
  });
}
```
- Vertical: circular/squircle image (56×56, `AppColors.surfaceTint` bg) + label (caption, 1 line, centered).

### `AppSearchBar` (`search_bar.dart`)
```dart
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hintText = 'Search for dal, chiura, tarkari…',
    this.onTap,            // if set, behaves as a non-focusable tappable field (route to search screen)
    this.onChanged,
    this.controller,
  });
}
```
- `AppCard`-styled rounded field, search prefix icon (`Icons.search`), optional suffix clear.
- If `onTap != null`, render as a tappable row (readonly) — used on the home screen.

### `AppBarWidget` (`app_bar_widget.dart`)
```dart
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
  });
  @override Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```
- Returns an `AppBar` configured from theme. Keep it thin — theme already styles it.

### `AppBottomNavBar` (`bottom_nav_bar.dart`)
```dart
enum AppNavTab { home, search, orders, profile }
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.current,
    required this.onChanged,
  });
}
```
- `NavigationBar` (M3) with 4 destinations; active color `AppColors.primary`, icons from `Icons`.

### `QuantityStepper` (`quantity_stepper.dart`)
```dart
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.qty,
    required this.onChanged,     // (int newQty) => void
    this.min = 0,
    this.max = 99,
  });
}
```
- "−  qty  +" pill (`AppColors.primary` bg, surface icons/text), `AppRadius.pillBorder`.
- `−` disabled at `min`, `+` disabled at `max` (reduce opacity).

### `OrderStatusBadge` (`order_status_badge.dart`)
```dart
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;  // pending|broadcasting|shop_confirmed|picked_up|in_transit|delivered|cancelled
}
```
- Color from `AppColors.forOrderStatus(status)`.
- Label is a humanized version of the status (e.g. `shop_confirmed` → "Shop confirmed").
- Small pill: bg = statusColor.withOpacity via `.withValues(alpha:0.12)`, fg = statusColor, label = `AppTypography.label`.

### `EmptyState` (`empty_state.dart`)
```dart
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,   // or illustration widget
    this.title = 'Nothing here yet',
    this.message,
    this.actionLabel,
    this.onAction,
  });
}
```
- Centered column: large muted icon (80px, `AppColors.textMuted`), title (`AppTypography.headline`), message (`AppTypography.caption`), optional `AppButton`.

### `LoadingShimmer` (`loading_shimmer.dart`)
```dart
class LoadingShimmer extends StatefulWidget {   // or use shimmer package
  const LoadingShimmer({super.key, required this.child});
  // ALSO provide:
  static Widget list({int itemCount = 6});       // skeleton list
  static Widget grid({int crossAxisCount = 2}); // skeleton grid
}
```
- Use the `shimmer` package (`^3.0.0`) — add to pubspec if not present.
- Base color `AppColors.surfaceTint`, highlight `AppColors.surface`.
- Skeleton shapes mimic `ProductCard` / list items. **No spinners** per Part A.2.4.

### `ToastNotification` (`toast_notification.dart`)
```dart
class ToastNotification {
  static void show(BuildContext context, String message, {ToastType type = ToastType.info});
  // ToastType: info, success, error, warning
}
```
- Implementation: `ScaffoldMessenger.of(context).showSnackBar(...)` (theme already styles it).
- Success/error/warning tint the snackbar bg to `AppColors.success/error/warning`; info stays `primaryDark`.
- Replaces all `Fluttertoast.showToast(...)` calls (old app uses fluttertoast in `add_to_cart_button.dart`).

## 6. Package additions you may make
- `shimmer: ^3.0.0` for `LoadingShimmer` (the one agent that owns that file edits pubspec + runs `flutter pub get`).

## 7. Do NOT
- Edit anything under `lib/theme/`, `lib/constants.dart`, `lib/main.dart`, `lib/route_generator.dart`.
- Touch any file under `lib/Screens/` or the existing `lib/UI/Widgets/` (those are migrated in Phase 3/4).
- Create a barrel file yet (screens will import components individually).
