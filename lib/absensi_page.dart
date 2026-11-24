import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiPage extends StatefulWidget {
  final String namaPencatat;

  const AbsensiPage({super.key, this.namaPencatat = 'Pelatih'});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  DateTime _tanggalTerpilih = DateTime.now();
  String _sesiTerpilih = 'Latihan Reguler';
  String _filterKelas = 'Semua';
  String _kataKunci = '';
  bool _isLoading = true;
  bool _isSaving = false;

  List _daftarAtlet = [];
  List<String> _opsiSesi = ['Latihan Reguler'];

  final Map<String, String> _statusMap = {};
  final Map<String, String> _catatanMap = {};

  @override
  void initState() {
    super.initState();
    _muatDataAwal();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _tanggalIso {
    final y = _tanggalTerpilih.year.toString().padLeft(4, '0');
    final m = _tanggalTerpilih.month.toString().padLeft(2, '0');
    final d = _tanggalTerpilih.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _muatDataAwal() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('atlet').select().order('nama', ascending: true),
        _supabase.from('jadwal_latihan').select().order('id', ascending: true),
      ]);

      final listAtlet = (results[0] as List).map((e) => Map.from(e)).toList();
      final listJadwal = results[1] as List;

      final Set<String> sesiSet = {'Latihan Reguler'};
      for (final j in listJadwal) {
        final label = '${j['hari']} • ${j['jam']} (${j['kelompok']})';
        sesiSet.add(label);
      }

      setState(() {
        _daftarAtlet = listAtlet;
        _opsiSesi = sesiSet.toList();
        if (!_opsiSesi.contains(_sesiTerpilih)) {
          _sesiTerpilih = _opsiSesi.first;
        }
      });

      await _muatAbsensiTanggal();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data atlet: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _muatAbsensiTanggal() async {
    setState(() => _isLoading = true);
    try {
      final existing = await _supabase
          .from('absensi_latihan')
          .select()
          .eq('tanggal', _tanggalIso)
          .eq('sesi_label', _sesiTerpilih);

      _statusMap.clear();
      _catatanMap.clear();

      for (final atlet in _daftarAtlet) {
        final nama = (atlet['nama'] ?? '').toString();
        _statusMap[nama] = 'Hadir';
        _catatanMap[nama] = '';
      }

      for (final row in (existing as List)) {
        final nama = (row['nama_atlet'] ?? '').toString();
        if (nama.isNotEmpty) {
          _statusMap[nama] = (row['status'] ?? 'Hadir').toString();
          _catatanMap[nama] = (row['catatan'] ?? '').toString();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat absensi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List get _atletTersaring {
    return _daftarAtlet.where((a) {
      final cocokKelas = _filterKelas == 'Semua' ||
          (a['kelas_latihan'] ?? '').toString().toLowerCase().contains(_filterKelas.toLowerCase());
      final cocokNama = _kataKunci.isEmpty ||
          (a['nama'] ?? '').toString().toLowerCase().contains(_kataKunci.toLowerCase());
      return cocokKelas && cocokNama;
    }).toList();
  }

  void _tandaiSemuaHadir() {
    setState(() {
      for (final atlet in _atletTersaring) {
        final nama = (atlet['nama'] ?? '').toString();
        _statusMap[nama] = 'Hadir';
      }
    });
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTerpilih,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _tanggalTerpilih) {
      setState(() => _tanggalTerpilih = picked);
      await _muatAbsensiTanggal();
    }
  }

  Future<void> _simpanAbsensi() async {
    final targetAtlet = _atletTersaring;
    if (targetAtlet.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final payload = targetAtlet.map((atlet) {
        final nama = (atlet['nama'] ?? '').toString();
        return {
          'tanggal': _tanggalIso,
          'sesi_label': _sesiTerpilih,
          'nama_atlet': nama,
          'kelompok_umur': (atlet['kelompok_umur'] ?? '').toString(),
          'kelas_latihan': (atlet['kelas_latihan'] ?? '').toString(),
          'status': _statusMap[nama] ?? 'Hadir',
          'catatan': _catatanMap[nama] ?? '',
          'dicatat_oleh': widget.namaPencatat,
        };
      }).toList();

      await _supabase
          .from('absensi_latihan')
          .upsert(payload, onConflict: 'tanggal,sesi_label,nama_atlet');

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absensi $_tanggalIso (${targetAtlet.length} atlet) berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan absensi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _ubahCatatanAtlet(String namaAtlet, bool isMobile) {
    final ctrl = TextEditingController(text: _catatanMap[namaAtlet] ?? '');

    Widget kontenForm() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Catatan untuk $namaAtlet',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Keterangan (misal: Izin ujian / Cedera ringan)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                onPressed: () {
                  setState(() => _catatanMap[namaAtlet] = ctrl.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Simpan Catatan'),
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
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: kontenForm(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(content: kontenForm()),
      );
    }
  }

  Color _warnaStatus(String status) {
    switch (status) {
      case 'Hadir':
        return Colors.green.shade600;
      case 'Izin':
        return Colors.blue.shade600;
      case 'Sakit':
        return Colors.orange.shade700;
      case 'Alpa':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listTampil = _atletTersaring;

    int jmlHadir = 0, jmlIzin = 0, jmlSakit = 0, jmlAlpa = 0;
    for (final a in listTampil) {
      final st = _statusMap[(a['nama'] ?? '').toString()] ?? 'Hadir';
      if (st == 'Hadir') jmlHadir++;
      if (st == 'Izin') jmlIzin++;
      if (st == 'Sakit') jmlSakit++;
      if (st == 'Alpa') jmlAlpa++;
    }
    final rasioHadir = listTampil.isEmpty ? 0.0 : jmlHadir / listTampil.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return RefreshIndicator(
          onRefresh: _muatAbsensiTanggal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel Kontrol Tanggal, Sesi, Filter Kelas & Pencarian
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: isMobile ? double.infinity : null,
                            child: OutlinedButton.icon(
                              onPressed: _pilihTanggal,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                'Tanggal: $_tanggalIso',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 300,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey(_sesiTerpilih),
                              initialValue: _sesiTerpilih,
                              decoration: InputDecoration(
                                labelText: 'Sesi / Jadwal Latihan',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: _opsiSesi
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) async {
                                if (val == null) return;
                                setState(() => _sesiTerpilih = val);
                                await _muatAbsensiTanggal();
                              },
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 185,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_filterKelas),
                              initialValue: _filterKelas,
                              decoration: InputDecoration(
                                labelText: 'Filter Kelas',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Semua', child: Text('Semua Kelas')),
                                DropdownMenuItem(value: 'Pemula', child: Text('Kelas Pemula')),
                                DropdownMenuItem(value: 'Menengah', child: Text('Kelas Menengah')),
                                DropdownMenuItem(value: 'Prestasi', child: Text('Kelas Prestasi')),
                              ],
                              onChanged: (val) => setState(() => _filterKelas = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kolom Cari Cepat Nama Atlet
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _kataKunci = val),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atlet...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _kataKunci.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _kataKunci = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bilah Progres Kehadiran Interaktif
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Persentase Kehadiran Sesi Ini',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                          Text(
                            '${(rasioHadir * 100).round()}% ($jmlHadir/${listTampil.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: rasioHadir),
                        duration: const Duration(milliseconds: 350),
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Badge Statistik & Tombol Simpan
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _badgeStat('Hadir: $jmlHadir', Colors.green.shade700, Colors.green.shade50),
                              _badgeStat('Izin: $jmlIzin', Colors.blue.shade700, Colors.blue.shade50),
                              _badgeStat('Sakit: $jmlSakit', Colors.orange.shade800, Colors.orange.shade50),
                              _badgeStat('Alpa: $jmlAlpa', Colors.red.shade700, Colors.red.shade50),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _tandaiSemuaHadir,
                                icon: const Icon(Icons.done_all, size: 17),
                                label: const Text('Semua Hadir'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _simpanAbsensi,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save_rounded, size: 18),
                                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Absensi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Daftar Checklist Atlet
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                else if (listTampil.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text('Tidak ada data atlet yang sesuai filter.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listTampil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final atlet = listTampil[index];
                      final nama = (atlet['nama'] ?? '-').toString();
                      final statusSaatIni = _statusMap[nama] ?? 'Hadir';
                      final catatan = _catatanMap[nama] ?? '';

                      return Container(
                        padding: EdgeInsets.all(isMobile ? 14 : 16),
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
                                  radius: 19,
                                  backgroundColor: _warnaStatus(statusSaatIni).withValues(alpha: 0.12),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: _warnaStatus(statusSaatIni),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nama,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${atlet['kelas_latihan']} • ${atlet['kelompok_umur']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    catatan.isNotEmpty ? Icons.comment : Icons.add_comment_outlined,
                                    color: catatan.isNotEmpty ? const Color(0xFF0284C7) : Colors.grey,
                                    size: 20,
                                  ),
                                  tooltip: 'Catatan Atlet',
                                  onPressed: () => _ubahCatatanAtlet(nama, isMobile),
                                ),
                              ],
                            ),
                            if (catatan.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Catatan: $catatan',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // 4 Tombol Status Interaktif Sejajar Penuh (Mudah Diketuk di HP)
                            Row(
                              children: ['Hadir', 'Izin', 'Sakit', 'Alpa'].map((pilihan) {
                                final terpilih = statusSaatIni == pilihan;
                                final warna = _warnaStatus(pilihan);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: InkWell(
                                      onTap: () => setState(() => _statusMap[nama] = pilihan),
                                      borderRadius: BorderRadius.circular(9),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(
                                          color: terpilih ? warna : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Text(
                                          pilihan,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: terpilih ? Colors.white : const Color(0xFF475569),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badgeStat(String teks, Color warnaTeks, Color warnaLatar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(color: warnaTeks, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}