// Dosya: lib/meter_model.dart

/// Tek bir sayaçtan gelen tüm paketi temsil eder.
class MeterReading {
  final String manufacturer;
  final String serialNumber;
  final String deviceType;
  final int version;
  final String encryption;
  final String frameType;
  final List<MeterValue> values;
  final DateTime parseTime;
  final String rawHex;
  final String? error;

  MeterReading({
    required this.manufacturer,
    required this.serialNumber,
    required this.deviceType,
    required this.version,
    required this.encryption,
    required this.frameType,
    required this.values,
    required this.parseTime,
    this.rawHex = "",
    this.error,
  });

  factory MeterReading.error(String errorMessage) {
    return MeterReading(
      manufacturer: "UNK",
      serialNumber: "00000000",
      deviceType: "",
      version: 0,
      encryption: "Hata",
      frameType: "Error",
      values: [],
      parseTime: DateTime.now(),
      error: errorMessage,
    );
  }
  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.writeln("=== SAYAÇ OKUMA SONUCU ===");
    sb.writeln("Marka       : $manufacturer ($frameType)");
    sb.writeln("Seri No     : $serialNumber");
    sb.writeln("Tip         : $deviceType (v$version)");
    sb.writeln("Durum       : $encryption");
    sb.writeln("--- DEĞERLER ---");
    if (values.isEmpty) {
      sb.writeln("  (Değer yok veya ayrıştırılamadı)");
    } else {
      for (var v in values) {
        sb.writeln("  * ${v.description.padRight(22)} : ${v.value} ${v.unit}");
      }
    }
    if (error != null) sb.writeln("!!! HATA: $error !!!");
    sb.writeln("==========================");
    return sb.toString();
  }
}

/// Sayacın içindeki her bir ölçüm değerini temsil eder (Tüketim, Hacim vb.)
class MeterValue {
  final double value;
  final String unit;
  final String description;

  MeterValue(this.value, this.unit, this.description);

  @override
  String toString() => 'MeterValue(value: $value, unit: $unit, description: $description)';
}
