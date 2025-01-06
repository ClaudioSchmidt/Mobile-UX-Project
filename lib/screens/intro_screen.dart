import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ScrollController für SingleChildScrollView und Scrollbar
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true, // Scrollbalken immer sichtbar
          controller: scrollController, // Verknüpfe Scrollbar mit Controller
          child: SingleChildScrollView(
            controller: scrollController, // Verknüpfe SingleChildScrollView mit Controller
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Abschnitt 1: App-Name u& Begrüßung
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF6200EE),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 100,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to Talkio',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your gateway to connecting, chatting, learing new languages with new people!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Abschnitt 2: App-Sinn
                _buildFeatureSection(
                  title: 'What is Talkio?',
                  description:
                      'Talkio is a platform where you can practice languages, meet new people, and connect globally.',
                ),
                // Abschnitt 3: Features
                _buildFeatureSection(
                  title: 'Like Profiles',
                  description:
                      'Mark profiles you like and help us find better matches for you. Feedback ensures quality!',
                ),
                _buildFeatureSection(
                  title: 'Matchmaking',
                  description:
                      'Use our smart matchmaking system to find partners automatically or manually.',
                ),
               
                // Abschnitt 4: Anmeldung und Call-to-Action
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF3700B3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Get Started with Talkio',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text(
                          'Don’t have an account? Register',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helferfunktion für Features ohne Bilder
  Widget _buildFeatureSection({required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF6200EE), // Hintergrundfarbe für Sektionen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Titel in weiß
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70, // Beschreibung in weiß
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
