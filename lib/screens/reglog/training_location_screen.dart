import 'package:flutter/material.dart';
import 'package:fitness_app/models/registration_data.dart';
import 'training_experience_screen.dart';

class TrainingLocationScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const TrainingLocationScreen({Key? key, required this.registrationData}) : super(key: key);

  @override
  _TrainingLocationScreenState createState() => _TrainingLocationScreenState();
}

class _TrainingLocationScreenState extends State<TrainingLocationScreen> {
  final List<Map<String, String>> locations = [
    {"name": "At home", "image": "assets/images/home.jpg"},
    {"name": "In the gym", "image": "assets/images/gym.jpg"},
  ];

  void setTrainingLocation(String location) {
    widget.registrationData.location = location;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingExperienceScreen(registrationData: widget.registrationData),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(255),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 🔹 Центрируем весь Column
          children: [
            Center( // 🔹 Центрируем заголовок
              child: Text(
                "Where to train?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            SizedBox(height: 40),

            Expanded(
              child: ListView.separated(
                itemCount: locations.length,
                separatorBuilder: (context, index) => SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return _buildLocationCard(location["name"]!, location["image"]!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLocationCard(String name, String imagePath) {
  return GestureDetector(
    onTap: () => setTrainingLocation(name),
    child: Container(
      height: 60, // 🔹 Фиксируем высоту карточки
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 219, 200, 173),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 Текстовое описание
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ),
          ),

          // 🔹 Исправленное изображение
          ClipRRect(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              width: 100, // 🔹 Устанавливаем фиксированную ширину
              height: 60, // 🔹 Совпадает с высотой карточки
              fit: BoxFit.cover, // 🔹 Заполняет область, не искажая изображение
            ),
          ),
        ],
      ),
    ),
  );
}

}
