import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../utils/app_localizations.dart';

class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedBankId;
  String? _selectedCompanyId;
  int _durationMonths = 12;

  @override
  void initState() {
    super.initState();
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    if (loanProvider.banks.isEmpty) {
      loanProvider.fetchBanks();
    }
    if (loanProvider.companies.isEmpty) {
      loanProvider.fetchCompanies();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitLoanRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    final amount = double.parse(_amountController.text);
    final availableCredit = loanProvider.getAvailableCredit(
      _selectedBankId!,
      _selectedCompanyId!,
    );

    if (amount > availableCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds available credit limit of \$${availableCredit.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await loanProvider.submitLoanRequest(
      userId: authProvider.user!.id,
      bankId: _selectedBankId!,
      companyId: _selectedCompanyId!,
      amount: amount,
      durationMonths: _durationMonths,
      token: authProvider.token!,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      _amountController.clear();
      setState(() {
        _selectedBankId = null;
        _selectedCompanyId = null;
        _durationMonths = 12;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final loanProvider = Provider.of<LoanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('loan_request')),
      ),
      body: loanProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedBankId,
                      decoration: InputDecoration(
                        labelText: localizations.translate('select_bank'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: loanProvider.banks
                          .where((bank) => bank.isActive)
                          .map((bank) => DropdownMenuItem(
                                value: bank.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(bank.logo),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(bank.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBankId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a bank';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCompanyId,
                      decoration: InputDecoration(
                        labelText: localizations.translate('select_company'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: loanProvider.companies
                          .where((company) => company.isActive)
                          .map((company) => DropdownMenuItem(
                                value: company.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(company.logo),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(company.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCompanyId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a company';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizations.translate('loan_amount'),
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter loan amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _durationMonths,
                      decoration: InputDecoration(
                        labelText: 'Duration (months)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [6, 12, 18, 24, 36, 48]
                          .map((months) => DropdownMenuItem(
                                value: months,
                                child: Text('$months months'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _durationMonths = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_selectedBankId != null && _selectedCompanyId != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Credit',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${loanProvider.getAvailableCredit(_selectedBankId!, _selectedCompanyId!).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ElevatedButton(
                      onPressed: _submitLoanRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        localizations.translate('submit_request'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
