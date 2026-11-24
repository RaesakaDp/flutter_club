import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _supabase = Supabase.instance.client;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Controller Login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controller Daftar Wali Atlet
  final _regNamaWaliController = TextEditingController();
  final _regNoHpController = TextEditingController();
  final _regNamaAtletController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  List<String> _daftarNamaAtlet = [];
  bool _inputAtletManual = false;

  @override
  void initState() {
    super.initState();
    _muatDaftarAtlet();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNamaWaliController.dispose();
    _regNoHpController.dispose();
    _regNamaAtletController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _muatDaftarAtlet() async {
    try {
      final response = await _supabase
          .from('atlet')
          .select('nama')
          .order('nama', ascending: true);

      final List data = response as List;
      final namaList = data
          .map((e) => (e['nama'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _daftarNamaAtlet = namaList;
          if (_daftarNamaAtlet.isNotEmpty) {
            _regNamaAtletController.text = _daftarNamaAtlet.first;
          } else {
            _inputAtletManual = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _inputAtletManual = true);
      }
    }
  }

  Future<void> _prosesLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      setState(() {
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          _errorMessage = 'Email atau kata sandi salah. Silakan periksa kembali.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Terjadi gangguan koneksi. Coba beberapa saat lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _prosesDaftarWali() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _regEmailController.text.trim().toLowerCase();
    final password = _regPasswordController.text;
    final namaWali = _regNamaWaliController.text.trim();
    final noHp = _regNoHpController.text.trim();
    final namaAtlet = _regNamaAtletController.text.trim();

    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        await _supabase.from('profil_pengguna').upsert({
          'email': email,
          'nama_lengkap': namaWali,
          'no_hp': noHp.isEmpty ? '-' : noHp,
          'role': 'wali',
          'nama_atlet_terkait': namaAtlet,
          'status_akun': 'pending',
        }, onConflict: 'email');

        if (authResponse.session == null && mounted) {
          setState(() {
            _isRegisterMode = false;
            _emailController.text = email;
            _successMessage =
                'Pendaftaran berhasil dikirim! Akunmu sedang menunggu konfirmasi Super Admin.';
          });
        }
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.toLowerCase().contains('already registered')) {
          _errorMessage = 'Email ini sudah terdaftar. Silakan pindah ke tab Masuk.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendaftarkan akun: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 850;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildPanelBranding(),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(36),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _buildAuthCard(isMobile: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF0369A1), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildAuthCard(isMobile: true),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPanelBranding() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0369A1), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.waves, color: Color(0xFF38BDF8), size: 32),
              ),
              const SizedBox(width: 14),
              const Text(
                'AQUA CLUB PRESTASI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem Pembinaan & Portal Wali Atlet Terpadu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kelola data atlet tiap kelas, lisensi pelatih, limit terbaik kejuaraan (PB), serta transparansi iuran untuk wali atlet.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 32),
              _buildFeatureBadge(Icons.admin_panel_settings_outlined, 'Dashboard Terpisah: Admin, Pelatih & Wali'),
              const SizedBox(height: 12),
              _buildFeatureBadge(Icons.how_to_reg_outlined, 'Pendaftaran Mandiri Wali dengan Verifikasi Admin'),
              const SizedBox(height: 12),
              _buildFeatureBadge(Icons.emoji_events_outlined, 'Pemantauan Limit Terbaik (PB) Real-Time'),
            ],
          ),
          const Text(
            '© 2026 Aqua Club Management System',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAuthCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 22 : 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.waves, color: Color(0xFF0284C7), size: 32),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Pemilih Mode: Masuk vs Daftar Wali Atlet
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isRegisterMode = false;
                      _errorMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isRegisterMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_isRegisterMode
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]
                            : [],
                      ),
                      child: Text(
                        'Masuk Akun',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: !_isRegisterMode ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isRegisterMode = true;
                      _errorMessage = null;
                      _successMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isRegisterMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _isRegisterMode
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]
                            : [],
                      ),
                      child: Text(
                        'Daftar Wali Atlet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: _isRegisterMode ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            _isRegisterMode ? 'Pendaftaran Wali Atlet' : 'Selamat Datang Kembali',
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            _isRegisterMode
                ? 'Buat akun untuk memantau limit & iuran anak. Akun akan aktif setelah dikonfirmasi Super Admin.'
                : 'Masuk sebagai Admin Klub, Pelatih, atau Wali Atlet.',
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Notifikasi Sukses
          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green.shade800, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),

          // Notifikasi Error
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isRegisterMode) _buildFormLogin() else _buildFormDaftarWali(),
        ],
      ),
    );
  }

  Widget _buildFormLogin() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email Akun',
              hintText: 'nama@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
              if (!val.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _prosesLogin(),
            decoration: InputDecoration(
              labelText: 'Kata Sandi',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
              if (val.length < 6) return 'Kata sandi minimal 6 karakter';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResetPasswordPage(
                      initialEmail: _emailController.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text(
                'Lupa kata sandi?',
                style: TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _prosesLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Masuk Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormDaftarWali() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regNamaWaliController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap Orang Tua / Wali',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama wali wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regNoHpController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nomor WhatsApp / HP Aktif',
              hintText: '0812xxxxxxxx',
              prefixIcon: const Icon(Icons.phone_android),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Nomor WhatsApp wajib diisi untuk verifikasi' : null,
          ),
          const SizedBox(height: 12),

          if (_daftarNamaAtlet.isNotEmpty && !_inputAtletManual) ...[
            DropdownButtonFormField<String>(
              initialValue: _daftarNamaAtlet.contains(_regNamaAtletController.text)
                  ? _regNamaAtletController.text
                  : _daftarNamaAtlet.first,
              decoration: InputDecoration(
                labelText: 'Pilih Nama Atlet (Anak)',
                prefixIcon: const Icon(Icons.pool),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: _daftarNamaAtlet
                  .map((nama) => DropdownMenuItem(value: nama, child: Text(nama)))
                  .toList(),
              onChanged: (val) => setState(() => _regNamaAtletController.text = val!),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  _inputAtletManual = true;
                  _regNamaAtletController.clear();
                }),
                child: const Text('Nama anak belum ada di daftar? Ketik manual', style: TextStyle(fontSize: 12)),
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _regNamaAtletController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Atlet (Anak)',
                prefixIcon: const Icon(Icons.pool),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama atlet wajib diisi' : null,
            ),
            if (_daftarNamaAtlet.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _inputAtletManual = false;
                    _regNamaAtletController.text = _daftarNamaAtlet.first;
                  }),
                  child: const Text('Pilih dari daftar atlet klub', style: TextStyle(fontSize: 12)),
                ),
              )
            else
              const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email untuk Login',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
              if (!val.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _prosesDaftarWali(),
            decoration: InputDecoration(
              labelText: 'Buat Kata Sandi (Min. 6 karakter)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
              if (val.length < 6) return 'Kata sandi minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _prosesDaftarWali,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Ajukan Pendaftaran Akun', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}