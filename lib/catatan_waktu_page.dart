import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'export_helper.dart';

class CatatanWaktu {
  final int id;
  final String namaAtlet;
  final String kelompokUmur;
  final String nomorLomba;
  final double waktuDetik;
  final double? targetLimit;
  final String tanggalTes;

  CatatanWaktu({
    required this.id,
    required this.namaAtlet,
    required this.kelompokUmur,
    required this.nomorLomba,
    required this.waktuDetik,
    this.targetLimit,
    required this.tanggalTes,
  });

  factory CatatanWaktu.fromMap(Map map) {
    return CatatanWaktu(
      id: map['id'] ?? 0,
      namaAtlet: map['nama_atlet'] ?? '-',
      kelompokUmur: map['kelompok_umur'] ?? 'KU-1',
      nomorLomba: map['nomor_lomba'] ?? '50m Gaya Bebas',
      waktuDetik: (map['waktu_detik'] as num?)?.toDouble() ?? 0.0,
      targetLimit: (map['target_limit'] as num?)?.toDouble(),
      tanggalTes: map['tanggal_tes'] ?? '-',
    );
  }
}

class CatatanWaktuPage extends StatefulWidget {
  const CatatanWaktuPage({super.key});

  @override
  State<CatatanWaktuPage> createState() => _CatatanWaktuPageState();
}

class _CatatanWaktuPageState extends State<CatatanWaktuPage> {
  final _supabase = Supabase.instance.client;
  List<CatatanWaktu> _daftarWaktu = [];
  List<String> _daftarNamaAtletDb = [];
  bool _isLoading = true;

  bool _modeLimitTerbaik = true; // true = Limit Terbaik (PB), false = Semua Riwayat Tes
  String _kataKunciCari = '';
  String _filterNomor = 'Semua';

  final List<String> _opsiKU = ['Senior', 'KU-1', 'KU-2', 'KU-3', 'KU-4', 'Pemula'];
  final List<String> _opsiNomorLomba = [
    '50m Gaya Bebas',
    '100m Gaya Bebas',
    '200m Gaya Bebas',
    '400m Gaya Bebas',
    '50m Gaya Dada',
    '100m Gaya Dada',
    '200m Gaya Dada',
    '50m Gaya Punggung',
    '100m Gaya Punggung',
    '50m Gaya Kupu-kupu',
    '100m Gaya Kupu-kupu',
    '200m Gaya Ganti',
  ];

  @override
  void initState() {
    super.initState();
    _ambilDataLengkap();
  }

  Future<void> _ambilDataLengkap() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('catatan_waktu').select().order('id', ascending: false),
        _supabase.from('atlet').select('nama').order('nama', ascending: true),
      ]);

      final List dataWaktu = results[0] as List;
      final List dataAtlet = results[1] as List;

      setState(() {
        _daftarWaktu = dataWaktu.map((item) => CatatanWaktu.fromMap(item)).toList();
        _daftarNamaAtletDb = dataAtlet
            .map((a) => (a['nama'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat catatan waktu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Menghitung catatan waktu tercepat (Personal Best) per atlet per nomor lomba
  List<CatatanWaktu> get _daftarLimitTerbaik {
    final Map<String, CatatanWaktu> terbaikMap = {};

    for (final item in _daftarWaktu) {
      final kunci = '${item.namaAtlet.trim().toLowerCase()}_${item.nomorLomba}';
      if (!terbaikMap.containsKey(kunci) || item.waktuDetik < terbaikMap[kunci]!.waktuDetik) {
        terbaikMap[kunci] = item;
      }
    }

    final listPB = terbaikMap.values.toList();
    listPB.sort((a, b) => a.namaAtlet.toLowerCase().compareTo(b.namaAtlet.toLowerCase()));
    return listPB;
  }

  List<CatatanWaktu> get _dataTersaring {
    final sumberData = _modeLimitTerbaik ? _daftarLimitTerbaik : _daftarWaktu;
    return sumberData.where((item) {
      final cocokNama = item.namaAtlet.toLowerCase().contains(_kataKunciCari.toLowerCase());
      final cocokNomor = _filterNomor == 'Semua' || item.nomorLomba == _filterNomor;
      return cocokNama && cocokNomor;
    }).toList();
  }

  void _eksporCsvLimit() {
    final dataTampil = _dataTersaring;
    if (dataTampil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data catatan waktu untuk diekspor.')),
      );
      return;
    }

    final List<List> baris = [
      ['Nama Atlet', 'KU', 'Nomor Lomba', 'Limit Terbaik / Waktu (Detik)', 'Target Limit (Detik)', 'Keterangan Limit', 'Tanggal Tercapai'],
    ];

    for (final item in dataTampil) {
      String ketLimit = 'Belum ada target';
      if (item.targetLimit != null && item.targetLimit! > 0) {
        ketLimit = item.waktuDetik <= item.targetLimit! ? 'LOLOS LIMIT' : 'Belum Limit';
      }
      baris.add([
        item.namaAtlet,
        item.kelompokUmur,
        item.nomorLomba,
        item.waktuDetik,
        item.targetLimit ?? '-',
        ketLimit,
        item.tanggalTes,
      ]);
    }

    final namaFile = _modeLimitTerbaik ? 'limit_terbaik_atlet_pb.csv' : 'riwayat_catatan_waktu.csv';
    unduhFileCsv(namaFile, baris);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rekap limit waktu (CSV) berhasil diunduh!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _simpanCatatanBaru({
    required String nama,
    required String ku,
    required String nomor,
    required double detik,
    double? targetLimit,
    required String tanggal,
  }) async {
    try {
      await _supabase.from('catatan_waktu').insert({
        'nama_atlet': nama,
        'kelompok_umur': ku,
        'nomor_lomba': nomor,
        'waktu_detik': detik,
        'target_limit': targetLimit,
        'tanggal_tes': tanggal,
      });
      await _ambilDataLengkap();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan waktu berhasil disimpan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan waktu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusCatatan(int id) async {
    try {
      await _supabase.from('catatan_waktu').delete().eq('id', id);
      await _ambilDataLengkap();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _tampilkanFormTambah() {
    final namaController = TextEditingController(
      text: _daftarNamaAtletDb.isNotEmpty ? _daftarNamaAtletDb.first : '',
    );
    final waktuController = TextEditingController();
    final targetLimitController = TextEditingController();
    final now = DateTime.now();
    final tglDefault = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final tanggalController = TextEditingController(text: tglDefault);

    String pilihKU = 'KU-2';
    String pilihNomor = _opsiNomorLomba.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Input Catatan Waktu & Limit'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_daftarNamaAtletDb.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _daftarNamaAtletDb.contains(namaController.text)
                              ? namaController.text
                              : _daftarNamaAtletDb.first,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Atlet Terdaftar',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pool),
                          ),
                          items: _daftarNamaAtletDb
                              .map((nama) => DropdownMenuItem(value: nama, child: Text(nama)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => namaController.text = val!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Atlet (Bisa ketik manual)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: pilihKU,
                              decoration: const InputDecoration(labelText: 'KU', border: OutlineInputBorder()),
                              items: _opsiKU.map((ku) => DropdownMenuItem(value: ku, child: Text(ku))).toList(),
                              onChanged: (val) => setDialogState(() => pilihKU = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: pilihNomor,
                              decoration: const InputDecoration(labelText: 'Nomor Lomba', border: OutlineInputBorder()),
                              items: _opsiNomorLomba.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                              onChanged: (val) => setDialogState(() => pilihNomor = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: waktuController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Waktu Tempuh Atlet (Detik, misal: 27.85)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: targetLimitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Target Limit Kejuaraan (Opsional, misal: 28.00)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: tanggalController,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Tes / Kejuaraan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                  onPressed: () {
                    final nama = namaController.text.trim();
                    final detik = double.tryParse(waktuController.text.trim().replaceAll(',', '.'));
                    final target = double.tryParse(targetLimitController.text.trim().replaceAll(',', '.'));
                    if (nama.isEmpty || detik == null) return;
                    Navigator.pop(context);
                    _simpanCatatanBaru(
                      nama: nama,
                      ku: pilihKU,
                      nomor: pilihNomor,
                      detik: detik,
                      targetLimit: target,
                      tanggal: tanggalController.text.trim(),
                    );
                  },
                  child: const Text('Simpan Catatan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataTampil = _dataTersaring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saklar Mode: Limit Terbaik (PB) vs Semua Riwayat Tes
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Limit Terbaik Atlet (PB)'),
                    selected: _modeLimitTerbaik,
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      color: _modeLimitTerbaik ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _modeLimitTerbaik = true),
                  ),
                  ChoiceChip(
                    label: const Text('Semua Riwayat Tes'),
                    selected: !_modeLimitTerbaik,
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      color: !_modeLimitTerbaik ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _modeLimitTerbaik = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter & Tombol Aksi
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 250,
                    child: TextField(
                      onChanged: (val) => setState(() => _kataKunciCari = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atlet...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF94A3B8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterNomor,
                        items: ['Semua', ..._opsiNomorLomba]
                            .map((n) => DropdownMenuItem(value: n, child: Text(n == 'Semua' ? 'Nomor: Semua' : n)))
                            .toList(),
                        onChanged: (val) => setState(() => _filterNomor = val!),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _ambilDataLengkap,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang Data',
                  ),
                  OutlinedButton.icon(
                    onPressed: _eksporCsvLimit,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(_modeLimitTerbaik ? 'Ekspor Limit PB' : 'Ekspor Riwayat'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _tampilkanFormTambah,
                    icon: const Icon(Icons.timer, size: 18),
                    label: const Text('Catat Waktu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tabel Limit Terbaik / Riwayat
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : dataTampil.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'Belum ada catatan waktu di database. Klik "Catat Waktu" untuk menambahkan.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth - (isMobile ? 32 : 64),
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                  columns: [
                                    const DataColumn(label: Text('Nama Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('KU', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Nomor Lomba', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(
                                      label: Text(
                                        _modeLimitTerbaik ? 'Limit Terbaik (PB)' : 'Waktu Tempuh',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const DataColumn(label: Text('Target Limit', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Status Limit', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: dataTampil.map((item) {
                                    final punyaTarget = item.targetLimit != null && item.targetLimit! > 0;
                                    final lolosLimit = punyaTarget && item.waktuDetik <= item.targetLimit!;

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item.namaAtlet, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(item.kelompokUmur)),
                                        DataCell(Text(item.nomorLomba)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F9FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_modeLimitTerbaik) ...[
                                                  const Icon(Icons.emoji_events, size: 15, color: Colors.amber),
                                                  const SizedBox(width: 5),
                                                ],
                                                Text(
                                                  '${item.waktuDetik} dtk',
                                                  style: const TextStyle(
                                                    color: Color(0xFF0284C7),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(punyaTarget ? '${item.targetLimit} dtk' : '-')),
                                        DataCell(
                                          !punyaTarget
                                              ? const Text('-', style: TextStyle(color: Colors.grey))
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: lolosLimit ? Colors.green.shade50 : Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    lolosLimit ? 'Lolos Limit' : 'Belum Limit',
                                                    style: TextStyle(
                                                      color: lolosLimit ? Colors.green.shade700 : Colors.orange.shade800,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        DataCell(Text(item.tanggalTes)),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                            tooltip: 'Hapus',
                                            onPressed: () => _hapusCatatan(item.id),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}