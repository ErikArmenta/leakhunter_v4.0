import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Asset loader test', () async {
    try {
      final data = await rootBundle.load('assets/tiles/-2/7/4.png');
      print('SUCCESFULLY LOADED TILE! Size: ${data.lengthInBytes} bytes');
    } catch (e) {
      print('FAILED TO LOAD TILE: $e');
    }
    try {
      final data0 = await rootBundle.load('assets/tiles/0/0/0.png');
      print('SUCCESFULLY LOADED 0/0/0.png! Size: ${data0.lengthInBytes} bytes');
    } catch (e) {
      print('FAILED TO LOAD 0/0/0.png: $e');
    }
  });
}
