// Dosya: lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'meter_model.dart';
import 'module_config.dart';
import 'wm_bus_parser.dart';
import 'wmbus_utils.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WirelessMBusApp(),
    ),
  );
}

class WirelessMBusApp extends StatefulWidget {
  const WirelessMBusApp({super.key});
  @override
  State<WirelessMBusApp> createState() => _WirelessMBusAppState();
}

class _WirelessMBusAppState extends State<WirelessMBusApp> {
  // --- USB Değişkenleri ---
  List<UsbDevice> _devices = [];
  UsbDevice? _selectedDevice;
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;

  // --- Modül Listesi ---
  final List<RFModuleConfig> _availableModules = [
    RadiocraftT1CConfig(),
    RadiocraftT1Config(),
    RadiocraftT2Config(),
    RadiocraftS1Config(),
    RadiocraftS2Config(),
    RadiocraftC1Config(),
    RadiocraftC2Config(),
    RadiocraftT2CConfig(),
    RadiocraftRConfig(),
    AmberModuleConfig(),
    AtlasConfig(),
    ImstModuleConfig(),
    QundisConfig(),
    IzarConfig(),
    RacBlueConfig(),
    TeksanConfig(),
    TelitXE50Config(),
  ];
  RFModuleConfig? _selectedModule;

  // --- Parser ve Veri ---
  final WMBusParser _parser = WMBusParser();
  final List<int> _rxBuffer = [];
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  final List<MeterReading> _readings = [];

  // Hedef Sayaç Listesi (Boş)
  final List<String> _targetSerials = [];

  bool _isConnected = false;
  bool _isScanning = false;
  bool _isConfiguring = false;
  Completer<void>? _configCompleter;
  String _statusMessage = "Hazır";

  @override
  void initState() {
    super.initState();
    WakelockPlus.toggle(enable: true);
    UsbSerial.usbEventStream!.listen((event) => _getPorts());
    _getPorts();

    _availableModules.sort((a, b) => a.sortId.compareTo(b.sortId));
    if (_availableModules.isNotEmpty) {
      _selectedModule = _availableModules.first;
    }
    _resetMeterList();
  }

  void _resetMeterList() {
    _readings.clear();
    for (var serial in _targetSerials) {
      _readings.add(
        MeterReading(
          manufacturer: "",
          serialNumber: serial,
          deviceType: "",
          version: 0,
          encryption: "Bekleniyor",
          frameType: "",
          values: [],
          parseTime: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  Future<void> _getPorts() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (!mounted) return;
    setState(() => _devices = devices);
  }

  // --- BAĞLANTI ---
  Future<void> _connect() async {
    if (_selectedDevice == null || _selectedModule == null) return;
    try {
      _port = await _selectedDevice!.create();
      if (!await _port!.open()) {
        _addLog("HATA: Port açılamadı.");
        return;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setFlowControl(UsbPort.FLOW_CONTROL_OFF);
      await _port!.setPortParameters(_selectedModule!.baudRate, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      _subscription = _port!.inputStream!.listen(_handleIncomingData, onError: (err) => _addLog("Err: $err"));

      setState(() {
        _isConnected = true;
        _statusMessage = "Bağlandı. Başlamaya Hazır.";
      });
      _addLog("BAĞLANDI: ${_selectedModule!.baudRate} baud.");
    } catch (e) {
      _addLog("Hata: $e");
      _disconnect();
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _port?.close();
    _subscription = null;
    _port = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isScanning = false;
        _isConfiguring = false;
        _rxBuffer.clear();
        _statusMessage = "Bağlantı Kesildi";
      });
      _addLog("Bağlantı kesildi.");
    }
  }

  // --- KONFİGÜRASYON ---
  Future<void> _startReadingWithConfig() async {
    if (!_isConnected || _port == null) {
      _addLog("Önce USB Bağlantısını kurun!");
      return;
    }

    setState(() {
      _statusMessage = "Konfigürasyon Yapılıyor...";
      _isConfiguring = true;
      _isScanning = false;
      _rxBuffer.clear();
    });

    _addLog("${_selectedModule!.name} Başlatılıyor...");

    Future<bool> sendCommandAndWait(String hexCmd) async {
      try {
        _configCompleter = Completer<void>();
        List<int> bytes = WMBusUtils.hexToBytes(hexCmd);
        _addLog("TX: $hexCmd");
        if (_port != null) {
          await _port!.write(Uint8List.fromList(bytes));
        }
        await _configCompleter!.future.timeout(const Duration(seconds: 3));
        return true;
      } catch (e) {
        _addLog("Zaman aşımı (Cevap gelmedi): $hexCmd");
        return false;
      }
    }

    bool success = true;
    for (String command in _selectedModule!.initCommands) {
      if (!_isConfiguring) {
        success = false;
        break;
      }
      bool sent = await sendCommandAndWait(command);
      if (!sent) _addLog("Uyarı: Onay alınamadı, devam ediliyor...");
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (success && _isConfiguring) {
      setState(() {
        _isConfiguring = false;
        _isScanning = true;
        _statusMessage = "Okuma Yapılıyor...";
      });
      _addLog("Modül Hazır. Sayaçlar Bekleniyor...");
    } else {
      setState(() {
        _isConfiguring = false;
        _statusMessage = "İptal/Hata.";
      });
    }
  }

  void _stopReading() {
    setState(() {
      _isScanning = false;
      _isConfiguring = false;
      if (_configCompleter != null && !_configCompleter!.isCompleted) {
        _configCompleter!.completeError("Durduruldu");
      }
      _statusMessage = "Durduruldu.";
    });
    _addLog("Kullanıcı durdurdu.");
  }

  // --- GELEN VERİ İŞLEME ---
  void _handleIncomingData(Uint8List data) {
    String hexRaw = WMBusUtils.toHexString(data);
    _addLog("RX: $hexRaw");

    // Konfigürasyon Modu
    if (_isConfiguring) {
      bool isConfigComplete = false;
      ModuleProtocol proto = _selectedModule?.protocol ?? ModuleProtocol.standard;

      if (proto == ModuleProtocol.amber) {
        if (data.isNotEmpty && data[0] == 0xFF) isConfigComplete = true;
      } else if (proto == ModuleProtocol.radiocrafts) {
        if (data.contains(0x3E)) isConfigComplete = true;
      } else {
        if (data.isNotEmpty) isConfigComplete = true;
      }

      if (isConfigComplete && _configCompleter != null && !_configCompleter!.isCompleted) {
        _configCompleter!.complete();
      }
      return;
    }

    if (!_isScanning) return;

    _rxBuffer.addAll(data);
    if (_rxBuffer.length > 4096) {
      _addLog("Buffer temizlendi (Taşma)");
      _rxBuffer.clear();
    }

    ModuleProtocol proto = _selectedModule?.protocol ?? ModuleProtocol.standard;

    // --- RADIOCRAFTS (FIX) ---
    if (proto == ModuleProtocol.radiocrafts) {
      while (_rxBuffer.length >= 5) {
        int start = _rxBuffer.indexOf(0x68);

        if (start == -1) {
          _rxBuffer.clear();
          break;
        }

        if (start > 0) {
          _rxBuffer.removeRange(0, start); // Öncesini temizle
          continue;
        }

        if (_rxBuffer.length < 2) break;
        int length = _rxBuffer[1]; // DÜZELTİLDİ

        if (_rxBuffer.length < length + 3) break;

        if (_rxBuffer[length + 2] != 0x16) {
          _rxBuffer.removeAt(0); // Paket bozuk
          continue;
        }

        List<int> packet = _rxBuffer.sublist(1, 1 + length);
        packet[0] = (packet[0] - 1) & 0xFF; // Fix: Length - 1

        _processParsedFrame(packet);

        _rxBuffer.removeRange(0, length + 3);
      }
      return;
    }

    // --- AMBER MODÜLÜ (RAW SUPPORT EKLENDİ) ---
    if (proto == ModuleProtocol.amber) {
      while (_rxBuffer.length >= 5) {
        // 1. Durum: WRAPPED (FF 03 L ...)
        if (_rxBuffer[0] == 0xFF && _rxBuffer.length > 3 && _rxBuffer[1] == 0x03) {
          int L = _rxBuffer[2];
          if (_rxBuffer.length < L + 4) break; // Veri bekleniyor

          List<int> packet = _rxBuffer.sublist(2, 2 + L);
          packet[0] = (packet[0] - 1) & 0xFF; // C# Amber Fix: L-1

          _processParsedFrame(packet);
          _rxBuffer.removeRange(0, L + 4);
          continue;
        }

        // 2. Durum: RAW M-BUS
        // int L = _rxBuffer[0];

        if (_rxBuffer[0] != 0xFF) {
          break;
        }

        _rxBuffer.removeAt(0);
      }
    }

    // --- GENEL PARSER (Standard / Amber Raw / Telit) ---
    while (_rxBuffer.isNotEmpty && proto != ModuleProtocol.radiocrafts) {
      int startIndex = -1;
      int lengthByte = 0;
      int frameOffset = 0;

      if (_rxBuffer.isNotEmpty && _rxBuffer[0] > 9 && _rxBuffer[0] < 255) {
        startIndex = 0;
        lengthByte = _rxBuffer[0];
        frameOffset = 1;
      } else {
        _rxBuffer.removeAt(0);
        continue;
      }

      int totalLen = frameOffset + lengthByte;

      if (_rxBuffer.length < totalLen) break;

      List<int> frameForParser = _rxBuffer.sublist(0, totalLen);
      _processParsedFrame(frameForParser);
      _rxBuffer.removeRange(0, totalLen);
    }
  }

  void _processParsedFrame(List<int> frameBytes) {
    MeterReading result = _parser.parseFrame(frameBytes);

    if (result.error != null) return;
    if (result.manufacturer == "UNK") return;

    // --- FİLTRE: TÜKETİM YOKSA GÖSTERME (AKTİF EDİLDİ) ---
    // Eğer 'values' listesinde kWh, m3, wh birimli veya "enerji", "hacim" açıklamalı bir veri yoksa,
    // bu okumayı KAYDETME. Sadece Tarih/Saat veya Durum (Error flags) gelmiş olabilir.
    bool hasConsumption = result.values.any((val) {
      String u = val.unit.toLowerCase();
      String d = val.description.toLowerCase();
      return u.contains("kwh") || u.contains("m3") || u.contains("wh") || d.contains("enerji") || d.contains("hacim") || d.contains("volume") || d.contains("energy");
    });

    if (!hasConsumption) {
      _addLog("SİNYAL: ${result.serialNumber} (Enerji/Hacim verisi yok, atlandı)");
      return; // İŞLEMİ DURDUR
    }

    setState(() {
      int index = _readings.indexWhere((r) => r.serialNumber == result.serialNumber);

      if (index != -1) {
        if (result.values.isNotEmpty) {
          _readings[index] = result;

          String valText = "";
          var primaryVal = result.values.firstWhere((v) => v.unit.isNotEmpty, orElse: () => result.values.first);

          if (primaryVal.stringValue.isNotEmpty) {
            valText = primaryVal.stringValue;
          } else {
            valText = "${primaryVal.value} ${primaryVal.unit}";
          }
          _addLog("GÜNCEL: ${result.serialNumber} -> $valText");
        }
      } else {
        if (result.serialNumber != "00000000") {
          _readings.add(result);
          String info = result.values.isNotEmpty ? "Veri Var" : "Bekleniyor";
          _addLog("YENİ: ${result.serialNumber} ($info)");
        }
      }
    });
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() => _logs.add("${DateTime.now().toString().substring(11, 19)} -> $msg"));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("W-MBus Okuyucu: ${_readings.length} Sayaç"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() {
              _logs.clear();
              _resetMeterList();
              _statusMessage = "Temizlendi";
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionPanel(),
          Container(
            width: double.infinity,
            color: Colors.blue[50],
            padding: const EdgeInsets.all(8),
            child: Text(
              "DURUM: $_statusMessage",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
            ),
          ),
          Expanded(
            child: _readings.isEmpty
                ? const Center(child: Text("Veri Bekleniyor..."))
                : ListView.builder(
                    itemCount: _readings.length,
                    itemBuilder: (ctx, i) => _buildMeterCard(_readings[i]),
                  ),
          ),
          InkWell(
            onTap: () => Clipboard.setData(ClipboardData(text: _logs.join('\n'))),
            child: Container(
              height: 200,
              color: Colors.black,
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _logs.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  child: Text(
                    _logs[i],
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.usb),
        onPressed: () {
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const DecodePage()));
        },
      ),
    );
  }

  Widget _buildConnectionPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        children: [
          DropdownButton<UsbDevice>(
            isExpanded: true,
            value: _selectedDevice,
            hint: const Text("USB Cihazı Seç"),
            items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.productName ?? "Cihaz"))).toList(),
            onChanged: _isConnected ? null : (v) => setState(() => _selectedDevice = v),
          ),
          DropdownButton<RFModuleConfig>(
            isExpanded: true,
            value: _selectedModule,
            hint: const Text("RF Modülü Seç"),
            onChanged: (_isScanning || _isConfiguring) ? null : (v) => setState(() => _selectedModule = v),
            items: _availableModules.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isConnected ? _disconnect : _connect,
                style: ElevatedButton.styleFrom(backgroundColor: _isConnected ? Colors.grey : Colors.green),
                child: Text(_isConnected ? "KES" : "BAĞLAN"),
              ),
              ElevatedButton.icon(
                onPressed: (_isConnected && !_isScanning && !_isConfiguring) ? _startReadingWithConfig : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text("BAŞLAT"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              ElevatedButton.icon(
                onPressed: (_isConnected && (_isScanning || _isConfiguring)) ? _stopReading : null,
                icon: const Icon(Icons.stop),
                label: const Text("DURDUR"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard(MeterReading r) {
    bool hasData = r.values.isNotEmpty;
    return InkWell(
      onTap: () => Clipboard.setData(ClipboardData(text: r.toString())),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(8),
        color: hasData ? Colors.green[50] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("SERİ: ${r.serialNumber}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    r.manufacturer,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ],
              ),
              const Divider(),
              if (hasData) ...[
                ...r.values.map((val) {
                  String displayValue = val.stringValue.isNotEmpty ? val.stringValue : "${val.value} ${val.unit}";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(val.description),
                        Text(
                          displayValue,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const Text("Veri Bekleniyor...", style: TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 5),
              InkWell(
                onTap: () => Clipboard.setData(ClipboardData(text: r.rawHex)),
                child: Text(
                  "RAW: ${r.rawHex}",
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
