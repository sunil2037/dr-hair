import '../domain/policy_models.dart';

/// Centralized repository for all application policies, terms, and regulatory disclosures.
class PolicyRepository {
  PolicyRepository._();

  static const String currentEffectiveDate = 'October 2026';
  static const String pendingApprovalDefaultNotice =
      'Policy details pending business and legal approval. The parameters below represent current draft operational standards and require formal corporate sign-off before commercial release.';

  static PolicyDocument getPolicy(PolicyType type) {
    switch (type) {
      case PolicyType.privacyPolicy:
        return _privacyPolicy;
      case PolicyType.termsAndConditions:
        return _termsAndConditions;
      case PolicyType.returnsAndRefunds:
        return _returnsAndRefunds;
      case PolicyType.cancellationPolicy:
        return _cancellationPolicy;
      case PolicyType.moneyBackGuarantee:
        return _moneyBackGuarantee;
    }
  }

  static List<PolicyDocument> getAllPolicies() {
    return [
      _privacyPolicy,
      _termsAndConditions,
      _returnsAndRefunds,
      _cancellationPolicy,
      _moneyBackGuarantee,
    ];
  }

  // 1. PRIVACY POLICY (DPDP Act 2023 Compliant Notice)
  static const PolicyDocument _privacyPolicy = PolicyDocument(
    type: PolicyType.privacyPolicy,
    title: 'Privacy Policy',
    lastUpdated: currentEffectiveDate,
    summary:
        'This Privacy Notice explains how Dr. Hair collects, uses, protects, and handles your personal data, hair assessment responses, and scalp progression photographs in compliance with India’s Digital Personal Data Protection (DPDP) Act, 2023.',
    hasPendingLegalApproval: true,
    pendingApprovalNotice:
        'Pending formal legal approval: Final registered corporate entity name, registered office address in Karnataka/Delhi, and official appointment of the Data Protection Officer / Grievance Officer.',
    sections: [
      PolicySection(
        title: '1. Standalone DPDP Notice & Overview',
        content:
            'Dr. Hair ("we", "our", "us") values your privacy. In accordance with the Digital Personal Data Protection Act, 2023, this notice is presented as an independent, accessible statement of the personal data processed, the specific purposes for such processing, and the mechanisms by which you may exercise your statutory rights as a Data Principal.',
      ),
      PolicySection(
        title: '2. Personal Data We Collect',
        content:
            'We collect and process the following categories of personal and health-related wellness data:',
        bulletPoints: [
          'Identity & Contact Data: Mobile phone number, full name, email address, and delivery shipping addresses.',
          'Hair Assessment & Profile Data: Age range, biological gender, primary hair concerns, thinning stage, shedding levels, scalp oiliness/dryness, and lifestyle factors.',
          'Scalp Progression Images: User-uploaded photographs of the crown, frontal hairline, and scalp vertex.',
          'Care Regimen & Interaction Data: Completed routine tasks, scheduled doses, reminder timestamps, and hair coach appointment bookings.',
        ],
      ),
      PolicySection(
        title: '3. Purpose of Processing',
        content:
            'Your personal data is collected and processed exclusively for legitimate specified purposes:',
        bulletPoints: [
          'To generate customized topical serum and oral supplement recommendations tailored to your follicular condition.',
          'To monitor your hair density progression over 30, 60, and 90-day intervals.',
          'To fulfill product orders, track delivery dispatches, and communicate regimen updates.',
          'To deliver local dose consistency reminder notifications scheduled by you.',
        ],
      ),
      PolicySection(
        title: '4. Scalp Photos & Clinician Review Sharing',
        content:
            'Photographs and assessment responses uploaded in this version of the app are held locally on your device for session review. In this build, live dermatologist tele-triage endpoints are disconnected. We do not sell, rent, or share your scalp photographs with third-party advertising brokers.',
        isPendingApproval: true,
        pendingApprovalNotes:
            'Clinician network agreement pending. When tele-dermatology dispatch is enabled, data will be transmitted via encrypted HIPAA/DISHA-aligned channels to verified medical practitioners.',
      ),
      PolicySection(
        title: '5. Data Retention & Erasure',
        content:
            'We retain personal data only for as long as necessary to fulfill the care purposes or comply with statutory accounting requirements. You have the right at any time to request erasure of your scalp check-in photographs or personal account by contacting our support team.',
      ),
      PolicySection(
        title: '6. Your Rights Under DPDP Act, 2023',
        content:
            'As a Data Principal, you have the statutory right to: (a) Access a summary of personal data processed, (b) Correct, complete, or update inaccurate data, (c) Withdraw consent and request data deletion, and (d) Nominate an individual in the event of death or incapacity.',
      ),
      PolicySection(
        title: '7. Grievance Redressal Officer',
        content:
            'For any privacy inquiries, data subject access requests, or complaints under the DPDP Act and Consumer Protection (E-Commerce) Rules:',
        isPendingApproval: true,
        pendingApprovalNotes:
            'Pending corporate appointment: Name of Grievance Redressal Officer, registered address, and official grievance email address.',
        bulletPoints: [
          'Designation: Grievance Redressal Officer (Data Protection)',
          'Corporate Entity: Dr. Hair Wellness Private Limited (Pending Final Legal Incorporation)',
          'Email: support@drhair.com / grievance@drhair.com',
          'Response Timeline: Acknowledgment within 48 hours; resolution within 30 days as prescribed by law.',
        ],
      ),
    ],
  );

  // 2. TERMS & CONDITIONS
  static const PolicyDocument _termsAndConditions = PolicyDocument(
    type: PolicyType.termsAndConditions,
    title: 'Terms & Conditions',
    lastUpdated: currentEffectiveDate,
    summary:
        'These Terms & Conditions govern your access to and use of the Dr. Hair mobile application, care tracking tools, consultations, and personalized hair products.',
    hasPendingLegalApproval: true,
    pendingApprovalNotice:
        'Pending formal legal review: Governing state jurisdiction (Bengaluru / Delhi courts) and limitation of liability caps for product manufacturing.',
    sections: [
      PolicySection(
        title: '1. Clinical & Medical Disclaimer',
        content:
            'Dr. Hair provides cosmetic and topical trichological wellness products and general lifestyle regimen tracking. The in-app hair assessment, density ratings, and algorithmic product suggestions are preliminary wellness assessments and DO NOT constitute an in-person medical diagnosis, prescription, or clinical guarantee.',
        bulletPoints: [
          'If you experience acute scalp dermatitis, sudden alopecia areata, open lesions, or adverse allergic reactions, discontinue use immediately and consult a board-certified dermatologist.',
          'Any coach bookings scheduled via the app are supportive wellness consultations, not emergency medical services.',
        ],
      ),
      PolicySection(
        title: '2. User Accounts & Verification',
        content:
            'You are responsible for maintaining the confidentiality of your mobile number and authentication codes. You agree that all information supplied during hair assessments, shipping addresses, and personal profiles is truthful, current, and accurate.',
      ),
      PolicySection(
        title: '3. Regimen Use & Safety Instructions',
        content:
            'Users must carefully follow product application instructions, dosage limits (e.g. 1ml topical booster daily), and patch-test guidelines before applying topical treatments. Keep products out of reach of children and avoid contact with eyes.',
      ),
      PolicySection(
        title: '4. Demo & Prototype States',
        content:
            'Portions of this application—including local mock payment checkouts, simulated clinician triage, and local push notifications—are provided as functional application demonstrations. Real payments, delivery commitments, and clinical submissions will not be billed or fulfilled until payment gateway and clinic backend contracts are live.',
      ),
      PolicySection(
        title: '5. Intellectual Property',
        content:
            'All text, graphics, proprietary treatment formulations, logo marks, software code, and educational content in Dr. Hair are the exclusive intellectual property of Dr. Hair and protected under copyright and trademark laws.',
      ),
      PolicySection(
        title: '6. Governing Law & Jurisdiction',
        content:
            'These Terms are governed by and construed in accordance with the laws of India. Any disputes arising hereunder shall be subject to the exclusive jurisdiction of the competent courts in Bengaluru, Karnataka, India.',
        isPendingApproval: true,
        pendingApprovalNotes:
            'Jurisdiction subject to confirmation by company legal counsel upon formal incorporation.',
      ),
    ],
  );

  // 3. RETURNS & REFUNDS POLICY
  static const PolicyDocument _returnsAndRefunds = PolicyDocument(
    type: PolicyType.returnsAndRefunds,
    title: 'Returns & Refunds Policy',
    lastUpdated: currentEffectiveDate,
    summary:
        'Our policy on product returns, hygiene seal restrictions, transit damage replacements, and payment refund turnaround times.',
    hasPendingLegalApproval: true,
    pendingApprovalNotice:
        'Pending formal business review: Banking partner refund processing turnaround timeline (5-7 business days) and designated reverse pickup courier logistics contract.',
    sections: [
      PolicySection(
        title: '1. Hygiene & Seal Restrictions',
        content:
            'Due to strict medical hygiene, safety, and personal care contamination standards under applicable consumer protection regulations:',
        bulletPoints: [
          'Topical serums, cleansers, shampoos, and oral nutritional supplements CANNOT be returned or refunded once the tamper-evident security seal or outer packaging has been opened, unsealed, or used.',
          'Unopened, sealed product kits in original undamaged packaging may be eligible for return authorization within 7 days of delivery, subject to inspection.',
        ],
      ),
      PolicySection(
        title: '2. Damaged, Defective, or Incorrect Deliveries',
        content:
            'If your package arrives physically damaged in transit, leaking, defective, or contains the wrong product:',
        bulletPoints: [
          'Report the issue within 48 hours of receipt via the in-app Contact Support page or email support@drhair.com.',
          'Provide clear photos or video footage of the outer shipping box, shipping label, and the damaged item.',
          'Upon verification, Dr. Hair will dispatch a free replacement shipment or issue a full refund to the original payment source.',
        ],
      ),
      PolicySection(
        title: '3. Refund Processing & Method',
        content:
            'Approved refunds are credited back to the original method of payment (UPI, Credit/Debit Card, or Netbanking).',
        isPendingApproval: true,
        pendingApprovalNotes:
            'Turnaround subject to final payment gateway integration (Razorpay / Cashfree SLA): typically 5 to 7 business days from authorization.',
      ),
      PolicySection(
        title: '4. Non-Refundable Services',
        content:
            'Completed guidance consultations with hair coaches, customized hair analysis assessments, and prescription review service fees (if applicable) are non-refundable once the service has been rendered.',
      ),
    ],
  );

  // 4. CANCELLATION POLICY
  static const PolicyDocument _cancellationPolicy = PolicyDocument(
    type: PolicyType.cancellationPolicy,
    title: 'Cancellation Policy',
    lastUpdated: currentEffectiveDate,
    summary:
        'Guidelines and cutoff times for cancelling product orders and hair coach guidance appointments.',
    hasPendingLegalApproval: true,
    pendingApprovalNotice:
        'Pending business review: Courier API dispatch webhook integration for automated order cancellation locks.',
    sections: [
      PolicySection(
        title: '1. Product Order Cancellation Cutoff',
        content:
            'Because orders are prepared and dispatched rapidly through express couriers (e.g. BlueDart Express):',
        bulletPoints: [
          'Orders may be cancelled free of charge ONLY while the order status is in "Processing" and before courier dispatch tracking has been generated.',
          'Once an order has entered "Shipped" or "Out for Delivery", it cannot be cancelled. You may refuse delivery at the doorstep, subject to return shipping terms.',
        ],
      ),
      PolicySection(
        title: '2. Coach Consultation Cancellations & Rescheduling',
        content:
            'You may reschedule or cancel a booked video consultation with a hair specialist up to 4 hours prior to the scheduled slot without penalty. Missed appointments without notice may forfeit the consultation slot.',
      ),
      PolicySection(
        title: '3. Subscription Regimen Cancellations',
        content:
            'If you are enrolled in an auto-replenishment monthly care regimen, you can pause or cancel upcoming shipments at any time up to 48 hours before the scheduled monthly billing date directly from your Profile settings.',
      ),
    ],
  );

  // 5. MONEY-BACK GUARANTEE (Explicitly Pending Formal Approval)
  static const PolicyDocument _moneyBackGuarantee = PolicyDocument(
    type: PolicyType.moneyBackGuarantee,
    title: 'Money-Back Guarantee',
    lastUpdated: currentEffectiveDate,
    summary:
        'Terms regarding the proposed Dr. Hair 90-Day Regrowth Consistency Guarantee. Please note that these terms are currently draft proposals pending formal corporate and clinical validation.',
    hasPendingLegalApproval: true,
    pendingApprovalNotice:
        'POLICY DETAILS PENDING FORMAL BUSINESS & LEGAL APPROVAL. Dr. Hair does not currently represent a binding commercial money-back guarantee in production. The terms below represent proposed qualification standards under internal review.',
    sections: [
      PolicySection(
        title: '1. Status: Under Business & Legal Review',
        content:
            'Dr. Hair is committed to clinically proven trichological efficacy. However, because biological hair regrowth response varies by genetics, nutritional baseline, and consistency, a binding money-back guarantee is subject to strict eligibility criteria that are currently pending executive and legal ratification.',
        isPendingApproval: true,
        pendingApprovalNotes:
            'Do not treat this policy as an active legal warranty until officially ratified and published on the production legal registry.',
      ),
      PolicySection(
        title: '2. Proposed Consistency Qualification Criteria',
        content:
            'Under the proposed 90-day consistency framework, eligible participants must demonstrate:',
        bulletPoints: [
          'Continuous, uninterrupted use of the prescribed daily topical serum and supplement regimen for a minimum of 90 consecutive days.',
          'Logging of at least 85% of daily routine tasks in the Dr. Hair care tracker.',
          'Monthly scalp progression check-in photographs taken on Day 1 (baseline), Day 30, Day 60, and Day 90 under identical lighting and camera angles.',
        ],
      ),
      PolicySection(
        title: '3. Proposed Exclusions',
        content:
            'The proposed guarantee would not apply to: (a) Advanced Norwood Stage 6-7 complete follicular fibrosis, (b) Hair loss caused by chemotherapy, thyroid dysfunction, or autoimmune conditions, (c) Inconsistent application with multi-week gaps, or (d) Simultaneous use of competing unapproved chemical agents.',
      ),
      PolicySection(
        title: '4. Claims Process (When Ratified)',
        content:
            'Upon formal corporate launch, claims would be reviewed by a clinical trichology board comparing verified baseline and 90-day photographs. Details will be updated here once approved by company directors.',
      ),
    ],
  );
}
