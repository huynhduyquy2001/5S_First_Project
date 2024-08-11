import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: InputPage(),
    );
  }
}

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _mtdController = TextEditingController();
  final TextEditingController _mtd1Controller = TextEditingController();
  final TextEditingController _mtd2Controller = TextEditingController();

  String _result = '';

  void _updateResult() {
    setState(() {
      StringBuffer sb = StringBuffer()
        ..write('Tọa độ: ')
        ..write(_latitudeController.text)
        ..write(',')
        ..write(_longitudeController.text)
        ..write('   MTD: ')
        ..write(_mtdController.text)
        ..write(', MTD2: ')
        ..write(_mtd1Controller.text)
        ..write(', MTD3: ')
        ..write(_mtd2Controller.text);
      _result = sb.toString();

      // Clear input fields
      _latitudeController.clear();
      _longitudeController.clear();
      _mtdController.clear();
      _mtd1Controller.clear();
      _mtd2Controller.clear();

      // Hide the keyboard
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập thông tin'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(
                  _latitudeController, 'Nhập vĩ độ', TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(
                  _longitudeController, 'Nhập kinh độ', TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(_mtdController, 'Nhập MTD', TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(
                  _mtd1Controller, 'Nhập MTD1', TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(
                  _mtd2Controller, 'Nhập MTD2', TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateResult,
                child: const Text('Lưu'),
              ),
              const SizedBox(height: 20),
              Text(
                _result,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      TextInputType keyboardType) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
