import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  Future<void> _completeIntroduction(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('introduction_completed', true);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Bienvenido a NutriCalendar",
          body: "Tu aplicación completa para gestionar recetas saludables y planificar tus comidas semanales.",
          image: Center(
            child: Image.asset(
              'assets/image/1.jpg',
              height: 300,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: TextStyle(fontSize: 18),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
        PageViewModel(
          title: "Gestiona tus Recetas",
          body: "Crea, edita y organiza tus recetas favoritas. Sube imágenes, añade ingredientes y pasos de preparación.",
          image: Center(
            child: Image.asset(
              'assets/image/2.jpg',
              height: 300,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: TextStyle(fontSize: 18),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
        PageViewModel(
          title: "Escanea Productos",
          body: "Utiliza el escáner de códigos de barras para obtener información nutricional de productos al instante.",
          image: Center(
            child: Image.asset(
              'assets/image/3.jpg',
              height: 300,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: TextStyle(fontSize: 18),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
        PageViewModel(
          title: "Planifica tu Semana",
          body: "Organiza tus comidas en el calendario semanal y mantén un control de tu alimentación.",
          image: Center(
            child: Image.asset(
              'assets/image/4.jpg',
              height: 300,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: TextStyle(fontSize: 18),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
        PageViewModel(
          title: "¡Comienza Ahora!",
          body: "Crea tu cuenta y empieza a disfrutar de una alimentación más organizada y saludable.",
          image: Center(
            child: Icon(
              Icons.check_circle,
              size: 200,
              color: Colors.green[700],
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: TextStyle(fontSize: 18),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
      ],
      onDone: () => _completeIntroduction(context),
      onSkip: () => _completeIntroduction(context),
      showSkipButton: true,
      skip: const Text('Saltar', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Comenzar', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Colors.green[700]!,
        color: Colors.grey,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
