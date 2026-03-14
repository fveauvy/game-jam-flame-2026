import 'package:game_jam/screens/credits/credit_entry.dart';

class CreditsConfig {
  const CreditsConfig._();

  static const List<CreditEntry> mainCredits = <CreditEntry>[
    CreditEntry('Alice Abadia', <String>['Art', 'Concept']),
    CreditEntry('Bastien Génin', <String>['Dev', 'Art', 'Music']),
    CreditEntry('Jason Fachan', <String>['Dev']),
    CreditEntry('Elliot Cunningham', <String>['Dev']),
    CreditEntry('François Veauvy', <String>['Dev']),
  ];

  static const List<CreditEntry> specialThanks = <CreditEntry>[
    CreditEntry('Thomas Deléron', <String>['Art', 'Music']),
  ];
}
