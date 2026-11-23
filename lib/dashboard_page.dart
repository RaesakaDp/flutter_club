import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'beranda_page.dart';
import 'atlet_page.dart';
import 'jadwal_page.dart';
import 'catatan_waktu_page.dart';
import 'iuran_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List _menuItems = [
    {'title': 'Beranda', 'icon': Icons.dashboard_rounded},
    {'title': 'Data Atlet', 'icon': Icons.pool_rounded},
    {'title': 'Jadwal Latihan', 'icon': Icons.calendar_month_rounded},
    {'title': 'Catatan Waktu', 'icon': Icons.timer_rounded},
    {'title': 'Iuran & Keuangan', 'icon': Icons.payments_rounded},
  ];

  Future<void> _konfirmasiLogout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Kamu harus memasukkan email dan kata sandi lagi untuk mengakses dashboard.'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

        return Scaffold(
          key: _scaffoldKey,
          // Drawer otomatis muncul hanya saat dibuka di layar HP
          drawer: isMobile
              ? Drawer(
                  width: 260,
                  backgroundColor: const Color(0xFF0F172A),
                  child: SafeArea(child: _buildSidebarContent(isDrawer: true)),
                )
              : null,
          body: Row(
            children: [
              // Sidebar permanen hanya muncul di Laptop / Desktop
              if (!isMobile)
                Container(
                  width: 250,
                  color: const Color(0xFF0F172A),
                  child: _buildSidebarContent(isDrawer: false),
                ),

              // Area Konten Utama
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: isMobile ? 64 : 70,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
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
                                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 26),
                                tooltip: 'Buka Menu',
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                _menuItems[_selectedIndex]['title'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isMobile)
                              IconButton(
                                onPressed: () => setState(() => _selectedIndex = 1),
                                icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0284C7)),
                                tooltip: 'Tambah Atlet',
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => setState(() => _selectedIndex = 1),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Aksi Cepat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildBodyContent(),
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
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Admin Klub';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: const Row(
            children: [
              Icon(Icons.waves, color: Color(0xFF38BDF8), size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AQUA CLUB\nMANAGER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 16),

        // Daftar Menu Navigasi
        Expanded(
          child: ListView.builder(
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
                  leading: Icon(
                    _menuItems[index]['icon'],
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                  title: Text(
                    _menuItems[index]['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (isDrawer) {
                      Navigator.pop(context); // Tutup drawer otomatis di HP
                    }
                  },
                ),
              );
            },
          ),
        ),

        // Info Pengguna & Tombol Logout di Bawah Sidebar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black26,
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF0284C7),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admin Klub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(
                          userEmail,
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

  Widget _buildBodyContent() {
    if (_selectedIndex == 0) {
      return const BerandaPage();
    } else if (_selectedIndex == 1) {
      return const AtletPage();
    } else if (_selectedIndex == 2) {
      return const JadwalPage();
    } else if (_selectedIndex == 3) {
      return const CatatanWaktuPage();
    } else if (_selectedIndex == 4) {
      return const IuranPage();
    }
    return const SizedBox();
  }
}