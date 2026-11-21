import 'package:flutter/material.dart';

class TagihanIuran {
  String id;
  String namaAtlet;
  String kelompokUmur;
  String bulan;
  int nominal;
  bool isLunas;
  String tanggalBayar;

  TagihanIuran({
    required this.id,
    required this.namaAtlet,
    required this.kelompokUmur,
    required this.bulan,
    required this.nominal,
    required this.isLunas,
    required this.tanggalBayar,
  });
}

class IuranPage extends StatefulWidget {
  const IuranPage({super.key});

  @override
  State<IuranPage> createState() => _IuranPageState();
}

class _IuranPageState extends State<IuranPage> {
  final List<TagihanIuran> _daftarTagihan = [
    TagihanIuran(
      id: 'INV-2026-001',
      namaAtlet: 'Rafa Pratama',
      kelompokUmur: 'KU-1',
      bulan: 'November 2026',
      nominal: 450000,
      isLunas: true,
      tanggalBayar: '03 Nov 2026',
    ),
    TagihanIuran(
      id: 'INV-2026-002',
      namaAtlet: 'Nadia Putri',
      kelompokUmur: 'KU-2',
      bulan: 'November 2026',
      nominal: 450000,
      isLunas: true,
      tanggalBayar: '05 Nov 2026',
    ),
    TagihanIuran(
      id: 'INV-2026-003',
      namaAtlet: 'Dimas Anggara',
      kelompokUmur: 'KU-1',
      bulan: 'November 2026',
      nominal: 450000,
      isLunas: false,
      tanggalBayar: '-',
    ),
    TagihanIuran(
      id: 'INV-2026-004',
      namaAtlet: 'Kenzo Wijaya',
      kelompokUmur: 'Pemula',
      bulan: 'November 2026',
      nominal: 350000,
      isLunas: false,
      tanggalBayar: '-',
    ),
  ];

  String _filterStatus = 'Semua';

  // Format angka menjadi Rupiah sederhana (contoh: 450000 -> Rp 450.000)
  String _formatRupiah(int angka) {
    final teks = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $teks';
  }

  List<TagihanIuran> get _tagihanTersaring {
    if (_filterStatus == 'Lunas') {
      return _daftarTagihan.where((t) => t.isLunas).toList();
    } else if (_filterStatus == 'Belum Lunas') {
      return _daftarTagihan.where((t) => !t.isLunas).toList();
    }
    return _daftarTagihan;
  }

  int get _totalPemasukan {
    return _daftarTagihan.where((t) => t.isLunas).fold(0, (sum, item) => sum + item.nominal);
  }

  int get _totalTertunggak {
    return _daftarTagihan.where((t) => !t.isLunas).fold(0, (sum, item) => sum + item.nominal);
  }

  void _tambahTagihanBaru() {
    final namaController = TextEditingController();
    final nominalController = TextEditingController(text: '450000');
    String pilihKU = 'KU-1';
    String pilihBulan = 'November 2026';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Tagihan Iuran Baru'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(labelText: 'Nama Atlet', border: OutlineInputBorder()),
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
                      initialValue: pilihBulan,
                      decoration: const InputDecoration(labelText: 'Periode Bulan', border: OutlineInputBorder()),
                      items: ['November 2026', 'Desember 2026']
                          .map((bln) => DropdownMenuItem(value: bln, child: Text(bln)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => pilihBulan = val!),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nominal Iuran (Angka saja)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                  onPressed: () {
                    if (namaController.text.trim().isEmpty) return;
                    final nominal = int.tryParse(nominalController.text.trim()) ?? 450000;
                    final nomor = (_daftarTagihan.length + 1).toString().padLeft(3, '0');

                    setState(() {
                      _daftarTagihan.add(
                        TagihanIuran(
                          id: 'INV-2026-$nomor',
                          namaAtlet: namaController.text.trim(),
                          kelompokUmur: pilihKU,
                          bulan: pilihBulan,
                          nominal: nominal,
                          isLunas: false,
                          tanggalBayar: '-',
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Tagihan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _ubahStatusBayar(TagihanIuran tagihan) {
    setState(() {
      tagihan.isLunas = !tagihan.isLunas;
      tagihan.tanggalBayar = tagihan.isLunas ? '21 Nov 2026' : '-';
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataTampil = _tagihanTersaring;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu Ringkasan Keuangan
          Row(
            children: [
              _buildFinanceCard(
                'Total Pemasukan Terkumpul',
                _formatRupiah(_totalPemasukan),
                Icons.account_balance_wallet,
                Colors.green,
              ),
              const SizedBox(width: 20),
              _buildFinanceCard(
                'Total Iuran Tertunggak',
                _formatRupiah(_totalTertunggak),
                Icons.pending_actions,
                Colors.orange,
              ),
              const SizedBox(width: 20),
              _buildFinanceCard(
                'Total Tagihan Bulan Ini',
                '${_daftarTagihan.length} Tagihan',
                Icons.receipt_long,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Baris Filter & Tombol Buat Tagihan
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
                    value: _filterStatus,
                    items: ['Semua', 'Lunas', 'Belum Lunas']
                        .map((st) => DropdownMenuItem(value: st, child: Text('Status: $st')))
                        .toList(),
                    onChanged: (val) => setState(() => _filterStatus = val!),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _tambahTagihanBaru,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Tagihan Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabel Tagihan Iuran
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text('No. Invoice', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nama Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('KU', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Periode', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nominal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tgl Bayar', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi Cepat', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: dataTampil.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(item.namaAtlet)),
                    DataCell(Text(item.kelompokUmur)),
                    DataCell(Text(item.bulan)),
                    DataCell(Text(_formatRupiah(item.nominal), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isLunas ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.isLunas ? 'Lunas' : 'Belum Lunas',
                          style: TextStyle(
                            color: item.isLunas ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(item.tanggalBayar)),
                    DataCell(
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _ubahStatusBayar(item),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              foregroundColor: item.isLunas ? Colors.grey.shade700 : Colors.green.shade700,
                            ),
                            child: Text(item.isLunas ? 'Batalkan' : 'Tandai Lunas', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() => _daftarTagihan.removeWhere((t) => t.id == item.id));
                            },
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

  Widget _buildFinanceCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}