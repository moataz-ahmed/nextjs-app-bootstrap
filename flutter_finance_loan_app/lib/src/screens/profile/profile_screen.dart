import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.user?.fullName ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.user?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(localizations.translate('language')),
                    trailing: DropdownButton<String>(
                      value: languageProvider.currentLanguage,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(localizations.translate('english')),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(localizations.translate('arabic')),
                        ),
                        DropdownMenuItem(
                          value: 'ku',
                          child: Text(localizations.translate('kurdish')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          languageProvider.changeLanguage(value);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone Number'),
                    subtitle: Text(authProvider.user?.phoneNumber ?? 'Not provided'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Member Since'),
                    subtitle: Text(
                      '${authProvider.user?.createdAt.day}/${authProvider.user?.createdAt.month}/${authProvider.user?.createdAt.year}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(localizations.translate('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
