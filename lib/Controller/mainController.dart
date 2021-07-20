import 'dart:async';
import 'dart:math';
import 'package:async/async.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:uuid/uuid.dart';


enum UploadState {
  waiting,
  uploading,
  uploaded,
}

void noop() => {};

typedef void ChangeListener(Iterable<FileUploadStatus> statuses);

class mainController extends GetxController {

  static const int _MAX_SIMULTANEOUS_UPLOADING_FILES = 3;
  static const int _MAX_FILES_TOTAL = 30;

  static const int UPLOAD_DURATION_MIN = 1;
  static const int UPLOAD_DURATION_MAX = 5;

  late  BuiltList<FileUploadStatus>  _uploadStatuses;
  late  BuiltMap<String, CancelableOperation> _uploadOperations;
  late  BuiltList<ChangeListener>_changeListeners;

  final Random _random;
  final Uuid _uuid;

  mainController(): _random = Random(),  _uuid = Uuid() {
    // TODO load state from persistence

     _uploadStatuses = BuiltList() ;
    _changeListeners = BuiltList() ;
      _uploadOperations = BuiltMap();
     update();
  }

  VoidCallback addItemsChangeListener(ChangeListener listener) {
    _changeListeners = _changeListeners.rebuild((list) => list.add(listener));
    update();
    return () { removeItemsChangeListener(listener); };

  }

  void removeItemsChangeListener(ChangeListener listener) {
    _changeListeners = _changeListeners.rebuild((list) => list.remove(listener));
    update();
  }

  String upload(String namePrefix) {
    if (_uploadStatuses.length == _MAX_FILES_TOTAL) {
      throw 'max_limit_error';
    }
    final needWait = _getCountByState(UploadState.uploading) == _MAX_SIMULTANEOUS_UPLOADING_FILES;
    UploadState uploadState = needWait ? UploadState.waiting : UploadState.uploading;
    final id = _uuid.v1();
    _uploadStatuses = _uploadStatuses.rebuild((statuses) {
      statuses.add(FileUploadStatus(id, uploadState, '$namePrefix${id.substring(0, 5)}'));
    });
    if (!needWait) {
      _startUploading(id);
    }
    _notify();
    update();
    return id;

  }

  void _startUploading(String id) {
    CancelableOperation co = CancelableOperation.fromFuture(
      Future.delayed(Duration(seconds: UPLOAD_DURATION_MIN + _random.nextInt(UPLOAD_DURATION_MAX))),
      onCancel: () => _handleOperationCancelled(id),
    );

    _uploadOperations = _uploadOperations.rebuild((operations) => operations[id] = co);

    co.value.then((_) => _handleOperationDone(id));
    update();
  }

  int _getCountByState(UploadState state) =>
      _uploadStatuses.where((FileUploadStatus file) => file.state == state).toList().length;

  bool canReset() {
    update();
    return _uploadStatuses.length > 0;

  }

  bool canSave() {
    update();
    return _uploadStatuses.length > 0 && _getCountByState(UploadState.uploaded) == _uploadStatuses.length;

  }

  int get fileCount => _uploadStatuses.length;

  bool isFileCountLimit() => _uploadStatuses.length == _MAX_FILES_TOTAL;

  Future<void> save() async {

    if(!canSave()) {
      throw 'save_error';

    }

    // TODO persist state
    update();

  }

  bool reset() {

    if (!canReset()) {
      return false;
    }
    _uploadOperations.forEach((id, co) => co.cancel());
    _uploadOperations = BuiltMap();
    _uploadStatuses = BuiltList();
    _notify();
    update();
    return true;

  }

  dynamic appendFile() {
    update();
    return upload('Файл #');

  }

  String getId(int index) => _uploadStatuses.toList()[index].id;
  void delete(String id) {
    _uploadOperations = _uploadOperations.rebuild((map) {
      CancelableOperation? co = map.remove(id);
      if (co != null) {
        co.cancel();
      }
      _uploadStatuses = _uploadStatuses.rebuild((statuses) {
        statuses.removeWhere((status) => status.id == id);
      });
      _notify();
          });

     _handleUploadStatusesCountDecreased();
    update();
  }

  Iterable<FileUploadStatus> get fileUploadStatuses => _uploadStatuses.toBuiltList();

  _handleOperationDone(String id) {
    int index = _uploadStatuses.indexWhere((FileUploadStatus s) => s.id == id);
    FileUploadStatus targetElement = _uploadStatuses[index];

    _uploadStatuses = _uploadStatuses.rebuild((statuses) {
      statuses[index] = targetElement.setState(UploadState.uploaded);
    });

    _uploadOperations = _uploadOperations.rebuild((ops) => ops.remove(id));

    _notify();

    _handleUploadStatusesCountDecreased();
    update();
    return targetElement;

  }

  _handleOperationCancelled(String id) {
    _uploadStatuses = _uploadStatuses.rebuild((ss) => ss.removeWhere((s) => s.id == id));

    _uploadOperations = _uploadOperations.rebuild((ops) => ops.remove(id));

    _notify();

    _handleUploadStatusesCountDecreased();
    update();
  }

  // done/delete/cancelled
  _handleUploadStatusesCountDecreased() {
    int uploading = _getCountByState(UploadState.uploading);
    int waiting = _getCountByState(UploadState.waiting);
    int vacant = _MAX_SIMULTANEOUS_UPLOADING_FILES - uploading;

    if (vacant > 0 && waiting > 0) {
      _uploadStatuses = _uploadStatuses.rebuild((statuses) {
        statuses.map((status) {
          if (status.state == UploadState.waiting && vacant > 0 && waiting > 0) {
            final newStatus = status.setState(UploadState.uploading);

            _startUploading(status.id);

            vacant--;
            waiting--;

            return newStatus;
          }

          return status;

        });
      });
    } update();
  }

  Future getUploadFuture(String id) {
    if (_uploadOperations[id] != null) {
      return _uploadOperations[id]!.value;
    }update();
    return Future.value();

  }

  _notify() {
    _changeListeners.forEach((Function cb) => cb(fileUploadStatuses));
    update();
  }
  
}

@immutable
class FileUploadStatus {
  final String id;
  final UploadState state;
  final String name;

  FileUploadStatus(this.id, this.state, this.name);

 FileUploadStatus setState(UploadState state) => FileUploadStatus(id, state, name);
  //final user = FileUploadStatus(this.id, this.state, this.name).obs;

}


