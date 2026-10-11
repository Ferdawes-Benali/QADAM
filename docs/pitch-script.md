# Pitch script — Qadam (≈ 5 min pitch + 3 min live demo)

**Format assumption:** the cahier des charges does not state a duration. This script targets **5 minutes of pitch +
3 minutes of live demo** (slide 6), then Q&A. Times are cumulative. Two speakers: **A** (story, business),
**B** (product, tech). Speak French by default; one Derja sentence at the opening.

| Slide | Time | Speaker | Script |
| --- | --- | --- | --- |
| 1 Opening | 0:00–0:20 | A | « قدم يعني خطوة… وقدم يعني الساق. » Qadam veut dire le pied, et le pas. Nous avons construit un pas de 10 secondes par jour qui peut éviter une amputation. |
| 2 Human problem | 0:20–1:00 | A | Voici Am Hédi — un personnage fictif, mais vous le connaissez tous. 62 ans, diabétique depuis 15 ans, une plaie au pied l'an dernier, il ne sent plus bien ses pieds. L'hiver, il les chauffe près du kanoun. Une inflammation commence sous son avant-pied droit : il ne la sent pas. Quand il verra la plaie, il sera déjà tard. En Tunisie, 1,4 million d'adultes vivent avec le diabète ; un sur trois ne le sait pas. |
| 3 Why current care fails | 1:00–1:40 | A | Aujourd'hui, la surveillance repose sur l'auto-examen : à Tunis, seuls 22 % des patients hospitalisés regardent leurs pieds chaque jour. Le médecin voit le pied tous les trois mois. Entre deux consultations : rien. Pourtant la science a un signal simple : un point plus chaud de 2,2 °C que le même point de l'autre pied, deux jours de suite. Ce suivi à domicile divise par deux le risque d'ulcère dans les essais — mais les outils existants sont importés, en anglais, et génèrent beaucoup de fausses alertes. |
| 4 Our solution | 1:40–2:10 | B | Qadam : un tapis, une app en derja, un tableau de bord pour l'équipe soignante. Le patient monte 10 secondes sur le tapis. Qadam compare gauche et droite, explique le résultat, dit quoi faire, et prévient le soignant — qui décide. |
| 5 User journey | 2:10–2:30 | B | Avant : on découvre la plaie, urgence, parfois amputation. Avec Qadam : alerte orange au jour 1, rouge au jour 2, le médecin confirme, rendez-vous le lendemain, décharge du pied. |
| 6 Live demo | 2:30–5:30 | B (+A on the phone) | **Live demo — docs/demo-script.md.** Green scan → warm the right sensor → amber → red in Derja → dashboard triage → evidence → confirm in 3 steps → patient sees the decision → danger sign in the assistant handled without AI. |
| 7 Technology | 5:30–6:00 | B | Arduino, deux capteurs, trames vérifiées par CRC, MQTT, un hub FastAPI conteneurisé, une app Flutter hors ligne et chiffrée. La détection est une règle publiée, testée dans deux langages avec les mêmes vecteurs. L'IA ne décide rien : elle explique, en derja, après un filtre de sécurité fixe. Données pseudonymisées, AES-256, audit infalsifiable, export FHIR. |
| 8 Effectiveness | 6:00–6:20 | B | Ce que nous avons prouvé aujourd'hui : la chaîne complète fonctionne, 50+ tests automatisés passent. Ce que nous n'avons pas encore prouvé : le bénéfice clinique en Tunisie. Notre pilote mesurera l'adhésion, la précision des alertes, le délai de revue et les ulcères détectés avant ouverture. |
| 9 Market | 6:20–6:40 | A | Premier segment : les patients à haut risque suivis par les cliniques et endocrinologues privés à Tunis, Sfax, Sousse. Puis les services publics, puis la CNAM. Puis le Maghreb. |
| 10 Business model | 6:40–7:00 | A | La clinique paie un abonnement par patient suivi, tapis prêté inclus. Le journal glycémie et l'éducation restent gratuits. Objectif : remboursement CNAM sur preuves. Ces prix sont des hypothèses que le pilote validera. |
| 11 Strategy | 7:00–7:15 | A | Un service d'endocrinologie partenaire pour le pilote, les pharmacies comme points de distribution, et des coûts maîtrisés : tapis à moins de 220 TND, un serveur par clinique. |
| 12 Trust & safety | 7:15–7:35 | B | Recommandation consultative, validation humaine, indice de confiance, mode démo et simulation toujours étiquetés. Avant un vrai pilote : déclaration INPDP, hébergement agréé, comité d'éthique, qualification dispositif médical. |
| 13 Roadmap | 7:35–7:50 | A | 3 mois : tapis 8 capteurs de contact, calibration, protocole. 6 mois : pilote de 30 à 50 patients. Ensuite : semelle, intégration hospitalière. |
| 14 Closing | 7:50–8:00 | A | Une amputation commence souvent par une chaleur que personne ne sent. Qadam la rend visible — et laisse le médecin décider. **Un pas par jour, pour garder ses pieds.** |

## Q&A — prepared answers (technical defence)

**Why not AI for detection?** No Tunisian dataset exists to train or validate it; the literature validates a simple
threshold. A published, explainable rule with a confidence index is safer for an SADM; AI is limited to language.

**DHT22 is not a skin sensor.** Correct — this bench proves the data chain. The mat design uses 8 DS18B20 contact
sensors (ESP32); first milestone is calibration against a reference thermometer (±0.3 °C target).

**False positives?** The reference smart-mat study reported 97 % sensitivity but 57 % false positives at 2.2 °C.
We add 2-day persistence, a measurement-quality index, and clinician review in 3 steps; the pilot measures precision.

**What if the network fails?** The app works offline (encrypted outbox, local rule, local safety library); the hub
runs on a laptop with SQLite and an embedded broker; Docker compose for reproducibility; backup hotspot.

**Scalability?** Stateless API + SQLite today; per-clinic hubs → PostgreSQL + managed MQTT/TLS → multi-tenant; FHIR
export prepares SIH integration. MQTT handles thousands of devices on one broker.

**Data governance?** Names never leave the phone; pseudonym on the hub; consent for sharing and AI; AES-256 at rest;
TLS 1.3 profile; hash-chained audit; export and erasure. INPDP declaration before any pilot.

**Who pays?** Clinics first (subscription with mat loan), CNAM later on evidence. All prices are hypotheses.

**Why Derja?** Comprehension is the bottleneck: 77 % poor foot-care knowledge in the Tunis study. Texts are drafts
pending native-speaker and clinician review.

**What did you generate with AI tools and can you explain it?** Every module is documented (README, architecture,
contracts); the team walks through the pipeline: firmware frame → CRC → MQTT → rule → alert → review.
