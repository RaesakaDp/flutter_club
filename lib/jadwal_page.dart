import 'package:flutter/material.dart';

class JadwalLatihan {
  String id;
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
}

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final List<JadwalLatihan> _daftarJadwal = [
    JadwalLatihan(
      id: 'JDW-01',
      hari: 'Senin',
      jam: '15:30 - 17:30 WIB',
      kelompok: 'KU-1 & KU-2 (Prestasi)',
      materi: 'Endurance Gaya Bebas & Kupu-kupu',
      pelatih: 'Coach Budi',
      kolam: 'Kolam Utama (Lintasan 1-4)',
      status: 'Terjadwal',
    ),
    JadwalLatihan(
      id: 'JDW-02',
      hari: 'Rabu',
      jam: '16:00 - 17:15 WIB',
      kelompok: 'Pemula',
      materi: 'Teknik Pernapasan & Meluncur',
      pelatih: 'Coach Sari',
      kolam: 'Kolam Latih',
      status: 'Berlangsung',
    ),
    JadwalLatihan(
      id: 'JDW-03',
      hari: 'Sabtu',
      jam: '07:00 - 09:30 WIB',
      kelompok: 'Semua KU',
      materi: 'Simulasi Lomba & Time Trial 50m/100m',
      pelatih: 'Coach Budi & Tim',
      kolam: 'Kolam Utama (Semua Lintasan)',
      status: 'Terjadwal',
    ),
  ];

  String _filterHari = 'Semua';
  final List<String> _opsiHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<String> _opsiStatus = ['Terjadwal', 'Berlangsung', 'Selesai'];

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
              content: SizedBox(
                width: 450,
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

                    setState(() {
                      if (isEdit) {
                        jadwalEdit.hari = pilihHari;
                        jadwalEdit.jam = jamController.text.trim();
                        jadwalEdit.kelompok = kelompokController.text.trim();
                        jadwalEdit.materi = materiController.text.trim();
                        jadwalEdit.pelatih = pelatihController.text.trim();
                        jadwalEdit.kolam = kolamController.text.trim();
                        jadwalEdit.status = pilihStatus;
                      } else {
                        final nomor = (_daftarJadwal.length + 1).toString().padLeft(2, '0');
                        _daftarJadwal.add(
                          JadwalLatihan(
                            id: 'JDW-$nomor',
                            hari: pilihHari,
                            jam: jamController.text.trim(),
                            kelompok: kelompokController.text.trim(),
                            materi: materiController.text.trim(),
                            pelatih: pelatihController.text.trim(),
                            kolam: kolamController.text.trim(),
                            status: pilihStatus,
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Filter Hari & Tombol Tambah
          Row(
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
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _tampilkanFormJadwal(),
                icon: const Icon(Icons.add_alarm, size: 18),
                label: const Text('Tambah Jadwal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daftar Kartu Jadwal Latihan
          if (dataTampil.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(child: Text('Belum ada jadwal latihan pada hari tersebut.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataTampil.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final jadwal = dataTampil[index];
                final isBerlangsung = jadwal.status == 'Berlangsung';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBerlangsung ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                      width: isBerlangsung ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Kotak Hari & Jam
                      Container(
                        width: 160,
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

                      // Detail Materi & Pelatih
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                const SizedBox(width: 10),
                                Text(
                                  jadwal.materi,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.pool, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(jadwal.kolam, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                const SizedBox(width: 20),
                                const Icon(Icons.sports, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(jadwal.pelatih, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Status & Tombol Aksi
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
                        onPressed: () {
                          setState(() => _daftarJadwal.removeWhere((item) => item.id == jadwal.id));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}