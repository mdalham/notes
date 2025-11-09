import 'package:flutter/material.dart';
import 'custom_container.dart';
import 'custom_menu.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? subMaxLines;
  final List<String> menuTitles;
  final List<VoidCallback> menuCallbacks;

  const CustomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.subMaxLines,
    required this.menuTitles,
    required this.menuCallbacks,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CustomContainer(
      color: colorScheme.primaryContainer,
      circularRadius: 12,
      outlineColor: colorScheme.outline,
      child: ListTile(
        leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Image.asset('asset/strokIcons/note.png', color: Colors.grey,scale: 0.6,)
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 9, color: colorScheme.onPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: GestureDetector(
          onTapDown: (details) {
            customMenuWidget(
              context: context,
              position: details.globalPosition,
              titles: menuTitles,
              onTapCallbacks: menuCallbacks,
              colorScheme: colorScheme,
            );
          },
          child: Icon(Icons.more_vert, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
