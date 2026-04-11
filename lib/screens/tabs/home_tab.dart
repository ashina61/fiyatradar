import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';
import '../admin_screen.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products.take(6).toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: FRInsets.pageTopBar,
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanDark]),
                  borderRadius: FRRadii.pill,
                ),
                alignment: Alignment.center,
                child: const Text('FK', style: TextStyle(color: ProtoColors.bgPrimary, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Merhaba,', style: TextStyle(color: ProtoColors.textSubtle, fontSize: 10)),
                  Text('Adem', style: TextStyle(color: ProtoColors.textPrimary, fontWeight: FontWeight.w700)),
                ]),
              ),
              NotificationButton(
                badge: state.unreadNotificationCount,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: ProtoColors.tan, borderRadius: FRRadii.pill),
                  child: const Icon(Icons.settings, color: ProtoColors.bgPrimary),
                ),
              )
            ]),
          ),
          ProtoSearchField(
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView(
              padding: FRInsets.horizontalPage,
              scrollDirection: Axis.horizontal,
              children: const [
                _Chip('Tümü', true),
                _Chip('Elektronik', false),
                _Chip('Gıda', false),
                _Chip('Bakım', false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: FRInsets.heroBottom,
              children: [
                Container(
                  margin: FRInsets.horizontalPage,
                  padding: FRInsets.cardL,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ProtoColors.flashStart, ProtoColors.flashEnd]),
                    borderRadius: FRRadii.xl,
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('⚡ FLASH DEAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Sony WH-1000XM5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(height: 14),
                const ProtoSectionHeader('Senin İçin Öneriler'),
                const SizedBox(height: 10),
                const Padding(
                  padding: FRInsets.horizontalPage,
                  child: ProtoCard(child: Row(children: [
                    Text('🎧', style: TextStyle(fontSize: 24)), SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sony WH-1000XM5', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Son aradığın üründe düşüş', style: TextStyle(fontSize: 11, color: ProtoColors.textSubtle)),
                    ])),
                    Text('₺1.299', style: TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w700)),
                  ])),
                ),
                const SizedBox(height: 14),
                const ProtoSectionHeader('Canlı Fiyatlar'),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: FRInsets.horizontalPage,
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                      child: Container(
                        decoration: protoSurface(),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [ProtoColors.surfaceAlt, ProtoColors.surfaceElevated]),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(ProtoRadius.xl)),
                              ),
                              alignment: Alignment.center,
                              child: Text(p.emoji, style: const TextStyle(fontSize: 38)),
                            ),
                          ),
                          Padding(
                            padding: FRInsets.card10,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('₺${(p.lowestPrice ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w800)),
                            ]),
                          )
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.active);
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: FRInsets.rightGapS,
      padding: FRInsets.horizontalM,
      decoration: BoxDecoration(
        color: active ? ProtoColors.tan : ProtoColors.surface,
        borderRadius: FRRadii.pill,
        border: Border.all(color: active ? ProtoColors.tan : ProtoColors.border),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 12, color: active ? ProtoColors.bgPrimary : ProtoColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}
