# Expense App

A comprehensive personal expense tracking application built with Flutter and Firebase.

---

## Project Info

| Field | Value |
|---|---|
| **App Name** | `expence_app` |
| **Version** | `1.0.0+1` |
| **Description** | Track your expenses with analytics, bank management, and export capabilities |
| **Dart SDK** | `^3.8.1` |
| **State Management** | Provider (ChangeNotifier) |
| **Backend** | Firebase (Auth + Firestore) |
| **Firebase Project** | `my-expences-proj` |

---

## Dependencies

### Core
| Package | Version |
|---|---|
| `firebase_core` | `^3.12.1` |
| `firebase_auth` | `^5.5.4` |
| `cloud_firestore` | `^5.6.5` |
| `provider` | `^6.1.2` |

### UI & Charts
| Package | Version |
|---|---|
| `google_fonts` | `^6.2.1` |
| `fl_chart` | `^0.70.2` |
| `animated_custom_dropdown` | `^1.13.0` |
| `intl` | `^0.19.0` |

### Export & Files
| Package | Version |
|---|---|
| `excel` | `^4.0.6` |
| `pdf` | `^3.11.3` |
| `path_provider` | `^2.1.5` |
| `open_file` | `^3.5.4` |
| `share_plus` | `^10.1.4` |

### Utilities
| Package | Version |
|---|---|
| `shared_preferences` | `^2.3.4` |
| `audioplayers` | `^6.1.0` |
| `flutter_local_notifications` | `^18.0.1` |
| `permission_handler` | `^11.3.1` |
| `workmanager` | `^0.5.2` |

---

## Folder Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── migrate_funtion.dart
├── register_screen.dart
├── detail_screen.dart
│
├── auth/
│   ├── provider/
│   │   └── auth_provider.dart
│   └── screen/
│       ├── auth_wraper.dart
│       └── login_screen.dart
│
├── expense_home/
│   ├── models/
│   │   ├── expense_model.dart
│   │   └── expense_items.dart
│   ├── provider/
│   │   └── expence_provider.dart
│   ├── screens/
│   │   └── expence_screen.dart
│   └── widgets/
│       ├── add_expense_form.dart
│       ├── app_text_fields.dart
│       ├── auto_complete_text_fields.dart
│       ├── bank_selector_drop_down.dart
│       ├── delete_expense_dialog.dart
│       ├── edit_expense_dialog.dart
│       ├── edit_expense_form.dart
│       ├── expense_tiles_new.dart
│       ├── expense_type_selector.dart
│       └── type_button.dart
│
├── expense_history/
│   ├── provider/
│   │   └── history_page_provider.dart
│   ├── screens/
│   │   └── history_screen.dart
│   └── widgets/
│       └── grand_total_banner.dart
│
├── history_screens/
│   ├── bank_monthly_break_down_screen.dart
│   ├── day_expense_tile.dart
│   ├── expense_type_breakdown_screen.dart
│   ├── history_app_bar.dart
│   ├── month_list_page.dart
│   ├── monthly_expense_list.dart
│   ├── monthly_expense_page.dart
│   ├── search_expance_screen.dart
│   └── simple_grand_total_form_month.dart
│
├── models/
│   ├── bank_model.dart
│   ├── bank_month_model.dart
│   ├── bank_month_entry_model.dart
│   ├── credit_model.dart
│   ├── income_entry.dart
│   ├── month_stats.dart
│   └── year_stats.dart
│
├── enums/
│   ├── expense_type.dart
│   ├── indian_number_formatter.dart
│   └── transaction_type_enum.dart
│
├── providers/
│   ├── all_expense_provider.dart
│   ├── bank_expense_analysis_provider.dart
│   ├── bank_provider.dart
│   ├── credit_provider.dart
│   ├── export_provider.dart
│   ├── month_expense_provider.dart
│   └── year_stat_provider.dart
│
├── analytics/
│   ├── provider/
│   │   └── analytics_provider.dart
│   ├── screens/
│   │   └── anaylitcs_scree.dart
│   └── widgets/
│       ├── all_detail_screens.dart
│       ├── analytics_header.dart
│       ├── bank_usage_card.dart
│       ├── category_breakdown_card.dart
│       ├── daily_heatmap_card.dart
│       ├── kpi_detail_screen.dart
│       ├── kpi_strip.dart
│       ├── monthly_trend_card.dart
│       ├── savings_rate_card.dart
│       ├── spending_habits_card.dart
│       ├── streak_card.dart
│       └── top_expenses_card.dart
│
├── pages/
│   ├── bank_list_page.dart
│   ├── bank_form_page.dart
│   ├── bank_month_page.dart
│   ├── bank_analysis_screen.dart
│   ├── edit_bank_month_dialog.dart
│   ├── export_data_page.dart
│   ├── expense_particular_day_overView.dart
│   └── credit_borrow_lent/
│       └── bank_credit_screen.dart
│
├── credit_card_part/
│   ├── credit_list_montly.dart
│   ├── credit_month_list_tiles.dart
│   └── month_credit_expense_page.dart
│
├── setting/
│   ├── provider/
│   │   └── setting_provider.dart
│   └── screens/
│       └── setting_page.dart
│
├── services/
│   ├── audio_player.dart
│   └── notification_service.dart
│
├── reusable widgets/
│   ├── day_expense.dart
│   └── transaction_type_chips.dart
│
└── widgets/
    └── bank_transfer_dialog.dart
```

---

## Screen Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        main.dart                            │
│               Firebase.initializeApp()                      │
│            Workmanager.initialize() (non-web)               │
│                    MultiProvider (9)                         │
│                         │                                   │
│                    MaterialApp                               │
│                         │                                   │
│                     AuthWrapper                              │
│                   (StreamBuilder)                            │
│                    ╱           ╲                             │
│           Not Logged In    Logged In                         │
│               │                 │                            │
│         LoginScreen       ExpenseScreen ◄─── HOME           │
│         RegisterScreen         │                            │
│                          ┌─────┼──────────┬──────────┐      │
│                          │     │          │          │      │
│                      History  Bank      Credit    Settings  │
│                          │     │          │          │      │
│                    ┌─────┘  ┌──┘       ┌──┘     ┌───┘      │
│                    │        │          │        │           │
│              GrandTotal   BankList  CreditScreen Settings  │
│              Banner       │          │        (Backup/      │
│                │       BankForm   Borrow/     Restore/      │
│           ┌────┤       │        Lent Tabs    Repair)       │
│           │    │    BankMonth                   │          │
│        Month  Search  │                        │          │
│        List   │    BankAnalysis                 │          │
│           │   │                                │          │
│      Monthly  ExpenseType                   ExportData     │
│      Expense  Breakdown                     (PDF/Excel)    │
│      Page     │                                             │
│           BankMonthly                                       │
│           Breakdown                                         │
│                                                             │
│       ExpenseAnalyticsScreen ◄─── (via AppBar menu)         │
│              │                                              │
│         KPI Strip                                           │
│         Monthly Trend                                       │
│         Category Breakdown                                  │
│         Daily Heatmap                                       │
│         Bank Usage                                          │
│         Spending Habits                                     │
│         Savings Rate                                        │
│         Behaviour/Streaks                                   │
│         Top Expenses                                        │
│              │                                              │
│         8 Detail Drill-down Screens                         │
└─────────────────────────────────────────────────────────────┘
```

### Navigation Details

| From | Action | To |
|---|---|---|
| `ExpenseScreen` | Tap calendar date | `DateDetailScreen` |
| `ExpenseScreen` | FAB (+) | Add expense form (bottom sheet) |
| `ExpenseScreen` | AppBar → History | `HistoryScreen` |
| `ExpenseScreen` | AppBar → Banks | `BankPage` |
| `ExpenseScreen` | AppBar → Credit | `BankCreditScreen` |
| `ExpenseScreen` | AppBar → Settings | `ExpenseMaintenancePage` |
| `ExpenseScreen` | AppBar → Analytics | `ExpenseAnalyticsScreen` |
| `ExpenseScreen` | AppBar → Export | `ExportDataPage` |
| `HistoryScreen` | Tap month tile | `MonthlyExpensePage` |
| `HistoryScreen` | Tap day tile | `DateDetailScreen` |
| `HistoryScreen` | Search | `SearchExpensesScreen` |
| `HistoryScreen` | Type filter | `ExpenseTypeBreakdownScreen` |
| `BankPage` | FAB (+) | `BankFormPage` |
| `BankPage` | Tap bank | `BankAccountPage` |
| `BankAccountPage` | Transfer | `BankTransferDialog` |
| `BankAccountPage` | Analytics | `BankAnalysisScreen` |

---

## Architecture

**Pattern:** Provider (ChangeNotifier-based state management)

### Global Providers (initialized in `main.dart`)

| # | Provider | Responsibility |
|---|---|---|
| 1 | `AuthProvider` | Firebase Auth: login, register, reset, delete, signout |
| 2 | `ExpenseProvider` | Expense CRUD, title autocomplete, date/bank selection |
| 3 | `AllExpensesProvider` | Flat Firestore stream + SharedPreferences cache |
| 4 | `MonthExpensesProvider` | Monthly expense stats (totalDays, avgPerDay, highestDay) |
| 5 | `BankProvider` | Bank CRUD, bank month CRUD, month entries, transfers |
| 6 | `BankCreditProvider` | Borrow/Lent/Completed credit CRUD |
| 7 | `HistoryPageProvider` | Year/month navigation, history data fetching |
| 8 | `ExportProvider` | PDF/Excel export, background Workmanager tasks |
| 9 | `SettingsProvider` | Backup/restore/repair/verify Firestore data |

### Local Providers (created on-screen)

| Provider | Responsibility |
|---|---|
| `AnalyticsProvider` | 30+ computed analytics fields per year |
| `BankAnalysisProvider` | Per-bank expense analysis with trends |
| `YearStatsProvider` | Year/month stats fetching and caching |

---

## Firestore Data Structure

```
users/
  {uid}/
    expenses/
      {yyyy-MM-dd}/
        items/
          {docId}  →  { id, title, amount, type, description, createdAt, transactionType }
    banks/
      {bankId}/
        (doc)  →  { id, bankName, addedDate }
        months/
          {yyyy-MM}/
            (doc)  →  { id, totalAdded, currentAmount, surplusPreviousMonth, incomeThisMonth, createdAt, updatedAt }
            entries/
              {entryId}  →  { id, amount, description, createdAt, type, targetBankId, sourceBankId }
    bankCredits/
      {docId}  →  { id, title, amount, type, status, bankId, createdAt, completedAt }
    yearStats/
      {yyyy}/
        (doc)  →  { year, grandTotal }
      {yyyy-MM}/
        (doc)  →  { month, saving, needed, luxury, grandTotal }
    incomes/
      {year}/
        (doc)  →  { year, amount }
```

---

## Models

| Model | Fields | Serialization |
|---|---|---|
| `ExpenseDay` | `dateId`, `total` | Simple |
| `ExpenseItem` | `id`, `dateId`, `title`, `amount`, `type`, `description`, `createdAt`, `transactionType` | `fromFirestore()`, `toJson()`, `fromJson()` |
| `BankModel` | `id`, `bankName`, `addedDate` | `fromFirestore()`, `toMap()` + static `cashBank` |
| `BankMonthModel` | `id`, `totalAdded`, `currentAmount`, `surplusPreviousMonth`, `incomeThisMonth`, `createdAt`, `updatedAt` | `fromFirestore()`, `toMap()` |
| `BankMonthEntry` | `id`, `amount`, `description`, `createdAt`, `type`, `targetBankId`, `sourceBankId` | `fromFirestore()`, `toMap()` |
| `BankCredit` | `id`, `title`, `amount`, `type`, `status`, `bankId`, `createdAt`, `completedAt` | `fromFirestore()`, `toMap()` |
| `IncomeEntry` | `year`, `amount` | `toMap()`, `fromMap()` |
| `YearStats` | `year`, `grandTotal` | `fromFirestore()`, `toMap()` |
| `MonthStats` | `month`, `saving`, `needed`, `luxury`, `grandTotal` | `fromFirestore()`, `toMap()` |

---

## Enums

| Enum | Values |
|---|---|
| `ExpenseType` | `saving`, `needed`, `luxury` |
| `TransactionTypeEnum` | `credit`, `cash` |
| `EntryType` | Income, Expense, Transfer variants (in BankMonthEntry) |
| `CreditType` | `borrow`, `lent` |
| `CreditStatus` | `active`, `completed` |

---

## Services

| Service | Purpose |
|---|---|
| `NotificationService` | Local notifications for export progress/completion (Android channel: `export_channel`) |
| `AudioPlayerService` | Audio playback wrapper using `audioplayers` |

---

## Key Features

1. **Authentication** — Email/password login, registration, email verification, password reset, account deletion
2. **Expense CRUD** — Add/edit/delete expenses with title autocomplete, amount in Indian number format, description, type, payment method
3. **Calendar View** — Date picker on home screen, tap date to see/add expenses
4. **Expense Classification** — Three-tier: Saving, Needed, Luxury with color coding
5. **Transaction Types** — Cash vs Credit (linked to specific bank)
6. **Multi-Bank Management** — Create/edit/delete banks, monthly budget tracking, surplus carry-forward, income management
7. **Inter-Bank Transfers** — Transfer money between banks with transaction logging
8. **Credit Tracking** — Borrow/Lent tracking with active/completed status
9. **Search** — Search by title with min/max amount filter, month/year selection
10. **History Navigation** — Year/month navigation, monthly breakdown, per-date drill-down
11. **Analytics Dashboard** — 12+ visualization cards:
    - KPI Strip (Total Spent, Peak Day, Daily Average, Transactions)
    - Monthly Trend bar chart (animated)
    - Category Breakdown (horizontal bars)
    - Daily Heatmap (GitHub-style)
    - Bank Usage (segmented bar)
    - Spending Habits (stacked bar: Luxury/Needed/Saving)
    - Savings Rate (circular gauge + monthly bars)
    - Behaviour/Streaks (weekday chart)
    - Top Expenses (ranked list)
    - 8 detail drill-down screens
12. **PDF Export** — Monthly/yearly reports with Workmanager background support
13. **Excel Export** — Monthly/yearly reports
14. **File Management** — View, open, share exported files
15. **Backup/Restore** — Full Firestore backup creation and restoration
16. **Data Repair/Verify** — Data integrity tools
17. **Notifications** — Local notifications for export progress and completion
18. **Data Migration** — One-time Firestore restructuring function
19. **SharedPreferences Cache** — Local caching for offline/fast loading

---

## Platform Support

| Platform | Status |
|---|---|
| Android | Supported |
| iOS | Supported |
| Web | Supported |
| macOS | Supported |
| Windows | Supported |
| Linux | Not supported |

---

## Theme

Dark theme throughout:
- Background: `#121212`
- Surface: `#1E1E1E`
- Cards: `#2C2C2C`
- Borders: `#3C3C3C`
- Accent: `#64FFDA` (teal)

---

## Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK `^3.8.1`
- Firebase project configured

### Setup
```bash
flutter pub get
flutterfire configure
flutter run
```

### Build
```bash
flutter build apk
flutter build ios
flutter build web
```

---

## Project Stats

| Metric | Count |
|---|---|
| Dart files | 80 |
| Providers | 12 |
| Models | 9 |
| Screens/Pages | 20+ |
| Widgets | 15+ |
| Services | 2 |
