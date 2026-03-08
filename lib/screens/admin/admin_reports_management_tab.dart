import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart'; // Rapor provider'ının olduğu yol
import '../../utils/theme.dart';
import 'report_detail_screen.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); 
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pWarning = Color(0xFFFF9500);
const Color pSuccess = Color(0xFF34C759);
const Color pBorder = Color(0x1F6A442A);

class AdminReportsManagementTab extends ConsumerStatefulWidget {
  const AdminReportsManagementTab({super.key});

  @override
  ConsumerState<AdminReportsManagementTab> createState() => _AdminReportsManagementTabState();
}

class _AdminReportsManagementTabState extends ConsumerState<AdminReportsManagementTab> {
  int _selectedFilterIndex = 0; // 0: Tümü, 1: Bekleyen, 2: Çözüldü, 3: Reddedildi
  final List<String> _filters = ['Tümü', 'Bekleyen', 'Çözüldü', 'Reddedildi'];
  final List<String> _statusKeys = ['all', 'pending', 'resolved', 'rejected'];

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);

    return Container(
      color: pBgApp,
      child: Column(
        children: [
          // 💥 1. LÜKS SEGMENTED FİLTRE 💥
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: pStudio,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: pBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (index) => _buildFilterBtn(index)),
                ),
              ),
            ),
          ),

          // 💥 2. RAPOR LİSTESİ 💥
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
              error: (_, __) => const Center(child: Text('Raporlar yüklenemedi')),
              data: (reports) {
                final filteredReports = _statusKeys[_selectedFilterIndex] == 'all'
                    ? reports
                    : reports.where((r) => r['status'] == _statusKeys[_selectedFilterIndex]).toList();

                if (filteredReports.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _PremiumReportCard(
                      report: report,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? pSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected ? const [BoxShadow(color: Color(0x146A442A), blurRadius: 8)] : [],
        ),
        child: Text(
          _filters[index],
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? pTextMain : pTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.check_circle_outline, color: pTextMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Rapor bulunamadı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pTextMain)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PREMIUM RAPOR KARTI
// ---------------------------------------------------------------------------
class _PremiumReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _PremiumReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = report['status'] as String? ?? 'pending';
    final targetType = report['targetType'] as String? ?? 'Yorum';
    final reason = report['reason'] as String? ?? 'Uygunsuz içerik';
    
    // Durum Renkleri
    Color statusColor = pWarning;
    if (status == 'resolved') statusColor = pSuccess;
    if (status == 'rejected') statusColor = pAlert;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: pSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pBorder),
          boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Sol Renkli Çizgi (Duruma Göre)
                Container(width: 6, color: statusColor),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tür ve Durum Rozetleri
                            Row(
                              children: [
                                _miniBadge(targetType.toUpperCase(), pBrandBrownLight, pBrandBrown),
                                const SizedBox(width: 6),
                                _miniBadge(status == 'pending' ? 'BEKLEYOR' : status.toUpperCase(), statusColor.withOpacity(0.1), statusColor),
                              ],
                            ),
                            const Icon(Icons.chevron_right, color: pTextMuted, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          reason,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detayları görmek için dokunun',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textCol, letterSpacing: 0.5)),
    );
  }
}
