import 'dart:async';
import 'dart:core';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_location_flutter/common_components/build_marker.dart';
import 'package:at_location_flutter/location_modal/hybrid_model.dart';
import 'package:at_location_flutter/service/master_location_service.dart';
import 'package:latlong/latlong.dart';

import 'at_location_notification_listener.dart';
import 'distance_calculate.dart';
import 'my_location.dart';

class LocationService {
  LocationService._();
  static LocationService _instance = LocationService._();
  factory LocationService() => _instance;

  List<String> atsignsToTrack;

  AtClientImpl atClientInstance;

  HybridModel eventData;
  HybridModel myData;
  LatLng etaFrom;
  String textForCenter;
  bool calculateETA, addCurrentUserMarker, isMapInitialized = false;

  List<HybridModel> hybridUsersList;

  StreamController _atHybridUsersController;
  Stream<List<HybridModel>> get atHybridUsersStream =>
      _atHybridUsersController.stream;
  StreamSink<List<HybridModel>> get atHybridUsersSink =>
      _atHybridUsersController.sink;

  init(List<String> atsignsToTrackFromApp,
      {LatLng etaFrom,
      bool calculateETA,
      bool addCurrentUserMarker,
      String textForCenter}) async {
    hybridUsersList = [];
    _atHybridUsersController = StreamController<List<HybridModel>>.broadcast();
    atsignsToTrack = atsignsToTrackFromApp;
    this.etaFrom = etaFrom;
    this.calculateETA = calculateETA;
    this.addCurrentUserMarker = addCurrentUserMarker;
    this.textForCenter = textForCenter;
    print('atsignsTotrack $atsignsToTrack');
    if (etaFrom != null) addCentreMarker();
    await addMyDetailsToHybridUsersList();

    updateHybridList();
  }

  void dispose() {
    _atHybridUsersController.close();
    isMapInitialized = false;
  }

  mapInitialized() {
    isMapInitialized = true;
  }

  addMyDetailsToHybridUsersList() async {
    String _atsign = AtLocationNotificationListener().currentAtSign;
    LatLng mylatlng = await MyLocation().myLocation();
    var _image = await MasterLocationService().getImageOfAtsignNew(_atsign);

    HybridModel _myData = HybridModel(
        displayName: _atsign, latLng: mylatlng, eta: '?', image: _image);
    if (etaFrom != null) _myData.eta = await _calculateEta(_myData);

    _myData.marker = buildMarker(_myData);

    myData = _myData;

    if (addCurrentUserMarker) {
      hybridUsersList.add(myData);
    }
    // this is added to _atHybridUsersController using WidgetsBinding.instance.addPostFrameCallback from at_location_flutter_plugin
    // adding it here was leading to Ticker not getting disposed
  }

  addCentreMarker() {
    HybridModel centreMarker = HybridModel(
        displayName: textForCenter, latLng: etaFrom, eta: '', image: null);
    centreMarker.marker = buildMarker(centreMarker);
    // TODO : Think of another way
    Future.delayed(
        const Duration(seconds: 2), () => hybridUsersList.add(centreMarker));
  }

  // called for the first time pckage is entered from main app
  updateHybridList() async {
    print('updateHybridList location_service');

    await Future.forEach(MasterLocationService().allReceivedUsersList,
        (user) async {
      print('MasterLocationService().allReceivedUsersList ${user.displayName}');
      print(
          'atsignsToTrack.contains(user.displayName) ${atsignsToTrack.contains(user.displayName)}');
      if (atsignsToTrack.contains(user.displayName)) await updateDetails(user);
    });

    print('hybridUsersList $hybridUsersList');
    hybridUsersList.forEach((element) {
      print('added in updateHybridList: ${element.displayName}');
      print('added in updateHybridList: ${element.latLng}');
    });

    if (hybridUsersList.length != 0)
      Future.delayed(const Duration(seconds: 2),
          () => _atHybridUsersController.add(hybridUsersList));
    // if (isMapInitialized) notifyListeners();
  }

  // called when any new/updated data is received in the main app
  newList() async {
    print('inside newList location_service');
    if (atsignsToTrack != null) {
      await Future.forEach(MasterLocationService().allReceivedUsersList,
          (user) async {
        print(
            'MasterLocationService().allReceivedUsersList newList ${user.displayName}');
        print(
            'atsignsToTrack.contains(user.displayName) newList ${atsignsToTrack.contains(user.displayName)}');

        if (atsignsToTrack.contains(user.displayName))
          await updateDetails(user);
      });
      hybridUsersList.forEach((element) {
        print('added in location_service: ${element.displayName}');
      });
      if (!_atHybridUsersController.isClosed)
        _atHybridUsersController.add(hybridUsersList);
    }
  }

  // called when a user stops sharing his location
  removeUser(String atsign) {
    if ((atsignsToTrack != null) && (hybridUsersList.length != 0)) {
      hybridUsersList.removeWhere((element) => element.displayName == atsign);
      if (!_atHybridUsersController.isClosed)
        _atHybridUsersController.add(hybridUsersList);
    }
  }

  // called to get the new details marker & eta
  updateDetails(HybridModel user) async {
    bool contains = false;
    int index;
    hybridUsersList.forEach((hybridUser) {
      if (hybridUser.displayName == user.displayName) {
        contains = true;
        index = hybridUsersList.indexOf(hybridUser);
      }
    });
    if (contains) {
      print('${hybridUsersList[index].latLng} != ${user.latLng}');
      await addDetails(user, index: index);
    } else
      await addDetails(user);
  }

  // returns new marker and eta
  addDetails(HybridModel user, {int index}) async {
    user.marker = buildMarker(user);
    user.eta = await _calculateEta(user);
    // user.eta = '?';
    if (index != null)
      hybridUsersList[index] = user;
    else
      hybridUsersList.add(user);
    print('hybridUsersList from addDetails $hybridUsersList');
  }

  _calculateEta(HybridModel user) async {
    if (calculateETA)
      try {
        var _res;
        if (etaFrom != null)
          _res = await DistanceCalculate().calculateETA(etaFrom, user.latLng);
        else
          _res =
              await DistanceCalculate().calculateETA(myData.latLng, user.latLng);
        return _res;
      } catch (e) {
        print('Error in _calculateEta $e');
        return '?';
      }
    else
      return '?';
  }

  notifyListeners() {
    if (hybridUsersList.length > 0)
      _atHybridUsersController.add(hybridUsersList);
  }
}