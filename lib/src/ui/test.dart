import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _salesMessage = "";
  String _locationMessage = "";

  void _updateSalesMessage(String message) {
    setState(() {
      _salesMessage = message;
    });
  }

  void _updateLocationMessage(String message) {
    setState(() {
      _locationMessage = message;
    });
  }

  void _getCurrentLocation() async {
    String location = await _fetchLocation();
    _updateLocationMessage(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doanh số và tọa độ'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _showSalesInputDialog(context, _updateSalesMessage);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black, // Màu chữ trong nút
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20), // Đặt border radius cho nút
                ),
              ),
              child: const Text('Popup Doanh Số'),
            ),
            const SizedBox(height: 20),
            Text(
              _salesMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black, // Màu chữ trong nút
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20), // Đặt border radius cho nút
                ),
              ),
              child: const Text('Lấy tọa độ hiện tại'),
            ),
            const SizedBox(height: 20),
            Text(
              _locationMessage,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _showSalesInputDialog(
    BuildContext context, Function(String) updateSalesMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SalesInputDialog(updateSalesMessage: updateSalesMessage);
    },
    barrierDismissible: false,
  );
}

Future<String> _fetchLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Kiểm tra nếu dịch vụ định vị được bật.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return "Dịch vụ định vị không được bật.";
  }

  // Kiểm tra nếu quyền được cấp.
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return "Quyền định vị bị từ chối.";
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return "Quyền định vị bị từ chối vĩnh viễn.";
  }
  String formattedDate =
      DateFormat('yyyy-MM-dd – kk:mm:ss').format(DateTime.now());

  // Khi đã có quyền, lấy vị trí hiện tại.
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  return "Vị trí: ${position.latitude}, ${position.longitude}\nThời gian: $formattedDate";
}

class SalesInputDialog extends StatefulWidget {
  final Function(String) updateSalesMessage;

  const SalesInputDialog({required this.updateSalesMessage, super.key});

  @override
  _SalesInputDialogState createState() => _SalesInputDialogState();
}

class _SalesInputDialogState extends State<SalesInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");
  static const int _maxValue = 999999999999999; // Giá trị tối đa
  bool _shouldFormat = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_formatInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_formatInput);
    _controller.dispose();
    super.dispose();
  }

  void _formatInput() {
    if (!_shouldFormat) return;

    String currentText = _controller.text.replaceAll(',', '');
    int cursorPosition = _controller.selection.baseOffset;

    if (currentText.isNotEmpty) {
      if (currentText.startsWith('0')) {
        currentText = currentText.substring(1);
        cursorPosition = cursorPosition -
            1; // Adjust cursor position if leading zero is removed
      }
      try {
        int currentValue = int.parse(currentText);
        if (currentValue <= _maxValue) {
          String formattedText = _numberFormat.format(currentValue);
          cursorPosition = _calculateNewCursorPosition(
              _controller.text, formattedText, cursorPosition);

          _controller.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: cursorPosition),
          );
        } else {
          String formattedText = _numberFormat.format(_maxValue);
          _controller.value = TextEditingValue(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
        }
      } catch (e) {
        // Nếu xảy ra lỗi khi chuyển đổi chuỗi thành số nguyên
      }
    }
  }

  int _calculateNewCursorPosition(
      String originalText, String formattedText, int originalCursorPosition) {
    int newCursorPosition = originalCursorPosition;

    int commaCountBeforeCursor = originalText
        .substring(0, originalCursorPosition)
        .replaceAll(RegExp(r'[^,]'), '')
        .length;
    int newCommaCountBeforeCursor = formattedText
        .substring(0, newCursorPosition)
        .replaceAll(RegExp(r'[^,]'), '')
        .length;

    newCursorPosition += newCommaCountBeforeCursor - commaCountBeforeCursor;

    return newCursorPosition;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập tổng tiền đơn hàng'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right, // Căn chỉnh văn bản nhập sang bên phải
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15), // Giới hạn số lượng ký tự
        ],
        decoration: const InputDecoration(
          labelText: 'Nhập số',
          border: OutlineInputBorder(),
        ),
        enableInteractiveSelection:
            true, // Cho phép di chuyển chuột để chọn vị trí
        onTap: () {
          setState(() {
            _shouldFormat =
                false; // Ngừng định dạng khi người dùng nhấn vào TextField
          });
        },
        onChanged: (text) {
          setState(() {
            _shouldFormat = true; // Cho phép định dạng khi người dùng nhập liệu
          });
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            // Xóa nội dung của TextField
            setState(() {
              _controller.clear();
            });
          },
          child: const Text('Nhập lại'),
        ),
        TextButton(
          onPressed: () {
            // Xử lý logic lưu doanh số ở đây
            String sales = _controller.text.replaceAll(',', '');
            if (sales.isEmpty) {
              // Hiển thị thông báo lỗi nếu input rỗng
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vui lòng nhập doanh số',
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.red, // Đổi màu nền thành đỏ
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                      top: 50.0,
                      left: 10.0,
                      right: 10.0), // Hiển thị phía trên màn hình
                ),
              );
            } else {
              try {
                int salesValue = int.parse(sales);
                if (salesValue <= _maxValue) {
                  // Hiển thị thông báo Doanh số và thời gian nhập
                  String formattedDate = DateFormat('dd-MM-yyyy – kk:mm:ss')
                      .format(DateTime.now());
                  widget.updateSalesMessage(
                      'Doanh số: $salesValue\nThời gian nhập: $formattedDate');
                  Navigator.of(context).pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Giá trị không hợp lệ',
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.red, // Đổi màu nền thành đỏ
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                        top: 50.0,
                        left: 10.0,
                        right: 10.0), // Hiển thị phía trên màn hình
                  ),
                );
              }
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
