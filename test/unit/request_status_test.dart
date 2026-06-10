import 'package:flutter_test/flutter_test.dart';
import 'package:roadside_help/data/models/service_request.dart';

void main() {
  group('RequestStatus mapping', () {
    test('parses backend strings', () {
      expect(requestStatusFromString('on_the_way'), RequestStatus.onTheWay);
      expect(requestStatusFromString('completed'), RequestStatus.completed);
      expect(requestStatusFromString('cancelled'), RequestStatus.cancelled);
    });

    test('terminal states', () {
      expect(RequestStatus.completed.isTerminal, isTrue);
      expect(RequestStatus.cancelled.isTerminal, isTrue);
      expect(RequestStatus.accepted.isTerminal, isFalse);
      expect(RequestStatus.requested.isTerminal, isFalse);
    });

    test('labels are non-empty', () {
      for (final s in RequestStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });
}
