import 'package:flutter_test/flutter_test.dart';
import 'package:room_rental_marketplace/theme.dart';

void main() {
  test('booking labels match designed status colors', () {
    expect(bookingLabel('pending'), 'ລໍຖ້າຢືນຢັນ');
    expect(bookingLabel('confirmed'), 'ຢືນຢັນແລ້ວ');
    expect(bookingLabel('rejected'), 'ຖືກປະຕິເສດ');
    expect(bookingColor('confirmed'), AppTheme.confirmed);
  });
}
