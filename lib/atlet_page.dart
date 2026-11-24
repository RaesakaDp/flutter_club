import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'export_helper.dart';

class Atlet {
  final int id;
  String nama;
  String nik;
  String jenisKelamin;
  String tanggalLahir;
  String kelompokUmur;
  String kelasLatihan;
  String gayaUtama;
  String status;

  Atlet({
    required this.id,
    required this.nama,
    required this.nik,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.kelompokUmur,
    required this.kelasLatihan,
    required this.gayaUtama,
    required this.status,
  });

  factory Atlet.fromMap(Map map) {
    return Atlet(
      id: map['id'] ?? 0,
      nama: map['nama'] ?? '-',
      nik: map['nik'] ?? '-',
      jenisKelamin: map['jenis_kelamin'] ?? 'Putra',
      tanggalLahir: map['tanggal_lahir'] ?? '-',
      kelompokUmur: map['kelompok_umur'] ?? 'KU-1',
      kelasLatihan: map['kelas_latihan'] ?? 'Kelas Pembinaan',
      gayaUtama: map['gaya_utama'] ?? 'Gaya Bebas',
      status: map['status'] ?? 'Aktif',
    );
  }
}

class AtletPage extends StatefulWidget {
  const AtletPage({super.key});

  @override
  State<AtletPage> createState() => _AtletPageState();
}

class _AtletPageState extends State<AtletPage> {
  final _supabase = Supabase.instance.client;
  List<Atlet> _daftarAtlet = [];
  bool _isLoading = true;

  String _kataKunciCari = '';
  String _filterKelas = 'Semua';
  String _filterKU = 'Semua';

  final List<String> _opsiKelas = [
    'Kelas Prestasi Utama',
    'Kelas Pra-Prestasi',
    'Kelas Pembinaan',
    'Kelas Pemula',
  ];
  final List<String> _opsiKU = ['Senior', 'KU-1', 'KU-2', 'KU-3', 'KU-4', 'Pemula'];
  final List<String> _opsiJK = ['Putra', 'Putri'];
  final List<String> _opsiGaya = ['Gaya Bebas', 'Gaya Dada', 'Gaya Punggung', 'Gaya Kupu-kupu', 'Gaya Ganti'];
  final List<String> _opsiStatus = ['Aktif', 'Cuti'];

  @override
  void initState() {
    super.initState();
    _ambilDataAtlet();
  }

  Future<void> _ambilDataAtlet() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('atlet')
          .select()
          .order('id', ascending: true);

      final List dataMentah = response as List;
      setState(() {
        _daftarAtlet = dataMentah.map((item) => Atlet.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data atlet: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _eksporCsvAtlet() {
    final dataTampil = _atletTersaring;
    if (dataTampil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data atlet untuk diekspor.')),
      );
      return;
    }

    final List<List> baris = [
      ['ID Atlet', 'NIK', 'Nama Lengkap', 'L/P', 'Tanggal Lahir', 'Kelompok Umur', 'Kelas Latihan', 'Gaya Spesialis', 'Status'],
    ];

    for (final a in dataTampil) {
      final kode = 'ATL-${a.id.toString().padLeft(3, '0')}';
      baris.add([
        kode,
        a.nik,
        a.nama,
        a.jenisKelamin,
        a.tanggalLahir,
        a.kelompokUmur,
        a.kelasLatihan,
        a.gayaUtama,
        a.status,
      ]);
    }

    unduhFileCsv('database_atlet_pendaftaran.csv', baris);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data pendaftaran atlet (CSV) berhasil diunduh!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _simpanKeDatabase({
    Atlet? atletEdit,
    required String nama,
    required String nik,
    required String jk,
    required String tglLahir,
    required String ku,
    required String kelas,
    required String gaya,
    required String status,
  }) async {
    try {
      final dataKirim = {
        'nama': nama,
        'nik': nik.isEmpty ? '-' : nik,
        'jenis_kelamin': jk,
        'tanggal_lahir': tglLahir.isEmpty ? '-' : tglLahir,
        'kelompok_umur': ku,
        'kelas_latihan': kelas,
        'gaya_utama': gaya,
        'status': status,
      };

      if (atletEdit != null) {
        await _supabase.from('atlet').update(dataKirim).eq('id', atletEdit.id);
      } else {
        await _supabase.from('atlet').insert(dataKirim);
      }

      await _ambilDataAtlet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(atletEdit != null ? 'Data atlet diperbarui!' : 'Atlet baru berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusAtlet(Atlet atlet) async {
    try {
      await _supabase.from('atlet').delete().eq('id', atlet.id);
      await _ambilDataAtlet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data ${atlet.nama} berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Atlet> get _atletTersaring {
    return _daftarAtlet.where((atlet) {
      final kodeAtlet = 'ATL-${atlet.id.toString().padLeft(3, '0')}';
      final cocokNama = atlet.nama.toLowerCase().contains(_kataKunciCari.toLowerCase()) ||
          kodeAtlet.toLowerCase().contains(_kataKunciCari.toLowerCase()) ||
          atlet.nik.toLowerCase().contains(_kataKunciCari.toLowerCase());
      final cocokKelas = _filterKelas == 'Semua' || atlet.kelasLatihan == _filterKelas;
      final cocokKU = _filterKU == 'Semua' || atlet.kelompokUmur == _filterKU;
      return cocokNama && cocokKelas && cocokKU;
    }).toList();
  }

  void _tampilkanFormAtlet({Atlet? atletEdit}) {
    final isEdit = atletEdit != null;
    final namaController = TextEditingController(text: isEdit ? atletEdit.nama : '');
    final nikController = TextEditingController(text: isEdit && atletEdit.nik != '-' ? atletEdit.nik : '');
    final tglLahirController = TextEditingController(
      text: isEdit && atletEdit.tanggalLahir != '-' ? atletEdit.tanggalLahir : '',
    );

    String pilihJK = isEdit && _opsiJK.contains(atletEdit.jenisKelamin) ? atletEdit.jenisKelamin : _opsiJK.first;
    String pilihKelas = isEdit && _opsiKelas.contains(atletEdit.kelasLatihan)
        ? atletEdit.kelasLatihan
        : _opsiKelas.first;
    String pilihKU = isEdit && _opsiKU.contains(atletEdit.kelompokUmur) ? atletEdit.kelompokUmur : 'KU-2';
    String pilihGaya = isEdit && _opsiGaya.contains(atletEdit.gayaUtama) ? atletEdit.gayaUtama : _opsiGaya.first;
    String pilihStatus = isEdit ? atletEdit.status : _opsiStatus.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Data Atlet' : 'Tambah Atlet Baru'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap Atlet (Sesuai Akta/KK)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nikController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIK Atlet (Untuk Pendaftaran Lomba)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: pilihJK,
                              decoration: const InputDecoration(
                                labelText: 'Putra / Putri',
                                border: OutlineInputBorder(),
                              ),
                              items: _opsiJK.map((jk) => DropdownMenuItem(value: jk, child: Text(jk))).toList(),
                              onChanged: (val) => setDialogState(() => pilihJK = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tglLahirController,
                              decoration: const InputDecoration(
                                labelText: 'Tgl Lahir (DD/MM/YYYY)',
                                hintText: '12/05/2013',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: pilihKelas,
                        decoration: const InputDecoration(
                          labelText: 'Kelas Latihan / Tingkat Prestasi',
                          border: OutlineInputBorder(),
                        ),
                        items: _opsiKelas.map((kls) => DropdownMenuItem(value: kls, child: Text(kls))).toList(),
                        onChanged: (val) => setDialogState(() => pilihKelas = val!),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: pilihKU,
                              decoration: const InputDecoration(
                                labelText: 'Kelompok Umur',
                                border: OutlineInputBorder(),
                              ),
                              items: _opsiKU.map((ku) => DropdownMenuItem(value: ku, child: Text(ku))).toList(),
                              onChanged: (val) => setDialogState(() => pilihKU = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: pilihStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: _opsiStatus.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                              onChanged: (val) => setDialogState(() => pilihStatus = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: pilihGaya,
                        decoration: const InputDecoration(
                          labelText: 'Nomor / Gaya Spesialis Utama',
                          border: OutlineInputBorder(),
                        ),
                        items: _opsiGaya.map((gaya) => DropdownMenuItem(value: gaya, child: Text(gaya))).toList(),
                        onChanged: (val) => setDialogState(() => pilihGaya = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (namaController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    _simpanKeDatabase(
                      atletEdit: atletEdit,
                      nama: namaController.text.trim(),
                      nik: nikController.text.trim(),
                      jk: pilihJK,
                      tglLahir: tglLahirController.text.trim(),
                      ku: pilihKU,
                      kelas: pilihKelas,
                      gaya: pilihGaya,
                      status: pilihStatus,
                    );
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Atlet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _warnaKelas(String kelas) {
    if (kelas == 'Kelas Prestasi Utama') return Colors.indigo;
    if (kelas == 'Kelas Pra-Prestasi') return const Color(0xFF0284C7);
    if (kelas == 'Kelas Pembinaan') return Colors.teal;
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final dataTampil = _atletTersaring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Kelas, KU, Pencarian & Tombol Ekspor
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 250,
                    child: TextField(
                      onChanged: (value) => setState(() => _kataKunciCari = value),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, NIK, atau ID...',
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
                        value: _filterKelas,
                        items: ['Semua', ..._opsiKelas]
                            .map((kls) => DropdownMenuItem(value: kls, child: Text(kls == 'Semua' ? 'Kelas: Semua' : kls)))
                            .toList(),
                        onChanged: (val) => setState(() => _filterKelas = val!),
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
                        value: _filterKU,
                        items: ['Semua', ..._opsiKU]
                            .map((ku) => DropdownMenuItem(value: ku, child: Text('KU: $ku')))
                            .toList(),
                        onChanged: (val) => setState(() => _filterKU = val!),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _ambilDataAtlet,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang Data',
                  ),
                  OutlinedButton.icon(
                    onPressed: _eksporCsvAtlet,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Ekspor Excel Lomba'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _tampilkanFormAtlet(),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Tambah Atlet'),
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
                                'Belum ada data atlet pada filter ini. Klik "Tambah Atlet" untuk menambahkan.',
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
                                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nama Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('NIK', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('L/P & Tgl Lahir', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Kelas Latihan', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('KU', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Gaya Spesialis', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: dataTampil.map((atlet) {
                                    final isAktif = atlet.status == 'Aktif';
                                    final kodeAtlet = 'ATL-${atlet.id.toString().padLeft(3, '0')}';
                                    final warnaKls = _warnaKelas(atlet.kelasLatihan);
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(kodeAtlet, style: const TextStyle(fontWeight: FontWeight.w500))),
                                        DataCell(Text(atlet.nama, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(atlet.nik)),
                                        DataCell(Text('${atlet.jenisKelamin} • ${atlet.tanggalLahir}')),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: warnaKls.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              atlet.kelasLatihan,
                                              style: TextStyle(
                                                color: warnaKls,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(atlet.kelompokUmur, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(atlet.gayaUtama)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isAktif ? Colors.green.shade50 : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              atlet.status,
                                              style: TextStyle(
                                                color: isAktif ? Colors.green.shade700 : Colors.orange.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                                tooltip: 'Edit',
                                                onPressed: () => _tampilkanFormAtlet(atletEdit: atlet),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                tooltip: 'Hapus',
                                                onPressed: () => _hapusAtlet(atlet),
                                              ),
                                            ],
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