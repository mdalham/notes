import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes/screen/support%20screen/add_or_edit_screen.dart';
import 'package:provider/provider.dart';
import '../../model/dialog_helper.dart';
import '../../service/database/database_helper.dart';
import '../../service/database/table/note.dart';
import '../../service/provider/database_provider.dart';

class NoteViewScreen extends StatefulWidget {
  final Notes note;
  final VoidCallback onReload;
  const NoteViewScreen({super.key, required this.note, required this.onReload});

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool isMarkedHeart = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;
  List<Notes> _allNotes = [];
  Notes? _note;

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _note = widget.note;
    _loadNotes();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final note = _note!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary),
        ),
        title: Text(
          'Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final provider = Provider.of<NoteProvider>(
                context,
                listen: false,
              );
              await provider.favoriteNotes(_note!);
              final updatedNote = provider.notes.firstWhere(
                (n) => n.id == _note!.id,
              );
              if (!mounted) return;
              setState(() {
                _note = updatedNote;
                _loadNotes();
              });
            },
            icon: Image.asset(
              _note!.isFavorite
                  ? 'asset/filledIcons/heart.png'
                  : 'asset/strokIcons/heart.png',
              width: 20,
              height: 20,
              color: _note!.isFavorite ? Colors.red : colorScheme.onPrimary,
            ),
          ),

          InkWell(
            onTap: () async {
              final updatedNote = await Navigator.push<Notes?>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddOrEditScreen(note: _note, onReload: _loadNotes),
                ),
              );

              if (updatedNote != null && mounted) {
                setState(() {
                  _note = updatedNote;
                });
                _loadNotes();
                widget.onReload();
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'asset/filledIcons/edit.png',
                width: 18,
                height: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          // Delete icon
          IconButton(
            onPressed: () async {
              final confirmed = await DialogHelper.showConfirmationDialog(
                context: context,
                title: 'Delete Note',
                message: 'Are you sure you want to delete this note?',
              );
              if (confirmed) {
                await _databaseHelper.deleteNote(widget.note.id!);
                widget.onReload();
                Navigator.pop(context);
              }
            },
            icon: Image.asset(
              'asset/filledIcons/delete.png',
              width: 20,
              height: 20,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      bottomNavigationBar: _isBannerLoaded
          ? Container(
        color: Colors.transparent,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : SizedBox.shrink(),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(note.dateTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: Text(
                        note.description,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onPrimary,
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<Notes?> getNoteById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Notes.fromMap(result.first);
    }
    return null;
  }

  Future<void> _loadNotes() async {
    final notes = await _databaseHelper.getNotes();
    if (!mounted) return;
    setState(() {
      _allNotes = notes;
      _isLoading = false;
    });
  }

  String _formatDateTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _loadBanner() {

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7237142331361857/2946105458', // Test Banner ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
}
