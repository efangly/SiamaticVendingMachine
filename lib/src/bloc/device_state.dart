part of 'device_bloc.dart';

class DeviceState extends Equatable {
  final List<int> writedata;
  final bool isOpen;
  final String machineStatus;
  final int running;
  final List<Widget> textWidgetList;
  const DeviceState({
    this.writedata = const [],
    this.isOpen = false,
    this.machineStatus = "Not Ready",
    this.running = 1,
    this.textWidgetList = const [],
  });

  DeviceState copyWith({
    List<int>? writedata,
    bool? isOpen,
    String? machineStatus,
    int? running,
    List<Widget>? textWidgetList,
  }) {
    return DeviceState(
      writedata: writedata ?? this.writedata,
      isOpen: isOpen ?? this.isOpen,
      machineStatus: machineStatus ?? this.machineStatus,
      running: running ?? this.running,
      textWidgetList: textWidgetList ?? this.textWidgetList,
    );
  }

  @override
  List<Object> get props => [writedata, isOpen, machineStatus, running, textWidgetList];
}
