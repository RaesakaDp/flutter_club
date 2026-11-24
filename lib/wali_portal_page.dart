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
  int _tabIndex = 0;

  List _semuaAtlet = [];
  List _semuaWaktu = [];
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
        _semuaJadwal = results[2] as List;
        _semuaIuran = results[3] as List;
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

  void _lihatKwitansi(Map item) {
    final kodeInv = 'INV-${(item['id'] ?? 0).toString().padLeft(3, '0')}';
    final isLunas = item['is_lunas'] == true;
    final nominal = (item['nominal'] as num?)?.toInt() ?? 0;
    final nominalTeks = _formatRupiah(nominal);

    final pesanKonfirmasi = '''
*KONFIRMASI IURAN - AQUA CLUB*
No. Invoice : $kodeInv
Nama Atlet  : ${item['nama_atlet']} (${item['kelompok_umur']})
Periode     : ${item['bulan']}
Nominal     : $nominalTeks
Status      : ${isLunas ? 'LUNAS' : 'BELUM LUNAS'}
Tgl Bayar   : ${item['tanggal_bayar'] ?? '-'}''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rincian Tagihan ($kodeInv)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atlet: ${item['nama_atlet']} (${item['kelompok_umur']})'),
            const SizedBox(height: 6),
            Text('Periode: ${item['bulan']}'),
            const SizedBox(height: 6),
            Text('Nominal: $nominalTeks', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Status: ${isLunas ? 'LUNAS (${item['tanggal_bayar']})' : 'BELUM LUNAS'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pesanKonfirmasi));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rincian disalin untuk dikirim ke Admin via WhatsApp!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin Rincian'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilAtlet = _profilAtletAktif;
    final listPB = _limitTerbaikAnak;
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
            Text('Portal Wali Atlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            label: const Text('Keluar', style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 20 : 26),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${widget.namaWali}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pantau perkembangan limit renang, jadwal latihan, dan status administrasi atlet.',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                ),
                                const SizedBox(height: 18),
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
                                                  child: Text('Atlet: ${a['nama']} (${a['kelompok_umur']})'),
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
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _atletTerpilih.isEmpty ? 'Atlet Belum Ditautkan' : _atletTerpilih,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                profilAtlet != null
                                                    ? '${profilAtlet['kelas_latihan']} • ${profilAtlet['kelompok_umur']} • Spesialis ${profilAtlet['gaya_utama']}'
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
                          const SizedBox(height: 20),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                label: Text('Limit Terbaik Anak (${listPB.length})'),
                                selected: _tabIndex == 0,
                                selectedColor: const Color(0xFF4F46E5),
                                labelStyle: TextStyle(
                                  color: _tabIndex == 0 ? Colors.white : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) => setState(() => _tabIndex = 0),
                              ),
                              ChoiceChip(
                                label: Text('Jadwal Latihan (${_semuaJadwal.length})'),
                                selected: _tabIndex == 1,
                                selectedColor: const Color(0xFF4F46E5),
                                labelStyle: TextStyle(
                                  color: _tabIndex == 1 ? Colors.white : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) => setState(() => _tabIndex = 1),
                              ),
                              ChoiceChip(
                                label: Text('Status Iuran (${listTagihan.length})'),
                                selected: _tabIndex == 2,
                                selectedColor: const Color(0xFF4F46E5),
                                labelStyle: TextStyle(
                                  color: _tabIndex == 2 ? Colors.white : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) => setState(() => _tabIndex = 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (_tabIndex == 0) _buildTabLimitAnak(listPB),
                          if (_tabIndex == 1) _buildTabJadwalKlub(),
                          if (_tabIndex == 2) _buildTabIuranAnak(listTagihan),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.emoji_events, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['nomor_lomba'] ?? '-').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tercapai pada ${item['tanggal_tes']}${punyaTarget ? ' • Target Limit: $target dtk' : ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$detik dtk',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${j['hari']} • ${j['jam']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
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

  Widget _buildTabIuranAnak(List listTagihan) {
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
        final nominal = (item['nominal'] as num?)?.toInt() ?? 0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iuran Bulan ${item['bulan']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatRupiah(nominal)} • ${isLunas ? 'Dibayar tgl ${item['tanggal_bayar']}' : 'Menunggu pembayaran'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLunas ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLunas ? 'Lunas' : 'Belum Lunas',
                  style: TextStyle(
                    color: isLunas ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Color(0xFF4F46E5)),
                tooltip: 'Rincian / Kwitansi',
                onPressed: () => _lihatKwitansi(item),
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