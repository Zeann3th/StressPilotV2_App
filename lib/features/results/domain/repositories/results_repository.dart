import '../models/request_log.dart';

abstract class ResultsRepository {
  Stream<List<RequestLog>> get logStream;
  bool get isConnected;
  void connect();
  void disconnect();
  void dispose();
}
