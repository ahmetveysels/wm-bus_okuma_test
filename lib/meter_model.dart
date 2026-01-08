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
        String valStr = v.stringValue.isNotEmpty ? v.stringValue : "${v.value} ${v.unit}";
        sb.writeln("  * ${v.description.padRight(22)} : $valStr");
      }
    }
    if (error != null) sb.writeln("!!! HATA: $error !!!");
    sb.writeln("==========================");
    return sb.toString();
  }
}

/// Sayacın içindeki her bir ölçüm değerini temsil eder.
class MeterValue {
  final double value;       // Sayısal değer (Tüketim, Hacim vb.)
  final String stringValue; // Metinsel değer (Tarih, Zaman vb.) - YENİ
  final String unit;        // Birim (kWh, m3, °C)
  final String description; // Açıklama (Enerji, Hacim vb.)

  MeterValue(this.value, this.unit, this.description, {this.stringValue = ""});

  @override
  String toString() => 'MeterValue(val: $value, str: $stringValue, unit: $unit)';
}