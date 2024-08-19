import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/services.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  DeviceBloc() : super(const DeviceState()) {
    on<ConnectDevice>((event, emit) async {
      SerialPort port = SerialPort("/dev/ttyS1");
      List<String> resData = [];
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
        emit(state.copyWith(isOpen: true, machineStatus: "Ready"));
        upcomingData.listen((data) {
          resData = data.map((e) => e.toRadixString(16)).toList();
          String res = resData.join(',');
          if (res == 'fa,fb,41,0,40') {
            if (state.writedata.isEmpty) {
              port.write(Uint8List.fromList([0xfa, 0xfb, 0x42, 0x00, 0x43]));
            } else {
              port.write(Uint8List.fromList(state.writedata));
              if (kDebugMode) {
                print('Sending Data, PackNo: ${state.running.toString()}');
              }
              emit(state.copyWith(writedata: [], running: state.running == 255 ? 1 : state.running + 1));
            }
          } else if (res == 'fa,fb,42,0,43') {
            debugPrint('ACK from Machine');
            emit(state.copyWith(machineStatus: "Pending"));
          } else {
            if (resData.join(',').substring(0, 8) == 'fa,fb,71' || resData.join(',').substring(0, 8) == 'fa,fb,11') {
              debugPrint('Return ACK to machine');
              port.write(Uint8List.fromList([0xfa, 0xfb, 0x42, 0x00, 0x43]));
              emit(state.copyWith(machineStatus: "Ready"));
            } else if (res.substring(0, 8) != 'fa,fb,52') {
              port.write(Uint8List.fromList([0xfa, 0xfb, 0x42, 0x00, 0x43]));
              debugPrint('Received: $res');
              debugPrint('Return ACK to machine');
            }
          }
          if (state.textWidgetList.length >= 20) state.textWidgetList.removeAt(0);
          state.textWidgetList.add(Text(res, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
          emit(state.copyWith(textWidgetList: state.textWidgetList));
        });
      } on SerialPortError catch (err, _) {
        if (kDebugMode) {
          print('SerialPortError: $err');
        }
        port.close();
      }
    });

    on<SetDeviceCommand>((event, emit) {
      int checksum = 0;
      for (var element in event.commands) {
        if (element == 0xfa) {
          checksum = 0xfa;
        } else {
          checksum = checksum ^ element;
        }
      }
      event.commands.add(checksum);
      emit(state.copyWith(writedata: event.commands));
      List<String> response = state.writedata.map((e) => e.toRadixString(16)).toList();
      if (kDebugMode) {
        print("Sent: ${response.join(',')}");
      }
    });
  }
}
