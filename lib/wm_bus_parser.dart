// Dosya: lib/wm_bus_parser.dart

import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:testrfidokuma/wmbus_utils.dart';

import 'meter_model.dart';

class WMBusParser {
  WMBusParser();

  // --- C# Dosyasından Alınan AES Anahtarları (128-bit) ---
  static final List<String> _aesKeys = [
    "51728910E66D83F851728910E66D83F8",
    "614467726164754D70726F58694D754D",
    "39BC8A10E66D83F839BC8A10E66D83F8",
    "CE2922F434379405B89613381FD65352",
    "CE2922F434379405A89613381FD65352",
    "12345678901234561234567890123456",
    "12345678901234567890123456789012",
    "2A687141495A2A502F5D773E7E247C5E",
    "2F656E3C6D5E7321754E64563D57532B",
    "423D4B7365482B4B4047576927652725",
    "2B366E692E215D4F39317B6F21727B68",
    "283F214463275F3C4D7554764221613F",
    "306C6A2071292A20382229442B416948",
    "576D51393B56684044276B3527425F62",
    "312E5C2D42346A7A6870675250274E54",
    "7C6464235A31385D4028682022447C31",
    "48C1A9B237A0FE7D30AF25B6CD29014C",
    "198D231C956C34DA724F1BDE2A14B4AC",
    "F9213142F537196E5A9C061CEA2E6A56",
    "F417C018B5295D90BF4013A21F12573D",
    "123456789ABCDEF10111213141516171",
    "17161514131211101FEDCBA987654321",
    "82B0551191F51D66EFCDAB8967452301",
    "C25572A46BFD55F13F93DC54EDC78DC2",
    "E6C88800DEB868C0D6A84880CE982840",
    "31323334353637383930313233343536",
    "DD4275DAD7765FFFFD99EC0C7C763E42",
    "074D7BD5DED3E499C9EF3DD9C9452222",
    "D6502C6D7FB762316E7ECDD1382F2222",
    "72B5925FB1F0B2ECDCB9D01045120000",
    "973DE16D8F32D711337774DCD86C2222",
    "25C3D4610CF61B08DBB504BACF9D0000",
    "AC4CB507A2D237EA3856818365840000",
    "9BB592B8E40AA50C2B21CA6B6CB10000",
    "C85DDFF5E04131774869F2901E3B0000",
    "1EECA4C14546C53C883E88396F550000",
    "7FB6798EF816C674FEAC416A841D0000",
    "00000000000000000000000000001234",
    "0E4A54C3486164D9DECE427268190000",
    "039742BB0FBBB125BF336C97F2D70000",
    "0C6517E796B1BE4455F49DCA297A0000",
    "0978252B78514024611F85B1A5D70000",
    "FE00AB122B4A1811F98A003413C7C813",
    "FC18877D8558CB06D91F4093CED10000",
    "2B7E151628AED2A6ABF7158809CF4F3C",
    "3E812EC681C5E20DDF2A000000000000",
    "C51331429B378FEADBCBAC2B0EC55143",
    "A4E375C6B09FD185F27C4E96FC273AE4",
    "DD4B21E9EF71E1291183A46B913AE6F2",
    "834B23152C250AADD5C0C378432B228A",
    "289DFF07669D7A23DE0EF88D2F7129E7",
    "D41D8CD98F00B204E9800998ECF8427E",
    "0102DD4B21E9EF71E1296FF97E296FA5",
    "00112233445566778899AABBCCDDEEFF",
    "000102030405060708090A0B0C0D0E0F",
    "0102030405060708090A0B0C0D0E0F11",
    "0102030405060708090A0B0C0D0E0F00",
    "0102030405060708090A0B0C0D0E0FFF",
    "12345678912345678912345678912345",
    "123456789123456789123456789ABCDE",
    "0123456789ABCDEF0123456789ABCDEF",
    "01010101010101010101010101010101",
    "02020202020202020202020202020202",
    "03030303030303030303030303030303",
    "04040404040404040404040404040404",
    "05050505050505050505050505050505",
    "06060606060606060606060606060606",
    "07070707070707070707070707070707",
    "08080808080808080808080808080808",
    "09090909090909090909090909090909",
    "0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A",
    "0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B",
    "0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C",
    "0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D0D",
    "0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E0E",
    "0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F",
    "00000000000000000000000000000000",
    "11111111111111111111111111111111",
    "22222222222222222222222222222222",
    "33333333333333333333333333333333",
    "44444444444444444444444444444444",
    "55555555555555555555555555555555",
    "66666666666666666666666666666666",
    "77777777777777777777777777777777",
    "88888888888888888888888888888888",
    "99999999999999999999999999999999",
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
    "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
    "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
    "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE",
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    "0D67DA3B064C14BF7790DDC3A6034676",
    "B7DD6081BCF6AE05CD2A67791CB9FCCC",
    "CAFEBABE123456789ABCDEF0CAFEBABE",
    "A55173AABA2B04E651AF371C5BD44555",
    "53404B1F3B468BA410E5FECFE260254C",
    "3147AD7685399BB3DD90AFFA798E84C7",
    "7B0183C81FB061FC46522889DD382456",
    "6AC72C5D9C22AB90E0EC0BA7888A1BFA",
    "7451EE08411D5D7E1F088436EFA0C1FD",
    "4E33EECAD7A8216839A1C128306021AB",
    "1E03759C02CD37F51DF51BDDA1F90488",
    "6D4793A9704948ABF57C7A24A91DEB94",
    "6E5A77FF8BE001FF3BCF343F499BEBDA",
    "0A18FA63DBA64E5438ABE72BEB757730",
    "00000000000000000000000000000001",
    "FCF41938F63432975B52505F547FCEDF",
    "AAA896100FED12DD614DD5D46369ACDD",
    "BEDB81B52C29B5C143388CBB0D15A051",
    "A004EB23329A477F1DD2D7820B56EB3D",
    "28F64A24988064A079AA2C807D6102AF",
    "28F64A24988064A079AA2C807D6102AE",
    "859A9D0F5DC2BAD679644E4FB6F9CE29",
    "5065747220486F6C79737A6577736B69",
    "58721910E66D83F851728910E66D83F8",
    "58721910E66D83F858721910E66D83F8",
    "296B4F5E07EEA2C95DFAE9195AD9484F",
    "3245678564FF6543214EF5678909876F",
    "123456789012345678900987654321FE",
    "C6A5D343AEFFD1503B0E8DE24FA4E063",
    "5A8470C4806F4A87CEF4D5F2D9855566",
    "508A1C4091D7D14D860459FCD361C30A",
    "C08E3C86B1829003414C04636244EE07",
    "414C04636244EE07C08E3C86B1829003",
    "C08E3C86B1829003C08E3C86B1829003",
    "414C04636244EE07414C04636244EE07",
    "11111111111111112222222222222222",
    "11112222333344445555666677778888",
    "11112222333344441111222233334444",
    "55556666777788885555666677778888",
    "5572404C696E6B4C6F52613230313823",
    "281ECEA9EE036FAC114297C333C4141A",
    "BEFE9863E28D564A873A2EB9B87451A4",
    "00004000000300000500001000000600",
    "00001000020000300004000050000600",
  ];

  // --- Diehl / Hydrometer Özel Anahtarları (64-bit) ---
  static final List<String> _diehlKeys = ["51728910E66D83F8", "39BC8A10E66D83F8", "58721910E66D83F8"];

  MeterReading parseFrame(List<int> frame) {
    if (frame.length < 10) {
      return MeterReading.error("Veri paketi çok kısa (<10 byte)");
    }

    try {
      int headerOffset = 0;
      if (frame[0] == 0x68 && frame.length > 4 && frame[3] == 0x68) {
        headerOffset = 4;
      }

      int manIndex = headerOffset + 2;
      int idIndex = headerOffset + 4;

      List<int> manBytes = frame.sublist(manIndex, manIndex + 2);
      String manufacturer = _decodeManufacturer(manBytes);

      List<int> idBytes = frame.sublist(idIndex, idIndex + 4);
      String serialNumber = idBytes.reversed.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      int version = frame[idIndex + 4];
      int typeByte = frame[idIndex + 5];
      int ciField = frame[idIndex + 6];

      int currentIndex = headerOffset + 11;
      List<int> workingFrame = List.from(frame);
      bool wasDecrypted = false;
      String encryptionStatus = "Açık";

      // --- TECHEM (TCH) KOMPAKT MOD KONTROLÜ (BİRİM DÜZELTİLDİ) ---
      if (manufacturer == "TCH" && (ciField == 0xA0 || ciField == 0xA1 || ciField == 0xA2)) {
        return _parseTechemCompact(workingFrame, manufacturer, serialNumber, version, typeByte, ciField);
      }

      // --- ŞİFRE ÇÖZME İŞLEMLERİ ---
      // 1. Diehl/HYD Özel Şifreleme (LFSR)
      if (manufacturer == "HYD" || manufacturer == "DFS" || manufacturer == "SAP" || manufacturer == "DME") {
        List<int>? decryptedLFSR = _tryDecryptDiehlLFSR(workingFrame, headerOffset);
        if (decryptedLFSR != null) {
          workingFrame = decryptedLFSR;
          wasDecrypted = true;
          encryptionStatus = "Çözüldü (Diehl LFSR)";
          currentIndex = headerOffset + 15;
        }
      }

      // 2. Standart AES Şifreleme (Mode 5)
      if (!wasDecrypted) {
        if (ciField == 0x7A && frame.length > headerOffset + 15) {
          int tCount = frame[headerOffset + 11];
          int config2 = frame[headerOffset + 14];
          int aesType = config2 & 0x0F;

          if (aesType == 0x05) {
            encryptionStatus = "AES Şifreli (Çözülüyor...)";
            List<int> ivHeader = frame.sublist(headerOffset + 2, headerOffset + 10);
            List<int> ivTCount = List.filled(8, tCount);
            List<int> iv = [...ivHeader, ...ivTCount];

            int payloadStart = headerOffset + 15;
            List<int> encryptedPayload = frame.sublist(payloadStart);

            List<int>? decrypted = _tryDecryptAES(encryptedPayload, iv);
            if (decrypted != null) {
              workingFrame = [...frame.sublist(0, payloadStart), ...decrypted];
              wasDecrypted = true;
              encryptionStatus = "Çözüldü (AES)";
              currentIndex = payloadStart;
            } else {
              encryptionStatus = "Şifre Çözülemedi (Key Bulunamadı)";
            }
          }
        } else if (ciField == 0x72 && frame.length > headerOffset + 23) {
          int tCount = frame[headerOffset + 19];
          int config2 = frame[headerOffset + 22];
          int aesType = config2 & 0x0F;

          if (aesType == 0x05) {
            encryptionStatus = "AES Şifreli (Çözülüyor...)";
            List<int> ivHeader = frame.sublist(headerOffset + 2, headerOffset + 10);
            List<int> ivTCount = List.filled(8, tCount);
            List<int> iv = [...ivHeader, ...ivTCount];

            int payloadStart = headerOffset + 23;
            List<int> encryptedPayload = frame.sublist(payloadStart);

            List<int>? decrypted = _tryDecryptAES(encryptedPayload, iv);
            if (decrypted != null) {
              workingFrame = [...frame.sublist(0, payloadStart), ...decrypted];
              wasDecrypted = true;
              encryptionStatus = "Çözüldü (AES)";
              currentIndex = payloadStart;
            } else {
              encryptionStatus = "Şifre Çözülemedi (AES)";
            }
          } else {
            currentIndex = headerOffset + 23;
          }
        } else {
          if (currentIndex + 4 < frame.length) {
            bool isIdRepeated = true;
            for (int i = 0; i < 4; i++) {
              if (frame[currentIndex + i] != idBytes[i]) {
                isIdRepeated = false;
                break;
              }
            }
            if (isIdRepeated) currentIndex += 12;
          }
        }
      }

      // --- STANDART PARSER DÖNGÜSÜ ---
      List<MeterValue> parsedValues = [];

      while (currentIndex < workingFrame.length - 1) {
        if (currentIndex >= workingFrame.length) break;

        int dif = workingFrame[currentIndex];

        if (dif == 0x2F) {
          currentIndex++;
          continue;
        }

        if (dif == 0x0D) {
          int tempIndex = currentIndex + 1;
          if (tempIndex < workingFrame.length) {
            int vif = workingFrame[tempIndex];
            while ((vif & 0x80) != 0 && tempIndex + 1 < workingFrame.length) {
              tempIndex++;
              vif = workingFrame[tempIndex];
            }
            tempIndex++;
            if (tempIndex < workingFrame.length) {
              int length = workingFrame[tempIndex];
              currentIndex = tempIndex + 1 + length;
              continue;
            }
          }
        }

        if ((dif & 0x80) != 0) {
          currentIndex++;
          continue;
        }

        if (currentIndex + 1 >= workingFrame.length) break;
        int vif = workingFrame[currentIndex + 1];

        if (vif == 0x79 || vif == 0x78) {
          int len = _getDataLengthBytes(dif);
          currentIndex += 2 + len;
          continue;
        }

        bool isDate = ((vif & 0x7F) == 0x6D || (vif & 0x7F) == 0x6C);
        bool isReturnTemp = (vif == 0xFD && (currentIndex + 2 < workingFrame.length && workingFrame[currentIndex + 2] == 0x3C));
        bool isBCD = _isBCDType(dif);
        int dataLen = _getDataLengthBytes(dif);

        if (dataLen == -1) break;

        if (dataLen > 0 && (currentIndex + 2 + dataLen) <= workingFrame.length) {
          int dataStartIndex = currentIndex + 2;

          int tempVifIndex = currentIndex + 1;
          while ((workingFrame[tempVifIndex] & 0x80) != 0 && tempVifIndex < workingFrame.length) {
            tempVifIndex++;
            dataStartIndex++;
          }

          if (dataStartIndex + dataLen <= workingFrame.length) {
            List<int> dataBytes = workingFrame.sublist(dataStartIndex, dataStartIndex + dataLen);

            double valDouble = 0.0;
            String strValue = "";
            String unit = "";
            String desc = _getDescriptionFromVIF(vif, isReturnTemp);

            if (isDate) {
              if (dataLen == 4)
                strValue = _parseDateTypeF(dataBytes);
              else if (dataLen == 2)
                strValue = _parseDateTypeG(dataBytes);
              parsedValues.add(MeterValue(0, "", "$desc: $strValue"));
            } else {
              if (isBCD)
                valDouble = _bcdToDouble(dataBytes);
              else
                valDouble = _intToDouble(dataBytes);

              // BİRİM DÜZELTMELERİ (Wh -> kWh ekledim)
              if ((vif & 0x7F) == 0x06)
                unit = "kWh";
              else if ((vif & 0x7F) == 0x05) {
                unit = "kWh";
                valDouble /= 10.0;
              } else if ((vif & 0x7F) == 0x03) {
                unit = "kWh";
                valDouble /= 1000.0;
              } // Wh -> kWh (HYD)
              else if ((vif & 0x7F) == 0x13 || (vif & 0x7F) == 0x14) {
                unit = "m3";
                valDouble /= 1000.0;
              } else if (vif == 0x2A) {
                unit = "°C";
                desc = "Gidiş Sıc.";
              } else if (isReturnTemp) {
                unit = "°C";
                valDouble /= 10.0;
              }

              if (unit != "" || desc.contains("Sıc")) {
                parsedValues.add(MeterValue(valDouble, unit, desc));
              }
            }
          }
        }

        int headerLen = 2;
        int tempInd = currentIndex + 1;
        while ((workingFrame[tempInd] & 0x80) != 0 && tempInd < workingFrame.length) {
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
        frameType: wasDecrypted ? "Çözüldü" : "Standart",
        values: parsedValues,
        parseTime: DateTime.now(),
        rawHex: WMBusUtils.toHexString(frame),
      );
    } catch (e) {
      return MeterReading.error("Parse Hatası: $e");
    }
  }

  // --- YENİ: Techem Compact Parser (BİRİM DÜZELTİLDİ) ---
  MeterReading _parseTechemCompact(List<int> frame, String man, String serial, int ver, int type, int ci) {
    List<MeterValue> vals = [];
    int offset = 0;
    if (frame[0] == 0x68) offset = 4;

    try {
      // Techem Compact Mod: 14. byte'tan itibaren veriler başlar
      if (frame.length > offset + 18) {
        int val1 = _toUInt16(frame, offset + 14); // Güncel
        int val2 = _toUInt16(frame, offset + 18); // Önceki

        double dVal1 = val1.toDouble();
        double dVal2 = val2.toDouble();

        String unit = "";

        // --- BİRİM VE ÇARPAN AYARLARI ---
        // Isı (Heat) tipleri
        if (type == 0x04 || (type >= 0x43 && type <= 0x45) || (type >= 0xA3 && type <= 0xA5) || (type >= 0xC3 && type <= 0xC5)) {
          unit = "kWh";

          if (type == 0x44 || type == 0xA4 || type == 0xC4) {
            if (val1 != 0) dVal1 *= 10;
            if (val2 != 0) dVal2 *= 10;
          }

          // GJ to kWh (C# mantığı)
          if (type >= 0xC3 && type <= 0xC5) {
            if (val1 != 0) dVal1 = (dVal1 / 1000.0) / 0.0036;
            if (val2 != 0) dVal2 = (dVal2 / 1000.0) / 0.0036;
          } else if (type == 0x04 && val1 != 0) {
            dVal1 *= 10;
          }
        }
        // Su (Water) tipleri
        else if (type == 0x07 || type == 0x06 || type == 0x16 || type == 0x15 || (type >= 0x60 && type <= 0x62) || (type >= 0x70 && type <= 0x72)) {
          unit = "m3";
          if (type == 0x70) {
            dVal1 /= 100.0;
            dVal2 /= 100.0;
          } else {
            dVal1 /= 10.0;
            dVal2 /= 10.0;
          }
        }
        // Payölçer (HCA)
        else if (type == 0x08 || type == 0x80) {
          unit = "birim";
        } else {
          unit = "Birim (${type.toRadixString(16).toUpperCase()})";
        }

        vals.add(MeterValue(dVal1, unit, "Güncel Değer (TCH)"));
        vals.add(MeterValue(dVal2, unit, "Önceki Değer (TCH)"));
      }
    } catch (e) {
      return MeterReading.error("TCH Compact Parse Hatası");
    }

    return MeterReading(
      manufacturer: man,
      serialNumber: serial,
      deviceType: "Compact TCH",
      version: ver,
      encryption: "Compact Mod",
      frameType: "Techem Compact",
      values: vals,
      parseTime: DateTime.now(),
      rawHex: WMBusUtils.toHexString(frame),
    );
  }

  int _toUInt16(List<int> bytes, int offset) {
    if (offset + 2 > bytes.length) return 0;
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  // --- Diehl / HYD LFSR Decryption Logic (DÜZELTİLDİ: BIG ENDIAN) ---
  List<int>? _tryDecryptDiehlLFSR(List<int> frame, int headerOffset) {
    int dataStart = headerOffset + 15;
    if (frame.length <= dataStart) return null;

    List<int> payload = frame.sublist(dataStart);
    List<int> header = frame.sublist(headerOffset, dataStart);

    for (String keyHex in _diehlKeys) {
      try {
        List<int> keyBytes = WMBusUtils.hexToBytes(keyHex);
        // HATA DÜZELTME: C# kodu anahtarları Big Endian olarak işliyor (ToUInt32(..., true)).
        int seed1 = _toUInt32BE(keyBytes, 0);
        int seed2 = _toUInt32BE(keyBytes, 4);
        int key = seed1 ^ seed2;

        // HATA DÜZELTME: Başlık parçaları da Big Endian olarak okunmalı.
        int part1 = _toUInt32BE(header, 2);
        int part2 = _toUInt32BE(header, 6);
        int part3 = _toUInt32BE(header, 10);

        key ^= part1;
        key ^= part2;
        key ^= part3;

        List<int> decoded = List.from(payload);

        for (int i = 0; i < decoded.length; i++) {
          for (int j = 0; j < 8; j++) {
            bool bit = ((key & 0x2) != 0) ^ ((key & 0x4) != 0) ^ ((key & 0x800) != 0) ^ ((key & 0x80000000) != 0);
            key = ((key << 1) & 0xFFFFFFFF) | (bit ? 1 : 0);
          }
          decoded[i] = (payload[i] ^ (key & 0xFF)) & 0xFF;
        }

        if (decoded.isNotEmpty && decoded[0] == 0x4B) {
          List<int> newFrame = [...frame.sublist(0, dataStart), ...decoded];
          return newFrame;
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Helper: Big Endian UInt32 okuma (C# uyumluluğu için)
  int _toUInt32BE(List<int> bytes, int offset) {
    if (offset + 4 > bytes.length) return 0;
    return (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
  }

  // --- AES Mode 5 Decryption ---
  List<int>? _tryDecryptAES(List<int> encryptedData, List<int> iv) {
    if (encryptedData.isEmpty || encryptedData.length % 16 != 0) return null;

    for (String keyHex in _aesKeys) {
      try {
        final key = enc.Key.fromBase16(keyHex);
        final ivObj = enc.IV(Uint8List.fromList(iv));
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: null));

        final decrypted = encrypter.decryptBytes(enc.Encrypted(Uint8List.fromList(encryptedData)), iv: ivObj);

        if (decrypted.length > 2 && decrypted[0] == 0x2F && decrypted[1] == 0x2F) {
          return decrypted;
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // --- YARDIMCI METOTLAR ---
  int _getDataLengthBytes(int dif) {
    int type = dif & 0x0F;
    switch (type) {
      case 0x00:
        return 0;
      case 0x01:
        return 1;
      case 0x02:
        return 2;
      case 0x03:
        return 3;
      case 0x04:
        return 4;
      case 0x05:
        return 4;
      case 0x06:
        return 6;
      case 0x07:
        return 8;
      case 0x09:
        return 1;
      case 0x0A:
        return 2;
      case 0x0B:
        return 3;
      case 0x0C:
        return 4;
      case 0x0D:
        return -1;
      case 0x0E:
        return 6;
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

  String _parseDateTypeG(List<int> bytes) {
    if (bytes.length < 2) return "";
    int val = bytes[0] | (bytes[1] << 8);
    int day = val & 0x1F;
    int month = (val >> 8) & 0x0F;
    int year = ((val >> 9) & 0x7F) + 2000;
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

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
    int plainVif = vif & 0x7F;
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
      case 0x37:
        return "Radyo Modül";
      default:
        return "Tip: ${type.toRadixString(16)}";
    }
  }
}
