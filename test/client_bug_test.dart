import 'package:flutter_test/flutter_test.dart';
import 'package:taller_360_garage/models/cliente.dart';
import 'package:taller_360_garage/models/vehiculo.dart';

void main() {
  group('Cliente Model and Parsing', () {
    test('parses gRQL Lambda fields (client_name, tax_id, cell_phone) correctly', () {
      final json = {
        'client_id': 'cli-001',
        'client_name': 'Carlos Perez',
        'tax_id': 'V-12345678',
        'cell_phone': '0414-1234567',
        'email': 'carlos@example.com',
        'address': 'Calle Principal #12',
      };

      final cliente = Cliente.fromJson(json);

      expect(cliente.id, equals('cli-001'));
      expect(cliente.nombre, equals('Carlos Perez'));
      expect(cliente.ci, equals('V-12345678'));
      expect(cliente.telefono, equals('0414-1234567'));
      expect(cliente.email, equals('carlos@example.com'));
      expect(cliente.direccion, equals('Calle Principal #12'));
    });

    test('handles empty or null fields safely without throwing RangeError', () {
      final json = <String, dynamic>{
        'client_id': 'cli-002',
      };

      final cliente = Cliente.fromJson(json);

      expect(cliente.nombre, equals(''));
      expect(cliente.ci, equals(''));
      expect(cliente.telefono, equals(''));

      // Simulate the UI avatar logic that caused the RangeError
      final initialLetter = cliente.nombre.trim().isNotEmpty
          ? cliente.nombre.trim().substring(0, 1).toUpperCase()
          : 'C';

      expect(initialLetter, equals('C'));
    });
  });

  group('Vehiculo Model and Parsing', () {
    test('parses vehicle_id and client_name correctly', () {
      final json = {
        'vehicle_id': 'veh-001',
        'clients_fk_id': 'cli-001',
        'client_name': 'Carlos Perez',
        'brand': 'Toyota',
        'model': 'Corolla',
        'license_plate': 'AB123CD',
      };

      final veh = Vehiculo.fromJson(json);

      expect(veh.id, equals('veh-001'));
      expect(veh.clientName, equals('Carlos Perez'));
      expect(veh.licensePlate, equals('AB123CD'));
    });
  });
}
