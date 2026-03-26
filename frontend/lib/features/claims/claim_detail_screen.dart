import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/claim_model.dart';
import '../../providers/claim_provider.dart';

class ClaimDetailScreen extends ConsumerWidget {
  final ClaimModel claim;
  const ClaimDetailScreen({super.key, required this.claim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(
      claimProvider.select((s) => s.reports[claim.id]),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: Text(
          '${claim.disasterType} Claim',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _HeaderCard(claim: claim),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 500),
              child: _InfoCard(claim: claim),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 500),
              child: _sectionLabel('Post-Disaster Photo'),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              duration: const Duration(milliseconds: 500),
              child: _PhotoPlaceholder(imageUrl: claim.afterImageUrl),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 500),
              child: _sectionLabel('Claim Progress'),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              duration: const Duration(milliseconds: 500),
              child: _Timeline(status: claim.status),
            ),
            const SizedBox(height: 24),
            if (claim.status == 'processing')
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: _infoBanner(
                  'Verification in progress. Our AI is analyzing your submitted images.',
                  Colors.blue,
                ),
              ),
            if (claim.status == 'verified' && report != null)
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/report', extra: report),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    'View Compensation Report',
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      );

  Widget _infoBanner(String message, Color color) => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Header Card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final ClaimModel claim;
  const _HeaderCard({required this.claim});

  static const _icons = <String, IconData>{
    'Flood': Icons.water_outlined,
    'Cyclone': Icons.cyclone,
    'Earthquake': Icons.terrain_outlined,
    'Fire': Icons.local_fire_department_outlined,
    'Storm': Icons.thunderstorm_outlined,
    'Landslide': Icons.landslide_outlined,
  };

  static const _statusColors = <String, Color>{
    'pending': Color(0xFFFB8C00),
    'processing': Color(0xFF1565C0),
    'verified': Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[claim.status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _icons[claim.disasterType] ?? Icons.warning_amber_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${claim.disasterType} Damage',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submitted ${DateFormat('d MMM yyyy').format(claim.submittedAt)}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              claim.status.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ClaimModel claim;
  const _InfoCard({required this.claim});

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(Icons.location_on_outlined, 'Location', claim.location),
            const Divider(height: 20),
            _row(Icons.notes_outlined, 'Description', claim.description),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Photo Placeholder ────────────────────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  final String? imageUrl;
  const _PhotoPlaceholder({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 220,
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 44, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Post-disaster photo submitted',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ─────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final String status;
  const _Timeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Claim Submitted', 'Form & photos received',
          Icons.upload_file_outlined, true),
      _Step(
        'AI Verification',
        'Satellite image comparison & damage scoring',
        Icons.psychology_outlined,
        status == 'processing' || status == 'verified',
      ),
      _Step(
        'Report Generated',
        'Compensation calculated & report ready',
        Icons.description_outlined,
        status == 'verified',
      ),
    ];

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++)
            _TimelineTile(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  const _Step(this.title, this.subtitle, this.icon, this.done);
}

class _TimelineTile extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _TimelineTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: step.done ? green : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.done ? Icons.check : step.icon,
                    color: step.done ? Colors.white : Colors.grey[400],
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.done
                          ? green.withValues(alpha: 0.3)
                          : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: step.done ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Text(
                    step.subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
