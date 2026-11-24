import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _atletAktif = 0;
  int _atletPrestasi = 0;
  int _pelatihAktif = 0;
  int _totalPelatih = 0;
  int _pemasukanLunas = 0;
  int _tagihanBelumLunas = 0;
  int _totalCatatanWaktu = 0;

  List _jadwalRingkas = [];
  List _waktuTerbaru = [];

  @override
  void initState() {
    super.initState();
    _muatStatistikBeranda();
  }

  Future<void> _muatStatistikBeranda() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('atlet').select(),
        _supabase.from('pelatih').select(),
        _supabase.from('jadwal_latihan').select().order('id', ascending: true),
        _supabase.from('tagihan_iuran').select(),
        _supabase.from('catatan_waktu').select().order('id', ascending: false),
      ]);

      final listAtlet = results[0] as List;
      final listPelatih = results[1] as List;
      final listJadwal = results[2] as List;
      final listIuran = results[3] as List;
      final listWaktu = results[4] as List;

      int hitungAktif = 0;
      int hitungPrestasi = 0;
      for (var a in listAtlet) {
        if (a['status'] == 'Aktif') hitungAktif++;
        final kelas = (a['kelas_latihan'] ?? '').toString();
        if (kelas.contains('Prestasi')) hitungPrestasi++;
      }

      int hitungPelatihAktif = 0;
      for (var p in listPelatih) {
        if (p['status'] == 'Aktif') hitungPelatihAktif++;
      }

      int sumLunas = 0;
      int countTunggakan = 0;
      for (var t in listIuran) {
        if (t['is_lunas'] == true) {
          sumLunas += (t['nominal'] as num?)?.toInt() ?? 0;
        } else {
          countTunggakan++;
        }
      }

      setState(() {
        _atletAktif = hitungAktif;
        _atletPrestasi = hitungPrestasi;
        _totalPelatih = listPelatih.length;
        _pelatihAktif = hitungPelatihAktif;
        _pemasukanLunas = sumLunas;
        _tagihanBelumLunas = countTunggakan;
        _totalCatatanWaktu = listWaktu.length;

        _jadwalRingkas = listJadwal.take(4).toList();
        _waktuTerbaru = listWaktu.take(4).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat ringkasan beranda: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 650;
        final isDesktop = width >= 950;

        final kartuStatistik = [
          _buildStatCard(
            judul: 'Atlet Aktif',
            nilai: '$_atletAktif Atlet',
            subjudul: '$_atletPrestasi atlet kelas prestasi',
            ikon: Icons.pool,
            warna: const Color(0xFF0284C7),
          ),
          _buildStatCard(
            judul: 'Tim Pelatih',
            nilai: '$_pelatihAktif Pelatih',
            subjudul: 'Dari total $_totalPelatih terdaftar',
            ikon: Icons.sports,
            warna: Colors.indigo,
          ),
          _buildStatCard(
            judul: 'Catatan Limit Waktu',
            nilai: '$_totalCatatanWaktu Rekor',
            subjudul: 'Tersimpan di database',
            ikon: Icons.timer,
            warna: Colors.orange,
          ),
          _buildStatCard(
            judul: 'Iuran Terkumpul',
            nilai: _formatRupiah(_pemasukanLunas),
            subjudul: '$_tagihanBelumLunas tagihan belum lunas',
            ikon: Icons.account_balance_wallet,
            warna: Colors.green,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard Pembinaan Prestasi',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Database atlet per kelas, pelatih terdaftar, limit terbaik (PB), dan administrasi lomba.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _muatStatistikBeranda,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Sinkronkan Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dashboard Pembinaan Prestasi Klub',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Kelola database atlet tiap kelas, lisensi pelatih untuk pendaftaran kejuaraan, serta catatan limit terbaik (PB).',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _muatStatistikBeranda,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Sinkronkan Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(child: kartuStatistik[0]),
                      const SizedBox(width: 16),
                      Expanded(child: kartuStatistik[1]),
                      const SizedBox(width: 16),
                      Expanded(child: kartuStatistik[2]),
                      const SizedBox(width: 16),
                      Expanded(child: kartuStatistik[3]),
                    ],
                  )
                else if (!isMobile)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: kartuStatistik[0]),
                          const SizedBox(width: 16),
                          Expanded(child: kartuStatistik[1]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: kartuStatistik[2]),
                          const SizedBox(width: 16),
                          Expanded(child: kartuStatistik[3]),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      kartuStatistik[0],
                      const SizedBox(height: 12),
                      kartuStatistik[1],
                      const SizedBox(height: 12),
                      kartuStatistik[2],
                      const SizedBox(height: 12),
                      kartuStatistik[3],
                    ],
                  ),
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPanelJadwal()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPanelWaktu()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPanelJadwal(),
                      const SizedBox(height: 16),
                      _buildPanelWaktu(),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelJadwal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Latihan Terdaftar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          if (_jadwalRingkas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Belum ada jadwal latihan.')),
            )
          else
            ..._jadwalRingkas.map((j) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0F9FF),
                    child: Icon(Icons.event_available, color: Color(0xFF0284C7), size: 20),
                  ),
                  title: Text(
                    '${j['hari']} • ${j['materi']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${j['jam']} (${j['kelompok']}) - ${j['kolam']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildPanelWaktu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Waktu Terbaru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          if (_waktuTerbaru.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Belum ada catatan waktu.')),
            )
          else
            ..._waktuTerbaru.map((w) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.speed, color: Colors.orange.shade700, size: 20),
                  ),
                  title: Text(
                    '${w['nama_atlet']} (${w['kelompok_umur']})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${w['nomor_lomba']} • ${w['tanggal_tes']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${w['waktu_detik']} dtk',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                      fontSize: 14,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String judul,
    required String nilai,
    required String subjudul,
    required IconData ikon,
    required Color warna,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Text(judul, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, color: warna, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(nilai, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subjudul, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}