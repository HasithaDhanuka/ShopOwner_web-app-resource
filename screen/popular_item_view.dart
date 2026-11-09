import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_app/Utils/colors.dart';
import 'package:web_app/firebase/firebase_userOrder.dart';
import 'package:web_app/model/user_order.dart';

class PopularItemView extends StatefulWidget {
  const PopularItemView({super.key});

  @override
  State<PopularItemView> createState() => _PopularItemViewState();
}

class _PopularItemViewState extends State<PopularItemView> {
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
      appBar: AppBar(title: const Text('Popular Item')),
      body: StreamBuilder<List<UserOrder>>(
        stream: readDeleteHistoryOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _StatusView(
              icon: Icons.cloud_off_outlined,
              message: 'Could not load order history.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildDashboard(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDashboard(List<UserOrder> orders) {
    final itemCounts = <String, int>{};
    for (final order in orders) {
      final date = order.timestamp?.toDate();
      if (date == null ||
          date.year != _selectedYear ||
          date.month != _selectedMonth) {
        continue;
      }

      for (final item in order.userOrders) {
        final itemName = item.itemName.trim();
        if (itemName.isEmpty) continue;
        // Each stored FoodItem represents one purchased unit; itemCount is stock.
        itemCounts.update(
          itemName,
          (currentCount) => currentCount + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final rankings = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final soldItemCount = rankings.fold<int>(0, (sum, item) => sum + item.value);
    final topItems = rankings.take(5).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  if (rankings.isEmpty)
                    const _StatusView(
                      icon: Icons.storefront_outlined,
                      message: 'No sold items were found for this month.',
                    )
                  else ...[
                    _buildHighlights(
                      topItem: rankings.first,
                      soldItemCount: soldItemCount,
                    ),
                    const SizedBox(height: 20),
                    _buildChart(topItems),
                    const SizedBox(height: 20),
                    _buildRankingList(rankings),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Best sellers', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Popular items for the selected month',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyColor.myWhite70,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Previous year',
          onPressed: () => setState(() => _selectedYear--),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$_selectedYear',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MyColor.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          tooltip: 'Next year',
          onPressed: () => setState(() => _selectedYear++),
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
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
            if (month != null) setState(() => _selectedMonth = month);
          },
        ),
      ],
    );
  }

  Widget _buildHighlights({
    required MapEntry<String, int> topItem,
    required int soldItemCount,
  }) {
    final compact = MediaQuery.of(context).size.width < 640;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: compact ? double.infinity : 340,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: MyColor.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.emoji_events_outlined,
                        color: MyColor.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top seller',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 5),
                        Text(
                          topItem.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${topItem.value} sold',
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
        ),
        SizedBox(
          width: compact ? double.infinity : 260,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: MyColor.secondary, size: 30),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items sold',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 5),
                      Text(
                        '$soldItemCount',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<MapEntry<String, int>> topItems) {
    final maxCount = topItems.first.value;
    final chartMax = maxCount == 0 ? 1.0 : maxCount * 1.2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 this month',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Number of items sold',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyColor.myWhite70,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
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
                        reservedSize: 42,
                        interval: chartMax / 4,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
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
                          final rank = value.toInt();
                          if (rank < 0 || rank >= topItems.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '#${rank + 1}',
                              style: const TextStyle(
                                color: MyColor.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(topItems.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: topItems[index].value.toDouble(),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: index == 0
                                ? [MyColor.tertiary, MyColor.primary]
                                : [
                                    MyColor.secondary.withOpacity(0.55),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(topItems.length, (index) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: index == 0 ? MyColor.primary : MyColor.secondary,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: MyColor.onPrimary, fontSize: 11),
                    ),
                  ),
                  label: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Text(
                      '${topItems[index].key} · ${topItems[index].value}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingList(List<MapEntry<String, int>> rankings) {
    final highestCount = rankings.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly ranking',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...List.generate(rankings.length, (index) {
              final entry = rankings[index];
              final progress = entry.value / highestCount;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _rankBadge(index + 1),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: MyColor.outline.withOpacity(0.25),
                              valueColor: AlwaysStoppedAnimation(
                                index == 0 ? MyColor.primary : MyColor.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${entry.value} sold',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: index == 0 ? MyColor.primary : MyColor.myWhite,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final color = switch (rank) {
      1 => MyColor.primary,
      2 => MyColor.secondary,
      3 => MyColor.tertiary,
      _ => MyColor.darkSurfaceRaised,
    };
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Text(
        '$rank',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.icon, required this.message});

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
            Icon(icon, color: MyColor.myWhite70, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
