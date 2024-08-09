import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  List<String> resData = [];
  bool isOpen = false;
  int running = 1;
  SerialPort port = SerialPort("/dev/ttyS1");
  List<int> writedata = [];
  List<Widget> textWidgetList = [];
  String machineStatus = "Not Ready";
  TextEditingController selectController = TextEditingController();
  final ButtonStyle style = ElevatedButton.styleFrom(
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  );

  void connectToPort() async {
    try {
      final config = SerialPortConfig()
        ..baudRate = 57600
        ..bits = 8
        ..parity = 0
        ..stopBits = 1
        ..xonXoff = 0;
      port.config = config;

      SerialPortReader reader = SerialPortReader(port, timeout: 10000);
      Stream<Uint8List> upcomingData = reader.stream.map((data) {
        return data;
      });
      port.openReadWrite();
      setState(() {
        isOpen = true;
        machineStatus = "Ready";
      });
      upcomingData.listen((data) {
        resData = data.map((e) => e.toRadixString(16)).toList();
        String res = resData.join(',');
        if (res == 'fa,fb,41,0,40') {
          if (writedata.isEmpty) {
            port.write(Uint8List.fromList([0xfa, 0xfb, 0x42, 0x00, 0x43]));
          } else {
            port.write(Uint8List.fromList(writedata));
            debugPrint('Sending Data, PackNo: ${running.toString()}');
            writedata = [];
            if (running == 255) {
              running = 1;
            } else {
              running = running + 1;
            }
          }
        } else if (res == 'fa,fb,42,0,43') {
          debugPrint('ACK from Machine');
          setState(() => machineStatus = "Pending");
        } else {
          if (resData.join(',').substring(0, 8) == 'fa,fb,71' || resData.join(',').substring(0, 8) == 'fa,fb,11') {
            debugPrint('Return ACK to machine');
            port.write(Uint8List.fromList([0xfa, 0xfb, 0x42, 0x00, 0x43]));
            setState(() => machineStatus = "Ready");
          } else if (res.substring(0, 8) != 'fa,fb,52') {
            port.write(Uint8List.fromList([0xfa, 0xfb, 0x42, 0x00, 0x43]));
            debugPrint('Received: $res');
            debugPrint('Return ACK to machine');
          }
        }
        setState(() {
          if (textWidgetList.length >= 20) textWidgetList.removeAt(0);
          textWidgetList.add(Text(res, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
        });
      });
    } on SerialPortError catch (err, _) {
      debugPrint('SerialPortError: $err');
      port.close();
    } finally {}
  }

  void writeSerialData(List<int> commands) {
    int checksum = 0;
    for (var element in commands) {
      if (element == 0xfa) {
        checksum = 0xfa;
      } else {
        checksum = checksum ^ element;
      }
    }
    commands.add(checksum);
    writedata = commands;
    var response = writedata.map((e) => e.toRadixString(16)).toList();
    debugPrint("Sent: ${response.join(',')}");
  }

  @override
  void initState() {
    super.initState();
    connectToPort();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            height: 400,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 63, 252),
                  Color.fromARGB(255, 0, 77, 192),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 1.0],
              ),
            ),
            child: const SafeArea(
                child: Text(
              "Vending Machine TestTools",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )),
          ),
        ),
        body: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    "Connected Port: ${isOpen ? port.name : "N/A"}",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Status: $machineStatus",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "PackNo: ${running.toString()}",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    "Lift Test: ",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([0xfa, 0xfb, 0x70, 0x05, running, 0x54, 0x01, 0x00, 0x00]),
                    child: const Text('Floor 0'),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([0xfa, 0xfb, 0x70, 0x05, running, 0x54, 0x01, 0x00, 0x01]),
                    child: const Text('Floor 1'),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([0xfa, 0xfb, 0x70, 0x05, running, 0x54, 0x01, 0x00, 0x02]),
                    child: const Text('Floor 2'),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([0xfa, 0xfb, 0x70, 0x05, running, 0x54, 0x01, 0x00, 0x03]),
                    child: const Text('Floor 3'),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([0xfa, 0xfb, 0x70, 0x05, running, 0x54, 0x01, 0x00, 0x04]),
                    child: const Text('Floor 4'),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([0xfa, 0xfb, 0x70, 0x05, running, 0x54, 0x01, 0x00, 0x05]),
                    child: const Text('Floor 5'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: selectController,
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  ElevatedButton(
                    style: style,
                    onPressed: () => writeSerialData([
                      0xfa,
                      0xfb,
                      0x06,
                      0x05,
                      running,
                      0x01,
                      0x01,
                      0x00,
                      selectController.text.isEmpty ? 0x01 : int.parse(selectController.text)
                    ]),
                    child: const Text('Sent'),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text("Message from Vending Machine", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.black),
                  textWidgetList.isNotEmpty
                      ? Column(
                          children: textWidgetList.reversed.toList(),
                        )
                      : const Text(
                          "No Data",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          height: 100,
          width: 100,
          child: FloatingActionButton(
            onPressed: () => writeSerialData([0xfa, 0xfb, 0x03, 0x03, running, 0x00, 0x23]),
            child: const Icon(Icons.send_sharp, size: 50),
          ),
        ),
      ),
    );
  }
}
