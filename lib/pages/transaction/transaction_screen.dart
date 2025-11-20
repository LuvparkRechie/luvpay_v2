import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/functions/functions.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import '../../custom_widgets/app_color_v2.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List logs = [];
  Timer? _tmr;
  bool hasNet = true;
  String _selectedFilter = 'Today';
  String transDesc = "No transactions found";
  bool _isLoading = true;

  static const Map<String, int> _filterDays = {
    'Today': 0,
    'Week': 7,
    'Month': 30,
  };

  @override
  void initState() {
    _isLoading = true;
    super.initState();
    getLogs(true);
  }

  @override
  void dispose() {
    _tmr?.cancel();
    super.dispose();
  }

  void runTimer() {
    _tmr?.cancel();
    _tmr = Timer.periodic(Duration(seconds: 5), (e) {
      getLogs(false);
    });
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> getLogs(bool isLog, {int? days}) async {
    DateTime timeNow = await Functions.getTimeNow();
    String toDate = timeNow.toString().split(" ")[0];
    String fromDate =
        timeNow.subtract(Duration(days: days ?? 0)).toString().split(" ")[0];

    int userId = await Authentication().getUserId();
    String subApi =
        "${ApiKeys.getTransLogs}?user_id=$userId&tran_date_from=$fromDate&tran_date_to=$toDate";

    final response = await HttpRequestApi(api: subApi).get();

    if (response is String) {
      setState(() {
        hasNet = !response.toLowerCase().contains("internet");
      });
    } else if (response is Map && response["items"].isNotEmpty) {
      List items = response["items"];
      transDesc = "No transactions found";
      hasNet = true;

      if (_selectedFilter.toLowerCase() == "today") {
        DateTime timeNow = await Functions.getTimeNow();
        DateTime today = timeNow.toUtc();
        String todayString = today.toIso8601String().substring(0, 10);

        List todayItems =
            items.where((transaction) {
              String transactionDate =
                  transaction['tran_date'].toString().split("T")[0];
              return transactionDate == todayString;
            }).toList();

        setState(() {
          logs = todayItems;
        });
      } else {
        setState(() {
          logs = items;
        });
      }
    } else {
      setState(() {
        logs = [];
        transDesc = "No transactions found for $_selectedFilter";
      });
    }

    _isLoading = false;
    if (mounted) setState(() {});

    if (isLog && _selectedFilter.toLowerCase() == "today") runTimer();
  }

  void _handleFilterSelect(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
      logs.clear();
    });
    _tmr?.cancel();
    getLogs(true, days: _filterDays[filter]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Section
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColorV2.primaryVariant,
                      AppColorV2.primaryVariant.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your payment history',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter Section - Using SliverToBoxAdapter instead of SliverPersistentHeader
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    ['Today', 'Week', 'Month'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () => _handleFilterSelect(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? LinearGradient(
                                      colors: [
                                        AppColorV2.primaryVariant,
                                        AppColorV2.primaryVariant.withOpacity(
                                          0.9,
                                        ),
                                      ],
                                    )
                                    : null,
                            color:
                                isSelected
                                    ? null
                                    : Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: AppColorV2.primaryVariant
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            filter,
                            style: GoogleFonts.inter(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColorV2.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Content Section
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 200,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: 6),
            )
          else if (logs.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final transaction = logs[index];
                return Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: _TransactionCard(
                    name: transaction['category'] as String,
                    category: transaction['tran_desc'] as String,
                    date: _formatDate(transaction['tran_date']),
                    amount: transaction['amount'] as String,
                    isPositive: !transaction['amount'].toString().contains("-"),
                  ),
                );
              }, childCount: logs.length),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColorV2.primaryVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            transDesc,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorV2.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start making payments to see your history',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColorV2.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String name;
  final String category;
  final String date;
  final String amount;
  final bool isPositive;

  const _TransactionCard({
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle transaction details
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isPositive
                            ? Color(0xFF00B894).withOpacity(0.15)
                            : Color(0xFFE84393).withOpacity(0.15),
                        isPositive
                            ? Color(0xFF00B894).withOpacity(0.08)
                            : Color(0xFFE84393).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isPositive ? Color(0xFF00B894) : Color(0xFFE84393),
                    size: 26,
                  ),
                ),

                const SizedBox(width: 16),

                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3436),
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          color: Color(0xFF636E72),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          color: Color(0xFFB2BEC3),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Amount and status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color:
                            isPositive ? Color(0xFF00B894) : Color(0xFFE84393),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPositive
                                ? Color(0xFF00B894).withOpacity(0.1)
                                : Color(0xFFE84393).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPositive ? 'CREDIT' : 'DEBIT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isPositive
                                  ? Color(0xFF00B894)
                                  : Color(0xFFE84393),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
