import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_sp2/const.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:rxdart/rxdart.dart';

class StreamPageWidget extends StatefulWidget {
  @override
  _StreamPageWidgetState createState() => _StreamPageWidgetState();
}

class _StreamPageWidgetState extends State<StreamPageWidget> {
  Stream<List<DocumentSnapshot>> stream;
  final _firestore = FirebaseFirestore.instance;
  final geo = Geoflutterfire();
  var radius =  BehaviorSubject<double>.seeded(1.0);

  @override
  void initState() {
    super.initState();
    final center = geo.point(latitude: 41.312710528718796, longitude: 69.27733964256669);
    stream = radius.switchMap((rad) {
      var collectionReference = _firestore.collection(COLLECTION);
      return geo.collection(collectionRef: collectionReference).within(
          center: center, radius: rad, field: 'position', strictMode: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          StreamBuilder(
            stream: stream,
            builder: (BuildContext context,
                AsyncSnapshot<List<DocumentSnapshot>> snapshots) {
              if (snapshots.connectionState == ConnectionState.active &&
                  snapshots.hasData) {
                print('data ${snapshots.data}');
                return Container(
                  height: MediaQuery.of(context).size.height * 1/1.45,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final doc = snapshots.data[index];
                      final data = doc.data();
                      print(
                          'doc with id ${doc.id} distance ${data['distance']}');
                      GeoPoint point = data['position']['geopoint'];
                    
                      return ListTile(
                        title: Text(
                         doc.data()[COMPANY_NAME],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${point.latitude}, ${point.longitude}'),
                        trailing: Text(
                            '${data['documentType'] == DocumentChangeType.added ? 'Added' : 'Modified'}'),
                      );
                    },
                    itemCount: snapshots.data.length,
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Slider(
              min: 1,
              max: 100,
              divisions: 5,
              value: _value,
              label: _label,
              activeColor: Colors.blue,
              inactiveColor: Colors.blue.withOpacity(0.2),
              onChanged: (double value) => changed(value),
            ),
          ),
        ],
      ),
    );
  }

  double _value = 1.0;
  String _label = '';

  changed(value) {
    setState(() {
      _value = value;
      print(_value);
      _label = '${_value.toInt().toString()} kms';
    });
    radius.add(value);
  }
}