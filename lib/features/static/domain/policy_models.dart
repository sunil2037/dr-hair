/// Represents the types of legal and consumer policies supported.
enum PolicyType {
  privacyPolicy(
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    shortTitle: 'Privacy',
  ),
  termsAndConditions(
    slug: 'terms',
    title: 'Terms & Conditions',
    shortTitle: 'Terms',
  ),
  returnsAndRefunds(
    slug: 'returns-refunds',
    title: 'Returns & Refunds Policy',
    shortTitle: 'Returns & Refunds',
  ),
  cancellationPolicy(
    slug: 'cancellation-policy',
    title: 'Cancellation Policy',
    shortTitle: 'Cancellations',
  );

  final String slug;
  final String title;
  final String shortTitle;

  const PolicyType({
    required this.slug,
    required this.title,
    required this.shortTitle,
  });

  static PolicyType fromSlug(String? slug) {
    return PolicyType.values.firstWhere(
      (p) => p.slug == slug,
      orElse: () => PolicyType.privacyPolicy,
    );
  }
}

/// A structured section within a policy document.
class PolicySection {
  final String title;
  final String content;
  final bool isPendingApproval;
  final String? pendingApprovalNotes;
  final List<String> bulletPoints;

  const PolicySection({
    required this.title,
    required this.content,
    this.isPendingApproval = false,
    this.pendingApprovalNotes,
    this.bulletPoints = const [],
  });
}

/// A complete policy document with regulatory metadata and sections.
class PolicyDocument {
  final PolicyType type;
  final String title;
  final String lastUpdated;
  final String summary;
  final bool hasPendingLegalApproval;
  final String? pendingApprovalNotice;
  final List<PolicySection> sections;

  const PolicyDocument({
    required this.type,
    required this.title,
    required this.lastUpdated,
    required this.summary,
    this.hasPendingLegalApproval = false,
    this.pendingApprovalNotice,
    required this.sections,
  });

  factory PolicyDocument.fromJson(Map<String, dynamic> json, {PolicyType? fallbackType}) {
    final typeStr = json['type']?.toString() ?? json['slug']?.toString() ?? '';
    final resolvedType = fallbackType ??
        PolicyType.values.firstWhere(
          (t) =>
              t.slug.toLowerCase() == typeStr.toLowerCase() ||
              t.name.toLowerCase() == typeStr.toLowerCase(),
          orElse: () => PolicyType.privacyPolicy,
        );

    final rawSections = json['sections'] as List<dynamic>? ?? [];
    final sections = rawSections
        .whereType<Map<String, dynamic>>()
        .map((s) => PolicySection(
              title: s['title']?.toString() ?? '',
              content: s['content']?.toString() ?? '',
              bulletPoints: (s['bullet_points'] as List<dynamic>? ?? s['bulletPoints'] as List<dynamic>? ?? [])
                  .map((e) => e.toString())
                  .toList(),
            ))
        .toList();

    return PolicyDocument(
      type: resolvedType,
      title: json['title']?.toString() ?? resolvedType.title,
      lastUpdated: json['last_updated']?.toString() ?? json['effective_date']?.toString() ?? 'October 2026',
      summary: json['summary']?.toString() ?? '',
      hasPendingLegalApproval: json['has_pending_approval'] == true,
      pendingApprovalNotice: json['pending_approval_notice']?.toString(),
      sections: sections,
    );
  }
}
