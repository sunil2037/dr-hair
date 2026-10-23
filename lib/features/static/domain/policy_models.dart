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
}
