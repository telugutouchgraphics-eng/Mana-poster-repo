import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/purchase_invoice_service.dart';

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  State<PurchaseInvoicesScreen> createState() => _PurchaseInvoicesScreenState();
}

class _PurchaseInvoicesScreenState extends State<PurchaseInvoicesScreen>
    with AppLanguageStateMixin {
  final PurchaseInvoiceService _service = PurchaseInvoiceService();
  Future<List<PurchaseInvoice>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchInvoices();
  }

  Future<void> _refresh() async {
    final future = _service.fetchInvoices();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // FutureBuilder owns the visible error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PurchaseInvoicesCopy(context.strings);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: copy.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<PurchaseInvoice>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _InvoiceStateMessage(
                icon: Icons.receipt_long_outlined,
                title: copy.loadFailedTitle,
                message: copy.loadFailedMessage,
                actionLabel: copy.tryAgain,
                onAction: _refresh,
              );
            }
            final invoices = snapshot.data ?? const <PurchaseInvoice>[];
            if (invoices.isEmpty) {
              return _InvoiceStateMessage(
                icon: Icons.receipt_long_outlined,
                title: copy.emptyTitle,
                message: copy.emptyMessage,
                actionLabel: copy.refresh,
                onAction: _refresh,
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: invoices.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _InvoiceNotice(copy: copy);
                  }
                  return _InvoiceBillCard(
                    invoice: invoices[index - 1],
                    copy: copy,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceNotice extends StatelessWidget {
  const _InvoiceNotice({required this.copy});

  final _PurchaseInvoicesCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  copy.officialReceipt,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy.notice,
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _InvoiceBillCard extends StatelessWidget {
  const _InvoiceBillCard({
    required this.invoice,
    required this.copy,
  });

  final PurchaseInvoice invoice;
  final _PurchaseInvoicesCopy copy;

  @override
  Widget build(BuildContext context) {
    final displayDate = invoice.displayDate;
    final expiryAt = invoice.expiryAt;
    final user = FirebaseAuth.instance.currentUser;
    final userAccount =
        user?.email ?? user?.phoneNumber ?? copy.verifiedAccount;
    final hasPrice = invoice.priceLabel.trim().isNotEmpty;
    final displayPrice = hasPrice ? invoice.priceLabel : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Top Receipt Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'MANA POSTER',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        copy.taxInvoiceReceipt,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _PaidStampBadge(label: copy.paidStatus),
              ],
            ),
          ),

          // Receipt Perforation Divider
          const _ReceiptPerforationDivider(),

          // Bill Metadata
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              children: <Widget>[
                _ReceiptDetailRow(
                  label: copy.purchaseDate,
                  value: displayDate == null
                      ? copy.notAvailable
                      : _formatDateTime(context, displayDate),
                ),
                _ReceiptDetailRow(
                  label: copy.paymentMethod,
                  value: copy.googlePlayBilling,
                ),
                _ReceiptDetailRow(
                  label: copy.billedTo,
                  value: userAccount,
                ),
                _ReceiptDetailRow(
                  label: copy.platform,
                  value: invoice.platform?.isNotEmpty == true
                      ? invoice.platform!
                      : copy.googlePlay,
                ),
                if (invoice.orderId != null &&
                    invoice.orderId!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _OrderIdBar(
                    orderId: invoice.orderId!,
                    rawOrderId: invoice.rawOrderId,
                    copy: copy,
                  ),
                ],
              ],
            ),
          ),

          // Dashed Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _DashedLine(),
          ),
          const SizedBox(height: 14),

          // Purchased Item / Subscription Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  copy.planDetailsTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  invoice.planName,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFC7D2FE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: Color(0xFF4F46E5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        copy.periodLabel(invoice.billingPeriod),
                                        style: const TextStyle(
                                          color: Color(0xFF4338CA),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            displayPrice,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        copy.planBenefits,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 10),
                      // Subtotal row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            copy.subtotal,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            displayPrice,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Tax row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            copy.taxLabel,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            hasPrice ? copy.taxIncludedBadge : '—',
                            style: TextStyle(
                              color: hasPrice
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
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

          // Total Paid Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          copy.totalPaid,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPrice
                              ? copy.taxInclusive
                              : copy.priceUnavailable,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coverage Period Box (if dates exist)
          if (displayDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            copy.coverageTimeline,
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            expiryAt == null
                                ? '${copy.activeFrom}: ${_formatDate(context, displayDate)}'
                                : '${copy.activeFrom}: ${_formatDate(context, displayDate)} → ${copy.validUntil}: ${_formatDate(context, expiryAt)}',
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Merchant Legal Notice Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF94A3B8),
                    size: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    copy.officialMerchantNote,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  static String _formatDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }

  static String _formatDateTime(BuildContext context, DateTime value) {
    final date = MaterialLocalizations.of(context).formatMediumDate(value);
    final hour =
        value.hour > 12 ? value.hour - 12 : (value.hour == 0 ? 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final amPm = value.hour >= 12 ? 'PM' : 'AM';
    return '$date, $hour:$minute $amPm';
  }
}

class _ReceiptPerforationDivider extends StatelessWidget {
  const _ReceiptPerforationDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: _DashedLine(
              color: Color(0xFFCBD5E1),
              height: 1.2,
              dashWidth: 6,
              dashSpace: 4,
            ),
          ),
          Positioned(
            left: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8FC),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8FC),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({
    this.color = const Color(0xFFE2E8F0),
    this.height = 1.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  final Color color;
  final double height;
  final double dashWidth;
  final double dashSpace;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        if (dashCount <= 0) return const SizedBox.shrink();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OrderIdBar extends StatelessWidget {
  const _OrderIdBar({
    required this.orderId,
    required this.rawOrderId,
    required this.copy,
  });

  final String orderId;
  final String? rawOrderId;
  final _PurchaseInvoicesCopy copy;

  @override
  Widget build(BuildContext context) {
    final toCopy = rawOrderId ?? orderId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              orderId,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: toCopy));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(copy.orderIdCopied),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.copy_rounded,
                    size: 12,
                    color: Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    copy.copyOrderId,
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ReceiptDetailRow extends StatelessWidget {
  const _ReceiptDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidStampBadge extends StatelessWidget {
  const _PaidStampBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            size: 13,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF047857),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceStateMessage extends StatelessWidget {
  const _InvoiceStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 46, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => onAction(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseInvoicesCopy {
  const _PurchaseInvoicesCopy(this.strings);

  final AppStrings strings;

  String priceLabel(PurchaseInvoice invoice) {
    final amount =
        invoice.priceLabel.isEmpty ? priceUnavailable : invoice.priceLabel;
    final period = periodLabel(invoice.billingPeriod);
    return period.isEmpty ? amount : '$amount · $period';
  }

  String periodLabel(InvoiceBillingPeriod period) {
    return switch (period) {
      InvoiceBillingPeriod.monthly => monthlyPlan,
      InvoiceBillingPeriod.yearly => yearlyPlan,
      InvoiceBillingPeriod.introductory => introductoryPlan,
      InvoiceBillingPeriod.unknown => strings.localized(
        telugu: 'ప్రామాణిక ప్లాన్',
        english: 'Standard Plan',
        hindi: 'मानक योजना',
        tamil: 'நிலையான திட்டம்',
        kannada: 'ಪ್ರಾಮಾಣಿಕ ಯೋಜನೆ',
        malayalam: 'സ്റ്റാൻഡേർഡ് പ്ലാൻ',
        marathi: 'मानक योजना',
        gujarati: 'પ્રમાણભૂત પ્લાન',
        bengali: 'স্ট্যান্ডার্ড প্ল্যান',
        punjabi: 'ਸਟੈਂਡਰਡ ਪਲਾਨ',
        odia: 'ଷ୍ଟାଣ୍ଡାର୍ଡ ପ୍ଲାନ୍',
        assamese: 'মানক আঁচনি',
        konkani: 'प्रमाणीत येवजण',
        nepali: 'मानक योजना',
        meitei: 'স্তেন্দর্দ প্লান',
        mizo: 'Standard Plan',
        kashmiri: 'سٹینڈرڈ پلان',
        ladakhi: 'ཚད་ལྡན་འཆར་གཞི།',
      ),
    };
  }

  String get taxInvoiceReceipt => strings.localized(
    telugu: 'పన్ను ఇన్వాయిస్ & రసీదు',
    english: 'Tax Invoice & Receipt',
    hindi: 'कर इनवॉइस और रसीद',
    tamil: 'வரி விலைப்பட்டியல் & ரசீது',
    kannada: 'ತೆರಿಗೆ ಇನ್‌ವಾಯ್ಸ್ ಮತ್ತು ರಶೀದಿ',
    malayalam: 'ടാക്സ് ഇൻവോയ്സും രസീതും',
    marathi: 'कर बीजक आणि पावती',
    gujarati: 'ટેક્સ ઇનવોઇસ અને રસીદ',
    bengali: 'ট্যাক্স ইনভয়েস এবং রসিদ',
    punjabi: 'ਟੈਕਸ ਇਨਵੌਇਸ ਅਤੇ ਰਸੀਦ',
    odia: 'ଟ୍ୟାକ୍ସ ଇନଭଏସ୍ ଏବଂ ରସିଦ୍',
    assamese: 'কৰ ইনভয়েচ আৰু ৰচিদ',
    konkani: 'कर इनव्हॉईस आनी पावती',
    nepali: 'कर बीजक तथा रसिद',
    meitei: 'তেক্স ইনভোইস অমসুং রসিদ',
    mizo: 'Chhiah Invoice leh Receipt',
    kashmiri: 'ٹیکس اِنوائس تہٕ رسیٖد',
    ladakhi: 'ཁྲལ་གྱི་ཐོ་དང་འཛིན་ཡིག',
  );

  String get officialReceipt => strings.localized(
    telugu: 'అధికారిక డిజిటల్ రసీదు',
    english: 'Official Digital Receipt',
    hindi: 'आधिकारिक डिजिटल रसीद',
    tamil: 'அதிகாரப்பூர்வ டிஜிட்டல் ரசீது',
    kannada: 'ಅಧಿಕೃತ ಡಿಜಿಟಲ್ ರಶೀದಿ',
    malayalam: 'ഔദ്യോഗിക ഡിജിറ്റൽ രസീത്',
    marathi: 'अधिकृत डिजिटल पावती',
    gujarati: 'સત્તાવાર ડિજિટલ રસીદ',
    bengali: 'অফিসিয়াল ডিজিটাল রসিদ',
    punjabi: 'ਅਧਿਕਾਰਤ ਡਿਜੀਟਲ ਰਸੀਦ',
    odia: 'ଅଫିସିଆଲ୍ ଡିଜିଟାଲ୍ ରସିଦ୍',
    assamese: 'আনুষ্ঠানিক ডিজিটেল ৰচিদ',
    konkani: 'अधिकारिक डिजिटल पावती',
    nepali: 'आधिकारिक डिजिटल रसिद',
    meitei: 'ওফিসিএল দিজিতেল রসিদ',
    mizo: 'Official Digital Receipt',
    kashmiri: 'سرکٲرؠ ڈیجیٹل رسیٖد',
    ladakhi: 'གཞུང་འབྲེལ་ཌི་ཇི་ཊཱལ་འཛིན་ཡིག',
  );

  String get paidStatus => strings.localized(
    telugu: 'చెల్లించబడింది',
    english: 'PAID',
    hindi: 'भुगतान पूर्ण',
    tamil: 'செலுத்தப்பட்டது',
    kannada: 'ಪಾವತಿಸಲಾಗಿದೆ',
    malayalam: 'പണം നൽകി',
    marathi: 'भरणा केला',
    gujarati: 'ચુકવેલ',
    bengali: 'পরিশোধিত',
    punjabi: 'ਭੁਗਤਾਨ ਹੋ ਗਿਆ',
    odia: 'ପୈଠ ହୋଇଛି',
    assamese: 'পৰিশোধিত',
    konkani: 'फारीक केलां',
    nepali: 'भुक्तान गरियो',
    meitei: 'পীথোকখ্রে',
    mizo: 'PEK TAWH',
    kashmiri: 'ادا کٔرمٕژ',
    ladakhi: 'སྤྲད་ཟིན་པ།',
  );

  String get billedTo => strings.localized(
    telugu: 'ఖాతాదారు',
    english: 'Billed To',
    hindi: 'बिल प्राप्तकर्ता',
    tamil: 'பில் பெறுநர்',
    kannada: 'ಬಿಲ್ ಪಡೆದವರು',
    malayalam: 'ബിൽ ചെയ്ത വ്യക്തി',
    marathi: 'बिल कोणाच्या नावे',
    gujarati: 'બિલ ધારક',
    bengali: 'বিল প্রাপক',
    punjabi: 'ਬਿੱਲ ਪ੍ਰਾਪਤਕਰਤਾ',
    odia: 'ବିଲ୍ ପ୍ରାପ୍ତକର୍ତ୍ତା',
    assamese: 'বিল প্ৰাপক',
    konkani: 'बील कोणाचे नांवार',
    nepali: 'बिल प्राप्तकर्ता',
    meitei: 'বিল ফংবা মী',
    mizo: 'Billed To',
    kashmiri: 'بل حٲصل کَرَن وول',
    ladakhi: 'ཐོ་ཐོབ་མི།',
  );

  String get paymentMethod => strings.localized(
    telugu: 'చెల్లింపు విధానం',
    english: 'Payment Method',
    hindi: 'भुगतान का तरीका',
    tamil: 'பணம் செலுத்தும் முறை',
    kannada: 'ಪಾವತಿ ವಿಧಾನ',
    malayalam: 'പേയ്‌മെന്റ് രീതി',
    marathi: 'पेमेंट पद्धत',
    gujarati: 'ચુકવણી પદ્ધતિ',
    bengali: 'পেমেন্ট পদ্ধতি',
    punjabi: 'ਭੁਗਤਾਨ ਵਿਧੀ',
    odia: 'ପେମେଣ୍ଟ ପ୍ରଣାଳୀ',
    assamese: 'পৰিশোধ পদ্ধতি',
    konkani: 'पेमेंट पद्धत',
    nepali: 'भुक्तानी विधि',
    meitei: 'পীথোকপগী পাম্বৈ',
    mizo: 'Pawisa pek dan',
    kashmiri: 'ادائیگی ہُنٛد طریقہٕ',
    ladakhi: 'དངུལ་སྤྲོད་ཐབས་ལམ།',
  );

  String get googlePlayBilling => strings.localized(
    telugu: 'Google Play బిల్లింగ్',
    english: 'Google Play Billing',
    hindi: 'Google Play बिलिंग',
    tamil: 'Google Play பில்லிங்',
    kannada: 'Google Play ಬಿಲ್ಲಿಂಗ್',
    malayalam: 'Google Play ബില്ലിംഗ്',
    marathi: 'Google Play बिलिंग',
    gujarati: 'Google Play બિલિંગ',
    bengali: 'Google Play বিলিং',
    punjabi: 'Google Play ਬਿਲਿੰਗ',
    odia: 'Google Play ବିଲିଂ',
    assamese: 'Google Play বিলিং',
    konkani: 'Google Play बिलिंग',
    nepali: 'Google Play बिलिङ',
    meitei: 'Google Play বিলিং',
    mizo: 'Google Play Billing',
    kashmiri: 'Google Play بِلِنگ',
    ladakhi: 'Google Play ཐོ་བཀོད།',
  );

  String get itemDescription => strings.localized(
    telugu: 'వివరణ & ప్లాన్',
    english: 'Item & Plan Details',
    hindi: 'विवरण और प्लान',
    tamil: 'விவரம் & திட்டம்',
    kannada: 'ವಿವರಣೆ ಮತ್ತು ಯೋಜನೆ',
    malayalam: 'വിവരണം & പ്ലാൻ',
    marathi: 'तपशील आणि योजना',
    gujarati: 'વિગત અને પ્લાન',
    bengali: 'বিবরণ ও প্ল্যান',
    punjabi: 'ਵੇਰਵਾ ਅਤੇ ਪਲਾਨ',
    odia: 'ବିବରଣୀ ଓ ପ୍ଲାନ୍',
    assamese: 'বিৱৰণ আৰু আঁচনি',
    konkani: 'तपशील आनी येवजण',
    nepali: 'विवरण र योजना',
    meitei: 'অকুপ্পা মরোল অমসুং প্লান',
    mizo: 'Item & Plan Details',
    kashmiri: 'تفصیٖل تہٕ پلان',
    ladakhi: 'ཞིབ་ཕྲ་དང་འཆར་གཞི།',
  );

  String get duration => strings.localized(
    telugu: 'కాలపరిమితి',
    english: 'Duration',
    hindi: 'अवधि',
    tamil: 'கால அளவு',
    kannada: 'ಅವಧಿ',
    malayalam: 'കാലാവധി',
    marathi: 'कालावधी',
    gujarati: 'સમયગાળો',
    bengali: 'মেয়াদ',
    punjabi: 'ਮਿਆਦ',
    odia: 'ଅବଧି',
    assamese: 'সময়সীমা',
    konkani: 'काळ',
    nepali: 'अवधि',
    meitei: 'মতমাং',
    mizo: 'A hun chhung',
    kashmiri: 'مدت',
    ladakhi: 'དུས་ཡུན།',
  );

  String get amount => strings.localized(
    telugu: 'మొత్తం',
    english: 'Amount',
    hindi: 'राशि',
    tamil: 'தொகை',
    kannada: 'ಮೊತ್ತ',
    malayalam: 'തുക',
    marathi: 'रक्कम',
    gujarati: 'રકમ',
    bengali: 'পরিমাণ',
    punjabi: 'ਰਕਮ',
    odia: 'ରାଶି',
    assamese: 'পৰিমাণ',
    konkani: 'रक्कम',
    nepali: 'रकम',
    meitei: 'মমল',
    mizo: 'Zat',
    kashmiri: 'رقم',
    ladakhi: 'དངུལ་འབོར།',
  );

  String get planDetailsTitle => strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ వివరాలు',
    english: 'Subscription details',
    hindi: 'सदस्यता विवरण',
    tamil: 'சந்தா விவரங்கள்',
    kannada: 'ಚಂದಾದಾರಿಕೆ ವಿವರಗಳು',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ വിവരങ്ങൾ',
    marathi: 'सदस्यता तपशील',
    gujarati: 'સબ્સ્ક્રિપ્શન વિગતો',
    bengali: 'সাবস্ক্রিপশনের বিবরণ',
    punjabi: 'ਗਾਹਕੀ ਦੇ ਵੇਰਵੇ',
    odia: 'ସଦସ୍ୟତା ବିବରଣୀ',
    assamese: 'গ্ৰাহকভুক্তিৰ বিৱৰণ',
    konkani: 'वर्गणी तपशील',
    nepali: 'सदस्यता विवरण',
    meitei: 'সবস্ক্রিপ্সন মরোল',
    mizo: 'Subscription Details',
    kashmiri: 'سبسکرپشن تفصیٖل',
    ladakhi: 'མངགས་ཉོའི་ཞིབ་ཕྲ།',
  );

  String get subtotal => strings.localized(
    telugu: 'ఉపమొత్తం (Subtotal)',
    english: 'Subtotal',
    hindi: 'उप-योग (Subtotal)',
    tamil: 'கூட்டுத்தொகை (Subtotal)',
    kannada: 'ಉಪಮೊತ್ತ (Subtotal)',
    malayalam: 'ഉപതുക (Subtotal)',
    marathi: 'उप-एकूण (Subtotal)',
    gujarati: 'પેટા સરવાળો (Subtotal)',
    bengali: 'উপমোট (Subtotal)',
    punjabi: 'ਉਪ-ਕੁੱਲ (Subtotal)',
    odia: 'ଉପମୋଟ୍ (Subtotal)',
    assamese: 'উপমুঠ (Subtotal)',
    konkani: 'उप-एकूण (Subtotal)',
    nepali: 'उप-कुल (Subtotal)',
    meitei: 'সবতোতল (Subtotal)',
    mizo: 'Subtotal',
    kashmiri: 'سَب ٹوٹل (Subtotal)',
    ladakhi: 'བསྡོམས་ཐོ་ཕྲ་མོ། (Subtotal)',
  );

  String get taxLabel => strings.localized(
    telugu: 'వర్తించే పన్ను (GST)',
    english: 'Applicable Tax (GST)',
    hindi: 'लागू कर (GST)',
    tamil: 'பொருந்தக்கூடிய வரி (GST)',
    kannada: 'ಅನ್ವಯವಾಗುವ ತೆರಿಗೆ (GST)',
    malayalam: 'ബാധകമായ നികുതി (GST)',
    marathi: 'लागू कर (GST)',
    gujarati: 'લાગુ કર (GST)',
    bengali: 'প্রযোজ্য কর (GST)',
    punjabi: 'ਲਾਗੂ ਟੈਕਸ (GST)',
    odia: 'ପ୍ରଯୁଜ୍ୟ ଟ୍ୟାକ୍ସ (GST)',
    assamese: 'প্ৰଯোজ্য কৰ (GST)',
    konkani: 'लागू कर (GST)',
    nepali: 'लागू कर (GST)',
    meitei: 'চৎনবা তেক্স (GST)',
    mizo: 'Chhiah (GST)',
    kashmiri: 'لٲگوٗ ٹیکس (GST)',
    ladakhi: 'ཁྲལ་ (GST)',
  );

  String get taxIncludedBadge => strings.localized(
    telugu: 'ధరలోనే ఉంది (Included)',
    english: 'Included in price',
    hindi: 'कीमत में शामिल (Included)',
    tamil: 'விலையில் அடங்கும் (Included)',
    kannada: 'ಬೆಲೆಯಲ್ಲಿ ಸೇರಿದೆ (Included)',
    malayalam: 'വിലയിൽ ഉൾപ്പെടുത്തിയിട്ടുണ്ട് (Included)',
    marathi: 'किंमतीत समाविष्ट (Included)',
    gujarati: 'કિંમતમાં સામેલ (Included)',
    bengali: 'দামে অন্তর্ভুক্ত (Included)',
    punjabi: 'ਕੀਮਤ ਵਿੱਚ ਸ਼ਾਮਲ (Included)',
    odia: 'ମୂଲ୍ୟରେ ଅନ୍ତର୍ଭୁକ୍ତ (Included)',
    assamese: 'মূল্যত অন্তৰ্ভুক্ত (Included)',
    konkani: 'किमतींत आस्पावलां (Included)',
    nepali: 'मूल्यमा समावेश (Included)',
    meitei: 'মমলদা য়াওরে (Included)',
    mizo: 'Manah a tel sa',
    kashmiri: 'قیمتس مَنٛز شٲمِل',
    ladakhi: 'རིན་གོང་ནང་ཚུད་ཡོད།',
  );

  String get totalPaid => strings.localized(
    telugu: 'మొత్తం చెల్లింపు (Grand Total)',
    english: 'Total Paid (Grand Total)',
    hindi: 'कुल भुगतान (Grand Total)',
    tamil: 'மொத்த கட்டணம் (Grand Total)',
    kannada: 'ಒಟ್ಟು ಪಾವತಿ (Grand Total)',
    malayalam: 'ആകെ നൽകിയത് (Grand Total)',
    marathi: 'एकूण भरणा (Grand Total)',
    gujarati: 'કુલ ચુકવણી (Grand Total)',
    bengali: 'মোট পরিশোধ (Grand Total)',
    punjabi: 'ਕੁੱਲ ਭੁਗਤਾਨ (Grand Total)',
    odia: 'ସର୍ବମୋଟ ପୈଠ (Grand Total)',
    assamese: 'মুঠ পৰিশোধ (Grand Total)',
    konkani: 'सगळें मेळून फारीक (Grand Total)',
    nepali: 'कुल भुक्तानी (Grand Total)',
    meitei: 'অপুনবা পীথোকপা (Grand Total)',
    mizo: 'Pek zat zawng zawng (Grand Total)',
    kashmiri: 'کُل رقم ادا کٔرمٕژ (Grand Total)',
    ladakhi: 'ཁྱོན་བསྡོམས་སྤྲད་པ། (Grand Total)',
  );

  String get taxInclusive => strings.localized(
    telugu: 'అన్ని వర్తించే పన్నులు (GST) కలిపి',
    english: 'Inclusive of all applicable taxes (GST)',
    hindi: 'सभी लागू करों (GST) सहित',
    tamil: 'பொருந்தக்கூடிய அனைத்து வரிகளும் (GST) உட்பட',
    kannada: 'ಅನ್ವಯವಾಗುವ ಎಲ್ಲಾ ತೆರಿಗೆಗಳು (GST) ಸೇರಿವೆ',
    malayalam: 'ബാധകമായ എല്ലാ നികുതികളും (GST) ഉൾപ്പെടെ',
    marathi: 'सर्व लागू करांसह (GST)',
    gujarati: 'લાગુ તમામ કર (GST) સહિત',
    bengali: 'প্রযোজ্য সমস্ত কর (GST) অন্তর্ভুক্ত',
    punjabi: 'ਸਾਰੇ ਲਾਗੂ ਟੈਕਸ (GST) ਸ਼ਾਮਲ',
    odia: 'ସମସ୍ତ ପ୍ରଯୁଜ୍ୟ ଟ୍ୟାକ୍ସ (GST) ଅନ୍ତର୍ଭୁକ୍ତ',
    assamese: 'সকলো প্ৰযোজ্য কৰ (GST) অন্তৰ্ভুক্ত',
    konkani: 'सगळे लागू कर (GST) धरून',
    nepali: 'सबै लागू करहरू (GST) सहित',
    meitei: 'চৎনবা য়াবা তেক্স (GST) পুম্নমক য়াওনা',
    mizo: 'Chhiah (GST) tel vekin',
    kashmiri: 'سٲری لٲگوٗ ٹیکس (GST) رٔلِتھ',
    ladakhi: 'ཁྲལ་ཡོད་ཚད་ (GST) ཚུད་ཡོད།',
  );

  String get coverageTimeline => strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ వ్యవధి',
    english: 'Subscription Coverage',
    hindi: 'सदस्यता अवधि',
    tamil: 'சந்தா காலம்',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಅವಧಿ',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ കാലാവധി',
    marathi: 'सदस्यता कालावधी',
    gujarati: 'સબ્સ્ક્રિપ્શન સમયગાળો',
    bengali: 'সাবস্ক্রিপশন কভারেজ',
    punjabi: 'ਗਾਹਕੀ ਦੀ ਮਿਆਦ',
    odia: 'ସଦସ୍ୟତା ଅବଧି',
    assamese: 'গ্ৰাহকভুক্তিৰ সময়সীমা',
    konkani: 'वर्गणी काळ',
    nepali: 'सदस्यता कभरेज',
    meitei: 'সবস্ক্রিপ্সন মতম',
    mizo: 'Subscription Coverage',
    kashmiri: 'سبسکرپشن کوریج',
    ladakhi: 'མངགས་ཉོའི་དུས་ཡུན།',
  );

  String get activeFrom => strings.localized(
    telugu: 'ప్రారంభం',
    english: 'Active From',
    hindi: 'शुरू',
    tamil: 'தொடக்கம்',
    kannada: 'ಪ್ರಾರಂಭ',
    malayalam: 'ആരംഭം',
    marathi: 'सुरू',
    gujarati: 'શરૂ',
    bengali: 'শুরু',
    punjabi: 'ਸ਼ੁਰੂਆਤ',
    odia: 'ଆରମ୍ଭ',
    assamese: 'আৰম্ভণি',
    konkani: 'सुरू',
    nepali: 'सुरु',
    meitei: 'হৌখিবা',
    mizo: 'A tir',
    kashmiri: 'شروٗع',
    ladakhi: 'འགོ་བཙུགས།',
  );

  String get copyOrderId => strings.localized(
    telugu: 'కాపీ',
    english: 'Copy',
    hindi: 'कॉपी',
    tamil: 'நகலெடு',
    kannada: 'ನಕಲಿಸಿ',
    malayalam: 'പകർത്തു',
    marathi: 'कॉपी करा',
    gujarati: 'કોપી',
    bengali: 'কপি',
    punjabi: 'ਕਾਪੀ',
    odia: 'କପି',
    assamese: 'কপি',
    konkani: 'कॉपी',
    nepali: 'प्रतिलिपि',
    meitei: 'কোপী',
    mizo: 'Copy',
    kashmiri: 'نَقٕل',
    ladakhi: 'འདྲ་བཤུས།',
  );

  String get orderIdCopied => strings.localized(
    telugu: 'ఆర్డర్ ID క్లిప్‌బోర్డ్‌కి కాపీ చేయబడింది',
    english: 'Order ID copied to clipboard',
    hindi: 'ऑर्डर ID क्लिपबोर्ड पर कॉपी हो गया',
    tamil: 'ஆர்டர் ஐடி கிளிப்போர்டில் நகலெடுக்கப்பட்டது',
    kannada: 'ಆರ್ಡರ್ ID ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ನಕಲಿಸಲಾಗಿದೆ',
    malayalam: 'ഓർഡർ ഐഡി ക്ലിപ്പ്ബോർഡിലേക്ക് പകർത്തി',
    marathi: 'ऑर्डर आयडी क्लिपबोर्डवर कॉपी झाला',
    gujarati: 'ઓર્ડર આઈડી ક્લિપબોર્ડ પર કોપી થયો',
    bengali: 'অর্ডার আইডি ক্লিপবোর্ডে কপি করা হয়েছে',
    punjabi: 'ਆਰਡਰ ID ਕਲਿੱਪਬੋਰਡ ਤੇ ਕਾਪੀ ਹੋ ਗਿਆ',
    odia: 'ଅର୍ଡର ID କ୍ଲିପବୋର୍ଡକୁ କପି ହୋଇଛି',
    assamese: 'অৰ্ডাৰ ID ক্লিপবৰ্ডত কপি কৰা হ’ল',
    konkani: 'ऑर्डर आयडी क्लिपबोर्डाचेर कॉपी जाला',
    nepali: 'अर्डर ID क्लिपबोर्डमा प्रतिलिपि गरियो',
    meitei: 'ওর্দর ID ক্লিপবোর্দতা কোপী তৌরে',
    mizo: 'Order ID clipboard-ah copy a ni',
    kashmiri: 'آرڈر ID کلپ بورڈس پؠٹھ نَقٕل کَرنہٕ آمٕژ',
    ladakhi: 'བཀའ་རྒྱའི་ཨང་གྲངས་འདྲ་བཤུས་ཟིན་པ།',
  );

  String get officialMerchantNote => strings.localized(
    telugu:
        'Google Play ఈ కొనుగోలుకు అధికారిక వ్యాపారి. అధికారిక పన్ను రసీదుల కోసం payments.google.com చూడండి.',
    english:
        'Google Play is the merchant of record for this purchase. For official tax receipts, visit payments.google.com.',
    hindi:
        'Google Play इस खरीदारी का आधिकारिक मर्चेंट है। आधिकारिक टैक्स रसीदों के लिए payments.google.com पर जाएं।',
    tamil:
        'Google Play இந்த வாங்குதலுக்கு அதிகாரப்பூர்வ வணிகர். அதிகாரப்பூர்வ வரி ரசீதுகளுக்கு payments.google.com ஐப் பார்க்கவும்.',
    kannada:
        'Google Play ಈ ಖರೀದಿಗೆ ಅಧಿಕೃತ ವ್ಯಾಪಾರಿಯಾಗಿದೆ. ಅಧಿಕೃತ ತೆರಿಗೆ ರಶೀದಿಗಳಿಗಾಗಿ payments.google.com ಗೆ ಭೇಟಿ ನೀಡಿ.',
    malayalam:
        'ഈ വാങ്ങലിന്റെ ഔദ്യോഗിക വ്യാപാരി Google Play ആണ്. ഔദ്യോഗിക നികുതി രസീതുകൾക്കായി payments.google.com സന്ദർശിക്കുക.',
    marathi:
        'Google Play या खरेदीसाठी अधिकृत व्यापारी आहे. अधिकृत कर पावत्यांसाठी payments.google.com ला भेट द्या.',
    gujarati:
        'આ ખરીદી માટે Google Play સત્તાવાર મર્ચન્ટ છે. સત્તાવાર કર રસીદો માટે payments.google.com ની મુલાકાત લો.',
    bengali:
        'Google Play এই কেনাকাটার অফিসিয়াল মার্চেন্ট। অফিসিয়াল কর রসিদের জন্য payments.google.com দেখুন।',
    punjabi:
        'Google Play ਇਸ ਖਰੀਦ ਲਈ ਅਧਿਕਾਰਤ ਵਪਾਰੀ ਹੈ। ਅਧਿਕਾਰਤ ਟੈਕਸ ਰਸੀਦਾਂ ਲਈ payments.google.com ਦੇਖੋ।',
    odia:
        'Google Play ଏହି କ୍ରୟ ପାଇଁ ଅଫିସିଆଲ୍ ବ୍ୟବସାୟୀ ଅଟେ। ଅଫିସିଆଲ୍ ଟ୍ୟାକ୍ସ ରସିଦ୍ ପାଇଁ payments.google.com ଦେଖନ୍ତୁ।',
    assamese:
        'Google Play এই ক্ৰয়ৰ আনুষ্ঠানিক ব্যৱসায়ী। আনুষ্ঠানিক কৰ ৰচিদৰ বাবে payments.google.com চাওক।',
    konkani:
        'Google Play ह्या खरेदी खातीर अधिकारिक व्यापारी आसा. अधिकारिक कर पावत्यां खातीर payments.google.com पळयात.',
    nepali:
        'Google Play यस खरिदको लागि आधिकारिक व्यापारी हो। आधिकारिक कर रसिदहरूको लागि payments.google.com मा जानुहोस्।',
    meitei:
        'Google Play অসি লৈবসিগী ওফিসিএল ভেন্দোরনি। ওফিসিএল তেক্স রসিদকীদমক payments.google.com দা চঙবিয়ু।',
    mizo:
        'Google Play hi he purchase-ah hian merchant a ni. Official tax receipt tan payments.google.com tlawh rawh.',
    kashmiri:
        'Google Play چھُ اَتھ خریٖدٲری خٲطرٕ سَرکٲرؠ تاجر۔ سَرکٲرؠ ٹیکس رسیٖد خٲطرٕ کٔرِو payments.google.com وِزِٹ۔',
    ladakhi:
        'Google Play འདི་ཉོ་ཚོང་འདིའི་གཞུང་འབྲེལ་ཚོང་པ་ཡིན། གཞུང་འབྲེལ་ཁྲལ་གྱི་འཛིན་ཡིག་ཆེད་ payments.google.com ལ་གཟིགས།',
  );

  String get planBenefits => strings.localized(
    telugu:
        'అన్‌లిమిటెడ్ HD డౌన్‌లోడ్లు · నో వాటర్‌మార్క్ · అన్ని ప్రీమియం పోస్టర్లు',
    english: 'Unlimited HD Downloads · No Watermark · All Premium Posters',
    hindi: 'अनलिमिटेड HD डाउनलोड · नो वॉटरमार्क · सभी प्रीमियम पोस्टर',
    tamil:
        'வரம்பற்ற HD பதிவிறக்கங்கள் · வாட்டர்மார்க் இல்லை · அனைத்து பிரீமியம் போஸ்டர்கள்',
    kannada:
        'ಅನ್‌ಲಿಮಿಟೆಡ್ HD ಡೌನ್‌ಲೋಡ್‌ಗಳು · ವಾಟರ್‌ಮಾರ್ಕ್ ಇಲ್ಲ · ಎಲ್ಲಾ ಪ್ರೀಮಿಯಂ ಪೋಸ್ಟರ್‌ಗಳು',
    malayalam:
        'പരിധിയില്ലാത്ത HD ഡൗൺലോഡുകൾ · വാട്ടർമാർക്ക് ഇല്ല · എല്ലാ പ്രീമിയം പോസ്റ്ററുകളും',
    marathi: 'अमर्याद HD डाऊनलोड्स · वॉटरमार्क नाही · सर्व प्रीमियम पोस्टर्स',
    gujarati:
        'અમર્યાદિત HD ડાઉનલોડ્સ · વોટરમાર્ક નથી · તમામ પ્રીમિયમ પોસ્ટર્સ',
    bengali: 'আনলিমিটেড HD ডাউনলোড · ওয়াটারমার্ক নেই · সমস্ত প্রিমিয়াম পোস্টার',
    punjabi: 'ਅਸੀਮਤ HD ਡਾਊਨਲੋਡ · ਕੋਈ ਵਾਟਰਮਾਰਕ ਨਹੀਂ · ਸਾਰੇ ਪ੍ਰੀਮੀਅਮ ਪੋਸਟਰ',
    odia: 'ଅସୀମିତ HD ଡାଉନଲୋଡ୍ · ୱାଟରମାର୍କ ନାହିଁ · ସମସ୍ତ ପ୍ରିମିୟମ୍ ପୋଷ୍ଟର୍',
    assamese: 'সীমাহীন HD ডাউনল’ড · ৱাটাৰমাৰ্ক নাই · সকলো প্ৰিমিয়াম প’ষ্টাৰ',
    konkani: 'अमर्यादीत HD डावनलोड · वॉटरमार्क ना · सगळे प्रीमियम पोस्टर्स',
    nepali:
        'असीमित HD डाउनलोडहरू · कुनै वाटरमार्क छैन · सबै प्रिमियम पोस्टरहरू',
    meitei:
        'লেপকপা য়াওদবা HD দাউনলোদ · ৱাতরমাক য়াওদে · প্রিমিয়ম পোস্তর পুম্নমক',
    mizo: 'Unlimited HD Downloads · No Watermark · All Premium Posters',
    kashmiri: 'لامحدود HD ڈاون لوڈ · واٹر مارک وَرٲے · سٲری پریمیم پوسٹر',
    ladakhi:
        'ཚད་མེད་ HD ཕབ་ལེན། · ཆུ་རྟགས་མེད། · ཁྱད་འཕགས་ཀྱི་སྦྱར་ཡིག་ཡོད་ཚད།',
  );

  String get verifiedAccount => strings.localized(
    telugu: 'ధృవీకరించబడిన ఖాతా',
    english: 'Verified Account',
    hindi: 'सत्यापित खाता',
    tamil: 'சரிபார்க்கப்பட்ட கணக்கு',
    kannada: 'ಪರಿಶೀಲಿಸಿದ ಖಾತೆ',
    malayalam: 'സ്ഥിരീകരിച്ച അക്കൗണ്ട്',
    marathi: 'सत्यापित खाते',
    gujarati: 'ચકાસાયેલ એકાઉન્ટ',
    bengali: 'যাচাইকৃত অ্যাকাউন্ট',
    punjabi: 'ਪ੍ਰਮਾਣਿਤ ਖਾਤਾ',
    odia: 'ଯାଞ୍ଚ ହୋଇଥିବା ଖାତା',
    assamese: 'প্ৰমাণিত একাউণ্ট',
    konkani: 'तपासणी जाल्लें खाते',
    nepali: 'प्रमाणित खाता',
    meitei: 'চেক তৌরবা একাউন্ত',
    mizo: 'Verified Account',
    kashmiri: 'تصدیٖق شُدٕ اَکاؤنٹ',
    ladakhi: 'དཔྱད་ཞིབ་ཟིན་པའི་ཁ་ཐོ།',
  );

  String get priceUnavailable => strings.localized(
    telugu: 'ధర రికార్డు అందుబాటులో లేదు',
    english: 'Price record unavailable',
    hindi: 'कीमत का रिकॉर्ड उपलब्ध नहीं है',
    tamil: 'விலைப் பதிவு கிடைக்கவில்லை',
    kannada: 'ಬೆಲೆಯ ದಾಖಲೆ ಲಭ್ಯವಿಲ್ಲ',
    malayalam: 'വിലയുടെ രേഖ ലഭ്യമല്ല',
    marathi: 'किमतीची नोंद उपलब्ध नाही',
    gujarati: 'કિંમતનો રેકોર્ડ ઉપલબ્ધ નથી',
    bengali: 'দামের রেকর্ড পাওয়া যাচ্ছে না',
    punjabi: 'ਕੀਮਤ ਦਾ ਰਿਕਾਰਡ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
    odia: 'ମୂଲ୍ୟର ରେକର୍ଡ ଉପଲବ୍ଧ ନାହିଁ',
    assamese: 'মূল্যৰ ৰেকৰ্ড উপলব্ধ নহয়',
    konkani: 'किमतीची नोंद उपलब्ध ना',
    nepali: 'मूल्यको अभिलेख उपलब्ध छैन',
    meitei: 'মমলগী রেকোর্দ ফংদে',
    mizo: 'Man chhinchhiahna a awm lo',
    kashmiri: 'قیمتُک ریکارڈ چھُ نہٕ دستیاب',
    ladakhi: 'རིན་གོང་གི་ཐོ་མེད།',
  );

  String get monthlyPlan => strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
    hindi: 'मासिक योजना',
    tamil: 'மாதாந்திரத் திட்டம்',
    kannada: 'ಮಾಸಿಕ ಯೋಜನೆ',
    malayalam: 'പ്രതിമാസ പ്ലാൻ',
    marathi: 'मासिक योजना',
    gujarati: 'માસિક પ્લાન',
    bengali: 'মাসিক প্ল্যান',
    punjabi: 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
    odia: 'ମାସିକ ପ୍ଲାନ୍',
    assamese: 'মাহিলি আঁচনি',
    konkani: 'म्हयन्याची येवजण',
    nepali: 'मासिक योजना',
    meitei: 'থাগী প্লান',
    mizo: 'Thla khat plan',
    kashmiri: 'ماہانہٕ پلان',
    ladakhi: 'ཟླ་རེའི་འཆར་གཞི།',
  );

  String get yearlyPlan => strings.localized(
    telugu: 'వార్షిక ప్లాన్',
    english: 'Yearly plan',
    hindi: 'वार्षिक योजना',
    tamil: 'வருடாந்திரத் திட்டம்',
    kannada: 'ವಾರ್ಷಿಕ ಯೋಜನೆ',
    malayalam: 'വാർഷിക പ്ലാൻ',
    marathi: 'वार्षिक योजना',
    gujarati: 'વાર્ષિક પ્લાન',
    bengali: 'বার্ষিক প্ল্যান',
    punjabi: 'ਸਾਲਾਨਾ ਪਲਾਨ',
    odia: 'ବାର୍ଷିକ ପ୍ଲାନ୍',
    assamese: 'বাৰ্ষিক আঁচনি',
    konkani: 'वर्साची येवजण',
    nepali: 'वार्षिक योजना',
    meitei: 'চহীগী প্লান',
    mizo: 'Kum khat plan',
    kashmiri: 'سالانہٕ پلان',
    ladakhi: 'ལོ་རེའི་འཆར་གཞི།',
  );

  String get introductoryPlan => strings.localized(
    telugu: 'ప్రారంభ ఆఫర్',
    english: 'Introductory offer',
    hindi: 'शुरुआती ऑफ़र',
    tamil: 'அறிமுகச் சலுகை',
    kannada: 'ಪರಿಚಯ ಕೊಡುಗೆ',
    malayalam: 'ആമുഖ ഓഫർ',
    marathi: 'प्रारंभिक ऑफर',
    gujarati: 'પ્રારંભિક ઑફર',
    bengali: 'প্রারম্ভিক অফার',
    punjabi: 'ਸ਼ੁਰੂਆਤੀ ਪੇਸ਼ਕਸ਼',
    odia: 'ପ୍ରାରମ୍ଭିକ ଅଫର୍',
    assamese: 'আৰম্ভণিৰ অফাৰ',
    konkani: 'सुरवेची ऑफर',
    nepali: 'प्रारम्भिक अफर',
    meitei: 'অহানবা ওফর',
    mizo: 'A tir offer',
    kashmiri: 'ابتدٲیی آفر',
    ladakhi: 'འགོ་བཙུགས་ཀྱི་ཕན་ཐོགས།',
  );

  String get title => strings.localized(
    telugu: 'కొనుగోలు ఇన్వాయిసులు',
    english: 'Purchase invoices',
    hindi: 'खरीद इनवॉइस',
    tamil: 'வாங்கிய விலைப்பட்டியல்கள்',
    kannada: 'ಖರೀದಿ ಇನ್‌ವಾಯ್ಸ್‌ಗಳು',
    malayalam: 'പർച്ചേസ് ഇൻവോയ്സുകൾ',
    marathi: 'खरेदी बीजक',
    gujarati: 'ખરીદી ઇનવોઇસ',
    bengali: 'ক্রয় ইনভয়েস',
    punjabi: 'ਖਰੀਦ ਇਨਵੌਇਸ',
    odia: 'କ୍ରୟ ଇନଭଏସ୍',
    assamese: 'ক্ৰয় ইনভয়েচ',
    konkani: 'खरेदी इनव्हॉईस',
    nepali: 'खरिद बीजक',
    meitei: 'লৈরবা ইনভোইস',
    mizo: 'Purchase invoices',
    kashmiri: 'خریٖدٲری ہٕنٛز اِنوائس',
    ladakhi: 'ཉོ་ཚོང་གི་ཐོ་ཡིག',
  );

  String get refresh => strings.localized(
    telugu: 'రిఫ్రెష్ చేయండి',
    english: 'Refresh',
    hindi: 'रिफ्रेश करें',
    tamil: 'புதுப்பி',
    kannada: 'ರಿಫ್ರೆಶ್ ಮಾಡಿ',
    malayalam: 'പുതുക്കുക',
    marathi: 'रिफ्रेश करा',
    gujarati: 'રીફ્રેશ કરો',
    bengali: 'রিফ্রেশ করুন',
    punjabi: 'ਤਾਜ਼ਾ ਕਰੋ',
    odia: 'ରିଫ୍ରେଶ୍ କରନ୍ତୁ',
    assamese: 'ৰিফ্ৰেছ কৰক',
    konkani: 'ताजे करात',
    nepali: 'रिफ्रेस गर्नुहोस्',
    meitei: 'অমুক হন্না শেমজিনবীয়ু',
    mizo: 'Tih thar rawh',
    kashmiri: 'ریفریش کٔرِو',
    ladakhi: 'གསར་བཟོ་བྱོས།',
  );

  String get tryAgain => strings.localized(
    telugu: 'మళ్ళీ ప్రయత్నించండి',
    english: 'Try again',
    hindi: 'पुनः प्रयास करें',
    tamil: 'மீண்டும் முயற்சிக்கவும்',
    kannada: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    malayalam: 'വീണ്ടും ശ്രമിക്കുക',
    marathi: 'पुन्हा प्रयत्न करा',
    gujarati: 'ફરી પ્રયાસ કરો',
    bengali: 'আবার চেষ্টা করুন',
    punjabi: 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
    odia: 'ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ',
    assamese: 'পুনৰ চেষ্টা কৰক',
    konkani: 'परत यत्न करात',
    nepali: 'पुनः प्रयास गर्नुहोस्',
    meitei: 'অমুক হন্না হোৎনবীয়ু',
    mizo: 'Han tum nawn leh rawh',
    kashmiri: 'دوبارٕ کٔرِو کوٗشِش',
    ladakhi: 'ཡང་བསྐྱར་འབད་བརྩོན་བྱོས།',
  );

  String get notice => strings.localized(
    telugu:
        'యాప్‌లోని కొనుగోళ్లకు Google Play అధికారిక వ్యాపారిగా వ్యవహరిస్తుంది. మీ ఖాతాలో నమోదైన ఆర్డర్ వివరాలు ఇక్కడ కనిపిస్తాయి.',
    english:
        'Google Play is the merchant of record for in-app purchases. These receipts show order details recorded on your account.',
    hindi:
        'ऐप के अंदर की गई खरीदारी के लिए Google Play आधिकारिक मर्चेंट है। ये रसीदें आपके खाते में दर्ज ऑर्डर का विवरण दिखाती हैं।',
    tamil:
        'பயன்பாட்டு வாங்குதல்களுக்கு Google Play அதிகாரப்பூர்வ வணிகராக செயல்படுகிறது. இந்தக் கட்டண ரசீதுகள் உங்கள் கணக்கில் பதிவான ஆர்டர் விவரங்களைக் காட்டுகின்றன.',
    kannada:
        'ಅಪ್ಲಿಕೇಶನ್‌ನಲ್ಲಿನ ಖರೀದಿಗಳಿಗೆ Google Play ಅಧಿಕೃತ ವ್ಯಾಪಾರಿಯಾಗಿದೆ. ಈ ರಶೀದಿಗಳು ನಿಮ್ಮ ಖಾತೆಯಲ್ಲಿ ದಾಖಲಾಗಿರುವ ಆದೇಶದ ವಿವರಗಳನ್ನು ತೋರಿಸುತ್ತವೆ.',
    malayalam:
        'ആപ്പിലെ വാങ്ങലുകൾക്ക് Google Play ആണ് ഔദ്യോഗിക വ്യാപാരി. ഈ രസീതുകൾ നിങ്ങളുടെ അക്കൗണ്ടിൽ രേഖപ്പെടുത്തിയ ഓർഡർ വിവരങ്ങളാണ് കാണിക്കുന്നത്.',
    marathi:
        'अ‍ॅपमधील खरेदीसाठी Google Play अधिकृत व्यापारी आहे. या पावत्या तुमच्या खात्यावर नोंदवलेल्या ऑर्डरचे तपशील दाखवतात.',
    gujarati:
        'ઍપમાં ખરીદી માટે Google Play સત્તાવાર મર્ચન્ટ તરીકે કામ કરે છે. આ રસીદો તમારા એકાઉન્ટમાં નોંધાયેલી ઑર્ડર વિગતો દર્શાવે છે.',
    bengali:
        'অ্যাপের কেনাকাটার জন্য Google Play অফিসিয়াল মার্চেন্ট হিসেবে কাজ করে। এই রসিদগুলি আপনার অ্যাকাউন্টে রেকর্ড করা অর্ডারের বিবরণ দেখায়।',
    punjabi:
        'ਐਪ ਅੰਦਰਲੀਆਂ ਖਰੀਦਾਂ ਲਈ Google Play ਅਧਿਕਾਰਤ ਵਪਾਰੀ ਹੈ। ਇਹ ਰਸੀਦਾਂ ਤੁਹਾਡੇ ਖਾਤੇ ਵਿੱਚ ਦਰਜ ਆਰਡਰ ਦੇ ਵੇਰਵੇ ਦਿਖਾਉਂਦੀਆਂ ਹਨ।',
    odia:
        'ଆପ୍ ମଧ୍ୟରେ କ୍ରୟ ପାଇଁ Google Play ଅଫିସିଆଲ୍ ବ୍ୟବସାୟୀ ଭାବରେ କାର୍ଯ୍ୟ କରେ। ଏହି ରସିଦଗୁଡ଼ିକ ଆପଣଙ୍କ ଖାତାରେ ଥିବା ଅର୍ଡର ବିବରଣୀ ପ୍ରଦର୍ଶନ କରେ।',
    assamese:
        'এপৰ ক্ৰয়ৰ বাবে Google Play আনুষ্ঠানিক ব্যৱসায়ী। এই ৰচিদসমূহে আপোনাৰ একাউণ্টত থকা অৰ্ডাৰৰ বিৱৰণ প্ৰদৰ্শন কৰে।',
    konkani:
        'ॲपांतल्या खरेदी खातीर Google Play अधिकारिक व्यापारी म्हणून काम करता. ह्यो पावत्यो तुमच्या खात्याचेर नोंद जाल्ले ऑर्डर तपशील दाखयतात.',
    nepali:
        'एप भित्रका खरिदहरूको लागि Google Play आधिकारिक व्यापारी हो। यी रसिदहरूले तपाईंको खातामा दर्ता भएका अर्डर विवरणहरू देखाउँछन्।',
    meitei:
        'এপ মনুংগী লৈবশিংগীদমক Google Play না ওফিসিএল ভেন্দোর ওইনা থবক তৌই। রসিদশিং অসিনা অদোমগী একাউন্ততা রেজিস্তর তৌরবা ওর্দর মরোলশিং উৎলি।',
    mizo:
        'App chhunga lei atan Google Play hi merchant a ni. Heng receipt hian i account-a order record te a entir a ni.',
    kashmiri:
        'ایپ کؠن خریٖدٲرین خٲطرٕ چھُ Google Play سَرکٲرؠ تاجر پٲٹھؠ کٲم کَران۔ یِم رسیٖد چھِ تُہٕندِس اَکاؤنٹس پؠٹھ دَرٕج آرڈر تفصیٖل ہٲوان۔',
    ladakhi:
        'མཉེན་ཆས་ནང་གི་ཉོ་ཚོང་ལ་ Google Play གཞུང་འབྲེལ་ཚོང་པ་ཡིན། འཛིན་ཡིག་འདི་དག་གིས་ཁྱེད་ཀྱི་ཁ་ཐོའི་ནང་བཀོད་པའི་བཀའ་རྒྱའི་ཞིབ་ཕྲ་སྟོན་ནོ།',
  );

  String get emptyTitle => strings.localized(
    telugu: 'ఇన్వాయిసులు కనుగొనబడలేదు',
    english: 'No invoices found',
    hindi: 'कोई इनवॉइस नहीं मिला',
    tamil: 'விலைப்பட்டியல்கள் எதுவும் காணப்படவில்லை',
    kannada: 'ಯಾವುದೇ ಇನ್‌ವಾಯ್ಸ್‌ಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
    malayalam: 'ഇൻവോയ്സുകളൊന്നും കണ്ടെത്തിയില്ല',
    marathi: 'कोणतेही बीजक आढळले नाही',
    gujarati: 'કોઈ ઇનવોઇસ મળ્યા નથી',
    bengali: 'কোনো ইনভয়েস পাওয়া যায়নি',
    punjabi: 'ਕੋਈ ਇਨਵੌਇਸ ਨਹੀਂ ਮਿਲਿਆ',
    odia: 'କୌଣସି ଇନଭଏସ୍ ମିଳିଲା ନାହିଁ',
    assamese: 'কোনো ইনভয়েচ পোৱা নগ’ল',
    konkani: 'खंयचेंय इनव्हॉईस मेळ्ळें ना',
    nepali: 'कुनै बीजक फेला परेन',
    meitei: 'ইনভোইস অমত্তা ফংদে',
    mizo: 'Invoice hmuh a ni lo',
    kashmiri: 'کانٛہہ اِنوائس آو نہٕ لبنہٕ',
    ladakhi: 'ཐོ་ཡིག་གང་ཡང་མ་རྙེད།',
  );

  String get emptyMessage => strings.localized(
    telugu: 'మీ ఖాతాలో పూర్తయిన లేదా ధృవీకరించబడిన కొనుగోలు రికార్డులు కనిపించలేదు.',
    english: 'No completed or verified purchase records were found for your account.',
    hindi: 'आपके खाते के लिए कोई पूर्ण या सत्यापित खरीदारी रिकॉर्ड नहीं मिला।',
    tamil: 'உங்கள் கணக்கில் நிறைவுற்ற அல்லது சரிபார்க்கப்பட்ட வாங்குதல் பதிவுகள் எதுவும் இல்லை.',
    kannada: 'ನಿಮ್ಮ ಖಾತೆಗೆ ಪೂರ್ಣಗೊಂಡ ಅಥವಾ ಪರಿಶೀಲಿಸಿದ ಯಾವುದೇ ಖರೀದಿ ದಾಖಲೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ.',
    malayalam: 'നിങ്ങളുടെ അക്കൗണ്ടിൽ പൂർത്തിയായതോ സ്ഥിരീകരിച്ചതോ ആയ വാങ്ങൽ രേഖകളൊന്നും കണ്ടെത്തിയില്ല.',
    marathi: 'तुमच्या खात्यासाठी कोणतेही पूर्ण किंवा पडताळलेले खरेदी रेकॉर्ड आढळले नाही.',
    gujarati: 'તમારા એકાઉન્ટ માટે કોઈ પૂર્ણ અથવા ચકાસાયેલ ખરીદી રેકોર્ડ મળ્યા નથી.',
    bengali: 'আপনার অ্যাকাউন্টের জন্য কোনো সম্পন্ন বা যাচাইকৃত ক্রয়ের রেকর্ড পাওয়া যায়নি।',
    punjabi: 'ਤੁਹਾਡੇ ਖਾਤੇ ਲਈ ਕੋਈ ਪੂਰਾ ਜਾਂ ਪ੍ਰਮਾਣਿਤ ਖਰੀਦ ਰਿਕਾਰਡ ਨਹੀਂ ਮਿਲਿਆ।',
    odia: 'ଆପଣଙ୍କ ଖାତା ପାଇଁ କୌଣସି ସମ୍ପୂର୍ଣ୍ଣ କିମ୍ବା ଯାଞ୍ଚ ହୋଇଥିବା କ୍ରୟ ରେକର୍ଡ ମିଳିଲା ନାହିଁ।',
    assamese: 'আপোনাৰ একাউণ্টৰ বাবে কোনো সম্পূৰ্ণ বা প্ৰমাণিত ক্ৰয়ৰ ৰেকৰ্ড পোৱা নগ’ল।',
    konkani: 'तुमच्या खात्या खातीर खंयचीच पुराय जाल्ली वा तपासणी केल्ली खरेदी नोंद मेळ्ळी ना.',
    nepali: 'तपाईंको खाताको लागि कुनै पूरा वा प्रमाणित खरिद अभिलेख फेला परेन।',
    meitei: 'অদোমগী একাউন্তগী লোইশিনরবা নত্রগা ভেরিফাই তৌরবা লৈবগী রেকোর্দ অমত্তা ফংদে।',
    mizo: 'I account atan thil lei zawh tawh emaw verify tawh record hmuh a ni lo.',
    kashmiri: 'تُہٕندِس اَکاؤنٹس خٲطرٕ آو نہٕ کانٛہہ مُکَمَل یا تصدیٖق شُدٕ خریٖدٲری ریکارڈ لبنہٕ۔',
    ladakhi: 'ཁྱེད་ཀྱི་ཁ་ཐོའི་ནང་ཚར་བའམ་དཔྱད་ཞིབ་ཟིན་པའི་ཉོ་ཚོང་གི་ཐོ་མེད།',
  );

  String get loadFailedTitle => strings.localized(
    telugu: 'ఇన్వాయిసులను లోడ్ చేయడం సాధ్యం కాలేదు',
    english: 'Could not load invoices',
    hindi: 'इनवॉइस लोड नहीं किए जा सके',
    tamil: 'விலைப்பட்டியல்களை ஏற்ற முடியவில்லை',
    kannada: 'ಇನ್‌ವಾಯ್ಸ್‌ಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
    malayalam: 'ഇൻവോയ്സുകൾ ലോഡ് ചെയ്യാനായില്ല',
    marathi: 'बीजक लोड करता आले नाही',
    gujarati: 'ઇનવોઇસ લોડ કરી શકાયા નથી',
    bengali: 'ইনভয়েস লোড করা যায়নি',
    punjabi: 'ਇਨਵੌਇਸ ਲੋਡ ਨਹੀਂ ਕੀਤੇ ਜਾ ਸਕੇ',
    odia: 'ଇନଭଏସ୍ ଲୋଡ୍ କରିବା ସମ୍ଭବ ହେଲା ନାହିଁ',
    assamese: 'ইনভয়েচ লোড কৰিব পৰা নগ’ল',
    konkani: 'इनव्हॉईस लोड करूंक शकले ना',
    nepali: 'बीजकहरू लोड गर्न सकिएन',
    meitei: 'ইনভোইসশিং লোদ তৌবা ঙমদে',
    mizo: 'Invoice a load thei lo',
    kashmiri: 'اِنوائس ہؠکہِ نہٕ لوڈ گٔژھِتھ',
    ladakhi: 'ཐོ་ཡིག་འཇུག་མ་ཐུབ།',
  );

  String get loadFailedMessage => strings.localized(
    telugu: 'మీ కొనుగోలు రికార్డులను పొందే సమయంలో సమస్య ఏర్పడింది. దయచేసి మళ్ళీ ప్రయత్నించండి.',
    english: 'There was a problem retrieving your purchase records. Please try again.',
    hindi: 'आपके खरीदारी रिकॉर्ड प्राप्त करने में समस्या आई। कृपया पुनः प्रयास करें।',
    tamil: 'உங்கள் வாங்குதல் பதிவுகளைப் பெறுவதில் சிக்கல் ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ನಿಮ್ಮ ಖರೀದಿ ದಾಖಲೆಗಳನ್ನು ಪಡೆಯುವಾಗ ಸಮಸ್ಯೆಯಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'നിങ്ങളുടെ വാങ്ങൽ രേഖകൾ വീണ്ടെടുക്കുന്നതിൽ ഒരു പ്രശ്നമുണ്ടായി. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
    marathi: 'तुमचे खरेदी रेकॉर्ड आणताना समस्या आली. कृपया पुन्हा प्रयत्न करा.',
    gujarati: 'તમારા ખરીદી રેકોર્ડ મેળવવામાં સમસ્યા આવી. કૃપા કરીને ફરી પ્રયાસ કરો.',
    bengali: 'আপনার ক্রয়ের রেকর্ড পুনরুদ্ধার করতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
    punjabi: 'ਤੁਹਾਡੇ ਖਰੀਦ ਰਿਕਾਰਡ ਪ੍ਰਾਪਤ ਕਰਨ ਵਿੱਚ ਸਮੱਸਿਆ ਆਈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    odia: 'ଆପଣଙ୍କ କ୍ରୟ ରେକର୍ଡ ପାଇବାରେ ସମସ୍ୟା ଦେଖାଦେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
    assamese: 'আপোনাৰ ক্ৰয়ৰ ৰেকৰ্ড উদ্ধাৰ কৰাত এটা সমস্যা হৈছিল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
    konkani: 'तुमच्यो खरेदी नोंदी मेळोवपांत अडचण आयली. उपकार करून परत यत्न करात.',
    nepali: 'तपाईंको खरिद अभिलेखहरू प्राप्त गर्दा समस्या आयो। कृपया पुनः प्रयास गर्नुहोस्।',
    meitei: 'অদোমগী লৈবগী রেকোর্দ পুরকপদা অৱাবা অমা থোকখি। চGoObjectবা তৌবীদুনা অমুক হন্না হোৎনবীয়ু।',
    mizo: 'I thil lei record lak chhuah dawnin buaina a awm. Khawngaihin han tum nawn leh rawh.',
    kashmiri: 'تُہٕنٛز خریٖدٲری ریکارڈ حٲصِل کَرنَس مَنٛز آیہِ کانٛہہ رُکاوَٹ۔ مہر Kerni کٔرِو دوبارٕ کوٗشِش۔',
    ladakhi: 'ཁྱེད་ཀྱི་ཉོ་ཚོང་གི་ཐོ་ལེན་པའི་སྐབས་སུ་དཀའ་ངལ་བྱུང་། ཡང་བསྐྱར་འབད་བརྩོན་བྱོས།',
  );

  String get purchaseDate => strings.localized(
    telugu: 'కొనుగోలు తేదీ',
    english: 'Purchase date',
    hindi: 'खरीद की तारीख',
    tamil: 'வாங்கிய தேதி',
    kannada: 'ಖರೀದಿಸಿದ ದಿನಾಂಕ',
    malayalam: 'വാങ്ങിയ തീയതി',
    marathi: 'खरेदी तारीख',
    gujarati: 'ખરીદી તારીખ',
    bengali: 'ক্রয়ের তারিখ',
    punjabi: 'ਖਰੀਦ ਦੀ ਮਿਤੀ',
    odia: 'କ୍ରୟ ତାରିଖ',
    assamese: 'ক্ৰয়ৰ তাৰিখ',
    konkani: 'खरेदी तारीख',
    nepali: 'खरिद मिति',
    meitei: 'লৈখিবা তাং',
    mizo: 'Lei ni',
    kashmiri: 'خریٖدٲری ہُنٛد دوہ',
    ladakhi: 'ཉོ་ཚེས།',
  );

  String get validUntil => strings.localized(
    telugu: 'వ్యాలిడిటీ ముగింపు',
    english: 'Valid until',
    hindi: 'वैधता समाप्ति',
    tamil: 'செல்லுபடியாகும் வரை',
    kannada: 'ಮಾನ್ಯತೆಯ ಅವಧಿ',
    malayalam: 'സാധുതയുള്ളത് വരെ',
    marathi: 'पर्यंत वैध',
    gujarati: 'સુધી માન્ય',
    bengali: 'মেয়াদ শেষ',
    punjabi: 'ਤੱਕ ਵੈਧ',
    odia: 'ପର୍ଯ୍ୟନ୍ତ ବୈଧ',
    assamese: 'লৈকে বৈধ',
    konkani: 'पर्यंत वैध',
    nepali: 'सम्म मान्य',
    meitei: 'চৎনবা মতম লোইবা',
    mizo: 'A nung tawk',
    kashmiri: 'تام جائز',
    ladakhi: 'ནུས་ཡོད་དུས་ཚོད།',
  );

  String get orderId => strings.localized(
    telugu: 'ఆర్డర్ ID',
    english: 'Order ID',
    hindi: 'ऑर्डर ID',
    tamil: 'ஆர்டர் ஐடி',
    kannada: 'ಆರ್ಡರ್ ID',
    malayalam: 'ഓർഡർ ഐഡി',
    marathi: 'ऑर्डर आयडी',
    gujarati: 'ઑર્ડર આઈડી',
    bengali: 'অর্ডার আইডি',
    punjabi: 'ਆਰਡਰ ID',
    odia: 'ଅର୍ଡର ID',
    assamese: 'অৰ্ডাৰ ID',
    konkani: 'ऑर्डर आयडी',
    nepali: 'अर्डर ID',
    meitei: 'ওর্দর ID',
    mizo: 'Order ID',
    kashmiri: 'آرڈر ID',
    ladakhi: 'བཀའ་རྒྱའི་ཨང་གྲངས།',
  );

  String get platform => strings.localized(
    telugu: 'ప్లాట్‌ఫారమ్',
    english: 'Platform',
    hindi: 'प्लेटफ़ॉर्म',
    tamil: 'தளம்',
    kannada: 'ಪ್ಲಾಟ್‌ಫಾರ್ಮ್',
    malayalam: 'പ്ലാറ്റ്ഫോം',
    marathi: 'प्लॅटफॉर्म',
    gujarati: 'પ્લેટફોર્મ',
    bengali: 'প্ল্যাটফর্ম',
    punjabi: 'ਪਲੇਟਫਾਰਮ',
    odia: 'ପ୍ଲାଟଫର୍ମ',
    assamese: 'প্লেটফৰ্ম',
    konkani: 'प्लॅटफॉर्म',
    nepali: 'प्लेटफर्म',
    meitei: 'প্লেতফোর্ম',
    mizo: 'Platform',
    kashmiri: 'پلیٹ فارم',
    ladakhi: 'སྡིངས་ཆ།',
  );

  String get googlePlay => 'Google Play';

  String get notAvailable => strings.localized(
    telugu: 'అందుబాటులో లేదు',
    english: 'Not available',
    hindi: 'उपलब्ध नहीं',
    tamil: 'கிடைக்கவில்லை',
    kannada: 'ಲಭ್ಯವಿಲ್ಲ',
    malayalam: 'ലഭ്യമല്ല',
    marathi: 'उपलब्ध नाही',
    gujarati: 'ઉપલબ્ધ નથી',
    bengali: 'পাওয়া যাচ্ছে না',
    punjabi: 'ਉਪਲਬਧ ਨਹੀਂ',
    odia: 'ଉପଲବ୍ଧ ନାହିଁ',
    assamese: 'উপলব্ধ নহয়',
    konkani: 'उपलब्ध ना',
    nepali: 'उपलब्ध छैन',
    meitei: 'ফংদে',
    mizo: 'A awm lo',
    kashmiri: 'دستیاب چھُ نہٕ',
    ladakhi: 'མེད།',
  );

  String statusText(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'active') {
      return strings.localized(
        telugu: 'యాక్టివ్',
        english: 'Active',
        hindi: 'सक्रिय',
        tamil: 'செயலில்',
        kannada: 'ಸಕ್ರಿಯ',
        malayalam: 'സജീവം',
        marathi: 'सक्रिय',
        gujarati: 'સક્રિય',
        bengali: 'সক্রিয়',
        punjabi: 'ਸਰਗਰਮ',
        odia: 'ସକ୍ରିୟ',
        assamese: 'সক্ৰিয়',
        konkani: 'सक्रिय',
        nepali: 'सक्रिय',
        meitei: 'একতিভ',
        mizo: 'Active',
        kashmiri: 'متحرک',
        ladakhi: 'ཤུགས་ཡོད།',
      );
    }
    if (normalized == 'verified') {
      return strings.localized(
        telugu: 'ధృవీకరించబడింది',
        english: 'Verified',
        hindi: 'सत्यापित',
        tamil: 'சரிபார்க்கப்பட்டது',
        kannada: 'ಪರಿಶೀಲಿಸಲಾಗಿದೆ',
        malayalam: 'സ്ഥിരീകരിച്ചു',
        marathi: 'पडताळणी झाली',
        gujarati: 'ચકાસાયેલ',
        bengali: 'যাচাইকৃত',
        punjabi: 'ਪ੍ਰਮਾਣਿਤ',
        odia: 'ଯାଞ୍ଚ ହୋଇଛି',
        assamese: 'প্ৰমাণিত',
        konkani: 'तपासणी जाल्ली',
        nepali: 'प्रमाणित',
        meitei: 'ভেরিফাই তৌরে',
        mizo: 'Verified',
        kashmiri: 'تصدیٖق شُدٕ',
        ladakhi: 'དཔྱད་ཞིབ་ཟིན་པ།',
      );
    }
    return raw;
  }
}