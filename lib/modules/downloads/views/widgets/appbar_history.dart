import 'package:download_d/modules/settings/views/pages/settings_page.dart';
import 'package:flutter/material.dart';

class AppBarHistory extends StatelessWidget implements PreferredSizeWidget {
  final bool visibleResumeAll;
  const AppBarHistory({
    Key key,
    this.visibleResumeAll = false,
  }) : super(key: key);

  Size get preferredSize => Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("Historial"),
      actions: [
        ButtonBar(
          children: [
            IconButton(
              icon: Icon(Icons.settings_rounded),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsPage()));
              },
            ),
            // PopupMenuButton(
            //   icon: Icon(Icons.more_vert_rounded),
            //   onSelected: (value) {},
            //   itemBuilder: (context) {
            //     return [
            //       PopupMenuItem(
            //         child: Text('Configuracion'),
            //         value: 'settings',
            //       ),
            //     ];
            //   },
            // ),
          ],
        )
      ],
    );
  }
}
