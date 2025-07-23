import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_localizations.dart';
import '../loan/loan_request_screen.dart';
import '../loan/transaction_history_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.user != null && authProvider.token != null) {
      await loanProvider.fetchBanks();
      await loanProvider.fetchCompanies();
      await loanProvider.fetchUserLoans(authProvider.user!.id, authProvider.token!);
      await loanProvider.fetchCreditLimits(authProvider.user!.id, authProvider.token!);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Provider.of<LanguageProvider>(context).isRTL;

    final List<Widget> screens = [
      const DashboardHome(),
      const LoanRequestScreen(),
      const TransactionHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard),
            label: localizations.translate('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.request_page),
            label: localizations.translate('loan_request'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: localizations.translate('transaction_history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: localizations.translate('profile'),
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final loanProvider = Provider.of<LoanProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final pendingLoans = loanProvider.loans.where((loan) => 
      loan.status.toLowerCase() == 'pending').length;
    final approvedLoans = loanProvider.loans.where((loan) => 
      loan.status.toLowerCase() == 'approved').length;

    return RefreshIndicator(
      onRefresh: () async {
        if (authProvider.user != null && authProvider.token != null) {
          await loanProvider.fetchUserLoans(
            authProvider.user!.id, 
            authProvider.token!
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations.translate('welcome)}, ${authProvider.user?.fullName ?? ''}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.pending, size: 40, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text(
                            pendingLoans.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(localizations.translate('pending')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, size: 40, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(
                            approvedLoans.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(localizations.translate('approved')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              localizations.translate('credit_limit'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (loanProvider.creditLimits.isEmpty)
              const Center(
                child: Text('No credit limits available'),
              )
            else
              ...loanProvider.creditLimits.map((limit) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '${loanProvider.banks.firstWhere((b) => b.id == limit.bankId).name} - '
                    '${loanProvider.companies.firstWhere((c) => c.id == limit.companyId).name}'
                  ),
                  subtitle: Text(
                    '${localizations.translate('available_credit')}: \$${limit.availableLimit.toStringAsFixed(2)}'
                  ),
                  trailing: Text(
                    '\$${limit.totalLimit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
