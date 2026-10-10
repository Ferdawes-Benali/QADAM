/// Minimal i18n: French, Modern Standard Arabic ('ar') and Tunisian Derja ('aeb', Arabic script).
/// Derja wording is a first draft: have a native speaker review it before the demo.
class K {
  static const home = 'home', glucose = 'glucose', feet = 'feet', learn = 'learn', me = 'me';
  static const hello = 'hello', todayPlan = 'todayPlan', streak = 'streak';
  static const addReading = 'addReading', lastReading = 'lastReading', noData = 'noData';
  static const meds = 'meds', nextDose = 'nextDose', taken = 'taken', addMed = 'addMed';
  static const scanNow = 'scanNow', liveMat = 'liveMat', connected = 'connected', disconnected = 'disconnected';
  static const statusGreen = 'statusGreen', statusAmber = 'statusAmber', statusRed = 'statusRed';
  static const left = 'left', right = 'right', difference = 'difference';
  static const selfCheck = 'selfCheck', history = 'history';
  static const tellFamily = 'tellFamily', callDoctor = 'callDoctor', explain = 'explain';
  static const myDiabetes = 'myDiabetes', askCoach = 'askCoach', askHint = 'askHint';
  static const report = 'report', language = 'language', settings = 'settings', demoMode = 'demoMode';
  static const save = 'save', next = 'next', name = 'name', diabetesType = 'diabetesType';
  static const lowSugar = 'lowSugar', highSugar = 'highSugar', fasting = 'fasting', afterMeal = 'afterMeal';
  static const disclaimer = 'disclaimer';
}

const Map<String, Map<String, String>> _tr = {
  'fr': {
    K.home: 'Accueil', K.glucose: 'Glycémie', K.feet: 'Pieds', K.learn: 'Apprendre', K.me: 'Moi',
    K.hello: 'Bonjour', K.todayPlan: 'Mon plan du jour', K.streak: 'jours de suite',
    K.addReading: 'Ajouter une mesure', K.lastReading: 'Dernière mesure', K.noData: 'Pas encore de données',
    K.meds: 'Médicaments', K.nextDose: 'Prochaine prise', K.taken: 'Pris', K.addMed: 'Ajouter un médicament',
    K.scanNow: 'Scanner mes pieds', K.liveMat: 'Tapis Qadam', K.connected: 'connecté', K.disconnected: 'non connecté',
    K.statusGreen: 'Pieds normaux', K.statusAmber: 'À surveiller', K.statusRed: 'Alerte : contactez votre médecin',
    K.left: 'Gauche', K.right: 'Droit', K.difference: 'Différence',
    K.selfCheck: 'Auto-examen du pied', K.history: 'Historique',
    K.tellFamily: 'Prévenir ma famille', K.callDoctor: 'Appeler le médecin', K.explain: 'Explication',
    K.myDiabetes: 'Mon diabète', K.askCoach: 'Poser une question', K.askHint: 'Ex : puis-je marcher pieds nus ?',
    K.report: 'Rapport pour le médecin (PDF)', K.language: 'Langue', K.settings: 'Réglages', K.demoMode: 'Mode démo (1 scan = 1 jour)',
    K.save: 'Enregistrer', K.next: 'Suivant', K.name: 'Prénom', K.diabetesType: 'Type de diabète',
    K.lowSugar: 'Hypoglycémie : prenez 15 g de sucre et recontrôlez dans 15 min', K.highSugar: 'Glycémie très élevée : contactez votre médecin',
    K.fasting: 'À jeun', K.afterMeal: 'Après repas',
    K.disclaimer: 'Qadam est une aide au dépistage, pas un diagnostic. Urgence : SAMU 190.',
  },
  'ar': {
    K.home: 'الرئيسية', K.glucose: 'السكر', K.feet: 'القدمان', K.learn: 'تعلّم', K.me: 'حسابي',
    K.hello: 'مرحبا', K.todayPlan: 'خطة اليوم', K.streak: 'أيام متتالية',
    K.addReading: 'إضافة قياس', K.lastReading: 'آخر قياس', K.noData: 'لا توجد بيانات بعد',
    K.meds: 'الأدوية', K.nextDose: 'الجرعة القادمة', K.taken: 'تم أخذه', K.addMed: 'إضافة دواء',
    K.scanNow: 'فحص القدمين', K.liveMat: 'بساط قدم', K.connected: 'متصل', K.disconnected: 'غير متصل',
    K.statusGreen: 'القدمان سليمتان', K.statusAmber: 'يحتاج إلى مراقبة', K.statusRed: 'تنبيه: اتصل بطبيبك',
    K.left: 'اليسرى', K.right: 'اليمنى', K.difference: 'الفرق',
    K.selfCheck: 'الفحص الذاتي للقدم', K.history: 'السجل',
    K.tellFamily: 'إعلام العائلة', K.callDoctor: 'الاتصال بالطبيب', K.explain: 'الشرح',
    K.myDiabetes: 'السكري لديّ', K.askCoach: 'اطرح سؤالا', K.askHint: 'مثال: هل يمكنني المشي حافيا؟',
    K.report: 'تقرير للطبيب (PDF)', K.language: 'اللغة', K.settings: 'الإعدادات', K.demoMode: 'وضع العرض (فحص = يوم)',
    K.save: 'حفظ', K.next: 'التالي', K.name: 'الاسم', K.diabetesType: 'نوع السكري',
    K.lowSugar: 'انخفاض السكر: تناول 15 غ من السكر وأعد القياس بعد 15 دقيقة', K.highSugar: 'السكر مرتفع جدا: اتصل بطبيبك',
    K.fasting: 'على الريق', K.afterMeal: 'بعد الأكل',
    K.disclaimer: 'قدم أداة مساعدة للكشف وليست تشخيصا. في حالة الطوارئ: 190.',
  },
  'aeb': {
    K.home: 'الدار', K.glucose: 'السكر', K.feet: 'الساقين', K.learn: 'تعلّم', K.me: 'أنا',
    K.hello: 'عسلامة', K.todayPlan: 'برنامج اليوم', K.streak: 'نهار ورا نهار',
    K.addReading: 'زيد قيس', K.lastReading: 'آخر قيس', K.noData: 'مازال ما فما شي',
    K.meds: 'الدواء', K.nextDose: 'الدوا الجاي', K.taken: 'شربتو', K.addMed: 'زيد دوا',
    K.scanNow: 'افحص ساقيك', K.liveMat: 'زربية قدم', K.connected: 'مربوطة', K.disconnected: 'موش مربوطة',
    K.statusGreen: 'ساقيك لاباس', K.statusAmber: 'رد بالك شوية', K.statusRed: 'تنبيه: كلّم الطبيب متاعك',
    K.left: 'اليسار', K.right: 'اليمين', K.difference: 'الفرق',
    K.selfCheck: 'شوف ساقك بروحك', K.history: 'اللي فات',
    K.tellFamily: 'علّم العايلة', K.callDoctor: 'كلّم الطبيب', K.explain: 'الشرح',
    K.myDiabetes: 'السكر متاعي', K.askCoach: 'اسأل سؤال', K.askHint: 'مثلا: نجم نمشي حافي؟',
    K.report: 'تقرير للطبيب (PDF)', K.language: 'اللغة', K.settings: 'الإعدادات', K.demoMode: 'وضع العرض',
    K.save: 'سجّل', K.next: 'اللي بعدو', K.name: 'الإسم', K.diabetesType: 'نوع السكر',
    K.lowSugar: 'السكر هبط: كول 15 غرام سكر وعاود قيس بعد ربع ساعة', K.highSugar: 'السكر طالع برشا: كلّم الطبيب',
    K.fasting: 'على الريق', K.afterMeal: 'بعد الماكلة',
    K.disclaimer: 'قدم يعاونك تكشف بكري، موش تشخيص. في الخطر: 190.',
  },
};

String translate(String lang, String key) => _tr[lang]?[key] ?? _tr['fr']![key] ?? key;
