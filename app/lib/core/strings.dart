/// Qadam UI strings: [French, Modern Standard Arabic, Tunisian Derja (Arabic script)].
/// Derja is a first draft by the team: have native speakers + a clinician review before any pilot.
/// test/strings_test.dart checks every key has 3 non-empty entries and that placeholders match.
const Map<String, List<String>> _s = {
  // ---------------------------------------------------------------- common
  'common.back': ['Retour', 'رجوع', 'ارجع'],
  'common.next': ['Continuer', 'متابعة', 'كمّل'],
  'common.save': ['Enregistrer', 'حفظ', 'سجّل'],
  'common.cancel': ['Annuler', 'إلغاء', 'بطّل'],
  'common.delete': ['Supprimer', 'حذف', 'فسّخ'],
  'common.edit': ['Modifier', 'تعديل', 'بدّل'],
  'common.done': ['Terminé', 'تم', 'كمّلنا'],
  'common.ok': ['OK', 'حسنًا', 'باهي'],
  'common.yes': ['Oui', 'نعم', 'إيه'],
  'common.no': ['Non', 'لا', 'لا'],
  'common.seeAll': ['Tout voir', 'عرض الكل', 'شوف الكل'],
  'common.understood': ['J\'ai compris', 'فهمت', 'فهمت'],
  'common.notDiagnosis': [
    'Qadam aide à repérer tôt un problème ; ce n\'est pas un diagnostic. Urgence : 190.',
    'قدم يساعد على الكشف المبكر وليس تشخيصًا. في حالة الطوارئ: 190.',
    'قدم يعاونك تكشف بكري، موش تشخيص. في الخطر: 190.'
  ],

  // ---------------------------------------------------------------- navigation
  'nav.home': ['Accueil', 'الرئيسية', 'الدار'],
  'nav.feet': ['Pieds', 'القدمان', 'ساقيّ'],
  'nav.glucose': ['Glycémie', 'السكر', 'السكر'],
  'nav.assistant': ['Assistant', 'المساعد', 'المعاون'],
  'nav.more': ['Plus', 'المزيد', 'زيد'],

  // ---------------------------------------------------------------- time
  'time.never': ['jamais', 'أبدًا', 'حتى مرة'],
  'time.s': ['il y a {n} s', 'منذ {n} ث', 'هاذي {n} ثانية'],
  'time.m': ['il y a {n} min', 'منذ {n} د', 'هاذي {n} دقيقة'],
  'time.h': ['il y a {n} h', 'منذ {n} س', 'هاذي {n} ساعة'],
  'time.d': ['il y a {n} j', 'منذ {n} يوم', 'هاذي {n} نهار'],

  // ---------------------------------------------------------------- levels, sides, sites, sources
  'level.green': ['Normal', 'طبيعي', 'لاباس'],
  'level.amber': ['À surveiller', 'يحتاج مراقبة', 'رد بالك'],
  'level.red': ['Alerte', 'تنبيه', 'تنبيه'],
  'level.none': ['Pas encore de scan', 'لا يوجد فحص بعد', 'مازال ما عملتش فحص'],
  'side.left': ['Gauche', 'اليسرى', 'اليسار'],
  'side.right': ['Droit', 'اليمنى', 'اليمين'],
  'site.mth1': ['avant-pied (gros orteil)', 'مقدّم القدم (جهة الإبهام)', 'قدّام الساق (جيهة الصبع الكبير)'],
  'site.mth5': ['avant-pied (petit orteil)', 'مقدّم القدم (جهة الخنصر)', 'قدّام الساق (جيهة الصبع الصغير)'],
  'site.hallux': ['gros orteil', 'إبهام القدم', 'الصبع الكبير'],
  'site.heel': ['talon', 'الكعب', 'الكعبة'],
  'source.hardware': ['Capteurs réels', 'حساسات حقيقية', 'حسّاسات حقيقية'],
  'source.simulated': ['SIMULATION', 'محاكاة', 'سيمولاسيون'],
  'source.manual': ['Saisie manuelle', 'إدخال يدوي', 'بيدك'],
  'source.synthetic': ['Données de démo', 'بيانات تجريبية', 'معطيات تجربة'],
  'conf.high': ['élevée', 'مرتفعة', 'عالية'],
  'conf.medium': ['moyenne', 'متوسطة', 'متوسطة'],
  'conf.low': ['faible', 'ضعيفة', 'ضعيفة'],
  'band.low': ['Hypoglycémie', 'انخفاض السكر', 'السكر هابط'],
  'band.very_high': ['Très élevée', 'مرتفع جدًا', 'طالع برشا'],
  'band.in_target': ['Dans la cible', 'ضمن الهدف', 'في البلاصة'],
  'band.out_of_target': ['Hors cible', 'خارج الهدف', 'برّا البلاصة'],
  'ctx.fasting': ['À jeun', 'على الريق', 'على الريق'],
  'ctx.after_meal': ['Après repas', 'بعد الأكل', 'بعد الماكلة'],
  'ctx.other': ['Autre', 'أخرى', 'وقت آخر'],
  'type.t1': ['Type 1', 'النوع 1', 'نوع 1'],
  'type.t2': ['Type 2', 'النوع 2', 'نوع 2'],
  'type.gest': ['Gestationnel', 'سكري الحمل', 'سكر الحمل'],
  'type.other': ['Autre / je ne sais pas', 'آخر / لا أعرف', 'آخر / ما نعرفش'],
  'treat.tablets': ['Comprimés', 'حبوب', 'حبوب'],
  'treat.insulin': ['Insuline', 'أنسولين', 'أنسولين (إبرة)'],
  'treat.both': ['Les deux', 'الاثنان', 'الزوز'],
  'treat.diet': ['Régime seul', 'حمية فقط', 'ريجيم برك'],
  'riskLabel.low': ['risque pied bas', 'خطر منخفض على القدم', 'خطر صغير على الساق'],
  'riskLabel.moderate': ['risque pied modéré', 'خطر متوسط على القدم', 'خطر متوسط على الساق'],
  'riskLabel.high': ['risque pied élevé', 'خطر مرتفع على القدم', 'خطر كبير على الساق'],

  // ---------------------------------------------------------------- onboarding
  'onb.start': ['Commencer', 'ابدأ', 'يلّا نبداو'],
  'onb.finish': ['Créer mon espace', 'إنشاء حسابي', 'اعمل الحساب متاعي'],
  'onb.tagline': [
    'Prendre soin de vos pieds, chaque jour, en une minute.',
    'اعتنِ بقدميك كل يوم في دقيقة واحدة.',
    'اعتني بساقيك كل نهار في دقيقة.'
  ],
  'onb.taglineSub': [
    'Qadam suit votre diabète et repère tôt les signes qui précèdent une plaie au pied.',
    'يرافقك قدم في متابعة السكري ويكشف مبكرًا العلامات التي تسبق جرح القدم.',
    'قدم يتبّع معاك السكر ويكشف بكري العلامات اللي تجي قبل جرح الساق.'
  ],
  'onb.chooseLang': ['Choisissez votre langue', 'اختر لغتك', 'اختار اللغة متاعك'],
  'onb.about.title': ['Ce que fait Qadam', 'ماذا يفعل قدم', 'شنوّة يعمل قدم'],
  'onb.about.p1.t': ['Un scan des pieds en 10 secondes', 'فحص القدمين في 10 ثوانٍ', 'فحص الساقين في 10 ثواني'],
  'onb.about.p1.b': [
    'Vous montez pieds nus sur le tapis. Qadam compare la température du même point sous vos deux pieds : un point plus chaud peut signaler une inflammation avant la plaie.',
    'تقف حافيًا على البساط، فيقارن قدم حرارة النقطة نفسها تحت قدميك: نقطة أسخن قد تدل على التهاب قبل ظهور الجرح.',
    'تطلع حافي على الزربية، وقدم يقارن السخانة في نفس البلاصة تحت ساقيك: بلاصة أسخن تنجم تكون التهاب قبل ما يبان الجرح.'
  ],
  'onb.about.p2.t': ['Votre glycémie et vos médicaments', 'السكر والأدوية', 'السكر والدوا'],
  'onb.about.p2.b': [
    'Notez vos glycémies en g/L et cochez vos prises. Qadam vous indique la conduite à tenir en cas d\'hypoglycémie.',
    'سجّل قياسات السكر بـ غ/ل وأشّر على أدويتك. يرشدك قدم عند انخفاض السكر.',
    'سجّل السكر بـ غ/ل وعلّم على الدوا اللي شربتو. قدم يقلك شنوّة تعمل كي يهبط السكر.'
  ],
  'onb.about.p3.t': ['Votre équipe de soins informée', 'فريقك الطبي على علم', 'الطبيب متاعك يكون على بالو'],
  'onb.about.p3.b': [
    'Si vous l\'acceptez, vos résultats sont envoyés à votre équipe soignante, qui valide ou rejette chaque alerte.',
    'إذا وافقت، تُرسل نتائجك إلى فريقك الطبي الذي يؤكد كل تنبيه أو يرفضه.',
    'كان توافق، النتايج تتبعث للطبيب متاعك وهو اللي يأكد ولا يرفض كل تنبيه.'
  ],

  // ---------------------------------------------------------------- consent
  'consent.title': ['Vos données, vos choix', 'بياناتك، اختياراتك', 'المعطيات متاعك، الاختيار متاعك'],
  'consent.sub': [
    'Vous pouvez changer chaque choix plus tard dans Réglages.',
    'يمكنك تغيير كل اختيار لاحقًا من الإعدادات.',
    'تنجم تبدّل كل اختيار من بعد في الإعدادات.'
  ],
  'consent.local.t': ['Chiffrées sur votre téléphone', 'مشفّرة على هاتفك', 'مشفّرة في تليفونك'],
  'consent.local.b': [
    'Toujours. Elles sont protégées par votre code PIN (chiffrement AES-256). Votre nom ne quitte jamais le téléphone.',
    'دائمًا. محمية برمزك السري (تشفير AES-256). اسمك لا يغادر هاتفك أبدًا.',
    'ديما. محمية بالكود السري متاعك (تشفير AES-256). اسمك عمرو ما يخرج من التليفون.'
  ],
  'consent.share.t': ['Partager avec mon équipe de soins', 'المشاركة مع فريقي الطبي', 'نبعث للطبيب متاعي'],
  'consent.share.b': [
    'Scans, glycémies et prises de médicaments, envoyés sous un code patient (sans nom) quand vous êtes connecté.',
    'الفحوصات والسكر والأدوية تُرسل برمز مريض (دون اسم) عند الاتصال.',
    'الفحوصات والسكر والدوا يتبعثو بكود (بلا اسم) كي تكون مكونيكتي.'
  ],
  'consent.ai.t': ['Assistant avec intelligence artificielle', 'مساعد بالذكاء الاصطناعي', 'المعاون بالذكاء الاصطناعي'],
  'consent.ai.b': [
    'Vos questions passent par le serveur de votre équipe vers Google Gemini. Sans cela, l\'assistant utilise des réponses vérifiées, hors ligne.',
    'تمرّ أسئلتك عبر خادم فريقك إلى Google Gemini. وبدون ذلك يستعمل المساعد إجابات موثّقة دون إنترنت.',
    'الأسئلة متاعك تتعدّى من سرفور الطبيب لـ Google Gemini. من غير هذا، المعاون يستعمل أجوبة متأكدين منها بلا إنترنت.'
  ],
  'consent.understand': [
    'Je comprends que Qadam ne remplace pas mon médecin.',
    'أفهم أن قدم لا يعوّض طبيبي.',
    'فهمت اللي قدم ما يعوّضش الطبيب متاعي.'
  ],
  'consent.change': [
    'Vous pouvez exporter ou effacer toutes vos données à tout moment.',
    'يمكنك تصدير كل بياناتك أو حذفها في أي وقت.',
    'تنجم تصدّر ولا تفسخ المعطيات متاعك وقتلي تحب.'
  ],

  // ---------------------------------------------------------------- about you / risk / contacts
  'you.title': ['Parlons de vous', 'لنتعرّف عليك', 'نتعرّفو عليك'],
  'you.sub': ['Pour adapter les conseils.', 'لتكييف النصائح.', 'باش النصايح تكون على قدّك.'],
  'you.name': ['Prénom', 'الاسم', 'الإسم'],
  'you.nameHelp': ['Reste sur ce téléphone.', 'يبقى على هذا الهاتف.', 'يقعد في التليفون هذا.'],
  'you.type': ['Type de diabète', 'نوع السكري', 'نوع السكر'],
  'you.treatment': ['Traitement', 'العلاج', 'الدوا'],
  'you.year': ['Année du diagnostic (facultatif)', 'سنة التشخيص (اختياري)', 'عام اللي عرفت فيه (موش لازم)'],
  'risk.title': ['Vos pieds', 'قدماك', 'ساقيك'],
  'risk.sub': ['Deux questions pour connaître votre niveau de risque.', 'سؤالان لمعرفة مستوى الخطر.', 'زوز أسئلة باش نعرفو قدّاش الخطر.'],
  'risk.q1': [
    'Avez-vous déjà eu une plaie au pied ou une amputation ?',
    'هل أصبت سابقًا بجرح في القدم أو بتر؟',
    'عمرك صارلك جرح في ساقك ولا قصّولك حاجة؟'
  ],
  'risk.q2': [
    'Sentez-vous moins vos pieds (fourmis, engourdissement) ?',
    'هل قلّ إحساسك بقدميك (تنميل أو خدر)؟',
    'تحسّ ساقيك ناقصين حس (نمّال ولا تخدير)؟'
  ],
  'risk.result.low': [
    'Risque bas : un scan par jour reste une bonne habitude de prévention.',
    'خطر منخفض: فحص يومي عادة وقائية جيدة.',
    'خطر صغير: فحص كل نهار عادة باهية باش تحمي روحك.'
  ],
  'risk.result.moderate': [
    'Risque modéré : le suivi quotidien de la température est recommandé (IWGDF).',
    'خطر متوسط: يُنصح بمراقبة الحرارة يوميًا (IWGDF).',
    'خطر متوسط: ينصحو بمراقبة السخانة كل نهار (IWGDF).'
  ],
  'risk.result.high': [
    'Risque élevé : le scan quotidien est particulièrement important pour vous. Parlez-en à votre médecin.',
    'خطر مرتفع: الفحص اليومي مهم جدًا بالنسبة إليك. تحدّث مع طبيبك.',
    'خطر كبير: الفحص كل نهار مهم برشا ليك. احكي مع الطبيب متاعك.'
  ],
  'contacts.title': ['Vos contacts', 'جهات الاتصال', 'الناس متاعك'],
  'contacts.sub': [
    'Pour appeler votre médecin ou prévenir un proche en un geste.',
    'للاتصال بطبيبك أو إعلام أحد أقاربك بلمسة واحدة.',
    'باش تكلّم الطبيب ولا تعلّم واحد من العايلة بضغطة وحدة.'
  ],
  'contacts.doctor': ['Mon médecin', 'طبيبي', 'الطبيب متاعي'],
  'contacts.family': ['Un proche', 'أحد الأقارب', 'واحد من العايلة'],
  'contacts.name': ['Nom', 'الاسم', 'الإسم'],
  'contacts.phone': ['Téléphone (avec 216)', 'الهاتف (مع 216)', 'التليفون (بـ 216)'],
  'contacts.skip': ['Facultatif : vous pourrez les ajouter plus tard.', 'اختياري: يمكنك إضافتهم لاحقًا.', 'موش لازم: تنجم تزيدهم من بعد.'],

  // ---------------------------------------------------------------- PIN & lock
  'pin.title': ['Protégez vos données', 'احمِ بياناتك', 'احمي المعطيات متاعك'],
  'pin.sub': [
    'Choisissez un code de 4 à 6 chiffres. Il chiffre vos données sur ce téléphone.',
    'اختر رمزًا من 4 إلى 6 أرقام. يشفّر بياناتك على هذا الهاتف.',
    'اختار كود من 4 لـ 6 أرقام. يشفّر المعطيات متاعك في التليفون.'
  ],
  'pin.enter': ['Code PIN', 'الرمز السري', 'الكود السري'],
  'pin.confirm': ['Confirmez le code', 'أكّد الرمز', 'عاود الكود'],
  'pin.err.format': ['Le code doit contenir 4 à 6 chiffres.', 'يجب أن يتكوّن الرمز من 4 إلى 6 أرقام.', 'الكود لازم يكون من 4 لـ 6 أرقام.'],
  'pin.err.match': ['Les deux codes sont différents.', 'الرمزان غير متطابقين.', 'الزوز كودات موش كيف كيف.'],
  'pin.warning': [
    'Sans ce code, les données de ce téléphone ne peuvent pas être récupérées. Ne le partagez pas.',
    'بدون هذا الرمز لا يمكن استرجاع بيانات هذا الهاتف. لا تشاركه.',
    'من غير الكود هذا، المعطيات ما تنجمش ترجع. ما تعطيه لحد.'
  ],
  'lock.title': ['Bon retour', 'مرحبًا بعودتك', 'مرحبا بيك'],
  'lock.sub': ['Entrez votre code pour ouvrir Qadam.', 'أدخل رمزك لفتح قدم.', 'دخّل الكود متاعك باش تحل قدم.'],
  'lock.unlock': ['Déverrouiller', 'فتح', 'حلّ'],
  'lock.wrong': ['Code incorrect.', 'رمز خاطئ.', 'الكود غالط.'],
  'lock.forgot': ['Code oublié ?', 'نسيت الرمز؟', 'نسيت الكود؟'],
  'lock.reset.title': ['Réinitialiser Qadam ?', 'إعادة ضبط قدم؟', 'نرجّعو قدم من الأول؟'],
  'lock.reset.body': [
    'Vos données sont chiffrées avec ce code : sans lui, elles seront définitivement effacées de ce téléphone.',
    'بياناتك مشفّرة بهذا الرمز: بدونه ستُحذف نهائيًا من هذا الهاتف.',
    'المعطيات مشفّرة بالكود هذا: من غيرو يتفسخو نهائيًا من التليفون.'
  ],
  'lock.reset.confirm': ['Tout effacer', 'حذف الكل', 'فسّخ كل شي'],

  // ---------------------------------------------------------------- home
  'home.morning': ['Bonjour', 'صباح الخير', 'صباح الخير'],
  'home.afternoon': ['Bon après-midi', 'مساء الخير', 'عسلامة'],
  'home.evening': ['Bonsoir', 'مساء الخير', 'مسّاك بالخير'],
  'home.sub': ['Voici votre journée.', 'إليك يومك.', 'هاو نهارك.'],
  'home.today': ['Aujourd\'hui', 'اليوم', 'اليوم'],
  'home.task.scan': ['Scanner mes pieds', 'فحص القدمين', 'نفحص ساقيّ'],
  'home.task.glucose': ['Mesurer ma glycémie', 'قياس السكر', 'نقيس السكر'],
  'home.task.meds': ['Médicaments : {done}/{total}', 'الأدوية: {done}/{total}', 'الدوا: {done}/{total}'],
  'home.task.addMeds': ['Ajouter mes médicaments', 'أضف أدويتي', 'زيد الدوا متاعي'],
  'home.feet': ['Mes pieds', 'قدماي', 'ساقيّ'],
  'home.noScan': [
    'Pas encore de scan. Montez sur le tapis Qadam pour le premier.',
    'لا يوجد فحص بعد. قف على بساط قدم لأول فحص.',
    'مازال ما عملتش فحص. اطلع على زربية قدم للفحص الأول.'
  ],
  'home.feetDetail': [
    'Écart maximal {dt} °C · {site}',
    'أكبر فرق {dt} °م · {site}',
    'أكبر فرق {dt} درجة · {site}'
  ],
  'home.glucose': ['Glycémie', 'السكر', 'السكر'],
  'home.noGlucose': ['Aucune mesure pour l\'instant.', 'لا توجد قياسات بعد.', 'مازال ما قستش.'],
  'home.adherence': ['Médicaments (7 j)', 'الأدوية (7 أيام)', 'الدوا (7 أيام)'],
  'home.streak': ['Scans à la suite', 'فحوصات متتالية', 'فحوصات ورا بعضها'],
  'home.days': ['j', 'يوم', 'نهار'],
  'home.ask': ['Une question ?', 'لديك سؤال؟', 'عندك سؤال؟'],
  'home.askHint': ['Pieds nus, Ramadan, hypoglycémie…', 'المشي حافيًا، رمضان، انخفاض السكر…', 'نمشي حافي؟ رمضان؟ السكر هابط؟'],
  'home.redTitle': ['Le même point est chaud 2 jours de suite', 'النقطة نفسها ساخنة يومين متتاليين', 'نفس البلاصة سخونة نهارين ورا بعضهم'],
  'home.redBody': ['Voir quoi faire et contacter votre médecin.', 'اعرف ما يجب فعله واتصل بطبيبك.', 'شوف شنوّة تعمل وكلّم الطبيب.'],

  // ---------------------------------------------------------------- sync
  'sync.ok': ['Équipe de soins à jour · {when}', 'تمت المزامنة مع الفريق الطبي · {when}', 'الطبيب عندو كل شي · {when}'],
  'sync.syncing': ['Envoi à votre équipe…', 'جارٍ الإرسال إلى فريقك…', 'نبعثو للطبيب…'],
  'sync.offline': [
    'Hors connexion : {n} élément(s) en attente, envoyés plus tard',
    'دون اتصال: {n} عنصر في الانتظار وسيُرسل لاحقًا',
    'ما فماش كونيكسيون: {n} حاجة تستنى وتتبعث من بعد'
  ],
  'sync.error': ['Envoi impossible pour le moment', 'تعذّر الإرسال حاليًا', 'ما نجمناش نبعثو توّا'],
  'sync.idle': ['Prêt à synchroniser', 'جاهز للمزامنة', 'حاضر'],
  'sync.notPaired': ['Données gardées sur ce téléphone uniquement', 'البيانات محفوظة على هذا الهاتف فقط', 'المعطيات في التليفون هذا برك'],
  'sync.now': ['Synchroniser', 'مزامنة الآن', 'ابعث توّا'],
  'sync.label': ['Synchronisation', 'المزامنة', 'الإرسال'],
  'sync.pending': ['{n} en attente', '{n} في الانتظار', '{n} يستناو'],
  'sync.state.idle': ['en veille', 'في وضع الاستعداد', 'مستني'],
  'sync.state.syncing': ['en cours', 'جارية', 'قاعد يبعث'],
  'sync.state.ok': ['à jour', 'محدّثة', 'لاباس'],
  'sync.state.offline': ['hors connexion', 'دون اتصال', 'بلا كونيكسيون'],
  'sync.state.error': ['erreur', 'خطأ', 'غلطة'],
  'sync.state.notPaired': ['non connecté', 'غير مرتبط', 'موش مربوط'],

  // ---------------------------------------------------------------- feet & device
  'feet.title': ['Mes pieds', 'قدماي', 'ساقيّ'],
  'feet.history': ['Historique', 'السجل', 'اللي فات'],
  'feet.simBanner': [
    'Mode SIMULATION : ces valeurs sont générées par l\'ordinateur, ce ne sont pas des mesures.',
    'وضع المحاكاة: هذه القيم يولّدها الحاسوب وليست قياسات.',
    'سيمولاسيون: الأرقام هاذي يعملها الكمبيوتر، موش قياسات.'
  ],
  'feet.diagramLabel': ['Vos deux pieds sur le tapis', 'قدماك على البساط', 'ساقيك على الزربية'],
  'feet.difference': ['Écart', 'الفرق', 'الفرق'],
  'feet.liveNote': [
    'Valeurs en direct du tapis. Le résultat n\'est calculé que pendant un scan.',
    'قيم مباشرة من البساط. لا تُحسب النتيجة إلا أثناء الفحص.',
    'أرقام مباشرة من الزربية. النتيجة تتحسب كان وقت الفحص.'
  ],
  'feet.start': ['Lancer un scan de 10 s', 'ابدأ فحصًا لمدة 10 ثوانٍ', 'ابدا فحص 10 ثواني'],
  'feet.startHint': [
    'Pieds nus, propres et secs, posés à plat. Restez immobile.',
    'القدمان حافيتان ونظيفتان وجافتان ومسطّحتان. لا تتحرّك.',
    'ساقيك حافيين، نظاف وناشفين، محطوطين مليح. ما تتحرّكش.'
  ],
  'feet.cannotScan': ['Le tapis doit être connecté pour scanner.', 'يجب أن يكون البساط متصلًا للفحص.', 'الزربية لازم تكون مربوطة باش تفحص.'],
  'feet.measuring': ['Mesure en cours…', 'جارٍ القياس…', 'قاعد نقيس…'],
  'feet.stand': ['Restez debout, immobile, les deux pieds à plat.', 'ابقَ واقفًا دون حركة والقدمان مسطّحتان.', 'اقعد واقف وما تتحرّكش، ساقيك الزوز محطوطين.'],
  'feet.recent': ['Derniers scans', 'آخر الفحوصات', 'آخر الفحوصات'],
  'feet.selfCheck': [
    'Chaque soir, regardez aussi vos pieds (dessous et entre les orteils). Une plaie, une ampoule ou une couleur anormale : appelez votre médecin.',
    'كل مساء افحص قدميك أيضًا بعينيك (من الأسفل وبين الأصابع). جرح أو فقاعة أو لون غير طبيعي: اتصل بطبيبك.',
    'كل عشية شوف ساقيك بعينيك زادة (من تحت وبين الصوابع). جرح، فقاعة ولا لون موش عادي: كلّم الطبيب.'
  ],
  'dev.online': ['Tapis connecté', 'البساط متصل', 'الزربية مربوطة'],
  'dev.fault': ['Capteur en défaut', 'خلل في حسّاس', 'حسّاس فيه مشكل'],
  'dev.stale': ['Données anciennes', 'بيانات قديمة', 'معطيات قدام'],
  'dev.waiting': ['En attente du tapis', 'في انتظار البساط', 'نستناو في الزربية'],
  'dev.connecting': ['Connexion…', 'جارٍ الاتصال…', 'قاعد يتربط…'],
  'dev.brokerDown': ['Ordinateur injoignable', 'تعذّر الوصول إلى الحاسوب', 'الكمبيوتر ما يجاوبش'],
  'dev.bridgeError': ['Le tapis ne répond pas', 'البساط لا يستجيب', 'الزربية ما تجاوبش'],
  'dev.notConfigured': ['Tapis non configuré', 'البساط غير مُعدّ', 'الزربية موش مركّبة'],
  'dev.detail': ['{device} · dernière mesure {when}', '{device} · آخر قياس {when}', '{device} · آخر قيس {when}'],
  'dev.help.notConfigured': [
    'Touchez ici pour saisir l\'adresse de l\'ordinateur relié au tapis.',
    'المس هنا لإدخال عنوان الحاسوب المتصل بالبساط.',
    'انزل هنا باش تكتب عنوان الكمبيوتر المربوط بالزربية.'
  ],
  'dev.help.brokerDown': [
    'Impossible de joindre {host}. Le téléphone et l\'ordinateur sont-ils sur le même Wi-Fi ? Le serveur est-il lancé ?',
    'تعذّر الوصول إلى {host}. هل الهاتف والحاسوب على نفس شبكة الواي فاي؟ هل الخادم يعمل؟',
    'ما نجمناش نوصلو لـ {host}. التليفون والكمبيوتر على نفس الويفي؟ السرفور خدّام؟'
  ],
  'dev.help.waiting': [
    'Connecté à l\'ordinateur, mais aucune mesure reçue. Le pont série est-il lancé ?',
    'متصل بالحاسوب لكن لم يصل أي قياس. هل تم تشغيل الجسر؟',
    'مربوط بالكمبيوتر أما ما وصل حتى قيس. البريدج خدّام؟'
  ],
  'dev.help.stale': [
    'Dernière mesure reçue {when}. Les valeurs affichées ne sont pas à jour.',
    'آخر قياس وصل {when}. القيم المعروضة غير محدّثة.',
    'آخر قيس وصل {when}. الأرقام اللي تشوف فيهم موش جدد.'
  ],
  'dev.help.fault': [
    'Un capteur ne répond pas : la valeur manquante n\'est jamais estimée. Vérifiez son branchement.',
    'أحد الحساسات لا يستجيب: لا يتم تقدير القيمة الناقصة أبدًا. تحقق من توصيله.',
    'حسّاس ما يجاوبش: الرقم الناقص ما نخمّنوهش. ثبّت في التوصيل متاعو.'
  ],
  'dev.help.bridgeError': ['Le pont signale :', 'يشير الجسر إلى:', 'البريدج يقول:'],

  // ---------------------------------------------------------------- scan errors
  'scan.err.noDevice': [
    'Le tapis n\'est pas prêt. Vérifiez la connexion puis réessayez.',
    'البساط غير جاهز. تحقق من الاتصال ثم أعد المحاولة.',
    'الزربية موش حاضرة. ثبّت في الكونيكسيون وعاود.'
  ],
  'scan.err.fault': [
    'Un capteur était en défaut pendant la mesure : aucun résultat n\'a été calculé.',
    'كان أحد الحساسات معطّلًا أثناء القياس: لم تُحسب أي نتيجة.',
    'حسّاس كان فيه مشكل وقت القيس: ما حسبنا حتى نتيجة.'
  ],
  'scan.err.warming': [
    'Le tapis se stabilise. Attendez 10 secondes et relancez.',
    'البساط في طور الاستقرار. انتظر 10 ثوانٍ وأعد.',
    'الزربية مازالت تستقر. استنى 10 ثواني وعاود.'
  ],
  'scan.err.noData': ['Aucune mesure reçue pendant le scan. Réessayez.', 'لم يصل أي قياس أثناء الفحص. أعد المحاولة.', 'ما وصل حتى قيس وقت الفحص. عاود.'],
  'scan.err.implausible': [
    'Valeurs hors limites (capteur mal posé ?). Réessayez.',
    'قيم خارج الحدود (حسّاس غير مثبّت جيدًا؟). أعد المحاولة.',
    'أرقام موش منطقية (الحسّاس موش في بلاصتو؟). عاود.'
  ],

  // ---------------------------------------------------------------- scan result
  'result.title': ['Résultat du scan', 'نتيجة الفحص', 'نتيجة الفحص'],
  'result.simulated': [
    'SIMULATION — résultat de démonstration, pas une mesure de vos pieds.',
    'محاكاة — نتيجة للعرض وليست قياسًا لقدميك.',
    'سيمولاسيون — نتيجة للعرض، موش قيس متاع ساقيك.'
  ],
  'result.head.green': ['Vos deux pieds ont une température équilibrée.', 'حرارة قدميك متوازنة.', 'السخانة في ساقيك الزوز متوازنة.'],
  'result.head.amber': ['Un point est plus chaud que sur l\'autre pied.', 'نقطة أسخن من القدم الأخرى.', 'فما بلاصة أسخن من الساق الأخرى.'],
  'result.head.red': [
    'Le même point est plus chaud depuis 2 jours. Contactez votre médecin aujourd\'hui.',
    'النقطة نفسها أسخن منذ يومين. اتصل بطبيبك اليوم.',
    'نفس البلاصة سخونة هاذي نهارين. كلّم الطبيب اليوم.'
  ],
  'result.diagram': ['Point le plus chaud : pied {side}, {site}', 'النقطة الأسخن: القدم {side}، {site}', 'البلاصة الأسخن: الساق {side}، {site}'],
  'result.why': ['Pourquoi ce résultat ?', 'لماذا هذه النتيجة؟', 'علاش النتيجة هاذي؟'],
  'result.why.green': [
    'L\'écart entre vos deux pieds ({dt} °C) est sous le seuil de {th} °C.',
    'الفرق بين قدميك ({dt} °م) أقل من حدّ {th} °م.',
    'الفرق بين ساقيك ({dt} درجة) تحت الحد متاع {th} درجة.'
  ],
  'result.why.amber': [
    'Votre pied {side} est plus chaud de {dt} °C ({site}). Le seuil est {th} °C. Une seule fois : à surveiller.',
    'قدمك {side} أسخن بـ {dt} °م ({site}). الحد هو {th} °م. مرة واحدة: للمراقبة.',
    'ساقك {side} أسخن بـ {dt} درجة ({site}). الحد {th} درجة. مرة وحدة: رد بالك.'
  ],
  'result.why.red': [
    'Votre pied {side} est plus chaud de {dt} °C ({site}), au même endroit que lors du scan précédent. Au-delà de {th} °C deux jours de suite, une inflammation est possible.',
    'قدمك {side} أسخن بـ {dt} °م ({site})، في المكان نفسه كما في الفحص السابق. تجاوز {th} °م يومين متتاليين قد يعني التهابًا.',
    'ساقك {side} أسخن بـ {dt} درجة ({site})، في نفس البلاصة متاع الفحص اللي قبل. فوق {th} درجة نهارين ورا بعضهم ينجم يكون التهاب.'
  ],
  'result.demoNote': [
    'Mode démo : le scan précédent compte comme « hier ».',
    'وضع العرض: الفحص السابق يُعتبر «أمس».',
    'وضع العرض: الفحص اللي قبل نحسبوه «البارح».'
  ],
  'result.confidence': ['Fiabilité de la mesure : {n}/100', 'موثوقية القياس: {n}/100', 'قدّاش القيس مضمون: {n}/100'],
  'result.confidenceHelp': [
    'Calculée à partir du nombre de lectures, de la stabilité des capteurs et de la distance au seuil. Ce n\'est pas une probabilité de maladie.',
    'تُحسب من عدد القراءات واستقرار الحساسات والبعد عن الحد. ليست احتمال مرض.',
    'تتحسب من عدد القراءات، ثبات الحسّاسات والبعد على الحد. موش احتمال مرض.'
  ],
  'result.lowConfidence': [
    'Mesure peu fiable : restez immobile et refaites un scan.',
    'قياس غير موثوق: ابقَ ثابتًا وأعد الفحص.',
    'القيس موش مضمون: اقعد ساكت وعاود الفحص.'
  ],
  'result.todo': ['Que faire ?', 'ماذا أفعل؟', 'شنوّة نعمل؟'],
  'todo.green.1': ['Continuez le scan chaque jour, à la même heure.', 'واصل الفحص كل يوم في الساعة نفسها.', 'كمّل الفحص كل نهار في نفس الوقت.'],
  'todo.green.2': ['Regardez vos pieds ce soir, entre les orteils aussi.', 'افحص قدميك هذا المساء، وبين الأصابع أيضًا.', 'شوف ساقيك العشية، حتى بين الصوابع.'],
  'todo.green.3': ['Ne marchez jamais pieds nus.', 'لا تمشِ حافيًا أبدًا.', 'ما تمشيش حافي حتى مرة.'],
  'todo.amber.1': ['Reposez ce pied aujourd\'hui : limitez la marche.', 'أرح هذه القدم اليوم: قلّل المشي.', 'ريّح الساق هاذي اليوم: نقّص من المشي.'],
  'todo.amber.2': ['Vérifiez vos chaussures et l\'endroit chaud (rougeur, ampoule).', 'افحص حذاءك والمكان الساخن (احمرار، فقاعة).', 'ثبّت في الصباط وفي البلاصة السخونة (حمورية، فقاعة).'],
  'todo.amber.3': ['Refaites un scan demain à la même heure.', 'أعد الفحص غدًا في الساعة نفسها.', 'عاود الفحص غدوة في نفس الوقت.'],
  'todo.red.1': ['Appelez votre médecin aujourd\'hui.', 'اتصل بطبيبك اليوم.', 'كلّم الطبيب اليوم.'],
  'todo.red.2': ['Évitez de marcher sur ce pied en attendant.', 'تجنّب المشي على هذه القدم في الأثناء.', 'ما تمشيش برشا على الساق هاذي في الأثناء.'],
  'todo.red.3': ['Pas de chaleur, pas de crème sur la zone, ne percez rien.', 'لا حرارة ولا كريم على المنطقة ولا تثقب شيئًا.', 'لا سخانة، لا كريمة على البلاصة، وما تثقب حتى شي.'],
  'todo.emergency': [
    'Plaie, pied noir, fièvre ou odeur : urgences ou 190 maintenant.',
    'جرح أو قدم سوداء أو حمّى أو رائحة: الاستعجالي أو 190 الآن.',
    'جرح، ساق كحلة، حمّى ولا ريحة: الاستعجالي ولا 190 توّا.'
  ],
  'action.callDoctor': ['Appeler mon médecin {name}', 'الاتصال بطبيبي {name}', 'كلّم الطبيب {name}'],
  'action.tellFamily': ['Prévenir un proche (WhatsApp)', 'إعلام أحد الأقارب (واتساب)', 'علّم العايلة (واتساب)'],
  'action.familyMsg': [
    'Qadam : {name} a un point chaud au pied {side} ({dt} °C) deux jours de suite. Merci de l\'aider à joindre son médecin aujourd\'hui.',
    'قدم: لدى {name} نقطة ساخنة في القدم {side} ({dt} °م) يومين متتاليين. من فضلك ساعده على الاتصال بطبيبه اليوم.',
    'قدم: {name} عندو بلاصة سخونة في الساق {side} ({dt} درجة) نهارين ورا بعضهم. عاونو باش يكلّم الطبيب اليوم يعيشك.'
  ],
  'action.ack': ['J\'ai contacté mon médecin', 'اتصلت بطبيبي', 'كلّمت الطبيب'],
  'action.acked': ['Noté {when} : vous avez contacté votre médecin.', 'سُجّل {when}: اتصلت بطبيبك.', 'تسجّل {when}: كلّمت الطبيب.'],
  'action.call190': ['Appeler le 190', 'اتصل بـ 190', 'كلّم 190'],
  'care.notShared': [
    'Ce résultat reste sur votre téléphone (aucune équipe de soins connectée).',
    'تبقى هذه النتيجة على هاتفك (لا يوجد فريق طبي مرتبط).',
    'النتيجة هاذي تقعد في تليفونك (ما فماش طبيب مربوط).'
  ],
  'care.pending': ['Sera envoyé à votre équipe dès que possible.', 'سيُرسل إلى فريقك عند الإمكان.', 'تتبعث للطبيب أول ما يكون ممكن.'],
  'care.received': ['Reçu par votre équipe de soins.', 'وصل إلى فريقك الطبي.', 'وصلت للطبيب متاعك.'],
  'care.waitingReview': ['Reçu par votre équipe : en attente de l\'avis d\'un soignant.', 'وصل إلى فريقك: في انتظار رأي الطبيب.', 'وصلت للطبيب: نستناو رأيو.'],
  'review.confirmed': ['Votre équipe a confirmé cette alerte', 'أكّد فريقك هذا التنبيه', 'الطبيب أكّد التنبيه هذا'],
  'review.dismissed': ['Votre équipe a examiné cette alerte et l\'a levée', 'راجع فريقك هذا التنبيه وألغاه', 'الطبيب شاف التنبيه ونحّاه'],
  'review.short.confirmed': ['confirmée par le soignant', 'أكّدها الطبيب', 'الطبيب أكّدها'],
  'review.short.dismissed': ['levée par le soignant', 'ألغاها الطبيب', 'الطبيب نحّاها'],

  // ---------------------------------------------------------------- history
  'history.title': ['Historique des pieds', 'سجل القدمين', 'تاريخ الساقين'],
  'history.chart': ['Écart gauche/droite (°C)', 'الفرق بين اليسرى واليمنى (°م)', 'الفرق بين اليسار واليمين (درجة)'],
  'history.legend': [
    'Ligne rouge : seuil 2,2 °C. Couleur du point = niveau du scan.',
    'الخط الأحمر: حد 2.2 °م. لون النقطة = مستوى الفحص.',
    'الخط الأحمر: الحد 2.2 درجة. لون النقطة = مستوى الفحص.'
  ],
  'history.empty.t': ['Pas encore d\'historique', 'لا يوجد سجل بعد', 'مازال ما فما تاريخ'],
  'history.empty.b': ['Vos scans apparaîtront ici.', 'ستظهر فحوصاتك هنا.', 'الفحوصات متاعك يبانو هوني.'],

  // ---------------------------------------------------------------- glucose
  'glu.title': ['Glycémie', 'السكر في الدم', 'السكر'],
  'glu.add': ['Ajouter une mesure', 'إضافة قياس', 'زيد قيس'],
  'glu.value': ['Valeur', 'القيمة', 'الرقم'],
  'glu.err.range': [
    'Entrez une valeur entre 0,20 et 6,00 g/L (ou en mg/dL : 20 à 600).',
    'أدخل قيمة بين 0.20 و6.00 غ/ل (أو بـ ملغ/دل: من 20 إلى 600).',
    'دخّل رقم بين 0.20 و 6.00 غ/ل (ولا بـ mg/dL: من 20 لـ 600).'
  ],
  'glu.last': ['Dernière', 'الأخير', 'الأخير'],
  'glu.mean7': ['Moyenne 7 j', 'متوسط 7 أيام', 'المعدّل 7 أيام'],
  'glu.inTarget': ['Dans la cible', 'ضمن الهدف', 'في البلاصة'],
  'glu.chart': ['30 dernières mesures', 'آخر 30 قياسًا', 'آخر 30 قيس'],
  'glu.legend': [
    'Bande verte : 0,80 à 1,80 g/L. Ligne rouge : 0,70 g/L (hypoglycémie). Cibles à ajuster avec votre médecin.',
    'الشريط الأخضر: من 0.80 إلى 1.80 غ/ل. الخط الأحمر: 0.70 غ/ل (انخفاض). الأهداف يحدّدها طبيبك.',
    'الشريط الأخضر: من 0.80 لـ 1.80 غ/ل. الخط الأحمر: 0.70 غ/ل (هبوط). الطبيب يحدد الأرقام معاك.'
  ],
  'glu.history': ['Mesures', 'القياسات', 'القياسات'],
  'glu.deleteQ': ['Supprimer cette mesure ?', 'حذف هذا القياس؟', 'نفسخو القيس هذا؟'],
  'glu.empty.t': ['Aucune mesure', 'لا توجد قياسات', 'ما فما حتى قيس'],
  'glu.empty.b': ['Ajoutez votre glycémie après chaque contrôle au glucomètre.', 'أضف قياس السكر بعد كل فحص بالجهاز.', 'زيد السكر بعد كل قيس بالآلة.'],
  'glu.saved.in_target': ['Enregistré : dans la cible.', 'تم الحفظ: ضمن الهدف.', 'تسجّل: في البلاصة.'],
  'glu.saved.out_of_target': [
    'Enregistré : hors cible. Notez ce que vous avez mangé, parlez-en à votre médecin si cela se répète.',
    'تم الحفظ: خارج الهدف. سجّل ما أكلته وتحدث مع طبيبك إذا تكرر ذلك.',
    'تسجّل: برّا البلاصة. تفكّر شنوّة كليت، واحكي مع الطبيب كان تعاودت.'
  ],
  'glu.low.title': ['Hypoglycémie : {v} g/L', 'انخفاض السكر: {v} غ/ل', 'السكر هابط: {v} غ/ل'],
  'glu.low.1': [
    'Prenez 15 g de sucre rapide : 3 morceaux de sucre ou ½ verre de jus.',
    'تناول 15 غ من السكر السريع: 3 قطع سكر أو نصف كأس عصير.',
    'كول 15 غرام سكر: 3 قطع سكر ولا نص كاس عصير.'
  ],
  'glu.low.2': ['Attendez 15 minutes, puis remesurez.', 'انتظر 15 دقيقة ثم أعد القياس.', 'استنى ربع ساعة وعاود قيس.'],
  'glu.low.3': [
    'Toujours sous 0,70 g/L ? Recommencez, puis prenez un repas ou une collation.',
    'ما زال أقل من 0.70 غ/ل؟ أعد ذلك ثم تناول وجبة أو لمجة.',
    'مازال تحت 0.70 غ/ل؟ عاود، ومن بعد كول حاجة.'
  ],
  'glu.low.emergency': [
    'Personne confuse ou inconsciente : appelez le 190, ne rien donner à boire.',
    'إذا كان الشخص مرتبكًا أو فاقدًا للوعي: اتصل بـ 190 ولا تعطه شيئًا ليشربه.',
    'كان الواحد مخلوط ولا طايح: كلّم 190 وما تشرّبوش حتى شي.'
  ],
  'glu.low.familyMsg': [
    'Qadam : {name} a une glycémie basse ({v} g/L). Peux-tu l\'appeler maintenant ?',
    'قدم: لدى {name} انخفاض في السكر ({v} غ/ل). هل يمكنك الاتصال به الآن؟',
    'قدم: {name} السكر متاعو هابط ({v} غ/ل). تنجم تكلّمو توّا؟'
  ],
  'glu.high.title': ['Glycémie très élevée', 'السكر مرتفع جدًا', 'السكر طالع برشا'],
  'glu.high.body': [
    'Buvez de l\'eau et remesurez plus tard. Si c\'est au-dessus de 2,50 g/L plusieurs fois, ou avec soif intense, vomissements ou grande fatigue, contactez votre médecin rapidement. Ne changez pas votre traitement seul(e).',
    'اشرب الماء وأعد القياس لاحقًا. إذا تجاوز 2.50 غ/ل عدة مرات أو صاحبه عطش شديد أو قيء أو تعب كبير، اتصل بطبيبك بسرعة. لا تغيّر علاجك بنفسك.',
    'اشرب الماء وعاود قيس من بعد. كان فوق 2.50 غ/ل برشا مرات، ولا معاه عطش كبير، ترجيع ولا تعب برشا، كلّم الطبيب فيسع. ما تبدّلش الدوا وحدك.'
  ],

  // ---------------------------------------------------------------- meds
  'meds.title': ['Médicaments', 'الأدوية', 'الدوا'],
  'meds.add': ['Ajouter un médicament', 'إضافة دواء', 'زيد دوا'],
  'meds.edit': ['Modifier le médicament', 'تعديل الدواء', 'بدّل الدوا'],
  'meds.name': ['Nom', 'الاسم', 'الإسم'],
  'meds.dose': ['Dose (facultatif)', 'الجرعة (اختياري)', 'الدوز (موش لازم)'],
  'meds.times': ['Heures de prise', 'مواعيد الأخذ', 'أوقات الدوا'],
  'meds.addTime': ['Heure', 'ساعة', 'وقت'],
  'meds.today': ['Aujourd\'hui', 'اليوم', 'اليوم'],
  'meds.taken': ['pris', 'تم', 'شربتو'],
  'meds.adherence7': ['Prises effectuées sur 7 jours', 'الجرعات المأخوذة خلال 7 أيام', 'الدوا اللي شربتو في 7 أيام'],
  'meds.note': [
    'Qadam vous aide à vous souvenir. Il ne modifie jamais un traitement : c\'est votre médecin qui décide.',
    'يساعدك قدم على التذكّر. لا يغيّر العلاج أبدًا: طبيبك هو من يقرّر.',
    'قدم يعاونك تتفكّر. عمرو ما يبدّل الدوا: الطبيب هو اللي يقرر.'
  ],
  'meds.empty.t': ['Aucun médicament', 'لا توجد أدوية', 'ما فما حتى دوا'],
  'meds.empty.b': ['Ajoutez vos traitements pour cocher chaque prise.', 'أضف أدويتك للتأشير على كل جرعة.', 'زيد الدوا متاعك باش تعلّم كل مرة.'],

  // ---------------------------------------------------------------- assistant
  'ai.title': ['Assistant Qadam', 'مساعد قدم', 'معاون قدم'],
  'ai.clear': ['Effacer la conversation', 'مسح المحادثة', 'فسّخ الحديث'],
  'ai.mode.online': [
    'Connecté à votre équipe : réponses d\'IA encadrées. Les signes d\'urgence sont détectés par des règles fixes, avant l\'IA.',
    'متصل بفريقك: إجابات ذكاء اصطناعي مؤطّرة. علامات الخطر تكشفها قواعد ثابتة قبل الذكاء الاصطناعي.',
    'مربوط بالطبيب: أجوبة بالذكاء الاصطناعي مع حدود. علامات الخطر يكشفوها قواعد ثابتة قبل الذكاء الاصطناعي.'
  ],
  'ai.mode.offline': [
    'Mode hors ligne : réponses vérifiées de la bibliothèque Qadam (sans IA).',
    'وضع دون اتصال: إجابات موثّقة من مكتبة قدم (دون ذكاء اصطناعي).',
    'بلا إنترنت: أجوبة متأكدين منها من مكتبة قدم (بلا ذكاء اصطناعي).'
  ],
  'ai.intro': [
    'Posez une question sur vos pieds, votre glycémie, l\'alimentation ou le Ramadan. Je donne des informations générales : je ne remplace pas votre médecin et je ne modifie jamais un traitement.',
    'اطرح سؤالًا عن قدميك أو السكر أو الأكل أو رمضان. أقدّم معلومات عامة: لا أعوّض طبيبك ولا أغيّر العلاج أبدًا.',
    'اسأل على ساقيك، السكر، الماكلة ولا رمضان. نعطيك معلومات عامة: ما نعوّضش الطبيب وعمري ما نبدّل الدوا.'
  ],
  'ai.topics': ['Questions fréquentes', 'أسئلة شائعة', 'أسئلة يسألوها برشا'],
  'ai.limits': [
    'En cas de plaie, pied noir, fièvre, douleur dans la poitrine ou malaise : appelez le 190.',
    'في حالة جرح أو قدم سوداء أو حمّى أو ألم في الصدر أو إغماء: اتصل بـ 190.',
    'كان فما جرح، ساق كحلة، حمّى، وجيعة في الصدر ولا طيحة: كلّم 190.'
  ],
  'ai.hint': ['Écrivez votre question…', 'اكتب سؤالك…', 'اكتب سؤالك…'],
  'ai.send': ['Envoyer', 'إرسال', 'ابعث'],
  'ai.shareContext': [
    'Utiliser mon dernier scan et ma dernière glycémie pour répondre',
    'استعمال آخر فحص وآخر قياس سكر للإجابة',
    'استعمل آخر فحص وآخر قيس سكر في الجواب'
  ],
  'ai.src.rules': ['Message de sécurité fixe (pas d\'IA)', 'رسالة أمان ثابتة (ليست ذكاءً اصطناعيًا)', 'رسالة أمان ثابتة (موش ذكاء اصطناعي)'],
  'ai.src.gemini': [
    'Réponse générée par IA — informative, non validée médicalement',
    'إجابة من الذكاء الاصطناعي — للمعلومة، غير مصادق عليها طبيًا',
    'جواب بالذكاء الاصطناعي — للمعلومة برك، موش مأكّد طبيًا'
  ],
  'ai.src.library': ['Bibliothèque Qadam vérifiée (sans IA)', 'مكتبة قدم الموثّقة (دون ذكاء اصطناعي)', 'مكتبة قدم المتأكدين منها (بلا ذكاء اصطناعي)'],
  'ai.src.offline': ['Hors ligne · bibliothèque Qadam vérifiée', 'دون اتصال · مكتبة قدم الموثّقة', 'بلا إنترنت · مكتبة قدم'],
  'ai.danger.emergency': ['Urgence possible', 'حالة طارئة محتملة', 'تنجم تكون حالة خطيرة'],
  'ai.danger.urgent': ['À voir par un médecin aujourd\'hui', 'يجب أن يراه طبيب اليوم', 'لازم يشوفها طبيب اليوم'],
  'topic.barefoot': ['Marcher pieds nus ?', 'المشي حافيًا؟', 'نمشي حافي؟'],
  'topic.heat': ['Hammam, kanoun, chaleur', 'الحمّام والكانون والحرارة', 'الحمّام، الكانون والسخانة'],
  'topic.daily_check': ['Examiner mes pieds', 'فحص قدميّ', 'كيفاش نشوف ساقيّ'],
  'topic.nails': ['Ongles et cors', 'الأظافر والمسامير', 'الظوافر والكور'],
  'topic.shoes': ['Chaussures et chaussettes', 'الأحذية والجوارب', 'الصباط والكلاسط'],
  'topic.qadam_result': ['Comprendre mon résultat', 'فهم نتيجتي', 'نفهم النتيجة متاعي'],
  'topic.hypo': ['Hypoglycémie', 'انخفاض السكر', 'السكر هابط'],
  'topic.hyper': ['Glycémie élevée', 'ارتفاع السكر', 'السكر طالع'],
  'topic.ramadan': ['Jeûne du Ramadan', 'صيام رمضان', 'صيام رمضان'],
  'topic.food': ['Alimentation', 'الأكل', 'الماكلة'],
  'topic.activity': ['Activité physique', 'النشاط البدني', 'الحركة والسبور'],
  'topic.treatment_change': ['Changer ma dose ?', 'تغيير جرعتي؟', 'نبدّل الدوز؟'],
  'topic.privacy': ['Mes données', 'بياناتي', 'المعطيات متاعي'],
  'topic.targets': ['Valeurs cibles', 'القيم المستهدفة', 'الأرقام المطلوبة'],

  // ---------------------------------------------------------------- alerts
  'alerts.title': ['Alertes et suivi', 'التنبيهات والمتابعة', 'التنبيهات والمتابعة'],
  'alerts.explain': [
    'Chaque alerte est revue par votre équipe de soins, qui la confirme ou la lève. Sa réponse apparaît ici.',
    'يراجع فريقك الطبي كل تنبيه فيؤكده أو يلغيه. يظهر رده هنا.',
    'الطبيب يشوف كل تنبيه ويأكدو ولا ينحّيه. الجواب متاعو يبان هوني.'
  ],
  'alerts.foot': ['Pied : écart {dt} °C ({site})', 'القدم: فرق {dt} °م ({site})', 'الساق: فرق {dt} درجة ({site})'],
  'alerts.glucose.low': ['Hypoglycémie : {v} g/L', 'انخفاض السكر: {v} غ/ل', 'السكر هابط: {v} غ/ل'],
  'alerts.glucose.very_high': ['Glycémie très élevée : {v} g/L', 'سكر مرتفع جدًا: {v} غ/ل', 'السكر طالع برشا: {v} غ/ل'],
  'alerts.sent': ['envoyée à l\'équipe', 'أُرسل إلى الفريق', 'تبعثت للطبيب'],
  'alerts.pending': ['en attente d\'envoi', 'في انتظار الإرسال', 'تستنى باش تتبعث'],
  'alerts.local': ['sur ce téléphone', 'على هذا الهاتف', 'في التليفون هذا'],
  'alerts.acked': ['vous avez contacté le médecin', 'اتصلت بالطبيب', 'كلّمت الطبيب'],
  'alerts.empty.t': ['Aucune alerte', 'لا توجد تنبيهات', 'ما فما حتى تنبيه'],
  'alerts.empty.b': ['C\'est une bonne nouvelle. Continuez vos scans.', 'هذا خبر جيد. واصل فحوصاتك.', 'هاذي خبر باهي. كمّل الفحوصات.'],

  // ---------------------------------------------------------------- care circle
  'care.title': ['Mon entourage de soins', 'دائرة الرعاية', 'الناس اللي يعتنيو بيّ'],
  'care.noContact': ['Aucun numéro enregistré.', 'لا يوجد رقم مسجّل.', 'ما فما حتى نومرو.'],
  'care.call': ['Appeler', 'اتصال', 'كلّم'],
  'care.hello': ['Bonjour, c\'est {name} (via Qadam).', 'مرحبًا، أنا {name} (عبر قدم).', 'عسلامة، أنا {name} (من قدم).'],
  'care.team': ['Équipe de soins', 'الفريق الطبي', 'الطبيب والفريق'],
  'care.paired': ['Connecté · code patient {ref}', 'مرتبط · رمز المريض {ref}', 'مربوط · الكود متاعك {ref}'],
  'care.notPaired': [
    'Pas encore connecté. Demandez un code d\'appairage à votre médecin ou à votre centre de santé.',
    'غير مرتبط بعد. اطلب رمز الربط من طبيبك أو مركزك الصحي.',
    'مازال موش مربوط. اطلب كود من الطبيب ولا من المستوصف.'
  ],
  'care.connect': ['Se connecter à mon équipe', 'الارتباط بفريقي', 'اربط بالطبيب متاعي'],
  'care.manage': ['Gérer la connexion', 'إدارة الارتباط', 'تصرّف في الربط'],
  'care.report': ['Rapport pour la consultation', 'تقرير للاستشارة', 'تقرير للطبيب'],
  'care.reportBody': [
    'PDF des 30 derniers jours (scans, glycémies, observance) à montrer à votre médecin.',
    'ملف PDF لآخر 30 يومًا (الفحوصات، السكر، الالتزام بالدواء) لعرضه على طبيبك.',
    'PDF متاع آخر 30 نهار (فحوصات، سكر، دوا) توريه للطبيب.'
  ],
  'care.reportBtn': ['Créer et partager le PDF', 'إنشاء ومشاركة PDF', 'اعمل وابعث الـ PDF'],

  // ---------------------------------------------------------------- connection
  'conn.title': ['Tapis et équipe de soins', 'البساط والفريق الطبي', 'الزربية والطبيب'],
  'conn.mat': ['Tapis Qadam', 'بساط قدم', 'زربية قدم'],
  'conn.matHelp': [
    'Adresse IP de l\'ordinateur relié au tapis (même Wi-Fi que ce téléphone).',
    'عنوان IP للحاسوب المتصل بالبساط (نفس شبكة الواي فاي).',
    'عنوان IP متاع الكمبيوتر المربوط بالزربية (نفس الويفي).'
  ],
  'conn.host': ['Adresse de l\'ordinateur', 'عنوان الحاسوب', 'عنوان الكمبيوتر'],
  'conn.port': ['Port', 'المنفذ', 'البور'],
  'conn.device': ['Identifiant du tapis', 'معرّف البساط', 'إسم الزربية'],
  'conn.connect': ['Connecter', 'اتصال', 'اربط'],
  'conn.ok': ['Connecté à l\'ordinateur.', 'تم الاتصال بالحاسوب.', 'تربطنا بالكمبيوتر.'],
  'conn.fail': ['Connexion impossible. Vérifiez l\'adresse et le Wi-Fi.', 'تعذّر الاتصال. تحقق من العنوان والواي فاي.', 'ما نجمناش نتربطو. ثبّت في العنوان والويفي.'],
  'conn.state.notConfigured': ['Non configuré', 'غير مُعدّ', 'موش مركّب'],
  'conn.state.connecting': ['Connexion…', 'جارٍ الاتصال…', 'قاعد يتربط…'],
  'conn.state.brokerDown': ['Ordinateur injoignable', 'تعذّر الوصول إلى الحاسوب', 'الكمبيوتر ما يجاوبش'],
  'conn.state.waiting': ['Connecté, en attente de mesures', 'متصل، في انتظار القياسات', 'مربوط، نستناو القياسات'],
  'conn.state.online': ['Mesures reçues', 'القياسات تصل', 'القياسات واصلة'],
  'conn.state.stale': ['Mesures interrompues', 'توقفت القياسات', 'القياسات وقفت'],
  'conn.state.fault': ['Capteur en défaut', 'خلل في حسّاس', 'حسّاس فيه مشكل'],
  'conn.state.bridgeError': ['Le pont ne lit plus le tapis', 'الجسر لا يقرأ البساط', 'البريدج ما عادش يقرا الزربية'],
  'conn.hub': ['Équipe de soins', 'الفريق الطبي', 'الطبيب'],
  'conn.hubHelp': [
    'Saisissez l\'adresse du serveur de votre centre et le code donné par votre médecin.',
    'أدخل عنوان خادم مركزك والرمز الذي أعطاك إياه طبيبك.',
    'اكتب عنوان السرفور متاع المركز والكود اللي عطاهولك الطبيب.'
  ],
  'conn.hubUrl': ['Adresse du serveur', 'عنوان الخادم', 'عنوان السرفور'],
  'conn.code': ['Code d\'appairage', 'رمز الربط', 'كود الربط'],
  'conn.pair': ['Connecter mon équipe', 'ربط فريقي', 'اربط الطبيب'],
  'conn.unpair': ['Déconnecter', 'فكّ الارتباط', 'فكّ الربط'],
  'conn.paired': ['Connecté en tant que {ref} · {url}', 'مرتبط بصفة {ref} · {url}', 'مربوط بالكود {ref} · {url}'],
  'conn.noConsent': [
    'Le partage avec l\'équipe est désactivé dans vos choix de confidentialité.',
    'المشاركة مع الفريق معطّلة في إعدادات الخصوصية.',
    'البعث للطبيب مسكّر في إعدادات الخصوصية.'
  ],
  'conn.demo': ['Mode démonstration', 'وضع العرض', 'وضع العرض'],
  'conn.demoHelp': [
    'Chaque scan compte comme un jour, pour montrer l\'alerte rouge en quelques minutes. À désactiver en usage réel.',
    'كل فحص يُحسب يومًا لعرض التنبيه الأحمر في دقائق. يجب تعطيله في الاستعمال الحقيقي.',
    'كل فحص نحسبوه نهار باش نوريو التنبيه الأحمر في دقايق. سكّرو في الاستعمال الحقيقي.'
  ],
  'pair.ok': ['Connecté à votre équipe ({ref}).', 'تم الربط بفريقك ({ref}).', 'تربطت بالطبيب ({ref}).'],
  'pair.err.network': ['Serveur injoignable. Vérifiez l\'adresse et le Wi-Fi.', 'تعذّر الوصول إلى الخادم. تحقق من العنوان والواي فاي.', 'السرفور ما يجاوبش. ثبّت في العنوان والويفي.'],
  'pair.err.code': ['Code invalide ou expiré.', 'رمز غير صالح أو منتهي.', 'الكود غالط ولا وفى.'],
  'pair.err.other': ['Appairage impossible pour le moment.', 'تعذّر الربط حاليًا.', 'ما نجمناش نربطو توّا.'],

  // ---------------------------------------------------------------- settings & more
  'set.title': ['Réglages', 'الإعدادات', 'الإعدادات'],
  'set.language': ['Langue', 'اللغة', 'اللغة'],
  'set.profile': ['Mon profil', 'ملفي', 'البروفيل متاعي'],
  'set.privacy': ['Confidentialité et sécurité', 'الخصوصية والأمان', 'الخصوصية والأمان'],
  'set.shareHelp': ['Envoi des résultats sous code patient.', 'إرسال النتائج برمز المريض.', 'نبعثو النتايج بالكود متاعك.'],
  'set.aiHelp': ['Sinon : réponses vérifiées sans IA.', 'وإلا: إجابات موثّقة دون ذكاء اصطناعي.', 'وإلا: أجوبة متأكدين منها بلا ذكاء اصطناعي.'],
  'set.changePin': ['Changer le code PIN', 'تغيير الرمز السري', 'بدّل الكود السري'],
  'set.oldPin': ['Code actuel', 'الرمز الحالي', 'الكود الحالي'],
  'set.newPin': ['Nouveau code', 'الرمز الجديد', 'الكود الجديد'],
  'set.pinChanged': ['Code modifié. Vos données ont été rechiffrées.', 'تم تغيير الرمز وإعادة تشفير بياناتك.', 'الكود تبدّل والمعطيات تشفّرت من جديد.'],
  'set.lockNow': ['Verrouiller maintenant', 'القفل الآن', 'سكّر توّا'],
  'set.export': ['Exporter mes données', 'تصدير بياناتي', 'صدّر المعطيات متاعي'],
  'set.exportHelp': ['Copie un fichier JSON lisible dans le presse-papiers.', 'ينسخ ملف JSON مقروء إلى الحافظة.', 'ينسخ ملف JSON في الكليبورد.'],
  'set.exported': ['Données copiées dans le presse-papiers.', 'تم نسخ البيانات إلى الحافظة.', 'المعطيات تنسخت.'],
  'set.erase.title': ['Effacer toutes mes données', 'حذف كل بياناتي', 'فسّخ المعطيات الكل'],
  'set.erase.body': [
    'Tout sera supprimé définitivement de ce téléphone.',
    'سيتم حذف كل شيء نهائيًا من هذا الهاتف.',
    'كل شي يتفسخ نهائيًا من التليفون.'
  ],
  'set.erase.bodyPaired': [
    'Tout sera supprimé de ce téléphone, et une demande d\'effacement sera envoyée au serveur de votre équipe.',
    'سيُحذف كل شيء من هذا الهاتف وسيُرسل طلب حذف إلى خادم فريقك.',
    'كل شي يتفسخ من التليفون، ونبعثو طلب فسخ لسرفور الطبيب.'
  ],
  'set.erase.confirm': ['Effacer définitivement', 'حذف نهائي', 'فسّخ نهائيًا'],
  'set.display': ['Affichage', 'العرض', 'العرض'],
  'set.advanced': ['Mode avancé', 'الوضع المتقدّم', 'الوضع المتقدّم'],
  'set.advancedHelp': ['Affiche les détails techniques (pont, trames).', 'يعرض التفاصيل التقنية.', 'يوري التفاصيل التقنية.'],
  'more.ref': ['Code patient : {ref}', 'رمز المريض: {ref}', 'الكود متاعك: {ref}'],
  'more.alerts': ['Alertes et suivi', 'التنبيهات والمتابعة', 'التنبيهات والمتابعة'],
  'more.alertsSub': ['Réponses de votre équipe', 'ردود فريقك', 'أجوبة الطبيب'],
  'more.meds': ['Médicaments', 'الأدوية', 'الدوا'],
  'more.medsSub': ['Prises du jour, observance', 'جرعات اليوم والالتزام', 'دوا اليوم'],
  'more.care': ['Médecin, proches, rapport', 'الطبيب، الأقارب، التقرير', 'الطبيب، العايلة، التقرير'],
  'more.careSub': ['Appeler, prévenir, partager le PDF', 'اتصال، إعلام، مشاركة PDF', 'كلّم، علّم، ابعث الـ PDF'],
  'more.conn': ['Tapis et équipe de soins', 'البساط والفريق الطبي', 'الزربية والطبيب'],
  'more.connSub': ['Connexion, appairage, mode démo', 'الاتصال، الربط، وضع العرض', 'الربط ووضع العرض'],
  'more.settings': ['Réglages', 'الإعدادات', 'الإعدادات'],
  'more.settingsSub': ['Langue, PIN, confidentialité', 'اللغة، الرمز، الخصوصية', 'اللغة، الكود، الخصوصية'],
  'more.aboutSub': ['Usage prévu, limites, sécurité', 'الاستعمال، الحدود، الأمان', 'الاستعمال، الحدود، الأمان'],

  // ---------------------------------------------------------------- about
  'about.title': ['À propos et limites', 'حول التطبيق وحدوده', 'على قدم وحدودو'],
  'about.use.t': ['Usage prévu', 'الاستعمال المقصود', 'لشنوّة يصلح'],
  'about.use.b': [
    'Aider les personnes diabétiques à risque à surveiller leurs pieds chaque jour et à prévenir leur équipe de soins tôt. Qadam ne pose pas de diagnostic : chaque alerte est confirmée ou levée par un soignant.',
    'مساعدة مرضى السكري المعرّضين للخطر على مراقبة أقدامهم يوميًا وإعلام فريقهم الطبي مبكرًا. لا يقدّم قدم تشخيصًا: يؤكد الطبيب كل تنبيه أو يلغيه.',
    'يعاون الناس اللي عندهم السكر باش يراقبو ساقيهم كل نهار ويعلمو الطبيب بكري. قدم ما يعطيش تشخيص: الطبيب يأكد ولا ينحّي كل تنبيه.'
  ],
  'about.proto.t': ['Prototype', 'نموذج أولي', 'نموذج أولي'],
  'about.proto.b': [
    'Le tapis de démonstration utilise deux capteurs DHT22 (température de l\'air, ±0,5 °C). Ce ne sont pas des thermomètres de peau et Qadam n\'est pas un dispositif médical validé.',
    'يستعمل بساط العرض حسّاسين DHT22 (حرارة الهواء، ±0.5 °م). ليسا مقياسي حرارة للجلد، وقدم ليس جهازًا طبيًا مصادقًا عليه.',
    'زربية العرض فيها زوز حسّاسات DHT22 (سخانة الهواء، ±0.5 درجة). موش ترمومترات للجلد، وقدم موش جهاز طبي مصادق عليه.'
  ],
  'about.rule.t': ['La règle utilisée', 'القاعدة المستعملة', 'القاعدة'],
  'about.rule.b': [
    'Écart ≥ 2,2 °C au même point des deux pieds, deux jours de suite : signal utilisé dans les études de surveillance thermique à domicile et recommandé par l\'IWGDF (2023) pour les patients à risque.',
    'فرق ≥ 2.2 °م في النقطة نفسها بين القدمين يومين متتاليين: علامة مستعملة في دراسات المراقبة الحرارية المنزلية وتوصي بها IWGDF (2023) للمرضى المعرّضين للخطر.',
    'فرق 2.2 درجة ولا أكثر في نفس البلاصة بين الساقين نهارين ورا بعضهم: علامة استعملوها في الدراسات وتنصح بيها IWGDF (2023).'
  ],
  'about.privacy.t': ['Confidentialité', 'الخصوصية', 'الخصوصية'],
  'about.privacy.b': [
    'Données chiffrées (AES-256) sur le téléphone, nom jamais transmis, partage soumis à votre accord, export et effacement à tout moment.',
    'بيانات مشفّرة (AES-256) على الهاتف، الاسم لا يُرسل أبدًا، المشاركة بموافقتك، التصدير والحذف في أي وقت.',
    'المعطيات مشفّرة (AES-256) في التليفون، الاسم ما يتبعثش، البعث بموافقتك، والتصدير والفسخ وقتلي تحب.'
  ],
  'about.ai.t': ['Intelligence artificielle', 'الذكاء الاصطناعي', 'الذكاء الاصطناعي'],
  'about.ai.b': [
    'L\'IA (Google Gemini, via le serveur de votre équipe) explique et éduque. Elle ne détecte rien et ne décide rien : la détection est une règle fixe et testée, et les urgences sont repérées sans IA.',
    'يشرح الذكاء الاصطناعي (Google Gemini عبر خادم فريقك) ويثقّف فقط. لا يكشف ولا يقرّر: الكشف قاعدة ثابتة ومختبرة، والطوارئ تُكتشف دون ذكاء اصطناعي.',
    'الذكاء الاصطناعي (Google Gemini من سرفور الطبيب) يشرح ويعلّم برك. ما يكشف حتى شي وما يقرر حتى شي: الكشف قاعدة ثابتة، والخطر يتكشف بلا ذكاء اصطناعي.'
  ],
  'about.reg.t': ['Cadre réglementaire', 'الإطار القانوني', 'القانون'],
  'about.reg.b': [
    'Avant tout pilote : déclaration INPDP, hébergement agréé des données de santé, validation clinique et marquage du dispositif.',
    'قبل أي تجربة: تصريح لدى الهيئة الوطنية لحماية المعطيات الشخصية، استضافة معتمدة لبيانات الصحة، مصادقة سريرية وترخيص الجهاز.',
    'قبل أي تجربة حقيقية: تصريح للهيئة الوطنية لحماية المعطيات الشخصية، استضافة مرخّصة للمعطيات الصحية، تجربة سريرية وترخيص.'
  ],
};

const _index = {'fr': 0, 'ar': 1, 'aeb': 2};

/// Returns the string for [lang] ('fr' | 'ar' | 'aeb'), replacing {placeholders} with [args].
String translate(String lang, String key, [Map<String, String>? args]) {
  final entry = _s[key];
  var text = entry == null ? key : entry[_index[lang] ?? 0];
  if (text.isEmpty && entry != null) text = entry[0];
  if (args != null) {
    args.forEach((k, v) => text = text.replaceAll('{$k}', v));
  }
  return text;
}

/// For tests.
Map<String, List<String>> get allStrings => _s;
