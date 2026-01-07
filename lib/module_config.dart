// Dosya: lib/module_config.dart

abstract class RFModuleConfig {
  String get name;
  int get baudRate;
  int get sortId;
  List<String> get initCommands;
}

// --- RADIOCRAFTS ---

class RadiocraftT1CConfig implements RFModuleConfig {
  @override
  String get name => "RC1180 T1+C";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 1;
  @override
  List<String> get initCommands => ["00", "4D", "03 0B", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "0B", "58"];
}

class RadiocraftT1Config implements RFModuleConfig {
  @override
  String get name => "RC1180 T1";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 2;
  @override
  List<String> get initCommands => ["00", "4D", "03 01", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "01", "58"];
}

class RadiocraftT2Config implements RFModuleConfig {
  @override
  String get name => "RC1180 T2";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 3;
  @override
  List<String> get initCommands => ["00", "4D", "03 02", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "02", "58"];
}

class RadiocraftS1Config implements RFModuleConfig {
  @override
  String get name => "RC1180 S1";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 4;
  @override
  List<String> get initCommands => ["00", "4D", "03 03", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "03", "58"];
}

class RadiocraftS2Config implements RFModuleConfig {
  @override
  String get name => "RC1180 S2";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 5;
  @override
  List<String> get initCommands => ["00", "4D", "03 00", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "00", "58"];
}

class RadiocraftC1Config implements RFModuleConfig {
  @override
  String get name => "RC1180 C1";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 6;
  @override
  List<String> get initCommands => ["00", "4D", "03 09", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "09", "58"];
}

class RadiocraftC2Config implements RFModuleConfig {
  @override
  String get name => "RC1180 C2";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 7;
  @override
  List<String> get initCommands => ["00", "4D", "03 08", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "08", "58"];
}

class RadiocraftT2CConfig implements RFModuleConfig {
  @override
  String get name => "RC1180 T2+C";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 8;
  @override
  List<String> get initCommands => ["00", "4D", "03 0A", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "0A", "58"];
}

class RadiocraftRConfig implements RFModuleConfig {
  @override
  String get name => "RC1180 R";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 9;
  @override
  List<String> get initCommands => ["00", "4D", "03 04", "04 00", "05 01", "36 04", "3A 01", "3D 02", "3E 00", "3F 00", "FF", "47", "04", "58"];
}

// --- OTHER ---

class AmberModuleConfig implements RFModuleConfig {
  @override
  String get name => "AMBER AMB8665-M";
  @override
  int get baudRate => 9600;
  @override
  int get sortId => 10;
  @override
  List<String> get initCommands => ["FF 11 00 EE", "FF 05 00 FA", "FF 09 03 05 01 01 F0", "FF 09 03 45 01 01 B0", "FF 09 03 46 01 09 BB", "FF 05 00 FA"];
}

class AtlasConfig implements RFModuleConfig {
  @override
  String get name => "ATLAS CC430F6137";
  @override
  int get baudRate => 38400;
  @override
  int get sortId => 11;
  @override
  List<String> get initCommands => ["10 49 FE 47 16", "10 4B FE 49 16"];
}

class ImstModuleConfig implements RFModuleConfig {
  @override
  String get name => "IMST iM871A RF";
  @override
  int get baudRate => 57600;
  @override
  int get sortId => 12;
  @override
  List<String> get initCommands => ["A5 01 09 01 01", "A5 01 03 06 01 03 00 0A 30 01 00"];
}

class QundisConfig implements RFModuleConfig {
  @override
  String get name => "QUNDIS Q log 5.5 RF";
  @override
  int get baudRate => 9600;
  @override
  int get sortId => 13;
  @override
  List<String> get initCommands => ["C0 00 02 82 0A 04 C0"];
}

class IzarConfig implements RFModuleConfig {
  @override
  String get name => "IZAR RECEIVER 868";
  @override
  int get baudRate => 9600;
  @override
  int get sortId => 14;
  @override
  List<String> get initCommands => ["78 00"];
}

class RacBlueConfig implements RFModuleConfig {
  @override
  String get name => "RAC MBWBLUE";
  @override
  int get baudRate => 115200;
  @override
  int get sortId => 15;
  @override
  List<String> get initCommands => ["01 FE 07 15 00 79 7A", "01 FE 06 10 45 09"];
}

class TeksanConfig implements RFModuleConfig {
  @override
  String get name => "TEKSAN MRF49XA";
  @override
  int get baudRate => 9600;
  @override
  int get sortId => 16;
  @override
  List<String> get initCommands => [];
}

class TelitXE50Config implements RFModuleConfig {
  @override
  String get name => "TELIT xE50 868 RF";
  @override
  int get baudRate => 19200;
  @override
  int get sortId => 17;
  @override
  List<String> get initCommands => ["2B 2B 2B", "41 54 52 0D", "41 54 53 34 30 32 3D 32 32 33 0D", "41 54 53 34 30 30 3D 31 35 0D", "41 54 4F 0D"];
}
