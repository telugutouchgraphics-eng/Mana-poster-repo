import 'package:flutter/material.dart';

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: invoices.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _InvoiceNotice(copy: copy);
                  }
                  return _InvoiceCard(invoice: invoices[index - 1], copy: copy);
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copy.notice,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.copy});

  final PurchaseInvoice invoice;
  final _PurchaseInvoicesCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayDate = invoice.displayDate;
    final expiryAt = invoice.expiryAt;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      invoice.planName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.priceLabel,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: copy.statusText(invoice.statusLabel)),
            ],
          ),
          const SizedBox(height: 16),
          _InvoiceRow(
            label: copy.purchaseDate,
            value: displayDate == null
                ? copy.notAvailable
                : _formatDate(context, displayDate),
          ),
          if (expiryAt != null)
            _InvoiceRow(
              label: copy.validUntil,
              value: _formatDate(context, expiryAt),
            ),
          _InvoiceRow(
            label: copy.orderId,
            value: invoice.orderId ?? copy.notAvailable,
          ),
          _InvoiceRow(
            label: copy.platform,
            value: invoice.platform?.isNotEmpty == true
                ? invoice.platform!
                : copy.googlePlay,
          ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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

  String get title => strings.localized(
    telugu: 'కొనుగోలు ఇన్వాయిసులు',
    english: 'Purchase invoices',
    hindi: 'खरीद इनवॉइस',
    tamil: 'வாங்கிய ரசீதுகள்',
    kannada: 'ಖರೀದಿ ಇನ್ವಾಯ್ಸ್',
    malayalam: 'വാങ്ങൽ ഇൻവോയിസുകൾ',
  );

  String get refresh => strings.localized(
    telugu: 'రిఫ్రెష్',
    english: 'Refresh',
    hindi: 'रीफ्रेश',
    tamil: 'புதுப்பிக்கவும்',
    kannada: 'ರಿಫ್ರೆಶ್',
    malayalam: 'പുതുക്കുക',
  );

  String get tryAgain => strings.localized(
    telugu: 'మళ్లీ ప్రయత్నించండి',
    english: 'Try again',
    hindi: 'फिर कोशिश करें',
    tamil: 'மீண்டும் முயற்சிக்கவும்',
    kannada: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    malayalam: 'വീണ്ടും ശ്രമിക്കുക',
  );

  String get notice => strings.localized(
    telugu:
        'ఇక్కడ మీ Mana Poster కొనుగోలు వివరాలు మాత్రమే కనిపిస్తాయి. అధికారిక చెల్లింపు రసీదు Google Play లో ఉంటుంది.',
    english:
        'This shows your Mana Poster purchase details only. The official payment receipt is managed by Google Play.',
    hindi:
        'यहां केवल आपके Mana Poster खरीद विवरण दिखते हैं. आधिकारिक भुगतान रसीद Google Play में रहती है.',
    tamil:
        'இங்கு உங்கள் Mana Poster வாங்கிய விவரங்கள் மட்டும் காட்டப்படும். அதிகாரப்பூர்வ கட்டண ரசீது Google Play-ல் இருக்கும்.',
    kannada:
        'ಇಲ್ಲಿ ನಿಮ್ಮ Mana Poster ಖರೀದಿ ವಿವರಗಳು ಮಾತ್ರ ಕಾಣುತ್ತವೆ. ಅಧಿಕೃತ ಪಾವತಿ ರಸೀದಿ Google Play ನಲ್ಲಿ ಇರುತ್ತದೆ.',
    malayalam:
        'ഇവിടെ നിങ്ങളുടെ Mana Poster വാങ്ങൽ വിവരങ്ങൾ മാത്രം കാണിക്കും. ഔദ്യോഗിക പേയ്മെന്റ് രസീത് Google Play-ലാണ്.',
  );

  String get emptyTitle => strings.localized(
    telugu: 'ఇన్వాయిసులు లేవు',
    english: 'No invoices found',
    hindi: 'कोई इनवॉइस नहीं मिला',
    tamil: 'ரசீதுகள் இல்லை',
    kannada: 'ಇನ್ವಾಯ್ಸ್ ಸಿಗಲಿಲ್ಲ',
    malayalam: 'ഇൻവോയിസുകൾ ഇല്ല',
  );

  String get emptyMessage => strings.localized(
    telugu: 'ఈ అకౌంట్‌లో కొనుగోలు వివరాలు ఇంకా కనిపించడం లేదు.',
    english: 'No purchase details are available for this account yet.',
    hindi: 'इस खाते के लिए अभी कोई खरीद विवरण उपलब्ध नहीं है.',
    tamil: 'இந்த கணக்கிற்கு வாங்கிய விவரங்கள் இன்னும் இல்லை.',
    kannada: 'ಈ ಖಾತೆಗೆ ಖರೀದಿ ವಿವರಗಳು ಇನ್ನೂ ಲಭ್ಯವಿಲ್ಲ.',
    malayalam: 'ഈ അക്കൗണ്ടിന് വാങ്ങൽ വിവരങ്ങൾ ഇതുവരെ ലഭ്യമല്ല.',
  );

  String get loadFailedTitle => strings.localized(
    telugu: 'లోడ్ కాలేదు',
    english: 'Could not load',
    hindi: 'लोड नहीं हुआ',
    tamil: 'லோடு ஆகவில்லை',
    kannada: 'ಲೋಡ್ ಆಗಲಿಲ್ಲ',
    malayalam: 'ലോഡ് ചെയ്യാനായില്ല',
  );

  String get loadFailedMessage => strings.localized(
    telugu: 'కొనుగోలు వివరాలు తెచ్చుకోలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
    english: 'Purchase details could not be loaded. Please try again.',
    hindi: 'खरीद विवरण लोड नहीं हो सके. फिर कोशिश करें.',
    tamil: 'வாங்கிய விவரங்களை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ಖರೀದಿ ವಿವರಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'വാങ്ങൽ വിവരങ്ങൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
  );

  String get purchaseDate =>
      strings.localized(telugu: 'కొనుగోలు తేదీ', english: 'Purchase date');

  String get validUntil =>
      strings.localized(telugu: 'చెల్లుబాటు', english: 'Valid until');

  String get orderId =>
      strings.localized(telugu: 'ఆర్డర్ ID', english: 'Order ID');

  String get platform =>
      strings.localized(telugu: 'ప్లాట్‌ఫారమ్', english: 'Platform');

  String get googlePlay => 'Google Play';

  String get notAvailable =>
      strings.localized(telugu: 'లభ్యం లేదు', english: 'Not available');

  String statusText(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('active') ||
        normalized.contains('purchased') ||
        normalized.contains('verified')) {
      return strings.localized(telugu: 'యాక్టివ్', english: 'Active');
    }
    if (normalized.contains('expired') || normalized.contains('cancel')) {
      return strings.localized(telugu: 'ముగిసింది', english: 'Expired');
    }
    return raw.trim().isEmpty
        ? strings.localized(telugu: 'సరే', english: 'OK')
        : raw;
  }
}
