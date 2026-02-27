import '../repositories/investor_repository.dart';
import '../repositories/transaction_repository.dart';

/// Service for generating and "sending" investor email reports.
/// In production use a real SMTP package (mailer, sendgrid_mailer, etc.).
/// For now we build the report payload and log it.
class EmailReportService {
  final InvestorRepository _investorRepo;
  final TransactionRepository _transactionRepo;

  EmailReportService({
    required InvestorRepository investorRepo,
    required TransactionRepository transactionRepo,
  })  : _investorRepo = investorRepo,
        _transactionRepo = transactionRepo;

  /// Generate a monthly investor report for the given month.
  Future<Map<String, dynamic>> generateInvestorReport({
    required int year,
    required int month,
  }) async {
    // Get all investors
    final investorsData = await _investorRepo.findAll(limit: 1000);
    final investors = investorsData['items'] as List<dynamic>;

    // Get the monthly financial summary
    final financeSummary =
        await _transactionRepo.getMonthlyReport(year, month);

    // Get portfolio summary
    final portfolio = await _investorRepo.getPortfolioSummary();

    final reports = <Map<String, dynamic>>[];

    for (final investor in investors) {
      final inv = investor as Map<String, dynamic>;
      final report = {
        'investorId': inv['id'],
        'investorName': inv['fullName'],
        'email': inv['email'],
        'company': inv['company'],
        'totalInvested': inv['totalInvested'],
        'expectedReturn': inv['expectedReturn'],
        'projectName': inv['projectName'],
        'reportPeriod': '$year-${month.toString().padLeft(2, '0')}',
        'financialSummary': {
          'totalIncome': financeSummary['income'],
          'totalExpense': financeSummary['expense'],
          'netResult': financeSummary['net'],
          'treasury': financeSummary['treasury'],
        },
        'portfolioOverview': {
          'totalInvestors': portfolio['investorCount'],
          'totalPortfolioValue': portfolio['totalInvested'],
          'actualReturns': portfolio['actualReturns'],
        },
      };
      reports.add(report);
    }

    // In a real system, we would send emails here.
    // For now, log and return the payload.
    print('[EmailReportService] Generated ${reports.length} '
        'investor reports for $year-$month');

    return {
      'success': true,
      'period': '$year-${month.toString().padLeft(2, '0')}',
      'reportsGenerated': reports.length,
      'reports': reports,
    };
  }

  /// Preview a report for a single investor (no send).
  Future<Map<String, dynamic>> previewReport({
    required String investorId,
    required int year,
    required int month,
  }) async {
    final investor = await _investorRepo.findById(investorId);
    if (investor == null) {
      throw Exception('Investisseur introuvable');
    }

    final financeSummary =
        await _transactionRepo.getMonthlyReport(year, month);
    final portfolio = await _investorRepo.getPortfolioSummary();

    return {
      'investorId': investor['id'],
      'investorName': investor['fullName'],
      'email': investor['email'],
      'company': investor['company'],
      'totalInvested': investor['totalInvested'],
      'expectedReturn': investor['expectedReturn'],
      'projectName': investor['projectName'],
      'reportPeriod': '$year-${month.toString().padLeft(2, '0')}',
      'financialSummary': {
        'totalIncome': financeSummary['income'],
        'totalExpense': financeSummary['expense'],
        'netResult': financeSummary['net'],
        'treasury': financeSummary['treasury'],
      },
      'portfolioOverview': {
        'totalInvestors': portfolio['investorCount'],
        'totalPortfolioValue': portfolio['totalInvested'],
        'actualReturns': portfolio['actualReturns'],
      },
    };
  }
}
