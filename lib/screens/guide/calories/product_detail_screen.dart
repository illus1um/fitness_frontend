import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatelessWidget {
  final String name;
  final List nutrients;
  final String? imageUrl;

  const ProductDetailScreen({
    Key? key,
    required this.name,
    required this.nutrients,
    this.imageUrl,
  }) : super(key: key);

  String getNutrient(String label) {
    final nutrient = nutrients.firstWhere(
      (n) => n['nutrientName'].toString().toLowerCase() == label.toLowerCase(),
      orElse: () => null,
    );
    if (nutrient == null || nutrient['value'] == null) return '—';
    return '${nutrient['value']} ${nutrient['unitName'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (imageUrl != null)
            Container(
              margin: EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: screenWidth * 0.5,
                  height: screenWidth * 0.5,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (context, url) => Container(
                    width: screenWidth * 0.5,
                    height: screenWidth * 0.5,
                    color: isDarkMode ? Color(0xFF333333) : Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: screenWidth * 0.5,
                    height: screenWidth * 0.5,
                    color: isDarkMode ? Color(0xFF333333) : Colors.grey.shade200,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),

          // Nutritional Information Header
          Container(
            margin: EdgeInsets.only(bottom: 16.0),
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: isDarkMode ? 0 : 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Color(0xFF3A3225)
                        : goldColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: goldColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Nutritional Information\n(per 100g)",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nutrients List
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: isDarkMode ? 0 : 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildNutrientTile("Energy (Calories)", getNutrient('Energy'), isDarkMode, goldColor, true),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Protein", getNutrient('Protein'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Fat", getNutrient('Total lipid (fat)'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Carbohydrates", getNutrient('Carbohydrate, by difference'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Fiber", getNutrient('Fiber, total dietary'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Calcium", getNutrient('Calcium, Ca'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Iron", getNutrient('Iron, Fe'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Potassium", getNutrient('Potassium, K'), isDarkMode, goldColor),
                _buildDivider(isDarkMode),
                _buildNutrientTile("Sodium", getNutrient('Sodium, Na'), isDarkMode, goldColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientTile(String label, String value, bool isDarkMode, Color goldColor, [bool isHighlighted = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted
                  ? goldColor
                  : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800),
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isHighlighted ? 18 : 16,
              color: isHighlighted
                  ? goldColor
                  : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
      height: 1,
      thickness: 0.5,
    );
  }
}
