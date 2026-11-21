import 'package:flutter/material.dart';

// Cetakan (Model) Data Atlet
class Atlet {
  String id;
  String nama;
  String kelompokUmur;
  String gayaUtama;
  String status;

  Atlet({
    required this.id,
    required this.nama,
    required this.kelompokUmur,
    required this.gayaUtama,
    required this.status,
  });
}

class AtletPage extends StatefulWidget {
  const AtletPage({super.key});

  @override
  State<AtletPage> createState() => _AtletPageState();
}

class _AtletPageState extends State<AtletPage> {
  // Data awal tiruan (Dummy Data) sebelum terhubung ke database
  final List<Atlet> _daftarAtlet = [
    Atlet(id: 'ATL-001', nama: 'Rafa Pratama', kelompokUmur: 'KU-1', gayaUtama: 'Gaya Bebas', status: 'Aktif'),
    Atlet(id: 'ATL-002', nama: 'Nadia Putri', kelompokUmur: 'KU-2', gayaUtama: 'Gaya Kupu-kupu', status: 'Aktif'),
    Atlet(id: 'ATL-003', nama: 'Dimas Anggara', kelompokUmur: 'KU-1', gayaUtama: 'Gaya Dada', status: 'Aktif'),
    Atlet(id: 'ATL-004', nama: 'Zahra Aulia', kelompokUmur: 'KU-3', gayaUtama: 'Gaya Punggung', status: 'Cuti'),
    Atlet(id: 'ATL-005', nama: 'Kenzo Wijaya', kelompokUmur: 'Pemula', gayaUtama: 'Gaya Bebas', status: 'Aktif'),
  ];

  String _kataKunciCari = '';
  String _filterKU = 'Semua';

  final List<String> _opsiKU = ['KU-1', 'KU-2', 'KU-3', 'Pemula'];
  final List<String> _opsiGaya = ['Gaya Bebas', 'Gaya Dada', 'Gaya Punggung', 'Gaya Kupu-kupu'];
  final List<String> _opsiStatus = ['Aktif', 'Cuti'];

  // Menyaring daftar atlet berdasarkan pencarian & filter KU
  List<Atlet> get _atletTersaring {
    return _daftarAtlet.where((atlet) {
      final cocokNama = atlet.nama.toLowerCase().contains(_kataKunciCari.toLowerCase()) ||
          atlet.id.toLowerCase().contains(_kataKunciCari.toLowerCase());
      final cocokKU = _filterKU == 'Semua' || atlet.kelompokUmur == _filterKU;
      return cocokNama && cocokKU;
    }).toList();
  }

  // Menampilkan Dialog Form untuk Tambah atau Edit Atlet
  void _tampilkanFormAtlet({Atlet? atletEdit}) {
    final isEdit = atletEdit != null;
    final namaController = TextEditingController(text: isEdit ? atletEdit.nama : '');
    String pilihKU = isEdit ? atletEdit.kelompokUmur : _opsiKU.first;
    String pilihGaya = isEdit ? atletEdit.gayaUtama : _opsiGaya.first;
    String pilihStatus = isEdit ? atletEdit.status : _opsiStatus.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Data Atlet' : 'Tambah Atlet Baru'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Atlet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: pilihKU,
                      decoration: const InputDecoration(
                        labelText: 'Kelompok Umur (KU)',
                        border: OutlineInputBorder(),
                      ),
                      items: _opsiKU.map((ku) => DropdownMenuItem(value: ku, child: Text(ku))).toList(),
                      onChanged: (val) => setDialogState(() => pilihKU = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: pilihGaya,
                      decoration: const InputDecoration(
                        labelText: 'Gaya Spesialis',
                        border: OutlineInputBorder(),
                      ),
                      items: _opsiGaya.map((gaya) => DropdownMenuItem(value: gaya, child: Text(gaya))).toList(),
                      onChanged: (val) => setDialogState(() => pilihGaya = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: pilihStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Keanggotaan',
                        border: OutlineInputBorder(),
                      ),
                      items: _opsiStatus.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                      onChanged: (val) => setDialogState(() => pilihStatus = val!),
                    ),
                  ],
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

                    setState(() {
                      if (isEdit) {
                        atletEdit.nama = namaController.text.trim();
                        atletEdit.kelompokUmur = pilihKU;
                        atletEdit.gayaUtama = pilihGaya;
                        atletEdit.status = pilihStatus;
                      } else {
                        final nomorBaru = (_daftarAtlet.length + 1).toString().padLeft(3, '0');
                        _daftarAtlet.add(
                          Atlet(
                            id: 'ATL-$nomorBaru',
                            nama: namaController.text.trim(),
                            kelompokUmur: pilihKU,
                            gayaUtama: pilihGaya,
                            status: pilihStatus,
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
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

  // Menghapus data atlet
  void _hapusAtlet(Atlet atlet) {
    setState(() {
      _daftarAtlet.removeWhere((item) => item.id == atlet.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data ${atlet.nama} berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataTampil = _atletTersaring;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // BARIS PENCARIAN, FILTER, & TOMBOL TAMBAH
          // ==========================================
          Row(
            children: [
              // Kolom Pencarian
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (value) => setState(() => _kataKunciCari = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau ID atlet...',
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
              const SizedBox(width: 16),

              // Dropdown Filter Kelompok Umur
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
              const Spacer(),

              // Tombol Tambah Atlet
              ElevatedButton.icon(
                onPressed: () => _tampilkanFormAtlet(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah Atlet'),
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

          // ==========================================
          // TABEL DATA ATLET
          // ==========================================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: dataTampil.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('Tidak ada data atlet yang sesuai.')),
                  )
                : DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text('ID Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Kelompok Umur', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Gaya Spesialis', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: dataTampil.map((atlet) {
                      final isAktif = atlet.status == 'Aktif';
                      return DataRow(
                        cells: [
                          DataCell(Text(atlet.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(atlet.nama)),
                          DataCell(Text(atlet.kelompokUmur)),
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
        ],
      ),
    );
  }
}