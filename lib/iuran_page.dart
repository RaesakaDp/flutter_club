import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'export_helper.dart';

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

  factory TagihanIuran.fromMap(Map map) {
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

  void _eksporCsvIuran() {
    final dataTampil = _tagihanTersaring;
    if (dataTampil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data tagihan untuk diekspor.')),
      );
      return;
    }

    final List<List> baris = [
      ['No. Invoice', 'Nama Atlet', 'Kelompok Umur', 'Periode', 'Nominal (Rp)', 'Status', 'Tanggal Bayar'],
    ];

    for (final item in dataTampil) {
      final kodeInv = 'INV-${item.id.toString().padLeft(3, '0')}';
      baris.add([
        kodeInv,
        item.namaAtlet,
        item.kelompokUmur,
        item.bulan,
        item.nominal,
        item.isLunas ? 'Lunas' : 'Belum Lunas',
        item.tanggalBayar,
      ]);
    }

    unduhFileCsv('laporan_iuran_aqua_club.csv', baris);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan iuran (CSV) berhasil diunduh!'), backgroundColor: Colors.green),
    );
  }

  void _tampilkanKwitansi(TagihanIuran item) {
    final kodeInv = 'INV-${item.id.toString().padLeft(3, '0')}';
    final statusTeks = item.isLunas ? 'LUNAS' : 'BELUM LUNAS';
    final nominalTeks = _formatRupiah(item.nominal);

    final pesanWa = '''
*KWITANSI IURAN - AQUA CLUB*
No. Invoice : $kodeInv
Nama Atlet  : ${item.namaAtlet} (${item.kelompokUmur})
Periode     : ${item.bulan}
Nominal     : $nominalTeks
Status      : *$statusTeks*
Tgl Bayar   : ${item.tanggalBayar}

Terima kasih atas dukungan & kerjasamanya.''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.waves, color: Color(0xFF38BDF8), size: 32),
                    const SizedBox(height: 6),
                    const Text(
                      'AQUA CLUB MANAGER',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    Text(
                      'Bukti Tagihan & Pembayaran ($kodeInv)',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _barisKwitansi('Nama Atlet', item.namaAtlet),
                    _barisKwitansi('Kelompok Umur', item.kelompokUmur),
                    _barisKwitansi('Periode Bulan', item.bulan),
                    _barisKwitansi('Tanggal Bayar', item.tanggalBayar),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Iuran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          nominalTeks,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: item.isLunas ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: item.isLunas ? Colors.green.shade300 : Colors.red.shade300),
                      ),
                      child: Text(
                        statusTeks,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: item.isLunas ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pesanWa));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teks kwitansi disalin! Tinggal tempel (Paste) di WhatsApp.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin untuk WA'),
          ),
        ],
      ),
    );
  }

  Widget _barisKwitansi(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(nilai, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
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
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final kartuKeuangan = [
          _buildFinanceCard(
            'Total Pemasukan Terkumpul',
            _formatRupiah(_totalPemasukan),
            Icons.account_balance_wallet,
            Colors.green,
          ),
          _buildFinanceCard(
            'Total Iuran Tertunggak',
            _formatRupiah(_totalTertunggak),
            Icons.pending_actions,
            Colors.orange,
          ),
          _buildFinanceCard(
            'Total Tagihan Terdaftar',
            '${_daftarTagihan.length} Tagihan',
            Icons.receipt_long,
            Colors.blue,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  children: [
                    kartuKeuangan[0],
                    const SizedBox(height: 12),
                    kartuKeuangan[1],
                    const SizedBox(height: 12),
                    kartuKeuangan[2],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: kartuKeuangan[0]),
                    const SizedBox(width: 20),
                    Expanded(child: kartuKeuangan[1]),
                    const SizedBox(width: 20),
                    Expanded(child: kartuKeuangan[2]),
                  ],
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  IconButton(
                    onPressed: _ambilDataTagihan,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang Tagihan',
                  ),
                  OutlinedButton.icon(
                    onPressed: _eksporCsvIuran,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Ekspor Excel'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _tambahTagihanBaru,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Buat Tagihan Baru'),
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
                                'Belum ada data tagihan di database. Klik "Buat Tagihan Baru".',
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
                                            mainAxisSize: MainAxisSize.min,
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
                                                icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 20),
                                                tooltip: 'Lihat Kwitansi',
                                                onPressed: () => _tampilkanKwitansi(item),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                tooltip: 'Hapus',
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
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}