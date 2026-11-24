import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IuranPage extends StatefulWidget {
  const IuranPage({super.key});

  @override
  State<IuranPage> createState() => _IuranPageState();
}

class _IuranPageState extends State<IuranPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String _filterStatus = 'Semua';
  String _kataKunci = '';

  List _daftarTagihan = [];
  List _daftarAtlet = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('tagihan_iuran').select().order('id', ascending: false),
        _supabase.from('atlet').select().order('nama', ascending: true),
      ]);

      setState(() {
        _daftarTagihan = (results[0] as List).map((e) => Map.from(e)).toList();
        _daftarAtlet = (results[1] as List).map((e) => Map.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data iuran: $e'), backgroundColor: Colors.red),
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

  String get _tanggalHariIni {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List get _tagihanMenungguVerifikasi {
    return _daftarTagihan
        .where((t) => (t['status_verifikasi'] ?? '') == 'menunggu_verifikasi')
        .toList();
  }

  List get _tagihanTersaring {
    return _daftarTagihan.where((t) {
      bool cocokStatus = true;
      if (_filterStatus == 'Menunggu Verifikasi') {
        cocokStatus = (t['status_verifikasi'] ?? '') == 'menunggu_verifikasi';
      } else if (_filterStatus == 'Lunas') {
        cocokStatus = t['is_lunas'] == true;
      } else if (_filterStatus == 'Belum Lunas') {
        cocokStatus = t['is_lunas'] != true;
      }

      final nama = (t['nama_atlet'] ?? '').toString().toLowerCase();
      final bulan = (t['bulan'] ?? '').toString().toLowerCase();
      final q = _kataKunci.toLowerCase();
      final cocokCari = q.isEmpty || nama.contains(q) || bulan.contains(q);

      return cocokStatus && cocokCari;
    }).toList();
  }

  Future<void> _verifikasiPembayaran(Map item, {required bool setujui, String catatan = ''}) async {
    try {
      await _supabase.from('tagihan_iuran').update({
        'is_lunas': setujui,
        'status_verifikasi': setujui ? 'lunas' : 'ditolak',
        'tanggal_bayar': setujui ? _tanggalHariIni : '-',
        'catatan_pembayaran': catatan,
      }).eq('id', item['id']);

      await _muatData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              setujui
                  ? 'Pembayaran ${item['nama_atlet']} (${item['bulan']}) dikonfirmasi LUNAS!'
                  : 'Bukti transfer ${item['nama_atlet']} ditolak.',
            ),
            backgroundColor: setujui ? Colors.green : Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _tampilkanPreviewBukti(Map item, bool isMobile) {
    final url = (item['bukti_transfer_url'] ?? '').toString();
    final alasanController = TextEditingController(text: (item['catatan_pembayaran'] ?? '').toString());
    final nominal = (item['nominal'] as num?)?.toInt() ?? 0;

    Widget isiKonten() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bukti Transfer • ${item['nama_atlet']}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Periode: ${item['bulan']} • Nominal: ${_formatRupiah(nominal)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
          ),
          const SizedBox(height: 12),
          if (url.isEmpty)
            const Text('Belum ada file bukti transfer yang diunggah.')
          else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 42, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text('File berbentuk PDF / Dokumen'),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tautan bukti transfer disalin!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Salin Tautan File'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: alasanController,
            decoration: InputDecoration(
              labelText: 'Catatan Admin (wajib diisi jika menolak bukti)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _verifikasiPembayaran(
                    item,
                    setujui: false,
                    catatan: alasanController.text.trim().isEmpty
                        ? 'Bukti tidak terbaca / nominal tidak sesuai, silakan unggah ulang.'
                        : alasanController.text.trim(),
                  );
                },
                icon: const Icon(Icons.close, size: 17, color: Colors.red),
                label: const Text('Tolak Bukti', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _verifikasiPembayaran(
                    item,
                    setujui: true,
                    catatan: alasanController.text.trim(),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 17),
                label: const Text('Setujui & Lunas'),
              ),
            ],
          ),
        ],
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: isiKonten()),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(child: isiKonten()),
          ),
        ),
      );
    }
  }

  void _tambahTagihanDialog(bool isMobile) {
    if (_daftarAtlet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan data atlet terlebih dahulu.')),
      );
      return;
    }

    String atletTerpilih = (_daftarAtlet.first['nama'] ?? '').toString();
    final bulanController = TextEditingController(text: 'Desember 2026');
    final nominalController = TextEditingController(text: '250000');

    Widget buildForm(StateSetter setDialogState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Buat Tagihan Iuran Baru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            key: ValueKey(atletTerpilih),
            initialValue: atletTerpilih,
            decoration: InputDecoration(
              labelText: 'Pilih Atlet',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _daftarAtlet
                .map((a) => DropdownMenuItem<String>(
                      value: (a['nama'] ?? '').toString(),
                      child: Text('${a['nama']} (${a['kelompok_umur']})', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (val) => setDialogState(() => atletTerpilih = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bulanController,
            decoration: InputDecoration(
              labelText: 'Periode Bulan (misal: Desember 2026)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nominalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nominal Iuran (Rp)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                onPressed: () async {
                  final dataAtlet = _daftarAtlet.firstWhere((a) => a['nama'] == atletTerpilih);
                  final nominal = int.tryParse(nominalController.text.replaceAll('.', '').trim()) ?? 250000;
                  Navigator.pop(context);

                  await _supabase.from('tagihan_iuran').insert({
                    'nama_atlet': atletTerpilih,
                    'kelompok_umur': (dataAtlet['kelompok_umur'] ?? '-').toString(),
                    'bulan': bulanController.text.trim(),
                    'nominal': nominal,
                    'is_lunas': false,
                    'status_verifikasi': 'belum_bayar',
                    'tanggal_bayar': '-',
                  });
                  await _muatData();
                },
                child: const Text('Simpan Tagihan'),
              ),
            ],
          ),
        ],
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
            child: buildForm(setDialogState),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: buildForm(setDialogState),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _hapusTagihan(int id) async {
    await _supabase.from('tagihan_iuran').delete().eq('id', id);
    await _muatData();
  }

  @override
  Widget build(BuildContext context) {
    final antreanVerifikasi = _tagihanMenungguVerifikasi;
    final listTampil = _tagihanTersaring;

    int totalLunas = 0;
    int totalTunggakan = 0;
    for (final t in _daftarTagihan) {
      final nom = (t['nominal'] as num?)?.toInt() ?? 0;
      if (t['is_lunas'] == true) {
        totalLunas += nom;
      } else {
        totalTunggakan += nom;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return RefreshIndicator(
          onRefresh: _muatData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu Ringkasan Interaktif (Ketuk untuk memfilter)
                GridView.count(
                  crossAxisCount: isMobile ? 1 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 12,
                  childAspectRatio: isMobile ? 3.2 : 2.3,
                  children: [
                    _kartuKeuangan(
                      'Total Iuran Lunas',
                      _formatRupiah(totalLunas),
                      Colors.green.shade700,
                      Icons.check_circle,
                      aktif: _filterStatus == 'Lunas',
                      onTap: () => setState(() => _filterStatus = _filterStatus == 'Lunas' ? 'Semua' : 'Lunas'),
                    ),
                    _kartuKeuangan(
                      'Belum Terbayar',
                      _formatRupiah(totalTunggakan),
                      Colors.red.shade700,
                      Icons.pending_actions,
                      aktif: _filterStatus == 'Belum Lunas',
                      onTap: () => setState(() => _filterStatus = _filterStatus == 'Belum Lunas' ? 'Semua' : 'Belum Lunas'),
                    ),
                    _kartuKeuangan(
                      'Menunggu Cek Bukti',
                      '${antreanVerifikasi.length} Tagihan',
                      Colors.amber.shade900,
                      Icons.receipt_long,
                      aktif: _filterStatus == 'Menunggu Verifikasi',
                      onTap: () => setState(() => _filterStatus =
                          _filterStatus == 'Menunggu Verifikasi' ? 'Semua' : 'Menunggu Verifikasi'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Antrean Bukti Transfer Baru
                if (antreanVerifikasi.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade300, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: Colors.amber.shade900),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bukti Transfer Menunggu Verifikasi (${antreanVerifikasi.length})',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: antreanVerifikasi.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = antreanVerifikasi[index];
                            final nominal = (item['nominal'] as num?)?.toInt() ?? 0;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['nama_atlet']} • ${item['bulan']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nominal: ${_formatRupiah(nominal)}',
                                        style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _tampilkanPreviewBukti(item, isMobile),
                                    icon: const Icon(Icons.image_search, size: 18),
                                    label: const Text('Periksa Bukti'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Tombol Buat Tagihan, Cari & Filter Pill
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _tambahTagihanDialog(isMobile),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Buat Tagihan Baru'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 250,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _kataKunci = val),
                        decoration: InputDecoration(
                          hintText: 'Cari atlet atau bulan...',
                          prefixIcon: const Icon(Icons.search, size: 19),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Semua', 'Menunggu Verifikasi', 'Belum Lunas', 'Lunas'].map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filterStatus == f,
                          onSelected: (_) => setState(() => _filterStatus = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Daftar Tagihan: Card List di HP, DataTable di Desktop
                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                else if (listTampil.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(child: Text('Belum ada data tagihan pada kategori ini.')),
                  )
                else if (isMobile)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listTampil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildCardIuranMobile(listTampil[index]),
                  )
                else
                  _buildTableIuranDesktop(listTampil, constraints.maxWidth - 64),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardIuranMobile(Map item) {
    final isLunas = item['is_lunas'] == true;
    final stVerif = (item['status_verifikasi'] ?? 'belum_bayar').toString();
    final buktiUrl = (item['bukti_transfer_url'] ?? '').toString();
    final nominal = (item['nominal'] as num?)?.toInt() ?? 0;

    Color warnaBadge = Colors.red.shade700;
    Color latarBadge = Colors.red.shade50;
    String labelBadge = 'Belum Lunas';

    if (isLunas || stVerif == 'lunas') {
      warnaBadge = Colors.green.shade700;
      latarBadge = Colors.green.shade50;
      labelBadge = 'Lunas (${item['tanggal_bayar']})';
    } else if (stVerif == 'menunggu_verifikasi') {
      warnaBadge = Colors.amber.shade900;
      latarBadge = Colors.amber.shade50;
      labelBadge = 'Menunggu Verifikasi';
    } else if (stVerif == 'ditolak') {
      warnaBadge = Colors.deepOrange.shade800;
      latarBadge = Colors.deepOrange.shade50;
      labelBadge = 'Bukti Ditolak';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['nama_atlet'] ?? '-').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['bulan']} • ${item['kelompok_umur']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: latarBadge, borderRadius: BorderRadius.circular(20)),
                child: Text(labelBadge, style: TextStyle(color: warnaBadge, fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatRupiah(nominal),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (buktiUrl.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _tampilkanPreviewBukti(item, true),
                    icon: const Icon(Icons.receipt, size: 16),
                    label: const Text('Lihat Bukti'),
                  ),
                ),
              if (buktiUrl.isNotEmpty && !isLunas) const SizedBox(width: 8),
              if (!isLunas)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifikasiPembayaran(item, setujui: true),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Tandai Lunas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _hapusTagihan(item['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableIuranDesktop(List listTampil, double minWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text('Nama Atlet', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Bulan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nominal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: listTampil.map((item) {
                final isLunas = item['is_lunas'] == true;
                final stVerif = (item['status_verifikasi'] ?? 'belum_bayar').toString();
                final buktiUrl = (item['bukti_transfer_url'] ?? '').toString();
                final nominal = (item['nominal'] as num?)?.toInt() ?? 0;

                Color warnaBadge = Colors.red.shade700;
                Color latarBadge = Colors.red.shade50;
                String labelBadge = 'Belum Lunas';

                if (isLunas || stVerif == 'lunas') {
                  warnaBadge = Colors.green.shade700;
                  latarBadge = Colors.green.shade50;
                  labelBadge = 'Lunas (${item['tanggal_bayar']})';
                } else if (stVerif == 'menunggu_verifikasi') {
                  warnaBadge = Colors.amber.shade900;
                  latarBadge = Colors.amber.shade50;
                  labelBadge = 'Menunggu Verifikasi';
                } else if (stVerif == 'ditolak') {
                  warnaBadge = Colors.deepOrange.shade800;
                  latarBadge = Colors.deepOrange.shade50;
                  labelBadge = 'Bukti Ditolak';
                }

                return DataRow(
                  cells: [
                    DataCell(Text('${item['nama_atlet']}\n(${item['kelompok_umur']})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    DataCell(Text((item['bulan'] ?? '-').toString())),
                    DataCell(Text(_formatRupiah(nominal), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: latarBadge, borderRadius: BorderRadius.circular(20)),
                        child: Text(labelBadge,
                            style: TextStyle(color: warnaBadge, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    DataCell(
                      buktiUrl.isNotEmpty
                          ? TextButton.icon(
                              onPressed: () => _tampilkanPreviewBukti(item, false),
                              icon: const Icon(Icons.receipt, size: 17),
                              label: const Text('Lihat Bukti'),
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isLunas)
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              tooltip: 'Tandai Lunas',
                              onPressed: () => _verifikasiPembayaran(item, setujui: true),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Hapus',
                            onPressed: () => _hapusTagihan(item['id']),
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
    );
  }

  Widget _kartuKeuangan(
    String judul,
    String nilai,
    Color warna,
    IconData ikon, {
    required bool aktif,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: aktif ? warna : const Color(0xFFE2E8F0),
              width: aktif ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: warna.withValues(alpha: 0.1),
                child: Icon(ikon, color: warna),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(judul, style: const TextStyle(color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(nilai, style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: warna)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}