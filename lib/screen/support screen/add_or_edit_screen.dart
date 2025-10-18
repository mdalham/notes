import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes/model/folder_model.dart';
import 'package:provider/provider.dart';
import '../../service/database/table/folder.dart';
import '../../service/database/table/note.dart';
import '../../service/provider/database_provider.dart';

class AddOrEditScreen extends StatefulWidget {
  final Notes? note;
  final VoidCallback onReload;

  const AddOrEditScreen({super.key, this.note, required this.onReload});

  @override
  State<AddOrEditScreen> createState() => _AddOrEditScreenState();
}

class _AddOrEditScreenState extends State<AddOrEditScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  final _tittleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Folders? _selectedFolderItem;
  bool isMarkedHeart = false;
  bool _hasChanged = false;
  late NoteProvider provider;
  Notes? _note;

  late String _initialTitle;
  late String _initialDescription;
  Folders? _initialFolderItem;
  late bool _initialHeart;

  @override
  void initState() {
    super.initState();
    _loadBanner();
    provider = Provider.of<NoteProvider>(context, listen: false);
    if (widget.note != null) {
      // Editing existing note
      _note = widget.note;
      _tittleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
      isMarkedHeart = widget.note!.isFavorite;

      if (widget.note!.folderId != null) {
        _loadSelectedFolder(widget.note!.folderId!);
      }
    } else {
      // New note → start with None folder
      _note = Notes(
        id: null,
        folderId: null,
        dateTime: DateTime.now().toIso8601String(),
        title: '',
        description: '',
        isFavorite: false,
      );
      _selectedFolderItem = null;
    }

    _initialTitle = _tittleController.text;
    _initialDescription = _descriptionController.text;
    _initialFolderItem = _selectedFolderItem;
    _initialHeart = isMarkedHeart;

    _tittleController.addListener(_checkChanges);
    _descriptionController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () async {
                bool canPop = await _leaveAlert();
                if (canPop) Navigator.of(context).pop(_note);
              },
              icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary),
            ),
            title: Text(
              widget.note == null ? 'Add Note' : 'Edit Note',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    isMarkedHeart = !isMarkedHeart;
                  });
                  _checkChanges();
                },
                icon: Image.asset(
                  isMarkedHeart
                      ? 'asset/filledIcons/heart.png'
                      : 'asset/strokIcons/heart.png',
                  width: 20,
                  height: 20,
                  color: isMarkedHeart ? Colors.red : colorScheme.onPrimary,
                ),
              ),
              IconButton(
                onPressed: _saveNote,
                icon: Image.asset(
                  'asset/filledIcons/saved.png',
                  width: 20,
                  height: 20,
                  color: colorScheme.onPrimary,
                ),
              ),
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
              padding: EdgeInsets.all(10),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    FolderModel(
                      isNewNote: widget.note == null,
                      selectedFolder: _selectedFolderItem,
                      onSelected: (folder) {
                        setState(() {
                          _selectedFolderItem = folder;
                        });
                        _checkChanges();
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _tittleController,
                      style: TextStyle(color: colorScheme.primary),
                      cursorColor: colorScheme.onSurface,
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus!.unfocus();
                      },
                      cursorWidth: 4,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Title...',
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.outline,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: colorScheme.primaryContainer,
                        filled: true,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter title...'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: colorScheme.onPrimary),
                      cursorColor: colorScheme.onSurface,
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus!.unfocus();
                      },
                      cursorWidth: 4,
                      maxLines: null,
                      minLines: 24,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Write here...',
                        hintStyle: TextStyle(color: colorScheme.onPrimary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.outline,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: colorScheme.primaryContainer,
                        filled: true,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Write something...'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    _note =
        _note?.copyWith(
          folderId: _selectedFolderItem?.id,
          title: _tittleController.text,
          description: _descriptionController.text,
          isFavorite: isMarkedHeart,
          dateTime: DateTime.now().toIso8601String(),
        ) ??
        Notes(
          id: null,
          folderId: _selectedFolderItem?.id,
          title: _tittleController.text,
          description: _descriptionController.text,
          isFavorite: isMarkedHeart,
          dateTime: DateTime.now().toIso8601String(),
        );

    await provider.addOrUpdateNotes(_note!);
    widget.onReload();

    setState(() {
      _hasChanged = false;

      _initialTitle = _tittleController.text;
      _initialDescription = _descriptionController.text;
      _initialFolderItem = _selectedFolderItem;
      _initialHeart = isMarkedHeart;
    });
    Navigator.pop(context, _note);
  }

  void _checkChanges() {
    bool changed =
        _tittleController.text != _initialTitle ||
        _descriptionController.text != _initialDescription ||
        _selectedFolderItem?.id != _initialFolderItem?.id ||
        isMarkedHeart != _initialHeart;

    setState(() => _hasChanged = changed);
  }

  Future<void> _loadSelectedFolder(int folderId) async {
    if (provider.folders.isEmpty) await provider.loadFolders();
    Folders? folder = provider.folders.firstWhere(
      (f) => f.id == folderId,
      orElse: () => provider.folders.first,
    );
    if (mounted) setState(() => _selectedFolderItem = folder);
  }

  Future<bool> _leaveAlert() async {
    final colorScheme = Theme.of(context).colorScheme;
    if (_hasChanged) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              elevation: 0,
              backgroundColor: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outline, width: 1.5),
              ),
              title: Text(
                'Oops! Unsaved Changes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              content: Text(
                'Looks like you have some unsaved notes. If you leave now, your changes will be lost. Want to save them first or continue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7237142331361857/1169989358', // Test Banner ID
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
