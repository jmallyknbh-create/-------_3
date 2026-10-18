 class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  static const String _storageKey = 'jamal_songs_v1';
  final List<Song> _songs = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List<dynamic>;
        _songs.clear();
        _songs.addAll(list.map((e) => Song.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_songs.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (_) {}
  }

  void _addSong(String title, String duration) {
    if (title.trim().isEmpty) return;
    setState(() {
      _songs.insert(
        0,
        Song(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.trim(),
          duration: duration.isEmpty ? '3:45' : duration,
        ),
      );
    });
    _saveSongs();
  }

  void _deleteSong(Song song) {
    setState(() => _songs.remove(song));
    _saveSongs();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight),
        ),
      );
    }

    final visibleSongs = _songs.where((s) =>
        s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع اغاني مازن كنبه'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // نافذة إضافة أغنية جديدة
          _showAddSongDialog();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة أغنية', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'بحث في الأغاني...',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
              ),
            ),
          ),
          Expanded(
            child: visibleSongs.isEmpty
                ? const Center(
                    child: Text('لا توجد أغاني مضافة بعد',
                        style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView.builder(
                    itemCount: visibleSongs.length,
                    itemBuilder: (context, index) {
                      final song = visibleSongs[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Icon(Icons.music_note_rounded, color: Colors.white),
                          ),
                          title: Text(song.title,
                              style: const TextStyle(color: AppTheme.textPrimary)),
                          subtitle: Text('المدة: ${song.duration}',
                              style: const TextStyle(color: AppTheme.textMuted)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.danger),
                            onPressed: () => _deleteSong(song),
                          ),
                          onTap: () {
                            // هنا يمكنك لاحقاً إضافة مشغل الصوت لتشغيل الأغنية
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('جاري تشغيل: ${song.title}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSongDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('إضافة أغنية جديدة',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'اسم الأغنية أو الشيلة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(hintText: 'المدة (مثلاً 4:30)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              _addSong(titleController.text, durationController.text);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}