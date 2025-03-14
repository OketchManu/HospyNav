import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  EmergencyContactsScreenState createState() => EmergencyContactsScreenState();
}

class EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<Map<String, String>> emergencyContacts = [
    // Emergency Services
    {"name": "National Police Emergency", "number": "999"},
    {"name": "Ambulance Services", "number": "112"},
    {"name": "Kenya Red Cross", "number": "0700 395 395"},
    {"name": "St John Ambulance", "number": "0721 225 285"},
    {"name": "Fire Brigade", "number": "020 222181"},
    {"name": "Flying Doctors", "number": "020 315454"},
    
    // Fire stations
    {"name": "Baringo County Fire Brigade", "number": "0705719999"},
    {"name": "Bomet County Fire Brigade", "number": "0746036036"},
    {"name": "Bungoma County Fire Brigade", "number": "0799001100 / 0799002200"},
    {"name": "Embu County Fire Brigade", "number": "0721304448"},
    {"name": "Garissa County Fire Brigade", "number": "0774771910 / 0779771912"},
    {"name": "Isiolo Fire Brigade", "number": "0722111178"},
    {"name": "Kajiado Loitokitok Sub County Fire Brigade", "number": "0712932055"},
    {"name": "Kakamega County Fire Brigade", "number": "0562031155"},
    {"name": "Kiambu Fire & Rescue", "number": "0672222085 / 0724757507 / 0771755440"},
    {"name": "Kilifi County Fire Brigade", "number": "0730659555 / 1535"},
    {"name": "Kirinyaga County Fire Brigade", "number": "0711234567"},
    {"name": "Kisii County Fire Brigade", "number": "0707755577"},
    {"name": "Kisumu County Fire Brigade", "number": "0800720575 / 0112697970"},
    {"name": "Kitui County Fire Brigade", "number": "0702615888"},
    {"name": "Kwale County Fire Brigade", "number": "0790508898 / 0721225678"},
    {"name": "Limuru / Kikuyu & Lari Sub County Fire Brigade", "number": "0722551946"},
    {"name": "Machakos County Fire Brigade", "number": "0720808900 / 254715068861"},
    {"name": "Makueni County Fire Brigade", "number": "0715486141"},
    {"name": "Malindi County Fire Brigade", "number": "0733550990 / 0718242343"},
    {"name": "Mandera County Fire Brigade", "number": "0702524545"},
    {"name": "Meru County Fire Brigade", "number": "0726173505"},
    {"name": "Mombasa County Fire Brigade", "number": "0412225555 / 0738911911"},
    {"name": "Murang'a County Fire Brigade", "number": "0800721800"},
    {"name": "Nairobi Fire Brigade", "number": "0202222181 / 182 / 183"},
    {"name": "Nakuru County Fire Brigade", "number": "0202411440"},
    {"name": "Nandi County Fire Brigade", "number": "1548"},
    {"name": "Nanyuki County Fire Brigade", "number": "0726986933"},
    {"name": "Narok County Fire Brigade", "number": "0800722984 / +254799213209"},
    {"name": "Nyahururu County Fire Brigade", "number": "0706031031"},
    {"name": "Nyandarua County Fire Brigade", "number": "0735018018"},
    {"name": "Nyeri County Fire Brigade", "number": "0612032961"},
    {"name": "Tharaka Nithi County Fire Brigade", "number": "1513"},
    {"name": "Taita Taveta County Fire & Rescue", "number": "+254 113 087070 & 0789 712286"},
    {"name": "Trans Nzoia Fire Brigade", "number": "0202346945"},
    {"name": "Turkana County Fire Brigade", "number": "0111623637"},
    {"name": "Uasin Gishu Fire Brigade", "number": "0710646464"},
    {"name": "Vihiga County Fire Brigade", "number": "0800721205"},
      
    // Nairobi County
    {"name": "Kenyatta National Hospital", "number": "020 2726300"},
    {"name": "Nairobi Hospital", "number": "020 2845000"},
    {"name": "Aga Khan Hospital Nairobi", "number": "020 3740000"},
    {"name": "Mama Lucy Kibaki Hospital", "number": "020 2324500"},
    {"name": "Mbagathi District Hospital", "number": "020 2722984"},
    
    // Mombasa County
    {"name": "Coast General Hospital", "number": "041 2314204"},
    {"name": "Aga Khan Hospital Mombasa", "number": "041 2227710"},
    {"name": "Pandya Memorial Hospital", "number": "041 2312190"},
    {"name": "Port Reitz Sub-County Hospital", "number": "041 3432061"},
    
    // Kisumu County
    {"name": "Jaramogi Oginga Odinga Hospital", "number": "057 2023700"},
    {"name": "Kisumu County Hospital", "number": "057 2023700"},
    {"name": "Ahero Sub-County Hospital", "number": "057 2351234"},
    
    // Nakuru County
    {"name": "Nakuru Level 5 Hospital", "number": "051 2216383"},
    {"name": "Naivasha Sub-County Hospital", "number": "050 2020018"},
    {"name": "Kabarak University Hospital", "number": "0202114658"},
    {"name": "Molo Sub-County Hospital", "number": "051 721234"},
    {"name": "Kabarak University Emergency", "number": "0110009277"},
    
    // Uasin Gishu County
    {"name": "Moi Teaching & Referral Hospital", "number": "053 2033471"},
    {"name": "Eldoret Hospital", "number": "053 2061000"},
    {"name": "Turbo Sub-County Hospital", "number": "053 2062000"},
    
    // Machakos County
    {"name": "Machakos Level 5 Hospital", "number": "044 20372"},
    {"name": "Kathiani Sub-County Hospital", "number": "044 29876"},
    {"name": "Kangundo Sub-County Hospital", "number": "044 25432"},
    
    // Kiambu County
    {"name": "Kiambu Level 5 Hospital", "number": "066 2032811"},
    {"name": "Thika Level 5 Hospital", "number": "067 2220000"},
    {"name": "Gatundu Level 4 Hospital", "number": "067 2240000"},
    
    // Nyeri County
    {"name": "Nyeri County Referral Hospital", "number": "061 2032811"},
    {"name": "Mt Kenya Hospital", "number": "061 2034000"},
    {"name": "Karatina Sub-County Hospital", "number": "061 7234156"},
    
    // Kakamega County
    {"name": "Kakamega County Referral Hospital", "number": "056 30048"},
    {"name": "Malava Sub-County Hospital", "number": "056 31234"},
    {"name": "Butere Sub-County Hospital", "number": "056 32345"},
    
    // Kisii County
    {"name": "Kisii Teaching & Referral Hospital", "number": "058 30048"},
    {"name": "Keumbu Sub-County Hospital", "number": "058 31234"},
    {"name": "Marani Sub-County Hospital", "number": "058 32345"},
    
    // Meru County
    {"name": "Meru Teaching & Referral Hospital", "number": "064 30048"},
    {"name": "Timau Sub-County Hospital", "number": "064 31234"},
    {"name": "Nkubu Sub-County Hospital", "number": "064 32345"},
    
    // Emergency Helplines
    {"name": "Gender Violence Helpline", "number": "1195"},
    {"name": "Child Helpline", "number": "116"},
  ];

  List<Map<String, String>> filteredContacts = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredContacts = emergencyContacts;
  }

  void _filterContacts(String query) {
    setState(() {
      filteredContacts = emergencyContacts
          .where((contact) =>
              contact["name"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch call';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not call $phoneNumber'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  labelText: 'Search Contacts',
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            _filterContacts('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: Icon(
                          Icons.emergency,
                          color: Colors.red.shade700,
                        ),
                      ),
                      title: Text(
                        contact['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        contact['number']!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(contact['number']!),
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}