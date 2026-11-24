import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  final bool isRecoveryMode;
  final String initialEmail;

  const ResetPasswordPage({
    super.key,
    this.isRecoveryMode = false,
    this.initialEmail = '',
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _supabase = Supabase.instance.client;
  final _requestFormKey = GlobalKey<FormState>();
  final _updateFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _emailTerkirim = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? get _redirectUrl {
    try {
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
        return Uri.base.origin;
      }
    } catch (_) {}
    return null;
  }

  // Tahap 1: Mengirim tautan reset password ke email pengguna
  Future<void> _kirimEmailReset() async {
    if (!_requestFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim().toLowerCase();

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _redirectUrl,
      );

      if (mounted) {
        setState(() {
          _emailTerkirim = true;
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengirim email pemulihan. Periksa koneksi internetmu.';
          _isLoading = false;
        });
      }
    }
  }

  // Tahap 2: Menyimpan kata sandi baru setelah klik link email / saat ganti sandi
  Future<void> _simpanPasswordBaru() async {
    if (!_updateFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi baru berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Jika halaman dibuka lewat Navigator (dari dalam dashboard), kembali ke halaman sebelumnya
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memperbarui kata sandi. Tautan mungkin sudah kedaluwarsa.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _kembaliKeLogin() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      await _supabase.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmailAktif = _supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      body: Container(
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
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.isRecoveryMode ? Icons.lock_reset_rounded : Icons.mark_email_read_outlined,
                            color: const Color(0xFF0284C7),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.isRecoveryMode ? 'Buat Kata Sandi Baru' : 'Reset Kata Sandi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isRecoveryMode
                            ? (userEmailAktif.isNotEmpty
                                ? 'Masukkan kata sandi baru untuk akun $userEmailAktif.'
                                : 'Masukkan kata sandi baru yang mudah diingat namun aman.')
                            : 'Masukkan email yang terdaftar di Aqua Club. Tautan untuk mengatur ulang kata sandi akan dikirim ke kotak masukmu.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.5),
                      ),
                      const SizedBox(height: 22),

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

                      if (widget.isRecoveryMode)
                        _buildFormPasswordBaru()
                      else if (_emailTerkirim)
                        _buildPesanTerkirim()
                      else
                        _buildFormMintaReset(),

                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _kembaliKeLogin,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(
                          Navigator.canPop(context) ? 'Kembali' : 'Kembali ke Halaman Login',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormMintaReset() {
    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _kirimEmailReset(),
            decoration: InputDecoration(
              labelText: 'Email Terdaftar',
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
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _kirimEmailReset,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send_rounded, size: 18),
              label: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Kirim Tautan Reset Password',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesanTerkirim() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 42),
          const SizedBox(height: 12),
          Text(
            'Tautan Pemulihan Terkirim!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kami telah mengirim tautan reset kata sandi ke ${_emailController.text.trim()}.\n\nSilakan buka email tersebut (cek juga folder Spam) dan klik tautan di dalamnya untuk membuat kata sandi baru.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.green.shade800, height: 1.5),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => setState(() => _emailTerkirim = false),
            child: const Text('Kirim ulang ke email lain'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPasswordBaru() {
    return Form(
      key: _updateFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Kata Sandi Baru (Min. 6 karakter)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
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
              if (val == null || val.isEmpty) return 'Kata sandi baru wajib diisi';
              if (val.length < 6) return 'Minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _simpanPasswordBaru(),
            decoration: InputDecoration(
              labelText: 'Ulangi Kata Sandi Baru',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
              if (val == null || val.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
              if (val != _newPasswordController.text) return 'Kata sandi tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simpanPasswordBaru,
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
                  : const Text(
                      'Simpan Kata Sandi Baru',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}