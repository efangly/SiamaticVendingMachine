part of 'device_bloc.dart';

sealed class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object> get props => [];
}

class ConnectDevice extends DeviceEvent {}

class SetDeviceCommand extends DeviceEvent {
  final List<int> commands;
  const SetDeviceCommand(this.commands);
}
