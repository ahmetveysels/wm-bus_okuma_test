import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:testrfidokuma/meter_model.dart';
import 'package:testrfidokuma/wm_bus_parser.dart';

class DecodePage extends StatefulWidget {
  const DecodePage({super.key});

  @override
  State<DecodePage> createState() => _DecodePageState();
}

class _DecodePageState extends State<DecodePage> {
  final Rx<MeterReading?> _decodedReading = Rx<MeterReading?>(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decode Page'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              final String hex1 = "43 93 44 00 98 65 67 46 37 72 00 98 65 67 93 44 46 04 0E 00 00 20 0C 06 50 10 00 00 4C 06 50 10 00 00 42 6C 3F 3C CC 08 06 50 10 00 00 C2 08 6C 3F 3C 02 FD 17 00 00 32 6C FF FF 04 6D 0E 0A 45 31 12";
              final String hex2 = "43 93 44 00 98 65 67 46 37 72 00 98 65 67 93 44 46 04 0E 00 00 20 0C 06 50 10 00 00 4C 06 50 10 00 00 42 6C 3F 3C CC 08 06 50 10 00 00 C2 08 6C 3F 3C 02 FD 17 00 00 32 6C FF FF 04 6D 0E 0A 45 31 12";
              final String hex3 = "43 93 44 00 98 65 67 46 37 78 07 79 00 98 65 67 93 44 46 04 0D FF 5F 35 00 82 C8 00 00 F0 00 07 C0 06 FF FF 50 10 00 00 3F 3C 50 10 00 00 3F 3C 50 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2F 02 FD 17 00 00 04 6D 16 09 46 31 12";
              final String hex4 = "3D 44 93 44 00 98 65 67 46 37 72 00 98 65 67 93 44 46 04 C0 00 08 20 04 ED 39 2A 07 05 32 01 FD 0C 11 04 6D 12 10 47 31 02 FD 3C C2 01 0D FF 5F 0C 00 08 D7 FF 00 80 06 13 07 01 FF FC 12";
              final String hex = hex1.trim().replaceAll(" ", "");
              final WMBusParser parser = WMBusParser();
              //String hex1 to List<int> bytes
              List<int> frameBytes = [];
              for (int i = 0; i < hex.length; i += 2) {
                String byteString = hex.substring(i, i + 2);
                int byteValue = int.parse(byteString, radix: 16);
                frameBytes.add(byteValue);
              }
              MeterReading result = parser.parseFrame(frameBytes);
              debugPrint("Parsed: $result");
              _decodedReading.value = result;
            },
            child: const Text("Decode "),
          ),
          Obx(() {
            final reading = _decodedReading.value;
            if (reading == null) {
              return const Text("No data decoded yet.");
            } else if (reading.error != null) {
              return Text("Error: ${reading.error}");
            } else {
              return Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text("Manufacturer: ${reading.manufacturer}"),
                    ),
                    ListTile(
                      title: Text("Serial Number: ${reading.serialNumber}"),
                    ),
                    ListTile(
                      title: Text("Device Type: ${reading.deviceType}"),
                    ),
                    ListTile(
                      title: Text("Version: ${reading.version}"),
                    ),
                    ListTile(
                      title: Text("Encryption: ${reading.encryption}"),
                    ),
                    ListTile(
                      title: Text("Frame Type: ${reading.frameType}"),
                    ),
                    const Divider(),
                    ...reading.values.map(
                      (val) => ListTile(
                        title: Text(val.toString()),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }
}
