import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../utils/app_localizations.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.user != null && authProvider.token != null) {
      await loanProvider.fetchUserLoans(
        authProvider.user!.id,
        authProvider.token!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final loanProvider = Provider.of<LoanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('transaction_history')),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: loanProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : loanProvider.loans.isEmpty
                ? Center(
                    child: Text(localizations.translate('no_transactions')),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: loanProvider.loans.length,
                    itemBuilder: (context, index) {
                      final loan = loanProvider.loans[index];
                      final bank = loanProvider.banks.firstWhere(
                        (b) => b.id == loan.bankId,
                        orElse: () => loanProvider.banks.first,
                      );
                      final company = loanProvider.companies.firstWhere(
                        (c) => c.id == loan.companyId,
                        orElse: () => loanProvider.companies.first,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: loan.statusColor.withOpacity(0.2),
                            child: Icon(
                              _getStatusIcon(loan.status),
                              color: loan.statusColor,
                            ),
                          ),
                          title: Text(
                            '${bank.name} - ${company.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${localizations.translate('amount')}: \$${loan.amount.toStringAsFixed(2)}',
                              ),
                              Text(
                                '${localizations.translate('date')}: ${_formatDate(loan.requestDate)}',
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: loan.statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              localizations.translate(loan.status.toLowerCase()),
                              style: TextStyle(
                                color: loan.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            _showLoanDetails(context, loan, bank, company);
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'processing':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLoanDetails(
    BuildContext context,
    loan,
    bank,
    company,
  ) {
    final localizations = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${localizations.translate('transaction_id')}: ${loan.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${localizations.translate('bank')}: ${bank.name}'),
              Text('${localizations.translate('company')}: ${company.name}'),
              Text('${localizations.translate('amount')}: \$${loan.amount.toStringAsFixed(2)}'),
              Text('${localizations.translate('status')}: ${localizations.translate(loan.status.toLowerCase())}'),
              if (loan.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Rejection Reason: ${loan.rejectionReason}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
