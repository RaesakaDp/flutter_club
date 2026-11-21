import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatatanWaktuPage extends StatefulWidget {
  const CatatanWaktuPage({super.key});

  @override
  State<CatatanWaktuPage> createState() => _CatatanWaktuPageState();
}

class _CatatanWaktuPageState extends State<CatatanWaktuPage> {
  final _supabase = Supabase.instance.client;
  List> _daftarWaktu = [];
  bool _isLoading = true;
  String _filterNomor = 'Semua';

  final List<String> _opsiNomorLomba = [
    '50m Gaya Bebas',
    '100m Gaya Bebas',
    '50m Gaya Dada',
    '100m Gaya Dada',
    '50m Gaya Punggung',
    '50m Gaya Kupu-kupu',
  ];

  @override
  void initState() {
    super.initState();
    _ambilDataDariDatabase();
  }

  // Mengambil data dari tabel Supabase
  Future<void> _ambilDataDariDatabase() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('catatan_waktu')
          .select()
          .order('waktu_detik', ascending: true);

      setState(() {
        _daftarWaktu = List>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Menyimpan data baru ke Supabase
  Future<void> _simpanKeDatabase({
    required String nama,
    required String ku,
    required String nomor,
    required double waktu,
    required String tanggal,
  }) async {
    try {
      await _supabase.from('catatan_waktu').insert({
        'nama_atlet': nama,
        'kelompok_umur': ku,
        'nomor_lomba': nomor,
        'waktu_detik': waktu,
        'tanggal_tes': tanggal,
      });
      await _ambilDataDariDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan waktu berhasil disimpan ke cloud!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Menghapus data dari Supabase
  Future<void> _hapusDariDatabase(int id) async {
    try {
      await _supabase.from('catatan_waktu').delete().eq('id', id);
      await _ambilDataDariDatabase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List> get _dataTersaring {
    if (_filterNomor == 'Semua') return _daftarWaktu;
    return _daftarWaktu.where((item) => item['nomor_lomba'] == _filterNomor).toList();
  }

  void _tampilkanFormInput() {
    final namaController = TextEditingController();
    final waktuController = TextEditingController();
    final tanggalController = TextEditingController(text: '21 Nov 2026');
    String pilihKU = 'KU-1';
    String pilihNomor = _opsiNomorLomba.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Input Catatan Waktu (Time Trial)'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Atlet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: pilihKU,
                      decoration: const InputDecoration(labelText: 'Kelompok Umur', border: OutlineInputBorder()),
                      items: ['KU-1', 'KU-2', 'KU-3', 'Pemula']
                          .map((ku) => DropdownMenuItem(value: ku, child: Text(ku)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => pilihKU = val!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: pilihNomor,
                      decoration: const InputDecoration(labelText: 'Nomor Lomba', border: OutlineInputBorder()),
                      items: _opsiNomorLomba
                          .map((nm) => DropdownMenuItem(value: nm, child: Text(nm)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => pilihNomor = val!),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: waktuController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Catatan Waktu (dalam detik, contoh: 28.45)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: tanggalController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Tes / Lomba',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                  onPressed: () {
                    final nama = namaController.text.trim();
                    final waktu = double.tryParse(waktuController.text.trim().replaceAll(',', '.'));
                    if (nama.isEmpty || waktu == null) return;

                    Navigator.pop(context);
                    _simpanKeDatabase(
                      nama: nama,
                      ku: pilihKU,
                      nomor: pilihNomor,
                      waktu: waktu,
                      tanggal: tanggalController.text.trim(),
                    );
                  },
                  child: const Text('Simpan ke Database'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Filter & Aksi
          Row(
            children: [
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
                        .map((nm) => DropdownMenuItem(value: nm, child: Text('Nomor: $nm')))
                        .toList(),
                    onChanged: (val) => setState(() => _filterNomor = val!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _ambilDataDariDatabase,
                icon: const Icon(Icons.refresh),
                tooltip: 'Muat Ulang Data dari Cloud',
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _tampilkanFormInput,
                icon: const Icon(Icons.add_chart, size: 18),
                label: const Text('Input Catatan Waktu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabel Data Catatan Waktu
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
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: Text('Belum ada catatan waktu di database. Klik "Input Catatan Waktu" untuk menambah.'),
                        ),
                      )
                    : DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                        columns: const [
                          DataColumn(label: Text('Peringkat', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Nama Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('KU', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Nomor Lomba', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Waktu (Detik)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tanggal Tes', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: List.generate(dataTampil.length, (index) {
                          final item = dataTampil[index];
                          final isTercepat = index == 0 && _filterNomor != 'Semua';

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (isTercepat) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Rekor Tercepat',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              DataCell(Text(item['nama_atlet'] ?? '-')),
                              DataCell(Text(item['kelompok_umur'] ?? '-')),
                              DataCell(Text(item['nomor_lomba'] ?? '-')),
                              DataCell(
                                Text(
                                  '${item['waktu_detik']} dtk',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              DataCell(Text(item['tanggal_tes'] ?? '-')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'Hapus dari Database',
                                  onPressed: () => _hapusDariDatabase(item['id']),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
          ),
        ],
      ),
    );
  }
}