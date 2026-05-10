import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const String baseUrl =
      'https://resq-app-xsb98.ondigitalocean.app';

  List<dynamic> news = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/news'),
      );

      if (response.statusCode == 200) {
        setState(() {
          news = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("News fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'weather':
        return Icons.cloud_outlined;

      case 'emergency':
        return Icons.warning_amber_rounded;

      case 'disaster alert':
        return Icons.crisis_alert_outlined;

      case 'advisory':
        return Icons.campaign_outlined;

      case 'missing person':
        return Icons.person_search_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color getColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return Colors.red;

      case 'high':
        return Colors.orange;

      case 'moderate':
        return Colors.blue;

      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'News & Alerts',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : news.isEmpty
              ? const Center(
                  child: Text("No announcements available"),
                )

              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: news.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),

                  itemBuilder: (context, index) {
                    final item = news[index];

                    final category =
                        item['category'] ?? 'General';

                    final priority =
                        item['priority'] ?? 'Low';

                    return Container(
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),

                        border: Border.all(
                          color: const Color(0xFFE8E0D8),
                        ),
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,

                            decoration: BoxDecoration(
                              color: getColor(priority)
                                  .withOpacity(0.1),

                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            child: Icon(
                              getIcon(category),
                              color: getColor(priority),
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                Text(
                                  item['title'] ?? '',

                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  item['message'] ?? '',

                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,

                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}