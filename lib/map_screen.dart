import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:intl/intl.dart';
import 'package:isearch/models/place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:sunrise_sunset/sunrise_sunset.dart';

class MapScreen extends  StatefulWidget {
  String _detectedObject;
  MapScreen(this._detectedObject);
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  var _currentLocation;
  bool _isLoading,_isdark=false;
  Set<Polyline> polyline={};
  GoogleMapPolyline _googleMapPolyline=GoogleMapPolyline(apiKey: 'AIzaSyAic3e4Kt0mfxq6p3z-q8etA7XvvnSFGLU');
  var routeCoords;
  List<Place> _places=[];
  List<Marker> allMarkers=[];
  List<bool> _isDirection=[];
  LatLng _lastMapPosition;
  GoogleMapController _controller;
  PageController _pageController;
  int prevPage;
  DateTime sunrise,sunset;

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      _isLoading=true;
    });
    Geolocator().getCurrentPosition().then((currloc) {
      setState(() {
        _currentLocation = currloc;
        print(_currentLocation);
      });
       _getLocationData();
      });

    super.initState();
  }

  Future _getLocationData() async{
    final response = await SunriseSunset.getResults(
        latitude: _currentLocation.latitude, longitude: _currentLocation.longitude).then((value){
          print(value.data.sunrise);
          var dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(value.data.sunrise.toString(), true);
          var dateTime1 = DateFormat("yyyy-MM-dd HH:mm:ss").parse(value.data.sunset.toString(), true);
          setState(() {
            sunrise= dateTime.toLocal();
            sunset=dateTime1.toLocal();
          });
    });



      await http.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLocation.latitude},${_currentLocation.longitude}&radius=2000&keyword=${widget._detectedObject}&key=AIzaSyAic3e4Kt0mfxq6p3z-q8etA7XvvnSFGLU',
      ).then((response){
        print(json.decode(response.body));
        final Response=json.decode(response.body);
        Response['results'].map((element){
          return _places.add(
            Place(
              shopName: element['name'],
              address: element['vicinity'],
              description: element['name'],
              thumbnail: element['icon'],
              locationCoords: LatLng(element['geometry']['location']['lat'],element['geometry']['location']['lng']),
            )
          );
        }).toList();
//        print(_places[0].shopName);
//        print(_places[0].address);
//        print(_places[0].description);
//        print(_places[0].thumbnail);
//        print(_places[0].locationCoords);
        _places.forEach((element){
          allMarkers.add(
            Marker(
              markerId: MarkerId(element.shopName),
              draggable: false,
              infoWindow: InfoWindow(title: element.shopName,snippet: element.address),
              position: element.locationCoords,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            )
          );
          //Make list of bool for direction button
          _isDirection.add(false);
          print('No. of var in Bool direction: ${_isDirection.length}');
          _pageController = PageController(initialPage: 1, viewportFraction: 0.8)
            ..addListener(_onScroll);
          print(allMarkers);
        });

        setState(() {
          _isLoading=false;
        });
      } );
  }

  void _onScroll() {
    if (_pageController.page.toInt() != prevPage) {
      prevPage = _pageController.page.toInt();
      moveCamera();
    }
  }

  changeMapMode(){
    if(DateTime.now().isAfter(sunrise) && DateTime.now().isBefore(sunset)){
      getJsonFile('assets/sunrise.json').then(setMapStyle);
    }
    else{
      getJsonFile('assets/sunset.json').then(setMapStyle);
    }


  }

  changeMode(){
    if(!_isdark){
      getJsonFile('assets/sunrise.json').then(setMapStyle);
    }
    else{
      getJsonFile('assets/sunset.json').then(setMapStyle);
    }

  }

  Future<String> getJsonFile(String path) async{
    return await rootBundle.loadString(path);
  }

  void setMapStyle(String mapstyle){
    _controller.setMapStyle(mapstyle);
  }

  _onMapCreated(GoogleMapController controller) {
   // _controller.complete(controller);
    setState(() {
      _controller=controller;
    });
    changeMapMode();
    setState(() {
    });
  }

  moveCamera() {
    _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: _places[_pageController.page.toInt()].locationCoords,
        zoom: 17.0,
        bearing: 45.0,
        tilt: 60.0)));
  }

  _coffeeShopList(index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (BuildContext context, Widget widget) {
        double value = 1;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page - index;
          value = (1 - (value.abs() * 0.3) + 0.06).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 160.0,
            width: Curves.easeInOut.transform(value) * 350.0,
            child: widget,
          ),
        );
      },
      child: InkWell(
          onTap: () {
            // moveCamera();
          },
          child: Stack(children: [
            Center(
                child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 20.0,
                    ),
                    height: 125.0,
                    width: 275.0,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(0.0, 4.0),
                            blurRadius: 10.0,
                          ),
                        ]),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: Row(children: [
                          Container(
                              height: 90.0,
                              width: 90.0,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10.0),
                                      topLeft: Radius.circular(10.0)),
                                  image: DecorationImage(
                                      image: NetworkImage(
                                          _places[index].thumbnail),
                                      fit: BoxFit.cover))),
                          SizedBox(width: 5.0),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 180,
                                  child: Text(
                                    _places[index].shopName,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: 180,
                                  child: Text(
                                    _places[index].address,
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: 170.0,
                                  child: Text(
                                    _places[index].description,
                                    style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w300),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: 160,
                                  height: 30,
                                  child: FlatButton.icon(
                                    onPressed:(!_isDirection[index])?(){
                                      for(int i=0;i<_places.length;i++){
                                        if(i!=index){
                                          _isDirection[i]=false;
                                        }
                                        else{
                                          _isDirection[i]=true;
                                        }
                                      };
                                      _setDirection(_places[index].locationCoords);
                                    }:(){
                                      setState(() {
                                        _isDirection[index]=false;
                                        polyline.clear();
                                      });
                                    },
                                   icon: (!_isDirection[index])?Icon(Icons.directions,color: Colors.white,):Icon(Icons.close,color: Colors.white,),
                                   label: (!_isDirection[index])?Text('Directions',style: TextStyle(color: Colors.white),):Text('Cancel',style: TextStyle(color: Colors.white),),
                                   color: (!_isDirection[index])?Colors.blue:Colors.red,
                                   shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)),
                                   ),
                                )
                              ])
                        ]))))
          ])),
    );
  }

  Future _setDirection(LatLng destination) async{
   routeCoords = await _googleMapPolyline.getCoordinatesWithLocation(
     origin: LatLng(_currentLocation.latitude,_currentLocation.longitude),
      destination: destination,
       mode: RouteMode.driving);
       setState(() {
         polyline.add(
        Polyline(
          polylineId: PolylineId('route1'),
          visible: true,
          points: routeCoords,
          width: 4,
          color: Colors.blue,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap
        ),
      ); 
       });
      
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ISearch'),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline,color: _isdark?Colors.white:Colors.black,),
            onPressed: (){
              setState(() {
                _isdark?_isdark=false:_isdark=true;
                 changeMode();
              });
            },
          ),
        ]
      ),
      body: Stack(
        children: [
          (_isLoading)?Center(child:CircularProgressIndicator()):Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              rotateGesturesEnabled: true,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              onMapCreated: _onMapCreated,
              mapType: MapType.normal,
              polylines: polyline,
              markers: Set.from(allMarkers),
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentLocation.latitude, _currentLocation.longitude),
                zoom: 15.0,
              ),
            ),
          ),
          Positioned(
            bottom: 20.0,
            child: Container(
              height: 200.0,
              width: MediaQuery.of(context).size.width,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _places.length,
                itemBuilder: (BuildContext context, int index) {
                  return _coffeeShopList(index);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
