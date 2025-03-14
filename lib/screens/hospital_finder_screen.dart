import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hospy_nav/config/api_config.dart'; // Ensure this contains valid API keys
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;

// Utility Functions (unchanged)
String formatDuration(num seconds) {
  if (!seconds.isFinite) return 'N/A';
  final Duration duration = Duration(seconds: seconds.round());
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  final int remainingSeconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
  } else if (minutes > 0) {
    return '$minutes min ${remainingSeconds.toString().padLeft(2, '0')} sec';
  } else {
    return '$remainingSeconds sec';
  }
}

String formatDistance(num distanceInMeters) {
  final double distanceInKm = distanceInMeters / 1000;
  return distanceInKm >= 1
      ? '${distanceInKm.toStringAsFixed(2)} km'
      : '${distanceInMeters.toStringAsFixed(0)} m';
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({super.key});

  @override
  HospitalFinderScreenState createState() => HospitalFinderScreenState();
}

class HospitalFinderScreenState extends State<HospitalFinderScreen> with TickerProviderStateMixin {
  bool isLoading = true;
  bool isNavigating = false;
  bool isSearchBarVisible = true;
  bool isHospitalListVisible = true;
  late MapController mapController;
  LatLng? currentPosition;
  final LatLng defaultLocation = const LatLng(-1.2921, 36.8219); // Nairobi
  String selectedTransportMode = 'driving-car';
  List<Map<String, dynamic>> nearbyHospitals = [];
  List<Map<String, dynamic>> filteredHospitals = [];
  int? selectedHospitalIndex;
  List<Polyline> navigationLines = [];
  List<LatLng> fullRouteCoordinates = [];
  List<Map<String, dynamic>> navigationSteps = [];
  int currentNavigationStep = 0;
  double totalDistance = 0.0;
  double distanceTraveled = 0.0;
  double? heading;
  final TextEditingController searchController = TextEditingController();
  final DraggableScrollableController dragController = DraggableScrollableController();
  double remainingDuration = 0.0;

  final List<Map<String, String>> transportModes = [
    {'id': 'driving-car', 'name': 'Car', 'icon': 'directions_car'},
    {'id': 'cycling-regular', 'name': 'Bicycle', 'icon': 'directions_bike'},
    {'id': 'foot-walking', 'name': 'Walking', 'icon': 'directions_walk'},
  ];

  // Your existing hospital dataset (unchanged, truncated for brevity)
  final List<Map<String, dynamic>> allHospitals = [
    {
      "name": "Nairobi Hospital",
      "address": "Argwings Kodhek Rd, Nairobi, Kenya",
      "services": "Emergency Care, Surgery, Pediatrics, Radiology, Cardiology",
      "lat": -1.2921,
      "lon": 36.8219,
      "phone": "+254 20 2845000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Aga Khan University Hospital",
      "address": "3rd Parklands Avenue, Nairobi, Kenya",
      "services": "Emergency Care, Surgery, Oncology, Cardiology, Neurology",
      "lat": -1.2618,
      "lon": 36.8238,
      "phone": "+254 20 3662000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "MP Shah Hospital",
      "address": "Shivachi Road, Parklands, Nairobi",
      "services": "Emergency Care, Surgery, Pediatrics, Cardiology, Orthopedics",
      "lat": -1.2635,
      "lon": 36.8134,
      "phone": "+254 20 3742763",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kenyatta National Hospital",
      "address": "Hospital Road, Upper Hill, Nairobi",
      "services": "Emergency Care, Surgery, Pediatrics, Oncology, Cardiology",
      "lat": -1.3008,
      "lon": 36.8072,
      "phone": "+254 20 2726300",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Mater Hospital",
      "address": "South B, Dunga Road, Nairobi",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Cardiology",
      "lat": -1.3075,
      "lon": 36.8453,
      "phone": "+254 20 6903000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Gertrude's Children's Hospital",
      "address": "Muthaiga Road, Nairobi",
      "services": "Pediatric Emergency, Pediatric Surgery, Pediatric Oncology, Pediatric Neurology, Pediatric Cardiology",
      "lat": -1.2566,
      "lon": 36.8354,
      "phone": "+254 20 7206000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Coast General Teaching & Referral Hospital",
      "address": "Moi Avenue, Mombasa",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Cardiology",
      "lat": -4.0435,
      "lon": 39.6682,
      "phone": "+254 41 2314204",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Moi Teaching & Referral Hospital",
      "address": "Nandi Road, Eldoret",
      "services": "Emergency Care, Surgery, Pediatrics, Oncology, Cardiology",
      "lat": 0.5143,
      "lon": 35.2698,
      "phone": "+254 53 2033471",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kakamega County Referral Hospital",
      "address": "Kakamega-Webuye Road, Kakamega",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Gynecology",
      "lat": 0.2827,
      "lon": 34.7519,
      "phone": "+254 56 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kisumu County Referral Hospital",
      "address": "Angawa Avenue, Kisumu",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": -0.10153,
      "lon": 34.7556,
      "phone": "+254 57 2020833",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Nakuru Level 5 Hospital",
      "address": "Nakuru-Sigor Road, Nakuru",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Orthopedics",
      "lat": -0.2767,
      "lon": 36.0714,
      "phone": "+254 51 2216383",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Machakos Level 5 Hospital",
      "address": "Machakos Town, Machakos",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Ophthalmology",
      "lat": -1.5177,
      "lon": 37.2634,
      "phone": "+254 44 20014",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Embu Level 5 Hospital",
      "address": "Hospital Road, Embu",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Dialysis",
      "lat": -0.5333,
      "lon": 37.4500,
      "phone": "+254 68 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Nyeri County Referral Hospital",
      "address": "Mumbi Road, Nyeri",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Oncology",
      "lat": -0.4167,
      "lon": 36.9500,
      "phone": "+254 61 2030641",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Thika Level 5 Hospital",
      "address": "Kenyatta Highway, Thika",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, ENT",
      "lat": -1.0333,
      "lon": 37.0833,
      "phone": "+254 67 22777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kitale County Referral Hospital",
      "address": "Kitale-Kapenguria Road, Kitale",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Nutrition",
      "lat": 1.0167,
      "lon": 35.0000,
      "phone": "+254 54 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Garissa County Referral Hospital",
      "address": "Kismayu Road, Garissa",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Tropical Disease Unit",
      "lat": -0.4569,
      "lon": 39.6406,
      "phone": "+254 46 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kerugoya County Referral Hospital",
      "address": "Kerugoya-Kutus Road, Kerugoya",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Dialysis",
      "lat": -0.4989,
      "lon": 37.2803,
      "phone": "+254 60 21777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Busia County Referral Hospital",
      "address": "Busia-Kisumu Road, Busia",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, HIV Care",
      "lat": 0.4608,
      "lon": 34.1117,
      "phone": "+254 55 22455",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Siaya County Referral Hospital",
      "address": "Siaya-Kisumu Road, Siaya",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Ophthalmology",
      "lat": 0.0607,
      "lon": 34.2881,
      "phone": "+254 57 321081",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Voi County Referral Hospital",
      "address": "Voi-Taveta Road, Voi",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Snake Bite Unit",
      "lat": -3.3947,
      "lon": 38.5694,
      "phone": "+254 43 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Malindi Sub-County Hospital",
      "address": "Hospital Road, Malindi",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Tropical Disease Unit",
      "lat": -3.2138,
      "lon": 40.1169,
      "phone": "+254 42 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Naivasha Sub-County Hospital",
      "address": "Moi South Lake Road, Naivasha",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Burns Unit",
      "lat": -0.7172,
      "lon": 36.4359,
      "phone": "+254 50 2021022",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kericho County Referral Hospital",
      "address": "Kericho-Kisumu Road, Kericho",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Dialysis",
      "lat": -0.3684,
      "lon": 35.2830,
      "phone": "+254 52 30777",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Longisa County Referral Hospital",
      "address": "Bomet-Narok Road, Bomet",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, ENT",
      "lat": -0.7833,
      "lon": 35.3333,
      "phone": "+254 52 21022",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Homa Bay County Teaching and Referral Hospital",
      "address": "Homa Bay-Rongo Road, Homa Bay",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, HIV Care",
      "lat": -0.5277,
      "lon": 34.4577,
      "phone": "+254 59 22044",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
  "name": "PCEA Kikuyu Hospital",
  "address": "Kikuyu Town, Kiambu County",
  "services": "Orthopedics, Eye Care, General Surgery, Pediatrics",
  "lat": -1.2456,
  "lon": 36.6647,
  "phone": "+254 20 2040760",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Mary's Mission Hospital",
  "address": "Langata Road, Nairobi",
  "services": "Emergency Care, Maternity, Surgery, Diagnostics",
  "lat": -1.3278,
  "lon": 36.7795,
  "phone": "+254 20 3539999",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Consolata Hospital Nkubu",
  "address": "Nkubu, Meru County",
  "services": "General Medicine, Surgery, Maternity, Pediatrics",
  "lat": -0.0500,
  "lon": 37.6500,
  "phone": "+254 64 31313",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "AIC Kijabe Hospital",
  "address": "Kijabe, Kiambu County",
  "services": "Surgery, Orthopedics, Pediatrics, Training",
  "lat": -0.9431,
  "lon": 36.5958,
  "phone": "+254 20 3246500",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Meru Teaching and Referral Hospital",
  "address": "Meru Town, Meru County",
  "services": "Emergency Care, Surgery, Oncology, Pediatrics",
  "lat": 0.0463,
  "lon": 37.6559,
  "phone": "+254 64 31300",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Rift Valley Provincial General Hospital",
  "address": "Nakuru Town, Nakuru County",
  "services": "Emergency Care, Surgery, Maternity, Radiology",
  "lat": -0.2833,
  "lon": 36.0667,
  "phone": "+254 51 2217010",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ladnan Hospital",
  "address": "Pangani, Nairobi",
  "services": "Emergency Care, Surgery, Cardiology, Diagnostics",
  "lat": -1.2675,
  "lon": 36.8339,
  "phone": "+254 20 6760888",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mbagathi County Hospital",
  "address": "Kenyatta Market, Nairobi",
  "services": "Emergency Care, General Medicine, Maternity",
  "lat": -1.3090,
  "lon": 36.8118,
  "phone": "+254 20 2724714",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Francis Community Hospital",
  "address": "Kasarani, Nairobi",
  "services": "General Medicine, Surgery, Pediatrics, Maternity",
  "lat": -1.2245,
  "lon": 36.9085,
  "phone": "+254 20 3525353",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Nyamira County Referral Hospital",
  "address": "Nyamira Town, Nyamira County",
  "services": "Emergency Care, Surgery, Pediatrics, Obstetrics",
  "lat": -0.5667,
  "lon": 34.9333,
  "phone": "+254 58 514000",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Bungoma County Referral Hospital",
  "address": "Bungoma Town, Bungoma County",
  "services": "Emergency Care, Surgery, Maternity, Radiology",
  "lat": 0.5667,
  "lon": 34.5667,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Taita Taveta County Referral Hospital",
  "address": "Wundanyi, Taita Taveta County",
  "services": "Emergency Care, General Medicine, Surgery",
  "lat": -3.4000,
  "lon": 38.3667,
  "phone": "+254 43 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Lamu County Referral Hospital",
  "address": "Lamu Town, Lamu County",
  "services": "Emergency Care, Surgery, Pediatrics, Maternity",
  "lat": -2.2717,
  "lon": 40.9020,
  "phone": "+254 42 463000",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kisii Teaching and Referral Hospital",
  "address": "Kisii Town, Kisii County",
  "services": "Emergency Care, Surgery, Oncology, Pediatrics",
  "lat": -0.6773,
  "lon": 34.7796,
  "phone": "+254 58 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "AIC Litein Hospital",
  "address": "Litein, Kericho County",
  "services": "Surgery, Maternity, Pediatrics, General Medicine",
  "lat": -0.5833,
  "lon": 35.1833,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Luke’s Orthopaedic and Trauma Hospital",
  "address": "Eldoret, Uasin Gishu County",
  "services": "Orthopedics, Trauma Care, Surgery",
  "lat": 0.5143,
  "lon": 35.2698,
  "phone": "+254 53 2062000",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Pumwani Maternity Hospital",
  "address": "Eastleigh, Nairobi",
  "services": "Maternity, Gynecology, Neonatal Care",
  "lat": -1.2833,
  "lon": 36.8333,
  "phone": "+254 20 6763777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Sabatia Eye Hospital",
  "address": "Wodanga, Vihiga County",
  "services": "Eye Care, Surgery, Diagnostics",
  "lat": 0.0833,
  "lon": 34.7167,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Maua Methodist Hospital",
  "address": "Maua, Meru County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.2333,
  "lon": 37.9333,
  "phone": "+254 64 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Gatundu Level 5 Hospital",
  "address": "Gatundu, Kiambu County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -1.0167,
  "lon": 36.9167,
  "phone": "+254 67 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Nanyuki Teaching and Referral Hospital",
  "address": "Nanyuki, Laikipia County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": 0.0167,
  "lon": 37.0667,
  "phone": "+254 62 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Chogoria Mission Hospital",
  "address": "Chogoria, Tharaka-Nithi County",
  "services": "Surgery, Maternity, Pediatrics, Diagnostics",
  "lat": -0.2333,
  "lon": 37.6333,
  "phone": "+254 64 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kapsowar Mission Hospital",
  "address": "Kapsowar, Elgeyo-Marakwet County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.9833,
  "lon": 35.5667,
  "phone": "+254 53 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mombasa Hospital",
  "address": "Mama Ngina Drive, Mombasa",
  "services": "Emergency Care, Surgery, Cardiology",
  "lat": -4.0610,
  "lon": 39.6790,
  "phone": "+254 41 2312191",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Pandya Memorial Hospital",
  "address": "Digo Road, Mombasa",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -4.0500,
  "lon": 39.6667,
  "phone": "+254 41 2312233",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Avenue Hospital Kisumu",
  "address": "Milimani, Kisumu",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -0.0917,
  "lon": 34.7679,
  "phone": "+254 57 2021111",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ruaraka Uhai Neema Hospital",
  "address": "Ruaraka, Nairobi",
  "services": "General Medicine, Maternity, Surgery",
  "lat": -1.2500,
  "lon": 36.8667,
  "phone": "+254 20 2535216",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Joseph’s Mission Hospital",
  "address": "Kilgoris, Narok County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -1.0000,
  "lon": 34.8667,
  "phone": "+254 50 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ol Kalou County Referral Hospital",
  "address": "Ol Kalou, Nyandarua County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -0.2667,
  "lon": 36.3833,
  "phone": "+254 61 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Equity Afia Eldoret",
  "address": "Eldoret Town, Uasin Gishu County",
  "services": "General Medicine, Diagnostics, Outpatient Care",
  "lat": 0.5143,
  "lon": 35.2698,
  "phone": "+254 53 2063000",
  "emergency": "no",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kilimani Hospital",
  "address": "Kilimani, Nairobi",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -1.2833,
  "lon": 36.7833,
  "phone": "+254 20 2711414",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Bomet County Referral Hospital",
  "address": "Bomet Town, Bomet County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -0.7818,
  "lon": 35.3416,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Murang’a County Referral Hospital",
  "address": "Murang’a Town, Murang’a County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.7167,
  "lon": 37.1500,
  "phone": "+254 60 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Taveta Sub-County Hospital",
  "address": "Taveta, Taita Taveta County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -3.4000,
  "lon": 37.6833,
  "phone": "+254 43 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kitui County Referral Hospital",
  "address": "Kitui Town, Kitui County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -1.3667,
  "lon": 38.0167,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Barnet Memorial Hospital",
  "address": "Kabete, Kiambu County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -1.2333,
  "lon": 36.7333,
  "phone": "+254 20 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kendu Mission Hospital",
  "address": "Kendu Bay, Homa Bay County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.3667,
  "lon": 34.6500,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Iten County Referral Hospital",
  "address": "Iten, Elgeyo-Marakwet County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": 0.6703,
  "lon": 35.5081,
  "phone": "+254 53 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. John’s Hospital",
  "address": "Nyali, Mombasa",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -4.0333,
  "lon": 39.7000,
  "phone": "+254 41 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Maralal County Referral Hospital",
  "address": "Maralal, Samburu County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": 1.0968,
  "lon": 36.6980,
  "phone": "+254 65 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Othaya Level 5 Hospital",
  "address": "Othaya, Nyeri County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -0.5667,
  "lon": 36.9333,
  "phone": "+254 61 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kangundo Level 4 Hospital",
  "address": "Kangundo, Machakos County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -1.3000,
  "lon": 37.3333,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Masaba Hospital",
  "address": "Kuresoi, Nakuru County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -0.3500,
  "lon": 35.7000,
  "phone": "+254 51 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Cheptalal Sub-County Hospital",
  "address": "Cheptalal, Kericho County",
  "services": "General Medicine, Maternity, Surgery",
  "lat": -0.4000,
  "lon": 35.3167,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Lugulu Mission Hospital",
  "address": "Webuye, Bungoma County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.6167,
  "lon": 34.7667,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Nyabondo Mission Hospital",
  "address": "Nyabondo, Kisumu County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -0.3833,
  "lon": 34.9833,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Chuka County Referral Hospital",
  "address": "Chuka, Tharaka-Nithi County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.3167,
  "lon": 37.6500,
  "phone": "+254 64 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Hekima Hospital",
  "address": "Ngong, Kajiado County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -1.3667,
  "lon": 36.6667,
  "phone": "+254 20 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Karatina Sub-County Hospital",
  "address": "Karatina, Nyeri County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.4833,
  "lon": 37.1333,
  "phone": "+254 61 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Eldama Ravine Sub-County Hospital",
  "address": "Eldama Ravine, Baringo County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": 0.0500,
  "lon": 35.7167,
  "phone": "+254 51 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Theresa’s Mission Hospital",
  "address": "Kiirua, Meru County",
  "services": "General Medicine, Surgery, Maternity, Pediatrics",
  "lat": 0.1167,
  "lon": 37.6333,
  "phone": "+254 64 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Rift Valley Odyssey Hospital",
  "address": "Kapsabet, Nandi County",
  "services": "Emergency Care, Surgery, Diagnostics",
  "lat": 0.2039,
  "lon": 35.0917,
  "phone": "+254 53 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mukumu Hospital",
  "address": "Kakamega, Kakamega County",
  "services": "General Medicine, Maternity, Surgery",
  "lat": 0.2833,
  "lon": 34.7500,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mbale County Referral Hospital",
  "address": "Mbale, Vihiga County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": 0.0833,
  "lon": 34.7167,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Elizabeth Hospital",
  "address": "Mukurweini, Nyeri County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.5667,
  "lon": 37.0500,
  "phone": "+254 61 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kilimanjaro Hospital",
  "address": "Ongata Rongai, Kajiado County",
  "services": "Emergency Care, Surgery, Diagnostics",
  "lat": -1.4000,
  "lon": 36.7667,
  "phone": "+254 20 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Karatina Level 4 Hospital",
  "address": "Karatina, Nyeri County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -0.4833,
  "lon": 37.1333,
  "phone": "+254 61 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Tumutumu Hospital",
  "address": "Nyeri, Nyeri County",
  "services": "Surgery, Maternity, General Medicine",
  "lat": -0.4167,
  "lon": 37.0000,
  "phone": "+254 61 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Runyenjes Level 4 Hospital",
  "address": "Runyenjes, Embu County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.4000,
  "lon": 37.5667,
  "phone": "+254 68 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mutomo Mission Hospital",
  "address": "Mutomo, Kitui County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -1.8333,
  "lon": 38.2167,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kendu Adventist Hospital",
  "address": "Kendu Bay, Homa Bay County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": -0.3667,
  "lon": 34.6500,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Port Victoria Sub-County Hospital",
  "address": "Port Victoria, Busia County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.1000,
  "lon": 34.0333,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kapkatet County Hospital",
  "address": "Kapkatet, Kericho County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -0.4667,
  "lon": 35.2000,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Londiani Sub-County Hospital",
  "address": "Londiani, Kericho County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.1667,
  "lon": 35.5833,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Sigowet Sub-County Hospital",
  "address": "Sigowet, Kericho County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -0.3833,
  "lon": 35.3167,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Monica’s Hospital",
  "address": "Kisumu, Kisumu County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.1000,
  "lon": 34.7500,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Maseno Mission Hospital",
  "address": "Maseno, Kisumu County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -0.0167,
  "lon": 34.5833,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kaimosi Mission Hospital",
  "address": "Kaimosi, Vihiga County",
  "services": "Surgery, Maternity, General Medicine",
  "lat": 0.1333,
  "lon": 34.8500,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Bondo Sub-County Hospital",
  "address": "Bondo, Siaya County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -0.2333,
  "lon": 34.2667,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ukwala Sub-County Hospital",
  "address": "Ukwala, Siaya County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.1833,
  "lon": 34.2167,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Madiany Sub-County Hospital",
  "address": "Madiany, Siaya County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -0.2833,
  "lon": 34.3167,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Lukenya Hospital",
  "address": "Athi River, Machakos County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -1.4500,
  "lon": 36.9833,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Patrick’s Mission Hospital",
  "address": "Wote, Makueni County",
  "services": "Surgery, Pediatrics, General Medicine",
  "lat": -1.7833,
  "lon": 37.6333,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Rachuonyo Sub-County Hospital",
  "address": "Oyugis, Homa Bay County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.5000,
  "lon": 34.7333,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Matuu Level 4 Hospital",
  "address": "Matuu, Machakos County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -1.1500,
  "lon": 37.5333,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Tigoni Level 4 Hospital",
  "address": "Tigoni, Kiambu County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -1.1333,
  "lon": 36.6667,
  "phone": "+254 66 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kendu Bay Sub-County Hospital",
  "address": "Kendu Bay, Homa Bay County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.3667,
  "lon": 34.6500,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Githunguri Level 4 Hospital",
  "address": "Githunguri, Kiambu County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": -1.0500,
  "lon": 36.7833,
  "phone": "+254 66 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Makindu Sub-County Hospital",
  "address": "Makindu, Makueni County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -2.2833,
  "lon": 37.8167,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kyuso Sub-County Hospital",
  "address": "Kyuso, Kitui County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.5667,
  "lon": 38.2167,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mwingi Level 4 Hospital",
  "address": "Mwingi, Kitui County",
  "services": "Emergency Care, Surgery, Diagnostics",
  "lat": -0.9333,
  "lon": 38.0667,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Sultan Hamud Sub-County Hospital",
  "address": "Sultan Hamud, Makueni County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -2.0167,
  "lon": 37.3667,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Limuru Level 4 Hospital",
  "address": "Limuru, Kiambu County",
  "services": "Surgery, Maternity, General Medicine",
  "lat": -1.1000,
  "lon": 36.6500,
  "phone": "+254 66 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kibwezi Sub-County Hospital",
  "address": "Kibwezi, Makueni County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -2.4167,
  "lon": 37.9667,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ndhiwa Sub-County Hospital",
  "address": "Ndhiwa, Homa Bay County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -0.7333,
  "lon": 34.3667,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kikuyu Mission Hospital",
  "address": "Kikuyu, Kiambu County",
  "services": "Surgery, Eye Care, General Medicine",
  "lat": -1.2456,
  "lon": 36.6647,
  "phone": "+254 20 2040760",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Taveta Sub-County Hospital",
  "address": "Taveta, Taita Taveta County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -3.4000,
  "lon": 37.6833,
  "phone": "+254 43 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Rumuruti Sub-County Hospital",
  "address": "Rumuruti, Laikipia County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": 0.2667,
  "lon": 36.5333,
  "phone": "+254 62 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kathonzweni Sub-County Hospital",
  "address": "Kathonzweni, Makueni County",
  "services": "Surgery, Maternity, Pediatrics",
  "lat": -1.9167,
  "lon": 37.7333,
  "phone": "+254 44 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Laisamis Sub-County Hospital",
  "address": "Laisamis, Marsabit County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 1.5833,
  "lon": 37.8167,
  "phone": "+254 69 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Bura Sub-County Hospital",
  "address": "Bura, Taita Taveta County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -3.4667,
  "lon": 38.3167,
  "phone": "+254 43 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Moyale Sub-County Hospital",
  "address": "Moyale, Marsabit County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 3.5167,
  "lon": 39.0500,
  "phone": "+254 69 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "St. Mary’s Hospital Mumias",
  "address": "Mumias, Kakamega County",
  "services": "Surgery, Pediatrics, General Medicine",
  "lat": 0.3333,
  "lon": 34.4833,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Siaya District Hospital",
  "address": "Siaya Town, Siaya County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": 0.0667,
  "lon": 34.2833,
  "phone": "+254 57 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kericho District Hospital",
  "address": "Kericho Town, Kericho County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -0.3667,
  "lon": 35.2833,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kapsabet District Hospital",
  "address": "Kapsabet Town, Nandi County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": 0.2000,
  "lon": 35.1000,
  "phone": "+254 53 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Bomet District Hospital",
  "address": "Bomet Town, Bomet County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.7833,
  "lon": 35.3333,
  "phone": "+254 52 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Narok District Hospital",
  "address": "Narok Town, Narok County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": -1.0833,
  "lon": 35.8667,
  "phone": "+254 50 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kilgoris Sub-County Hospital",
  "address": "Kilgoris, Narok County",
  "services": "Emergency Care, Surgery, Pediatrics",
  "lat": -1.0000,
  "lon": 34.8833,
  "phone": "+254 50 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Trans Mara District Hospital",
  "address": "Lolgorian, Narok County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -1.3167,
  "lon": 34.8000,
  "phone": "+254 50 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ololulunga Sub-County Hospital",
  "address": "Ololulunga, Narok County",
  "services": "Surgery, Pediatrics, General Medicine",
  "lat": -1.1333,
  "lon": 35.6500,
  "phone": "+254 50 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Homa Bay District Hospital",
  "address": "Homa Bay Town, Homa Bay County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.5333,
  "lon": 34.4500,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Mbita Sub-County Hospital",
  "address": "Mbita, Homa Bay County",
  "services": "General Medicine, Surgery, Diagnostics",
  "lat": -0.4167,
  "lon": 34.2000,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Suba Sub-County Hospital",
  "address": "Sindo, Homa Bay County",
  "services": "Surgery, Maternity, Pediatrics",
  "lat": -0.5333,
  "lon": 34.1500,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kisii District Hospital",
  "address": "Kisii Town, Kisii County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": -0.6667,
  "lon": 34.7667,
  "phone": "+254 58 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Ogembo Sub-County Hospital",
  "address": "Ogembo, Kisii County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.8167,
  "lon": 34.7333,
  "phone": "+254 58 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kenyenya Sub-County Hospital",
  "address": "Kenyenya, Kisii County",
  "services": "Surgery, Pediatrics, Diagnostics",
  "lat": -0.8833,
  "lon": 34.7333,
  "phone": "+254 58 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Marani Sub-County Hospital",
  "address": "Marani, Kisii County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.5833,
  "lon": 34.8000,
  "phone": "+254 58 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Nyamache Sub-County Hospital",
  "address": "Nyamache, Kisii County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -0.8500,
  "lon": 34.8333,
  "phone": "+254 58 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Migori District Hospital",
  "address": "Migori Town, Migori County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": -1.0667,
  "lon": 34.4667,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Rongo Sub-County Hospital",
  "address": "Rongo, Migori County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": -0.7500,
  "lon": 34.6000,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Awendo Sub-County Hospital",
  "address": "Awendo, Migori County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": -0.9000,
  "lon": 34.5333,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kehancha Sub-County Hospital",
  "address": "Kehancha, Migori County",
  "services": "Surgery, Pediatrics, Diagnostics",
  "lat": -1.2000,
  "lon": 34.4833,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Uriri Sub-County Hospital",
  "address": "Uriri, Migori County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": -0.9500,
  "lon": 34.4833,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Nyatike Sub-County Hospital",
  "address": "Nyatike, Migori County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": -1.1333,
  "lon": 34.3333,
  "phone": "+254 59 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Busia District Hospital",
  "address": "Busia Town, Busia County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": 0.4667,
  "lon": 34.1167,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Malaba Sub-County Hospital",
  "address": "Malaba, Busia County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": 0.6333,
  "lon": 34.2833,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Funyula Sub-County Hospital",
  "address": "Funyula, Busia County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.2833,
  "lon": 34.0667,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Nambale Sub-County Hospital",
  "address": "Nambale, Busia County",
  "services": "Surgery, Pediatrics, Diagnostics",
  "lat": 0.4333,
  "lon": 34.2500,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Butula Sub-County Hospital",
  "address": "Butula, Busia County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": 0.3333,
  "lon": 34.3333,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Bungoma District Hospital",
  "address": "Bungoma Town, Bungoma County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": 0.5667,
  "lon": 34.5667,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Webuye Sub-County Hospital",
  "address": "Webuye, Bungoma County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": 0.6167,
  "lon": 34.7667,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kimilili Sub-County Hospital",
  "address": "Kimilili, Bungoma County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": 0.7833,
  "lon": 34.7167,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Chwele Sub-County Hospital",
  "address": "Chwele, Bungoma County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.7000,
  "lon": 34.5833,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Sirisia Sub-County Hospital",
  "address": "Sirisia, Bungoma County",
  "services": "Surgery, Pediatrics, Diagnostics",
  "lat": 0.7333,
  "lon": 34.5000,
  "phone": "+254 55 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kakamega District Hospital",
  "address": "Kakamega Town, Kakamega County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": 0.2833,
  "lon": 34.7500,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Butere Sub-County Hospital",
  "address": "Butere, Kakamega County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": 0.2167,
  "lon": 34.5000,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Matungu Sub-County Hospital",
  "address": "Matungu, Kakamega County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": 0.4167,
  "lon": 34.4833,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Likuyani Sub-County Hospital",
  "address": "Likuyani, Kakamega County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": 0.6667,
  "lon": 34.9167,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Malava Sub-County Hospital",
  "address": "Malava, Kakamega County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 0.4500,
  "lon": 34.8500,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Vihiga District Hospital",
  "address": "Vihiga Town, Vihiga County",
  "services": "Surgery, Pediatrics, Diagnostics",
  "lat": 0.0500,
  "lon": 34.7333,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Hamisi Sub-County Hospital",
  "address": "Hamisi, Vihiga County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": 0.0833,
  "lon": 34.8333,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Luanda Sub-County Hospital",
  "address": "Luanda, Vihiga County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": 0.0167,
  "lon": 34.6167,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Emuhaya Sub-County Hospital",
  "address": "Emuhaya, Vihiga County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": 0.0500,
  "lon": 34.6333,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Sabatia Sub-County Hospital",
  "address": "Sabatia, Vihiga County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": 0.1167,
  "lon": 34.7167,
  "phone": "+254 56 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Trans Nzoia District Hospital",
  "address": "Kitale Town, Trans Nzoia County",
  "services": "General Medicine, Surgery, Maternity",
  "lat": 1.0167,
  "lon": 35.0000,
  "phone": "+254 54 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kiminini Sub-County Hospital",
  "address": "Kiminini, Trans Nzoia County",
  "services": "Surgery, Pediatrics, Diagnostics",
  "lat": 0.8833,
  "lon": 34.9167,
  "phone": "+254 54 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Saboti Sub-County Hospital",
  "address": "Saboti, Trans Nzoia County",
  "services": "Emergency Care, Surgery, Maternity",
  "lat": 0.9333,
  "lon": 34.8333,
  "phone": "+254 54 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Cherangany Sub-County Hospital",
  "address": "Cherangany, Trans Nzoia County",
  "services": "General Medicine, Surgery, Pediatrics",
  "lat": 1.0500,
  "lon": 35.1333,
  "phone": "+254 54 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Kwanza Sub-County Hospital",
  "address": "Kwanza, Trans Nzoia County",
  "services": "Surgery, Maternity, Diagnostics",
  "lat": 1.1833,
  "lon": 34.9667,
  "phone": "+254 54 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
{
  "name": "Endebess Sub-County Hospital",
  "address": "Endebess, Trans Nzoia County",
  "services": "Emergency Care, Surgery, General Medicine",
  "lat": 1.0667,
  "lon": 34.8500,
  "phone": "+254 54 30777",
  "emergency": "yes",
  "wheelchair": "yes",
  "distance": 0.0
},
    {
      "name": "Jaramogi Oginga Odinga Teaching and Referral Hospital",
      "address": "Kenyatta Highway, Kisumu",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Oncology",
      "lat": -0.0887,
      "lon": 34.7716,
      "phone": "+254 57 2023000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Mediheal Hospital Nairobi",
      "address": "Parklands Road, Westlands",
      "services": "Emergency Care, Surgery, Pediatrics, Cardiology, Neurology",
      "lat": -1.2632,
      "lon": 36.8172,
      "phone": "+254 20 2215577",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Karen Hospital",
      "address": "Lang'ata Road, Karen",
      "services": "Emergency Care, Cardiology, Neurology, Pediatrics, Obstetrics",
      "lat": -1.3198,
      "lon": 36.7218,
      "phone": "+254 20 3560000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Coptic Hospital",
      "address": "Ngong Road, Nairobi",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Dialysis",
      "lat": -1.2980,
      "lon": 36.7977,
      "phone": "+254 20 3882601",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Mama Lucy Kibaki Hospital",
      "address": "Umoja-Kayole Road, Nairobi",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, HIV Care",
      "lat": -1.2794,
      "lon": 36.8959,
      "phone": "+254 20 2624212",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Eldoret Hospital",
      "address": "Ronald Ngala Street, Eldoret",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Orthopedics",
      "lat": 0.5143,
      "lon": 35.2695,
      "phone": "+254 53 2061000",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kiambu Level 5 Hospital",
      "address": "Kiambu Road, Kiambu",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": -1.1722,
      "lon": 36.8302,
      "phone": "+254 67 22095",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Narok County Referral Hospital",
      "address": "Narok-Mai Mahiu Road, Narok",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Gynecology",
      "lat": -1.0965,
      "lon": 35.8712,
      "phone": "+254 50 22038",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Isiolo County Referral Hospital",
      "address": "Isiolo-Marsabit Road, Isiolo",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": 0.3517,
      "lon": 37.5822,
      "phone": "+254 64 52054",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Migori County Referral Hospital",
      "address": "Migori-Isebania Road, Migori",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Gynecology",
      "lat": -1.0631,
      "lon": 34.4731,
      "phone": "+254 59 22123",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Tenwek Mission Hospital",
      "address": "Bomet-Kaplong Road, Bomet",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Cardiology",
      "lat": -0.7014,
      "lon": 35.3472,
      "phone": "+254 52 20066",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kapenguria County Referral Hospital",
      "address": "Kitale-Lodwar Road, Kapenguria",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": 1.2333,
      "lon": 35.1167,
      "phone": "+254 54 62001",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Wajir County Referral Hospital",
      "address": "Hospital Road, Wajir",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Nutrition",
      "lat": 1.7469,
      "lon": 40.0573,
      "phone": "+254 46 421234",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Makueni County Referral Hospital",
      "address": "Wote Town, Makueni",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": -1.7908,
      "lon": 37.6288,
      "phone": "+254 44 21234",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Marsabit County Referral Hospital",
      "address": "Marsabit-Moyale Road, Marsabit",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": 2.3352,
      "lon": 37.9965,
      "phone": "+254 69 210123",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Mandera County Referral Hospital",
      "address": "Hospital Road, Mandera",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Nutrition",
      "lat": 3.9366,
      "lon": 41.8513,
      "phone": "+254 46 210123",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kapsabet County Referral Hospital",
      "address": "Eldoret-Kisumu Road, Kapsabet",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": 0.2042,
      "lon": 35.1047,
      "phone": "+254 53 52123",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Kajiado County Referral Hospital",
      "address": "Kajiado-Namanga Road, Kajiado",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": -1.8528,
      "lon": 36.7783,
      "phone": "+254 45 21234",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
    {
      "name": "Turkana County Referral Hospital",
      "address": "Lodwar-Kitale Road, Lodwar",
      "services": "Emergency Care, Surgery, Pediatrics, Obstetrics, Radiology",
      "lat": 3.1167,
      "lon": 35.6000,
      "phone": "+254 54 21234",
      "emergency": "yes",
      "wheelchair": "yes",
      "distance": 0.0,
    },
  ];

 @override
void initState() {
  super.initState();
  mapController = MapController();
  _initializeMap();
  _startLocationUpdates();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _searchNearbyHospitals(); // Ensure async fetch happens
    if (mounted) {
      setState(() {
        filteredHospitals = List.from(nearbyHospitals); // Sync after fetch
      });
    }
  });
}

  @override
  void dispose() {
    searchController.dispose();
    dragController.dispose();
    super.dispose();
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
          heading = position.heading;
          _updateNearbyHospitals();
          if (isNavigating) {
            _updateNavigationProgress();
            _checkOffRouteAndRecenter();
            _updateRouteLine();
            _centerMapOnNavigation();
          }
        });
      }
    });
  }

  void _updateNearbyHospitals() {
  if (currentPosition == null) return;

  if (nearbyHospitals.isEmpty) {
    nearbyHospitals = allHospitals.map((hospital) {
      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        double.parse(hospital['lat'].toString()),
        double.parse(hospital['lon'].toString()),
      );
      return {...hospital, 'distance': distance};
    }).where((hospital) => hospital['distance'] <= 10000).toList();

    nearbyHospitals.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
  }
  filteredHospitals = List.from(nearbyHospitals); // Sync with current data
  _filterHospitals(searchController.text); // Apply filter
}

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    await _getCurrentLocation();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      _showDefaultLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
          heading = position.heading;
          isLoading = false;
          _updateNearbyHospitals();
        });
        mapController.move(currentPosition!, 14); // Increased zoom for better detail
        await _searchNearbyHospitals();
      }
    } catch (e) {
      _showDefaultLocation();
    }
  }

  void _showDefaultLocation() {
    if (mounted) {
      setState(() {
        currentPosition = defaultLocation;
        isLoading = false;
        _updateNearbyHospitals();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Using default location: Nairobi')),
      );
    }
  }

 Future<void> _searchNearbyHospitals() async {
  if (currentPosition == null) return;

  setState(() => isLoading = true);

  try {
    final apiHospitals = await _fetchHospitalsFromApi();
    // Combine without duplicating, preserving existing hospitals
    final combinedHospitals = [
      ...nearbyHospitals.where((h) => allHospitals.any((local) => local['name'] == h['name'])), // Keep static ones
      ...apiHospitals.where((apiHospital) => !nearbyHospitals.any((local) =>
          local['name'] == apiHospital['name'] &&
          local['lat'].toString() == apiHospital['lat'].toString() &&
          local['lon'].toString() == apiHospital['lon'].toString()))
    ];

    combinedHospitals.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    if (mounted) {
      setState(() {
        nearbyHospitals = combinedHospitals; // Update with combined list
        filteredHospitals = List.from(combinedHospitals); // Sync filtered list
        isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospitals: $e')),
      );
    }
  }
}

  Future<List<Map<String, dynamic>>> _fetchHospitalsFromApi() async {
    if (currentPosition == null) return [];

    try {
      final overpassQuery = '''
        [out:json];
        (
          node["amenity"="hospital"](around:10000,${currentPosition!.latitude},${currentPosition!.longitude});
          node["amenity"="clinic"](around:10000,${currentPosition!.latitude},${currentPosition!.longitude});
        );
        out body;
      ''';
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['elements'] as List? ?? [];

        final hospitalDetails = <Map<String, dynamic>>[];
        for (var hospital in results) {
          final lat = hospital['lat'] as double?;
          final lon = hospital['lon'] as double?;
          final tags = hospital['tags'] as Map<String, dynamic>? ?? {};

          if (lat == null || lon == null) continue;

          final distance = Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            lat,
            lon,
          );

          if (distance > 10000) continue;

          final name = tags['name'] ?? 'Unnamed Facility';
          final baseDetails = {
            'name': name,
            'lat': lat,
            'lon': lon,
            'address': tags['addr:full'] ?? tags['street'] ?? 'Address not available',
            'phone': tags['phone'] ?? 'Not available',
            'emergency': tags['emergency'] == 'yes' ? 'yes' : 'no',
            'wheelchair': tags['wheelchair'] == 'yes' ? 'yes' : 'no',
            'services': tags['healthcare'] ?? 'General Medical Services',
            'distance': distance,
          };

          final enrichedData = await _fetchHospitalDetailsFromGooglePlaces(name, lat, lon);
          hospitalDetails.add({
            ...baseDetails,
            'phone': enrichedData['phone'] ?? baseDetails['phone'],
            'address': enrichedData['address'] ?? baseDetails['address'],
            'services': enrichedData['services'] ?? baseDetails['services'],
            'emergency': enrichedData['emergency'] ?? baseDetails['emergency'],
            'wheelchair': enrichedData['wheelchair'] ?? baseDetails['wheelchair'],
          });
        }

        return hospitalDetails;
      } else {
        throw Exception('Overpass API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('API Fetch Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchHospitalDetailsFromGooglePlaces(String name, double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
          'location': '$lat,$lon',
          'radius': '500',
          'keyword': name,
          'type': 'hospital',
          'key': ApiConfig.rapidApiKey, // Ensure this is set in api_config.dart
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final place = results[0];
          final detailsResponse = await http.get(
            Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
              'place_id': place['place_id'],
              'fields': 'name,formatted_phone_number,formatted_address,types,wheelchair_accessible_entrance',
              'key': ApiConfig.rapidApiKey,
            }),
          );

          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            final result = detailsData['result'] ?? {};
            final types = (result['types'] as List? ?? []).cast<String>();
            final services = types
                .where((type) => !['point_of_interest', 'establishment', 'hospital'].contains(type))
                .map((type) => type.replaceAll('_', ' ').capitalize())
                .take(5)
                .join(', ');

            return {
              'address': result['formatted_address'] ?? place['vicinity'] ?? 'Address not available',
              'phone': result['formatted_phone_number'] ?? 'Not available',
              'emergency': types.contains('emergency') ? 'yes' : 'no',
              'wheelchair': result['wheelchair_accessible_entrance'] == true ? 'yes' : 'no',
              'services': services.isNotEmpty ? services : 'General Medical Services',
            };
          }
        }
      }
      return {
        'address': 'Address not available',
        'phone': 'Not available',
        'emergency': 'no',
        'wheelchair': 'no',
        'services': 'General Medical Services',
      };
    } catch (e) {
      if (kDebugMode) print('Google Places Error: $e');
      return {
        'address': 'Address not available',
        'phone': 'Not available',
        'emergency': 'no',
        'wheelchair': 'no',
        'services': 'General Medical Services',
      };
    }
  }

  Future<Map<String, dynamic>> _getRouteNavigation(LatLng start, LatLng end) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://api.openrouteservice.org/v2/directions/$selectedTransportMode'
        '?api_key=${ApiConfig.openRouteKey}'
        '&start=${start.longitude},${start.latitude}'
        '&end=${end.longitude},${end.latitude}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      if (features.isEmpty) {
        throw Exception('No route found');
      }

      final route = features[0];
      final geometry = route['geometry'];
      final properties = route['properties'];
      final segments = properties['segments'][0];
      final steps = segments['steps'] as List;
      final coordinates = geometry['coordinates'] as List;

      final routeCoords = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
      final formattedSteps = steps.map((step) {
        final wayPoints = step['way_points'] as List;
        final endPoint = coordinates[wayPoints[1]];
        return {
          'instruction': step['instruction'] ?? 'Continue',
          'distance': (step['distance'] as num?)?.toDouble() ?? 0.0,
          'duration': (step['duration'] as num?)?.toDouble() ?? 0.0,
          'end_location': {'lat': endPoint[1], 'lng': endPoint[0]},
          'notified': false,
        };
      }).toList();

      final distance = (segments['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (segments['duration'] as num?)?.toDouble() ?? 0.0;

      return {
        'distance': distance.isFinite ? distance : 0.0,
        'duration': duration.isFinite ? duration : 0.0,
        'steps': formattedSteps,
        'routeCoordinates': routeCoords,
      };
    } else {
      throw Exception('Route fetch failed: ${response.statusCode}');
    }
  } catch (e) {
    if (kDebugMode) print('Route Error: $e');
    return {'distance': 0.0, 'duration': 0.0, 'steps': [], 'routeCoordinates': []};
  }
}

  void _updateNavigationProgress() {
  if (navigationSteps.isEmpty || currentPosition == null) return;

  final currentStep = navigationSteps[currentNavigationStep];
  final stepLocation = LatLng(currentStep['end_location']['lat'], currentStep['end_location']['lng']);
  final distanceToStep = Geolocator.distanceBetween(
    currentPosition!.latitude,
    currentPosition!.longitude,
    stepLocation.latitude,
    stepLocation.longitude,
  );

  double traveled = 0.0;
  double remainingDuration = 0.0;
  for (int i = 0; i < currentNavigationStep; i++) {
    traveled += navigationSteps[i]['distance'] as double;
  }
  traveled += (navigationSteps[currentNavigationStep]['distance'] as double) - distanceToStep;
  distanceTraveled = math.min(traveled, totalDistance);

  // Calculate remaining duration based on steps
  for (int i = currentNavigationStep; i < navigationSteps.length; i++) {
    if (i == currentNavigationStep) {
      remainingDuration += (distanceToStep / navigationSteps[i]['distance']) * navigationSteps[i]['duration'];
    } else {
      remainingDuration += navigationSteps[i]['duration'] as double;
    }
  }

  if (distanceToStep < 100 && !currentStep['notified']) {
    setState(() => currentStep['notified'] = true);
    _showUpcomingTurnNotification(currentStep);
  }

  if (distanceToStep < 20 && currentNavigationStep < navigationSteps.length - 1) {
    setState(() => currentNavigationStep++);
    _showNextNavigationStep();
  }

  // Update state with remaining duration
  setState(() {
    this.remainingDuration = remainingDuration;
  });
}

  void _checkOffRouteAndRecenter() async {
    if (currentPosition == null || fullRouteCoordinates.isEmpty) return;

    double minDistance = double.infinity;
    for (var coord in fullRouteCoordinates) {
      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        coord.latitude,
        coord.longitude,
      );
      minDistance = math.min(minDistance, distance);
    }

    if (minDistance > 50 && selectedHospitalIndex != null) {
      final hospital = filteredHospitals[selectedHospitalIndex!];
      final hospitalLocation = LatLng(hospital['lat'], hospital['lon']);
      final navigationDetails = await _getRouteNavigation(currentPosition!, hospitalLocation);

      setState(() {
        navigationSteps = List<Map<String, dynamic>>.from(navigationDetails['steps']);
        fullRouteCoordinates = List<LatLng>.from(navigationDetails['routeCoordinates']);
        totalDistance = navigationDetails['distance'] as double;
        currentNavigationStep = 0;
        distanceTraveled = 0.0;
        _updateRouteLine();
      });
      if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Route recalculated')),
  );
}
    }
  }

  void _showUpcomingTurnNotification(Map<String, dynamic> step) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Next: ${step['instruction']} in ${formatDistance(step['distance'])}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showNextNavigationStep() {
    if (currentNavigationStep < navigationSteps.length) {
      final step = navigationSteps[currentNavigationStep];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${step['instruction']} (${formatDistance(step['distance'])})',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

 void _startNavigation(Map<String, dynamic> hospital) async {
  if (currentPosition == null) return;

  final hospitalLocation = LatLng(hospital['lat'], hospital['lon']);
  setState(() {
    isLoading = true;
    isNavigating = true;
    isSearchBarVisible = false;
    isHospitalListVisible = false;
    selectedHospitalIndex = filteredHospitals.indexOf(hospital);
    dragController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  final navigationDetails = await _getRouteNavigation(currentPosition!, hospitalLocation);
  if (mounted) {
    if (navigationDetails['distance'] == 0 || navigationDetails['routeCoordinates'].isEmpty) {
      setState(() {
        isLoading = false;
        isNavigating = false;
        isSearchBarVisible = true;
        isHospitalListVisible = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start navigation: No valid route found')),
      );
      return;
    }

    setState(() {
      navigationSteps = List<Map<String, dynamic>>.from(navigationDetails['steps']);
      fullRouteCoordinates = List<LatLng>.from(navigationDetails['routeCoordinates']);
      totalDistance = (navigationDetails['distance'] as num).toDouble();
      currentNavigationStep = 0;
      distanceTraveled = 0.0;
      _updateRouteLine();
      isLoading = false;
    });
    _showNextNavigationStep();
    _centerMapOnNavigation();
  }
}

  void _centerMapOnNavigation() {
    if (currentPosition == null || navigationSteps.isEmpty) return;

    final currentStep = navigationSteps[currentNavigationStep];
    final nextStepLocation = LatLng(currentStep['end_location']['lat'], currentStep['end_location']['lng']);
    final bounds = LatLngBounds.fromPoints([currentPosition!, nextStepLocation]);
    mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _stopNavigation() {
    setState(() {
      isNavigating = false;
      navigationLines.clear();
      navigationSteps.clear();
      fullRouteCoordinates.clear();
      currentNavigationStep = 0;
      distanceTraveled = 0.0;
      totalDistance = 0.0;
      isSearchBarVisible = true;
      isHospitalListVisible = true;
    });
  }

  void _updateRouteLine() {
    if (currentPosition == null || fullRouteCoordinates.isEmpty) return;

    int closestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < fullRouteCoordinates.length; i++) {
      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        fullRouteCoordinates[i].latitude,
        fullRouteCoordinates[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    setState(() {
      navigationLines = [
        Polyline(
          points: fullRouteCoordinates.sublist(closestIndex),
          strokeWidth: 6.0,
          color: Colors.blueAccent.withValues(alpha:0.8),
        ),
      ];
    });
  }

  void _filterHospitals(String query) {
  setState(() {
    if (query.isEmpty) {
      filteredHospitals = List.from(nearbyHospitals);
    } else {
      filteredHospitals = nearbyHospitals.where((hospital) {
        final name = hospital['name'].toString().toLowerCase();
        final address = hospital['address'].toString().toLowerCase();
        final services = hospital['services'].toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || address.contains(q) || services.contains(q);
      }).toList();
    }
    filteredHospitals.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
  });
}

  void _onHospitalSelected(int index) async {
    final hospital = filteredHospitals[index];
    final hospitalLocation = LatLng(hospital['lat'], hospital['lon']);

    setState(() => isLoading = true);
    final navigationDetails = await _getRouteNavigation(currentPosition!, hospitalLocation);

    if (mounted) {
      setState(() {
        selectedHospitalIndex = index;
        navigationLines = [
          Polyline(
            points: navigationDetails['routeCoordinates'],
            color: Colors.blueAccent,
            strokeWidth: 6.0,
          ),
        ];
        isLoading = false;
      });
      _showNavigationDetails(hospital, navigationDetails);
    }
  }

  void _showNavigationDetails(Map<String, dynamic> hospital, Map<String, dynamic> navigationDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To: ${hospital['name']}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance: ${formatDistance(navigationDetails['distance'])}', style: const TextStyle(fontSize: 16)),
                    Text('ETA: ${formatDuration(navigationDetails['duration'])}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    Navigator.pop(context);
                    _startNavigation(hospital);
                  },
                  child: const Text('Start', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('Address: ${hospital['address']}'),
            Text('Phone: ${hospital['phone']}'),
            Text('Emergency: ${hospital['emergency']}'),
            Text('Wheelchair: ${hospital['wheelchair']}'),
            Text('Services: ${hospital['services']}'),
          ],
        ),
      ),
    );
  }

  void _showHospitalDetails(Map<String, dynamic> hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital['name'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            Text('Address: ${hospital['address']}'),
            Row(
              children: [
                Text('Phone: ${hospital['phone']}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.teal),
                  onPressed: () => _launchPhone(hospital['phone']),
                ),
              ],
            ),
            Text('Emergency: ${hospital['emergency']}'),
            Text('Wheelchair: ${hospital['wheelchair']}'),
            Text('Services: ${hospital['services']}'),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _onHospitalSelected(filteredHospitals.indexOf(hospital)),
              child: const Text('Navigate', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not call $phoneNumber')),
    );
  }
}
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('HospyNav', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: Colors.teal,
      elevation: 0,
      actions: [
        if (isNavigating)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _stopNavigation,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.directions, color: Colors.white),
          onSelected: (mode) {
            setState(() {
              selectedTransportMode = mode;
              if (isNavigating && selectedHospitalIndex != null) {
                _startNavigation(filteredHospitals[selectedHospitalIndex!]);
              }
            });
          },
          itemBuilder: (context) => transportModes
              .map((mode) => PopupMenuItem<String>(
                    value: mode['id']!,
                    child: Row(
                      children: [
                        Icon(
                          mode['id'] == 'driving-car'
                              ? Icons.directions_car
                              : mode['id'] == 'cycling-regular'
                                  ? Icons.directions_bike
                                  : Icons.directions_walk,
                          color: selectedTransportMode == mode['id'] ? Colors.teal : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Text(mode['name']!, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: const Text('About HospyNav', style: TextStyle(color: Colors.teal)),
                content: const Text(
                  'Find and navigate to nearby hospitals within 10km with real-time directions and detailed information.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('OK', style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    body: Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition ?? defaultLocation,
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            if (currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: currentPosition!,
                    child: Transform.rotate(
                      angle: heading != null ? (heading! * math.pi / 180) : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Colors.teal, Colors.teal.withValues(alpha:0.5)]),
                          boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha:0.3), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: filteredHospitals.map((hospital) {
                return Marker(
                  width: 40,
                  height: 40,
                  point: LatLng(hospital['lat'], hospital['lon']),
                  child: GestureDetector(
                    onTap: () => _showHospitalDetails(hospital),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha:0.8),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha:0.3), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
            PolylineLayer(polylines: navigationLines),
          ],
        ),
        if (isSearchBarVisible)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.2), blurRadius: 10, spreadRadius: 2)],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search hospitals...',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.teal),
                    onPressed: () {
                      searchController.clear();
                      _filterHospitals('');
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: _filterHospitals,
              ),
            ),
          ),
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const CircularProgressIndicator(color: Colors.teal),
            ),
          ),
        if (isHospitalListVisible)
  DraggableScrollableSheet(
    initialChildSize: 0.5, // Keep at 0.5 (50% of screen height)
    minChildSize: 0.1,
    maxChildSize: 0.9,
    controller: dragController,
    builder: (context, scrollController) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Fixed header for "Hospitals Nearby" and "Refresh"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.2), blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 3,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hospitals Nearby (${filteredHospitals.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      TextButton(
                        onPressed: _searchNearbyHospitals,
                        child: const Text('Refresh', style: TextStyle(color: Colors.teal, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable hospital list
            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (filteredHospitals.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No hospitals within 10km', style: TextStyle(color: Colors.grey)),
                            ),
                          );
                        }
                        final hospital = filteredHospitals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Text(
                              hospital['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital['address'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  formatDistance(hospital['distance']),
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info, color: Colors.teal, size: 18),
                                  onPressed: () => _showHospitalDetails(hospital),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.directions, color: Colors.teal, size: 18),
                                  onPressed: () => _onHospitalSelected(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredHospitals.isEmpty ? 1 : filteredHospitals.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
        if (isNavigating && currentPosition != null)
  Positioned(
    top: 10,
    left: 10,
    right: 10,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal, Colors.tealAccent.withValues(alpha:0.8)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Navigation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining: ${formatDistance(totalDistance - distanceTraveled)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'ETA: ${totalDistance > 0 && navigationSteps.isNotEmpty ? formatDuration(((totalDistance - distanceTraveled) / totalDistance * navigationSteps.fold(0, (s, e) => s + (e['duration'] as num))).round()) : 'N/A'}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: totalDistance > 0 ? (distanceTraveled / totalDistance).clamp(0.0, 1.0) : 0.0,
            backgroundColor: Colors.white.withValues(alpha:0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ],
      ),
    ),
  ),
      ],
    ),
  );
}
}