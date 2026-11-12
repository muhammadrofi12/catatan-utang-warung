import 'package:flutter_test/flutter_test.dart';
import 'package:catatan_warung/ui/common.dart';

void main() {
  final formatter = AmountFormatter();
  String edit(String before, String after) => formatter
      .formatEditUpdate(
        TextEditingValue(text: before),
        TextEditingValue(text: after),
      )
      .text;
  test('rupiah formats whole numbers and rejects ambiguous decimal paste', () {
    expect(edit('', '25000'), '25.000');
    expect(edit('', '25.000'), '25.000');
    expect(edit('1.000', '1.0000'), '10.000');
    expect(edit('1.000', '1.00'), '100');
    expect(edit('', '1.5'), '');
    expect(edit('', '1,5'), '');
    expect(edit('', '-100'), '');
    expect(edit('', '1000000000'), '');
    expect(edit('25.000', ''), '');
  });
}
