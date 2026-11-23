import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JadwalLatihan {
  final int id;
  String hari;
  String jam;
  String kelompok;
  String materi;
  String pelatih;
  String kolam;
  String status;

  JadwalLatihan({
    required this.id,
    required this.hari,
    required this.jam,
    required this.kelompok,
    required this.materi,
    required this.pelatih,
    required this.kolam,
    required this.status,
  });

  factory JadwalLatihan.fromMap(Map map) {
    return JadwalLatihan(
      id: map['id'] ?? 0,
      hari: map['hari'] ?? 'Senin',
      jam: map['jam'] ?? '-',
      kelompok: map['kelompok'] ?? '-',
      materi: map['materi'] ?? '-',
      pelatih: map['pelatih'] ?? '-',
      kolam: map['kolam'] ?? '-',
      status: map['status'] ?? 'Terjadwal',
    );
  }
}

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _supabase = Supabase.instance.client;
  List<JadwalLatihan> _daftarJadwal = [];
  bool _isLoading = true;

  String _filterHari = 'Semua';
  final List<String> _opsiHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<String> _opsiStatus = ['Terjadwal', 'Berlangsung', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _ambilDataJadwal();
  }

  Future<void> _ambilDataJadwal() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('jadwal_latihan')
          .select()
          .order('id', ascending: true);

      final List dataMentah = response as List;
      setState(() {
        _daftarJadwal = dataMentah.map((item) => JadwalLatihan.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat jadwal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _simpanJadwal({
    JadwalLatihan? jadwalEdit,
    required String hari,
    required String jam,
    required String kelompok,
    required String materi,
    required String pelatih,
    required String kolam,
    required String status,
  }) async {
    try {
      final dataKirim = {
        'hari': hari,
        'jam': jam,
        'kelompok': kelompok,
        'materi': materi,
        'pelatih': pelatih,
        'kolam': kolam,
        'status': status,
      };

      if (jadwalEdit != null) {
        await _supabase.from('jadwal_latihan').update(dataKirim).eq('id', jadwalEdit.id);
      } else {
        await _supabase.from('jadwal_latihan').insert(dataKirim);
      }

      await _ambilDataJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jadwalEdit != null ? 'Jadwal diperbarui!' : 'Jadwal baru tersimpan ke cloud!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jadwal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusJadwal(int id) async {
    try {
      await _supabase.from('jadwal_latihan').delete().eq('id', id);
      await _ambilDataJadwal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus jadwal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<JadwalLatihan> get _jadwalTersaring {
    if (_filterHari == 'Semua') return _daftarJadwal;
    return _daftarJadwal.where((j) => j.hari == _filterHari).toList();
  }

  void _tampilkanFormJadwal({JadwalLatihan? jadwalEdit}) {
    final isEdit = jadwalEdit != null;
    String pilihHari = isEdit ? jadwalEdit.hari : _opsiHari.first;
    String pilihStatus = isEdit ? jadwalEdit.status : _opsiStatus.first;
    final jamController = TextEditingController(text: isEdit ? jadwalEdit.jam : '15:30 - 17:30 WIB');
    final kelompokController = TextEditingController(text: isEdit ? jadwalEdit.kelompok : '');
    final materiController = TextEditingController(text: isEdit ? jadwalEdit.materi : '');
    final pelatihController = TextEditingController(text: isEdit ? jadwalEdit.pelatih : '');
    final kolamController = TextEditingController(text: isEdit ? jadwalEdit.kolam : '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Jadwal Latihan' : 'Tambah Jadwal Latihan'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: pilihHari,
                        decoration: const InputDecoration(labelText: 'Hari Latihan', border: OutlineInputBorder()),
                        items: _opsiHari.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                        onChanged: (val) => setDialogState(() => pilihHari = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: jamController,
                        decoration: const InputDecoration(labelText: 'Jam Sesi', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: kelompokController,
                        decoration: const InputDecoration(labelText: 'Kelompok / Kelas (misal: KU-1)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: materiController,
                        decoration: const InputDecoration(labelText: 'Fokus Materi Latihan', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pelatihController,
                        decoration: const InputDecoration(labelText: 'Nama Pelatih', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: kolamController,
                        decoration: const InputDecoration(labelText: 'Lokasi Kolam & Lintasan', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: pilihStatus,
                        decoration: const InputDecoration(labelText: 'Status Sesi', border: OutlineInputBorder()),
                        items: _opsiStatus.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setDialogState(() => pilihStatus = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                  onPressed: () {
                    if (kelompokController.text.trim().isEmpty || materiController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    _simpanJadwal(
                      jadwalEdit: jadwalEdit,
                      hari: pilihHari,
                      jam: jamController.text.trim(),
                      kelompok: kelompokController.text.trim(),
                      materi: materiController.text.trim(),
                      pelatih: pelatihController.text.trim(),
                      kolam: kolamController.text.trim(),
                      status: pilihStatus,
                    );
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataTampil = _jadwalTersaring;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter & Tombol Tambah Responsif
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF94A3B8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterHari,
                        items: ['Semua', ..._opsiHari]
                            .map((hari) => DropdownMenuItem(value: hari, child: Text('Hari: $hari')))
                            .toList(),
                        onChanged: (val) => setState(() => _filterHari = val!),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _ambilDataJadwal,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang Jadwal',
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _tampilkanFormJadwal(),
                    icon: const Icon(Icons.add_alarm, size: 18),
                    label: const Text('Tambah Jadwal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dataTampil.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada jadwal latihan di database. Klik "Tambah Jadwal" untuk memulai.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dataTampil.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final jadwal = dataTampil[index];
                    final isBerlangsung = jadwal.status == 'Berlangsung';

                    return Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBerlangsung ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isBerlangsung ? 1.5 : 1,
                        ),
                      ),
                      child: isMobile
                          ? _buildKartuJadwalMobile(jadwal, isBerlangsung)
                          : _buildKartuJadwalDesktop(jadwal, isBerlangsung),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKartuJadwalMobile(JadwalLatihan jadwal, bool isBerlangsung) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${jadwal.hari} • ${jadwal.jam}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isBerlangsung ? Colors.blue.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                jadwal.status,
                style: TextStyle(
                  color: isBerlangsung ? Colors.blue.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                jadwal.kelompok,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              jadwal.materi,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pool, size: 15, color: Colors.grey),
                const SizedBox(width: 5),
                Text(jadwal.kolam, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports, size: 15, color: Colors.grey),
                const SizedBox(width: 5),
                Text(jadwal.pelatih, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              ],
            ),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _tampilkanFormJadwal(jadwalEdit: jadwal),
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
              label: const Text('Edit', style: TextStyle(color: Colors.blue)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _hapusJadwal(jadwal.id),
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              label: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKartuJadwalDesktop(JadwalLatihan jadwal, bool isBerlangsung) {
    return Row(
      children: [
        Container(
          width: 165,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jadwal.hari,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                jadwal.jam,
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      jadwal.kelompok,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    jadwal.materi,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pool, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(jadwal.kolam, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(jadwal.pelatih, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isBerlangsung ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            jadwal.status,
            style: TextStyle(
              color: isBerlangsung ? Colors.blue.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
          tooltip: 'Edit Jadwal',
          onPressed: () => _tampilkanFormJadwal(jadwalEdit: jadwal),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Hapus Jadwal',
          onPressed: () => _hapusJadwal(jadwal.id),
        ),
      ],
    );
  }
}