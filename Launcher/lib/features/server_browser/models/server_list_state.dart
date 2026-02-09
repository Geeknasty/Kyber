import 'package:kyber_launcher/features/server_browser/models/server_filter.dart';

class ServerListState {
  const ServerListState();
}

class ServerListInitial extends ServerListState {
  const ServerListInitial();
}

class ServerListLoading extends ServerListState {
  const ServerListLoading({this.filter});

  final ServerFilter? filter;
}

class ServerListLoaded extends ServerListState {
  const ServerListLoaded({
    required this.servers,
    required this.filter,
  });

  final ServerFilter filter;
  final List<Object> servers;
}

class ServerListError extends ServerListState {
  const ServerListError(this.message);

  final String message;
}
