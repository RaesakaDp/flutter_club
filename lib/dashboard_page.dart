import 'package:flutter/material.dart';
import 'atlet_page.dart';
import 'jadwal_page.dart';
import 'catatan_waktu_page.dart'; // <-- Tambahkan ini
import 'iuran_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Menggunakan List biasa agar aman dari error tipe data
  final List _menuItems = [
    {'title': 'Beranda', 'icon': Icons.dashboard_rounded},
    {'title': 'Data Atlet', 'icon': Icons.pool_rounded},
    {'title': 'Jadwal Latihan', 'icon': Icons.calendar_month_rounded},
    {'title': 'Catatan Waktu', 'icon': Icons.timer_rounded},
    {'title': 'Iuran & Keuangan', 'icon': Icons.payments_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. SIDEBAR (MENU SAMPING KIRI)
          Container(
            width: 250,
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Info Pengguna di Bagian Bawah Sidebar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black26,
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF0284C7),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Klub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Pelatih Kepala', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          // 2. AREA KONTEN UTAMA (KANAN)
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _menuItems[_selectedIndex]['title'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Aksi Cepat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      )
                    ],
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
  }

Widget _buildBodyContent() {
    if (_selectedIndex == 0) {
      return _buildBerandaView();
    } else if (_selectedIndex == 1) {
      return const AtletPage();
    } else if (_selectedIndex == 2) {
      return const JadwalPage();
    } else if (_selectedIndex == 3) {
      return const CatatanWaktuPage(); // <-- Menu Catatan Waktu terhubung ke Supabase
    } else if (_selectedIndex == 4) {
      return const IuranPage();
    }
    return const SizedBox();
  }

  Widget _buildBerandaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard('Total Atlet Aktif', '124 Atlet', Icons.groups, Colors.blue),
              const SizedBox(width: 20),
              _buildStatCard('Pelatih Terdaftar', '8 Pelatih', Icons.sports, Colors.teal),
              const SizedBox(width: 20),
              _buildStatCard('Sesi Latihan Hari Ini', '4 Sesi', Icons.pool, Colors.orange),
              const SizedBox(width: 20),
              _buildStatCard('Iuran Bulan Ini', '92% Lunas', Icons.check_circle, Colors.green),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Latihan Hari Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.access_time_filled, color: Color(0xFF0284C7)),
                  title: Text('Kelompok Umur 1 & 2 (Prestasi) - Gaya Bebas & Kupu-kupu'),
                  subtitle: Text('Pukul 15:30 - 17:30 WIB • Kolam Utama (Lintasan 1-4) • Coach Budi'),
                  trailing: Chip(label: Text('Berlangsung')),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.access_time, color: Colors.grey),
                  title: Text('Kelas Pemula & Dasar - Teknik Pernapasan & Meluncur'),
                  subtitle: Text('Pukul 16:00 - 17:00 WIB • Kolam Latih • Coach Sari'),
                  trailing: Chip(label: Text('Terjadwal')),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                color: color.withOpacity(0.1),
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
            )
          ],
        ),
      ),
    );
  }
}