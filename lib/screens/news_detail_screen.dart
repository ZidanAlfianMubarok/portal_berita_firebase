import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;
  final Map<String, dynamic> newsData;

  const NewsDetailScreen({
    super.key,
    required this.newsId,
    required this.newsData,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  User? _currentUser;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  void _postComment() async {
    if (_commentController.text.isEmpty) return;
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to comment')),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() => _isSending = true);

    try {
      await _firestoreService.addComment(
        widget.newsId,
        _commentController.text.trim(),
        _currentUser!.displayName ?? 'User',
        _currentUser!.uid,
      );
      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.newsData;
    final imageUrl = news['imageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('News Detail')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                              height: 200,
                              child: Center(
                                  child: Icon(Icons.broken_image, size: 50))),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (news['authorName'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'By: ${news['authorName']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        Text(
                          news['title'] ?? 'No Title',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          news['content'] ?? 'No Content',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const Text(
                          'Comments',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getComments(widget.newsId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Error loading comments'));
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());

                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty)
                        return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No comments yet. Be the first!'));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final data = comment.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                                child: Text((data['userName'] as String)[0]
                                    .toUpperCase())),
                            title: Text(data['userName']),
                            subtitle: Text(data['content']),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Comment Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2))
            ]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: _isSending ? null : _postComment,
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
