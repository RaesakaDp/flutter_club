import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'export_helper.dart';

class Pelatih {
  final int id;
  String nama;
  String nik;
  String lisensi;
  String spesialisasi;
  String noHp;
  String status;

  Pelatih({
    required this.id,
    required this.nama,
    required this.nik,
    required this.lisensi,
    required this.spesialisasi,
    required this.noHp,
    required this.status,
  });

  factory Pelatih.fromMap(Map map) {
    return Pelatih(
      id: map['id'] ?? 0,
      nama: map['nama'] ?? '-',
      nik: map['nik'] ?? '-',
      lisensi: map['lisensi'] ?? 'Lisensi C Daerah',
      spesialisasi: map['spesialisasi'] ?? 'Gaya Bebas & Sprint',
      noHp: map['no_hp'] ?? '-',
      status: map['status'] ?? 'Aktif',
    );
  }
}

class PelatihPage extends StatefulWidget {
  const PelatihPage({super.key});

  @override
  State<PelatihPage> createState() => _PelatihPageState();
}

class _PelatihPageState extends State<PelatihPage> {
  final _supabase = Supabase.instance.client;
  List<Pelatih> _daftarPelatih = [];
  bool _isLoading = true;

  String _kataKunciCari = '';
  String _filterLisensi = 'Semua';

  final List<String> _opsiLisensi = [
    'Lisensi A Nasional',
    'Lisensi B Nasional',
    'Lisensi C Daerah',
    'Lisensi D / Dasar',
    'Asisten Pelatih',
  ];

  final List<String> _opsiStatus = ['Aktif', 'Non-Aktif'];

  @override
  void initState() {
    super.initState();
    _ambilDataPelatih();
  }

  Future<void> _ambilDataPelatih() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('pelatih')
          .select()
          .order('id', ascending: true);

      final List dataMentah = response as List;
      setState(() {
        _daftarPelatih = dataMentah.map((item) => Pelatih.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pelatih: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _eksporCsvPelatih() {
    final dataTampil = _pelatihTersaring;
    if (dataTampil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data pelatih untuk diekspor.')),
      );
      return;
    }

    final List<List> baris = [
      ['ID Pelatih', 'Nama Lengkap', 'NIK / No. Identitas', 'Tingkat Lisensi', 'Spesialisasi', 'No. HP / WA', 'Status'],
    ];

    for (final p in dataTampil) {
      final kode = 'PLT-${p.id.toString().padLeft(3, '0')}';
      baris.add([kode, p.nama, p.nik, p.lisensi, p.spesialisasi, p.noHp, p.status]);
    }

    unduhFileCsv('database_pelatih_pendaftaran.csv', baris);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data pendaftaran pelatih (CSV) berhasil diunduh!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _simpanPelatih({
    Pelatih? pelatihEdit,
    required String nama,
    required String nik,
    required String lisensi,
    required String spesialisasi,
    required String noHp,
    required String status,
  }) async {
    try {
      final dataKirim = {
        'nama': nama,
        'nik': nik.isEmpty ? '-' : nik,
        'lisensi': lisensi,
        'spesialisasi': spesialisasi.isEmpty ? '-' : spesialisasi,
        'no_hp': noHp.isEmpty ? '-' : noHp,
        'status': status,
      };

      if (pelatihEdit != null) {
        await _supabase.from('pelatih').update(dataKirim).eq('id', pelatihEdit.id);
      } else {
        await _supabase.from('pelatih').insert(dataKirim);
      }

      await _ambilDataPelatih();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pelatihEdit != null ? 'Data pelatih diperbarui!' : 'Pelatih baru berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data pelatih: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusPelatih(Pelatih pelatih) async {
    try {
      await _supabase.from('pelatih').delete().eq('id', pelatih.id);
      await _ambilDataPelatih();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data ${pelatih.nama} berhasil dihapus')),
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

  List<Pelatih> get _pelatihTersaring {
    return _daftarPelatih.where((p) {
      final cocokNama = p.nama.toLowerCase().contains(_kataKunciCari.toLowerCase()) ||
          p.nik.toLowerCase().contains(_kataKunciCari.toLowerCase());
      final cocokLisensi = _filterLisensi == 'Semua' || p.lisensi == _filterLisensi;
      return cocokNama && cocokLisensi;
    }).toList();
  }

  void _tampilkanFormPelatih({Pelatih? pelatihEdit}) {
    final isEdit = pelatihEdit != null;
    final namaController = TextEditingController(text: isEdit ? pelatihEdit.nama : '');
    final nikController = TextEditingController(text: isEdit && pelatihEdit.nik != '-' ? pelatihEdit.nik : '');
    final spesialisasiController = TextEditingController(
      text: isEdit && pelatihEdit.spesialisasi != '-' ? pelatihEdit.spesialisasi : 'Kelas Prestasi & Sprint',
    );
    final hpController = TextEditingController(text: isEdit && pelatihEdit.noHp != '-' ? pelatihEdit.noHp : '');

    String pilihLisensi = isEdit && _opsiLisensi.contains(pelatihEdit.lisensi)
        ? pelatihEdit.lisensi
        : _opsiLisensi[2];
    String pilihStatus = isEdit ? pelatihEdit.status : _opsiStatus.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Data Pelatih' : 'Tambah Pelatih / Official'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap & Gelar Pelatih',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nikController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIK / ID Akuatik Indonesia (Pendaftaran)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: pilihLisensi,
                        decoration: const InputDecoration(
                          labelText: 'Tingkat Lisensi Kepelatihan',
                          border: OutlineInputBorder(),
                        ),
                        items: _opsiLisensi.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (val) => setDialogState(() => pilihLisensi = val!),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: spesialisasiController,
                        decoration: const InputDecoration(
                          labelText: 'Spesialisasi / Kelas Pegangan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pool),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: hpController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP / WhatsApp',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: pilihStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status Pelatih',
                          border: OutlineInputBorder(),
                        ),
                        items: _opsiStatus.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                        onChanged: (val) => setDialogState(() => pilihStatus = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (namaController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    _simpanPelatih(
                      pelatihEdit: pelatihEdit,
                      nama: namaController.text.trim(),
                      nik: nikController.text.trim(),
                      lisensi: pilihLisensi,
                      spesialisasi: spesialisasiController.text.trim(),
                      noHp: hpController.text.trim(),
                      status: pilihStatus,
                    );
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Pelatih'),
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
    final dataTampil = _pelatihTersaring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        hintText: 'Cari nama atau NIK pelatih...',
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
                        value: _filterLisensi,
                        items: ['Semua', ..._opsiLisensi]
                            .map((l) => DropdownMenuItem(value: l, child: Text(l == 'Semua' ? 'Lisensi: Semua' : l)))
                            .toList(),
                        onChanged: (val) => setState(() => _filterLisensi = val!),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _ambilDataPelatih,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang Data',
                  ),
                  OutlinedButton.icon(
                    onPressed: _eksporCsvPelatih,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Ekspor Data Pendaftaran'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _tampilkanFormPelatih(),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Tambah Pelatih'),
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
                                'Belum ada data pelatih. Klik "Tambah Pelatih" untuk melengkapi data pendaftaran tim.',
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
                                    DataColumn(label: Text('Nama Pelatih', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('NIK / ID Reg', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Lisensi', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Spesialisasi', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('No. HP / WA', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: dataTampil.map((p) {
                                    final kode = 'PLT-${p.id.toString().padLeft(3, '0')}';
                                    final isAktif = p.status == 'Aktif';
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(kode, style: const TextStyle(fontWeight: FontWeight.w500))),
                                        DataCell(Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(p.nik)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F9FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              p.lisensi,
                                              style: const TextStyle(
                                                color: Color(0xFF0284C7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(p.spesialisasi)),
                                        DataCell(Text(p.noHp)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isAktif ? Colors.green.shade50 : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              p.status,
                                              style: TextStyle(
                                                color: isAktif ? Colors.green.shade700 : Colors.grey.shade700,
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
                                                onPressed: () => _tampilkanFormPelatih(pelatihEdit: p),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                tooltip: 'Hapus',
                                                onPressed: () => _hapusPelatih(p),
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