import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/claim_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatCompensation(double amount) {
    if (amount >= 100000) {
      final lakh = amount / 100000;
      return '₹${lakh.toStringAsFixed(lakh.truncateToDouble() == lakh ? 0 : 1)}L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  IconData _disasterIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return Icons.water;
      case 'cyclone':
        return Icons.cyclone;
      case 'earthquake':
        return Icons.landscape;
      case 'fire':
        return Icons.local_fire_department;
      case 'storm':
        return Icons.thunderstorm;
      case 'landslide':
        return Icons.terrain;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _disasterColor(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return Colors.blue;
      case 'cyclone':
        return Colors.purple;
      case 'earthquake':
        return Colors.brown;
      case 'fire':
        return Colors.deepOrange;
      case 'storm':
        return Colors.indigo;
      case 'landslide':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final claimState = ref.watch(claimProvider);
    final user = authState.user;

    final today = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () => ref.read(claimProvider.notifier).loadClaims(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name ?? 'Citizen'} 👋',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            today,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor:
                          const Color(0xFF2E7D32).withValues(alpha: 0.15),
                      radius: 24,
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statColumn(
                          label: 'Total Claims',
                          value: '${claimState.claims.length}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _statColumn(
                          label: 'Verified',
                          value: '${claimState.verifiedCount}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _statColumn(
                          label: 'Compensation',
                          value: _formatCompensation(claimState.totalCompensation),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Claims',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/new-claim'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'New Claim',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (claimState.isLoading) ...[
                _shimmerCard(),
                _shimmerCard(),
                _shimmerCard(),
              ] else if (claimState.error != null && claimState.claims.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.wifi_off_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load claims',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to retry',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (claimState.claims.isEmpty)
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 72,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No claims yet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Submit your first claim to get started',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/new-claim'),
                            icon: const Icon(Icons.add),
                            label: const Text(
                              'Submit First Claim',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: claimState.claims.length,
                  itemBuilder: (context, index) {
                    final claim = claimState.claims[index];
                    final report = claimState.reports[claim.id];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      duration: const Duration(milliseconds: 400),
                      child: _ClaimCard(
                        claim: claim,
                        report: report,
                        disasterIcon: _disasterIcon(claim.disasterType),
                        disasterColor: _disasterColor(claim.disasterType),
                        statusColor: _statusColor(claim.status),
                        formatCompensation: _formatCompensation,
                        onTap: () =>
                            context.push('/claim-detail', extra: claim),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final ClaimModel claim;
  final dynamic report;
  final IconData disasterIcon;
  final Color disasterColor;
  final Color statusColor;
  final String Function(double) formatCompensation;
  final VoidCallback onTap;

  const _ClaimCard({
    required this.claim,
    required this.report,
    required this.disasterIcon,
    required this.disasterColor,
    required this.statusColor,
    required this.formatCompensation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final submittedDate =
        DateFormat('d MMM yyyy').format(claim.submittedAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: disasterColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(disasterIcon, color: disasterColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claim.disasterType,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    claim.location,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: $submittedDate',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    claim.status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (report != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    formatCompensation(report.compensationAmount as double),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
