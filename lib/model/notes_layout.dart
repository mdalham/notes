import 'package:flutter/material.dart';
import 'package:notes/service/database/database_helper.dart';
import 'package:notes/service/database/table/note.dart';
import 'package:provider/provider.dart';
import '../screen/support screen/add_or_edit_screen.dart';
import '../service/provider/database_provider.dart';
import 'custom_snackbar.dart';
import 'dialog_helper.dart';

class NotesLayout extends StatefulWidget {
  final Notes note;
  final VoidCallback onUpdated;
  final int noteId;
  final bool isFavorite;
  final VoidCallback? onFavoriteChanged;

  const NotesLayout({
    super.key,
    required this.note,
    required this.onUpdated,
    required this.noteId,
    required this.isFavorite,
    this.onFavoriteChanged,
  });

  @override
  State<NotesLayout> createState() => _NotesLayoutState();
}

class _NotesLayoutState extends State<NotesLayout> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    final provider = Provider.of<NoteProvider>(
                      context,
                      listen: false,
                    );
                    provider.favoriteNotes(widget.note);
                  },
                  child: Image.asset(
                    widget.note.isFavorite
                        ? 'asset/filledIcons/heart.png'
                        : 'asset/strokIcons/heart.png',
                    width: 20,
                    height: 20,
                    color: widget.note.isFavorite
                        ? Colors.red
                        : colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => _editNote(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Image.asset(
                      'asset/filledIcons/edit.png',
                      width: 18,
                      height: 18,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _deleteNote(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(Icons.delete, color: colorScheme.onPrimary),
                ),
              ],
            ),
            Text(
              widget.note.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              _formatDateTime(widget.note.dateTime),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: colorScheme.onPrimary),
            ),
            SizedBox(height: 2),
            Text(
              widget.note.description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimary,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context) async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context: context,
      title: 'Delete Note',
      message: 'Are you sure you want to delete this note?',
    );
    if (confirmed) {
      await _databaseHelper.deleteNote(widget.note.id!);
      if (mounted) {
        widget.onUpdated.call();
        CustomSnackBar.show(
          context,
          message: "Note deleted successfully!",
          backgroundColor: Colors.redAccent,
          icon: Icons.delete_outline,
        );
      }
    }
  }

  Future<void> _editNote(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddOrEditScreen(note: widget.note, onReload: () {}),
      ),
    );

    if (result == true) {
      final provider = Provider.of<NoteProvider>(context, listen: false);
      await provider.loadNotes();
    }
  }

  String _formatDateTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
