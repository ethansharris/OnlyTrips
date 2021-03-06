import 'dart:convert';
import 'package:http/http.dart' as http; // Use to post to the api server
import 'package:flutter/material.dart';
import 'package:onlytrips/menudrawer.dart';
import 'package:onlytrips/newtrip.dart';
import 'package:onlytrips/tripview.dart';
import 'package:onlytrips/trip.dart';
import 'package:onlytrips/shared_prefs.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Text countDown(Trip cardTrip) {
    int startYear = int.parse(cardTrip.startDate.substring(0, 4));
    int startMonth = int.parse(cardTrip.startDate.substring(5, 7));
    int startDay = int.parse(cardTrip.startDate.substring(8, 10));

    DateTime startDate = new DateTime(startYear, startMonth, startDay);

    Duration diff = startDate.difference(DateTime.now());

    return Text(
      (diff.inDays + 1).toString(),
      style: TextStyle(fontSize: 40.0, fontFamily: "Gotham Light Regular"),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  // Used to hold trip ID Strings
  List<String> tripList = new List<String>();

  // Holds all trip details after getting them with tripList values
  List<Trip> tripDetails = new List<Trip>();

  @override
  void initState() {
    super.initState();
    _getData();
    Future.delayed(const Duration(milliseconds: 500), () async {
      return _refreshIndicatorKey.currentState.show();
    });
  }

  Future _getData() async {
    await updateTrips();
    setState(() {
      tripList.forEach((element) async {
        await fetchTrips(element);
      });
    });
  }

  Future<void> updateTrips() async {
    final http.Response response =
        await http.post('https://onlytrips.herokuapp.com/travel',
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'email': sharedPrefs.currUser.email,
            }));
    if (response.statusCode == 200) {
      tripList = GetTripList.fromJson(jsonDecode(response.body)).trips;
      return;
    } else {
      throw Exception('Unable to get trips');
    }
  }

  Future<void> fetchTrips(String tripId) async {
    final http.Response response =
        await http.post('https://onlytrips.herokuapp.com/singleTrip',
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'id': tripId,
            }));
    if (response.statusCode == 200) {
      Trip newTrip = GetTripDetails.fromJson(jsonDecode(response.body)).trip;
      if (!tripDetails.contains(newTrip)) tripDetails.add(newTrip);
      return;
    } else {
      throw Exception('Unable to get trips');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Only',
              style: TextStyle(
                fontFamily: 'Gotham Light Regular',
                fontSize: 25.0,
              ),
            ),
            Text(
              'Trips',
              style: TextStyle(
                fontFamily: 'Marguerite',
                fontSize: 20.0,
                color: Colors.lightBlueAccent[400],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            semanticLabel: 'menu',
          ),
          onPressed: () => _scaffoldKey.currentState.openDrawer(),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.search,
              semanticLabel: 'search',
            ),
            onPressed: () {
              _getData();
            },
          ),
        ],
      ),
      drawer: new NavDrawer(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await _getData();
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: tripDetails.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TripView(currTrip: tripDetails[index]))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                    borderOnForeground: true,
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tripDetails
                                .elementAt(index)
                                .destination
                                .elementAt(0)
                                .city,
                            style: TextStyle(
                              fontFamily: 'Gotham Light Regular',
                              fontSize: 40.0,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                size: 50.0,
                              ),
                              countDown(tripDetails[index])
                            ],
                          )
                        ],
                      ),
                    )),
              ),
            );
          },
        ),
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: new FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => NewTrip())),
        tooltip: 'New Trip',
        child: new Icon(Icons.add),
        backgroundColor: Colors.lightBlueAccent[400],
      ),
    );
  }
}
