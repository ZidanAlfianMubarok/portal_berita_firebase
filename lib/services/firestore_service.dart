import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get stream of news
  Stream<QuerySnapshot> getNews() {
    return _db.collection('news').orderBy('date', descending: true).snapshots();
  }

  // Add news (optional, for testing)
  Future<void> addNews(
      String title, String content, String imageUrl, String uid) async {
    await _db.collection('news').add({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'uid': uid,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // Update news
  Future<void> updateNews(String newsId, String title, String content) async {
    await _db.collection('news').doc(newsId).update({
      'title': title,
      'content': content,
    });
  }

  // Delete news
  Future<void> deleteNews(String newsId) async {
    await _db.collection('news').doc(newsId).delete();
  }

  // Get stream of comments for a news item
  Stream<QuerySnapshot> getComments(String newsId) {
    return _db
        .collection('news')
        .doc(newsId)
        .collection('comments')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Add comment
  Future<void> addComment(
      String newsId, String content, String userName, String uid) async {
    await _db.collection('news').doc(newsId).collection('comments').add({
      'content': content,
      'userName': userName,
      'uid': uid,
      'date': FieldValue.serverTimestamp(),
    });
  }
}
