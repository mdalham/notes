import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notes/model/notes_layout.dart';
import 'package:notes/model/custom_list_tile.dart';
import 'package:notes/screen/support%20screen/notes_view_screen.dart';
import 'package:notes/service/provider/database_provider.dart';
import 'package:provider/provider.dart';
import '../../service/database/table/folder.dart';
import '../../service/database/table/note.dart';
import '../../service/provider/view_type_provider.dart';
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
      await _adsManager!.initialize();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _adsManager?.dispose();
    super.dispose();
  }

  Future<void> refreshNotes() async {
    setState(() => _isRefreshing = true);
    _adsManager?.refreshAds();
    await Provider.of<NoteProvider>(context, listen: false).loadNotes();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final folderNotes = provider.notes
        .where((note) => note.folderId == widget.folder.id)
        .toList();
    final colorScheme = Theme.of(context).colorScheme;
    final viewProvider = Provider.of<ViewTypeProvider>(context);
    final isGridView = viewProvider.isGridView;

    return PopScope(
      canPop: !(_adsManager?.isAdShowing ?? false),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.pop(context, true),
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _adsManager == null || provider.isLoading || _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : folderNotes.isEmpty
                ? Center(
                    child: Text(
                      "No notes in this folder",
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Notes list/grid
                      Expanded(
                        child: RefreshIndicator(
                          displacement: 20,
                          edgeOffset: 0,
                          color: Colors.blue,
                          backgroundColor: Colors.white,
                          onRefresh: refreshNotes,
                          child: ValueListenableBuilder(
                            valueListenable: _adsManager!.loadedAdsCount,
                            builder: (context, _, __) {
                              final totalCount =
                                  folderNotes.length +
                                  _adsManager!.adPositions.length;
                              final adIndices =
                                  _adsManager!.adPositions.keys.toList()
                                    ..sort();

                              if (isGridView) {
                                return ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 70),
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  itemCount: totalCount,
                                  itemBuilder: (context, index) {
                                    if (_adsManager!.adPositions.containsKey(
                                      index,
                                    )) {
                                      final adWidget = _adsManager?.getAdWidget(
                                        index,
                                      );
                                      if (adWidget != null) return adWidget;
                                    }

                                    final noteIndex =
                                        index -
                                        adIndices
                                            .where((i) => i < index)
                                            .length;
                                    if (noteIndex < 0 ||
                                        noteIndex >= folderNotes.length) {
                                      return const SizedBox.shrink();
                                    }

                                    final note = folderNotes[noteIndex];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _openNote(note),
                                        child: CustomListTile(
                                          title: note.title,
                                          subtitle: note.description,
                                          subMaxLines: 2,
                                          menuTitles: [
                                            note.isFavorite
                                                ? 'Unfavorite'
                                                : 'Favorite',
                                            'Edit',
                                            'Delete',
                                          ],
                                          menuCallbacks: [
                                            () => provider.favoriteNotes(note),
                                            () => _openNote(note),
                                            () => provider.deleteNotes(
                                              note.id ?? 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              return MasonryGridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                padding: const EdgeInsets.only(bottom: 70),
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                itemCount: totalCount,
                                itemBuilder: (context, index) {
                                  if (_adsManager!.adPositions.containsKey(
                                    index,
                                  )) {
                                    final adWidget = _adsManager?.getAdWidget(
                                      index,
                                    );
                                    if (adWidget != null) return adWidget;
                                  }

                                  final noteIndex =
                                      index -
                                      adIndices.where((i) => i < index).length;
                                  if (noteIndex < 0 ||
                                      noteIndex >= folderNotes.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final note = folderNotes[noteIndex];
                                  return GestureDetector(
                                    onTap: () => _openNote(note),
                                    child: NotesLayout(
                                      key: ValueKey(note.id),
                                      note: note,
                                      noteId: note.id!,
                                      isFavorite: note.isFavorite,
                                      onFavoriteChanged: () =>
                                          provider.favoriteNotes(note),
                                      onUpdated: () => provider.loadNotes(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _openNote(Notes note) {
    FocusScope.of(context).unfocus();
    _tapCounter++;
    if (_tapCounter >= _tapThreshold) {
      _tapCounter = 0;
      _adsManager?.showInterstitial();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteViewScreen(
          note: note,
          onReload: () =>
              Provider.of<NoteProvider>(context, listen: false).loadNotes(),
        ),
      ),
    );
  }
}
