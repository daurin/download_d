import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:flutter/material.dart';

class AddTaskFragment extends StatefulWidget {
  AddTaskFragment({Key key}) : super(key: key);

  @override
  _AddTaskFragmentState createState() => _AddTaskFragmentState();
}

class _AddTaskFragmentState extends State<AddTaskFragment> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      title: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Nueva descarga'),
        actions: [
          ButtonBar(
            children: [
              IconButton(
                icon: Icon(Icons.content_paste_rounded),
                onPressed: () {},
              )
            ],
          )
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ListTile(
                title: LimitedBox(
                  maxHeight: 110,
                  child: TextField(
                    maxLines: null,
                    decoration: InputDecoration.collapsed(
                      // prefixIcon: Icon(Icons.link_rounded),
                      // labelText: 'Enlaces',
                      hintText: 'Enlace',
                      // icon: Icon(Icons.link_rounded),
                      // suffixIcon: IconButton(
                      //   icon: Icon(Icons.preview_rounded),
                      //   onPressed: () {},
                      // ),

                      // border: UnderlineInputBorder(),
                      // filled: true,
                    ),
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                // isThreeLine: true,
                leading: Icon(Icons.link_rounded),
                title: Text(
                  // 'Opciones de descarga',
                  '1 de 15',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // subtitle: Text(
                //   'https://stackoverflow.com/questions/55277499/cant-increase-the-width-of-an-dialog-box-in-flutter',
                //   maxLines: 1,
                //   overflow: TextOverflow.visible,
                // ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text('Nombre'),
                subtitle: Text(DataSize(megabytes: 50).format()),
                trailing: IconButton(
                  icon: Icon(Icons.edit_rounded),
                  onPressed: (){},
                ),
              ),
              ListTile(
                title: Text('Tamaño'),
                subtitle: Text(DataSize(megabytes: 50).format()),
              ),
              ListTile(
                title: Text('Ruta'),
                subtitle: Text('/storage/emulated/0/downloads/'),
              ),
              ListTile(
            title: Text('Velocidad maxima descargas'),
            subtitle: Slider(
            value: 20,
            min: 1,
            max: 20,
            onChangeEnd: (value) {
              
            },
            onChanged: (value) {
              
            },
          ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
