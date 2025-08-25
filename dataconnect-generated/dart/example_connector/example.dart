library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'dart:convert';







class ExampleConnector {
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'example',
    'step02',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}



/* Future<void> fetchUsers() async {
  final response = await dataConnect.query('GetUsers', variables: {});
  print(response.toJson());
} */
