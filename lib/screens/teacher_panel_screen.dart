import 'package:flutter/material.dart';
import '../models/study_item.dart';
import '../models/deck_model.dart';
import '../state/app_state.dart';

class TeacherPanelScreen extends StatefulWidget {
  const TeacherPanelScreen({Key? key}) : super(key: key);

  @override
  State<TeacherPanelScreen> createState() => _TeacherPanelScreenState();
}

class _TeacherPanelScreenState extends State<TeacherPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Değişkenleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedDeckId; // Seçilen Ders/Deste ID'si
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _mnemonicController = TextEditingController();
  final _explanationController = TextEditingController();

  // Test Seçenekleri
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  int _correctOptionIndex = 0;

  // Boşluk Doldurma Şablonu
  final _clozeTextController = TextEditingController();

  // Yeni Ders Ekleme Form Değişkenleri (Dialog için)
  final _deckTitleController = TextEditingController();
  String _selectedCategoryForNewDeck = '657_dmk';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Varsayılan ilk desteyi seç
    final decks = AppState.instance.decksNotifier.value;
    if (decks.isNotEmpty) {
      _selectedDeckId = decks.first.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _mnemonicController.dispose();
    _explanationController.dispose();
    _clozeTextController.dispose();
    _deckTitleController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Yeni Ders / Deste Ekleme Diyaloğu (ADHD-uyumlu neon tasarım)
  void _showAddDeckDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0xFFEC4899).withOpacity(0.4), width: 1.5),
              ),
              title: const Text(
                'YENİ DERS / DESTE OLUŞTUR 📚',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _deckTitleController,
                    decoration: InputDecoration(
                      labelText: 'Ders / Konu Başlığı',
                      hintText: 'Örn: Anayasa Hukuku - Temel Haklar',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0B0F19).withOpacity(0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryForNewDeck,
                    decoration: InputDecoration(
                      labelText: 'Ana Kategori Grubu',
                      filled: true,
                      fillColor: const Color(0xFF0B0F19).withOpacity(0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: '657_dmk', child: Text('657 Sayılı DMK')),
                      DropdownMenuItem(value: 'kik', child: Text('Kamu İhale Kanunu')),
                      DropdownMenuItem(value: 'medical', child: Text('Tıbbi Sekreterlik')),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        _selectedCategoryForNewDeck = v!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_deckTitleController.text.trim().isEmpty) return;

                    final newDeck = StudyDeck(
                      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
                      title: _deckTitleController.text.trim(),
                      category: _selectedCategoryForNewDeck,
                    );

                    // State'e ekle
                    AppState.instance.addNewDeck(newDeck);
                    
                    // Formu temizle ve güncelle
                    _deckTitleController.clear();
                    Navigator.pop(context);

                    setState(() {
                      _selectedDeckId = newDeck.id; // Seçili desteyi yeni eklenen yap
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${newDeck.title}" dersi oluşturuldu! 🎉'),
                        backgroundColor: const Color(0xFF22C55E),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                  ),
                  child: const Text('Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveNewItem() {
    if (_selectedDeckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce bir ders/deste oluşturun! ⚠️'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Şık verilerini topla
    List<String> options = _optionControllers.map((c) => c.text.trim()).toList();
    
    // Eğer şıklar boş bırakılmışsa otomatik doldur
    if (options.any((o) => o.isEmpty)) {
      options = [
        _answerController.text.trim(),
        'Yanlış Şık 1',
        'Yanlış Şık 2',
        'Yanlış Şık 3',
      ];
    }

    // Seçilen destenin bilgilerini al
    final deck = AppState.instance.decksNotifier.value.firstWhere((d) => d.id == _selectedDeckId);

    // Boşluk doldurma metni girilmemişse otomatik şablon oluştur
    String clozeText = _clozeTextController.text.trim();
    if (clozeText.isEmpty) {
      clozeText = _questionController.text.replaceFirst(_answerController.text, '[${_answerController.text}]');
    }

    final newItem = StudyItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      deckId: _selectedDeckId!,
      category: deck.category,
      categoryDisplayName: deck.title, // Kategori ismi olarak dersin kendi adını veriyoruz
      question: _questionController.text.trim(),
      answer: _answerController.text.trim(),
      mnemonic: _mnemonicController.text.trim().isEmpty ? 'İpucu eklenmedi.' : _mnemonicController.text.trim(),
      options: options,
      correctOptionIndex: _correctOptionIndex,
      clozeText: clozeText,
      clozeAnswer: _answerController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty ? 'Detaylı açıklama eklenmedi.' : _explanationController.text.trim(),
    );

    // Uygulama State'ine ekle
    AppState.instance.addNewCard(newItem);

    // Formu temizle ve geri bildirim ver
    _formKey.currentState!.reset();
    _questionController.clear();
    _answerController.clear();
    _mnemonicController.clear();
    _explanationController.clear();
    _clozeTextController.clear();
    for (var c in _optionControllers) {
      c.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeni Soru Başarıyla Dersi Altına Eklendi! 🎉'),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÖĞRETMEN YÖNETİM PANELİ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFEC4899),
          tabs: const [
            Tab(icon: Icon(Icons.add_task), text: 'Yeni İçerik Ekle'),
            Tab(icon: Icon(Icons.people_outline), text: 'Öğrenci Analiz Raporları'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F19), Color(0xFF1E1E38)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAddContentTab(),
            _buildStudentReportsTab(),
          ],
        ),
      ),
    );
  }

  // TAB 1: Yeni İçerik Ekleme Formu
  Widget _buildAddContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DERS / DESTE SEÇİMİ VE YENİ DERS EKLEME
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<List<StudyDeck>>(
                    valueListenable: AppState.instance.decksNotifier,
                    builder: (context, decks, _) {
                      // Eğer seçili olan listede yoksa, listenin ilk elemanını seç
                      if (_selectedDeckId != null && !decks.any((d) => d.id == _selectedDeckId)) {
                        _selectedDeckId = decks.isNotEmpty ? decks.first.id : null;
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedDeckId,
                        decoration: InputDecoration(
                          labelText: 'Hedef Ders / Deste',
                          filled: true,
                          fillColor: const Color(0xFF1E293B).withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: decks.map((deck) {
                          return DropdownMenuItem<String>(
                            value: deck.id,
                            child: Text(
                              deck.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedDeckId = v;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Ders Ekleme Butonu
                ElevatedButton(
                  onPressed: _showAddDeckDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4), // Cyan
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add_box, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Soru Alanı
            _buildTextFormField(
              controller: _questionController,
              label: 'Ezber Kartı Sorusu / Terim Adı',
              hint: 'Örn: Devlet memurunun yıllık izin hakkı kaç gündür?',
              validator: (v) => v!.isEmpty ? 'Lütfen soruyu girin' : null,
            ),
            const SizedBox(height: 16),

            // Doğru Cevap Alanı
            _buildTextFormField(
              controller: _answerController,
              label: 'Doğru Cevap',
              hint: 'Örn: 20 gün',
              validator: (v) => v!.isEmpty ? 'Lütfen doğru cevabı girin' : null,
            ),
            const SizedBox(height: 16),

            // Zayıf Öğrenciler için Hafıza İpucu (Mnemonic)
            _buildTextFormField(
              controller: _mnemonicController,
              label: 'Zayıf Öğrenciler için Hafıza Kodlaması / İpucu (Z Kuşağı Diliyle 🧠)',
              hint: 'Örn: Yıllık izin = 20 gün çalış, 20 gün yat gibi komik bir çağrışım yazın.',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Detaylı Açıklama (Kanun Maddesi)
            _buildTextFormField(
              controller: _explanationController,
              label: 'Resmi Kanun Maddesi / Detaylı Bilgi',
              hint: 'Örn: 657 Sayılı Kanun Madde 102 uyarınca, hizmeti 1 yıldan 10 yıla kadar olan memurların...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ÇOKTAN SEÇMELİ TEST DETAYLARI
            const Text(
              'TEST ŞIKLARI (OPSİYONEL - Boş bırakılırsa otomatik üretilir)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 12),
            _buildOptionFields(),
            const SizedBox(height: 24),

            // BOŞLUK DOLDURMA DETAYLARI
            const Text(
              'BOŞLUK DOLDURMA ŞABLONU (OPSİYONEL - Gizlenecek cevabı [parantez] içinde yazın)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 12),
            _buildTextFormField(
              controller: _clozeTextController,
              label: 'Boşluklu Cümle',
              hint: 'Örn: Devlet memurlarının haftalık çalışma süresi genel olarak [40] saattir.',
            ),
            const SizedBox(height: 32),

            // Kaydet Butonu
            ElevatedButton.icon(
              onPressed: _saveNewItem,
              icon: const Icon(Icons.save),
              label: const Text('HAFIZAYA EKLE VE ÖĞRENCİLERE GÖNDER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // TAB 2: Öğrenci Raporları
  Widget _buildStudentReportsTab() {
    // Sınıfın simüle edilmiş ADHD/öğrenci başarı verileri
    final List<Map<String, dynamic>> simulatedStudents = [
      {
        "name": "Ahmet Yılmaz",
        "xp": "2,450 XP",
        "streak": "5 Gün 🔥",
        "struggle": "657 DMK - İzin Hakları",
        "success": 72,
        "avatar": "👶",
      },
      {
        "name": "Elif Kaya",
        "xp": "1,980 XP",
        "streak": "3 Gün 🔥",
        "struggle": "Kamu İhale K. - Usuller",
        "success": 55,
        "avatar": "⚡",
      },
      {
        "name": "Canan Demir",
        "xp": "3,120 XP",
        "streak": "12 Gün 🔥",
        "struggle": "Tıbbi Terimler (Sorunsuz)",
        "success": 91,
        "avatar": "👑",
      },
      {
        "name": "Murat Çelik",
        "xp": "450 XP",
        "streak": "0 Gün 😴",
        "struggle": "Hepsinde Zorlanıyor (Aktif Değil)",
        "success": 32,
        "avatar": "💤",
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: simulatedStudents.length,
      itemBuilder: (context, index) {
        final student = simulatedStudents[index];
        Color successColor = const Color(0xFF22C55E);
        if (student["success"] < 50) {
          successColor = const Color(0xFFEF4444);
        } else if (student["success"] < 80) {
          successColor = const Color(0xFFEAB308);
        }

        return Card(
          color: const Color(0xFF1E293B).withOpacity(0.4),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profil ve İsim
                    Row(
                      children: [
                        Text(student["avatar"], style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student["name"],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Gelişim Seviyesi: %${student["success"]} Başarı',
                              style: TextStyle(color: successColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // XP ve Seri
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(student["xp"], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF06B6D4))),
                        Text(student["streak"], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                const SizedBox(height: 4),
                // En çok hata yapılan yer
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    const Text('En Çok Sıkıntı Çektiği Konu: ', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    Expanded(
                      child: Text(
                        student["struggle"],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Ortak Input Tasarımı
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1E293B).withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5),
        ),
      ),
    );
  }

  // Şık Giriş Alanları
  Widget _buildOptionFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildOptionInput(0, 'A Şıkkı (Örn: Doğru Cevap)')),
            const SizedBox(width: 12),
            Expanded(child: _buildOptionInput(1, 'B Şıkkı')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildOptionInput(2, 'C Şıkkı')),
            const SizedBox(width: 12),
            Expanded(child: _buildOptionInput(3, 'D Şıkkı')),
          ],
        ),
        const SizedBox(height: 16),
        // Doğru Şık Hangisi?
        DropdownButtonFormField<int>(
          value: _correctOptionIndex,
          decoration: InputDecoration(
            labelText: 'Sınav için Doğru Cevap Şıkkı Hangisi?',
            filled: true,
            fillColor: const Color(0xFF1E293B).withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 0, child: Text('A Seçeneği')),
            DropdownMenuItem(value: 1, child: Text('B Seçeneği')),
            DropdownMenuItem(value: 2, child: Text('C Seçeneği')),
            DropdownMenuItem(value: 3, child: Text('D Seçeneği')),
          ],
          onChanged: (v) {
            setState(() {
              _correctOptionIndex = v!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOptionInput(int index, String label) {
    return TextFormField(
      controller: _optionControllers[index],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF1E293B).withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
