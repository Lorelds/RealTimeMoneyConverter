import 'package:flutter/foundation.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  double rateToUsd; 
  final int decimalDigits;

  CurrencyInfo(this.code, this.name, this.symbol, this.rateToUsd, {this.decimalDigits = 2});
}

class CurrencyConverter {

  static final Map<String, CurrencyInfo> currencies = {
    'USD': CurrencyInfo('USD', 'United States Dollar', '\$', 1.0),
    'EUR': CurrencyInfo('EUR', 'Euro', '€', 0.92),
    'JPY': CurrencyInfo('JPY', 'Japanese Yen', '¥', 150.0, decimalDigits: 0),
    'GBP': CurrencyInfo('GBP', 'British Pound', '£', 0.79),
    'AUD': CurrencyInfo('AUD', 'Australian Dollar', 'A\$', 1.53),
    'CAD': CurrencyInfo('CAD', 'Canadian Dollar', 'C\$', 1.36),
    'CHF': CurrencyInfo('CHF', 'Swiss Franc', 'CHF', 0.90),
    'CNY': CurrencyInfo('CNY', 'Chinese Yuan', '¥', 7.24),
    'HKD': CurrencyInfo('HKD', 'Hong Kong Dollar', 'HK\$', 7.82),
    'NZD': CurrencyInfo('NZD', 'New Zealand Dollar', 'NZ\$', 1.66),
    'SEK': CurrencyInfo('SEK', 'Swedish Krona', 'kr', 10.82),
    'KRW': CurrencyInfo('KRW', 'South Korean Won', '₩', 1370.0, decimalDigits: 0),
    'SGD': CurrencyInfo('SGD', 'Singapore Dollar', 'S\$', 1.35),
    'NOK': CurrencyInfo('NOK', 'Norwegian Krone', 'kr', 10.96),
    'MXN': CurrencyInfo('MXN', 'Mexican Peso', '\$', 16.90),
    'INR': CurrencyInfo('INR', 'Indian Rupee', '₹', 83.50),
    'RUB': CurrencyInfo('RUB', 'Russian Ruble', '₽', 91.0),
    'ZAR': CurrencyInfo('ZAR', 'South African Rand', 'R', 18.50),
    'TRY': CurrencyInfo('TRY', 'Turkish Lira', '₺', 32.20),
    'BRL': CurrencyInfo('BRL', 'Brazilian Real', 'R\$', 5.15),
    'TWD': CurrencyInfo('TWD', 'New Taiwan Dollar', 'NT\$', 32.40),
    'DKK': CurrencyInfo('DKK', 'Danish Krone', 'kr', 6.95),
    'PLN': CurrencyInfo('PLN', 'Polish Zloty', 'zł', 4.02),
    'THB': CurrencyInfo('THB', 'Thai Baht', '฿', 36.80),
    'IDR': CurrencyInfo('IDR', 'Indonesian Rupiah', 'Rp', 16000.0, decimalDigits: 0),
    'VND': CurrencyInfo('VND', 'Vietnamese Dong', '₫', 25400.0, decimalDigits: 0),
    'MYR': CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM', 4.74),
    'PHP': CurrencyInfo('PHP', 'Philippine Peso', '₱', 57.50),
    'AED': CurrencyInfo('AED', 'UAE Dirham', 'د.إ', 3.67),
    'SAR': CurrencyInfo('SAR', 'Saudi Riyal', '﷼', 3.75),
    'ILS': CurrencyInfo('ILS', 'Israeli New Shekel', '₪', 3.72),
    'CLP': CurrencyInfo('CLP', 'Chilean Peso', '\$', 930.0, decimalDigits: 0),
    'COP': CurrencyInfo('COP', 'Colombian Peso', '\$', 3900.0, decimalDigits: 0),
  };

  static String? convertPrice(
    String text,
    CurrencyInfo sourceCurrency,
    CurrencyInfo targetCurrency,
    double exchangeRate,
    bool isStrictMode,
  ) {

    final regex = RegExp(r'(\d+([.,]\d+)?)');
    final match = regex.firstMatch(text);

    if (match != null) {

      final numberString = match.group(0)!.replaceAll(',', '');
      final number = double.tryParse(numberString);

      if (number != null) {
        final lowerText = text.toLowerCase();
        final lowerSymbol = sourceCurrency.symbol.toLowerCase();
        final lowerCode = sourceCurrency.code.toLowerCase();

        final hasSymbol = lowerText.contains(lowerSymbol) || 
                          lowerText.contains(lowerCode) || 
                          lowerText.contains('\$') || 
                          lowerText.contains('€') || 
                          lowerText.contains('¥') ||
                          lowerText.contains('rp');

        final isValid = isStrictMode ? hasSymbol : (hasSymbol || number > 9);

        if (isValid) {

          final converted = number * exchangeRate;

          if (targetCurrency.decimalDigits == 0) {
             final formatted = converted.toStringAsFixed(0).replaceAllMapped(
               RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
               (Match m) => '${m[1]},'
             );
             return '${targetCurrency.symbol}$formatted';
          } else {
             final formatted = converted.toStringAsFixed(targetCurrency.decimalDigits);
             return '${targetCurrency.symbol}$formatted';
          }
        }
      }
    }
    return null;
  }
}

