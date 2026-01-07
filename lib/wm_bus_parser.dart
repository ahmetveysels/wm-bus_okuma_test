import 'dart:typed_data';
import 'package:testrfidokuma/wmbus_utils.dart';

import 'meter_model.dart';

class WMBusParser {
  WMBusParser();

  MeterReading parseFrame(List<int> frame) {
    // Güvenlik kontrolü
    if (frame.length < 10) {
      return MeterReading.error("Veri paketi çok kısa (<10 byte)");
    }

    try {
      // --- HEADER ANALİZİ ---
      int headerOffset = 0;
      // Long Frame (0x68 ... 0x68) kontrolü
      if (frame[0] == 0x68 && frame.length > 4 && frame[3] == 0x68) {
        headerOffset = 4;
      }

      int manIndex = headerOffset + 2;
      int idIndex = headerOffset + 4;

      // Üretici
      List<int> manBytes = frame.sublist(manIndex, manIndex + 2);
      String manufacturer = _decodeManufacturer(manBytes);

      // Seri No
      List<int> idBytes = frame.sublist(idIndex, idIndex + 4);
      String serialNumber = idBytes.reversed.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // Versiyon & Tip
      int version = frame[idIndex + 4];
      int typeByte = frame[idIndex + 5];
      int ciField = frame[idIndex + 6];

      // --- DATA ANALİZİ ---
      List<MeterValue> parsedValues = [];
      String encryptionStatus = "Açık";

      // Veri başlangıcı: Header (11 byte) + Offset
      int currentIndex = headerOffset + 11;

      // --- QUNDIS ÖZEL DÜZELTME (OFFSET) ---
      // Qundis CI=0x72 modunda başlığı tekrar eder ve ek bilgiler (Access/Status/Sig) gönderir.
      // Eğer verinin başında Seri No tekrar ediyorsa, bu bir Extended Header'dır.
      // Hex: ... 72 [00 98 65 67] ... (Seri No tekrarı)
      if (currentIndex + 4 < frame.length) {
        bool isIdRepeated = true;
        for (int i = 0; i < 4; i++) {
          if (frame[currentIndex + i] != idBytes[i]) {
            isIdRepeated = false;
            break;
          }
        }

        if (isIdRepeated) {
          // Access(1) + Status(1) + Sig(2) + ID(4) + Man(2) + Ver(1) + Type(1) = 12 Byte Ekstra
          // Bu durumda veri 23. byte'dan (headerOffset + 23) başlar.
          currentIndex += 12;
        }
      }

      while (currentIndex < frame.length - 1) {
        // Checksum hariç
        if (currentIndex >= frame.length) break;

        int dif = frame[currentIndex];

        // 0x2F = Idle Filler (Paket Sonu)
        if (dif == 0x2F) break;

        // --- DIF 0x0D (Variable Length) KONTROLÜ ---
        // Qundis 0D FF ... bloklarını atlamak veya özel işlemek gerekir.
        if (dif == 0x0D) {
          int tempIndex = currentIndex + 1;
          if (tempIndex < frame.length) {
            int vif = frame[tempIndex];
            // VIF Extension bit (0x80) varsa ilerle
            while ((vif & 0x80) != 0 && tempIndex + 1 < frame.length) {
              tempIndex++;
              vif = frame[tempIndex];
            }
            tempIndex++; // VIF bitti, sıradaki Length byte'ı (LVAR)

            if (tempIndex < frame.length) {
              int length = frame[tempIndex];
              // "Üreticiye Özel" olarak işaretle ve atla
              parsedValues.add(MeterValue(0, "", "Üretici Özel Verisi (Atlandı)"));
              currentIndex = tempIndex + 1 + length;
              continue;
            }
          }
        }

        // DIF Extension (0x80 bit) varsa atla
        if ((dif & 0x80) != 0) {
          currentIndex++;
          continue;
        }

        if (currentIndex + 1 >= frame.length) break;
        int vif = frame[currentIndex + 1];

        // --- ID FİLTRESİ ---
        // VIF 0x79 veya 0x78 (Fabrika No) veri değildir.
        if (vif == 0x79 || vif == 0x78) {
          int len = _getDataLengthBytes(dif);
          currentIndex += 2 + len;
          continue;
        }

        // --- TARİH KONTROLÜ ---
        // VIF: 6D (Type F - 4 Byte) veya 6C (Type G - 2 Byte)
        // ED & 0x7F == 6D olduğu için ED de tarihtir.
        bool isDate = ((vif & 0x7F) == 0x6D || (vif & 0x7F) == 0x6C);

        // --- SICAKLIK KONTROLÜ ---
        // VIF: FD, VIFE: 3C (Return Temp)
        // VIF: 2A (Flow Temp)
        bool isReturnTemp = (vif == 0xFD && (currentIndex + 2 < frame.length && frame[currentIndex + 2] == 0x3C));

        // Veri Uzunluğu ve Tipi
        bool isBCD = _isBCDType(dif);
        int dataLen = _getDataLengthBytes(dif);

        if (dataLen == -1) {
          // Variable Length yukarıda yakalanmadıysa break
          break;
        }

        // Değer Okuma
        if (dataLen > 0 && (currentIndex + 2 + dataLen) <= frame.length) {
          int dataStartIndex = currentIndex + 2;
          // Eğer Extended VIF varsa (örn FD 3C, ED 39), VIF byte sayısını hesapla
          // Basitçe: VIF'in MSB'si 1 ise bir sonraki byte VIFE'dir.
          int tempVifIndex = currentIndex + 1;
          while ((frame[tempVifIndex] & 0x80) != 0 && tempVifIndex < frame.length) {
            tempVifIndex++;
            dataStartIndex++;
          }

          if (dataStartIndex + dataLen <= frame.length) {
            List<int> dataBytes = frame.sublist(dataStartIndex, dataStartIndex + dataLen);

            double valDouble = 0.0;
            String strValue = "";
            String unit = "";
            String desc = _getDescriptionFromVIF(vif, isReturnTemp);

            if (isDate) {
              // Tarih verisini çöz
              if (dataLen == 4)
                strValue = _parseDateTypeF(dataBytes); // Type F
              else if (dataLen == 2)
                strValue = _parseDateTypeG(dataBytes); // Type G

              // Tarihi açıklama kısmına ekle, değer 0 olsun
              parsedValues.add(MeterValue(0, "", "$desc: $strValue"));
            } else {
              // Sayısal veri
              if (isBCD)
                valDouble = _bcdToDouble(dataBytes);
              else
                valDouble = _intToDouble(dataBytes);

              // Birim Düzeltmeleri
              if ((vif & 0x7F) == 0x06)
                unit = "kWh";
              else if ((vif & 0x7F) == 0x05) {
                unit = "kWh";
                valDouble /= 10.0;
              } // Wh -> kWh
              else if ((vif & 0x7F) == 0x13 || (vif & 0x7F) == 0x14) {
                unit = "m3";
                valDouble /= 1000.0;
              } else if (vif == 0x2A) {
                unit = "°C";
                desc = "Gidiş Sıc.";
              } else if (isReturnTemp) {
                unit = "°C";
                valDouble /= 10.0; // 0.1 C çözünürlük
              }

              // Sadece bilinen birimleri veya önemli verileri ekle
              // "Birim" yazan belirsiz sayıları (VIFE vb.) listeye ekleme
              if (unit != "" || desc.contains("Sıc")) {
                parsedValues.add(MeterValue(valDouble, unit, desc));
              }
            }
          }
        }

        // Bir sonraki bloğa geç (DIF + VIFs + DATA)
        // VIF sayısını tekrar hesapla
        int headerLen = 2; // DIF + VIF en az
        int tempInd = currentIndex + 1;
        while ((frame[tempInd] & 0x80) != 0 && tempInd < frame.length) {
          tempInd++;
          headerLen++;
        }

        currentIndex += headerLen + dataLen;
      }

      return MeterReading(
        manufacturer: manufacturer,
        serialNumber: serialNumber,
        deviceType: _getDeviceTypeString(typeByte),
        version: version,
        encryption: encryptionStatus,
        frameType: encryptionStatus == "AES Şifreli" ? "Şifreli" : "Açık",
        values: parsedValues,
        parseTime: DateTime.now(),
        rawHex: WMBusUtils.toHexString(frame),
      );
    } catch (e) {
      return MeterReading.error("Parse Hatası: $e");
    }
  }

  // --- YARDIMCI METOTLAR ---

  int _getDataLengthBytes(int dif) {
    int type = dif & 0x0F;
    switch (type) {
      case 0x00:
        return 0;
      case 0x01:
        return 1; // 8 bit
      case 0x02:
        return 2; // 16 bit
      case 0x03:
        return 3; // 24 bit
      case 0x04:
        return 4; // 32 bit
      case 0x05:
        return 4; // 32 bit float
      case 0x06:
        return 6; // 48 bit
      case 0x07:
        return 8; // 64 bit
      case 0x09:
        return 1; // 2 digit BCD
      case 0x0A:
        return 2; // 4 digit BCD
      case 0x0B:
        return 3; // 6 digit BCD
      case 0x0C:
        return 4; // 8 digit BCD
      case 0x0D:
        return -1; // Variable
      case 0x0E:
        return 6; // 12 digit BCD
      default:
        return 0;
    }
  }

  bool _isBCDType(int dif) {
    int type = dif & 0x0F;
    return (type >= 0x09 && type <= 0x0E && type != 0x0D);
  }

  double _bcdToDouble(List<int> bytes) {
    try {
      String result = bytes.reversed.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return double.tryParse(result) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _intToDouble(List<int> bytes) {
    if (bytes.length > 8) return 0.0;
    int value = 0;
    for (int i = 0; i < bytes.length; i++) {
      value += bytes[i] << (i * 8);
    }
    return value.toDouble();
  }

  // Type G (2 Byte) Date: Gün.Ay.Yıl
  String _parseDateTypeG(List<int> bytes) {
    if (bytes.length < 2) return "";
    int val = bytes[0] | (bytes[1] << 8);
    int day = val & 0x1F;
    int month = (val >> 8) & 0x0F;
    int year = ((val >> 9) & 0x7F) + 2000;
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

  // Type F (4 Byte) Date/Time: Dakika, Saat, Gün, Ay, Yıl
  String _parseDateTypeF(List<int> bytes) {
    if (bytes.length < 4) return "";
    int min = bytes[0] & 0x3F;
    int hour = bytes[1] & 0x1F;
    int day = bytes[2] & 0x1F;
    int month = bytes[3] & 0x0F;
    int year = ((bytes[3] & 0xF0) >> 1) | ((bytes[2] & 0xE0) >> 5);
    year += 2000;

    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} $hour:${min.toString().padLeft(2, '0')}";
  }

  String _decodeManufacturer(List<int> bytes) {
    if (bytes.length < 2) return "UNK";
    int m = (bytes[1] << 8) | bytes[0];
    int c1 = (m >> 10) & 0x1F;
    int c2 = (m >> 5) & 0x1F;
    int c3 = m & 0x1F;
    return String.fromCharCode(c1 + 64) + String.fromCharCode(c2 + 64) + String.fromCharCode(c3 + 64);
  }

  String _getDescriptionFromVIF(int vif, bool isReturnTemp) {
    if (isReturnTemp) return "Dönüş Sıc.";
    int plainVif = vif & 0x7F; // Extension bitini yoksay
    if (plainVif == 0x06 || plainVif == 0x05) return "Enerji";
    if (plainVif == 0x13 || plainVif == 0x14) return "Hacim";
    if (vif == 0x2A) return "Gidiş Sıc.";
    if (plainVif == 0x6C || plainVif == 0x6D) return "Zaman/Tarih";
    return "Veri";
  }

  String _getDeviceTypeString(int type) {
    switch (type) {
      case 0x03:
        return "Gaz";
      case 0x04:
        return "Isı";
      case 0x07:
        return "Su";
      case 0x15:
        return "Sıcak Su";
      case 0x16:
        return "Soğuk Su";
      case 0x37:
        return "Radyo Modül";
      default:
        return "Tip: ${type.toRadixString(16)}";
    }
  }
}
