// Dosya: lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Kendi proje dosyaların
import 'meter_model.dart';
import 'module_config.dart';
import 'wm_bus_parser.dart';
import 'wmbus_utils.dart';

// Eğer 'decode_page.dart' varsa import et, yoksa sil
// import 'package:testrfidokuma/decode_page.dart';

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

  // Hedef Sayaç Listesi
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
      _readings.add(MeterReading(manufacturer: "", serialNumber: serial, deviceType: "", version: 0, encryption: "Bekleniyor", frameType: "", values: [], parseTime: DateTime.now()));
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

    // Amber Protokolü (FF varsa temizle)
    if (proto == ModuleProtocol.amber) {
      while (_rxBuffer.isNotEmpty) {
        if (_rxBuffer[0] == 0xFF) {
          if (_rxBuffer.length > 2) {
            _rxBuffer.removeAt(0);
            continue;
          } else {
            break;
          }
        }
        break;
      }
    }

    while (_rxBuffer.isNotEmpty) {
      int startIndex = -1;
      int lengthByte = 0;
      int frameOffset = 0;

      if (proto == ModuleProtocol.radiocrafts) {
        startIndex = _rxBuffer.indexOf(0x68);
        if (startIndex != -1 && _rxBuffer.length > startIndex + 1) {
          lengthByte = _rxBuffer[startIndex + 1];
          frameOffset = 2;
        } else if (_rxBuffer.isNotEmpty && _rxBuffer[0] >= 10) {
          startIndex = 0;
          lengthByte = _rxBuffer[0];
          frameOffset = 1;
        }
      } else {
        if (_rxBuffer.isNotEmpty && _rxBuffer[0] > 9 && _rxBuffer[0] < 255) {
          startIndex = 0;
          lengthByte = _rxBuffer[0];
          frameOffset = 1;
        } else {
          _rxBuffer.removeAt(0);
          continue;
        }
      }

      if (startIndex == -1) break;
      if (startIndex > 0) _rxBuffer.removeRange(0, startIndex);

      int totalLen = frameOffset + lengthByte;
      if (_rxBuffer.length < totalLen) break;

      List<int> frameForParser = _rxBuffer.sublist(0, totalLen);
      _rxBuffer.removeRange(0, totalLen);

      _processParsedFrame(frameForParser);
    }
  }

  void _processParsedFrame(List<int> frameBytes) {
    MeterReading result = _parser.parseFrame(frameBytes);

    if (result.error != null) return;
    if (result.manufacturer == "UNK") return;

    setState(() {
      int index = _readings.indexWhere((r) => r.serialNumber == result.serialNumber);

      if (index != -1) {
        if (result.values.isNotEmpty) {
          _readings[index] = result;

          String valText = "";
          if (result.values.first.stringValue.isNotEmpty) {
            valText = result.values.first.stringValue;
          } else {
            valText = "${result.values.first.value} ${result.values.first.unit}";
          }
          _addLog("GÜNCEL: ${result.serialNumber} -> $valText");
        } else {
          _addLog("SİNYAL: ${result.serialNumber} (Veri bloğu yok - Eski değer korundu)");
        }
      } else {
        if (result.serialNumber != "00000000") {
          _readings.add(result);
          String info = result.values.isNotEmpty ? "Veri Var" : "Veri Bekleniyor...";
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
                  // EĞER STRINGVALUE DOLUYSA ONU GÖSTER (Tarih vb.)
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
