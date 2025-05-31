// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    final apiKey = dotenv.env['PEXELS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('Warning: PEXELS_API_KEY not found in environment variables');
      return null;
    }

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

    final apiKey = dotenv.env['USDA_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('Warning: USDA_API_KEY not found in environment variables');
      setState(() {
        _isLoading = false;
      });
      return;
    }

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Caloric Content of Products'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search product...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: goldColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onSubmitted: (value) {
                _searchTerm = value;
                _fetchFood(value);
              },
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(goldColor),
              ),
            )
          else if (_foods.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Use the search above to find a food item.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
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

                  return FutureBuilder<String?>(
                    future: _fetchImage(displayName),
                    builder: (context, snapshot) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                name: displayName,
                                nutrients: nutrients,
                                imageUrl: snapshot.data,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 3,
                          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                          shadowColor: isDarkMode 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            leading: snapshot.connectionState == ConnectionState.waiting
                                ? SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: snapshot.hasData
                                        ? CachedNetworkImage(
                                            imageUrl: snapshot.data!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 50,
                                              height: 50,
                                              color: isDarkMode ? Color(0xFF333333) : Colors.grey.shade200,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              width: 50,
                                              height: 50,
                                              color: isDarkMode ? Color(0xFF333333) : Colors.grey.shade200,
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            color: isDarkMode ? Color(0xFF333333) : Colors.grey.shade200,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                            ),
                                          ),
                                  ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            trailing: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? Color(0xFF3A3225)
                                    : goldColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: goldColor,
                              ),
                            ),
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
    );
  }
}
