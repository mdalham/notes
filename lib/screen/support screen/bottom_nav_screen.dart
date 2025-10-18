import 'package:flutter/material.dart';
import 'package:notes/screen/support%20screen/add_or_edit_screen.dart';
import 'package:provider/provider.dart';
import '../../service/provider/database_provider.dart';
import '../main screen/favorite_screen.dart';
import '../main screen/folder_screen.dart';
import '../main screen/home_screen.dart';
import '../main screen/setting_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late final List<Widget> _screen;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _screen = [
      const HomeScreen(),
      const FavoriteScreen(),
      const FolderScreen(),
      const SettingScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notesProvider = Provider.of<NoteProvider>(context);
    final activeColor = colorScheme.onSurface;
    final inactiveColor = colorScheme.onPrimary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _screen),
            Positioned(
              bottom: 10,
              left: 14,
              right: 14,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outline, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildBottomBarIcon(0, activeColor, inactiveColor),
                    buildBottomBarIcon(1, activeColor, inactiveColor),
                    SizedBox(width: 80),
                    buildBottomBarIcon(2, activeColor, inactiveColor),
                    buildBottomBarIcon(3, activeColor, inactiveColor),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 14.5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  child: FloatingActionButton(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddOrEditScreen(onReload: notesProvider.loadNotes),
                        ),
                      );
                      if(result == true){
                        setState(() {
                        });
                        notesProvider.loadNotes();
                      }
                    },
                    elevation: 0,
                    heroTag: 'fab_home',
                    backgroundColor: colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(color: colorScheme.outline, width: 1.5),
                    ),
                    child: Image.asset(
                      'asset/strokIcons/add.png',
                      width: 28,
                      height: 28,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomBarIcon(int index, Color activeColor, Color inactiveColor) {
    final isSelected = _currentIndex == index;
    final iconName = ['home', 'heart', 'folder', 'setting'];
    final imageAsset = iconName[index];

    return IconButton(
      onPressed: () {
        FocusScope.of(context).unfocus();
        onTabChanged(index);
      },
      icon: Image.asset(
        isSelected
            ? 'asset/filledIcons/$imageAsset.png'
            : 'asset/strokIcons/$imageAsset.png',
        width: 28,
        height: 28,
        color: isSelected ? activeColor : inactiveColor,
      ),
    );
  }

  void onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
