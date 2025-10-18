import 'package:flutter/material.dart';

class SearchField extends StatefulWidget {
  final TextEditingController? searchNotes;
  final ValueChanged<String>? onChanged;
  const SearchField({super.key, this.searchNotes, this.onChanged});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _searchNotes;

  @override
  void initState() {
    super.initState();
    _searchNotes = widget.searchNotes ?? TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    if(widget.searchNotes == null){
      _searchNotes.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline),
        ),
        child: TextField(
          onTapOutside: (event) {
            FocusManager.instance.primaryFocus!.unfocus();
          },
          controller: _searchNotes,
          style: TextStyle(color: colorScheme.onPrimary),
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: colorScheme.onPrimary),
            suffixIcon: _searchNotes.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchNotes.clear();
                      if (widget.onChanged != null) {
                        widget.onChanged!('');
                      }
                      setState(() {});
                    },
                    child: Icon(Icons.close, color: colorScheme.onPrimary),
                  )
                : null,
            hintText: 'Search notes...',
            hintStyle: TextStyle(color: colorScheme.onPrimary,),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}
