import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/database/table/folder.dart';
import '../service/provider/database_provider.dart';
import 'custom_snackbar.dart';

class FolderModel extends StatefulWidget {
  final void Function(Folders) onSelected;
  final Folders? selectedFolder;
  final bool isNewNote;
  final folderController = TextEditingController();
  FolderModel({
    super.key,
    required this.onSelected,
    this.selectedFolder,
    this.isNewNote = false,
  });

  @override
  State<FolderModel> createState() => _FolderModelState();
}

class _FolderModelState extends State<FolderModel> {
  List<Folders> folderItems = [];
  Folders? selectedFolderItem;

  @override
  void initState() {
    super.initState();
    selectedFolderItem = widget.isNewNote ? null : widget.selectedFolder;
    _loadFolders();
  }

  @override
  void didUpdateWidget(covariant FolderModel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isNewNote &&
        widget.selectedFolder != oldWidget.selectedFolder) {
      selectedFolderItem = widget.selectedFolder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outline,
                        width: 1.5,
                      )
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                      child: DropdownButtonFormField<int?>(
                        value: folderItems.any((f) => f.id == selectedFolderItem?.id)
                            ? selectedFolderItem?.id
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Select Folder',
                          labelStyle: TextStyle(fontSize: 10, color: colorScheme.onPrimary),
                          border: InputBorder.none
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None', style: TextStyle(fontSize: 14,color: colorScheme.onSurface)),
                          ),
                          ...folderItems.map(
                                (folder) => DropdownMenuItem<int?>(
                              value: folder.id,
                              child: Text(
                                folder.folderName,
                                style: TextStyle(fontSize: 14, color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (folderId) {
                          setState(() {
                            selectedFolderItem = folderItems.firstWhereOrNull(
                                  (f) => f.id == folderId,
                            );
                          });
                          if (selectedFolderItem != null) {
                            widget.onSelected(selectedFolderItem!);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outline,
                        width: 1.5
                      )
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final added = await _showNewFolderField(
                          context,
                          colorScheme,
                          widget.folderController,
                        );
                        if (!added || widget.folderController.text.isEmpty) {
                          return;
                        }

                        final folderName = widget.folderController.text.trim();
                        final provider = Provider.of<NoteProvider>(
                          context,
                          listen: false,
                        );

                          if (provider.folders.any(
                                (f) =>
                            f.folderName.toLowerCase() == folderName.toLowerCase(),
                          )) {
                            CustomSnackBar.show(
                              context,
                              message: "Folder name already exists!",
                              backgroundColor: Colors.red,
                              icon: Icons.warning_amber_rounded,
                            );
                            return;
                          }
                        final newFolder = await provider.addFolder(folderName);
                        await _reloadFoldersAfterAdd(newFolder);
                        widget.folderController.clear();
                      },
                      child:  Icon(Icons.add, size: 40,color: colorScheme.onPrimary,),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reloadFoldersAfterAdd(Folders newFolder) async {
    final provider = Provider.of<NoteProvider>(context, listen: false);
    await provider.loadFolders();
    if (!mounted) return;

    final ids = <int>{};
    folderItems = provider.folders
        .where((f) => f.id != null)
        .where((f) => ids.add(f.id!))
        .toList();

    setState(() {
      // pick new folder or fallback to last one
      selectedFolderItem = folderItems.firstWhereOrNull(
            (f) => f.id == newFolder.id,
      ) ??
          folderItems.lastOrNull;
    });

    if (selectedFolderItem != null) {
      widget.onSelected(selectedFolderItem!);
    }
  }

  Future<void> _loadFolders() async {
    final provider = Provider.of<NoteProvider>(context, listen: false);
    await provider.loadFolders();
    if (!mounted) return;

    final ids = <int>{};
    folderItems = provider.folders
        .where((f) => f.id != null)
        .where((f) => ids.add(f.id!))
        .toList();

    setState(() {
      selectedFolderItem = widget.isNewNote
          ? null
          : folderItems.firstWhereOrNull(
            (f) => f.id == widget.selectedFolder?.id,
      );
    });

    if (selectedFolderItem != null) {
      widget.onSelected(selectedFolderItem!);
    }
  }

  Future<bool> _showNewFolderField(
      BuildContext context,
      ColorScheme colorScheme,
      TextEditingController folderController,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: colorScheme.outline,
                width: 1.5
            )),
        title: Center(
          child: Text("New Folder", style: TextStyle(fontSize: 22, color: colorScheme.primary)),
        ),
        content: Container(
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline,
              width: 1.5
            )
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextFormField(
              controller: folderController,
              decoration: InputDecoration(
                hintText: 'Enter a folder name..',
                hintStyle: TextStyle(color: colorScheme.onPrimary),
                border: InputBorder.none,
              ),
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

