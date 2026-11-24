import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'beranda_page.dart';
import 'atlet_page.dart';
import 'pelatih_page.dart';
import 'jadwal_page.dart';
import 'absensi_page.dart';
import 'catatan_waktu_page.dart';
import 'iuran_page.dart';
import 'akun_pengguna_page.dart';
import 'reset_password_page.dart';

class DashboardPage extends StatefulWidget {
  final String role; // 'admin' atau 'pelatih'
  final String namaPengguna;
  final String emailPengguna;

  const DashboardPage({
    super.key,
    this.role = 'admin',
    this.namaPengguna = 'Admin Klub',
    this.emailPengguna = '',
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  bool get _isAdmin => widget.role == 'admin';

  Color get _warnaSidebar => _isAdmin ? const Color(0xFF0F172A) : const Color(0xFF064E3B);
  Color get _warnaAksen => _isAdmin ? const Color(0xFF0284C7) : const Color(0xFF0D9488);
  Color get _warnaIkonLogo => _isAdmin ? const Color(0xFF38BDF8) : const Color(0xFF5EEAD4);

    List get _menuItems {
    if (_isAdmin) {
      return [
        {'id': 'beranda', 'title': 'Beranda', 'short': 'Beranda', 'icon': Icons.dashboard_rounded},
        {'id': 'atlet', 'title': 'Data Atlet & Kelas', 'short': 'Atlet', 'icon': Icons.pool_rounded},
        {'id': 'absensi', 'title': 'Absensi Latihan', 'short': 'Absensi', 'icon': Icons.fact_check_rounded},
        {'id': 'iuran', 'title': 'Iuran & Keuangan', 'short': 'Iuran', 'icon': Icons.payments_rounded},
        {'id': 'pelatih', 'title': 'Data Pelatih', 'short': 'Pelatih', 'icon': Icons.sports_rounded},
        {'id': 'jadwal', 'title': 'Jadwal Latihan', 'short': 'Jadwal', 'icon': Icons.calendar_month_rounded},
        {'id': 'waktu', 'title': 'Limit & Catatan Waktu', 'short': 'Limit', 'icon': Icons.timer_rounded},
        {'id': 'akun', 'title': 'Hak Akses Pengguna', 'short': 'Akses', 'icon': Icons.admin_panel_settings_rounded},
      ];
    } else {
      return [
        {'id': 'beranda_pelatih', 'title': 'Beranda Pelatih', 'short': 'Beranda', 'icon': Icons.dashboard_rounded},
        {'id': 'atlet', 'title': 'Data Atlet & Kelas', 'short': 'Atlet', 'icon': Icons.pool_rounded},
        {'id': 'absensi', 'title': 'Absensi Latihan', 'short': 'Absensi', 'icon': Icons.fact_check_rounded},
        {'id': 'waktu', 'title': 'Limit & Catatan Waktu', 'short': 'Limit', 'icon': Icons.timer_rounded},
        {'id': 'jadwal', 'title': 'Jadwal Latihan', 'short': 'Jadwal', 'icon': Icons.calendar_month_rounded},
      ];
    }
  }

  void _pindahKeMenuId(String id) {
    final idx = _menuItems.indexWhere((m) => m['id'] == id);
    if (idx != -1) {
      setState(() => _selectedIndex = idx);
    }
  }

  Future<void> _konfirmasiLogout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Kamu harus memasukkan email dan kata sandi lagi untuk mengakses aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final daftarMenu = _menuItems;
    if (_selectedIndex >= daftarMenu.length) {
      _selectedIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;
        final bottomNavIndex = _selectedIndex < 4 ? _selectedIndex : 4;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isMobile
              ? Drawer(
                  width: 270,
                  backgroundColor: _warnaSidebar,
                  child: SafeArea(child: _buildSidebarContent(isDrawer: true)),
                )
              : null,
          bottomNavigationBar: isMobile
              ? NavigationBar(
                  height: 66,
                  backgroundColor: Colors.white,
                  elevation: 8,
                  indicatorColor: _warnaAksen.withValues(alpha: 0.15),
                  selectedIndex: bottomNavIndex,
                  onDestinationSelected: (idx) {
                    if (idx < 4) {
                      setState(() => _selectedIndex = idx);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                  destinations: [
                    for (int i = 0; i < 4; i++)
                      NavigationDestination(
                        icon: Icon(daftarMenu[i]['icon'] as IconData),
                        selectedIcon: Icon(daftarMenu[i]['icon'] as IconData, color: _warnaAksen),
                        label: daftarMenu[i]['short'] as String,
                      ),
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_rounded),
                      selectedIcon: Icon(Icons.grid_view_rounded, color: _warnaAksen),
                      label: 'Lainnya',
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (!isMobile)
                Container(
                  width: 255,
                  color: _warnaSidebar,
                  child: _buildSidebarContent(isDrawer: false),
                ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: isMobile ? 62 : 70,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            if (isMobile) ...[
                              IconButton(
                                icon: Icon(Icons.menu_rounded, color: _warnaSidebar, size: 26),
                                tooltip: 'Buka Semua Menu',
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                daftarMenu[_selectedIndex]['title'] as String,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 17.5 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _warnaAksen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isAdmin ? 'ADMIN' : 'PELATIH',
                                style: TextStyle(
                                  color: _warnaAksen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(daftarMenu[_selectedIndex]['id']),
                          child: _buildBodyContent(daftarMenu[_selectedIndex]['id'] as String),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent({required bool isDrawer}) {
    final daftarMenu = _menuItems;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.waves, color: _warnaIkonLogo, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isAdmin ? 'AQUA CLUB\nADMIN PANEL' : 'AQUA CLUB\nCOACH AREA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: daftarMenu.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: isSelected ? _warnaAksen : Colors.transparent,
                  leading: Icon(
                    daftarMenu[index]['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                  title: Text(
                    daftarMenu[index]['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (isDrawer) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black26,
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _warnaAksen,
                    child: Icon(_isAdmin ? Icons.admin_panel_settings : Icons.sports, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.namaPengguna,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.emailPengguna,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (isDrawer) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordPage(isRecoveryMode: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_reset_rounded, size: 16, color: Colors.white70),
                  label: const Text('Ganti Kata Sandi', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _konfirmasiLogout,
                  icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(String menuId) {
    switch (menuId) {
      case 'beranda':
        return BerandaPage();
      case 'beranda_pelatih':
        return _BerandaPelatihView(
          namaPelatih: widget.namaPengguna,
          onNavigateMenu: _pindahKeMenuId,
        );
      case 'atlet':
        return AtletPage();
      case 'pelatih':
        return PelatihPage();
      case 'jadwal':
        return JadwalPage();
      case 'absensi':
        return AbsensiPage(namaPencatat: widget.namaPengguna);
      case 'waktu':
        return CatatanWaktuPage();
      case 'iuran':
        return IuranPage();
      case 'akun':
        return AkunPenggunaPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BerandaPelatihView extends StatefulWidget {
  final String namaPelatih;
  final Function(String menuId) onNavigateMenu;

  const _BerandaPelatihView({
    required this.namaPelatih,
    required this.onNavigateMenu,
  });

  @override
  State<_BerandaPelatihView> createState() => _BerandaPelatihViewState();
}

class _BerandaPelatihViewState extends State<_BerandaPelatihView> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  int _totalAtlet = 0;
  int _atletPrestasi = 0;
  int _totalSesi = 0;
  int _totalRekor = 0;

  @override
  void initState() {
    super.initState();
    _muatRingkasanPelatih();
  }

  Future<void> _muatRingkasanPelatih() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        _supabase.from('atlet').select(),
        _supabase.from('jadwal_latihan').select(),
        _supabase.from('catatan_waktu').select(),
      ]);

      final listAtlet = res[0] as List;
      int prestasi = 0;
      for (final a in listAtlet) {
        if ((a['kelas_latihan'] ?? '').toString().contains('Prestasi')) prestasi++;
      }

      if (mounted) {
        setState(() {
          _totalAtlet = listAtlet.length;
          _atletPrestasi = prestasi;
          _totalSesi = (res[1] as List).length;
          _totalRekor = (res[2] as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _muatRingkasanPelatih,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          final daftarKartu = [
            _kartuPelatih(
              'Total Atlet Binaan',
              '$_totalAtlet Atlet',
              '$_atletPrestasi atlet kelas prestasi',
              Icons.pool,
              const Color(0xFF0D9488),
              () => widget.onNavigateMenu('atlet'),
            ),
            _kartuPelatih(
              'Jadwal Latihan',
              '$_totalSesi Sesi',
              'Terdaftar di kolam',
              Icons.calendar_month,
              Colors.indigo,
              () => widget.onNavigateMenu('jadwal'),
            ),
            _kartuPelatih(
              'Catatan Limit Waktu',
              '$_totalRekor Rekor',
              'Data time trial & lomba',
              Icons.timer,
              Colors.orange.shade800,
              () => widget.onNavigateMenu('waktu'),
            ),
          ];

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20 : 26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Bertugas, Coach ${widget.namaPelatih}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18.5 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Catat absensi latihan harian, pantau performa atlet tiap kelas, dan perbarui limit terbaik (PB).',
                        style: TextStyle(color: Colors.white70, fontSize: 13.5),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => widget.onNavigateMenu('absensi'),
                            icon: const Icon(Icons.fact_check_rounded, size: 18),
                            label: const Text('Mulai Absensi Hari Ini'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF064E3B),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => widget.onNavigateMenu('waktu'),
                            icon: const Icon(Icons.timer_rounded, size: 18, color: Colors.white),
                            label: const Text('Input Limit Waktu', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (isMobile)
                  Column(
                    children: [
                      daftarKartu[0],
                      const SizedBox(height: 12),
                      daftarKartu[1],
                      const SizedBox(height: 12),
                      daftarKartu[2],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: daftarKartu[0]),
                      const SizedBox(width: 14),
                      Expanded(child: daftarKartu[1]),
                      const SizedBox(width: 14),
                      Expanded(child: daftarKartu[2]),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kartuPelatih(
    String judul,
    String nilai,
    String sub,
    IconData ikon,
    Color warna,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      judul,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Icon(ikon, color: warna),
                ],
              ),
              const SizedBox(height: 8),
              Text(nilai, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: warna),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}