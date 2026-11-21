import 'package:flutter/material.dart';

void main() {
  runApp(const AplikasiWebSaya());
}

class AplikasiWebSaya extends StatelessWidget {
  const AplikasiWebSaya({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web App Pertama',
      debugShowCheckedModeBanner: false, // Menghilangkan pita "DEBUG" di pojok kanan atas
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HalamanBeranda(),
    );
  }
}

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Web Saya'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selamat Datang di Aplikasi Web Flutter!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Logika saat tombol diklik ditulis di sini
                print('Tombol berhasil ditekan!');
              },
              child: const Text('Mulai Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}