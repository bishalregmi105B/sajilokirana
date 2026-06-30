/// SajiloKirana shared constants.
///
/// Rebranded from the Blinkit clone: Nepali context (NPR currency, +977 dial
/// code, Kathmandu-area placeholders, festival calendar). See `docs/AUDIT.md`
/// §8 — the old `constants.dart` used Indian ₹ and +91.

/// Nepali Rupee symbol. Replaces the old `₹`.
const String appCurrencySymbol = "रु";

/// International dial code for Nepal.
const String appDialCode = "+977";

/// App display name.
const String appName = "SajiloKirana";

/// Backend base URL — override via --dart-define=API_BASE_URL=... at build time.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000', // Android emulator → host machine
);

enum RequestingMethods { get, post, put, delete }

/// Dummy product names used by the search delegate until the backend catalog
/// (Part D) is wired in.
const List<String> kDummyProducts = [
  "Wai Wai",
  "Tata Salt",
  "Amul Taaza Milk",
  "Nepal Tea",
  "Gundruk",
  "Sel Roti Flour",
  "Dhindo Atta",
  "Chiura (Beaten Rice)",
  "Sukuti",
  "Yak Cheese",
  "Daal (Lentils)",
  "Mustard Oil",
  "Timur (Sichuan Pepper)",
  "Jimbu",
  "Ghee",
  "Curd (Dahi)",
  "Paneer",
  "Eggs",
  "Sugarcane Juice",
  "Momo Wrappers",
  "Coca-Cola",
  "Mountain Dew",
  "Hukka",
  "Khajuri (Dates)",
  "Kishmish (Raisins)",
];

/// Short brand intro shown on the About screen. Replaces the old Blinkit
/// `introParagraph`.
const String introParagraph =
    'SajiloKirana brings your neighborhood kirana shop online. Order groceries '
    'and daily essentials from trusted local shops near you and get them '
    'delivered in minutes — no more queues, no more last-minute runs to the '
    'shop. We work with the kirana stores you already know, so the dal, chiura, '
    'tarkari and household items you need every day arrive fresh, fast and at '
    'fair prices. Track your order in real time, pay your way (eSewa, Khalti, '
    'Fonepay or cash), and support your local shopkeepers with every order.';

/// Sample coupons. Amounts now in NPR (was ₹).
const List<Map<String, dynamic>> kDummyCoupons = [
  {
    "headline": "रु100 off your first order",
    "couponCode": "NAYASADHAN",
    "dataPoints": [
      "रु100 off your first order",
      "Minimum order value: रु1,000",
      "Maximum discount: रु100",
      "Valid for new users only",
    ],
  },
  {
    "headline": "रु50 off on fresh vegetables",
    "couponCode": "TARKARI50",
    "dataPoints": [
      "रु50 off on fresh vegetables",
      "Minimum order value: रु400",
      "Valid till end of month",
    ],
  },
  {
    "headline": "Flat 15% off on dairy",
    "couponCode": "DAHI15",
    "dataPoints": [
      "Flat 15% off on dairy products",
      "Minimum order value: रु500",
      "Maximum discount: रु100",
    ],
  },
  {
    "headline": "Free delivery on orders over रु1,500",
    "couponCode": "FREEDEL",
    "dataPoints": [
      "Free home delivery",
      "Minimum order value: रु1,500",
      "Within 3km radius",
    ],
  },
  {
    "headline": "Festival special — Dashain dhamaka",
    "couponCode": "DASHAIN10",
    "dataPoints": [
      "10% off during Dashain",
      "Maximum discount: रु500",
      "Festival season only",
    ],
  },
];

/// Top-level category list. Nepal-relevant categories replace the Blinkit set.
const List<String> kCategoriesTitles = [
  "Paan & Supari",
  "Dairy, Bread & Eggs",
  "Fruits & Vegetables",
  "Cold Drinks & Juices",
  "Snacks & Namkeen",
  "Breakfast & Instant Food",
  "Sweets & Mithai",
  "Biscuits & Bakery",
  "Tea & Coffee",
  "Atta, Rice & Dal",
  "Masala & Oil",
  "Sauces & Spreads",
  "Chicken, Meat & Fish",
  "Puja Samagri",
  "Baby Care",
  "Pharma & Wellness",
  "Cleaning Essentials",
  "Home & Kitchen",
  "Personal Care",
  "Pet Food & Care",
];

/// Lightweight Nepali festival / holiday flag reference for demand-forecasting
/// feature flags (Part E.5) and in-app banners. Months are approximate windows.
const List<Map<String, String>> kFestivalCalendar = [
  {"name": "Dashain", "window": "Sep–Oct", "impact": "peak"},
  {"name": "Tihar / Deepawali", "window": "Oct–Nov", "impact": "peak"},
  {"name": "Chhath", "window": "Nov", "impact": "high"},
  {"name": "Maghe Sankranti", "window": "Jan", "impact": "medium"},
  {"name": "Holi", "window": "Mar", "impact": "high"},
  {"name": "Nepali New Year", "window": "Apr", "impact": "medium"},
  {"name": "Buddha Jayanti", "window": "May", "impact": "low"},
  {"name": "Teej", "window": "Sep", "impact": "high"},
];

/// Icon references used on the profile quick-actions. Kept as remote icons8
/// URLs (as in the original) until local assets are produced.
const List<String> kSvgIcons = [
  "https://img.icons8.com/ios/50/wallet--v1.png",
  "https://img.icons8.com/ios/50/filled-chat.png",
  "https://img.icons8.com/dotty/80/token-card-code.png",
];
