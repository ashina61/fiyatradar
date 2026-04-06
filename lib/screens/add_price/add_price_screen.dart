// lib/screens/add_price/add_price_screen.dart
// GREENFIELD v2 — "The Quick Submit"
// Rejected from the previous iteration: 3-step PageView wizard, mission framing,
// platform pill grid, per-step motivational copy.
// UX goal: log a price in under 15 seconds. ONE single screen, number is the hero,
// custom keypad replaces soft keyboard for the price field.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/add_price_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/fr_ink.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _productCtrl = TextEditingController();
  bool _submitting = false;
  int _stage = 0; // 0 product, 1 price+store

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(addPriceProvider.notifier).initializeForProduct(widget.initialProductId!);
        final s = ref.read(addPriceProvider);
        if (s.selectedProductId != null) {
          _productCtrl.text = s.productName;
          setState(() => _stage = 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final uid = ref.read(authUidProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapın.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      HapticFeedback.mediumImpact();
      await ref.read(addPriceProvider.notifier).submitPrice(userId: uid);
      if (!mounted) return;
      _productCtrl.clear();
      setState(() => _stage = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teşekkürler — fiyat kaydedildi.')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addPriceProvider);

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onClose: () => Navigator.of(context).maybePop(),
              stage: _stage,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _stage == 0
                    ? _StageProduct(
                        key: const ValueKey('product'),
                        state: s,
                        ctrl: _productCtrl,
                        onPicked: () => setState(() => _stage = 1),
                      )
                    : _StagePriceStore(
                        key: const ValueKey('price'),
                        state: s,
                        onEditProduct: () {
                          setState(() => _stage = 0);
                          _productCtrl.text = s.productName;
                        },
                      ),
              ),
            ),
            if (_stage == 1) _SubmitBar(enabled: _canSubmit(s) && !_submitting, loading: _submitting, onTap: _submit),
          ],
        ),
      ),
    );
  }

  bool _canSubmit(AddPriceState s) {
    final p = double.tryParse(s.price.replaceAll(',', '.')) ?? 0;
    return p > 0 && s.selectedProductId != null && s.selectedStoreId != null;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.stage});
  final VoidCallback onClose;
  final int stage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 14, FRInk.gutter, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 24, color: FRInk.ink),
          ),
          const Spacer(),
          Text(stage == 0 ? 'ÜRÜN' : 'FİYAT', style: FRType.micro),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Stage 1: product picker ──────────────────────────────────────────────────
class _StageProduct extends ConsumerWidget {
  const _StageProduct({super.key, required this.state, required this.ctrl, required this.onPicked});
  final AddPriceState state;
  final TextEditingController ctrl;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 0),
          child: Text('Hangi ürünün\nfiyatını\ngirmek istersin?', style: FRType.title),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: TextField(
            controller: ctrl,
            autofocus: true,
            cursorColor: FRInk.ink,
            onChanged: (v) => ref.read(addPriceProvider.notifier).onProductInputChanged(v),
            style: FRType.body.copyWith(fontSize: 20, color: FRInk.ink, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: UnderlineInputBorder(borderSide: BorderSide(color: FRInk.hairline)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: FRInk.hairline)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: FRInk.ink, width: 1.4)),
              hintText: 'ürün adı yaz…',
              hintStyle: TextStyle(color: FRInk.inkFaint, fontFamily: FRType.family, fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: state.productSuggestions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(FRInk.gutter),
                  child: Text(
                    state.productName.trim().length < 2
                        ? 'En az 2 harf yaz, katalogdan öneri gelsin.'
                        : 'Eşleşme bulunamadı.',
                    style: FRType.body,
                  ),
                )
              : ListView.separated(
                  itemCount: state.productSuggestions.length,
                  separatorBuilder: (_, __) => const FRHairline(indent: FRInk.gutter),
                  itemBuilder: (_, i) {
                    final p = state.productSuggestions[i];
                    return InkWell(
                      onTap: () {
                        ref.read(addPriceProvider.notifier).selectProductSuggestion(p);
                        ctrl.text = p.name;
                        onPicked();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (p.brand.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(p.brand, style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13)),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, color: FRInk.ink, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Stage 2: price (keypad) + store picker ──────────────────────────────────
class _StagePriceStore extends ConsumerWidget {
  const _StagePriceStore({super.key, required this.state, required this.onEditProduct});
  final AddPriceState state;
  final VoidCallback onEditProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(addPriceProvider.notifier);
    final price = state.price;
    final display = price.isEmpty ? '0' : price;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected product row
          Padding(
            padding: const EdgeInsets.fromLTRB(FRInk.gutter, 10, FRInk.gutter, 0),
            child: InkWell(
              onTap: onEditProduct,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ÜRÜN', style: FRType.micro),
                        const SizedBox(height: 4),
                        Text(state.productName, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Text('değiştir', style: TextStyle(
                    fontFamily: FRType.family, fontSize: 13, fontWeight: FontWeight.w600,
                    color: FRInk.saffron, decoration: TextDecoration.underline,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const FRHairline(),
          // Big price
          Padding(
            padding: const EdgeInsets.fromLTRB(FRInk.gutter, 28, FRInk.gutter, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  display,
                  style: FRType.display.copyWith(fontSize: 72, letterSpacing: -2.4),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text('₺', style: TextStyle(
                    fontFamily: FRType.family, fontSize: 28, fontWeight: FontWeight.w300, color: FRInk.inkMute,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: FRInk.gutter),
            child: Text('raf fiyatı — indirim hariç', style: FRType.body),
          ),
          const SizedBox(height: 24),
          _Keypad(
            onDigit: (d) => notifier.setPrice(_append(price, d)),
            onDot: () => notifier.setPrice(_appendDot(price)),
            onBack: () => notifier.setPrice(price.isEmpty ? '' : price.substring(0, price.length - 1)),
          ),
          const SizedBox(height: 24),
          const FRHairline(),
          const Padding(
            padding: EdgeInsets.fromLTRB(FRInk.gutter, 18, FRInk.gutter, 10),
            child: Text('MARKET', style: FRType.micro),
          ),
          _StorePicker(state: state, notifier: notifier),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  String _append(String cur, String d) {
    if (cur == '0') return d;
    if (cur.length >= 8) return cur;
    return cur + d;
  }
  String _appendDot(String cur) {
    if (cur.contains(',')) return cur;
    return (cur.isEmpty ? '0' : cur) + ',';
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onDot, required this.onBack});
  final ValueChanged<String> onDigit;
  final VoidCallback onDot;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      [',','0','⌫'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter / 2),
      child: Column(
        children: [
          for (final r in rows)
            Row(
              children: [
                for (final k in r)
                  Expanded(
                    child: _KeyButton(
                      label: k,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (k == '⌫') {
                          onBack();
                        } else if (k == ',') {
                          onDot();
                        } else {
                          onDigit(k);
                        }
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: FRType.family,
            fontSize: label == '⌫' ? 22 : 26,
            fontWeight: FontWeight.w500,
            color: FRInk.ink,
          ),
        ),
      ),
    );
  }
}

class _StorePicker extends StatelessWidget {
  const _StorePicker({required this.state, required this.notifier});
  final AddPriceState state;
  final AddPriceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final stores = [...state.nearbyStores, ...state.onlineStores].take(12).toList();
    if (state.isStoresLoading) {
      return const Padding(
        padding: EdgeInsets.all(FRInk.gutter),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.ink)),
      );
    }
    if (stores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: FRInk.gutter),
        child: Text('Market bulunamadı.', style: FRType.body),
      );
    }
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = stores[i];
          final selected = state.selectedStoreId == s.id;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setSelectedStore(s);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? FRInk.ink : FRInk.paperDeep,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                s.name,
                style: TextStyle(
                  fontFamily: FRType.family,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? FRInk.paper : FRInk.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.enabled, required this.loading, required this.onTap});
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 10, FRInk.gutter, 18),
      child: SizedBox(
        height: 58,
        width: double.infinity,
        child: Material(
          color: enabled ? FRInk.ink : FRInk.inkFaint,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.paper),
                    )
                  : const Text(
                      'Fiyatı bildir',
                      style: TextStyle(
                        fontFamily: FRType.family,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: FRInk.paper,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
