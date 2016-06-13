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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal News'),
        actions: [
          if (_currentUser == null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                )
                    .then((_) {
                  setState(() {
                    _currentUser = _authService.currentUser;
                  });
                });
              },
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            )
          else
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                )
                    .then((_) {
                  setState(() {
                    _currentUser = _authService.currentUser;
                  });
                });
              },
            ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  setState(() {
                    _currentUser = _authService.currentUser;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out')));
                }
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.deepPurple.shade50,
            width: double.infinity,
            child: Text(
              _currentUser != null
                  ? 'Hello, ${_currentUser?.displayName ?? 'User'}!'
                  : 'Welcome Guest',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
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
                  itemCount: data.size,
                  itemBuilder: (context, index) {
                    var news = data.docs[index];
                    var newsData = news.data() as Map<String, dynamic>;

                    // Check if current user is author
                    bool isAuthor = _currentUser != null &&
                        newsData.containsKey('uid') &&
                        newsData['uid'] == _currentUser!.uid;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: InkWell(
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
                                if (newsData['imageUrl'] != null &&
                                    (newsData['imageUrl'] as String).isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      newsData['imageUrl'],
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox(
                                                  height: 150,
                                                  child: Center(
                                                      child: Icon(
                                                          Icons.broken_image))),
                                    ),
                                  ),
                                if (isAuthor)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
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
                            ListTile(
                              title: Text(
                                news['title'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                news['content'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddNews,
        child: const Icon(Icons.add),
      ),
    );
  }
}
