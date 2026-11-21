import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TagihanIuran {
  final int id;
  final String namaAtlet;
  final String kelompokUmur;
  final String bulan;
  final int nominal;
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

  factory TagihanIuran.fromMap(Map<String, dynamic> map) {
    return TagihanIuran(
      id: map['id'] ?? 0,
      namaAtlet: map['nama_atlet'] ?? '-',
      kelompokUmur: map['kelompok_umur'] ?? 'KU-1',
      bulan: map['bulan'] ?? '-',
      nominal: (map['nominal'] as num?)?.toInt() ?? 0,
      isLunas: map['is_lunas'] == true,
      tanggalBayar: map['tanggal_bayar'] ?? '-',
    );
  }
}

class IuranPage extends StatefulWidget {
  const IuranPage({super.key});

  @override
  State<IuranPage> createState() => _IuranPageState();
}

class _IuranPageState extends State<IuranPage> {
  final _supabase = Supabase.instance.client;
  List<TagihanIuran> _daftarTagihan = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _ambilDataTagihan();
  }

  Future<void> _ambilDataTagihan() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('tagihan_iuran')
          .select()
          .order('id', ascending: false);

      final List dataMentah = response as List;
      setState(() {
        _daftarTagihan = dataMentah.map((item) => TagihanIuran.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat tagihan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _simpanTagihanBaru({
    required String nama,
    required String ku,
    required String bulan,
    required int nominal,
  }) async {
    try {
      await _supabase.from('tagihan_iuran').insert({
        'nama_atlet': nama,
        'kelompok_umur': ku,
        'bulan': bulan,
        'nominal': nominal,
        'is_lunas': false,
        'tanggal_bayar': '-',
      });
      await _ambilDataTagihan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tagihan baru tersimpan ke cloud!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat tagihan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _ubahStatusBayar(TagihanIuran tagihan) async {
    final statusBaru = !tagihan.isLunas;
    final now = DateTime.now();
    final tglHariIni =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final tglBayarBaru = statusBaru ? tglHariIni : '-';

    try {
      await _supabase.from('tagihan_iuran').update({
        'is_lunas': statusBaru,
        'tanggal_bayar': tglBayarBaru,
      }).eq('id', tagihan.id);

      await _ambilDataTagihan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusTagihan(int id) async {
    try {
      await _supabase.from('tagihan_iuran').delete().eq('id', id);
      await _ambilDataTagihan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus tagihan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
                      items: ['November 2026', 'Desember 2026', 'Januari 2027']
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
                    Navigator.pop(context);
                    _simpanTagihanBaru(
                      nama: namaController.text.trim(),
                      ku: pilihKU,
                      bulan: pilihBulan,
                      nominal: nominal,
                    );
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

  @override
  Widget build(BuildContext context) {
    final dataTampil = _tagihanTersaring;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                'Total Tagihan Terdaftar',
                '${_daftarTagihan.length} Tagihan',
                Icons.receipt_long,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 28),
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
              const SizedBox(width: 12),
              IconButton(
                onPressed: _ambilDataTagihan,
                icon: const Icon(Icons.refresh),
                tooltip: 'Muat Ulang Tagihan',
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
                        child: Center(child: Text('Belum ada data tagihan di database. Klik "Buat Tagihan Baru".')),
                      )
                    : DataTable(
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
                          final kodeInv = 'INV-${item.id.toString().padLeft(3, '0')}';
                          return DataRow(
                            cells: [
                              DataCell(Text(kodeInv, style: const TextStyle(fontWeight: FontWeight.w500))),
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
                                      onPressed: () => _hapusTagihan(item.id),
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