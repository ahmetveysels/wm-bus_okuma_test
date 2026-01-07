/// Yardımcı Araçlar
class WMBusUtils {
  static String toHexString(List<int> data) {
    return data.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
  }

  static List<int> hexToBytes(String hex) {
    hex = hex.replaceAll(" ", "");
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String byteStr = hex.substring(i, i + 2);
      bytes.add(int.parse(byteStr, radix: 16));
    }
    return bytes;
  }
}
