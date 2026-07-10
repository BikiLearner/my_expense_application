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
| **Architecture** | Feature-based Clean Architecture (partial) |
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
├── detail_screen.dart
├── firebase_options.dart
│
├── core/                                    ← App-wide infrastructure
│   ├── constants/                           ← (empty, to be populated)
│   ├── routes/                              ← (empty, to be populated)
│   ├── services/
│   │   ├── audio_player.dart                ← Audio playback wrapper
│   │   └── notification_service.dart        ← Local notifications
│   ├── theme/                               ← (empty, to be populated)
│   ├── utils/
│   │   └── indian_number_formatter.dart     ← Indian number formatting
│   └── widgets/                             ← (empty, to be populated)
│
├── shared/                                  ← Cross-feature shared code
│   ├── enums/
│   │   ├── expense_type.dart                ← saving/needed/luxury
│   │   └── transaction_type_enum.dart       ← credit/cash
│   ├── models/
│   │   ├── income_entry.dart                ← IncomeEntry
│   │   ├── month_stats.dart                 ← MonthStats
│   │   └── year_stats.dart                  ← YearStats
│   ├── providers/
│   │   └── year_stat_provider.dart          ← Year/month stats
│   ├── widgets/
│   │   ├── day_expense.dart                 ← DayCard widget
│   │   └── simple_grand_total_form_month.dart ← Month summary banner
│   ├── dialogs/                             ← (empty, to be populated)
│   └── extensions/                          ← (empty, to be populated)
│
├── features/
│   │
│   ├── auth/                                ← Authentication feature
│   │   └── presentation/
│   │       ├── provider/
│   │       │   └── auth_provider.dart       ← Login/Register/Reset
│   │       └── screen/
│   │           ├── auth_wraper.dart         ← StreamBuilder routing
│   │           ├── login_screen.dart        ← Login UI
│   │           └── register_screen.dart     ← Registration UI
│   │
│   ├── expense/                             ← Expense CRUD feature
│   │   ├── data/
│   │   │   ├── datasource/
│   │   │   │   └── expense_firestore_datasource.dart
│   │   │   ├── model/
│   │   │   │   ├── add_expense_request.dart
│   │   │   │   ├── delete_expense_request.dart
│   │   │   │   ├── edit_expense_request.dart
│   │   │   │   ├── expense_items.dart       ← ExpenseItem model
│   │   │   │   └── expense_model.dart       ← ExpenseDay model
│   │   │   └── repository/
│   │   │       └── expense_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repository/
│   │   │       ├── category_repository.dart
│   │   │       ├── expense_repository.dart  ← Interface
│   │   │       ├── income_repository.dart
│   │   │       └── statistics_repository.dart
│   │   └── presentation/
│   │       ├── provider/
│   │       │   └── expence_provider.dart    ← Core expense state (~900 lines)
│   │       ├── screens/
│   │       │   ├── expence_screen.dart      ← Home screen (calendar + tiles)
│   │       │   └── expense_particular_day_overView.dart
│   │       └── widgets/
│   │           ├── add_expense_form.dart
│   │           ├── app_text_fields.dart
│   │           ├── auto_complete_text_fields.dart
│   │           ├── bank_selector_drop_down.dart
│   │           ├── delete_expense_dialog.dart
│   │           ├── edit_expense_dialog.dart
│   │           ├── edit_expense_form.dart
│   │           ├── expense_tiles_new.dart
│   │           ├── expense_type_selector.dart
│   │           └── type_button.dart
│   │
│   ├── history/                             ← History & search feature
│   │   └── presentation/
│   │       ├── provider/
│   │       │   ├── all_expense_provider.dart
│   │       │   ├── history_page_provider.dart
│   │       │   └── month_expense_provider.dart
│   │       └── widgets/
│   │           ├── grand_total_banner.dart
│   │           ├── history_app_bar.dart
│   │           ├── month_list_page.dart
│   │           ├── monthly_expense_list.dart
│   │           ├── monthly_expense_page.dart
│   │           ├── search_expance_screen.dart
│   │           ├── expense_type_breakdown_screen.dart
│   │           ├── bank_monthly_break_down_screen.dart
│   │           └── day_expense_tile.dart
│   │
│   ├── bank/                                ← Bank management feature
│   │   ├── data/
│   │   │   └── model/
│   │   │       ├── bank_model.dart
│   │   │       ├── bank_month_model.dart
│   │   │       └── bank_month_entry_model.dart
│   │   └── presentation/
│   │       ├── provider/
│   │       │   ├── bank_expense_analysis_provider.dart
│   │       │   └── bank_provider.dart       ← Bank CRUD + transfers
│   │       ├── screens/
│   │       │   ├── bank_list_page.dart
│   │       │   ├── bank_form_page.dart
│   │       │   ├── bank_month_page.dart
│   │       │   └── bank_analysis_screen.dart
│   │       └── widgets/
│   │           ├── bank_transfer_dialog.dart
│   │           └── edit_bank_month_dialog.dart
│   │
│   ├── export/                              ← PDF/Excel export feature
│   │   └── presentation/
│   │       ├── provider/
│   │       │   └── export_provider.dart     ← Export + Workmanager
│   │       └── screens/
│   │           └── export_data_page.dart
│   │
│   ├── analytics/                           ← Analytics dashboard feature
│   │   └── presentation/
│   │       ├── provider/
│   │       │   └── analytics_provider.dart  ← 30+ computed metrics
│   │       ├── screens/
│   │       │   └── anaylitcs_scree.dart
│   │       └── widgets/
│   │           ├── all_detail_screens.dart  ← 8 detail drill-down screens
│   │           ├── analytics_header.dart
│   │           ├── bank_usage_card.dart
│   │           ├── category_breakdown_card.dart
│   │           ├── daily_heatmap_card.dart
│   │           ├── kpi_detail_screen.dart
│   │           ├── kpi_strip.dart
│   │           ├── monthly_trend_card.dart
│   │           ├── savings_rate_card.dart
│   │           ├── spending_habits_card.dart
│   │           ├── streak_card.dart
│   │           └── top_expenses_card.dart
│   │
│   └── setting/                             ← Settings & backup feature
│       └── presentation/
│           ├── provider/
│           │   └── setting_provider.dart    ← Backup/restore/repair
│           └── screens/
│               └── setting_page.dart
```

---

## Screen Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        main.dart                            │
│               Firebase.initializeApp()                      │
│            Workmanager.initialize() (non-web)               │
│                    MultiProvider (11)                        │
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

### Navigation Table

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

**Pattern:** Feature-based Clean Architecture (partial) with Provider

### Layer Separation

```
┌─────────────────────────────────────────────────┐
│ presentation/                                   │
│   screens/    → UI (StatefulWidget/Consumer)    │
│   widgets/    → Reusable UI components          │
│   provider/   → ChangeNotifier state classes    │
├─────────────────────────────────────────────────┤
│ domain/                                         │
│   repository/ → Abstract interfaces             │
│   model/      → Domain entities                 │
├─────────────────────────────────────────────────┤
│ data/                                           │
│   datasource/ → Firestore/API calls             │
│   model/      → Data transfer objects (DTOs)    │
│   repository/ → Repository implementations      │
└─────────────────────────────────────────────────┘
```

### Global Providers (initialized in `main.dart`)

| # | Provider | Feature | Responsibility |
|---|---|---|---|
| 1 | `AuthProvider` | auth | Firebase Auth login/register/reset |
| 2 | `ExpenseProvider` | expense | CRUD expenses, date selection, categories, balances |
| 3 | `AllExpensesProvider` | history | Flat Firestore stream + SharedPreferences cache |
| 4 | `MonthExpensesProvider` | history | Monthly expense stats |
| 5 | `BankProvider` | bank | Bank CRUD, monthly budgets, entries, transfers |
| 6 | `BankCreditProvider` | bank | Borrow/Lent/Completed credit CRUD |
| 7 | `HistoryPageProvider` | history | Year/month navigation, history data |
| 8 | `ExportProvider` | export | PDF/Excel export, Workmanager background tasks |
| 9 | `SettingsProvider` | setting | Backup/restore/repair/verify |
| 10 | `YearStatsProvider` | shared | Year-level stats with caching |

### Local Providers (created on-screen)

| Provider | Feature | Responsibility |
|---|---|---|
| `AnalyticsProvider` | analytics | 30+ computed analytics fields per year |
| `BankAnalysisProvider` | bank | Per-bank expense analysis with trends |

---

## Firestore Data Structure

```
users/
  {uid}/
    expenses/
      {yyyy-MM-dd}/
        items/
          {expenseId}  → { title, amount, type, description, createdAt, transactionType }
    year_stats/
      {yyyy}  → { grandTotal }
    month_stats/
      {yyyy-MM}  → { saving, needed, luxury, grandTotal }
    banks/
      {bankId}/
        (doc)  → { bankName, addedDate }
        months/
          {yyyy-MM}/
            (doc)  → { totalAdded, currentAmount, surplusPreviousMonth, incomeThisMonth }
            entries/
              {entryId}  → { amount, description, type, targetBankId, sourceBankId }
    bankCredits/
      {creditId}  → { title, amount, type, status, bankId, createdAt, completedAt }
    income/
      {yyyy}  → { amount }
    backups/
      {backupId}
```

---

## Models

| Model | Location | Fields |
|---|---|---|
| `ExpenseItem` | `features/expense/data/model/` | id, dateId, title, amount, type, description, createdAt, transactionType |
| `ExpenseDay` | `features/expense/data/model/` | dateId, total |
| `AddExpenseRequest` | `features/expense/data/model/` | DTO for adding expenses |
| `EditExpenseRequest` | `features/expense/data/model/` | DTO for editing expenses |
| `DeleteExpenseRequest` | `features/expense/data/model/` | DTO for deleting expenses |
| `BankModel` | `features/bank/data/model/` | id, bankName, addedDate + static `cashBank` |
| `BankMonthModel` | `features/bank/data/model/` | id, totalAdded, currentAmount, surplusPreviousMonth, incomeThisMonth |
| `BankMonthEntry` | `features/bank/data/model/` | id, amount, description, type, targetBankId, sourceBankId |
| `YearStats` | `shared/models/` | year, grandTotal |
| `MonthStats` | `shared/models/` | saving, needed, luxury, grandTotal |
| `IncomeEntry` | `shared/models/` | year, amount |

---

## Enums

| Enum | Location | Values |
|---|---|---|
| `ExpenseType` | `shared/enums/` | `saving`, `needed`, `luxury` — includes `label`, `icon`, `color` extensions |
| `TransactionTypeEnum` | `shared/enums/` | `credit`, `cash` |

---

## Services

| Service | Location | Purpose |
|---|---|---|
| `NotificationService` | `core/services/` | Local notifications for export progress/completion |
| `AudioPlayerService` | `core/services/` | Audio playback wrapper |

---

## Key Features

1. **Authentication** — Email/password login, registration, email verification, password reset, account deletion
2. **Expense CRUD** — Add/edit/delete with title autocomplete, Indian number format, description, type, payment method
3. **Calendar View** — Date picker on home screen, tap date to see/add expenses
4. **Expense Classification** — Three-tier: Saving, Needed, Luxury with color coding
5. **Transaction Types** — Cash vs Credit (linked to specific bank)
6. **Multi-Bank Management** — Create/edit/delete banks, monthly budget tracking, surplus carry-forward, income management
7. **Inter-Bank Transfers** — Transfer money between banks with transaction logging
8. **Credit Tracking** — Borrow/Lent tracking with active/completed status
9. **Search** — Search by title with min/max amount filter, month/year selection
10. **History Navigation** — Year/month navigation, monthly breakdown, per-date drill-down
11. **Analytics Dashboard** — 12+ visualization cards with 8 detail drill-down screens
12. **PDF/Excel Export** — Monthly/yearly reports with Workmanager background support
13. **File Management** — View, open, share exported files
14. **Backup/Restore** — Full Firestore backup creation and restoration
15. **Data Repair/Verify** — Data integrity tools
16. **Local Notifications** — Export progress and completion alerts
17. **SharedPreferences Cache** — Local caching for offline/fast loading

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
| Dart files | ~76 |
| Features | 7 (auth, expense, history, bank, export, analytics, setting) |
| Providers | 12 |
| Models | 11 |
| Screens | 20+ |
| Widgets | 15+ |
| Services | 2 |
