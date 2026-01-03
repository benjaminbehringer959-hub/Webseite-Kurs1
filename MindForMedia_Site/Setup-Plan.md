# Mind for Media - Setup Plan (WP + LearnDash + Polylang)

## 1) Ziel und Umfang
- WordPress Webseite fuer den 20-Tage-Kurs "Mind for Media".
- Landing Page + Onboarding + Kursbereich + Abschluss + Rechtliches.
- Mehrsprachig: DE/EN, Sprachwahl beim ersten Besuch + Sprachschalter im Header.
- Free Trial: Tage 1-5 frei, ab Tag 6 kostenpflichtig.
- Quiz pro Tag (3 Fragen), Reflexionsfragen, Konzentrationstest Tag 1 und 20 (Quiz-Auswertung reicht).

## 2) Empfohlener Stack
- CMS: WordPress 6.x
- LMS: LearnDash (Primary)
- Mehrsprachigkeit: Polylang
- Payment/Membership:
  - Entscheidung: Paid Memberships Pro + Stripe + PayPal
- Formulare (Onboarding/Feedback): WPForms Lite oder LearnDash Quiz (wenn moeglich)
- SEO: RankMath oder Yoast
- Cache: WP Super Cache / Host-Plugin
- Cookie/Consent: Nur noetig wenn Tracking o.ae. eingesetzt wird

## 3) Informationsarchitektur (Seiten)
- / (Landing)
- /onboarding (2-3 Fragen, Schrittanzeige)
- /vorwort
- /kurs (LearnDash Kurs-Startseite)
- /kurs/tag-1 bis /kurs/tag-20 (LearnDash Lektionen)
- /abschluss
- /datenschutz
- /impressum
- /agb
- optional: /feedback

## 4) Designvorschlag (modern, serioes, freundlich)
- Farben
  - Primary: #1E5D88
  - CTA: #2B7AB3
  - Creme BG: #F7F2EA
  - Text: #1F2430
- Typo
  - Headings: Manrope
  - Body: Source Sans 3
- UI
  - Radius 8-12px
  - Cards mit dezentem Schatten
  - Icons: schlicht (Lucide/Feather Stil)

## 5) Mehrsprachigkeit (Polylang)
- Default: DE, Secondary: EN
- Sprachwahl Overlay beim ersten Besuch
  - Wenn Browser-Sprache klar DE oder EN: vorauswaehlen
  - Speicherung der Wahl per Cookie/LocalStorage
- Sprachschalter im Header (DE | EN)
- Inhalte manuell uebersetzen (keine Auto-Translation live)

## 6) Kurslogik (LearnDash)
- Kurs "Mind for Media" mit 20 Lektionen
- Drip-Content:
  - Tag 1 sofort
  - Tag 2 nach 1 Tag, Tag 3 nach 2 Tagen, usw.
- Free Trial:
  - Tag 1-5 frei (Logged-in), Tag 6+ nur zahlend
- Fortschritt:
  - LearnDash Progress Bar aktivieren

## 7) Tagesstruktur (in jeder Lektion)
1. Einleitung
2. Aufgaben des Tages
3. Tipps (optional)
4. Fakt des Tages
5. Warum das funktioniert (Bonuswissen) + optional TTS Button
6. Quiz (3 Fragen, Single Choice, Checkbox-Optik via CSS)
7. Reflexionsfragen (4 Fragen, optional mit Notizfeldern ohne Speicherung)
8. Hinweis Konzentrationstest an Tag 1 und Tag 20 (Quiz-Auswertung)

## 8) Inhalte - Quelle Mapping
- Vorwort: `Inhalt/Vorwort.docx`
- Schlusswort/Abschluss: `Inhalt/Schlusswort.docx`
- Reflexionsfragen: `Inhalt/Reflexionsfragen.docx`
- Bonuswissen ("Warum das funktioniert"): `Inhalt/Bonuswissen.docx`
- Tages-Kurztexte: `Inhalt/Kurze Zusammenfassung.docx`
- Quizfragen: `Inhalt/Quisfragen.docx` (finale Quelle)
- Aufgaben: `Inhalt/Aufgaben.docx`
- Datei `Inhalt/falsch.docx` wirkt wie Rohfassung / Alternativen -> optional ignorieren

## 9) Rechtliches
Quelle: `Rechtliche Zusatzinfos.docx`
Anpassungen noetig:
- Text nennt Supabase (nicht passend zu WordPress) -> ersetzen durch WP/Hosting/Plugins
- Einige Platzhalter (Name, Adresse, Telefon) muessen final befuellt werden
- Cookies: nur noetige Cookies, Consent nur bei Tracking/Marketing

## 10) Offene Punkte / Entscheidungen
1) Rechtstexte: Finalen Betreiber, Adresse, Kontakt durchgeben.

## 11) Naechste Schritte (wenn du OK gibst)
- Content-Bausteine finalisieren (Aufgaben + Quiz-Quelle)
- Sprach-Overlay + Header-Switcher spezifizieren
- Erste Seitenstruktur in WordPress aufsetzen
- Muster-Lektion Tag 1 erstellen, Design und Formatierung testen

