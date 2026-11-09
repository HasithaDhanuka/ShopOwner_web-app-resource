import 'package:flutter/material.dart';
import 'package:web_app/screen/monthly_income_view.dart';
import 'package:web_app/screen/popular_item_view.dart';

class DataAnalysisView extends StatelessWidget {
  const DataAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Analysis'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const MonthlyIncomeView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Monthly Income'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const PopularItemView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Popular Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
