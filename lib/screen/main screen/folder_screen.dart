import 'package:flutter/material.dart';
import 'package:notes/screen/support%20screen/folder_notes_item_notes.dart';
import 'package:provider/provider.dart';
import '../../model/custom_snackbar.dart';
import '../../model/dialog_helper.dart';
import '../../service/database/table/folder.dart';
import '../../service/provider/database_provider.dart';
import '../../model/ads_manager.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Folders> selectedFolders = [];
  bool selectionMode = false; // true if long press activated
  bool isLoading = false;
  bool _isRefreshing = false;
  int _tapCounter = 0;
  final int _tapThreshold = 5;
  AdsManager? _adsManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<NoteProvider>(context, listen: false);
      await provider.loadFolders();

      _adsManager = AdsManager(
        noteIds: provider.notes.map((e) => e.id ?? 0).toList(),
        nativeAdId: 'ca-app-pub-7237142331361857/4071097828',
        bannerAdId: 'ca-app-pub-7237142331361857/6833379579',
        interstitialAdId: 'ca-app-pub-7237142331361857/5520297903',
      );
      _adsManager?.initialize();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _adsManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<NoteProvider>(context);
    final folders = provider.folders;

    return PopScope(
      canPop: !(_adsManager?.isAdShowing ?? false),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: selectionMode
              ? Text(
                  '${selectedFolders.length} selected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(
                  'Folders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
          leading: selectionMode
              ? IconButton(
                  icon: Icon(Icons.close, color: Colors.blue),
                  onPressed: exitSelectionMode,
                )
              : null,
          actions: selectionMode
              ? [
                  IconButton(
                    icon: Icon(Icons.delete, color: colorScheme.onPrimary),
                    onPressed: deleteSelectedFolders,
                  ),
                ]
              : null,
        ),
        body: _adsManager == null || isLoading || _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : folders.isEmpty
            ? Center(
                child: Text(
                  "No folders yet",
                  style: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
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
                    return ListView.builder(
                      physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: folders.length + _adsManager!.adPositions.length,
                      itemBuilder: (context, index) {
                        // Sorted ad indices
                        final adIndices = _adsManager!.adPositions.keys.toList()
                          ..sort();

                        if (_adsManager!.adPositions.containsKey(index)) {
                          final adWidget = _adsManager?.getAdWidget(index);
                          if (adWidget != null) return adWidget;
                        }

                        final noteIndex =
                            index - adIndices.where((i) => i < index).length;
                        if (noteIndex < 0 || noteIndex >= folders.length) {
                          return const SizedBox.shrink();
                        }

                        final folder = folders[noteIndex];
                        final isSelected = selectedFolders.contains(folder);

                        return GestureDetector(
                          onLongPress: () {
                            setState(() {
                              selectionMode = true;
                              toggleSelection(folder);
                            });
                          },
                          onTap: () {
                            if (selectionMode) {
                              toggleSelection(folder);
                            } else {
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
                                  builder: (_) =>
                                      FolderNotesItemNotes(folder: folder),
                                ),
                              );
                            }
                          },
                          child: Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.red
                                        : colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: ListTile(
                                    leading: selectionMode
                                        ? Checkbox(
                                            value: isSelected,
                                            onChanged: (value) {
                                              toggleSelection(folder);
                                            },
                                            checkColor: colorScheme.surface,
                                            fillColor: WidgetStateProperty.all(
                                              Colors.blue,
                                            ),
                                          )
                                        : Icon(
                                            Icons.folder,
                                            size: 55,
                                            color: colorScheme.onPrimary,
                                          ),
                                    title: Text(
                                      folder.folderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatDateTime(folder.folderDateTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    trailing: !selectionMode
                                        ? Icon(
                                            Icons.chevron_right,
                                            color: Colors.blue,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
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

  String _formatDateTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> deleteSelectedFolders() async {
    if (selectedFolders.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await DialogHelper.showConfirmationDialog(
      context: context,
      title: 'Delete Folder',
      message:
          "Are you sure you want to delete ${selectedFolders.length} folder's?",
    );

    if (!confirmed) return;

    final provider = Provider.of<NoteProvider>(context, listen: false);
    for (var folder in selectedFolders) {
      await provider.deleteFolder(folder.id!);
    }

    exitSelectionMode();
    _loadFolders();

    CustomSnackBar.show(
      context,
      message: "Folder's deleted successfully!",
      backgroundColor: Colors.redAccent,
      icon: Icons.delete_outline,
    );
  }

  Future<void> _loadFolders() async {
    setState(() => isLoading = true);
    final provider = Provider.of<NoteProvider>(context, listen: false);
    await provider.loadFolders();
    setState(() => isLoading = false);
  }

  void toggleSelection(Folders folder) {
    setState(() {
      if (selectedFolders.contains(folder)) {
        selectedFolders.remove(folder);
        if (selectedFolders.isEmpty) selectionMode = false;
      } else {
        selectedFolders.add(folder);
      }
    });
  }

  void exitSelectionMode() {
    setState(() {
      selectedFolders.clear();
      selectionMode = false;
    });
  }

  Future<void> refreshNotes() async {
    setState(() => _isRefreshing = true);
    _adsManager?.refreshAds();
    setState(() => _isRefreshing = false);
  }
}
