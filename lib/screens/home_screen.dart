import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  User? _currentUser;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  void _handleAddNews() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add news')),
      );
      Navigator.of(context)
          .push(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      )
          .then((_) {
        setState(() {
          _currentUser = _authService.currentUser;
        });
      });
      return;
    }

    showDialog(
        context: context,
        builder: (context) {
          final titleController = TextEditingController();
          final contentController = TextEditingController();
          return AlertDialog(
            title: const Text('Add News'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content')),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'A random image will be assigned.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final random = DateTime.now().millisecondsSinceEpoch;
                    final imageUrl =
                        'https://picsum.photos/seed/$random/300/200';

                    try {
                      // Pass uid
                      await _firestoreService.addNews(titleController.text,
                          contentController.text, imageUrl, _currentUser!.uid);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add news: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Add')),
            ],
          );
        });
  }

  void _handleEdit(String newsId, String currentTitle, String currentContent) {
    final titleController = TextEditingController(text: currentTitle);
    final contentController = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit News'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.updateNews(
                  newsId,
                  titleController.text,
                  contentController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('News updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(String newsId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteNews(newsId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('News deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildNewsFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentUser != null
                    ? 'Hello, ${_currentUser?.displayName ?? 'User'}!'
                    : 'Welcome Guest',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentUser != null
                    ? 'Here is your daily news'
                    : 'Login to create news',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getNews(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                    child: Text('Something went wrong. check permissions?'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.requireData;

              if (data.size == 0) {
                return const Center(child: Text('No news yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.size,
                itemBuilder: (context, index) {
                  var news = data.docs[index];
                  var newsData = news.data() as Map<String, dynamic>;

                  // Check if current user is author
                  bool isAuthor = _currentUser != null &&
                      newsData.containsKey('uid') &&
                      newsData['uid'] == _currentUser!.uid;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => NewsDetailScreen(
                                    newsId: news.id, newsData: newsData)));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: (newsData['imageUrl'] != null &&
                                        (newsData['imageUrl'] as String)
                                            .isNotEmpty)
                                    ? Image.network(
                                        newsData['imageUrl'],
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 180,
                                          color: Colors.grey[200],
                                          child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey)),
                                        ),
                                      )
                                    : Container(
                                        height: 180,
                                        color: Colors.deepPurple.shade100,
                                        child: const Center(
                                            child: Icon(Icons.newspaper,
                                                size: 60,
                                                color: Colors.deepPurple)),
                                      ),
                              ),
                              if (isAuthor)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Colors.black),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _handleEdit(
                                              news.id,
                                              newsData['title'] ?? '',
                                              newsData['content'] ?? '');
                                        } else if (value == 'delete') {
                                          _handleDelete(news.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('Edit'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete,
                                                color: Colors.red),
                                            title: Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news['title'],
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news['content'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 12),
                                if (newsData.containsKey('authorName'))
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 16, color: Colors.deepPurple),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${newsData['authorName']}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepPurple[400],
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'General',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
        ),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: const Text('Notifications'),
                activeColor: Colors.deepPurple,
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: false,
                onChanged: (val) {},
                title: const Text('Dark Mode'),
                activeColor: Colors.deepPurple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Support',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
        ),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.help_outline, color: Colors.deepPurple),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.info_outline, color: Colors.deepPurple),
                title: const Text('About App'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    switch (_selectedIndex) {
      case 0:
        currentWidget = _buildNewsFeed();
        break;
      case 1:
        currentWidget = _buildSettings();
        break;
      case 2:
        if (_currentUser != null) {
          currentWidget = const ProfileScreen();
        } else {
          currentWidget = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text('Please login to view profile'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    )
                        .then((_) {
                      setState(() {
                        _currentUser = _authService.currentUser;
                      });
                    });
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
        break;
      default:
        currentWidget = _buildNewsFeed();
    }

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text('Portal News',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.deepPurple.shade50,
              elevation: 0,
            )
          : null,
      body: currentWidget,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _handleAddNews,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
