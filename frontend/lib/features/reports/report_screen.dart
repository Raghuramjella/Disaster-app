import 'dart:io';
import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';
import '../../models/claim_model.dart';
import '../../models/report_model.dart';
import '../../providers/claim_provider.dart';
import '../../services/report_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final ReportModel report;
  const ReportScreen({super.key, required this.report});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _downloadingPdf = false;

  Future<void> _handlePdfDownload() async {
    setState(() => _downloadingPdf = true);
    try {
      final bytes = await ReportService.downloadPdf(widget.report.claimId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report_${widget.report.claimId}.pdf');
      await file.writeAsBytes(bytes);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final claims = ref.watch(claimProvider.select((s) => s.claims));
    final claim = claims.firstWhere(
      (c) => c.id == report.claimId,
      orElse: () => ClaimModel(
        id: report.claimId,
        disasterType: 'Unknown',
        location: 'N/A',
        description: '',
        status: 'verified',
        submittedAt: report.generatedAt,
      ),
    );

    final tierColor =
        AppConstants.tierColors[report.damageTier] ?? const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Compensation Report',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon.')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _StatusBanner(
                generatedAt: report.generatedAt,
                photoVerified: report.photoVerified,
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 500),
              child: _DamageGaugeCard(
                lossPercentage: report.lossPercentage,
                damageTier: report.damageTier,
                tierColor: tierColor,
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 500),
              child: _CompensationCard(amount: report.compensationAmount),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 500),
              child: _ClaimSummaryCard(
                claim: claim,
                report: report,
                tierColor: tierColor,
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 500),
              child: _BreakdownCard(report: report),
            ),
            if (report.photoVerified != null) ...[
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 450),
                duration: const Duration(milliseconds: 500),
                child: _AuthenticityCard(report: report),
              ),
            ],
            if (report.satelliteBeforeUrl != null ||
                report.satelliteAfterUrl != null) ...[
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 480),
                duration: const Duration(milliseconds: 500),
                child: _SatelliteCard(report: report),
              ),
            ],
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton.icon(
                onPressed: _downloadingPdf ? null : _handlePdfDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _downloadingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(
                  _downloadingPdf ? 'Downloading...' : 'Download PDF Report',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 500),
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  foregroundColor: const Color(0xFF2E7D32),
                ),
                icon: const Icon(Icons.home_outlined),
                label: Text(
                  'Back to Dashboard',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final DateTime generatedAt;
  final bool? photoVerified;
  const _StatusBanner({required this.generatedAt, this.photoVerified});

  @override
  Widget build(BuildContext context) {
    final suspicious = photoVerified == false;
    final bgColor = suspicious ? Colors.orange[50]! : Colors.green[50]!;
    final borderColor = suspicious ? Colors.orange.shade200 : Colors.green.shade200;
    final iconColor = suspicious ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final icon = suspicious ? Icons.warning_amber_outlined : Icons.verified_outlined;
    final title = suspicious ? 'Claim Under Review' : 'Claim Verified & Report Ready';
    final subtitle = suspicious
        ? 'Photo did not pass authenticity check · Compensation withheld'
        : 'Generated ${DateFormat('d MMM yyyy, h:mm a').format(generatedAt)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Damage Gauge ─────────────────────────────────────────────────────────────

class _DamageGaugeCard extends StatelessWidget {
  final double lossPercentage;
  final String damageTier;
  final Color tierColor;

  const _DamageGaugeCard({
    required this.lossPercentage,
    required this.damageTier,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'AI Damage Assessment',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: 160,
            child: CustomPaint(
              painter: _GaugePainter(
                percentage: (lossPercentage / 100).clamp(0.0, 1.0),
                color: tierColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${lossPercentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                      ),
                    ),
                    Text(
                      'Loss',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$damageTier Damage',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: tierColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = math.pi * 0.75;
    const sweepFull = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = Colors.grey.shade200
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull * percentage,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.percentage != percentage || old.color != color;
}

// ── Compensation Card ─────────────────────────────────────────────────────────

class _CompensationCard extends StatelessWidget {
  final double amount;
  const _CompensationCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Estimated Compensation',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-calculated · No admin review needed',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

// ── Claim Summary ─────────────────────────────────────────────────────────────

class _ClaimSummaryCard extends StatelessWidget {
  final ClaimModel claim;
  final ReportModel report;
  final Color tierColor;

  const _ClaimSummaryCard({
    required this.claim,
    required this.report,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Claim Summary',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _row('Disaster Type', claim.disasterType),
          _row('Location', claim.location),
          _row(
            'Image Similarity',
            '${(report.similarityScore * 100).toStringAsFixed(1)}%',
          ),
          _row(
            'Loss Percentage',
            '${report.lossPercentage.toStringAsFixed(1)}%',
          ),
          _row('Damage Tier', report.damageTier, valueColor: tierColor),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown Card ────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final ReportModel report;
  const _BreakdownCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final multiplierPct =
        (AppConstants.tierMultiplier[report.damageTier] ?? 0) * 100;
    final propertyValue = multiplierPct > 0
        ? (report.compensationAmount / (multiplierPct / 100)).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  color: Color(0xFFFB8C00), size: 20),
              const SizedBox(width: 8),
              Text(
                'How this was calculated',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFFFB8C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _calc('Declared Property Value',
              '₹ ${NumberFormat('#,##,###').format(propertyValue)}'),
          _calc('Damage Tier', report.damageTier),
          _calc('Tier Multiplier', '${multiplierPct.toInt()}%'),
          const Divider(height: 20),
          _calc(
            '₹$propertyValue × ${multiplierPct.toInt()}%',
            '₹ ${NumberFormat('#,##,###').format(report.compensationAmount.round())}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _calc(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: bold ? Colors.black87 : Colors.grey[700],
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold ? const Color(0xFFFB8C00) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Authenticity Card ─────────────────────────────────────────────────────────

class _AuthenticityCard extends StatelessWidget {
  final ReportModel report;
  const _AuthenticityCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final verified = report.photoVerified ?? false;
    final score = report.authenticityScore;
    final color = verified ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
    final bgColor = verified ? Colors.green[50]! : Colors.red[50]!;
    final borderColor = verified ? Colors.green.shade200 : Colors.red.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_user : Icons.gpp_bad_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Photo Authenticity',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  verified ? 'GENUINE' : 'SUSPICIOUS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            verified
                ? 'The uploaded photo is consistent with the satellite imagery of this location and disaster.'
                : 'The uploaded photo does not match the satellite imagery of this location. Manual review may be required.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
          ),
          if (score != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Match Score: ',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${(score * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Satellite Comparison Card ─────────────────────────────────────────────────

class _SatelliteCard extends StatelessWidget {
  final ReportModel report;
  const _SatelliteCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.satellite_alt, color: Color(0xFF1565C0), size: 20),
              const SizedBox(width: 8),
              Text(
                'Satellite Comparison',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sentinel-2 imagery fetched from Google Earth Engine',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (report.satelliteBeforeUrl != null)
                Expanded(
                  child: _SatelliteImage(
                    url: report.satelliteBeforeUrl!,
                    label: 'Before Disaster',
                    labelColor: const Color(0xFF2E7D32),
                  ),
                ),
              if (report.satelliteBeforeUrl != null &&
                  report.satelliteAfterUrl != null)
                const SizedBox(width: 10),
              if (report.satelliteAfterUrl != null)
                Expanded(
                  child: _SatelliteImage(
                    url: report.satelliteAfterUrl!,
                    label: 'After Disaster',
                    labelColor: const Color(0xFFE53935),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SatelliteImage extends StatelessWidget {
  final String url;
  final String label;
  final Color labelColor;
  const _SatelliteImage({
    required this.url,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: url,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 140,
              color: Colors.grey[100],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 140,
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.satellite_alt, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Not available',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: labelColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}
