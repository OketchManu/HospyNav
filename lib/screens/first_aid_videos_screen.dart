import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoId;
  final String duration;
  final String views;
  final List<String> relatedConditions;

  VideoItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoId,
    required this.duration,
    required this.views,
    required this.relatedConditions,
  });
}

class VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;

  const VideoCard({
    super.key, 
    required this.video, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        video.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${video.duration} | ${video.views} views',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              video.category,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    )..addListener(listener);
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blueAccent,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.blueAccent,
                    handleColor: Colors.blue,
                  ),
                  onReady: () {
                    _isPlayerReady = true;
                  },
                ),
                builder: (context, player) {
                  return player;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${widget.video.category}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.video.views} views',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            widget.video.duration,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FirstAidVideosScreen extends StatefulWidget {
  const FirstAidVideosScreen({super.key});

  @override
  FirstAidVideosScreenState createState() => FirstAidVideosScreenState();
}

class FirstAidVideosScreenState extends State<FirstAidVideosScreen> {
  List<VideoItem> allVideos = [];
  List<VideoItem> filteredVideos = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'All';
  final TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'First Aid',
    'Heart Health',
    'Mental Health',
    'Diabetes',
    'Respiratory',
    'Emergency',
    'Allergies',
    'Pediatric Care'
  ];

  @override
  void initState() {
    super.initState();
    loadInitialVideos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadInitialVideos() async {
    final defaultVideos = [
     VideoItem(
    id: 'emergency_first_aid',
    category: 'First Aid',
    title: 'Emergency First Aid Skills Everyone Should Know',
    description: '''This video by St John Ambulance covers essential first aid skills like performing primary survey, CPR on babies and adults, as well as how to use a defibrillator. 
    Learning basic first aid can be lifesaving in an emergency.''',
    thumbnailUrl: 'https://i.ytimg.com/vi/T_S_fM7l84Q/mqdefault.jpg', 
    videoId: 'T_S_fM7l84Q', 
    duration: '5:49', 
    views: '2.3M', 
    relatedConditions: ['first aid', 'emergency response', 'CPR'],
    ),
      VideoItem(
        id: 'cpr_technique',
        category: 'Emergency',
        title: 'How to Perform CPR - Step by Step Guide',
        description: 'Comprehensive guide to performing CPR on adults, children, and infants. Learn life-saving techniques.',
        thumbnailUrl: 'https://i.ytimg.com/vi/hizBdM1Ob68/mqdefault.jpg',
        videoId: 'hizBdM1Ob68',
        duration: '15:20',
        views: '5.1M',
        relatedConditions: ['heart attack', 'emergency', 'cardiac arrest'],
      ),
      VideoItem(
 id: 'cpr_basics',
 category: 'First Aid',
 title: 'How to Perform CPR (2024 Guidelines)',
 description: 'Learn proper CPR technique for adults, children and infants according to latest guidelines.',
 thumbnailUrl: 'https://i.ytimg.com/vi/hizBdM1Ob68/mqdefault.jpg',
 videoId: 'hizBdM1Ob68',
 duration: '8:45',
 views: '2.1M',
 relatedConditions: ['cardiac arrest', 'emergency response'],
),
VideoItem(
 id: 'heart_attack',
 category: 'Emergency',
 title: 'Heart Attack Warning Signs & First Aid',
 description: 'Recognize heart attack symptoms early and learn the immediate steps to take.',
 thumbnailUrl: 'https://i.ytimg.com/vi/gDwt7dD3awc/mqdefault.jpg',
 videoId: 'gDwt7dD3awc',
 duration: '10:15',
 views: '1.8M',
 relatedConditions: ['heart attack', 'chest pain'],
),
VideoItem(
 id: 'choking_response', 
 category: 'First Aid',
 title: 'How to Help Someone Who\'s Choking',
 description: 'Learn the Heimlich maneuver and other techniques to help choking victims.',
 thumbnailUrl: 'https://i.ytimg.com/vi/PA9hpOnvtCk/mqdefault.jpg',
 videoId: 'PA9hpOnvtCk',
 duration: '7:30',
 views: '2.4M',
 relatedConditions: ['choking', 'airway obstruction'],
),
VideoItem(
    id: 'seizure_aid',
    category: 'Emergency',
    title: 'What To Do If Someone Has A Seizure - St John Ambulance',
    description: 'A St John Ambulance trainer demonstrates what to look for if someone is having a seizure, what causes a seizure, and what to do to help.',
    thumbnailUrl: 'https://i.ytimg.com/vi/Ovsw7tdneqE/mqdefault.jpg',
    videoId: 'Ovsw7tdneqE',
    duration: '8:00',
    views: '1.5M',
    relatedConditions: ['epilepsy', 'seizures'],
),
VideoItem(
    id: 'wound_care',
    category: 'First Aid',
    title: 'Bandaging Basics',
    description: 'An instructional video demonstrating the basics of bandaging techniques.',
    thumbnailUrl: 'https://i.ytimg.com/vi/u6jsu779H74/mqdefault.jpg',
    videoId: 'u6jsu779H74',
    duration: '8:50',
    views: '62K',
    relatedConditions: ['cuts', 'wounds', 'bleeding'],
),
VideoItem(
    id: 'anaphylaxis',
    category: 'Emergency',
    title: 'First Aid for Severe Allergic Reactions | British Red Cross',
    description: 'Learn how to recognize and respond to severe allergic reactions (anaphylaxis) in this informative video.',
    thumbnailUrl: 'https://i.ytimg.com/vi/8EyYTW-1EP0/mqdefault.jpg',
    videoId: '8EyYTW-1EP0',
    duration: '5:00',
    views: '500K',
    relatedConditions: ['allergies', 'anaphylaxis'],
),
VideoItem(
    id: 'burns_treatment',
    category: 'First Aid',
    title: 'First Aid for Burns: What to Do Immediately | Mayo Clinic',
    description: 'Learn proper treatment for different degrees of burns and scalds in this Mayo Clinic video.',
    thumbnailUrl: 'https://i.ytimg.com/vi/B10sth4zjuI/mqdefault.jpg',
    videoId: 'B10sth4zjuI',
    duration: '3:00',
    views: '1.2M',
    relatedConditions: ['burns', 'scalds'],
),
VideoItem(
  id: 'stroke_signs',
  category: 'Emergency',
  title: 'Learn the warning signs for stroke F.A.S.T.',
  description: 'A stroke can happen at any age. Learn to recognize the warning signs using the FAST method in this educational video.',
  thumbnailUrl: 'https://i.ytimg.com/vi/kBoKrAILPPo/mqdefault.jpg',
  videoId: 'kBoKrAILPPo',
  duration: '1:01',
  views: '39K',
  relatedConditions: ['stroke', 'brain emergency'],
),
VideoItem(
  id: 'fracture_care',
  category: 'First Aid',
  title: 'How To Treat A Fracture & Fracture Types - First Aid Training - St John Ambulance',
  description: 'Learn how to properly immobilize and care for suspected fractures in this instructional video by St John Ambulance.',
  thumbnailUrl: 'https://i.ytimg.com/vi/HlNgrdg7NoQ/mqdefault.jpg',
  videoId: 'HlNgrdg7NoQ',
  duration: '2:52',
  views: '1.1M',
  relatedConditions: ['fractures', 'bone injury'],
),
VideoItem(
  id: 'hypothermia',
  category: 'Emergency',
  title: 'First aid for someone with hypothermia | British Red Cross',
  description: 'Learn to recognize and treat dangerously low body temperature in this informative video by the British Red Cross.',
  thumbnailUrl: 'https://i.ytimg.com/vi/DewzkBh2onc/mqdefault.jpg',
  videoId: 'DewzkBh2onc',
  duration: '3:20',
  views: '4.5K',
  relatedConditions: ['hypothermia', 'cold exposure'],
),
VideoItem(
 id: 'bleeding_control',
 category: 'First Aid',
 title: 'Stop the Bleed: Controlling Serious Bleeding',
 description: 'Essential techniques for controlling severe bleeding emergencies.',
 thumbnailUrl: 'https://i.ytimg.com/vi/mhBe7Q6mH3U/mqdefault.jpg',
 videoId: 'mhBe7Q6mH3U',
 duration: '9:20',
 views: '2.0M',
 relatedConditions: ['bleeding', 'trauma'],
),
VideoItem(
    id: 'heat_illness',
    category: 'Emergency',
    title: 'Heat Exhaustion vs Heat Stroke',
    description: 'Learn how to identify and treat serious heat-related illnesses.',
    thumbnailUrl: 'https://i.ytimg.com/vi/0xubzGiAjEU/mqdefault.jpg',
    videoId: '0xubzGiAjEU',
    duration: '8:15',
    views: '1.8M',
    relatedConditions: ['heat illness', 'hyperthermia'],
),
VideoItem(
    id: 'poison_response',
    category: 'First Aid',
    title: 'First Aid for Poisoning Emergencies',
    description: 'Steps to take when someone has ingested harmful substances.',
    thumbnailUrl: 'https://i.ytimg.com/vi/b2ieb8BZJuY/mqdefault.jpg',
    videoId: 'b2ieb8BZJuY',
    duration: '10:45',
    views: '1.5M',
    relatedConditions: ['poisoning', 'toxic exposure'],
),
VideoItem(
 id: 'diabetic_emergency',
 category: 'Emergency',
 title: 'Handling Diabetic Emergencies',
 description: 'Recognize and respond to high and low blood sugar emergencies.',
 thumbnailUrl: 'https://i.ytimg.com/vi/wZAjVQWbMlE/mqdefault.jpg',
 videoId: 'wZAjVQWbMlE',
 duration: '9:30',
 views: '1.7M',
 relatedConditions: ['diabetes', 'blood sugar'],
),
VideoItem(
  id: 'head_injury',
  category: 'First Aid',
  title: 'First aid for someone who has a head injury | British Red Cross',
  description: 'Learn how to assess and provide first aid for head injuries with this instructional video by the British Red Cross.',
  thumbnailUrl: 'https://i.ytimg.com/vi/Wu53L0oKkKg/mqdefault.jpg',
  videoId: 'Wu53L0oKkKg',
  duration: '2:11',
  views: '340K',
  relatedConditions: ['concussion', 'head trauma'],
),
VideoItem(
  id: 'spinal_care',
  category: 'Emergency',
  title: 'What To Do If Someone Has A Spinal Cord Injury - St John Ambulance',
  description: 'Critical information for handling suspected spinal injuries, presented by St John Ambulance.',
  thumbnailUrl: 'https://i.ytimg.com/vi/Uqy2IUhYkVA/mqdefault.jpg',
  videoId: 'Uqy2IUhYkVA',
  duration: '2:52',
  views: '340K',
  relatedConditions: ['spinal injury', 'neck injury'],
),
VideoItem(
  id: 'chest_pain',
  category: 'Emergency',
  title: 'Chest Pain: When to Call 911',
  description: 'How to assess chest pain severity and respond appropriately.',
  thumbnailUrl: 'https://i.ytimg.com/vi/gDwt7dD3awc/mqdefault.jpg',
  videoId: 'gDwt7dD3awc',
  duration: '8:35',
  views: '2.0M',
  relatedConditions: ['chest pain', 'heart problems'],
),
      VideoItem(
        id: 'vertigo_management',
        category: 'Emergency',
        title: 'Handling Severe Dizziness and Vertigo',
        description: 'First aid techniques for managing sudden and intense dizziness.',
        thumbnailUrl: 'https://i.ytimg.com/vi/mQR6b7CAiqk/mqdefault.jpg',
        videoId: 'mQR6b7CAiqk',
        duration: '8:30',
        views: '1.3M',
        relatedConditions: ['vertigo', 'dizziness', 'balance disorder'],
      ),
      VideoItem(
        id: 'sepsis_awareness',
        category: 'Emergency',
        title: 'Recognising the early signs of sepsis (Full Video)',
        description: 'Critical signs and immediate actions for potential sepsis development.',
        thumbnailUrl: 'https://i.ytimg.com/vi/qhAyNd4gEoA/mqdefault.jpg',
        videoId: 'qhAyNd4gEoA',
        duration: '5:00',
        views: '2.1M',
        relatedConditions: ['sepsis', 'infection', 'immune response'],
       ),
      VideoItem(
        id: 'kidney_info',
        category: 'Emergency',
        title: 'Kidney Stone Treatments | Cleveland Clinic',
        description: 'Learn about the symptoms, causes, and treatments for kidney stones in this informative video.',
        thumbnailUrl: 'https://i.ytimg.com/vi/kcaOMrOiyJs/mqdefault.jpg',
        videoId: 'kcaOMrOiyJs',
        duration: '8:12',
        views: '500K',
        relatedConditions: ['kidney stones', 'renal pain'],
      ),

      VideoItem(
        id: 'appendix_signs',
        category: 'Emergency',
        title: 'Appendicitis Symptoms and Treatment | Mayo Clinic',
        description: 'Understand how to recognize appendicitis symptoms and treatment options in this detailed video.',
        thumbnailUrl: 'https://i.ytimg.com/vi/oj_IJoqHXCQ/mqdefault.jpg',
        videoId: 'oj_IJoqHXCQ',
        duration: '5:40',
        views: '1.3M',
        relatedConditions: ['appendicitis', 'abdominal pain'],
      ),

      VideoItem(
        id: 'co_poisoning',
        category: 'Emergency',
        title: 'Carbon Monoxide Poisoning Prevention | American Red Cross',
        description: 'Discover how to prevent carbon monoxide poisoning and protect your family from this dangerous gas.',
        thumbnailUrl: 'https://i.ytimg.com/vi/C-WepWYGekk/mqdefault.jpg',
        videoId: 'C-WepWYGekk',
        duration: '4:45',
        views: '800K',
        relatedConditions: ['carbon monoxide', 'poisoning'],
      ),

      VideoItem(
        id: 'heat_illness',
        category: 'Emergency',
        title: 'Mayo Clinic Minute: Heat exhaustion and heatstroke',
        description: 'Learn how to recognize and respond to heat exhaustion and heatstroke.',
        thumbnailUrl: 'https://i.ytimg.com/vi/0xubzGiAjEU/mqdefault.jpg',
        videoId: '0xubzGiAjEU',
        duration: '1:30',
        views: '1.2M',
        relatedConditions: ['heat exhaustion', 'heat stroke'],
      ),

      VideoItem(
        id: 'wound_care',
        category: 'First Aid',
        title: 'First Aid for Severe Bleeding',
        description: 'Learn how to control severe bleeding in emergency situations.',
        thumbnailUrl: 'https://i.ytimg.com/vi/jYtJS1PtNq0/mqdefault.jpg',
        videoId: 'jYtJS1PtNq0',
        duration: '2:30',
        views: '950K',
        relatedConditions: ['wound care', 'infection'],
      ),

      VideoItem(
        id: 'nosebleed',
        category: 'First Aid',
        title: 'What to do during a nosebleed',
        description: 'Discover effective techniques to stop a nosebleed quickly and safely.',
        thumbnailUrl: 'https://i.ytimg.com/vi/3pSKRvIlVZ4/mqdefault.jpg',
        videoId: '3pSKRvIlVZ4',
        duration: '1:45',
        views: '700K',
        relatedConditions: ['nosebleed', 'bleeding'],
      ),

      VideoItem(
        id: 'food_safety',
        category: 'Emergency',
        title: 'How CDC Investigates Foodborne Outbreaks',
        description: 'Learn how the CDC identifies and responds to foodborne illness outbreaks.',
        thumbnailUrl: 'https://i.ytimg.com/vi/RKxYw6H7xlg/mqdefault.jpg',
        videoId: 'RKxYw6H7xlg',
        duration: '3:00',
        views: '1.3M',
        relatedConditions: ['food poisoning', 'dehydration'],
      ),

      VideoItem(
        id: 'sports_first_aid',
        category: 'First Aid',
        title: 'First Aid for Severe Bleeding',
        description: 'Learn how to control severe bleeding in emergency situations.',
        thumbnailUrl: 'https://i.ytimg.com/vi/jYtJS1PtNq0/mqdefault.jpg',
        videoId: 'jYtJS1PtNq0',
        duration: '2:30',
        views: '2.3M',
        relatedConditions: ['sports injury', 'sprains'],
      ),

      VideoItem(
        id: 'water_rescue',
        category: 'Emergency',
        title: 'Water Rescue Skills — Rescues at or Near the Surface',
        description: 'Master water rescue techniques and learn how to safely respond to drowning emergencies.',
        thumbnailUrl: 'https://i.ytimg.com/vi/kkN0wO2ci04/mqdefault.jpg',
        videoId: 'kkN0wO2ci04',
        duration: '4:00',
        views: '1.4M',
        relatedConditions: ['drowning', 'water safety'],
      ),

      VideoItem(
      id: 'diabetes_care',
      category: 'Diabetes',
      title: 'Managing Diabetic Emergencies',
      description: 'Advanced diabetes emergency response.',
      thumbnailUrl: 'https://i.ytimg.com/vi/wZAjVQWbMlE/mqdefault.jpg',
      videoId: 'wZAjVQWbMlE',
      duration: '11:10',
      views: '1.4M',
      relatedConditions: ['diabetes', 'blood sugar'],
      ),
            VideoItem(
              id: 'child_choking_advanced',
              category: 'Pediatric Care',
              title: 'Advanced Child Choking and Infant Rescue',
              description: 'Detailed techniques for saving a choking child at different ages.',
              thumbnailUrl: 'https://i.ytimg.com/vi/oswDpwzbAV8/mqdefault.jpg',
              videoId: 'oswDpwzbAV8',
              duration: '14:30',
              views: '2.1M',
              relatedConditions: ['choking', 'pediatric emergency', 'child safety'],
            ),
        VideoItem(
        id: 'mental_crisis',
        category: 'Mental Health',
        title: 'Mental Health Crisis Intervention | Mental Health Guide',
        description: 'Learn strategies for effectively managing mental health crises.',
        thumbnailUrl: 'https://i.ytimg.com/vi/5-PgSUTOSeM/mqdefault.jpg',
        videoId: '5-PgSUTOSeM',
        duration: '9:40',
        views: '1.5M',
        relatedConditions: ['mental health', 'crisis intervention'],
      ),

      VideoItem(
        id: 'wilderness_aid',
        category: 'First Aid',
        title: 'Wilderness First Aid Basics | Survival Skills',
        description: 'Essential first aid skills for emergencies in remote settings.',
        thumbnailUrl: 'https://i.ytimg.com/vi/fg-F3nWo5fw/mqdefault.jpg',
        videoId: 'fg-F3nWo5fw',
        duration: '12:50',
        views: '1.2M',
        relatedConditions: ['wilderness emergency', 'survival skills'],
      ),

      VideoItem(
        id: 'travel_health',
        category: 'Emergency',
        title: 'Travel Health and Safety | Travel Medicine',
        description: 'Essential tips and guidance on travel health and how to stay safe while traveling internationally.',
        thumbnailUrl: 'https://i.ytimg.com/vi/6gKalfwYNMg/mqdefault.jpg',
        videoId: '6gKalfwYNMg',
        duration: '8:05',
        views: '1.5M',
        relatedConditions: ['travel health', 'vaccines', 'disease prevention'],
      ),
      VideoItem(
  id: 'heart_health_1',
  category: 'Heart Health',
  title: 'Take Action to Prevent Heart Disease',
  description: 'Emphasizes the importance of preventive measures to maintain heart health.',
  thumbnailUrl: 'https://i.ytimg.com/vi/Fu1u11iRKAE/mqdefault.jpg',
  videoId: 'Fu1u11iRKAE',
  duration: '3:00',
  views: '1.5M',
  relatedConditions: ['Heart disease', 'Cardiovascular health'],
),

VideoItem(
  id: 'heart_health_2',
  category: 'Heart Health',
  title: 'Mayo Clinic Minute - What to do for a healthier heart',
  description: 'Provides actionable steps to improve heart health.',
  thumbnailUrl: 'https://i.ytimg.com/vi/wXk1Nj28Hm4/mqdefault.jpg',
  videoId: 'wXk1Nj28Hm4',
  duration: '1:30',
  views: '1.2M',
  relatedConditions: ['Heart disease', 'Cardiovascular health'],
),

VideoItem(
  id: 'respiratory_1',
  category: 'Respiratory',
  title: '5 Steps to Keep Your Lungs Healthy',
  description: 'Outlines essential practices for maintaining lung health.',
  thumbnailUrl: 'https://i.ytimg.com/vi/IwsljkMSVok/mqdefault.jpg',
  videoId: 'IwsljkMSVok',
  duration: '2:00',
  views: '1.5M',
  relatedConditions: ['COPD', 'Asthma', 'Lung diseases'],
),

VideoItem(
  id: 'respiratory_2',
  category: 'Respiratory',
  title: 'Understanding the Respiratory System and Lung Disease',
  description: 'Provides an overview of the respiratory system and common lung diseases.',
  thumbnailUrl: 'https://i.ytimg.com/vi/DFpEl6ZTAQc/mqdefault.jpg',
  videoId: 'DFpEl6ZTAQc',
  duration: '10:00',
  views: '800K',
  relatedConditions: ['COPD', 'Asthma', 'Lung cancer'],
),

VideoItem(
  id: 'respiratory_3',
  category: 'Respiratory',
  title: 'What is a Lung Health Navigator?',
  description: 'Explains the role of lung health navigators in managing respiratory health.',
  thumbnailUrl: 'https://i.ytimg.com/vi/JLcAQCPcXek/mqdefault.jpg',
  videoId: 'JLcAQCPcXek',
  duration: '3:00',
  views: '500K',
  relatedConditions: ['COPD', 'Asthma', 'Lung diseases'],
),

VideoItem(
  id: 'allergies_1',
  category: 'Allergies',
  title: 'The Real Reason Why You Have Allergies',
  description: 'Explores the underlying causes of allergies.',
  thumbnailUrl: 'https://i.ytimg.com/vi/9zCH37330f8/mqdefault.jpg',
  videoId: '9zCH37330f8',
  duration: '10:00',
  views: '2M',
  relatedConditions: ['Allergies', 'Immune response'],
),

VideoItem(
  id: 'allergies_2',
  category: 'Allergies',
  title: 'Allergies: Symptoms, Reaction, Treatment & Management',
  description: 'Comprehensive information on allergy symptoms and management.',
  thumbnailUrl: 'https://i.ytimg.com/vi/mNMvS89eVgg/mqdefault.jpg',
  videoId: 'mNMvS89eVgg',
  duration: '15:00',
  views: '1.5M',
  relatedConditions: ['Allergies', 'Immune response'],
),

VideoItem(
  id: 'allergies_3',
  category: 'Allergies',
  title: 'Is it a cold or allergies? What you need to know about ...',
  description: 'Learn how to distinguish between cold symptoms and allergies.',
  thumbnailUrl: 'https://i.ytimg.com/vi/ySTEZh1PtuE/mqdefault.jpg',
  videoId: 'ySTEZh1PtuE',
  duration: '5:00',
  views: '1.2M',
  relatedConditions: ['Cold', 'Allergies'],
),
VideoItem(
  id: 'allergies_4',
  category: 'Allergies',
  title: 'Manage Your Seasonal Allergies',
  description: 'Learn helpful tips and treatments to manage seasonal allergies.',
  thumbnailUrl: 'https://i.ytimg.com/vi/zCU7wna9ylQ/mqdefault.jpg',
  videoId: 'zCU7wna9ylQ',
  duration: '6:30',
  views: '800K',
  relatedConditions: ['Seasonal allergies', 'Allergy treatments'],
),


    ];

    setState(() {
      allVideos = defaultVideos;
      filteredVideos = defaultVideos;
      isLoading = false;
    });
  }

  void filterVideos() {
    setState(() {
      filteredVideos = allVideos.where((video) {
        final matchesSearch = searchQuery.isEmpty || 
          video.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          video.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          video.relatedConditions.any((condition) => 
            condition.toLowerCase().contains(searchQuery.toLowerCase()));
        
        final matchesCategory = selectedCategory == 'All' || video.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).colorScheme.primary.withAlpha(128),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health & Medical Videos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Search any medical condition for first aid guidance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filterVideos();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search conditions (e.g., heart attack, anxiety...)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                                filterVideos();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredVideos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No videos found for "$searchQuery"',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: filteredVideos.length,
                          itemBuilder: (context, index) {
                            return VideoCard(
                              video: filteredVideos[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerScreen(
                                      video: filteredVideos[index],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}