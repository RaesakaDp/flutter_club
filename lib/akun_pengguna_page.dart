import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilPengguna {
  final int id;
  final String email;
  final String namaLengkap;
  final String noHp;
  final String role;
  final String statusAkun;
  final String namaAtletTerkait;

  ProfilPengguna({
    required this.id,
    required this.email,
    required this.namaLengkap,
    required this.noHp,
    required this.role,
    required this.statusAkun,
    required this.namaAtletTerkait,
  });

  factory ProfilPengguna.fromMap(Map map) {
    return ProfilPengguna(
      id: map['id'] ?? 0,
      email: map['email'] ?? '-',
      namaLengkap: map['nama_lengkap'] ?? 'Pengguna',
      noHp: map['no_hp'] ?? '-',
      role: map['role'] ?? 'wali',
      statusAkun: map['status_akun'] ?? 'aktif',
      namaAtletTerkait: map['nama_atlet_terkait'] ?? '',
    );
  }
}

class AkunPenggunaPage extends StatefulWidget {
  const AkunPenggunaPage({super.key});

  @override
  State<AkunPenggunaPage> createState() => _AkunPenggunaPageState();
}

class _AkunPenggunaPageState extends State<AkunPenggunaPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<ProfilPengguna> _daftarPengguna = [];
  List<String> _daftarNamaAtlet = [];
  List _daftarPelatih = [];
  String _filterRole = 'Semua';
  String _kataKunci = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('profil_pengguna').select().order('id', ascending: false),
        _supabase.from('atlet').select('nama').order('nama', ascending: true),
        _supabase.from('pelatih').select().order('nama', ascending: true),
      ]);

      final listUser = results[0] as List;
      final listAtlet = results[1] as List;
      final listPelatih = results[2] as List;

      setState(() {
        _daftarPengguna = listUser.map((e) => ProfilPengguna.fromMap(e)).toList();
        _daftarNamaAtlet = listAtlet
            .map((a) => (a['nama'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();
        _daftarPelatih = listPelatih.map((p) => Map.from(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar akun: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isPelatihTersinkron(ProfilPengguna user) {
    if (user.role != 'pelatih') return false;
    final emailUser = user.email.trim().toLowerCase();
    final namaUser = user.namaLengkap.trim().toLowerCase();
    return _daftarPelatih.any((p) {
      final emailP = (p['email'] ?? '').toString().trim().toLowerCase();
      final namaP = (p['nama'] ?? '').toString().trim().toLowerCase();
      return (emailP.isNotEmpty && emailP == emailUser) || namaP == namaUser;
    });
  }

  List<ProfilPengguna> get _antreanPending {
    return _daftarPengguna.where((u) => u.statusAkun == 'pending').toList();
  }

  List<ProfilPengguna> get _penggunaTersaring {
    return _daftarPengguna.where((u) {
      bool cocokRole = true;
      if (_filterRole == 'Super Admin') cocokRole = u.role == 'admin';
      if (_filterRole == 'Pelatih') cocokRole = u.role == 'pelatih';
      if (_filterRole == 'Wali Atlet') cocokRole = u.role == 'wali';

      final q = _kataKunci.toLowerCase();
      final cocokCari = q.isEmpty ||
          u.namaLengkap.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.namaAtletTerkait.toLowerCase().contains(q);

      return cocokRole && cocokCari;
    }).toList();
  }

  Future<void> _ubahStatusAkun(ProfilPengguna item, String statusBaru) async {
    try {
      await _supabase
          .from('profil_pengguna')
          .update({'status_akun': statusBaru})
          .eq('id', item.id);

      await _muatData();
      if (mounted) {
        final pesan = statusBaru == 'aktif'
            ? 'Akun ${item.namaLengkap} disetujui & resmi aktif!'
            : 'Pendaftaran ${item.namaLengkap} ditolak.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
            backgroundColor: statusBaru == 'aktif' ? Colors.green : Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _simpanPengguna({
    ProfilPengguna? editItem,
    required String email,
    required String nama,
    required String noHp,
    required String role,
    required String statusAkun,
    required String namaAtlet,
  }) async {
    try {
      final data = {
        'email': email.toLowerCase().trim(),
        'nama_lengkap': nama.trim(),
        'no_hp': noHp.trim().isEmpty ? '-' : noHp.trim(),
        'role': role,
        'status_akun': statusAkun,
        'nama_atlet_terkait': role == 'wali' ? namaAtlet.trim() : '',
      };

      if (editItem != null) {
        await _supabase.from('profil_pengguna').update(data).eq('id', editItem.id);
      } else {
        await _supabase.from('profil_pengguna').upsert(data, onConflict: 'email');
      }

      await _muatData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              role == 'pelatih'
                  ? 'Akun pelatih tersimpan & otomatis tersinkron ke Data Pelatih!'
                  : 'Data hak akses pengguna tersimpan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan akun: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusPengguna(ProfilPengguna item) async {
    try {
      await _supabase.from('profil_pengguna').delete().eq('id', item.id);
      await _muatData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _tampilkanForm({ProfilPengguna? editItem, required bool isMobile}) {
    final isEdit = editItem != null;
    final emailController = TextEditingController(text: isEdit ? editItem.email : '');
    final namaController = TextEditingController(text: isEdit ? editItem.namaLengkap : '');
    final hpController = TextEditingController(text: isEdit && editItem.noHp != '-' ? editItem.noHp : '');
    final atletController = TextEditingController(
      text: isEdit && editItem.namaAtletTerkait.isNotEmpty
          ? editItem.namaAtletTerkait
          : (_daftarNamaAtlet.isNotEmpty ? _daftarNamaAtlet.first : ''),
    );

    String pilihRole = isEdit ? editItem.role : 'pelatih';
    String pilihStatus = isEdit ? editItem.statusAkun : 'aktif';
    int? pelatihTerpilihId;

    Widget isiForm(StateSetter setDialogState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEdit ? 'Edit Data & Konfirmasi Akun' : 'Tambah Hak Akses Akun',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('role_$pilihRole'),
                  initialValue: pilihRole,
                  decoration: InputDecoration(
                    labelText: 'Peran',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Super Admin')),
                    DropdownMenuItem(value: 'pelatih', child: Text('Pelatih')),
                    DropdownMenuItem(value: 'wali', child: Text('Wali Atlet')),
                  ],
                  onChanged: (val) => setDialogState(() => pilihRole = val!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('status_$pilihStatus'),
                  initialValue: pilihStatus,
                  decoration: InputDecoration(
                    labelText: 'Status Akun',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'pending', child: Text('Menunggu')),
                    DropdownMenuItem(value: 'ditolak', child: Text('Ditolak')),
                  ],
                  onChanged: (val) => setDialogState(() => pilihStatus = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (pilihRole == 'pelatih' && _daftarPelatih.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: pelatihTerpilihId,
              decoration: InputDecoration(
                labelText: 'Ambil dari Data Pelatih (Opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.sync),
              ),
              items: _daftarPelatih
                  .map((p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(
                          '${p['nama']}${(p['email'] ?? '').toString().isNotEmpty ? ' (${p['email']})' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (idTerpilih) {
                if (idTerpilih == null) return;
                final pelatih = _daftarPelatih.firstWhere((p) => p['id'] == idTerpilih);
                setDialogState(() {
                  pelatihTerpilihId = idTerpilih;
                  namaController.text = (pelatih['nama'] ?? '').toString();
                  final emailP = (pelatih['email'] ?? '').toString();
                  if (emailP.isNotEmpty) emailController.text = emailP;
                  final hpP = (pelatih['no_hp'] ?? '').toString();
                  if (hpP.isNotEmpty && hpP != '-') hpController.text = hpP;
                });
              },
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: namaController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Login',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: hpController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'No. HP / WhatsApp',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.phone_android),
            ),
          ),

          if (pilihRole == 'pelatih') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_alt, color: Color(0xFF0D9488), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Otomatis tersinkron dengan menu Data Pelatih.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (pilihRole == 'wali') ...[
            const SizedBox(height: 12),
            if (_daftarNamaAtlet.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _daftarNamaAtlet.contains(atletController.text)
                    ? atletController.text
                    : _daftarNamaAtlet.first,
                decoration: InputDecoration(
                  labelText: 'Cocokkan dengan Data Atlet Klub',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.pool),
                ),
                items: _daftarNamaAtlet
                    .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(n, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => atletController.text = val!),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: atletController,
              decoration: InputDecoration(
                labelText: 'Nama Atlet Terkait',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.child_care),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                onPressed: () {
                  if (emailController.text.trim().isEmpty || namaController.text.trim().isEmpty) return;
                  Navigator.pop(context);
                  _simpanPengguna(
                    editItem: editItem,
                    email: emailController.text,
                    nama: namaController.text,
                    noHp: hpController.text,
                    role: pilihRole,
                    statusAkun: pilihStatus,
                    namaAtlet: atletController.text,
                  );
                },
                child: const Text('Simpan & Sinkronkan'),
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
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(child: isiForm(setDialogState)),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(child: isiForm(setDialogState)),
            ),
          ),
        ),
      );
    }
  }

  String _labelRole(String role) {
    if (role == 'admin') return 'Super Admin';
    if (role == 'pelatih') return 'Pelatih';
    return 'Wali Atlet';
  }

  Color _warnaRole(String role) {
    if (role == 'admin') return const Color(0xFF0284C7);
    if (role == 'pelatih') return const Color(0xFF0D9488);
    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context) {
    final antrean = _antreanPending;
    final listTampil = _penggunaTersaring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return RefreshIndicator(
          onRefresh: _muatData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Antrean Konfirmasi Wali Atlet Baru
                if (antrean.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade300, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, color: Colors.amber.shade900),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Menunggu Konfirmasi (${antrean.length} Pendaftar)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: antrean.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pendaftar = antrean[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${pendaftar.namaLengkap} (${pendaftar.email})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Atlet: ${pendaftar.namaAtletTerkait.isEmpty ? '-' : pendaftar.namaAtletTerkait} • WA: ${pendaftar.noHp}',
                                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _ubahStatusAkun(pendaftar, 'aktif'),
                                        icon: const Icon(Icons.check_circle_outline, size: 17),
                                        label: const Text('Setujui'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _tampilkanForm(editItem: pendaftar, isMobile: isMobile),
                                        icon: const Icon(Icons.edit_outlined, size: 17),
                                        label: const Text('Cocokkan Atlet'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _ubahStatusAkun(pendaftar, 'ditolak'),
                                        icon: const Icon(Icons.close, size: 17, color: Colors.red),
                                        label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Tombol Tambah & Pencarian
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _tampilkanForm(isMobile: isMobile),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Tambah Hak Akses Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _kataKunci = val),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, email, atau atlet...',
                          prefixIcon: const Icon(Icons.search, size: 19),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Peran
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Semua', 'Super Admin', 'Pelatih', 'Wali Atlet'].map((roleFilter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(roleFilter),
                          selected: _filterRole == roleFilter,
                          onSelected: (_) => setState(() => _filterRole = roleFilter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Daftar Pengguna: Card List di HP, DataTable di Desktop
                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                else if (listTampil.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(child: Text('Tidak ada data pengguna yang sesuai filter.')),
                  )
                else if (isMobile)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listTampil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildCardPenggunaMobile(listTampil[index]),
                  )
                else
                  _buildTablePenggunaDesktop(listTampil, constraints.maxWidth - 64),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardPenggunaMobile(ProfilPengguna item) {
    final warna = _warnaRole(item.role);
    final isAktif = item.statusAkun == 'aktif';
    final isPending = item.statusAkun == 'pending';
    final tersinkron = _isPelatihTersinkron(item);

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
            children: [
              CircleAvatar(
                backgroundColor: warna.withValues(alpha: 0.12),
                child: Text(
                  item.namaLengkap.isNotEmpty ? item.namaLengkap[0].toUpperCase() : 'U',
                  style: TextStyle(color: warna, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${item.email} • ${item.noHp}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: warna.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_labelRole(item.role),
                    style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAktif ? Colors.green.shade50 : (isPending ? Colors.amber.shade50 : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAktif ? 'Aktif' : (isPending ? 'Menunggu' : 'Ditolak'),
                  style: TextStyle(
                    color: isAktif
                        ? Colors.green.shade700
                        : (isPending ? Colors.amber.shade900 : Colors.red.shade700),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (item.role == 'pelatih')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tersinkron ? const Color(0xFFF0FDFA) : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tersinkron ? 'Tersinkron Data Pelatih' : 'Belum di Data Pelatih',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tersinkron ? const Color(0xFF0F766E) : Colors.orange.shade800,
                    ),
                  ),
                )
              else if (item.role == 'wali' && item.namaAtletTerkait.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: Text('Atlet: ${item.namaAtletTerkait}', style: const TextStyle(fontSize: 11.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isAktif) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _ubahStatusAkun(item, 'aktif'),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Aktifkan'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tampilkanForm(editItem: item, isMobile: true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _hapusPengguna(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTablePenggunaDesktop(List<ProfilPengguna> listTampil, double minWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text('Nama Pengguna', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Email & WA', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Peran', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Keterangan / Atlet Terkait', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status Akun', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: listTampil.map((item) {
                final warna = _warnaRole(item.role);
                final isAktif = item.statusAkun == 'aktif';
                final isPending = item.statusAkun == 'pending';
                final tersinkron = _isPelatihTersinkron(item);

                return DataRow(
                  cells: [
                    DataCell(Text(item.namaLengkap, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${item.email}\n${item.noHp}', style: const TextStyle(fontSize: 12.5))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _labelRole(item.role),
                          style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      item.role == 'pelatih'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tersinkron ? Icons.check_circle : Icons.sync_problem,
                                  size: 16,
                                  color: tersinkron ? const Color(0xFF0D9488) : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tersinkron ? 'Tersinkron ke Data Pelatih' : 'Belum di Data Pelatih',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: tersinkron ? const Color(0xFF0F766E) : Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Text(item.role == 'wali' && item.namaAtletTerkait.isNotEmpty
                              ? item.namaAtletTerkait
                              : '-'),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAktif
                              ? Colors.green.shade50
                              : (isPending ? Colors.amber.shade50 : Colors.red.shade50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAktif ? 'Aktif' : (isPending ? 'Menunggu' : 'Ditolak'),
                          style: TextStyle(
                            color: isAktif
                                ? Colors.green.shade700
                                : (isPending ? Colors.amber.shade900 : Colors.red.shade700),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isAktif)
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              tooltip: 'Setujui & Aktifkan',
                              onPressed: () => _ubahStatusAkun(item, 'aktif'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                            tooltip: 'Edit',
                            onPressed: () => _tampilkanForm(editItem: item, isMobile: false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Hapus',
                            onPressed: () => _hapusPengguna(item),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}