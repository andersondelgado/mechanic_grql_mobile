import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers.dart';

class MonthlyBreakdownModel {
  final String month;
  final double income;
  final double expenses;
  final double balance;

  const MonthlyBreakdownModel({
    this.month = '',
    this.income = 0.0,
    this.expenses = 0.0,
    this.balance = 0.0,
  });

  factory MonthlyBreakdownModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return MonthlyBreakdownModel(
      month: (json['month'] ?? '').toString(),
      income: toDouble(json['income']),
      expenses: toDouble(json['expenses']),
      balance: toDouble(json['balance']),
    );
  }
}

class DashboardStatsModel {
  final int totalClients;
  final int totalVehicles;
  final int vehiclesInShop;
  final int completedRepairs;
  final double totalIncomeMonth;
  final double totalExpensesMonth;
  final double balanceMonth;
  final double totalIncomeAll;
  final double totalExpensesAll;
  final double totalBalanceAll;
  final double accountsReceivableTotal;
  final double accountsPayableTotal;
  final List<MonthlyBreakdownModel> monthlyBreakdown;

  const DashboardStatsModel({
    this.totalClients = 0,
    this.totalVehicles = 0,
    this.vehiclesInShop = 0,
    this.completedRepairs = 0,
    this.totalIncomeMonth = 0.0,
    this.totalExpensesMonth = 0.0,
    this.balanceMonth = 0.0,
    this.totalIncomeAll = 0.0,
    this.totalExpensesAll = 0.0,
    this.totalBalanceAll = 0.0,
    this.accountsReceivableTotal = 0.0,
    this.accountsPayableTotal = 0.0,
    this.monthlyBreakdown = const [],
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map)
        ? (rawJson['data'] as Map).cast<String, dynamic>()
        : rawJson;

    int toInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double toDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final rawMonthly = json['monthly_breakdown'];
    final List<MonthlyBreakdownModel> breakdownList = [];
    if (rawMonthly is List) {
      for (final item in rawMonthly) {
        if (item is Map) {
          breakdownList.add(
            MonthlyBreakdownModel.fromJson(item.cast<String, dynamic>()),
          );
        }
      }
    }

    return DashboardStatsModel(
      totalClients: toInt(json['total_clients']),
      totalVehicles: toInt(json['total_vehicles']),
      vehiclesInShop: toInt(json['vehicles_in_shop']),
      completedRepairs: toInt(json['completed_repairs']),
      totalIncomeMonth: toDouble(json['total_income_month']),
      totalExpensesMonth: toDouble(json['total_expenses_month']),
      balanceMonth: toDouble(json['balance_month']),
      totalIncomeAll: toDouble(json['total_income_all']),
      totalExpensesAll: toDouble(json['total_expenses_all']),
      totalBalanceAll: toDouble(json['total_balance_all']),
      accountsReceivableTotal: toDouble(json['accounts_receivable_total']),
      accountsPayableTotal: toDouble(json['accounts_payable_total']),
      monthlyBreakdown: breakdownList,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStatsModel>>((
      ref,
    ) {
      final apiClient = ref.read(apiClientProvider);
      return DashboardNotifier(apiClient);
    });

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStatsModel>> {
  final ApiClient _apiClient;

  DashboardNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiClient.getDashboardStats();
      if (data != null) {
        state = AsyncValue.data(DashboardStatsModel.fromJson(data));
      } else {
        state = const AsyncValue.data(DashboardStatsModel());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
