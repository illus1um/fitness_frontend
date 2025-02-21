import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  final List<Map<String, String>> guides = [
    {"title": "Exercises", "image": "assets/images/exercises.jpg"},
    {"title": "Sports Nutrition", "image": "assets/images/nutrition.jpg"},
    {"title": "Caloric content of products", "image": "assets/images/calories.jpg"},
    {"title": "Encyclopedia", "image": "assets/images/encyclopedia.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guide"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: guides.length,
          separatorBuilder: (context, index) => SizedBox(height: 20),
          itemBuilder: (context, index) {
            final guide = guides[index];
            return _buildGuideCard(guide["title"]!, guide["image"]!);
          },
        ),
      ),
    );
  }

  Widget _buildGuideCard(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        // TODO: Добавить логику перехода на соответствующую страницу
      },
      child: Container(
        width: double.infinity, // Карточка на всю ширину
        height: 120, // Увеличенная высота для лучшего отображения
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 219, 200, 173),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Текст
            Expanded(
              flex: 1, // Текст занимает 50% ширины
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ),
            ),

            // Картинка (теперь занимает ровно 50%)
            Expanded(
              flex: 1, // Картинка занимает 50% ширины
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover, // Заполняет 50% карточки без искажений
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
