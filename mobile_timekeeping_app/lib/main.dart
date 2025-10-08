import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// If you run `flutterfire configure`, this file will be generated.
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // If using FlutterFire CLI generated options, prefer the generated options:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
  } catch (e) {
    // Safe to proceed without Firebase in pure UI/dev flows.
    debugPrint('Firebase init skipped/failed: $e');
  }
  runApp(const MobileTimekeepingApp());
}

class MobileTimekeepingApp extends StatelessWidget {
  const MobileTimekeepingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Timekeeping',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Timekeeping')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Роль сонгох', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manager'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManagerHomeScreen()),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.engineering),
              label: const Text('Worker'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _NavTile(title: 'Ажилчин бүртгэх', icon: Icons.person_add_alt_1),
          _NavTile(title: 'Цагийн бүртгэл (list)', icon: Icons.schedule),
          _NavTile(title: 'Чөлөөний хүсэлт батлах', icon: Icons.approval),
          _NavTile(title: 'Ажлын хэсгийн сектор (map)', icon: Icons.map),
          Divider(),
          _NavTile(title: 'Chat system', icon: Icons.chat_bubble_outline),
          _NavTile(title: 'Тайлан (7 хоног, Excel)', icon: Icons.summarize),
        ],
      ),
    );
  }
}

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _NavTile(title: 'Ирсэн/Явсан цаг бүртгэх', icon: Icons.punch_clock_outlined),
          _NavTile(title: 'Чөлөөний хүсэлт', icon: Icons.beach_access_outlined),
          Divider(),
          _NavTile(title: 'Chat system', icon: Icons.chat_bubble_outline),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$title" - placeholder screen')),
        ),
      ),
    );
  }
}
