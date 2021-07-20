import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_work/Controller/mainController.dart';

class SecondPage extends StatelessWidget {
  final mainController controller = Get.find();
  @override
  Widget build(BuildContext context) {
    return
   Scaffold(
        appBar: AppBar(
          title: Text("Файлы"),
        ),
        body: Container(
          child: GetBuilder<mainController>(
    builder: (_) => _buildFileList()),
        ),
        floatingActionButton: Visibility(visible: !controller.isFileCountLimit(), child: FloatingActionButton(
          onPressed:(){controller.appendFile();

          },
          tooltip: 'Add file',
          child: Icon(Icons.add),
        ),
        ));
  }

  Widget _buildFileList() {
   dynamic statuses=controller.fileUploadStatuses;
    if (statuses.isEmpty) {
      return Center(
          child: Text('Нет файлов')
      );
    }

    return ListView.builder(
        itemCount: statuses.length,
        itemBuilder: (context, i) {
          final subtitle = {
            UploadState.uploaded: '',
            UploadState.uploading: 'Загружается',
            UploadState.waiting: 'В ожидании'
          }[statuses[i].state];

          return  GetBuilder<mainController>(
              builder: (_) =>ListTile(
            title: Text(statuses[i].name),
            trailing: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
               controller.delete(controller.getId(i));
              },
            ),
            subtitle: Text(subtitle!),

          ));
        }
    );
  }

}
