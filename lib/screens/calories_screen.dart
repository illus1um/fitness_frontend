import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'product_detail_screen.dart';

class CaloriesScreen extends StatefulWidget {
  @override
  _CaloriesScreenState createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends State<CaloriesScreen> {
  List<dynamic> _foods = [];
  String _searchTerm = '';
  bool _isLoading = false;

  Future<String?> _fetchImage(String query) async {
    final apiKey = 'c09vC0LhxDC8sU7uMGTnor1VpDfQRzRPHbzpmu2bn5BOs4kxHHV4aBeQ';
    final url = 'https://api.pexels.com/v1/search?query=$query&per_page=1';

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': apiKey,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final photos = data['photos'];
      if (photos != null && photos.isNotEmpty) {
        return photos[0]['src']['medium'];
      }
    }
    return null;
  }

  Future<void> _fetchFood(String query) async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = 'RFg02f11eBdfkEpSXMRQ7CuWnuEIxIGZgB5GZldk';
    final url =
        'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey&query=$query&pageSize=25';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> foods = data['foods'];

      final Map<String, dynamic> uniqueMap = {};

      for (var food in foods) {
        final name = food['description'] ?? 'Unknown Product';
        final brand = food['brandOwner'];
        final ingredients = food['ingredients'];

        String displayName = name;
        if (brand != null && brand.toString().isNotEmpty) {
          displayName = '$name ($brand)';
        } else if (ingredients != null &&
            ingredients.toString().length < 50) {
          displayName = '$name - ${ingredients.toString().split(',').first}';
        }

        if (!uniqueMap.containsKey(displayName)) {
          food['displayName'] = displayName;
          uniqueMap[displayName] = food;
        }
      }

      setState(() {
        _foods = uniqueMap.values.toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caloric Content of Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (value) {
                _searchTerm = value;
                _fetchFood(value);
              },
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_foods.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Use the search above to find a food item.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _foods.length,
                itemBuilder: (context, index) {
                  final food = _foods[index];
                  final displayName = food['displayName'];
                  final name = food['description'] ?? 'Unknown Product';
                  final nutrients = food['foodNutrients'] ?? [];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            name: displayName,
                            nutrients: nutrients,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        leading: FutureBuilder<String?>(
                          future: _fetchImage(displayName),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            } else if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: snapshot.data!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.broken_image),
                                ),
                              );
                            } else {
                              return Icon(Icons.image_not_supported);
                            }
                          },
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
