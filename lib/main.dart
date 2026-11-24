import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_page.dart';
import 'wali_portal_page.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iujskspgtuykqigwpegv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1anNrc3BndHV5a3FpZ3dwZWd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUyMzEyMjIsImV4cCI6MjExMDgwNzIyMn0.l0J7LAJfPa8Bv8Ir1lK6lIaDxLIhQVoAYxHHdilUBQk',
  );

  runApp(const SwimClubApp());
}

class SwimClubApp extends StatelessWidget {
  const SwimClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Club Prestasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final event = snapshot.data?.event;
          final session = Supabase.instance.client.auth.currentSession;

          // Otomatis buka halaman Buat Kata Sandi Baru saat link reset dari email diklik
          if (event == AuthChangeEvent.passwordRecovery) {
            return const ResetPasswordPage(isRecoveryMode: true);
          }

          if (session != null) {
            return RoleRouterScreen(email: session.user.email ?? '');
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class RoleRouterScreen extends StatefulWidget {
  final String email;
  const RoleRouterScreen({super.key, required this.email});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  final _supabase = Supabase.instance.client;
  bool _isChecking = true;
  String _role = 'admin';
  String _statusAkun = 'aktif';
  String _namaLengkap = 'Pengguna Klub';
  String _namaAtletTerkait = '';

  @override
  void initState() {
    super.initState();
    _cekPeranPengguna();
  }

  Future<void> _cekPeranPengguna() async {
    setState(() => _isChecking = true);
    try {
      final emailBersih = widget.email.trim().toLowerCase();
      final response = await _supabase
          .from('profil_pengguna')
          .select()
          .eq('email', emailBersih)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _role = (response['role'] ?? 'wali').toString();
          _statusAkun = (response['status_akun'] ?? 'aktif').toString();
          _namaLengkap = (response['nama_lengkap'] ?? 'Pengguna Klub').toString();
          _namaAtletTerkait = (response['nama_atlet_terkait'] ?? '').toString();
          _isChecking = false;
        });
      } else {
        final semuaProfil = await _supabase.from('profil_pengguna').select('id').limit(1);
        final tabelKosong = (semuaProfil as List).isEmpty;

        setState(() {
          _role = tabelKosong ? 'admin' : 'wali';
          _statusAkun = tabelKosong ? 'aktif' : 'pending';
          _namaLengkap = tabelKosong ? 'Super Admin' : widget.email.split('@').first;
          _namaAtletTerkait = '';
          _isChecking = false;
        });
      }
    } catch (_) {
      setState(() {
        _role = 'admin';
        _statusAkun = 'aktif';
        _namaLengkap = 'Super Admin';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waves, color: Color(0xFF38BDF8), size: 48),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text('Memeriksa status dan peran akun...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (_statusAkun == 'pending' || _statusAkun == 'ditolak') {
      final isDitolak = _statusAkun == 'ditolak';
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDitolak ? Colors.red.shade50 : Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDitolak ? Icons.block_rounded : Icons.hourglass_top_rounded,
                        size: 44,
                        color: isDitolak ? Colors.red.shade700 : Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isDitolak ? 'Pendaftaran Ditolak' : 'Menunggu Konfirmasi Super Admin',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isDitolak
                          ? 'Mohon maaf, pengajuan akun wali atlet atas nama $_namaLengkap belum dapat disetujui. Silakan hubungi pengurus klub.'
                          : 'Terima kasih $_namaLengkap. Pengajuan akun Wali Atlet untuk "${_namaAtletTerkait.isEmpty ? '-' : _namaAtletTerkait}" sedang diverifikasi oleh Super Admin klub.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Email terdaftar: ${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isDitolak) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _cekPeranPengguna,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Cek Status Persetujuan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => Supabase.instance.client.auth.signOut(),
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                        label: const Text('Keluar / Kembali ke Login', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_role == 'wali') {
      return WaliPortalPage(
        namaWali: _namaLengkap,
        emailWali: widget.email,
        namaAtletTerkait: _namaAtletTerkait,
      );
    }

    return DashboardPage(
      role: _role,
      namaPengguna: _namaLengkap,
      emailPengguna: widget.email,
    );
  }
}