/// Devises supportées. Les montants sont stockés en unités mineures (entiers).
/// L'exposant donne le nombre de décimales : 0 (MGA, JPY), 2 (EUR), 3 (KWD).
class CurrencyInfo {
  final String code;
  final int exponent;
  final String symbol;
  final String nameFr;
  final String nameEn;

  const CurrencyInfo(
      this.code, this.exponent, this.symbol, this.nameFr, this.nameEn);
}

const List<CurrencyInfo> kCurrencies = [
  // ---- Afrique ----
  CurrencyInfo('MGA', 0, 'Ar', 'Ariary malgache', 'Malagasy ariary'),
  CurrencyInfo('XOF', 0, 'FCFA', "Franc CFA (Afrique de l'Ouest)",
      'West African CFA franc'),
  CurrencyInfo('XAF', 0, 'FCFA', 'Franc CFA (Afrique centrale)',
      'Central African CFA franc'),
  CurrencyInfo('KMF', 0, 'CF', 'Franc comorien', 'Comorian franc'),
  CurrencyInfo('MUR', 2, 'Rs', 'Roupie mauricienne', 'Mauritian rupee'),
  CurrencyInfo('SCR', 2, 'SCR', 'Roupie seychelloise', 'Seychellois rupee'),
  CurrencyInfo('KES', 2, 'KSh', 'Shilling kényan', 'Kenyan shilling'),
  CurrencyInfo('TZS', 2, 'TSh', 'Shilling tanzanien', 'Tanzanian shilling'),
  CurrencyInfo('UGX', 0, 'USh', 'Shilling ougandais', 'Ugandan shilling'),
  CurrencyInfo('RWF', 0, 'FRw', 'Franc rwandais', 'Rwandan franc'),
  CurrencyInfo('BIF', 0, 'FBu', 'Franc burundais', 'Burundian franc'),
  CurrencyInfo('CDF', 2, 'FC', 'Franc congolais', 'Congolese franc'),
  CurrencyInfo('DJF', 0, 'Fdj', 'Franc djiboutien', 'Djiboutian franc'),
  CurrencyInfo('ETB', 2, 'Br', 'Birr éthiopien', 'Ethiopian birr'),
  CurrencyInfo('NGN', 2, '₦', 'Naira nigérian', 'Nigerian naira'),
  CurrencyInfo('GHS', 2, 'GH₵', 'Cedi ghanéen', 'Ghanaian cedi'),
  CurrencyInfo('ZAR', 2, 'R', 'Rand sud-africain', 'South African rand'),
  CurrencyInfo('ZMW', 2, 'ZK', 'Kwacha zambien', 'Zambian kwacha'),
  CurrencyInfo('MZN', 2, 'MT', 'Metical mozambicain', 'Mozambican metical'),
  CurrencyInfo('BWP', 2, 'P', 'Pula botswanais', 'Botswana pula'),
  CurrencyInfo('MAD', 2, 'DH', 'Dirham marocain', 'Moroccan dirham'),
  CurrencyInfo('DZD', 2, 'DA', 'Dinar algérien', 'Algerian dinar'),
  CurrencyInfo('TND', 3, 'DT', 'Dinar tunisien', 'Tunisian dinar'),
  CurrencyInfo('EGP', 2, 'E£', 'Livre égyptienne', 'Egyptian pound'),
  // ---- Europe ----
  CurrencyInfo('EUR', 2, '€', 'Euro', 'Euro'),
  CurrencyInfo('GBP', 2, '£', 'Livre sterling', 'Pound sterling'),
  CurrencyInfo('CHF', 2, 'CHF', 'Franc suisse', 'Swiss franc'),
  CurrencyInfo('SEK', 2, 'SEK', 'Couronne suédoise', 'Swedish krona'),
  CurrencyInfo('NOK', 2, 'NOK', 'Couronne norvégienne', 'Norwegian krone'),
  CurrencyInfo('DKK', 2, 'DKK', 'Couronne danoise', 'Danish krone'),
  CurrencyInfo('PLN', 2, 'zł', 'Zloty polonais', 'Polish zloty'),
  CurrencyInfo('CZK', 2, 'Kč', 'Couronne tchèque', 'Czech koruna'),
  CurrencyInfo('HUF', 2, 'Ft', 'Forint hongrois', 'Hungarian forint'),
  CurrencyInfo('RON', 2, 'lei', 'Leu roumain', 'Romanian leu'),
  CurrencyInfo('TRY', 2, '₺', 'Livre turque', 'Turkish lira'),
  CurrencyInfo('UAH', 2, '₴', 'Hryvnia ukrainienne', 'Ukrainian hryvnia'),
  CurrencyInfo('RUB', 2, '₽', 'Rouble russe', 'Russian ruble'),
  // ---- Amériques ----
  CurrencyInfo('USD', 2, '\$', 'Dollar américain', 'US dollar'),
  CurrencyInfo('CAD', 2, 'CA\$', 'Dollar canadien', 'Canadian dollar'),
  CurrencyInfo('MXN', 2, 'MX\$', 'Peso mexicain', 'Mexican peso'),
  CurrencyInfo('BRL', 2, 'R\$', 'Réal brésilien', 'Brazilian real'),
  CurrencyInfo('ARS', 2, 'AR\$', 'Peso argentin', 'Argentine peso'),
  CurrencyInfo('CLP', 0, 'CL\$', 'Peso chilien', 'Chilean peso'),
  CurrencyInfo('COP', 2, 'CO\$', 'Peso colombien', 'Colombian peso'),
  CurrencyInfo('PEN', 2, 'S/', 'Sol péruvien', 'Peruvian sol'),
  CurrencyInfo('HTG', 2, 'G', 'Gourde haïtienne', 'Haitian gourde'),
  // ---- Asie et Moyen-Orient ----
  CurrencyInfo('INR', 2, '₹', 'Roupie indienne', 'Indian rupee'),
  CurrencyInfo('PKR', 2, 'Rs', 'Roupie pakistanaise', 'Pakistani rupee'),
  CurrencyInfo('BDT', 2, '৳', 'Taka bangladais', 'Bangladeshi taka'),
  CurrencyInfo('LKR', 2, 'Rs', 'Roupie sri-lankaise', 'Sri Lankan rupee'),
  CurrencyInfo('CNY', 2, 'CN¥', 'Yuan chinois', 'Chinese yuan'),
  CurrencyInfo('JPY', 0, '¥', 'Yen japonais', 'Japanese yen'),
  CurrencyInfo('KRW', 0, '₩', 'Won sud-coréen', 'South Korean won'),
  CurrencyInfo('IDR', 2, 'Rp', 'Roupie indonésienne', 'Indonesian rupiah'),
  CurrencyInfo('PHP', 2, '₱', 'Peso philippin', 'Philippine peso'),
  CurrencyInfo('THB', 2, '฿', 'Baht thaïlandais', 'Thai baht'),
  CurrencyInfo('VND', 0, '₫', 'Dong vietnamien', 'Vietnamese dong'),
  CurrencyInfo('MYR', 2, 'RM', 'Ringgit malaisien', 'Malaysian ringgit'),
  CurrencyInfo('SGD', 2, 'S\$', 'Dollar de Singapour', 'Singapore dollar'),
  CurrencyInfo('HKD', 2, 'HK\$', 'Dollar de Hong Kong', 'Hong Kong dollar'),
  CurrencyInfo('AED', 2, 'AED', 'Dirham des Émirats', 'UAE dirham'),
  CurrencyInfo('SAR', 2, 'SAR', 'Riyal saoudien', 'Saudi riyal'),
  CurrencyInfo('QAR', 2, 'QAR', 'Riyal qatari', 'Qatari riyal'),
  CurrencyInfo('KWD', 3, 'KD', 'Dinar koweïtien', 'Kuwaiti dinar'),
  CurrencyInfo('ILS', 2, '₪', 'Shekel israélien', 'Israeli shekel'),
  // ---- Océanie ----
  CurrencyInfo('AUD', 2, 'A\$', 'Dollar australien', 'Australian dollar'),
  CurrencyInfo('NZD', 2, 'NZ\$', 'Dollar néo-zélandais', 'New Zealand dollar'),
];

final Map<String, CurrencyInfo> _byCode = {
  for (final c in kCurrencies) c.code: c,
};

/// Nombre de décimales de [currency] (2 par défaut si inconnue).
int exponentOf(String currency) => _byCode[currency]?.exponent ?? 2;

/// Symbole affiché ; le code ISO si la devise est inconnue.
String symbolOf(String currency) => _byCode[currency]?.symbol ?? currency;

List<String> get kSupportedCurrencies =>
    kCurrencies.map((c) => c.code).toList();

String currencyName(String code, String lang) {
  final c = _byCode[code];
  if (c == null) return code;
  return lang == 'fr' ? c.nameFr : c.nameEn;
}

String currencyLabel(String code, String lang) =>
    '$code · ${currencyName(code, lang)}';

/// Devise la plus probable pour un code pays ISO (ex. 'MG' -> 'MGA').
const Map<String, String> kCountryCurrency = {
  // Afrique
  'MG': 'MGA', 'SN': 'XOF', 'CI': 'XOF', 'ML': 'XOF', 'BF': 'XOF',
  'BJ': 'XOF', 'TG': 'XOF', 'NE': 'XOF', 'CM': 'XAF', 'GA': 'XAF',
  'CG': 'XAF', 'TD': 'XAF', 'KM': 'KMF', 'MU': 'MUR', 'SC': 'SCR',
  'KE': 'KES', 'TZ': 'TZS', 'UG': 'UGX', 'RW': 'RWF', 'BI': 'BIF',
  'CD': 'CDF', 'DJ': 'DJF', 'ET': 'ETB', 'NG': 'NGN', 'GH': 'GHS',
  'ZA': 'ZAR', 'ZM': 'ZMW', 'MZ': 'MZN', 'BW': 'BWP', 'MA': 'MAD',
  'DZ': 'DZD', 'TN': 'TND', 'EG': 'EGP',
  // Europe
  'FR': 'EUR', 'DE': 'EUR', 'ES': 'EUR', 'IT': 'EUR', 'PT': 'EUR',
  'BE': 'EUR', 'NL': 'EUR', 'IE': 'EUR', 'AT': 'EUR', 'FI': 'EUR',
  'GR': 'EUR', 'LU': 'EUR', 'HR': 'EUR', 'SK': 'EUR', 'SI': 'EUR',
  'EE': 'EUR', 'LV': 'EUR', 'LT': 'EUR', 'CY': 'EUR', 'MT': 'EUR',
  'GB': 'GBP', 'CH': 'CHF', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK',
  'PL': 'PLN', 'CZ': 'CZK', 'HU': 'HUF', 'RO': 'RON', 'TR': 'TRY',
  'UA': 'UAH', 'RU': 'RUB',
  // Amériques
  'US': 'USD', 'CA': 'CAD', 'MX': 'MXN', 'BR': 'BRL', 'AR': 'ARS',
  'CL': 'CLP', 'CO': 'COP', 'PE': 'PEN', 'HT': 'HTG',
  // Asie et Moyen-Orient
  'IN': 'INR', 'PK': 'PKR', 'BD': 'BDT', 'LK': 'LKR', 'CN': 'CNY',
  'JP': 'JPY', 'KR': 'KRW', 'ID': 'IDR', 'PH': 'PHP', 'TH': 'THB',
  'VN': 'VND', 'MY': 'MYR', 'SG': 'SGD', 'HK': 'HKD', 'AE': 'AED',
  'SA': 'SAR', 'QA': 'QAR', 'KW': 'KWD', 'IL': 'ILS',
  // Océanie
  'AU': 'AUD', 'NZ': 'NZD',
};

String? currencyForCountry(String? countryCode) => countryCode == null
    ? null
    : kCountryCurrency[countryCode.toUpperCase()];