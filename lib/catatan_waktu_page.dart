import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatatanWaktu {
  final int id;
  final String namaAtlet;
  final String kelompokUmur;
  final String nomorLomba;
  final double waktuDetik;
  final String tanggalTes;

  CatatanWaktu({
    required this.id,
    required this.namaAtlet,
    required this.kelompokUmur,
    required this.nomorLomba,
    required this.waktuDetik,
    required this.tanggalTes,
  });

  factory CatatanWaktu.fromMap(Map map) {
    return CatatanWaktu(
      id: map['id'] ?? 0,
      namaAtlet: map['nama_atlet'] ?? '-',
      kelompokUmur: map['kelompok_umur'] ?? 'KU-1',
      nomorLomba: map['nomor_lomba'] ?? '50m Gaya Bebas',
      waktuDetik: (map['waktu_detik'] as num?)?.toDouble() ?? 0.0,
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
  bool _isLoading = true;

  String _kataKunciCari = '';
  String _filterNomor = 'Semua';

  final List<String> _opsiKU = ['KU-1', 'KU-2', 'KU-3', 'Pemula'];
  final List<String> _opsiNomorLomba = [
    '50m Gaya Bebas',
    '100m Gaya Bebas',
    '50m Gaya Dada',
    '100m Gaya Dada',
    '50m Gaya Punggung',
    '50m Gaya Kupu-kupu',
    '200m Gaya Ganti',
  ];

  @override
  void initState() {
    super.initState();
    _ambilCatatanWaktu();
  }

  Future<void> _ambilCatatanWaktu() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('catatan_waktu')
          .select()
          .order('id', ascending: false);

      final List dataMentah = response as List;
      setState(() {
        _daftarWaktu = dataMentah.map((item) => CatatanWaktu.fromMap(item)).toList();
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

  Future<void> _simpanCatatanBaru({
    required String nama,
    required String ku,
    required String nomor,
    required double detik,
    required String tanggal,
  }) async {
    try {
      await _supabase.from('catatan_waktu').insert({
        'nama_atlet': nama,
        'kelompok_umur': ku,
        'nomor_lomba': nomor,
        'waktu_detik': detik,
        'tanggal_tes': tanggal,
      });
      await _ambilCatatanWaktu();
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
      await _ambilCatatanWaktu();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<CatatanWaktu> get _waktuTersaring {
    return _daftarWaktu.where((item) {
      final cocokNama = item.namaAtlet.toLowerCase().contains(_kataKunciCari.toLowerCase());
      final cocokNomor = _filterNomor == 'Semua' || item.nomorLomba == _filterNomor;
      return cocokNama && cocokNomor;
    }).toList();
  }

  void _tampilkanFormTambah() {
    final namaController = TextEditingController();
    final waktuController = TextEditingController();
    final now = DateTime.now();
    final tglDefault = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final tanggalController = TextEditingController(text: tglDefault);

    String pilihKU = _opsiKU.first;
    String pilihNomor = _opsiNomorLomba.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Catat Waktu Renang Baru'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
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
                        items: _opsiKU.map((ku) => DropdownMenuItem(value: ku, child: Text(ku))).toList(),
                        onChanged: (val) => setDialogState(() => pilihKU = val!),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: pilihNomor,
                        decoration: const InputDecoration(labelText: 'Nomor Lomba / Gaya', border: OutlineInputBorder()),
                        items: _opsiNomorLomba.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                        onChanged: (val) => setDialogState(() => pilihNomor = val!),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: waktuController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Catatan Waktu (Detik, misal: 28.45)',
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
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                  onPressed: () {
                    final nama = namaController.text.trim();
                    final detik = double.tryParse(waktuController.text.trim().replaceAll(',', '.'));
                    if (nama.isEmpty || detik == null) return;
                    Navigator.pop(context);
                    _simpanCatatanBaru(
                      nama: nama,
                      ku: pilihKU,
                      nomor: pilihNomor,
                      detik: detik,
                      tanggal: tanggalController.text.trim(),
                    );
                  },
                  child: const Text('Simpan Rekor'),
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
    final dataTampil = _waktuTersaring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter & Tombol Tambah Responsif
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 260,
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
                    onPressed: _ambilCatatanWaktu,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang Data',
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

              // Kontainer Tabel dengan Horizontal Scroll di HP
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
                                  columns: const [
                                    DataColumn(label: Text('Nama Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('KU', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nomor Lomba', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Catatan Waktu', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Tanggal Tes', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: dataTampil.map((item) {
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
                                            child: Text(
                                              '${item.waktuDetik} detik',
                                              style: const TextStyle(
                                                color: Color(0xFF0284C7),
                                                fontWeight: FontWeight.bold,
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