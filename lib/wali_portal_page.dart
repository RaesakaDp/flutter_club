import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_page.dart';

class WaliPortalPage extends StatefulWidget {
  final String namaWali;
  final String emailWali;
  final String namaAtletTerkait;

  const WaliPortalPage({
    super.key,
    required this.namaWali,
    required this.emailWali,
    required this.namaAtletTerkait,
  });

  @override
  State<WaliPortalPage> createState() => _WaliPortalPageState();
}

class _WaliPortalPageState extends State<WaliPortalPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  int? _uploadingTagihanId;
  int _tabIndex = 0;

  List _semuaAtlet = [];
  List _semuaWaktu = [];
  List _semuaAbsensi = [];
  List _semuaJadwal = [];
  List _semuaIuran = [];

  String _atletTerpilih = '';

  @override
  void initState() {
    super.initState();
    _atletTerpilih = widget.namaAtletTerkait;
    _muatDataPortal();
  }

  Future<void> _muatDataPortal() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('atlet').select().order('nama', ascending: true),
        _supabase.from('catatan_waktu').select().order('id', ascending: false),
        _supabase.from('absensi_latihan').select().order('tanggal', ascending: false),
        _supabase.from('jadwal_latihan').select().order('id', ascending: true),
        _supabase.from('tagihan_iuran').select().order('id', ascending: false),
      ]);

      final listAtlet = results[0] as List;
      String pilihAwal = _atletTerpilih;
      if (pilihAwal.isEmpty && listAtlet.isNotEmpty) {
        pilihAwal = (listAtlet.first['nama'] ?? '').toString();
      }

      setState(() {
        _semuaAtlet = listAtlet;
        _semuaWaktu = results[1] as List;
        _semuaAbsensi = results[2] as List;
        _semuaJadwal = results[3] as List;
        _semuaIuran = results[4] as List;
        _atletTerpilih = pilihAwal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data portal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map? get _profilAtletAktif {
    for (final a in _semuaAtlet) {
      if ((a['nama'] ?? '').toString().toLowerCase() == _atletTerpilih.trim().toLowerCase()) {
        return a as Map;
      }
    }
    return null;
  }

  List get _limitTerbaikAnak {
    final Map<String, Map> pbMap = {};
    for (final item in _semuaWaktu) {
      final nama = (item['nama_atlet'] ?? '').toString().trim().toLowerCase();
      if (nama != _atletTerpilih.trim().toLowerCase()) continue;

      final nomor = (item['nomor_lomba'] ?? '').toString();
      final detik = (item['waktu_detik'] as num?)?.toDouble() ?? 9999.0;
      if (!pbMap.containsKey(nomor) || detik < ((pbMap[nomor]!['waktu_detik'] as num?)?.toDouble() ?? 9999.0)) {
        pbMap[nomor] = Map<String, dynamic>.from(item);
      }
    }
    return pbMap.values.toList();
  }

  List get _absensiAnak {
    return _semuaAbsensi.where((a) {
      final nama = (a['nama_atlet'] ?? '').toString().trim().toLowerCase();
      return nama == _atletTerpilih.trim().toLowerCase();
    }).toList();
  }

  List get _tagihanAnak {
    return _semuaIuran.where((t) {
      final nama = (t['nama_atlet'] ?? '').toString().trim().toLowerCase();
      return nama == _atletTerpilih.trim().toLowerCase();
    }).toList();
  }

  String _formatRupiah(int angka) {
    final teks = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $teks';
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> _uploadBuktiTransfer(Map item) async {
    final tagihanId = item['id'] as int;

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );

      if (picked.isEmpty) return;
      final file = picked.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      setState(() => _uploadingTagihanId = tagihanId);

      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = ext == 'pdf'
          ? 'application/pdf'
          : (ext == 'png' ? 'image/png' : 'image/jpeg');
      final namaFile = 'tagihan_${tagihanId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage.from('bukti_transfer').uploadBinary(
            namaFile,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = _supabase.storage.from('bukti_transfer').getPublicUrl(namaFile);

      await _supabase.from('tagihan_iuran').update({
        'bukti_transfer_url': publicUrl,
        'status_verifikasi': 'menunggu_verifikasi',
        'catatan_pembayaran': '',
      }).eq('id', tagihanId);

      setState(() => _uploadingTagihanId = null);
      await _muatDataPortal();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti transfer berhasil diunggah! Menunggu verifikasi Admin.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _uploadingTagihanId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah bukti transfer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _lihatBuktiDanKwitansi(Map item, bool isMobile) {
    final kodeInv = 'INV-${(item['id'] ?? 0).toString().padLeft(3, '0')}';
    final isLunas = item['is_lunas'] == true;
    final nominal = (item['nominal'] as num?)?.toInt() ?? 0;
    final nominalTeks = _formatRupiah(nominal);
    final buktiUrl = (item['bukti_transfer_url'] ?? '').toString();

    final pesanKonfirmasi = '''
*KONFIRMASI IURAN - AQUA CLUB*
No. Invoice : $kodeInv
Nama Atlet  : ${item['nama_atlet']} (${item['kelompok_umur']})
Periode     : ${item['bulan']}
Nominal     : $nominalTeks
Status      : ${isLunas ? 'LUNAS' : 'MENUNGGU VERIFIKASI'}
Tgl Bayar   : ${item['tanggal_bayar'] ?? '-'}''';

    Widget kontenRincian() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rincian Tagihan ($kodeInv)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Atlet: ${item['nama_atlet']} (${item['kelompok_umur']})'),
          const SizedBox(height: 6),
          Text('Periode: ${item['bulan']}'),
          const SizedBox(height: 6),
          Text('Nominal: $nominalTeks', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Status: ${isLunas ? 'LUNAS (${item['tanggal_bayar']})' : 'Menunggu Verifikasi Admin'}'),
          if (buktiUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Bukti Transfer Terunggah:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  buktiUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Bukti transfer tersimpan (Format PDF)')),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pesanKonfirmasi));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rincian disalin!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin Rincian'),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(child: kontenRincian()),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(child: kontenRincian()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilAtlet = _profilAtletAktif;
    final listPB = _limitTerbaikAnak;
    final listAbsensi = _absensiAnak;
    final listTagihan = _tagihanAnak;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.waves, color: Color(0xFF818CF8)),
            SizedBox(width: 10),
            Text('Portal Wali Atlet', style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _muatDataPortal,
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResetPasswordPage(isRecoveryMode: true),
                ),
              );
            },
            icon: const Icon(Icons.lock_reset_rounded),
            tooltip: 'Ganti Kata Sandi',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return RefreshIndicator(
                  onRefresh: _muatDataPortal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kartu Identitas Wali & Atlet
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isMobile ? 18 : 26),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${widget.namaWali}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 18.5 : 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pantau limit renang, kehadiran latihan harian, dan pembayaran iuran atlet.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  if (widget.namaAtletTerkait.isEmpty && _semuaAtlet.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _atletTerpilih,
                                          isExpanded: true,
                                          items: _semuaAtlet
                                              .map((a) => DropdownMenuItem<String>(
                                                    value: (a['nama'] ?? '').toString(),
                                                    child: Text('Atlet: ${a['nama']} (${a['kelompok_umur']})',
                                                        overflow: TextOverflow.ellipsis),
                                                  ))
                                              .toList(),
                                          onChanged: (val) => setState(() => _atletTerpilih = val!),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.pool, color: Color(0xFF4F46E5)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _atletTerpilih.isEmpty ? 'Atlet Belum Ditautkan' : _atletTerpilih,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  profilAtlet != null
                                                      ? '${profilAtlet['kelas_latihan']} • ${profilAtlet['kelompok_umur']} • ${profilAtlet['gaya_utama']}'
                                                      : 'Hubungi admin klub untuk menautkan profil atlet.',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Bilah Navigasi Tab Scrollable untuk HP
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _tabPill(0, Icons.emoji_events_outlined, 'Limit (${listPB.length})'),
                                  const SizedBox(width: 8),
                                  _tabPill(1, Icons.fact_check_outlined, 'Absensi (${listAbsensi.length})'),
                                  const SizedBox(width: 8),
                                  _tabPill(2, Icons.calendar_month_outlined, 'Jadwal (${_semuaJadwal.length})'),
                                  const SizedBox(width: 8),
                                  _tabPill(3, Icons.payments_outlined, 'Iuran (${listTagihan.length})'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: KeyedSubtree(
                                key: ValueKey(_tabIndex),
                                child: _tabIndex == 0
                                    ? _buildTabLimitAnak(listPB)
                                    : _tabIndex == 1
                                        ? _buildTabAbsensiAnak(listAbsensi)
                                        : _tabIndex == 2
                                            ? _buildTabJadwalKlub()
                                            : _buildTabIuranAnak(listTagihan, isMobile),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _tabPill(int idx, IconData icon, String label) {
    final selected = _tabIndex == idx;
    return InkWell(
      onTap: () => setState(() => _tabIndex = idx),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : const Color(0xFF475569)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabLimitAnak(List listPB) {
    if (listPB.isEmpty) {
      return _buildEmptyBox('Belum ada catatan waktu / limit terbaik untuk $_atletTerpilih.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listPB.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = listPB[index];
        final detik = (item['waktu_detik'] as num?)?.toDouble() ?? 0.0;
        final target = (item['target_limit'] as num?)?.toDouble();
        final punyaTarget = target != null && target > 0;
        final lolos = punyaTarget && detik <= target;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.emoji_events, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['nomor_lomba'] ?? '-').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tgl ${item['tanggal_tes']}${punyaTarget ? ' • Limit: $target dtk' : ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$detik dtk',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                  if (punyaTarget) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: lolos ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lolos ? 'Lolos Limit' : 'Belum Limit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: lolos ? Colors.green.shade700 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabAbsensiAnak(List listAbsensi) {
    if (listAbsensi.isEmpty) {
      return _buildEmptyBox('Belum ada catatan absensi latihan untuk $_atletTerpilih.');
    }

    int hadir = 0, izin = 0, sakit = 0, alpa = 0;
    for (final a in listAbsensi) {
      final st = (a['status'] ?? '').toString();
      if (st == 'Hadir') hadir++;
      if (st == 'Izin') izin++;
      if (st == 'Sakit') sakit++;
      if (st == 'Alpa') alpa++;
    }
    final rasio = listAbsensi.isEmpty ? 0.0 : hadir / listAbsensi.length;
    final persen = (rasio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tingkat Kehadiran Latihan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    '$persen% ($hadir/${listAbsensi.length} sesi)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: rasio),
                duration: const Duration(milliseconds: 450),
                builder: (context, val, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chipAbsensi('Hadir: $hadir', Colors.green.shade700, Colors.green.shade50),
                  _chipAbsensi('Izin: $izin', Colors.blue.shade700, Colors.blue.shade50),
                  _chipAbsensi('Sakit: $sakit', Colors.orange.shade800, Colors.orange.shade50),
                  _chipAbsensi('Alpa: $alpa', Colors.red.shade700, Colors.red.shade50),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listAbsensi.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = listAbsensi[index];
            final status = (item['status'] ?? 'Hadir').toString();
            final catatan = (item['catatan'] ?? '').toString();

            Color warna = Colors.green.shade700;
            Color latar = Colors.green.shade50;
            if (status == 'Izin') {
              warna = Colors.blue.shade700;
              latar = Colors.blue.shade50;
            } else if (status == 'Sakit') {
              warna = Colors.orange.shade800;
              latar = Colors.orange.shade50;
            } else if (status == 'Alpa') {
              warna = Colors.red.shade700;
              latar = Colors.red.shade50;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['tanggal']} • ${item['sesi_label']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (catatan.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan pelatih: $catatan',
                            style: const TextStyle(color: Colors.grey, fontSize: 12.5, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      status,
                      style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _chipAbsensi(String teks, Color warna, Color latar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(20)),
      child: Text(teks, style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTabJadwalKlub() {
    if (_semuaJadwal.isEmpty) {
      return _buildEmptyBox('Belum ada jadwal latihan yang dipublikasikan.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _semuaJadwal.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final j = _semuaJadwal[index];
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${j['hari']} • ${j['jam']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    ),
                  ),
                  Chip(
                    label: Text((j['kelompok'] ?? '-').toString(), style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text((j['materi'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                'Lokasi: ${j['kolam']} • Pelatih: ${j['pelatih']}',
                style: const TextStyle(color: Colors.grey, fontSize: 12.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabIuranAnak(List listTagihan, bool isMobile) {
    if (listTagihan.isEmpty) {
      return _buildEmptyBox('Belum ada riwayat tagihan iuran untuk $_atletTerpilih.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listTagihan.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = listTagihan[index] as Map;
        final isLunas = item['is_lunas'] == true;
        final stVerif = (item['status_verifikasi'] ?? 'belum_bayar').toString();
        final catatan = (item['catatan_pembayaran'] ?? '').toString();
        final nominal = (item['nominal'] as num?)?.toInt() ?? 0;
        final isUploading = _uploadingTagihanId == item['id'];

        Color warnaBadge = Colors.red.shade700;
        Color latarBadge = Colors.red.shade50;
        String labelStatus = 'Belum Lunas';

        if (isLunas || stVerif == 'lunas') {
          warnaBadge = Colors.green.shade700;
          latarBadge = Colors.green.shade50;
          labelStatus = 'Lunas';
        } else if (stVerif == 'menunggu_verifikasi') {
          warnaBadge = Colors.amber.shade900;
          latarBadge = Colors.amber.shade50;
          labelStatus = 'Menunggu Verifikasi';
        } else if (stVerif == 'ditolak') {
          warnaBadge = Colors.deepOrange.shade800;
          latarBadge = Colors.deepOrange.shade50;
          labelStatus = 'Ditolak - Unggah Ulang';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Iuran ${item['bulan']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatRupiah(nominal)} • ${isLunas ? 'Dibayar tgl ${item['tanggal_bayar']}' : 'Silakan unggah bukti transfer'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: latarBadge, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      labelStatus,
                      style: TextStyle(color: warnaBadge, fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                ],
              ),

              if (catatan.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Catatan Admin: $catatan',
                    style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (!isLunas)
                    ElevatedButton.icon(
                      onPressed: isUploading ? null : () => _uploadBuktiTransfer(item),
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(
                        isUploading
                            ? 'Mengunggah...'
                            : (stVerif == 'menunggu_verifikasi' ? 'Ganti Bukti Transfer' : 'Upload Bukti Transfer'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _lihatBuktiDanKwitansi(item, isMobile),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Lihat Bukti & Rincian'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyBox(String pesan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}