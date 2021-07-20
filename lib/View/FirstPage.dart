import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_work/Controller/mainController.dart';


class FirstPage extends StatelessWidget {
  final mainController controller = Get.put(mainController());

  @override
  Widget build(BuildContext context) {
return  Scaffold(

    appBar: AppBar(
      title: Text('Start page'),
    ),
    body: Container(
      child: ListTile(
        title: Text("Файлы"),
        trailing: Icon(Icons.arrow_forward_ios),
        subtitle: GetBuilder<mainController>(
    builder: (_) => buildFileSubtitle()), //_buildFileSubtitle(),
        onTap: () => Get.toNamed('/page-two'),
      ),
    ),
    bottomNavigationBar: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[

        RaisedButton(
          child: Text('Сбросить'),
          onPressed: () {controller.reset() ? (){ controller.canReset(); } : null;
          }

        ),

        RaisedButton(
            child: Text('Сохранить'),
            onPressed:() {controller.canSave() ?controller.save(): null;
            controller.canSave() ?Get.snackbar('', 'Файлы сохранены',snackPosition:SnackPosition.BOTTOM):null;
            }
          //manager!.canSave() ? _handleClickSave : null,
        )

      ],
    )
);

}

buildFileSubtitle() {
  var statuses=controller.fileUploadStatuses;
  if (statuses.length == 0) {
    return Text("Нет файлов");
  }
  final countfile = statuses.where((status) => status.state != UploadState.uploaded).toList().length;
  if (countfile > 0) {
    return Text("Осталось загрузить: $countfile. Всего файлов: ${statuses.length}");
  }
  return Text("Всего файлов: ${statuses.length} ");
}
}


