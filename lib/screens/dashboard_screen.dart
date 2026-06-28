import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/study_item.dart';
import '../models/deck_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0F19),
              Color(0xFF111827),
              Color(0xFF1E1E38), // Synthwave derin mor esintisi
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ÜST BAR (Başlık, Seri ve Level/XP) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CODEX',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    // Günlük Seri (Streak) Göstergesi
                    ValueListenableBuilder<int>(
                      valueListenable: state.streakNotifier,
                      builder: (context, streak, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)], // Sarı - Kırmızı alev
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '$streak GÜN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- LEVEL VE XP KARTI ---
                _buildLevelXpCard(context, state),
                const SizedBox(height: 24),

                // --- ZAYIF NOKTALARIN ALERTI (Z Kuşağı Diliyle) ---
                _buildStruggleSummaryWidget(context, state),
                const SizedBox(height: 24),

                // --- DERS BAŞLIĞI ---
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: Text(
                    'DERS KÜTÜPHANESİ 📚',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFF06B6D4), // Neon Cyan
                    ),
                  ),
                ),

                // --- MEVCUT DERSLERİN LİSTELENMESİ (Dinamik) ---
                ValueListenableBuilder<List<StudyDeck>>(
                  valueListenable: state.decksNotifier,
                  builder: (context, decks, _) {
                    return ValueListenableBuilder<List<StudyItem>>(
                      valueListenable: state.itemsNotifier,
                      builder: (context, items, _) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: decks.length,
                          itemBuilder: (context, index) {
                            final deck = decks[index];
                            final cardCount = items.where((item) => item.deckId == deck.id).length;

                            return _buildDeckCard(context, deck, cardCount);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- BAŞARI ROZETLERİ ---
                _buildBadgesSection(context, state),
                const SizedBox(height: 32),

                // --- ÖĞRETMEN PANELİ GEÇİŞ BUTONU ---
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/teacher');
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF94A3B8)),
                    label: const Text(
                      'Öğretmen Yönetim Paneline Geç',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ders/Deste Kartı Tasarımı
  Widget _buildDeckCard(BuildContext context, StudyDeck deck, int cardCount) {
    Color categoryColor = const Color(0xFFEC4899); // Pembe
    String categoryName = "657 DMK";
    if (deck.category == 'kik') {
      categoryColor = const Color(0xFF06B6D4); // Cyan
      categoryName = "İhale K.";
    } else if (deck.category == 'medical') {
      categoryColor = const Color(0xFFF59E0B); // Sarı
      categoryName = "Tıbbi Sek.";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        title: Text(
          deck.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: categoryColor.withOpacity(0.4)),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(color: categoryColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$cardCount Kart',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.play_circle_outline, color: Colors.white, size: 28),
        onTap: () {
          _showStudyModesBottomSheet(context, deck);
        },
      ),
    );
  }

  // Ders Seçildiğinde Açılan Oyun Modları Menüsü
  void _showStudyModesBottomSheet(BuildContext context, StudyDeck deck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: const Color(0xFF06B6D4).withOpacity(0.4), width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                deck.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'ÇALIŞMA MODU SEÇİN 🧠',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF06B6D4), letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),

              // Mod 1: Akıllı Kartlar
              _buildModeTile(
                context: context,
                deckId: deck.id,
                title: 'Akıllı Kartlar',
                desc: 'Bellek ipuçları ve 3D kartlar.',
                icon: Icons.style,
                color: const Color(0xFFEC4899),
                route: '/flashcard',
              ),
              const SizedBox(height: 12),

              // Mod 2: Zamana Karşı Hızlı Test
              _buildModeTile(
                context: context,
                deckId: deck.id,
                title: 'Zamana Karşı Yarış',
                desc: '10 saniyede hızlı test! Kombonu yükselt.',
                icon: Icons.timer,
                color: const Color(0xFF06B6D4),
                route: '/quiz',
              ),
              const SizedBox(height: 12),

              // Mod 3: Sayı Avcısı (Boşluk Doldurma)
              _buildModeTile(
                context: context,
                deckId: deck.id,
                title: 'Sayı Avcısı (Boşluk Doldurma)',
                desc: 'Sayıları ve süreleri yazarak ezberle.',
                icon: Icons.edit_note,
                color: const Color(0xFF3B82F6),
                route: '/cloze',
              ),
              const SizedBox(height: 12),

              // Mod 4: Terim Eşleme
              _buildModeTile(
                context: context,
                deckId: deck.id,
                title: 'Terim Eşleme',
                desc: 'Tıbbi terim ve tanımları eşleştir.',
                icon: Icons.compare_arrows,
                color: const Color(0xFFF59E0B),
                route: '/matching',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTile({
    required BuildContext context,
    required String deckId,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        // AppState'de seçili dersin ID'sini kaydet
        AppState.instance.selectedDeckId = deckId;
        Navigator.pop(context); // Bottom sheet'i kapat
        Navigator.pushNamed(context, route); // Mod ekranına git
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F19).withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  // Seviye ve XP İlerleme Kartı
  Widget _buildLevelXpCard(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([state.levelNotifier, state.xpNotifier]),
        builder: (context, _) {
          int lvl = state.levelNotifier.value;
          int xp = state.xpNotifier.value;
          int threshold = lvl * 150;
          double progress = (xp / threshold).clamp(0.0, 1.0);

          return Row(
            children: [
              // Sol Taraf: Seviye Rozeti
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Pembe - Mor
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    'Lvl\n$lvl',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Sağ Taraf: XP Barı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MEVZUAT RÜTBESİ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$xp / $threshold XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // XP Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            color: const Color(0xFF0F172A),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 10,
                            width: progress * MediaQuery.of(context).size.width,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sonraki rütbeye ${(threshold - xp)} XP kaldı! 🚀',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Zayıf Noktalar Rapor Özeti Widget'ı
  Widget _buildStruggleSummaryWidget(BuildContext context, AppState state) {
    return ValueListenableBuilder<List<StudyItem>>(
      valueListenable: state.itemsNotifier,
      builder: (context, items, _) {
        final successRates = state.getCategorySuccessRates();
        String worstCategory = "";
        double lowestRate = 100.0;

        successRates.forEach((categoryName, rate) {
          if (rate < lowestRate) {
            lowestRate = rate;
            worstCategory = categoryName;
          }
        });

        // Eğer henüz hiçbir hata yapılmamışsa veya başarılar tam ise
        if (worstCategory.isEmpty || lowestRate >= 99.0) {
          return Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Şu An Harika Gidiyorsun!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                      ),
                      Text(
                        'Hata listen tertemiz. Ezber fırtınasına devam et!',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Zayıf konu tespiti uyarısı (Gen Z dili)
        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/struggle');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444).withOpacity(0.15),
                  const Color(0xFF7F1D1D).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZAYIF NOKTA TESPİT EDİLDİ!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                          letterSpacing: 1.0,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$worstCategory dersinde başarı oranın %${lowestRate.toInt()} seviyesine düştü. Dikkat dağınık gibi! 🧠',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text(
                            'Kayıpları Telafi Et',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Color(0xFFEF4444)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Başarı Rozetleri Bölümü
  Widget _buildBadgesSection(BuildContext context, AppState state) {
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BAŞARI ROZETLERİM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<List<String>>(
              valueListenable: state.badgesNotifier,
              builder: (context, unlockedBadges, _) {
                // Mevcut tüm rozetler ve ikonları
                final List<Map<String, String>> allBadges = [
                  {"name": "Çırak", "emoji": "👶", "desc": "Kodlamaya başladın."},
                  {"name": "Hızlı Öğrenen", "emoji": "⚡", "desc": "2. Seviyeye ulaştın."},
                  {"name": "Mevzuat Bükücü", "emoji": "⚔️", "desc": "3. Seviyeye ulaştın."},
                  {"name": "Codex Hâkimi", "emoji": "👑", "desc": "5. Seviyeye ulaştın."},
                ];

                return SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: allBadges.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final badge = allBadges[index];
                      final isUnlocked = unlockedBadges.contains(badge["name"]);

                      return Opacity(
                        opacity: isUnlocked ? 1.0 : 0.25, // Kilitliler şeffaf
                        child: Container(
                          width: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                badge["emoji"]!,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge["name"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                  color: isUnlocked ? const Color(0xFF06B6D4) : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
