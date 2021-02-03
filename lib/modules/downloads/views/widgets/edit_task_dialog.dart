import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:download_d/modules/downloads/views/widgets/add_task_dialog/add_task_details.dart';
import 'package:download_d/modules/global/services/download/download_http_helper.dart';
import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
import 'package:download_d/modules/global/views/widgets/list_tile_skeleton.dart';
import 'package:download_d/utils/debounce.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:string_validator/string_validator.dart';

class EditTaskDialog extends StatefulWidget {
  final String idTask;
  EditTaskDialog({
    Key key,
    @required this.idTask,
  }) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  TextEditingController _linkTextController;
  PageController _pageController;
  List<DownloadTask> _downloadTasks;
  List<String> _links;
  String _errorTextLink;
  int _selectedLinkIndex = 0;
  FocusNode _linkFocus;
  FocusNode _fileNameFocus;

  @override
  void initState() {
    super.initState();

    _linkTextController = TextEditingController();
    _pageController = PageController(
      initialPage: 0,
    );
    _downloadTasks = [];
    _linkFocus = FocusNode();
    _fileNameFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await _loadTask();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _linkTextController.dispose();
    _pageController?.dispose();
    _fileNameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      title: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Editar descarga'),
        actions: [
          ButtonBar(
            children: [
              IconButton(
                icon: Icon(Icons.save_rounded),
                onPressed: () async {
                  _onTapSave(context);
                },
              ),
            ],
          )
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LimitedBox(
                maxHeight: 150,
                child: TextField(
                  controller: _linkTextController,
                  focusNode: _linkFocus,
                  maxLines: null,
                  scrollPadding: EdgeInsets.zero,
                  keyboardType: TextInputType.multiline,
                  autocorrect: false,
                  autofocus: false,
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: _downloadTasks.length > 1 ? 'Enlaces' : 'Enlace',
                    alignLabelWithHint: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: EdgeInsets.all(16),
                    errorText: (_errorTextLink ?? '').length > 0
                        ? 'Debe espificar un enlace valido'
                        : null,
                    // suffix: SizedBox(
                    //   height: 15,
                    //   width: 15,
                    //   child: CircularProgressIndicator(
                    //     strokeWidth: 2.0,
                    //   ),
                    // ),
                    // suffixIcon: Visibility(
                    //   visible: _links.length > 1,
                    //   child: IconButton(
                    //     icon: Icon(
                    //       Icons.preview_rounded,
                    //       color: Theme.of(context).iconTheme.color,
                    //     ),
                    //     onPressed: () {},
                    //   ),
                    // ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_downloadTasks.length > 1) Divider(height: 1),

              Visibility(
                visible: _downloadTasks.length > 1 && _isValidLinks,
                child: ListTile(
                  // isThreeLine: true,
                  leading: Icon(Icons.link_rounded),
                  title: Text(
                    //  '1 de 5',
                    '${_selectedLinkIndex + 1} de ${_downloadTasks.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded),
                        onPressed: _selectedLinkIndex == 0
                            ? null
                            : () {
                                _pageController
                                    .jumpToPage(_selectedLinkIndex - 1);
                              },
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded),
                        onPressed:
                            _selectedLinkIndex == _downloadTasks.length - 1
                                ? null
                                : () {
                                    _pageController
                                        .jumpToPage(_selectedLinkIndex + 1);
                                  },
                      ),
                    ],
                  ),
                ),
              ),
              // TextField(
              //   controller: TextEditingController(text: 'filetest1.rar'),
              //   maxLines: 1,
              //   scrollPadding: EdgeInsets.zero,
              //   keyboardType: TextInputType.multiline,
              //   decoration: InputDecoration(
              //     labelText: 'Nombre',
              //     contentPadding: EdgeInsets.all(16),
              //     border: InputBorder.none,
              //   ),
              // ),
              Flexible(
                child: Container(
                  height: 290,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      setState(() {
                        _selectedLinkIndex = index;
                      });
                      if (_fileNameFocus.hasFocus) _fileNameFocus.unfocus();
                    },
                    //itemCount: _links.length == 0 ? 1 : _links.length,
                    itemCount: _downloadTasks.length,
                    itemBuilder: (context, index) {
                      DownloadTask task = _downloadTasks[index];
                      // return ListTileSkeleton();
                      if (task.status == null) {
                        return Column(
                          children:
                              List.generate(4, (index) => ListTileSkeleton()),
                        );
                      }
                      return AddTaskDetails(
                        key: ValueKey(
                            index.toString() + (task?.status?.value ?? '')),
                        task: task,
                        link: _downloadTasks[index].url,
                        fileNameFocus: _fileNameFocus,
                        onChangeDownloadTask: (DownloadTask task) {
                          setState(() {
                            _downloadTasks[index] = task;
                          });
                        },
                        onTapDownloadPath: () {
                          if (_linkFocus.hasFocus) _linkFocus.unfocus();
                          if (_fileNameFocus.hasFocus) _fileNameFocus.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text('Guardar'),
          onPressed: _isValidLinks ? () => _onTapSave(context) : null,
        ),
      ],
    );
  }

  bool get _isValidLinks =>
      _errorTextLink == null && _linkTextController.text.trim().length > 0;

  Future<void> _onTapSave(BuildContext context) async {
    for (var item in _downloadTasks) {
      await DownloadFileService().updateTask(
        item.idCustom,
        fileName: item.fileName,
        displayName: item.fileName,
        saveDir: item.saveDir,
        limitBandwidth: item.limitBandwidth,
      );
    }
    Navigator.pop(context);
  }

  Future<void> _loadTask() async {
    DownloadTask task = await DownloadFileService().findTask(widget.idTask);
    _linkTextController.text = task.url;
    _downloadTasks = [task];
  }
}
