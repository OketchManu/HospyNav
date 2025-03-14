import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _newsFuture;
  late AnimationController _loadingController;
  String? userProfileImagePath;
  String userName = 'User Name'; // Default value
  bool _isOnline = true;
  bool _isRefreshing = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _newsFuture = _fetchHealthNews();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadUserProfile(); // Load initial profile data

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _handleConnectivityChange(results.first);
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = !connectivityResult.contains(ConnectivityResult.none);
      });
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    if (mounted) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
        if (_isOnline) {
          _newsFuture = _fetchHealthNews();
        }
      });
    }
  }

  Future<List<dynamic>> _fetchHealthNews() async {
    if (!_isOnline) {
      return _getCachedNews();
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://newsapi.org/v2/top-headlines?category=health&country=us&apiKey=${dotenv.env['NEWS_API_KEY']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newsList = data['articles'].map((article) => {
              'title': article['title'],
              'description': article['description'],
              'content': article['content'],
              'source': article['source']['name'],
              'author': article['author'],
              'image': article['urlToImage'],
              'published_at': article['publishedAt'],
              'url': article['url'],
            }).toList();

        await _saveNewsToCache(newsList);
        return newsList;
      } else {
        throw HttpException('Failed to load news: ${response.statusCode}');
      }
    } catch (error) {
      return _getCachedNews();
    }
  }

  Future<void> _saveNewsToCache(List<dynamic> news) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_news', json.encode(news));
    await prefs.setString('last_news_fetch', DateTime.now().toIso8601String());
  }

  Future<List<dynamic>> _getCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedNewsString = prefs.getString('cached_news');
    return cachedNewsString != null
        ? (json.decode(cachedNewsString) as List<dynamic>)
        : [];
  }

  Future<void> _loadUserProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  // Load initial values from SharedPreferences
  setState(() {
    userProfileImagePath = prefs.getString('${userId}_imagePath');
    userName = prefs.getString('${userId}_username') ?? 'User Name';
    // Use photoBase64 as a fallback if imagePath isn't a file
    final photoBase64 = prefs.getString('${userId}_photoBase64');
    if (userProfileImagePath == null && photoBase64 != null) {
      userProfileImagePath = photoBase64; // Treat as Base64 for display
    }
  });
}

  Widget _buildProfileImage() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const CircleAvatar(
      radius: 16,
      child: Icon(Icons.person),
    );
  }

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircleAvatar(
          radius: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      if (snapshot.hasError) {
        debugPrint('Error fetching profile: ${snapshot.error}');
        return const CircleAvatar(
          radius: 16,
          child: Icon(Icons.error_outline),
        );
      }

      String? photoBase64;
      File? localImageFile;

      if (snapshot.hasData && snapshot.data!.exists) {
        final data = snapshot.data!.data() as Map<String, dynamic>;
        photoBase64 = data['photoBase64'] as String?;
      }

      // Fallback to local cache if no Firestore data or offline
      if (photoBase64 == null && userProfileImagePath != null) {
        if (userProfileImagePath!.startsWith('http')) {
          // Handle URL case (if you decide to support URLs later)
          return CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(userProfileImagePath!),
            child: null,
          );
        } else if (File(userProfileImagePath!).existsSync()) {
          localImageFile = File(userProfileImagePath!);
        }
      }

      return CircleAvatar(
        radius: 16,
        backgroundImage: photoBase64 != null
            ? MemoryImage(base64Decode(photoBase64))
            : localImageFile != null
                ? FileImage(localImageFile)
                : null,
        onBackgroundImageError: photoBase64 != null || localImageFile != null
            ? (exception, stackTrace) {
                debugPrint('Error loading profile image: $exception');
              }
            : null,
        child: photoBase64 == null && localImageFile == null
            ? const Icon(Icons.person)
            : null,
      );
    },
  );
}

  void _showNewsDetail(Map<String, dynamic> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewsDetailSheet(article: article),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[700]!,
              Colors.purple[800]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[500],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Offline Mode - Showing cached content',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              _buildQuickActions(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildNewsSection(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.purple[900],
        elevation: 0,
        title: const Text(
          'HospyNav',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _newsFuture = _fetchHealthNews();
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'Profile':
                  Navigator.pushNamed(context, '/profile').then((_) {
                    _loadUserProfile(); // Refresh profile data after returning
                    setState(() {}); // Trigger rebuild for StreamBuilder
                  });
                  break;
                case 'Settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'Feedback':
                  Navigator.pushNamed(context, '/feedback');
                  break;
              }
            },
            icon: _buildProfileImage(),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Profile',
                  child: ListTile(
                    leading: _buildProfileImage(),
                    title: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String displayName = userName; // Default
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          displayName = data['username'] as String? ?? userName;
                        }
                        return Text(displayName);
                      },
                    ),
                    subtitle: const Text('View Profile'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'Settings',
                  child: ListTile(
                    leading: Icon(Icons.settings, color: Colors.blue),
                    title: Text('Settings'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Feedback',
                  child: ListTile(
                    leading: Icon(Icons.feedback, color: Colors.orange),
                    title: Text('Feedback'),
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            Icons.local_hospital,
            'Find Hospital',
            Colors.red[400]!,
            () => Navigator.pushNamed(context, '/hospitals'),
          ),
          _buildQuickActionButton(
            Icons.phone_in_talk,
            'Emergency',
            Colors.green[400]!,
            () => Navigator.pushNamed(context, '/emergency_contacts'),
          ),
          _buildQuickActionButton(
            Icons.health_and_safety,
            'First Aid',
            Colors.orange[400]!,
            () => Navigator.pushNamed(context, '/first_aid'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Health News',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isRefreshing = true;
              });
              try {
                if (mounted) {
                  await _fetchHealthNews().then((news) {
                    setState(() {
                      _newsFuture = Future.value(news);
                      _isRefreshing = false;
                    });
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: FutureBuilder<List<dynamic>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (_isRefreshing) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.newspaper,
                    message: 'No health news available',
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: snapshot.data!.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildNewsCard(snapshot.data![index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        snapshot.data!.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () => _showNewsDetail(article),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: article['image'] != null
                  ? CachedNetworkImage(
                      imageUrl: article['image'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error_outline),
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.newspaper)),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['description'] ?? 'No description available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.source, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            article['source'] ?? 'Unknown Source',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (article['author'] != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    article['author'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(article['published_at'] ?? ''),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('MMM d, y');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _loadingController,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading health news...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load news\n$error',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _newsFuture = _fetchHealthNews();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.purple[900],
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewsDetailSheet extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsDetailSheet({
    super.key,
    required this.article,
  });

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (article['image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: article['image'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      article['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.source, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          article['source'] ?? 'Unknown Source',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (article['author'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            article['author'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(article['published_at'] ?? ''),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (article['description'] != null) ...[
                      Text(
                        article['description'],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (article['content'] != null)
                      Text(
                        article['content'],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (article['url'] != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          try {
                            _launchURL(article['url']);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Could not open article: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Read Full Article'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('MMMM d, y');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}