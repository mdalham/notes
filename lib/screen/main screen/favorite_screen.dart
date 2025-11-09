import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notes/service/provider/database_provider.dart';
import 'package:provider/provider.dart';
import '../../model/notes_layout.dart';
import '../../model/ads_manager.dart';
import '../../service/database/table/note.dart';
import '../../service/provider/view_type_provider.dart';
import '../support screen/notes_view_screen.dart';
import '../../model/custom_list_tile.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
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
        nativeAdId: 'ca-app-pub-7237142331361857/2371390387',
        bannerAdId: 'ca-app-pub-7237142331361857/8306243347',
        interstitialAdId: 'ca-app-pub-7237142331361857/4614023301',
      );
      await _adsManager?.initialize();
      setState(() {});
    });
  }

  Future<void> refreshNotes() async {
    setState(() => _isRefreshing = true);
    _adsManager?.refreshAds();
    setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    _adsManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteProvider = Provider.of<NoteProvider>(context);
    final favoriteNotes = noteProvider.favoriteNotesList;
    final viewProvider = Provider.of<ViewTypeProvider>(context);
    final isGridView = viewProvider.isGridView;

    return PopScope(
      canPop: !(_adsManager?.isAdShowing ?? false),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Favorite notes',
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
            child:
                _adsManager == null || noteProvider.isLoading || _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : favoriteNotes.isEmpty
                ? Center(
                    child: Text(
                      'No favorite notes yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onPrimary,
                      ),
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
                        final totalCount =
                            favoriteNotes.length +
                            _adsManager!.adPositions.length;
                        final adIndices = _adsManager!.adPositions.keys.toList()
                          ..sort();

                        if (isGridView) {
                          // List view
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 70),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: totalCount,
                            itemBuilder: (context, index) {
                              if (_adsManager!.adPositions.containsKey(index)) {
                                final adWidget = _adsManager?.getAdWidget(
                                  index,
                                );
                                if (adWidget != null) return adWidget;
                              }

                              final noteIndex =
                                  index -
                                  adIndices.where((i) => i < index).length;
                              if (noteIndex < 0 ||
                                  noteIndex >= favoriteNotes.length) {
                                return const SizedBox.shrink();
                              }

                              final note = favoriteNotes[noteIndex];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
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
                                      () => noteProvider.favoriteNotes(note),
                                      () => _openNote(note),
                                      () => noteProvider.deleteNotes(
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
                            if (_adsManager!.adPositions.containsKey(index)) {
                              final adWidget = _adsManager?.getAdWidget(index);
                              if (adWidget != null) return adWidget;
                            }

                            final noteIndex =
                                index -
                                adIndices.where((i) => i < index).length;
                            if (noteIndex < 0 ||
                                noteIndex >= favoriteNotes.length) {
                              return const SizedBox.shrink();
                            }

                            final note = favoriteNotes[noteIndex];
                            return GestureDetector(
                              onTap: () => _openNote(note),
                              child: NotesLayout(
                                note: note,
                                onUpdated: () => noteProvider.loadNotes(),
                                noteId: note.id ?? 0,
                                isFavorite: note.isFavorite,
                                onFavoriteChanged: () =>
                                    noteProvider.favoriteNotes(note),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _openNote(Notes note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteViewScreen(
          note: note,
          onReload: () =>
              Provider.of<NoteProvider>(context, listen: false).loadNotes(),
        ),
      ),
    );
  }
}
