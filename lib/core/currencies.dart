/// Nombre de décimales (exposant) par devise. Montants stockés en entiers.
const Map<String, int> kExponent = {
  'MGA': 0,
  'XOF': 0,
  'XAF': 0,
  'RWF': 0,
  'UGX': 0,
  'KES': 2,
  'NGN': 2,
  'GHS': 2,
  'MAD': 2,
  'TND': 2,
  'EUR': 2,
  'USD': 2,
  'GBP': 2,
  'INR': 2,
  'PHP': 2,
};

const Map<String, String> kSymbol = {
  'MGA': 'Ar',
  'EUR': '€',
  'USD': '\$',
  'GBP': '£',
  'XOF': 'FCFA',
  'XAF': 'FCFA',
};

int exponentOf(String currency) => kExponent[currency] ?? 2;

String symbolOf(String currency) => kSymbol[currency] ?? currency;

List<String> get kSupportedCurrencies => kExponent.keys.toList();
