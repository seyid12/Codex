import 'package:flutter/material.dart';
import '../models/study_item.dart';
import '../state/app_state.dart';

class StruggleAnalysisScreen extends StatelessWidget {
  const StruggleAnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZAYIF NOKTALARIM'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F19), Color(0xFF1E1E38)],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<List<StudyItem>>(
            valueListenable: state.itemsNotifier,
            builder: (context, items, _) {
              // Hatalı kartları filtrele ve hata sayısına göre büyükten küçüğe sırala
              final struggledItems = items.where((item) => item.wrongAttempts > 0).toList();
              struggledItems.sort((a, b) => b.wrongAttempts.compareTo(a.wrongAttempts));

              final successRates = state.getCategorySuccessRates();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- KATEGORİ BAŞARI ORANLARI ---
                    const SizedBox(height: 12),
                    const Text(
                      'KONU BAŞARI ANALİZİ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryProgressCard(successRates),
                    const SizedBox(height: 24),

                    // --- SORULARIN LİSTESİ ---
                    const Text(
                      'EN ÇOK HATA YAPILAN KARTLAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: struggledItems.isEmpty
                          ? _buildNoStrugglesWidget()
                          : ListView.builder(
                              itemCount: struggledItems.length,
                              itemBuilder: (context, index) {
                                final item = struggledItems[index];
                                return _buildStruggledCardTile(context, item);
                              },
                            ),
                    ),

                    // --- EN ALT: KURTARMA SEANSI BUTONU ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: struggledItems.isEmpty
                            ? null
                            : () {
                                // Sadece zor kartlar çalışma modunu açıp kartlar ekranına yönlendir
                                state.studyOnlyStruggled = true;
                                Navigator.pushReplacementNamed(context, '/flashcard');
                              },
                        icon: const Icon(Icons.flash_on),
                        label: const Text(
                          'KAYIPLARI TELAFİ ET (ZOR KARTLARI ÇALIŞ)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          disabledBackgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shadowColor: const Color(0xFFEF4444).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Kategorilere göre başarı oranları kartı
  Widget _buildCategoryProgressCard(Map<String, double> successRates) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: successRates.entries.map((entry) {
          final categoryName = entry.key;
          final rate = entry.value;
          
          // Renge karar ver (Kritik: Kırmızı, Orta: Sarı, Başarılı: Yeşil)
          Color progressColor = const Color(0xFF22C55E); // Yeşil
          String statusText = "Harika! 🏆";
          if (rate < 50.0) {
            progressColor = const Color(0xFFEF4444); // Kırmızı
            statusText = "Zorlanıyorsun! ⚠️";
          } else if (rate < 80.0) {
            progressColor = const Color(0xFFEAB308); // Sarı
            statusText = "Daha Çok Çalış! ⏳";
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '%${rate.toInt()} - $statusText',
                      style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: const Color(0xFF0B0F19),
                    color: progressColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Hatalı kart listeleme karosu
  Widget _buildStruggledCardTile(BuildContext context, StudyItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B).withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1.5),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.wrongAttempts} HATA',
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
        title: Text(
          item.question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item.categoryDisplayName,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        iconColor: const Color(0xFFEF4444),
        childrenPadding: const EdgeInsets.all(16.0),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DOĞRU CEVAP:', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  item.answer,
                  style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                const Text('HAFIZA İPUCU:', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
                  ),
                  child: Text(
                    item.mnemonic,
                    style: const TextStyle(color: Color(0xFF06B6D4), fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('AÇIKLAMA:', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  item.explanation,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Eğer henüz hiç hata yoksa gösterilecek widget
  Widget _buildNoStrugglesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('🏆🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'HİÇ ZAYIF NOKTAN YOK!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF22C55E)),
          ),
          SizedBox(height: 8),
          Text(
            'Sorularda hiç hata yapmadın veya henüz çalışmaya başlamadın. Harika odaklanma gücü!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
