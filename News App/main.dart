import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  NewsPageState createState() => NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  List _news = [];
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('http://<Your_IP_address>:5000/categories'));

    if (response.statusCode == 200) {
      setState(() {
        _categories = List<String>.from(json.decode(response.body));
        _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
        fetchNews();
      });
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> fetchNews() async {
    final categoryQuery = _selectedCategory != null ? '?category=$_selectedCategory' : '';
    final response = await http.get(Uri.parse('http://<Your_IP_address>:5000/news$categoryQuery'));

    if (response.statusCode == 200) {
      setState(() {
        _news = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load news');
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await launchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News App'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            if (_categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                      fetchNews();
                    });
                  },
                  items: _categories.map<DropdownMenuItem<String>>((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  dropdownColor: Colors.blue.shade700,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: _news.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _news.length,
                      itemBuilder: (context, index) {
                        final article = _news[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Text(
                              article['headline'],
                              style: const TextStyle(color: Colors.blue),
                            ),
                            subtitle: Text(article['category']),
                            onTap: () => _launchURL(article['link']),
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
}
