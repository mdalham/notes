import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notes/model/notes_layout.dart';
import 'package:notes/screen/support%20screen/notes_view_screen.dart';
import 'package:provider/provider.dart';
import '../../service/database/table/folder.dart';
import '../../service/provider/database_provider.dart';
import '../../model/ads_manager.dart';

class FolderNotesItemNotes extends StatefulWidget {
  final Folders folder;
  const FolderNotesItemNotes({super.key, required this.folder});

  @override
  State<FolderNotesItemNotes> createState() => _FolderNotesItemNotesState();
}

class _FolderNotesItemNotesState extends State<FolderNotesItemNotes> {
  AdsManager? _adsManager;
  bool _isRefreshing = false;
  int _tapCounter = 0;
  final int _tapThreshold = 5;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<NoteProvider>(context, listen: false);
      await provider.loadNotes();

      _adsManager = AdsManager(
        noteIds: provider.notes.map((e) => e.id ?? 0).toList(),
        nativeAdId: 'ca-app-pub-7237142331361857/6292566903',
        bannerAdId: 'ca-app-pub-7237142331361857/7460617846',
        interstitialAdId: 'ca-app-pub-7237142331361857/2520842858',
      );
      _adsManager!.initialize();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _adsManager!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final folderNotes = provider.notes
        .where((note) => note.folderId == widget.folder.id)
        .toList();
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop:!(_adsManager?.isAdShowing ?? false),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary),
          ),
          title: Text(
            widget.folder.folderName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        body: _adsManager == null || provider.isLoading || _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : folderNotes.isEmpty
            ? Center(
                child: Text(
                  "No notes in this folder",
                  style: TextStyle(fontSize: 18, color: colorScheme.onPrimary),
                ),
              )
            : RefreshIndicator(
                displacement: 20,
                edgeOffset: 0,
                color: Colors.blue,
                backgroundColor: Colors.white,
                onRefresh: refreshNotes,
                child: ValueListenableBuilder(
                  valueListenable: _adsManager!.loadedAdsCount,
                  builder: (context, _, __) {
                    return MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      padding: const EdgeInsets.all(10),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount:
                          folderNotes.length + _adsManager!.adPositions.length,
                      itemBuilder: (context, index) {
                        final adIndices = _adsManager!.adPositions.keys.toList()
                          ..sort();

                        if (_adsManager!.adPositions.containsKey(index)) {
                          final adWidget = _adsManager!.getAdWidget(index);
                          if (adWidget != null) return adWidget;
                        }

                        final noteIndex =
                            index - adIndices.where((i) => i < index).length;
                        if (noteIndex < 0 || noteIndex >= folderNotes.length) {
                          return const SizedBox.shrink();
                        }
                        final note = folderNotes[noteIndex];
                        return GestureDetector(
                          onTap: () async {
                            _tapCounter++;
                            if (_tapCounter >= _tapThreshold) {
                              _tapCounter = 0; // reset counter
                              if (_adsManager != null) {
                                _adsManager!.showInterstitial();
                              }
                            }
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteViewScreen(
                                  note: note,
                                  onReload: provider.loadNotes,
                                ),
                              ),
                            );
                            if (result == true) await provider.loadNotes();
                          },
                          child: NotesLayout(
                            key: ValueKey(note.id),
                            note: note,
                            noteId: note.id!,
                            isFavorite: note.isFavorite,
                            onFavoriteChanged: () => provider.favoriteNotes(note),
                            onUpdated: () => provider.loadNotes(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> refreshNotes() async {
    setState(() => _isRefreshing = true);
    _adsManager?.refreshAds();
    setState(() => _isRefreshing = false);
  }
}
