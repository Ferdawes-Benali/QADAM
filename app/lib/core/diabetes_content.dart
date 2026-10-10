/// Short, general diabetes education used (1) on the Learn screen and (2) as grounding text for the AI coach.
/// Medical review needed before any real-world use. Kept in French: the AI coach answers in the user's language.
const Map<String, String> diabetesTypeInfo = {
  't1': 'Diabète de type 1 : le pancréas ne produit plus d\'insuline. Le traitement repose sur l\'insuline à vie, '
      'l\'auto-surveillance de la glycémie et l\'adaptation des doses avec l\'équipe soignante. Risque d\'hypoglycémie '
      'si dose trop forte, repas sauté ou effort.',
  't2': 'Diabète de type 2 : le corps utilise mal l\'insuline. Traitement : alimentation, activité physique, '
      'comprimés et parfois insuline. Il évolue lentement et peut rester longtemps sans symptôme ; les complications '
      '(yeux, reins, nerfs des pieds) viennent d\'un sucre élevé pendant des années.',
  'gest': 'Diabète gestationnel : apparaît pendant la grossesse et disparaît souvent après l\'accouchement. '
      'Il nécessite un suivi rapproché pour la mère et le bébé, et un dépistage du diabète de type 2 après la grossesse.',
  'other': 'Autres formes ou prédiabète : à préciser avec le médecin. Les mêmes règles de base s\'appliquent : '
      'contrôler la glycémie, bouger, bien manger, surveiller ses pieds.',
};

const String footCareBasics = '''
Soins des pieds (personnes diabétiques) :
- Regarder ses pieds chaque jour (dessous et entre les orteils), avec un miroir si besoin.
- Ne jamais marcher pieds nus, même à la maison ou à la plage.
- Laver à l'eau tiède (tester avec le coude), bien sécher entre les orteils.
- Couper les ongles droits, ne pas couper les cors soi-même.
- Chaussures fermées, souples, vérifier l'intérieur avant de les mettre.
- Éviter les sources de chaleur directes (brasero, bouillotte, hammam très chaud) : la neuropathie empêche de sentir la brûlure.
- Une zone chaude, rouge ou gonflée, une plaie qui ne guérit pas : consulter rapidement.
- Une différence de température de plus de 2,2 °C entre le même point des deux pieds, deux jours de suite, est un signe d'alerte d'inflammation.
''';

const String glucoseBasics = '''
Repères glycémie (valeurs par défaut, à personnaliser avec le médecin) :
- À jeun : 0,80 à 1,30 g/L. Après repas (2 h) : moins de 1,80 g/L.
- Moins de 0,70 g/L = hypoglycémie : prendre 15 g de sucre rapide, recontrôler après 15 minutes.
- Plus de 2,50 g/L de façon répétée : contacter le médecin.
''';
