import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_app/Utils/colors.dart';
import 'package:web_app/firebase/firebase_userOrder.dart';
import 'package:web_app/model/user_order.dart';

class MonthlyIncomeView extends StatefulWidget {
  const MonthlyIncomeView({super.key});

  @override
  State<MonthlyIncomeView> createState() => _MonthlyIncomeViewState();
}

class _MonthlyIncomeViewState extends State<MonthlyIncomeView> {
  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedYear = today.year;
    _selectedMonth = today.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Income')),
      body: StreamBuilder<List<UserOrder>>(
        stream: readDeleteHistoryOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.cloud_off_outlined,
              message: 'Could not load income data.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildIncomeDashboard(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildIncomeDashboard(List<UserOrder> records) {
    final monthlyIncome = List<double>.filled(12, 0);
    for (final order in records) {
      final date = order.timestamp?.toDate();
      if (date == null || date.year != _selectedYear) continue;
      monthlyIncome[date.month - 1] += order.userTotalPrice.toDouble();
    }

    final totalIncome = monthlyIncome.fold<double>(0, (sum, value) => sum + value);
    final averageIncome = totalIncome / 12;
    final selectedIncome = monthlyIncome[_selectedMonth - 1];
    final peakIncome = monthlyIncome.reduce((a, b) => a > b ? a : b);
    final chartMax = peakIncome == 0 ? 1.0 : peakIncome * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildYearSelector(),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _summaryCard(
                        title: 'Yearly Income',
                        value: _formatCurrency(totalIncome),
                        caption: 'Total for $_selectedYear',
                        icon: Icons.account_balance_wallet_outlined,
                        accent: MyColor.primary,
                      ),
                      _summaryCard(
                        title: 'Monthly Average',
                        value: _formatCurrency(averageIncome),
                        caption: 'Average across 12 months',
                        icon: Icons.show_chart,
                        accent: MyColor.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income by month',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compare each month of $_selectedYear',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: MyColor.myWhite70,
                                ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 300,
                            child: BarChart(
                              BarChartData(
                                minY: 0,
                                maxY: chartMax,
                                alignment: BarChartAlignment.spaceAround,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: chartMax / 4,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: MyColor.outline.withOpacity(0.3),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 90,
                                      interval: chartMax / 4,
                                      getTitlesWidget: (value, meta) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          _formatAxisCurrency(value),
                                          style: const TextStyle(
                                            color: MyColor.myWhite70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      getTitlesWidget: (value, meta) {
                                        final monthIndex = value.toInt();
                                        if (monthIndex < 0 || monthIndex > 11) {
                                          return const SizedBox.shrink();
                                        }
                                        final selected = monthIndex + 1 == _selectedMonth;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _monthNames[monthIndex],
                                            style: TextStyle(
                                              color: selected
                                                  ? MyColor.primary
                                                  : MyColor.myWhite70,
                                              fontWeight: selected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(12, (index) {
                                  final isSelected = index + 1 == _selectedMonth;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: monthlyIncome[index],
                                        width: 16,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: isSelected
                                              ? [MyColor.tertiary, MyColor.primary]
                                              : [
                                                  MyColor.secondary.withOpacity(0.65),
                                                  MyColor.secondary,
                                                ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              color: MyColor.primary),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Selected month')),
                          DropdownButton<int>(
                            value: _selectedMonth,
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_monthNames[index]),
                              ),
                            ),
                            onChanged: (month) {
                              if (month != null) {
                                setState(() => _selectedMonth = month);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatCurrency(selectedIncome),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: MyColor.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (records.isEmpty) ...[
                    const SizedBox(height: 20),
                    const _MessageView(
                      icon: Icons.insights_outlined,
                      message: 'No orders were found in removeOrders.',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearSelector() {
    return Row(
      children: [
        Text('Annual overview', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        IconButton(
          tooltip: 'Previous year',
          onPressed: () => setState(() => _selectedYear--),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$_selectedYear',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyColor.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          tooltip: 'Next year',
          onPressed: () => setState(() => _selectedYear++),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String caption,
    required IconData icon,
    required Color accent,
  }) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MyColor.myWhite70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) =>
      '${amount.toStringAsFixed(0)}￥';

  String _formatAxisCurrency(double amount) =>
      '${amount.toStringAsFixed(0)}￥';
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: MyColor.myWhite70, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
