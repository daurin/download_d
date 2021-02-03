import 'dart:io';
import 'package:ext_storage/ext_storage.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:path/path.dart';
import 'package:download_d/modules/global/services/download/download_http_helper.dart';
import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
import 'package:download_d/modules/global/views/widgets/slider_hide_margin_track_shape.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_ex/path_provider_ex.dart';

class AddTaskDetails extends StatefulWidget {
  final String link;
  final DownloadTask task;
  final void Function(DownloadTask task) onChangeDownloadTask;
  final FocusNode fileNameFocus;
  final void Function() onTapDownloadPath;

  AddTaskDetails({
    Key key,
    @required this.link,
    @required this.task,
    this.onChangeDownloadTask,
    this.fileNameFocus,
    this.onTapDownloadPath,
  }) : super(key: key);

  @override
  _AddTaskDetailsState createState() => _AddTaskDetailsState();
}

class _AddTaskDetailsState extends State<AddTaskDetails> {
  TextEditingController _fileNameController;
  DownloadTask _task;
  double _limitDownloadSpeed;

  @override
  void initState() {
    super.initState();
    // _task=DownloadTask(
    //   idCustom: DateTime.now().millisecondsSinceEpoch.toString(),
    //   saveDir: DownloadFileService().preferences.downloadPath,
    // );
    _task = widget.task;
    _fileNameController = TextEditingController(
      text: _task?.fileName ?? '',
    );
    _limitDownloadSpeed = (_task?.limitBandwidth?.inKilobytes ?? 0) > 0
        ? _task.limitBandwidth.inKilobytes?.toDouble()
        : DataSize(megabytes: 2).inKilobytes.toDouble();
  }

  @override
  void dispose() {
    _fileNameController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _fileNameController,
          onChanged: (String value) {
            _changeDownloadTask(_task.copyWith(
              fileName: value,
            ));
          },
          maxLines: 1,
          focusNode: widget.fileNameFocus,
          scrollPadding: EdgeInsets.zero,
          keyboardType: TextInputType.multiline,
          // enabled: _fileNameController == null,
          decoration: InputDecoration(
            labelText: 'Nombre',
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
          ),
        ),
        ListTile(
          title: Text('Tamaño'),
          subtitle: Text(_task?.size != null ? _task.size.format() : ''),
        ),
        ListTile(
          title: Text('Ruta'),
          subtitle: Text(_task?.saveDir ?? ''),
          onTap: () => _onTapDownloadPath(context),
        ),
        ListTile(
          title: Text('limitar de ancho de banda'),
          subtitle: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 20),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackShape: SliderHideMarginTrackShape(),
                    ),
                    child: Slider(
                      value: _limitDownloadSpeed,
                      divisions: 100,
                      min: DataSize(kilobytes: 20).inKilobytes.toDouble(),
                      max: DataSize(megabytes: 2).inKilobytes.toDouble(),
                      onChangeEnd: (value) {
                        _changeDownloadTask(_task.copyWith(
                          limitBandwidth: value ==
                                  DataSize(megabytes: 2).inKilobytes.toDouble()
                              ? DataSize.zero
                              : DataSize(
                                  kilobytes: _limitDownloadSpeed.toInt(),
                                ),
                        ));
                      },
                      onChanged: (value) {
                        setState(() {
                          _limitDownloadSpeed = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              LimitedBox(
                maxWidth: 70,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Builder(builder: (context) {
                    String text;
                    if (_limitDownloadSpeed >=
                        DataSize(megabytes: 2).inKilobytes.toInt())
                      text = 'Max';
                    else
                      text = DataSize(
                            kibibytes: _limitDownloadSpeed.toInt(),
                          ).format(
                            decimals: _limitDownloadSpeed > 1048 ? 1 : 0,
                          ) +
                          '/s';
                    return Text(text);
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changeDownloadTask(DownloadTask task) {
    _task = task;
    if (widget.onChangeDownloadTask != null) widget.onChangeDownloadTask(_task);
  }

  void _onTapDownloadPath(BuildContext context) async {
    String rootDir = await ExtStorage.getExternalStorageDirectory();
    if (rootDir != null) {
      widget.onTapDownloadPath?.call();
      String path = await FilesystemPicker.open(
        title: 'Carpeta para descargas',
        context: context,
        rootDirectory: Directory(rootDir),
        fsType: FilesystemType.folder,
        pickText: 'Seleccionar esta carpeta',
        // folderIconColor: Colors.teal,
      );
      if (path != null) {
        _changeDownloadTask(_task.copyWith(
          saveDir: path,
        ));
      }
    }
  }
}
