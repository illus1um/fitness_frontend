import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Image.network(
                      imageUrl!,
                      width: width,
                      height: width,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

          Text(
            "Nutritional Information (per 100g):",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildNutrientTile("Energy (Calories)", getNutrient('Energy')),
          _buildNutrientTile("Protein", getNutrient('Protein')),
          _buildNutrientTile("Fat", getNutrient('Total lipid (fat)')),
          _buildNutrientTile("Carbohydrates", getNutrient('Carbohydrate, by difference')),
          _buildNutrientTile("Fiber", getNutrient('Fiber, total dietary')),
          _buildNutrientTile("Calcium", getNutrient('Calcium, Ca')),
          _buildNutrientTile("Iron", getNutrient('Iron, Fe')),
          _buildNutrientTile("Potassium", getNutrient('Potassium, K')),
          _buildNutrientTile("Sodium", getNutrient('Sodium, Na')),
        ],
      ),
    );
  }

  Widget _buildNutrientTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
