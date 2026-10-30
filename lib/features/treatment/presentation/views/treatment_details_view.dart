import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../care/presentation/viewmodels/care_cubit.dart';
import '../../../care/presentation/viewmodels/care_state.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_cubit.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_state.dart';

enum DocumentFormat { pdf, doc, image }

class ClinicalReportItem {
  final String id;
  final String title;
  final DocumentFormat format;
  final String fileName;
  final String fileSize;
  final String uploadedBy;
  final String uploadDate;
  final String uploaderRole; // 'Super Admin' or 'Admin'
  final String summary;
  final String department;
  final Map<String, String>? metrics;

  const ClinicalReportItem({
    required this.id,
    required this.title,
    required this.format,
    required this.fileName,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadDate,
    required this.uploaderRole,
    required this.summary,
    required this.department,
    this.metrics,
  });
}

class PrescribedMedicine {
  final String name;
  final String type;
  final String dosage;
  final String timing;
  final String instructions;
  final String purpose;
  final IconData icon;

  const PrescribedMedicine({
    required this.name,
    required this.type,
    required this.dosage,
    required this.timing,
    required this.instructions,
    required this.purpose,
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

  // Sample verified clinical reports uploaded by Admin & Super Admin
  final List<ClinicalReportItem> _reports = const [
    ClinicalReportItem(
      id: 'REP-001',
      title: 'High-Resolution Scalp Trichoscopy Scan',
      format: DocumentFormat.image,
      fileName: 'trichoscopy_density_scan_v1.png',
      fileSize: '2.8 MB',
      uploadedBy: 'Dr. Jai Bansal',
      uploaderRole: 'Super Admin',
      uploadDate: '26 Oct 2026',
      department: 'Clinical Trichology · Room 101',
      summary:
          'Polarized epiluminescence trichoscopy shows follicular miniaturization in vertex and frontal zones with mild perifollicular erythema.',
      metrics: {
        'Frontal Density': '64 FU/cm²',
        'Mid-Scalp Density': '48 FU/cm²',
        'Donor Area Density': '86 FU/cm²',
        'Miniaturization Rate': '24.5%',
        'Anagen / Telogen': '74% / 26%',
      },
    ),
    ClinicalReportItem(
      id: 'REP-002',
      title: 'Pathology & Hormonal Profile (DHT & Ferritin)',
      format: DocumentFormat.pdf,
      fileName: 'blood_hormonal_panel_lab.pdf',
      fileSize: '1.4 MB',
      uploadedBy: 'Admin Clinical Desk',
      uploaderRole: 'Admin',
      uploadDate: '24 Oct 2026',
      department: 'Diagnostic Pathology Lab',
      summary:
          'Serum Ferritin is sub-optimal (42 ng/mL) and Serum DHT is slightly elevated (68.2 ng/dL). Thyroid TSH is within normal limits.',
      metrics: {
        'Serum Ferritin': '42.0 ng/mL (Ref: 30-300)',
        'Total DHT': '68.2 ng/dL (High Normal)',
        'Serum Vitamin D3': '18.5 ng/mL (Deficient)',
        'TSH (Thyroid)': '2.14 mIU/L (Normal)',
        'Complete Blood Count': 'Normal Hemoglobin 14.8 g/dL',
      },
    ),
    ClinicalReportItem(
      id: 'REP-003',
      title: 'Sapphire FUE Graft & Donor Feasibility Plan',
      format: DocumentFormat.doc,
      fileName: 'graft_harvesting_surgical_plan.docx',
      fileSize: '840 KB',
      uploadedBy: 'Dr. Jai Bansal',
      uploaderRole: 'Super Admin',
      uploadDate: '22 Oct 2026',
      department: 'Hair Restoration Surgery Suite',
      summary:
          'Surgical assessment confirms safe donor harvest capability of up to 3,600 follicular units. Phase 1 hairline restoration recommended.',
      metrics: {
        'Donor Zone Capacity': '3,600 viable grafts',
        'Recommended Harvest': '2,200 Grafts (Phase 1)',
        'Graft Single/Multi': '450 Singles, 1,200 Doubles, 550 Multi',
        'Implantation Technique': 'Motorized 0.8mm Sapphire FUE',
      },
    ),
    ClinicalReportItem(
      id: 'REP-004',
      title: '30-Day Treatment Response Trichogram',
      format: DocumentFormat.pdf,
      fileName: 'trichogram_30day_progress.pdf',
      fileSize: '1.9 MB',
      uploadedBy: 'Dr. Jai Bansal',
      uploaderRole: 'Super Admin',
      uploadDate: '20 Oct 2026',
      department: 'Clinical Follow-up & Trichology',
      summary:
          'Positive response to DHT blocker and topical minoxidil protocol. Shedding velocity decreased by approximately 35% compared to baseline.',
      metrics: {
        'Shedding Reduction': '35% improvement',
        'Follicular Caliber': '+8% diameter gain',
        'Scalp Sebum pH': '6.4 (Balanced)',
        'Compliance Score': '94% Routine adherence',
      },
    ),
  ];

  // Prescribed Medicines by Dr. Jai Bansal (Super Admin)
  final List<PrescribedMedicine> _medicines = const [
    PrescribedMedicine(
      name: 'Minoxidil 5% + Finasteride 0.1% Serum',
      type: 'Topical Solution',
      dosage: '1 mL (6 metered sprays)',
      timing: 'Nightly before sleep',
      instructions:
          'Apply directly onto clean, dry thinning areas of the scalp. Gently massage with fingertips for 60 seconds.',
      purpose: 'Stimulates micro-circulation & inhibits localized DHT formation',
      icon: LucideIcons.sprayCan,
    ),
    PrescribedMedicine(
      name: 'Biotin 10mg + Zinc + Saw Palmetto Complex',
      type: 'Oral Nutra-Capsules',
      dosage: '1 Capsule daily',
      timing: 'Morning after breakfast',
      instructions:
          'Take with a full glass of water. Do not consume on an empty stomach.',
      purpose: 'Keratin protein synthesis & systemic DHT moderation',
      icon: LucideIcons.pill,
    ),
    PrescribedMedicine(
      name: 'Ketoconazole 2% Medicated Scalp Cleanser',
      type: 'Therapeutic Shampoo',
      dosage: '5-7 mL lather',
      timing: '2 to 3 times per week',
      instructions:
          'Work into scalp lather, leave on for 3 to 5 minutes before thoroughly rinsing with lukewarm water.',
      purpose: 'Anti-fungal, reduces micro-inflammation and excess sebum',
      icon: LucideIcons.sparkles,
    ),
    PrescribedMedicine(
      name: 'Follicular Peptide Growth Factor Mist',
      type: 'Scalp Activator',
      dosage: '4 sprays',
      timing: 'Alternate mornings',
      instructions:
          'Spray over crown and vertex region. Comb gently through hair. Non-greasy leave-in formula.',
      purpose: 'Strengthens dermal papilla cellular anchor points',
      icon: LucideIcons.droplets,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDownloadToast(String documentTitle, String fileName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.downloadCloud,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading $fileName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Saved to device downloads · Dr. Hair Vault',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReportBottomSheet(ClinicalReportItem report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailBottomSheet(
        report: report,
        onDownload: () => _showDownloadToast(report.title, report.fileName),
      ),
    );
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
        children: [
          _buildPrescriptionTab(),
          _buildMedicalReportsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: PRESCRIPTION DETAILS VIEW
  // ==========================================
  Widget _buildPrescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor & Super Admin Authorization Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.navyGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'PRESCRIBED BY SUPER ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'RX #84920-DH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Doctor Details Row
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.stethoscope,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Jai Bansal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chief Surgeon & Trichologist · Super Admin',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Reg: MCI-84920 · Sector 29 Clinic, Gurugram',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Clinical Assessment Info in Doctor Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CLINICAL DIAGNOSIS',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          BlocBuilder<HairTestCubit, HairTestState>(
                            builder: (context, state) => Text(
                              state.stage ?? 'Androgenetic Alopecia (Stage 3)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'PLAN DURATION',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '90 Days Active Protocol',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Download Prescription Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDownloadToast(
                      'Official Digital Prescription',
                      'DrHair_Prescription_RX84920.pdf',
                    ),
                    icon: const Icon(LucideIcons.download, size: 15),
                    label: const Text(
                      'Download Signed Prescription (PDF)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Title
          const Row(
            children: [
              Icon(LucideIcons.pill, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Prescribed Regimen & Dosage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Prescribed Medicines Cards
          ..._medicines.map((med) => _buildMedicineCard(med)),

          const SizedBox(height: 20),

          // Care Plan Routine Sync
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      LucideIcons.calendarCheck,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Daily Care Steps Synchronized',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'These medications are mapped into your daily routine checklist. Check them off morning and night to track compliance score.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<CareCubit, CareState>(
                  builder: (context, state) => state.routineTasks.isEmpty
                      ? const Text(
                          'No routine steps configured.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.routineTasks
                              .take(4)
                              .map(
                                (task) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary5,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primary100,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        task.isCompleted
                                            ? LucideIcons.checkCircle2
                                            : LucideIcons.circle,
                                        size: 12,
                                        color: task.isCompleted
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Safety & Super Admin Verification Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary5,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinician Direct Supervision',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This prescription has been formulated by Dr. Jai Bansal following your clinical intake. For dosage modifications, book a follow-up or chat with the clinical desk.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryDark,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.phoneCall,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Sector 29 Clinic Desk: +91 98765 43210',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              Container(
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
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
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
            if (_selectedReportFilter == 'PDF') return r.format == DocumentFormat.pdf;
            if (_selectedReportFilter == 'Images') return r.format == DocumentFormat.image;
            if (_selectedReportFilter == 'Docs') return r.format == DocumentFormat.doc;
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
                        'Verified Clinical Vault',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All laboratory findings, trichoscopy scans, and documents uploaded directly by Dr. Hair Admin Desk.',
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
                  _reports.where((r) => r.format == DocumentFormat.image).length,
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

          // Reports List
          ...filteredReports.map((report) => _buildReportCard(report)),
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
    final (icon, iconColor, bgBadgeColor, badgeText) = switch (report.format) {
      DocumentFormat.pdf => (
        LucideIcons.fileText,
        const Color(0xFFDC2626),
        const Color(0xFFFEE2E2),
        'PDF REPORT',
      ),
      DocumentFormat.image => (
        LucideIcons.image,
        AppColors.secondary,
        const Color(0xFFCCFBF1),
        'SCALP SCAN',
      ),
      DocumentFormat.doc => (
        LucideIcons.fileSpreadsheet,
        const Color(0xFF2563EB),
        const Color(0xFFDBEAFE),
        'DOCUMENT',
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header & Uploader Tag
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Format Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgBadgeColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Titles and metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin Uploader Tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: report.uploaderRole == 'Super Admin'
                                  ? AppColors.primary
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.checkCheck,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Uploaded by ${report.uploaderRole}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary5,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
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
                        'By ${report.uploadedBy} · ${report.uploadDate} · ${report.fileSize}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Clinical Summary Snippet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.summary,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.secondaryDark,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Actions Footer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openReportBottomSheet(report),
                    icon: const Icon(LucideIcons.eye, size: 14),
                    label: const Text(
                      'View in Sheet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary100),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDownloadToast(
                      report.title,
                      report.fileName,
                    ),
                    icon: const Icon(LucideIcons.download, size: 14),
                    label: const Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE DOCUMENT VIEWER BOTTOM SHEET
// ==========================================
class _ReportDetailBottomSheet extends StatelessWidget {
  final ClinicalReportItem report;
  final VoidCallback onDownload;

  const _ReportDetailBottomSheet({
    required this.report,
    required this.onDownload,
  });

  void _shareDocument(BuildContext context) {
    try {
      SharePlus.instance.share(
        ShareParams(
          text:
              'Dr. Hair Clinical Document: ${report.title} (Uploaded by ${report.uploadedBy}). Patient reference: RX-84920. Download at https://drhair.health/reports/${report.id}',
          subject: 'Dr. Hair - ${report.title}',
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              // Sheet Top Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.checkCheck,
                                      color: AppColors.secondary,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'UPLOADED BY ${report.uploaderRole.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.secondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                report.uploadDate,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${report.department} · ${report.uploadedBy}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.primaryDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 24),

              // Scrollable Sheet Document Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Preview Card based on Document Type
                    if (report.format == DocumentFormat.image)
                      _buildImageScanPreview(context),
                    if (report.format == DocumentFormat.pdf)
                      _buildPdfReportPreview(context),
                    if (report.format == DocumentFormat.doc)
                      _buildDocReportPreview(context),

                    const SizedBox(height: 18),

                    // Metrics Table (if any)
                    if (report.metrics != null && report.metrics!.isNotEmpty) ...[
                      const Text(
                        'Clinical Parameters & Readings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: report.metrics!.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryDark,
                                    ),
                                  ),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Observation & Clinician Notes
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary5,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.stethoscope,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Evaluated by ${report.uploadedBy}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.summary,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryDark,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Sheet Sticky Download & Share Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          onDownload();
                          Navigator.pop(context);
                        },
                        icon: const Icon(LucideIcons.download, size: 16),
                        label: Text(
                          'Download (${report.fileSize})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareDocument(context),
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary100),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // IMAGE SCAN BOTTOM SHEET PREVIEW
  Widget _buildImageScanPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      LucideIcons.scanLine,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TRICHOSCOPY POLARIZED 120X',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CALIBRATED',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Simulated High-Tech Micrograph Surface
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF090D16),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid lines overlay
                Opacity(
                  opacity: 0.15,
                  child: GridPaper(
                    color: Colors.tealAccent,
                    divisions: 2,
                    subdivisions: 1,
                  ),
                ),
                // Center Scalp Scan Graphic Representation
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.focus,
                          color: AppColors.secondary,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Vertex Micro-Density Scan #PT-84920',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scan Footer Tags
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMicroTag('DENSITY', '64 FU/cm²'),
                _buildMicroTag('HAIR COUNT', '132/cm²'),
                _buildMicroTag('TELOGEN RATIO', '26%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroTag(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // PDF LAB REPORT BOTTOM SHEET PREVIEW
  Widget _buildPdfReportPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PDF Letterhead
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DR. HAIR TRICHOLOGY CLINIC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Clinical Diagnostic Pathology Center · Gurugram',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OFFICIAL PDF',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Patient Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfField('PATIENT ID', '#PT-84920'),
              _buildPdfField('ORDERED BY', report.uploadedBy),
              _buildPdfField('STATUS', 'VERIFIED'),
            ],
          ),
          const SizedBox(height: 14),

          // Diagnostic Findings Table
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Test Investigation',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Result & Normal Range',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Serum Ferritin',
                      style: TextStyle(fontSize: 9, color: AppColors.secondaryDark),
                    ),
                    Text(
                      '42.0 ng/mL (30-300 ng/mL)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total DHT (Dihydrotestosterone)',
                      style: TextStyle(fontSize: 9, color: AppColors.secondaryDark),
                    ),
                    Text(
                      '68.2 ng/dL [HIGH] (25-65 ng/dL)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thyroid Stimulating Hormone (TSH)',
                      style: TextStyle(fontSize: 9, color: AppColors.secondaryDark),
                    ),
                    Text(
                      '2.14 mIU/L (0.4-4.2 mIU/L)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(LucideIcons.fileCheck, size: 14, color: AppColors.secondary),
              SizedBox(width: 4),
              Text(
                'Digitally Certified by Pathologist & Dr. Jai Bansal',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfField(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 7.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  // DOC REPORT BOTTOM SHEET PREVIEW
  Widget _buildDocReportPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.fileSpreadsheet,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surgical Graft Mapping Document',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Microsoft Word (.docx) · Clinical Protocol Document',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text(
            'SURGICAL RECONSTRUCTION SPECIFICATIONS:',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Donor safe harvesting zone verified with trichometer density at 86 FU/cm².\n'
            '2. Projected Phase 1 restoration requires 2,200 total follicular units.\n'
            '3. Sapphire blades (1.1mm width) allocated for acute-angle hairline incisions.\n'
            '4. Post-procedure PRP and low-level laser therapy (LLLT) scheduled for Week 2.',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.secondaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
