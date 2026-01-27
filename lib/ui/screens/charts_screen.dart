import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  late DateTime _selectedMonth;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final theme = Theme.of(context);

    final categoryTotals = transactionsNotifier.getCategoryTotals(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final totalAmount = categoryTotals.values.fold<double>(0, (a, b) => a + b);
    final dailyTrend = transactionsNotifier.getDailyTrend(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('📊 分析')),
      body: transactions.isEmpty
          ? _buildEmptyState(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(theme),
                  const SizedBox(height: 24),
                  _buildPieChart(theme, categoryTotals, totalAmount),
                  const SizedBox(height: 32),
                  _buildTrendSection(
                    theme,
                    dailyTrend,
                    categoryTotals.keys.toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/crab_mascot.png', width: 140, height: 140),
          const SizedBox(height: 24),
          Text(
            '財富沙灘暫時空空如也',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '開始記帳，讓小螃幫你分析財富流向！',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          DateFormat('yyyy年M月').format(_selectedMonth),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed:
              _selectedMonth.month < DateTime.now().month ||
                  _selectedMonth.year < DateTime.now().year
              ? _nextMonth
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildPieChart(
    ThemeData theme,
    Map<String, double> categoryTotals,
    double totalAmount,
  ) {
    if (categoryTotals.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(
            '本月沒有支出記錄',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final List<Color> colors = [
      theme.colorScheme.primary, // Coral Red
      theme.colorScheme.secondary, // Ocean Green
      const Color(0xFFFFB74D), // Amber
      const Color(0xFF64B5F6), // Light Blue
      const Color(0xFF81C784), // Light Green
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFE57373), // Red
      const Color(0xFF90A4AE), // Blue Gray
    ];

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: sortedEntries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final categoryEntry = entry.value;
                        final percentage =
                            (categoryEntry.value / totalAmount) * 100;

                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: categoryEntry.value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '總支出',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryEntry = entry.value;

                return _LegendItem(
                  color: colors[index % colors.length],
                  label: categoryEntry.key,
                  amount: categoryEntry.value,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(
    ThemeData theme,
    List<MapEntry<DateTime, double>> trend,
    List<String> categories,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📈 趨勢',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String?>(
                  value: _selectedCategory,
                  hint: const Text('全部'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    ...categories.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: trend.every((e) => e.value == 0)
                  ? Center(
                      child: Text(
                        '無資料',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _calculateInterval(trend),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max || value == meta.min) {
                                  return const SizedBox();
                                }
                                return Text(
                                  '\$${value.toInt()}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < trend.length) {
                                  // Show only specific days to avoid crowding
                                  if (trend[index].key.day % 5 != 1 &&
                                      trend[index].key.day !=
                                          _daysInMonth(_selectedMonth)) {
                                    return const SizedBox();
                                  }
                                  return Text(
                                    '${trend[index].key.day}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: trend.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.value);
                            }).toList(),
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  theme.colorScheme.secondary.withValues(
                                    alpha: 0,
                                  ),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(List<MapEntry<DateTime, double>> trend) {
    if (trend.isEmpty) return 1000;
    final maxValue = trend.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 1000;
    return (maxValue / 4).ceilToDouble();
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label \$${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
