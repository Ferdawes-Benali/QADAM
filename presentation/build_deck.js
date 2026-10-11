const pptxgen = require("pptxgenjs");
const React = require("react");
const RDS = require("react-dom/server");
const sharp = require("sharp");
const md = require("react-icons/md");
const fs = require("fs");
const { applyTheme } = require("/root/.claude/skills/synced/fb2b7b8d-fddc-4ba4-8c67-a785bb055ac0_bfe14ef6-0d26-471a-bc38-cb590c09df05/pptx/scripts/apply_theme.js");

const NAVY = "102D4B", NAVY7 = "1F4C78", SKY = "8DBADB", SKY1 = "E4EFF8", SKY0 = "F2F7FC", INK2 = "4A5B6E", INK3 = "5F6B78";
const OK = "1E7A4F", WATCH = "F2A93B", WATCHT = "8A5300", ALERT = "B42318", WHITE = "FFFFFF", LINE = "E2DED6";

const THEME = {
  name: "Qadam", headFontFace: "Calibri", bodyFontFace: "Calibri",
  colors: { dk1: NAVY, lt1: WHITE, dk2: INK2, lt2: SKY0, accent1: NAVY7, accent2: SKY, accent3: OK, accent4: WATCH,
            accent5: ALERT, accent6: INK3, hlink: NAVY7, folHlink: INK2 },
};

async function icon(name, color, size = 256) {
  const C = md[name];
  const svg = RDS.renderToStaticMarkup(React.createElement(C, { color: "#" + color, size }));
  const buf = await sharp(Buffer.from(svg)).resize(size, size).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}
const img = (p) => "image/png;base64," + fs.readFileSync(p).toString("base64");

(async () => {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE"; // 13.33 x 7.5
  pres.title = "Qadam — HackCure 2026";
  pres.author = "Équipe Qadam";
  pres.theme = { headFontFace: "Calibri", bodyFontFace: "Calibri" };
  const W = 13.333, H = 7.5, M = 0.6;
  const LOGO = img("logo.png"); // 520x329

  pres.defineSlideMaster({
    title: "CONTENT", background: { color: WHITE },
    objects: [
      { image: { x: W - M - 1.05, y: 6.9, w: 0.95, h: 0.6, data: LOGO } },
      { placeholder: { options: { name: "title", type: "title", x: M, y: 0.45, w: W - 2 * M, h: 0.9, fontSize: 34, bold: true, color: NAVY, valign: "top", align: "left", margin: 0 }, text: "" } },
    ],
    slideNumber: { x: M, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: INK3 },
  });
  pres.defineSlideMaster({ title: "DARK", background: { color: NAVY } });

  const sources = (s, text) => s.addText(text, { x: 1.3, y: 6.95, w: W - 3.2, h: 0.35, fontSize: 10, color: INK3, isTextBox: true, margin: 0, valign: "middle" });
  const kicker = (s, text, color = NAVY7) => s.addText(text.toUpperCase(), { x: M, y: 0.18, w: 8, h: 0.3, fontSize: 11, bold: true, color, charSpacing: 2, isTextBox: true, margin: 0 });
  async function badge(s, x, y, d, iconName, bg = SKY1, fg = NAVY7) {
    s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: bg }, line: { color: bg } });
    s.addImage({ data: await icon(iconName, fg), x: x + d * 0.22, y: y + d * 0.22, w: d * 0.56, h: d * 0.56 });
  }
  function card(s, x, y, w, h, fill = SKY0) {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: fill }, line: { color: fill }, rectRadius: 0.12 });
  }

  // ---------------------------------------------------------------- 1 opening
  pres.addSection({ title: "Ouverture" });
  let s = pres.addSlide({ masterName: "DARK", sectionTitle: "Ouverture" });
  s.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 6.2, h: H, fill: { color: WHITE }, line: { color: WHITE } });
  s.addImage({ data: LOGO, x: 0.9, y: 2.15, w: 4.4, h: 4.4 * 329 / 520 });
  s.addText("HackCure 2026 · Track IoT", { x: 0.9, y: 5.3, w: 4.6, h: 0.4, fontSize: 14, color: INK3, isTextBox: true, margin: 0 });
  s.addText("Un pas par jour\npour garder ses pieds", { x: 6.9, y: 1.9, w: 5.8, h: 1.9, fontSize: 40, bold: true, color: WHITE, isTextBox: true, margin: 0, valign: "top" });
  s.addText("Qadam repère, à la maison, l'inflammation qui précède la plaie du pied diabétique — et laisse le soignant décider.",
    { x: 6.9, y: 4.0, w: 5.6, h: 1.3, fontSize: 18, color: SKY1, isTextBox: true, margin: 0, valign: "top" });
  s.addText("قدم — خطوة كل نهار باش تحافظ على ساقيك", { x: 6.9, y: 5.6, w: 5.6, h: 0.5, fontSize: 18, color: SKY, isTextBox: true, margin: 0, rtlMode: true, align: "left" });
  s.addNotes("« قدم يعني خطوة… وقدم يعني الساق. » Qadam veut dire le pied, et le pas. Nous avons construit un pas de 10 secondes par jour qui peut éviter une amputation.");

  // ---------------------------------------------------------------- 2 human problem
  pres.addSection({ title: "Problème" });
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Problème" });
  kicker(s, "Le problème humain");
  s.addText("Une inflammation que personne ne sent", { placeholder: "title" });
  card(s, M, 1.55, 6.0, 4.9);
  await badge(s, M + 0.35, 1.85, 0.8, "MdPersonOutline");
  s.addText([{ text: "Am Hédi, 62 ans", options: { bold: true, fontSize: 20, color: NAVY, breakLine: true } },
             { text: "Persona fictif, construit à partir de profils typiques", options: { fontSize: 12, color: INK3, italic: true } }],
    { x: M + 1.35, y: 1.85, w: 4.5, h: 0.85, isTextBox: true, margin: 0, valign: "middle" });
  s.addText([
    { text: "Diabète de type 2 depuis 15 ans, plaie au pied guérie l'an dernier", options: { bullet: true, breakLine: true } },
    { text: "Ne sent plus bien ses pieds (neuropathie)", options: { bullet: true, breakLine: true } },
    { text: "L'hiver, il chauffe ses pieds près du kanoun", options: { bullet: true, breakLine: true } },
    { text: "Une zone chauffe sous son avant-pied droit : il ne la sent pas. Quand la plaie apparaîtra, ce sera tard.", options: { bullet: true } },
  ], { x: M + 0.35, y: 2.95, w: 5.4, h: 3.3, fontSize: 16, color: NAVY, isTextBox: true, margin: 0, paraSpaceAfter: 10, valign: "top" });
  const stat = (x, y, big, small, color = NAVY) => {
    s.addText(big, { x, y, w: 5.6, h: 0.95, fontSize: 54, bold: true, color, isTextBox: true, margin: 0, valign: "bottom" });
    s.addText(small, { x, y: y + 0.98, w: 5.6, h: 0.55, fontSize: 15, color: INK2, isTextBox: true, margin: 0, valign: "top" });
  };
  stat(7.2, 1.45, "1,39 million", "d'adultes tunisiens vivent avec le diabète (prévalence standardisée 16 %)");
  stat(7.2, 3.15, "1 sur 3", "ne sait pas qu'il est diabétique (31,7 % non diagnostiqués)", NAVY7);
  stat(7.2, 4.85, "19 – 34 %", "des personnes diabétiques auront un ulcère du pied au cours de leur vie", ALERT);
  sources(s, "Sources : IDF Diabetes Atlas, Tunisie, estimations 2024 · Armstrong, Boulton & Bus, NEJM 2017");
  s.addNotes("Voici Am Hédi — un personnage fictif, mais vous le connaissez tous. 62 ans, diabétique depuis 15 ans, une plaie au pied l'an dernier, il ne sent plus bien ses pieds. L'hiver, il les chauffe près du kanoun. Une inflammation commence sous son avant-pied droit : il ne la sent pas. En Tunisie, 1,4 million d'adultes vivent avec le diabète ; un sur trois ne le sait pas.");

  // ---------------------------------------------------------------- 3 why current approaches fail
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Problème" });
  kicker(s, "Pourquoi l'existant ne suffit pas");
  s.addText("Entre deux consultations, personne ne regarde", { placeholder: "title" });
  const cols = [
    ["MdVisibilityOff", "L'auto-examen n'est pas fait", "22 %", "des diabétiques hospitalisés à Tunis inspectent leurs pieds chaque jour ; 77 % ont un faible niveau de connaissance.", ALERT],
    ["MdThermostat", "Le signal existe", "÷ 2", "Surveiller la température des pieds à domicile réduit le risque d'ulcère (RR 0,51 ; 5 essais, 772 patients ; certitude faible).", OK],
    ["MdErrorOutline", "Les outils actuels sont mal adaptés", "57 %", "de faux positifs pour un tapis connecté importé au seuil 2,2 °C (sensibilité 97 %). Conçu pour un autre système de santé, en anglais, sans relais local.", WATCHT],
  ];
  for (let i = 0; i < 3; i++) {
    const x = M + i * 4.1;
    card(s, x, 1.6, 3.85, 4.95);
    await badge(s, x + 0.3, 1.85, 0.7, cols[i][0]);
    s.addText(cols[i][1], { x: x + 0.3, y: 2.7, w: 3.3, h: 0.7, fontSize: 17, bold: true, color: NAVY, isTextBox: true, margin: 0, valign: "top" });
    s.addText(cols[i][2], { x: x + 0.3, y: 3.4, w: 3.3, h: 1.0, fontSize: 48, bold: true, color: cols[i][4], isTextBox: true, margin: 0 });
    s.addText(cols[i][3], { x: x + 0.3, y: 4.5, w: 3.3, h: 1.9, fontSize: 14, color: INK2, isTextBox: true, margin: 0, valign: "top" });
  }
  sources(s, "Mizouri et al., La Tunisie Médicale 2021 · Golledge et al., Diabetes Metab Res Rev 2022 · Frykberg et al., Diabetes Care 2017 · IWGDF 2023");
  s.addNotes("Aujourd'hui, la surveillance repose sur l'auto-examen : à Tunis, seuls 22 % des patients hospitalisés regardent leurs pieds chaque jour. Pourtant la science a un signal simple : un point plus chaud de 2,2 °C que le même point de l'autre pied, deux jours de suite. Ce suivi à domicile divise par deux le risque d'ulcère — mais les outils existants sont importés, en anglais, et génèrent beaucoup de fausses alertes.");

  // ---------------------------------------------------------------- 4 solution
  pres.addSection({ title: "Solution" });
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Solution" });
  kicker(s, "Notre solution");
  s.addText("10 secondes par jour, un soignant qui décide", { placeholder: "title" });
  const sol = [
    ["MdSensors", "Le tapis", "Deux pieds, même point, gauche contre droite. Trames vérifiées (CRC), aucune décision dans le boîtier."],
    ["MdPhoneAndroid", "L'app patient", "En derja, arabe ou français. Résultat expliqué, conduite à tenir fixe, journal glycémie et médicaments. Hors ligne, chiffrée."],
    ["MdLocalHospital", "Le tableau de bord", "File de triage, preuves de l'alerte, confirmation ou rejet en 3 étapes, synthèse validée, export FHIR."],
  ];
  for (let i = 0; i < 3; i++) {
    const y = 1.6 + i * 1.65;
    await badge(s, M, y, 1.1, sol[i][0], i === 2 ? NAVY : SKY1, i === 2 ? WHITE : NAVY7);
    s.addText(sol[i][1], { x: M + 1.4, y: y + 0.02, w: 5.2, h: 0.45, fontSize: 20, bold: true, color: NAVY, isTextBox: true, margin: 0 });
    s.addText(sol[i][2], { x: M + 1.4, y: y + 0.48, w: 5.2, h: 0.95, fontSize: 15, color: INK2, isTextBox: true, margin: 0, valign: "top" });
  }
  s.addImage({ data: img("overview.png"), x: 7.3, y: 1.6, w: 5.45, h: 5.45 * 1650 / 2420 });
  s.addText("Tableau de bord soignant — capture réelle du prototype (données synthétiques)", { x: 7.3, y: 5.45, w: 5.45, h: 0.4, fontSize: 11, italic: true, color: INK3, isTextBox: true, margin: 0 });
  s.addNotes("Qadam : un tapis, une app en derja, un tableau de bord pour l'équipe soignante. Le patient monte 10 secondes sur le tapis. Qadam compare gauche et droite, explique le résultat, dit quoi faire, et prévient le soignant — qui décide.");

  // ---------------------------------------------------------------- 5 user journey
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Solution" });
  kicker(s, "Parcours patient");
  s.addText("De la plaie découverte à l'alerte anticipée", { placeholder: "title" });
  s.addText("AUJOURD'HUI", { x: M, y: 1.6, w: 3, h: 0.35, fontSize: 12, bold: true, color: ALERT, charSpacing: 2, isTextBox: true, margin: 0 });
  s.addText("AVEC QADAM", { x: M, y: 3.95, w: 3, h: 0.35, fontSize: 12, bold: true, color: OK, charSpacing: 2, isTextBox: true, margin: 0 });
  const row = (y, steps, color, bg) => {
    const w = 2.85, gap = 0.22;
    steps.forEach((t, i) => {
      const x = M + i * (w + gap);
      card(s, x, y, w, 1.6, bg);
      s.addText(t[0], { x: x + 0.2, y: y + 0.15, w: w - 0.4, h: 0.35, fontSize: 12, bold: true, color, isTextBox: true, margin: 0 });
      s.addText(t[1], { x: x + 0.2, y: y + 0.5, w: w - 0.4, h: 1.0, fontSize: 15, color: NAVY, isTextBox: true, margin: 0, valign: "top" });
      if (i < steps.length - 1) s.addText("›", { x: x + w - 0.02, y: y + 0.5, w: gap + 0.04, h: 0.5, fontSize: 22, color: INK3, isTextBox: true, margin: 0, align: "center" });
    });
  };
  row(2.0, [["Jour 0", "Inflammation silencieuse sous l'avant-pied"], ["Semaines 1–3", "Il marche, chauffe ses pieds, rien ne se voit"], ["Plaie ouverte", "Découverte tardive, infection possible"], ["Urgences", "Hospitalisation, risque d'amputation"]], ALERT, "FDE8E6");
  row(4.35, [["Jour 1 · orange", "Point plus chaud : repos du pied, contrôle des chaussures"], ["Jour 2 · rouge", "Même point : appel au médecin, proche prévenu par WhatsApp"], ["Le soignant", "Voit l'alerte en tête de file, confirme en 3 étapes"], ["Consultation", "Le lendemain, décharge du pied, avant la plaie"]], OK, "E4F3EA");
  s.addText("Parcours cible : à valider lors du pilote clinique.", { x: M, y: 6.2, w: 8, h: 0.35, fontSize: 12, italic: true, color: INK3, isTextBox: true, margin: 0 });
  s.addNotes("Avant : on découvre la plaie, urgence, parfois amputation. Avec Qadam : alerte orange au jour 1, rouge au jour 2, le médecin confirme, rendez-vous le lendemain, décharge du pied.");

  // ---------------------------------------------------------------- 6 live demo
  pres.addSection({ title: "Démonstration" });
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Démonstration" });
  kicker(s, "Démonstration en direct", ALERT);
  s.addText("Du capteur à la décision du soignant", { placeholder: "title" });
  const demo = ["Scan de 10 s : vert, écart 0,2 °C", "On chauffe le capteur droit", "Scan : orange, pied droit plus chaud", "Nouveau scan : rouge, message en derja", "Tableau de bord : alerte en tête de file", "Preuves → confirmer → enregistrer (3 étapes)", "Le patient voit la décision et la note", "Signe de danger : règle fixe, 190, sans IA"];
  demo.forEach((t, i) => {
    const y = 1.6 + i * 0.6;
    s.addShape(pres.shapes.OVAL, { x: M, y: y + 0.04, w: 0.42, h: 0.42, fill: { color: i < 4 ? SKY1 : NAVY }, line: { color: i < 4 ? SKY1 : NAVY } });
    s.addText(String(i + 1), { x: M, y: y + 0.04, w: 0.42, h: 0.42, fontSize: 13, bold: true, color: i < 4 ? NAVY7 : WHITE, align: "center", valign: "middle", isTextBox: true, margin: 0 });
    s.addText(t, { x: M + 0.6, y, w: 4.6, h: 0.5, fontSize: 15, color: NAVY, isTextBox: true, margin: 0, valign: "middle" });
  });
  s.addImage({ data: img("alert.png"), x: 5.95, y: 1.6, w: 6.8, h: 6.8 * 1780 / 2880 });
  s.addText("Matériel réel : Arduino Uno + 2 × DHT22 · repli : simulation étiquetée « SIMULATION »", { x: 5.95, y: 5.95, w: 6.8, h: 0.4, fontSize: 11, italic: true, color: INK3, isTextBox: true, margin: 0 });
  s.addNotes("Démo en direct — voir docs/demo-script.md. Scan vert → on chauffe le capteur droit → orange → rouge en derja → tableau de bord → preuves → confirmer en 3 étapes → le patient voit la décision → un signe de danger dans l'assistant est traité sans IA. Repli : bridge --simulate, touche h.");

  // ---------------------------------------------------------------- 7 technology
  pres.addSection({ title: "Technologie" });
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Technologie" });
  kicker(s, "Technologie et innovation");
  s.addText("Détection explicable, IA limitée au langage", { placeholder: "title" });
  const nodes = [["MdThermostat", "Capteurs", "DHT22 × 2\ngauche / droite"], ["MdMemory", "Arduino", "moyenne 10 s\ntrames CRC-8"], ["MdSettingsInputAntenna", "Pont + MQTT", "contrôle d'intégrité\nsource étiquetée"], ["MdStorage", "Hub", "règle, alertes, audit\nAES-256, FHIR"], ["MdPhoneAndroid", "App + tableau", "hors ligne, 3 langues\ndécision humaine"]];
  for (let i = 0; i < nodes.length; i++) {
    const x = M + i * 2.48;
    await badge(s, x + 0.55, 1.65, 0.95, nodes[i][0], i === 3 ? NAVY : SKY1, i === 3 ? WHITE : NAVY7);
    s.addText(nodes[i][1], { x, y: 2.7, w: 2.05, h: 0.4, fontSize: 16, bold: true, color: NAVY, align: "center", isTextBox: true, margin: 0 });
    s.addText(nodes[i][2], { x, y: 3.1, w: 2.05, h: 0.7, fontSize: 12, color: INK2, align: "center", isTextBox: true, margin: 0, valign: "top" });
    if (i < nodes.length - 1) s.addShape(pres.shapes.LINE, { x: x + 1.65, y: 2.12, w: 0.75, h: 0, line: { color: SKY, width: 2, endArrowType: "triangle" } });
  }
  const diff = [
    ["Règle publiée, pas de boîte noire", "Écart ≥ 2,2 °C, 2 jours, même site · mêmes 12 vecteurs de test en Python et en Dart"],
    ["Indice de confiance mesurable", "Échantillons × stabilité × distance au seuil, affiché avec les paramètres déclencheurs"],
    ["IA encadrée", "Gemini côté serveur seulement · règles d'urgence avant l'IA · filtre de sortie · repli vérifié"],
    ["Confidentialité dès la conception", "Nom sur le téléphone seulement · pseudonyme sur le hub · AES-256 · audit chaîné"],
  ];
  diff.forEach((d, i) => {
    const x = M + (i % 2) * 6.15, y = 4.1 + Math.floor(i / 2) * 1.35;
    card(s, x, y, 5.95, 1.2);
    s.addText(d[0], { x: x + 0.25, y: y + 0.15, w: 5.5, h: 0.4, fontSize: 16, bold: true, color: NAVY, isTextBox: true, margin: 0 });
    s.addText(d[1], { x: x + 0.25, y: y + 0.55, w: 5.5, h: 0.55, fontSize: 13, color: INK2, isTextBox: true, margin: 0, valign: "top" });
  });
  s.addNotes("Arduino, deux capteurs, trames vérifiées par CRC, MQTT, un hub FastAPI conteneurisé, une app Flutter hors ligne et chiffrée. La détection est une règle publiée, testée dans deux langages. L'IA ne décide rien : elle explique, en derja, après un filtre de sécurité fixe.");

  // ---------------------------------------------------------------- 8 effectiveness
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Technologie" });
  kicker(s, "Efficacité et validation");
  s.addText("Ce qui est prouvé, ce qui reste à prouver", { placeholder: "title" });
  card(s, M, 1.6, 5.9, 4.95, "E4F3EA");
  await badge(s, M + 0.3, 1.85, 0.7, "MdTaskAlt", WHITE, OK);
  s.addText("Vérifié aujourd'hui (prototype)", { x: M + 1.15, y: 1.95, w: 4.5, h: 0.5, fontSize: 18, bold: true, color: OK, isTextBox: true, margin: 0 });
  s.addText([
    { text: "51 tests automatisés réussis (règle, sécurité, API, MQTT de bout en bout)", options: { bullet: true, breakLine: true } },
    { text: "Trames du firmware vérifiées octet par octet par le pont (CRC-8)", options: { bullet: true, breakLine: true } },
    { text: "Défaut capteur détecté, jamais estimé ; données périmées signalées après 15 s", options: { bullet: true, breakLine: true } },
    { text: "HTTPS TLS 1.3 testé ; altération du journal d'audit détectée", options: { bullet: true } },
  ], { x: M + 0.3, y: 2.75, w: 5.3, h: 3.6, fontSize: 15, color: NAVY, isTextBox: true, margin: 0, paraSpaceAfter: 8, valign: "top" });
  card(s, 6.85, 1.6, 5.9, 4.95, "FFF2DA");
  await badge(s, 7.15, 1.85, 0.7, "MdScience", WHITE, WATCHT);
  s.addText("À mesurer au pilote (hypothèses)", { x: 8.0, y: 1.95, w: 4.6, h: 0.5, fontSize: 18, bold: true, color: WATCHT, isTextBox: true, margin: 0 });
  s.addText([
    { text: "Adhésion : ≥ 80 % des jours avec un scan", options: { bullet: true, breakLine: true } },
    { text: "Revue des alertes : délai médian < 24 h", options: { bullet: true, breakLine: true } },
    { text: "Précision des alertes (confirmées / total)", options: { bullet: true, breakLine: true } },
    { text: "Ulcères détectés avant ouverture, vs soins habituels", options: { bullet: true, breakLine: true } },
    { text: "Utilisabilité patient (SUS ≥ 70), temps soignant par alerte", options: { bullet: true } },
  ], { x: 7.15, y: 2.75, w: 5.3, h: 3.6, fontSize: 15, color: NAVY, isTextBox: true, margin: 0, paraSpaceAfter: 8, valign: "top" });
  s.addText("Aucun résultat clinique n'est revendiqué : le bénéfice doit être démontré en Tunisie.", { x: M, y: 6.6, w: 10, h: 0.3, fontSize: 12, italic: true, color: INK3, isTextBox: true, margin: 0 });
  s.addNotes("Ce que nous avons prouvé aujourd'hui : la chaîne complète fonctionne, 51 tests automatisés passent. Ce que nous n'avons pas encore prouvé : le bénéfice clinique en Tunisie. Notre pilote mesurera l'adhésion, la précision des alertes, le délai de revue et les ulcères détectés avant ouverture.");

  // ---------------------------------------------------------------- 9 market
  pres.addSection({ title: "Marché et modèle" });
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Marché et modèle" });
  kicker(s, "Marché et passage à l'échelle");
  s.addText("Commencer là où le risque est le plus élevé", { placeholder: "title" });
  const funnel = [
    ["1,39 M", "adultes diabétiques en Tunisie", 11.9, NAVY],
    ["Risque élevé", "antécédent d'ulcère, neuropathie, amputation (IWGDF 2–3) — part à mesurer", 9.6, NAVY7],
    ["Premiers clients", "cliniques de diabétologie et endocrinologues privés · Tunis, Sfax, Sousse", 7.3, "3A72A6"],
    ["Ensuite", "services publics (pilote) → CNAM → Maghreb", 5.0, SKY],
  ];
  funnel.forEach((f, i) => {
    const y = 1.65 + i * 1.2, x = M + (11.9 - f[2]) / 2;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w: f[2], h: 1.0, fill: { color: f[3] }, line: { color: f[3] }, rectRadius: 0.1 });
    s.addText([{ text: f[0] + "   ", options: { bold: true, fontSize: 20 } }, { text: f[1], options: { fontSize: 14 } }],
      { x: x + 0.3, y, w: f[2] - 0.6, h: 1.0, color: i === 3 ? NAVY : WHITE, align: "center", valign: "middle", isTextBox: true, margin: 0 });
  });
  sources(s, "IDF Diabetes Atlas 2024 (Tunisie) · segmentation : hypothèse de l'équipe, à quantifier lors du pilote");
  s.addNotes("Premier segment : les patients à haut risque suivis par les cliniques et endocrinologues privés à Tunis, Sfax, Sousse. Puis les services publics, puis la CNAM. Puis le Maghreb.");

  // ---------------------------------------------------------------- 10 business model
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Marché et modèle" });
  kicker(s, "Modèle économique (hypothèses)");
  s.addText("La clinique paie le suivi, le patient garde l'essentiel gratuit", { placeholder: "title" });
  const bm = [
    ["MdLocalHospital", "Clinique / endocrinologue", "Abonnement par patient suivi : tapis prêté, app, tableau de bord, support", "25–40 TND / patient / mois"],
    ["MdAccountBalance", "CNAM, mutuelles (phase 2)", "Forfait de télésurveillance remboursé pour les patients APCI à haut risque, sur preuves du pilote", "forfait annuel"],
    ["MdPerson", "Patient (option)", "Location du tapis pour l'auto-surveillance", "≈ 20 TND / mois"],
    ["MdFavoriteBorder", "Gratuit", "Journal glycémie et médicaments, assistant éducatif en derja", "0 TND"],
  ];
  for (let i = 0; i < bm.length; i++) {
    const x = M + (i % 2) * 6.15, y = 1.6 + Math.floor(i / 2) * 2.45;
    card(s, x, y, 5.95, 2.25);
    await badge(s, x + 0.3, y + 0.3, 0.75, bm[i][0]);
    s.addText(bm[i][1], { x: x + 1.25, y: y + 0.3, w: 4.5, h: 0.45, fontSize: 18, bold: true, color: NAVY, isTextBox: true, margin: 0 });
    s.addText(bm[i][2], { x: x + 1.25, y: y + 0.78, w: 4.5, h: 0.85, fontSize: 14, color: INK2, isTextBox: true, margin: 0, valign: "top" });
    s.addText(bm[i][3], { x: x + 1.25, y: y + 1.65, w: 4.5, h: 0.4, fontSize: 16, bold: true, color: NAVY7, isTextBox: true, margin: 0 });
  }
  s.addText("Pourquoi rester client : moins d'urgences et d'amputations, un suivi structuré entre deux visites, un service différenciant. Tous les prix sont à valider.", { x: M, y: 6.5, w: 11.2, h: 0.4, fontSize: 12, italic: true, color: INK3, isTextBox: true, margin: 0 });
  s.addNotes("La clinique paie un abonnement par patient suivi, tapis prêté inclus. Le journal glycémie et l'éducation restent gratuits. Objectif : remboursement CNAM sur preuves. Ces prix sont des hypothèses que le pilote validera.");

  // ---------------------------------------------------------------- 11 strategy
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Marché et modèle" });
  kicker(s, "Stratégie et viabilité");
  s.addText("Un pilote, des partenaires, des coûts maîtrisés", { placeholder: "title" });
  const strat = [
    ["MdHandshake", "Partenariats à explorer", "Un service d'endocrinologie pour le pilote · pharmacies comme points de remise et de conseil · associations de patients"],
    ["MdCampaign", "Acquisition", "Par les médecins (prescription du suivi) · démonstrations en clinique · bouche-à-oreille familial (WhatsApp)"],
    ["MdPayments", "Coûts à valider", "Tapis ESP32 + 8 capteurs : 150–220 TND (estimation) · hub par clinique : 50–150 TND / mois · IA optionnelle"],
    ["MdShield", "Barrières et réponses", "Confiance clinique → règle publiée + décision humaine · littératie → derja + voix · réseau → hors ligne"],
  ];
  for (let i = 0; i < strat.length; i++) {
    const y = 1.6 + i * 1.25;
    await badge(s, M, y, 0.85, strat[i][0]);
    s.addText(strat[i][1], { x: M + 1.15, y: y, w: 3.2, h: 0.85, fontSize: 17, bold: true, color: NAVY, isTextBox: true, margin: 0, valign: "middle" });
    s.addText(strat[i][2], { x: M + 4.4, y: y, w: 7.7, h: 0.85, fontSize: 14, color: INK2, isTextBox: true, margin: 0, valign: "middle" });
  }
  s.addText("Aucun partenariat n'est encore signé.", { x: M, y: 6.6, w: 8, h: 0.3, fontSize: 12, italic: true, color: INK3, isTextBox: true, margin: 0 });
  s.addNotes("Un service d'endocrinologie partenaire pour le pilote, les pharmacies comme points de distribution, et des coûts maîtrisés : tapis à moins de 220 TND, un serveur par clinique.");

  // ---------------------------------------------------------------- 12 trust
  pres.addSection({ title: "Confiance et feuille de route" });
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Confiance et feuille de route" });
  kicker(s, "Confiance, sécurité, déploiement");
  s.addText("Une aide consultative, jamais un diagnostic", { placeholder: "title" });
  const trust = [
    ["MdPersonSearch", "Humain dans la boucle", "Chaque alerte est confirmée ou rejetée par un soignant ; le patient voit la décision."],
    ["MdInsights", "Explicable", "Écart, seuil, site, persistance, indice de confiance affichés à chaque alerte."],
    ["MdLock", "Données protégées", "Pseudonymes, AES-256 au repos, TLS 1.3, consentement, export et effacement."],
    ["MdHistory", "Traçable", "Journal d'audit chaîné SHA-256 : accès, décisions, exports."],
    ["MdScience", "Honnête sur les données", "Simulation et données de démo toujours étiquetées ; capteurs prototypes signalés."],
    ["MdGavel", "Avant un vrai pilote", "Déclaration INPDP, hébergement agréé, comité d'éthique, qualification dispositif médical."],
  ];
  for (let i = 0; i < trust.length; i++) {
    const x = M + (i % 3) * 4.1, y = 1.6 + Math.floor(i / 3) * 2.45;
    card(s, x, y, 3.85, 2.25);
    await badge(s, x + 0.3, y + 0.28, 0.7, trust[i][0], i === 5 ? NAVY : SKY1, i === 5 ? WHITE : NAVY7);
    s.addText(trust[i][1], { x: x + 1.15, y: y + 0.28, w: 2.55, h: 0.7, fontSize: 16, bold: true, color: NAVY, isTextBox: true, margin: 0, valign: "middle" });
    s.addText(trust[i][2], { x: x + 0.3, y: y + 1.12, w: 3.3, h: 1.05, fontSize: 13, color: INK2, isTextBox: true, margin: 0, valign: "top" });
  }
  s.addNotes("Recommandation consultative, validation humaine, indice de confiance, mode démo et simulation toujours étiquetés. Avant un vrai pilote : déclaration INPDP, hébergement agréé, comité d'éthique, qualification dispositif médical.");

  // ---------------------------------------------------------------- 13 roadmap
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Confiance et feuille de route" });
  kicker(s, "Feuille de route");
  s.addText("Du prototype au pilote en six mois", { placeholder: "title" });
  s.addShape(pres.shapes.LINE, { x: M + 0.3, y: 2.25, w: 11.5, h: 0, line: { color: SKY, width: 3 } });
  const road = [
    ["Aujourd'hui", "Prototype", ["Banc Uno + 2 capteurs", "App, hub, tableau de bord", "Données synthétiques"], "Chaîne complète démontrée"],
    ["0–3 mois", "Tapis réel", ["ESP32 + 8 capteurs de contact × 10", "Calibration vs thermomètre de référence", "Relecture derja/arabe, dossier INPDP"], "Écart capteurs ±0,3 °C"],
    ["3–6 mois", "Pilote", ["30–50 patients à haut risque, 3 mois", "TLS partout, clés Keystore", "Tableau de bord en routine"], "≥ 80 % de jours scannés · revue < 24 h"],
    ["6–12 mois", "Preuve", ["Étude d'impact sur les ulcères", "Discussions CNAM", "Deuxième région"], "Ulcères évités, coût par patient"],
  ];
  road.forEach((r, i) => {
    const x = M + i * 3.05;
    s.addShape(pres.shapes.OVAL, { x: x + 0.15, y: 2.05, w: 0.4, h: 0.4, fill: { color: i === 0 ? NAVY : WHITE }, line: { color: NAVY, width: 2 } });
    s.addText(r[0], { x, y: 1.5, w: 2.8, h: 0.4, fontSize: 13, bold: true, color: NAVY7, isTextBox: true, margin: 0 });
    card(s, x, 2.75, 2.85, 3.85);
    s.addText(r[1], { x: x + 0.22, y: 2.92, w: 2.45, h: 0.45, fontSize: 19, bold: true, color: NAVY, isTextBox: true, margin: 0 });
    s.addText(r[2].map((t, j) => ({ text: t, options: { bullet: true, breakLine: j < r[2].length - 1 } })),
      { x: x + 0.22, y: 3.45, w: 2.45, h: 2.1, fontSize: 13, color: INK2, isTextBox: true, margin: 0, paraSpaceAfter: 6, valign: "top" });
    s.addText(r[3], { x: x + 0.22, y: 5.6, w: 2.45, h: 0.85, fontSize: 13, bold: true, color: OK, isTextBox: true, margin: 0, valign: "top" });
  });
  s.addNotes("3 mois : tapis 8 capteurs de contact, calibration, protocole. 6 mois : pilote de 30 à 50 patients. Ensuite : semelle, intégration hospitalière.");

  // ---------------------------------------------------------------- 14 closing
  pres.addSection({ title: "Conclusion" });
  s = pres.addSlide({ masterName: "DARK", sectionTitle: "Conclusion" });
  s.addText("Une amputation commence souvent par une chaleur que personne ne sent.", { x: 1.0, y: 1.4, w: 11.3, h: 1.6, fontSize: 36, bold: true, color: WHITE, isTextBox: true, margin: 0, valign: "top" });
  s.addText("Qadam la rend visible — et laisse le médecin décider.", { x: 1.0, y: 3.1, w: 11.3, h: 0.8, fontSize: 26, color: SKY, isTextBox: true, margin: 0 });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 1.0, y: 4.55, w: 3.6, h: 2.2, fill: { color: WHITE }, line: { color: WHITE }, rectRadius: 0.15 });
  s.addImage({ data: LOGO, x: 1.3, y: 4.75, w: 3.0, h: 3.0 * 329 / 520 });
  s.addText([{ text: "Un pas par jour, pour garder ses pieds.", options: { bold: true, fontSize: 22, color: WHITE, breakLine: true } },
             { text: "Merci · Questions ?", options: { fontSize: 18, color: SKY1 } }],
    { x: 5.1, y: 4.75, w: 7.2, h: 1.8, isTextBox: true, margin: 0, valign: "middle" });
  s.addNotes("Une amputation commence souvent par une chaleur que personne ne sent. Qadam la rend visible — et laisse le médecin décider. Un pas par jour, pour garder ses pieds.");

  await pres.writeFile({ fileName: "Qadam_pitch.pptx" });
  await applyTheme("Qadam_pitch.pptx", THEME);
  console.log("done");
})();
