import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notes/model/notes_layout.dart';
import 'package:notes/model/search_field.dart';
import 'package:notes/screen/support%20screen/notes_view_screen.dart';
import 'package:notes/service/provider/database_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/ads_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  bool _isRefreshing = false;
  int _tapCounter = 0;
  final int _tapThreshold = 5;
  AdsManager? _adsManager;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<NoteProvider>(context, listen: false);
      await provider.loadNotes();

      _adsManager = AdsManager(
        noteIds: provider.notes.map((e) => e.id ?? 0).toList(),
        nativeAdId: 'ca-app-pub-7237142331361857/7184733369',
        bannerAdId: 'ca-app-pub-7237142331361857/1081972405',
        interstitialAdId: 'ca-app-pub-7237142331361857/4917662676',
      );

      try {
        await _adsManager?.initialize();
        setState(() {});
      } catch (e) {
        debugPrint('AdsManager initialization failed: $e');
      }
    });
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFirstTime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adsManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notesProvider = Provider.of<NoteProvider>(context);

    return PopScope(
      canPop: !(_adsManager?.isAdShowing ?? false),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Notes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              SearchField(
                searchNotes: _searchController,
                onChanged: (s) => setState(() => _query = s),
              ),
              SizedBox(height: 10),
              Expanded(child: bodyContent(notesProvider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget bodyContent(NoteProvider noteProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = noteProvider.notes;
    final filteredNotes = _query.isEmpty
        ? notes
        : notes
              .where(
                (n) => n.title.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
    if (_adsManager == null || noteProvider.isLoading || _isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notes.isEmpty) {
      return Center(
        child: Text(
          'No notes found!',
          style: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
        ),
      );
    }
    if (filteredNotes.isEmpty) {
      return Center(
        child: Text(
          'No notes match your search',
          style: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
        ),
      );
    }
    return RefreshIndicator(
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
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: const EdgeInsets.only(bottom: 70),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: filteredNotes.length + _adsManager!.adPositions.length,
            itemBuilder: (context, index) {
              // Sorted ad indices
              final adIndices = _adsManager!.adPositions.keys.toList()..sort();

              if (_adsManager!.adPositions.containsKey(index)) {
                final adWidget = _adsManager?.getAdWidget(index);
                if (adWidget != null) return adWidget;
              }

              final noteIndex =
                  index - adIndices.where((i) => i < index).length;
              if (noteIndex < 0 || noteIndex >= filteredNotes.length) {
                return const SizedBox.shrink();
              }

              final note = filteredNotes[noteIndex];
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _tapCounter++;
                  if (_tapCounter >= _tapThreshold) {
                    _tapCounter = 0; // reset counter
                    if (_adsManager != null) {
                      _adsManager?.showInterstitial();
                    }
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteViewScreen(
                        note: note,
                        onReload: () => Provider.of<NoteProvider>(
                          context,
                          listen: false,
                        ).loadNotes(),
                      ),
                    ),
                  );
                },
                child: NotesLayout(
                  note: note,
                  onUpdated: () => Provider.of<NoteProvider>(
                    context,
                    listen: false,
                  ).loadNotes(),
                  noteId: note.id ?? 0,
                  isFavorite: note.isFavorite,
                  onFavoriteChanged: () => Provider.of<NoteProvider>(
                    context,
                    listen: false,
                  ).favoriteNotes(note),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _checkFirstTime() async {
    final colorScheme = Theme.of(context).colorScheme;
    final prefs = await SharedPreferences.getInstance();
    final seenDialog = prefs.getBool('seenDialog') ?? false;

    if (!seenDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFirstTimeDialog(colorScheme);
      });
      await prefs.setBool('seenDialog', true);
    }
  }

  void _showFirstTimeDialog(ColorScheme colorScheme) {
    showDialog(
      context: context,
      barrierDismissible: false, // must tap button to dismiss
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
        title: Text(
          "Just a Heads-Up",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: colorScheme.primary,
          ),
        ),
        content: Text(
          "If you uninstall the app, your saved notes will be permanently deleted. "
          "Make sure to back up anything important before removing the app."
          "Thanks for using Notes!",
          style: TextStyle(color: colorScheme.onPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Got it!", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> refreshNotes() async {
    setState(() => _isRefreshing = true);
    _adsManager?.refreshAds();
    setState(() => _isRefreshing = false);
  }
}
