import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../data/patient_clinical_api.dart';

enum DocumentFormat { pdf, doc, image }

class ClinicalReportItem {
  final String id;
  final String title;
  final DocumentFormat format;
  final String fileName;
  final String fileSize;
  final String uploadedBy;
  final String uploadDate;
  final String uploaderRole;

  const ClinicalReportItem({
    required this.id,
    required this.title,
    required this.format,
    required this.fileName,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadDate,
    required this.uploaderRole,
  });
}

class PrescribedMedicine {
  final String name;
  final String type;
  final String dosage;
  final String timing;
  final String instructions;
  final IconData icon;

  const PrescribedMedicine({
    required this.name,
    required this.type,
    required this.dosage,
    required this.timing,
    required this.instructions,
    required this.icon,
  });
}

class TreatmentDetailsView extends StatefulWidget {
  const TreatmentDetailsView({super.key});

  @override
  State<TreatmentDetailsView> createState() => _TreatmentDetailsViewState();
}

class _TreatmentDetailsViewState extends State<TreatmentDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedReportFilter = 'All';
  final PatientClinicalApi _clinicalApi = PatientClinicalApi();
  List<ClinicalReportItem> _reports = [];
  List<PrescribedMedicine> _medicines = [];
  List<Map<String, dynamic>> _routineSteps = [];
  List<Map<String, dynamic>> _dietMeals = [];
  Map<String, dynamic>? _latestPlan;
  String? _accessToken;
  String? _recordError;
  String? _downloadingReportId;
  bool _loadingRecord = true;
  bool _didResolveSession = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didResolveSession) return;
    _didResolveSession = true;
    final auth = context.read<AuthCubit?>()?.state;
    final token = auth?.sessionToken;
    if (token == null || token.isEmpty || auth?.isGuest == true) {
      setState(() {
        _loadingRecord = false;
        _recordError =
            'Sign in to view care plans and reports shared by your clinic.';
      });
      return;
    }
    _accessToken = token;
    unawaited(_loadClinicalRecord(token));
  }

  Future<void> _loadClinicalRecord(String token) async {
    setState(() {
      _loadingRecord = true;
      _recordError = null;
    });
    try {
      final record = await _clinicalApi.getClinicalRecord(token);
      final plans = _asMapList(record['care_plans']);
      final plan = plans.isEmpty ? null : plans.first;
      final medicineRows = _asMapList(plan?['medications']);
      final reports = _asMapList(record['reports'])
          .map((row) {
            final mime = row['mime_type']?.toString().toLowerCase() ?? '';
            final format = row['format']?.toString().toLowerCase() ?? '';
            final image =
                mime.startsWith('image/') ||
                ['jpg', 'jpeg', 'png', 'webp'].contains(format);
            return ClinicalReportItem(
              id: row['id']?.toString() ?? '',
              title: row['title']?.toString() ?? 'Clinical report',
              format: image ? DocumentFormat.image : DocumentFormat.pdf,
              fileName: row['file_name']?.toString() ?? 'report',
              fileSize: _formatBytes(row['bytes']),
              uploadedBy:
                  row['uploaded_by']?.toString().trim().isNotEmpty == true
                  ? row['uploaded_by'].toString()
                  : 'Clinic',
              uploaderRole: 'Clinic',
              uploadDate: _formatDate(row['created_at']),
            );
          })
          .where((report) => report.id.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _latestPlan = plan;
        _medicines = medicineRows
            .map(
              (row) => PrescribedMedicine(
                name: row['name']?.toString() ?? '',
                type: [row['category'], row['form']]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' · '),
                dosage: row['dose']?.toString() ?? '',
                timing: row['frequency']?.toString() ?? '',
                instructions: row['instructions']?.toString() ?? '',
                icon: LucideIcons.pill,
              ),
            )
            .toList();
        _routineSteps = _asMapList(plan?['routine_steps']);
        _dietMeals = _asMapList(plan?['diet_meals']);
        _reports = reports;
        _loadingRecord = false;
        _recordError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRecord = false;
        _recordError = 'Your clinic plan could not be loaded. Check your connection and try again.';
      });
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _formatBytes(dynamic value) {
    final bytes = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${bytes.toInt()} B';
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Date unavailable';
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _downloadReport(ClinicalReportItem report) async {
    final token = _accessToken;
    if (token == null) return;
    setState(() => _downloadingReportId = report.id);
    try {
      final uri = await _clinicalApi.getReportDownloadUri(
        accessToken: token,
        reportId: report.id,
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('The secure report link could not be opened.');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this report. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingReportId = null);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Medical Reports & Prescription',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary5,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary100),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryDark,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.pill, size: 15),
                      SizedBox(width: 8),
                      Text('Prescription Details'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileText, size: 15),
                      SizedBox(width: 8),
                      Text('Medical Reports'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPrescriptionTab(), _buildMedicalReportsTab()],
      ),
    );
  }

  // ==========================================
  // TAB 1: PRESCRIPTION DETAILS VIEW
  // ==========================================
  Widget _buildPrescriptionTab() {
    final plan = _latestPlan;
    return RefreshIndicator(
      onRefresh: () async {
        final token = _accessToken;
        if (token != null) await _loadClinicalRecord(token);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_loadingRecord)
            const Padding(
              padding: EdgeInsets.only(top: 72),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recordError != null)
            _clinicalLoadMessage(
              _recordError!,
              onRetry: () {
                final token = _accessToken;
                if (token != null) unawaited(_loadClinicalRecord(token));
              },
            )
          else if (plan == null)
            _clinicalLoadMessage(
              'Your clinic has not shared a care plan yet. Prescriptions and care suggestions will appear here after your clinician adds them.',
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.navyGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR CLINIC CARE PLAN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    plan['treatment_name']?.toString() ??
                        'Personalized care plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((plan['doctor_name']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prepared by ${plan['doctor_name']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if ((plan['diagnosis']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _planDetail(
                      'CLINICIAN ASSESSMENT',
                      plan['diagnosis'].toString(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if ((plan['stage']?.toString() ?? '').isNotEmpty)
                        _planBadge('Stage · ${plan['stage']}'),
                      if ((plan['duration']?.toString() ?? '').isNotEmpty)
                        _planBadge('Duration · ${plan['duration']}'),
                      if ((plan['next_review_date']?.toString() ?? '')
                          .isNotEmpty)
                        _planBadge(
                          'Review · ${_formatDate(plan['next_review_date'])}',
                        ),
                    ],
                  ),
                  if ((plan['instructions']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      plan['instructions'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(LucideIcons.pill, 'Prescribed medicines & products'),
            const SizedBox(height: 12),
            if (_medicines.isEmpty)
              _emptyPlanSection('No medicines or products in this care plan.')
            else
              ..._medicines.map(_buildMedicineCard),
            if (_routineSteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle(LucideIcons.calendarCheck, 'Your care routine'),
              const SizedBox(height: 12),
              ..._routineSteps.map((step) => _routineCard(step)),
            ],
            if (_dietMeals.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle(LucideIcons.heart, 'Diet suggestions'),
              const SizedBox(height: 12),
              ..._dietMeals.map((meal) => _dietCard(meal)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    ],
  );

  Widget _planBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _planDetail(String title, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _routineCard(Map<String, dynamic> step) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                step['title']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if ((step['time_of_day']?.toString() ?? '').isNotEmpty)
              Text(
                step['time_of_day'].toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
        if ((step['category']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            step['category'].toString(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.secondaryDark,
            ),
          ),
        ],
        if ((step['subtitle']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            step['subtitle'].toString(),
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.secondaryDark,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _dietCard(Map<String, dynamic> meal) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal['type']?.toString() ?? '',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meal['name']?.toString() ?? '',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        if ((meal['nutrients']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            meal['nutrients'].toString(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.secondaryDark,
            ),
          ),
        ],
        if ((meal['benefit']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            meal['benefit'].toString(),
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.secondaryDark,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _emptyPlanSection(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      message,
      style: const TextStyle(fontSize: 12, color: AppColors.secondaryDark),
    ),
  );

  Widget _clinicalLoadMessage(String message, {VoidCallback? onRetry}) =>
      Container(
        margin: const EdgeInsets.only(top: 64),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.fileText,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.secondaryDark,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.rotateCw, size: 15),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      );

  Widget _buildMedicineCard(PrescribedMedicine med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(med.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.type} · ${med.dosage}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (med.timing.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 108),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      med.timing,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (med.instructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      med.instructions,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondaryDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MEDICAL REPORTS & DOCUMENTS
  // ==========================================
  Widget _buildMedicalReportsTab() {
    final filteredReports = _selectedReportFilter == 'All'
        ? _reports
        : _reports.where((r) {
            if (_selectedReportFilter == 'PDF') {
              return r.format == DocumentFormat.pdf;
            }
            if (_selectedReportFilter == 'Images') {
              return r.format == DocumentFormat.image;
            }
            if (_selectedReportFilter == 'Docs') {
              return r.format == DocumentFormat.doc;
            }
            return true;
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports shared by your clinic',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Private documents uploaded to your patient record. Download links are created securely when you open a report.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondaryDark,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _reports.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'PDF',
                  _reports.where((r) => r.format == DocumentFormat.pdf).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Images',
                  _reports
                      .where((r) => r.format == DocumentFormat.image)
                      .length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Docs',
                  _reports.where((r) => r.format == DocumentFormat.doc).length,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_loadingRecord)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recordError != null)
            _clinicalLoadMessage(
              _recordError!,
              onRetry: () {
                final token = _accessToken;
                if (token != null) unawaited(_loadClinicalRecord(token));
              },
            )
          else if (filteredReports.isEmpty)
            _clinicalLoadMessage('No reports have been shared with you yet.')
          else
            ...filteredReports.map(_buildReportCard),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedReportFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedReportFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.secondaryDark,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.primary5,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(ClinicalReportItem report) {
    final isDownloading = _downloadingReportId == report.id;
    final (icon, color, badge) = switch (report.format) {
      DocumentFormat.pdf => (
        LucideIcons.fileText,
        const Color(0xFFDC2626),
        'PDF',
      ),
      DocumentFormat.image => (LucideIcons.image, AppColors.secondary, 'IMAGE'),
      DocumentFormat.doc => (
        LucideIcons.fileText,
        const Color(0xFF2563EB),
        'DOCUMENT',
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.fileName} · ${report.fileSize}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Shared by ${report.uploadedBy} · ${report.uploadDate}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Open secure report download',
            onPressed: isDownloading
                ? null
                : () => unawaited(_downloadReport(report)),
            icon: isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.download, size: 18),
          ),
        ],
      ),
    );
  }
}
