$base = "C:\Users\Benja\OneDrive\gesamter Inhalt\Test 1\Kurs\Webseite\Webseite Kurs1"
$siteDir = Join-Path $base "MindForMedia_Site\site"
$assetDir = Join-Path $siteDir "assets"

function Get-DocxText($path){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  if (-not (Test-Path -LiteralPath $path)) { return "" }
  $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
  try {
    $entry = $zip.GetEntry("word/document.xml")
    if ($null -eq $entry) { return "" }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try {
      $xml = $reader.ReadToEnd()
    } finally {
      $reader.Close()
    }
  } finally {
    $zip.Dispose()
  }
  return ($xml -replace '<w:p[^>]*>',"`n" -replace '<[^>]+>','')
}
function HtmlEncode($text){ return [System.Net.WebUtility]::HtmlEncode($text) }
function To-Paragraphs($text){
  if ($null -eq $text) { return "" }
  $clean = $text.Trim()
  if (-not $clean) { return "" }
  $parts = $clean -split "`n`n+"
  $paras = @()
  foreach ($p in $parts) {
    $line = ($p -replace "`n", " ").Trim()
    if ($line) { $paras += ("<p>" + (HtmlEncode $line) + "</p>") }
  }
  return ($paras -join "`n")
}
function Split-ByTag($text, $pattern, $groupIndex){
  $map = @{}
  $matches = [regex]::Matches($text, $pattern)
  for ($i=0; $i -lt $matches.Count; $i++) {
    $m = $matches[$i]
    $day = [int]$m.Groups[$groupIndex].Value
    $start = $m.Index + $m.Length
    $end = if ($i+1 -lt $matches.Count) { $matches[$i+1].Index } else { $text.Length }
    $section = $text.Substring($start, $end - $start).Trim()
    $map[$day] = $section
  }
  return $map
}
function Extract-SideFact($bonusText){
  $m = [regex]::Match($bonusText, 'Side Fact:\s*([^\n]+)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ""
}
function Convert-TasksToHtml($tasksText){
  if ($null -eq $tasksText) { return "" }
  $lines = $tasksText -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and $_ -ne "---" }
  $items = @()
  $current = $null
  foreach ($line in $lines) {
    if ($line -match '^(?:\*\*)?Aufgabe\s+(\d+):(?:\*\*)?\s*(.+)$') {
      if ($current) { $items += $current }
      $current = [ordered]@{ title = "Aufgabe $($matches[1])"; desc = $matches[2]; example = $null }
      continue
    }
    if ($line -match '^(?:\*\*)?Bonus:(?:\*\*)?\s*(.+)$') {
      if ($current) { $items += $current }
      $current = [ordered]@{ title = "Bonus"; desc = $matches[1]; example = $null }
      continue
    }
    if ($line -match '^(?:\*\s*\*Beispiel:\*\s*|Beispiel:\s*)(.+)$') {
      if ($current) { $current.example = $matches[1] }
      continue
    }
    if ($current) {
      if ($current.desc) { $current.desc += " " + $line } else { $current.desc = $line }
    }
  }
  if ($current) { $items += $current }
  $html = @()
  foreach ($it in $items) {
    $html += "<div class='task-card'>"
    $html += "<h4>" + (HtmlEncode $it.title) + "</h4>"
    $html += "<p>" + (HtmlEncode ($it.desc -replace '\s+', ' ')) + "</p>"
    if ($it.example) { $html += "<p class='task-example'><span>Beispiel:</span> " + (HtmlEncode $it.example) + "</p>" }
    $html += "</div>"
  }
  return ($html -join "`n")
}
function Convert-QuizToHtml($quizText, $day){
  if ($null -eq $quizText) { return "" }
  $blocks = [regex]::Split($quizText.Trim(), '(?m)^Frage\s+\d+\s*$') | Where-Object { $_.Trim() -ne "" }
  $html = @()
  $qIndex = 0
  foreach ($b in $blocks) {
    $qIndex++
    $qMatch = [regex]::Match($b, 'Frage:\s*(.+)')
    $question = if ($qMatch.Success) { $qMatch.Groups[1].Value.Trim() } else { "" }
    $opts = @{}
    foreach ($opt in @('A','B','C','D')) {
      $m = [regex]::Match($b, '^' + $opt + ':\s*(.+)$', 'Multiline')
      if ($m.Success) { $opts[$opt] = $m.Groups[1].Value.Trim() }
    }
    $correct = ([regex]::Match($b, 'Richtig:\s*([A-D])')).Groups[1].Value
    $explain = ([regex]::Match($b, 'Mini-Erkl.*?:\s*(.+)')).Groups[1].Value.Trim()

    $html += "<div class='quiz-card' data-answer='$correct'>"
    $html += "<p class='quiz-question'><strong>Frage ${qIndex}:</strong> " + (HtmlEncode $question) + "</p>"
    $html += "<div class='quiz-options'>"
    foreach ($opt in @('A','B','C','D')) {
      if ($opts.ContainsKey($opt)) {
        $id = "q${day}_${qIndex}_${opt}"
        $html += "<label class='quiz-option'><input type='radio' name='q${day}_${qIndex}' value='$opt' id='$id'><span class='box'></span><span class='opt-text'>" + (HtmlEncode ($opt + ': ' + $opts[$opt])) + "</span></label>"
      }
    }
    $html += "</div>"
    if ($explain) { $html += "<p class='quiz-explain' hidden>" + (HtmlEncode $explain) + "</p>" }
    $html += "</div>"
  }
  return ($html -join "`n")
}
function Convert-ReflexToHtml($reflexText){
  if ($null -eq $reflexText) { return "" }
  $lines = $reflexText -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
  $questions = $lines | Where-Object { $_ -notmatch '^-' }
  $html = @()
  $i = 0
  foreach ($q in $questions) {
    $i++
    $html += "<div class='reflex-item'>"
    $html += "<p><strong>Frage ${i}:</strong> " + (HtmlEncode $q) + "</p>"
    $html += "<textarea rows='3' placeholder='Notiere deine Gedanken (nur fuer dich)'></textarea>"
    $html += "</div>"
  }
  return ($html -join "`n")
}
function Build-Page($title, $body, $pageId){
@"
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<link rel="stylesheet" href="assets/styles.css">
</head>
<body data-page="$pageId">
<a class="skip-link" href="#main">Zum Inhalt</a>
<div class="lang-overlay" id="langOverlay" aria-hidden="true">
  <div class="lang-card">
    <h2>Sprache waehlen</h2>
    <p>Bitte waehle deine Sprache. Du kannst sie spaeter in der Navigation aendern.</p>
    <div class="lang-actions">
      <button class="btn primary" data-lang="de">Deutsch</button>
      <button class="btn ghost" data-lang="en" title="Coming soon">English (bald)</button>
    </div>
  </div>
</div>
<header class="site-header">
  <div class="container">
    <div class="brand">
      <div class="logo-dot"></div>
      <div class="brand-text">Mind for Media</div>
    </div>
    <nav class="nav">
      <a href="index.html">Start</a>
      <a href="kurs.html">Kurs</a>
      <a href="onboarding.html">Onboarding</a>
      <a href="vorwort.html">Vorwort</a>
      <a href="abschluss.html">Abschluss</a>
    </nav>
    <div class="header-actions">
      <div class="lang-switch">
        <button class="lang-btn active" data-lang="de">DE</button>
        <button class="lang-btn" data-lang="en" title="Coming soon">EN</button>
      </div>
      <a class="btn primary" href="onboarding.html">Kostenlos testen</a>
    </div>
  </div>
</header>
<main id="main">
$body
</main>
<footer class="site-footer">
  <div class="container footer-grid">
    <div>
      <div class="brand small">
        <div class="logo-dot"></div>
        <div class="brand-text">Mind for Media</div>
      </div>
      <p>Ein 20-Tage-Kurs fuer mehr Fokus beim Lernen.</p>
    </div>
    <div class="footer-links">
      <a href="datenschutz.html">Datenschutz</a>
      <a href="impressum.html">Impressum</a>
      <a href="agb.html">AGB</a>
    </div>
  </div>
</footer>
<script src="assets/app.js"></script>
</body>
</html>
"@
}

$inDir = Join-Path $base "Inhalt"
$textSummary = Get-DocxText (Join-Path $inDir "Kurze Zusammenfassung.docx")
$textTasks = Get-DocxText (Join-Path $inDir "Aufgaben.docx")
$textBonus = Get-DocxText (Join-Path $inDir "Bonuswissen.docx")
$textQuiz = Get-DocxText (Join-Path $inDir "Quisfragen.docx")
$textReflex = Get-DocxText (Join-Path $inDir "Reflexionsfragen.docx")
$textVorwort = Get-DocxText (Join-Path $inDir "Vorwort.docx")
$textSchluss = Get-DocxText (Join-Path $inDir "Schlusswort.docx")

$dash = [char]0x2013
$textTasks = $textTasks -replace "(?m)^Tag\s+(\d+)\s+-","## Tag $1 -"
$textTasks = $textTasks.Replace(("Tag 19 " + $dash), "## Tag 19 -")

$summaryMap = Split-ByTag $textSummary "(?m)^\s*Tag\s+(\d+)\s*:" 1
$bonusMap = Split-ByTag $textBonus "(?m)^\s*Tag\s+(\d+)\s*:" 1
$tasksMap = Split-ByTag $textTasks "(?m)^\s*##\s*Tag\s+(\d+)\b[^\n]*" 1
$quizMap = Split-ByTag $textQuiz "(?m)^\s*Tag\s+(\d+)\s*$" 1
$reflexMap = Split-ByTag $textReflex "(?m)^\s*TAG\s+(\d+)\b[^\n]*" 1

$landingBody = @'
<section class="hero">
  <div class="container hero-grid">
    <div>
      <p class="eyebrow">20 Tage gegen Ablenkung</p>
      <h1>Mind for Media - Dein 20-Tage-Kurs gegen Ablenkung beim Lernen</h1>
      <p class="lead">Ein strukturiertes Programm fuer mehr Fokus, weniger Social-Media-Impuls und ein ruhigeres Lerngefuehl. Schritt fuer Schritt, alltagstauglich, ohne Druck.</p>
      <div class="hero-actions">
        <a class="btn primary" href="onboarding.html">Kostenlos testen</a>
        <a class="btn ghost" href="kurs.html">Kurs ansehen</a>
      </div>
      <div class="hero-badges">
        <span>5 Tage kostenlos</span>
        <span>Taegliche Lektionen</span>
        <span>Quiz + Reflexion</span>
      </div>
    </div>
    <div class="hero-card" data-reveal>
      <h3>Was dich erwartet</h3>
      <ul>
        <li>klare Tagesstruktur</li>
        <li>kurze Aufgaben mit Wirkung</li>
        <li>Bonuswissen und Mini-Quizzes</li>
        <li>Reflexion fuer echte Aenderung</li>
      </ul>
      <div class="progress-mock">
        <div class="progress-bar" style="width:25%"></div>
      </div>
      <p class="small">Beispielhafter Fortschritt</p>
    </div>
  </div>
</section>
<section class="section">
  <div class="container">
    <h2>Vorteile auf einen Blick</h2>
    <div class="grid three">
      <div class="card" data-reveal><h3>Fokus verbessern</h3><p>Steigere deine Konzentration beim Lernen und lass dich weniger ablenken.</p></div>
      <div class="card" data-reveal><h3>Bildschirmzeit senken</h3><p>Reduziere unnoetige Handyzeit und gewinne mehr Klarheit im Alltag.</p></div>
      <div class="card" data-reveal><h3>Entspannter lernen</h3><p>Ohne staendige Impulse lernst du ruhiger und effektiver.</p></div>
    </div>
  </div>
</section>
<section class="section muted">
  <div class="container">
    <h2>So funktioniert der Kurs</h2>
    <div class="grid two">
      <div class="card" data-reveal><h3>Tag 1-5 kostenlos</h3><p>Starte direkt, teste die ersten Tage und erlebe den Ablauf.</p></div>
      <div class="card" data-reveal><h3>Tag 6-20 Pro</h3><p>Ab Tag 6 schaltest du den vollen Kurs mit allen Inhalten frei.</p></div>
    </div>
  </div>
</section>
<section class="section">
  <div class="container">
    <h2>Stimmen von Teilnehmenden</h2>
    <div class="grid three">
      <blockquote class="quote" data-reveal>"Dank Mind for Media kann ich mich endlich besser aufs Lernen konzentrieren."<span>Anna, 20</span></blockquote>
      <blockquote class="quote" data-reveal>"Ich haette nie gedacht, dass kleine Schritte so viel Ruhe bringen."<span>Jamal, 22</span></blockquote>
      <blockquote class="quote" data-reveal>"Der Kurs ist klar strukturiert und mega alltagstauglich."<span>Lea, 19</span></blockquote>
    </div>
  </div>
</section>
<section class="cta">
  <div class="container">
    <h2>Starte heute mit den ersten 5 Tagen kostenlos</h2>
    <p>Ohne Druck. Ohne Verpflichtung. Einfach ausprobieren.</p>
    <a class="btn primary" href="onboarding.html">Kostenlos testen</a>
  </div>
</section>
'@

$landing = Build-Page "Mind for Media - Kursstart" $landingBody "landing"
$landing | Out-File -FilePath (Join-Path $siteDir "index.html") -Encoding utf8

$onboardingBody = @'
<section class="section">
  <div class="container narrow">
    <h1>Onboarding</h1>
    <p class="lead">Beantworte kurz ein paar Fragen, damit du bewusst startest.</p>
    <div class="progress-wrap"><div class="progress-bar" id="onboardingProgress"></div></div>
    <form id="onboardingForm">
      <div class="step active">
        <h3>Frage 1 von 3</h3>
        <label>Warum moechtest du deinen Umgang mit Social Media veraendern?</label>
        <textarea rows="5" placeholder="Deine Antwort"></textarea>
        <button type="button" class="btn primary next">Weiter</button>
      </div>
      <div class="step">
        <h3>Frage 2 von 3</h3>
        <label>Wie oft fuehlst du dich beim Lernen abgelenkt?</label>
        <div class="choices">
          <label><input type="radio" name="freq"><span class="box"></span> Staendig</label>
          <label><input type="radio" name="freq"><span class="box"></span> Sehr oft</label>
          <label><input type="radio" name="freq"><span class="box"></span> Manchmal</label>
          <label><input type="radio" name="freq"><span class="box"></span> Selten</label>
          <label><input type="radio" name="freq"><span class="box"></span> Nie</label>
        </div>
        <button type="button" class="btn primary next">Weiter</button>
      </div>
      <div class="step">
        <h3>Frage 3 von 3 (optional)</h3>
        <label>Wie viele Stunden bist du durchschnittlich pro Tag am Smartphone?</label>
        <input type="text" placeholder="z. B. 2-3 Stunden">
        <button type="button" class="btn primary finish">Fertig</button>
      </div>
    </form>
  </div>
</section>
'@
$onboarding = Build-Page "Onboarding - Mind for Media" $onboardingBody "onboarding"
$onboarding | Out-File -FilePath (Join-Path $siteDir "onboarding.html") -Encoding utf8

$vorwortBody = @"
<section class="section">
  <div class="container narrow">
    <h1>Willkommen zum Mind for Media Kurs</h1>
    <div class="rich-text">
    $(To-Paragraphs $textVorwort)
    </div>
    <a class="btn primary" href="kurs.html">Zum Kursstart</a>
  </div>
</section>
"@
$vorwort = Build-Page "Vorwort - Mind for Media" $vorwortBody "vorwort"
$vorwort | Out-File -FilePath (Join-Path $siteDir "vorwort.html") -Encoding utf8

$abschlussBody = @"
<section class="section confetti">
  <div class="container narrow">
    <h1>Glueckwunsch zum Abschluss!</h1>
    <div class="rich-text">
    $(To-Paragraphs $textSchluss)
    </div>
    <div class="card">
      <h3>Feedback (optional)</h3>
      <form class="feedback">
        <label>Wie zufrieden bist du mit dem Kurs?</label>
        <input type="text" placeholder="z. B. 1-5">
        <label>Was hat dir am besten gefallen?</label>
        <textarea rows="3"></textarea>
        <label>Hast du Verbesserungsvorschlaege?</label>
        <textarea rows="3"></textarea>
        <button type="button" class="btn primary">Absenden</button>
      </form>
    </div>
  </div>
</section>
"@
$abschluss = Build-Page "Abschluss - Mind for Media" $abschlussBody "abschluss"
$abschluss | Out-File -FilePath (Join-Path $siteDir "abschluss.html") -Encoding utf8

$cards = @()
for ($day=1; $day -le 20; $day++) {
  $sum = $summaryMap[$day]
  $snippet = if ($sum) { ($sum -replace "\s+"," ").Trim() } else { "" }
  if ($snippet.Length -gt 140) { $snippet = $snippet.Substring(0,140) + "..." }
  $locked = $day -ge 6
  $badge = if ($day -le 5) { "Kostenlos" } else { "Pro" }
  $class = if ($locked) { "day-card locked" } else { "day-card" }
  $status = if ($locked) { '<span class="lock">Gesperrt ab Tag 6</span>' } else { '<span class="open">Starten</span>' }
  $card = "<a class='$class' href='tag-" + $day.ToString("00") + ".html'><div class='day-num'>Tag $day</div><div class='day-badge'>$badge</div><p>" + (HtmlEncode $snippet) + "</p>$status</a>"
  $cards += $card
}
$kursBody = @"
<section class="section">
  <div class="container">
    <h1>Kursuebersicht</h1>
    <div class="progress-wrap"><div class="progress-bar" style="width:0%"></div></div>
    <p class="small">Fortschritt: 0% abgeschlossen</p>
    <div class="grid three">$($cards -join '')</div>
  </div>
</section>
"@
$kurs = Build-Page "Kursuebersicht - Mind for Media" $kursBody "kurs"
$kurs | Out-File -FilePath (Join-Path $siteDir "kurs.html") -Encoding utf8

for ($day=1; $day -le 20; $day++) {
  $summary = To-Paragraphs $summaryMap[$day]
  $tasks = Convert-TasksToHtml $tasksMap[$day]
  $bonus = To-Paragraphs $bonusMap[$day]
  $quiz = Convert-QuizToHtml $quizMap[$day] $day
  $reflex = Convert-ReflexToHtml $reflexMap[$day]

  $fact = Extract-SideFact $bonusMap[$day]
  $factHtml = if ($fact) { "<div class='fact'><strong>Fakt des Tages:</strong> " + (HtmlEncode $fact) + "</div>" } else { "" }
  $testHtml = if ($day -eq 1 -or $day -eq 20) { "<div class='card'><h3>Konzentrationstest</h3><p>Kurztest 5-10 Minuten. Ergebnis notieren, um spaeter zu vergleichen.</p></div>" } else { "" }

  $body = @"
<section class="section">
  <div class="container narrow">
    <p class="eyebrow">Tag $day</p>
    <h1>Tag $day</h1>
    <div class="rich-text">$summary</div>
    $testHtml
    <h2>Aufgaben des Tages</h2>
    <div class="task-grid">$tasks</div>
    $factHtml
    <h2>Warum das funktioniert</h2>
    <button class="btn ghost tts" data-tts="bonus-$day">Anhoeren</button>
    <div class="rich-text" id="bonus-$day">$bonus</div>
    <h2>Quiz</h2>
    <div class="quiz">$quiz</div>
    <button class="btn primary quiz-check">Antworten pruefen</button>
    <h2>Reflexion</h2>
    <p class="small">Notiere deine Gedanken nur fuer dich. Es wird nichts gespeichert.</p>
    <div class="reflex">$reflex</div>
  </div>
</section>
"@

  $page = Build-Page "Tag $day - Mind for Media" $body "day-$day"
  $path = Join-Path $siteDir ("tag-" + $day.ToString("00") + ".html")
  $page | Out-File -FilePath $path -Encoding utf8
}

$impressumBody = @'
<section class="section">
<div class="container narrow">
<h1>Impressum</h1>
<p><strong>Betreiber:</strong> [Name des Betreibers]</p>
<p><strong>Anschrift:</strong> [Strasse, PLZ Ort, Land]</p>
<p><strong>Kontakt:</strong> [E-Mail] | [Telefon]</p>
<p><strong>Verantwortlich fuer den Inhalt:</strong> [Name, Adresse]</p>
<p><strong>Unternehmensangaben:</strong> [z. B. Kleinunternehmer nach §19 UStG]</p>
<p>Hinweis gem. §36 VSBG: Keine Teilnahme an Streitbeilegungsverfahren.</p>
</div></section>
'@
(Build-Page "Impressum" $impressumBody "impressum") | Out-File -FilePath (Join-Path $siteDir "impressum.html") -Encoding utf8

$datenschutzBody = @'
<section class="section">
<div class="container narrow">
<h1>Datenschutzerklaerung</h1>
<p>Diese Datenschutzerklaerung ist ein Entwurf und muss mit den finalen Betreiber- und Dienstleisterdaten befuellt werden.</p>
<h2>1. Verantwortliche Stelle</h2>
<p>[Name, Anschrift, Kontakt]</p>
<h2>2. Verarbeitete Daten</h2>
<p>Registrierungsdaten, Nutzungsdaten (Kursfortschritt), Zahlungsdaten ueber Stripe/PayPal.</p>
<h2>3. Zweck der Verarbeitung</h2>
<p>Bereitstellung des Kurses, Abwicklung der Zahlung, Support.</p>
<h2>4. Rechtsgrundlagen</h2>
<p>Art. 6 Abs. 1 lit. b (Vertrag), lit. f (berechtigtes Interesse), lit. c (gesetzliche Pflichten).</p>
<h2>5. Dienstleister</h2>
<p>WordPress Hosting, LearnDash, Paid Memberships Pro, Stripe, PayPal, Polylang.</p>
<h2>6. Speicherfristen</h2>
<p>Nach gesetzlichen Vorgaben (z. B. 10 Jahre fuer Rechnungen).</p>
<h2>7. Cookies</h2>
<p>Nur technisch notwendige Cookies. Consent-Tool bei Tracking.</p>
<h2>8. Rechte</h2>
<p>Auskunft, Berichtigung, Loeschung, Widerspruch, Datenuebertragbarkeit, Beschwerde.</p>
</div></section>
'@
(Build-Page "Datenschutz" $datenschutzBody "datenschutz") | Out-File -FilePath (Join-Path $siteDir "datenschutz.html") -Encoding utf8

$agbBody = @'
<section class="section">
<div class="container narrow">
<h1>AGB / Nutzungsbedingungen</h1>
<p>Diese AGB sind ein Entwurf und muessen mit den finalen Betreiber- und Preisinformationen befuellt werden.</p>
<h2>1. Anbieter</h2>
<p>[Name, Anschrift]</p>
<h2>2. Registrierung</h2>
<p>Nutzerkonto erforderlich. Minderjaehrige nur mit Zustimmung der Erziehungsberechtigten.</p>
<h2>3. Testphase</h2>
<p>Tag 1-5 kostenlos, danach Abo.</p>
<h2>4. Zahlung</h2>
<p>Zahlung ueber Stripe oder PayPal. Abo monatlich, jederzeit kuendbar.</p>
<h2>5. Widerruf</h2>
<p>14 Tage Widerrufsrecht, gesetzliche Regelungen beachten.</p>
</div></section>
'@
(Build-Page "AGB" $agbBody "agb") | Out-File -FilePath (Join-Path $siteDir "agb.html") -Encoding utf8

$css = @'
:root {
  --blue-900: #1E5D88;
  --blue-700: #2B7AB3;
  --cream: #F7F2EA;
  --ink: #1F2430;
  --muted: #5B6575;
  --card: #ffffff;
  --shadow: 0 12px 30px rgba(30, 93, 136, 0.12);
  --radius: 12px;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: "Source Sans 3", "Manrope", sans-serif;
  color: var(--ink);
  background: linear-gradient(160deg, #fdf8f1 0%, #f6f0e6 40%, #eef5fb 100%);
}
.container { width: min(1100px, 92%); margin: 0 auto; }
.container.narrow { width: min(800px, 92%); }
.skip-link { position: absolute; left: -999px; top: -999px; }
.skip-link:focus { left: 16px; top: 16px; background: #fff; padding: 8px 12px; z-index: 999; }
.site-header { position: sticky; top: 0; z-index: 10; background: rgba(247, 242, 234, 0.9); backdrop-filter: blur(8px); border-bottom: 1px solid rgba(30, 93, 136, 0.08); }
.site-header .container { display: flex; align-items: center; justify-content: space-between; padding: 14px 0; }
.brand { display: flex; align-items: center; gap: 10px; font-weight: 700; }
.brand.small { font-size: 0.9rem; }
.logo-dot { width: 12px; height: 12px; background: var(--blue-700); border-radius: 50%; box-shadow: 0 0 0 4px rgba(43, 122, 179, 0.15); }
.nav { display: flex; gap: 18px; }
.nav a { text-decoration: none; color: var(--ink); font-weight: 600; }
.header-actions { display: flex; align-items: center; gap: 12px; }
.btn { display: inline-flex; align-items: center; justify-content: center; padding: 10px 18px; border-radius: 999px; border: 1px solid transparent; text-decoration: none; font-weight: 700; cursor: pointer; }
.btn.primary { background: var(--blue-700); color: #fff; box-shadow: var(--shadow); }
.btn.ghost { background: transparent; border-color: var(--blue-700); color: var(--blue-700); }
.lang-switch { display: flex; background: #fff; border-radius: 999px; padding: 4px; border: 1px solid rgba(30,93,136,0.15); }
.lang-btn { background: none; border: 0; padding: 6px 10px; border-radius: 999px; cursor: pointer; }
.lang-btn.active { background: var(--blue-700); color: #fff; }
.hero { padding: 70px 0 40px; }
.hero-grid { display: grid; grid-template-columns: 1.2fr 0.8fr; gap: 30px; align-items: center; }
.hero h1 { font-family: "Manrope", sans-serif; font-size: clamp(2rem, 4vw, 3.2rem); margin: 10px 0; }
.lead { font-size: 1.1rem; color: var(--muted); }
.hero-actions { display: flex; gap: 12px; margin: 18px 0; flex-wrap: wrap; }
.hero-badges { display: flex; gap: 10px; flex-wrap: wrap; }
.hero-badges span { background: #fff; padding: 6px 10px; border-radius: 999px; border: 1px solid rgba(30,93,136,0.1); font-size: 0.85rem; }
.hero-card { background: #fff; padding: 22px; border-radius: var(--radius); box-shadow: var(--shadow); }
.progress-mock { height: 8px; background: #e3e7ef; border-radius: 999px; margin: 14px 0; overflow: hidden; }
.progress-mock .progress-bar { height: 100%; background: var(--blue-700); }
.section { padding: 60px 0; }
.section.muted { background: rgba(255,255,255,0.6); }
.section h2 { font-family: "Manrope", sans-serif; }
.grid { display: grid; gap: 18px; }
.grid.two { grid-template-columns: repeat(2, minmax(0,1fr)); }
.grid.three { grid-template-columns: repeat(3, minmax(0,1fr)); }
.card { background: #fff; padding: 20px; border-radius: var(--radius); box-shadow: var(--shadow); }
.quote { background: #fff; padding: 20px; border-radius: var(--radius); box-shadow: var(--shadow); font-style: italic; }
.quote span { display: block; margin-top: 10px; font-weight: 700; font-style: normal; }
.cta { padding: 50px 0; background: linear-gradient(140deg, #e5f1fb, #f6f0e6); text-align: center; }
.eyebrow { letter-spacing: 0.12em; text-transform: uppercase; font-size: 0.75rem; color: var(--muted); }
.small { font-size: 0.9rem; color: var(--muted); }
.task-grid { display: grid; gap: 12px; }
.task-card { background: #fff; padding: 16px; border-radius: var(--radius); box-shadow: var(--shadow); }
.task-example { font-size: 0.9rem; color: var(--muted); }
.task-example span { font-weight: 700; }
.rich-text p { line-height: 1.7; }
.fact { margin: 16px 0; padding: 12px; border-left: 4px solid var(--blue-700); background: rgba(43, 122, 179, 0.08); border-radius: 8px; }
.quiz { display: grid; gap: 12px; }
.quiz-card { background: #fff; padding: 16px; border-radius: var(--radius); box-shadow: var(--shadow); }
.quiz-options { display: grid; gap: 8px; margin-top: 8px; }
.quiz-option { display: flex; gap: 10px; align-items: center; cursor: pointer; }
.quiz-option input { display: none; }
.quiz-option .box { width: 18px; height: 18px; border: 2px solid var(--blue-700); border-radius: 4px; }
.quiz-option input:checked + .box { background: var(--blue-700); }
.quiz-explain { margin-top: 8px; color: var(--muted); }
.reflex { display: grid; gap: 12px; }
.reflex textarea { width: 100%; padding: 10px; border-radius: 10px; border: 1px solid #d0d6e1; }
.progress-wrap { height: 8px; background: #e3e7ef; border-radius: 999px; margin: 12px 0; overflow: hidden; }
.progress-wrap .progress-bar { height: 100%; background: var(--blue-700); width: 33%; }
.day-card { display: block; text-decoration: none; background: #fff; padding: 16px; border-radius: var(--radius); box-shadow: var(--shadow); color: var(--ink); position: relative; }
.day-card.locked { opacity: 0.7; }
.day-num { font-weight: 700; margin-bottom: 6px; }
.day-badge { position: absolute; top: 12px; right: 12px; background: var(--blue-700); color: #fff; padding: 4px 10px; border-radius: 999px; font-size: 0.75rem; }
.lock { display: inline-block; margin-top: 10px; color: var(--muted); }
.open { display: inline-block; margin-top: 10px; color: var(--blue-700); font-weight: 700; }
.site-footer { background: #1f2430; color: #f0f2f5; padding: 30px 0; }
.footer-grid { display: flex; justify-content: space-between; gap: 20px; }
.footer-links { display: flex; gap: 16px; align-items: center; }
.footer-links a { color: #f0f2f5; text-decoration: none; }
.lang-overlay { position: fixed; inset: 0; background: rgba(31,36,48,0.5); display: none; align-items: center; justify-content: center; z-index: 20; }
.lang-overlay.show { display: flex; }
.lang-card { background: #fff; padding: 24px; border-radius: var(--radius); width: min(420px, 90%); box-shadow: var(--shadow); }
.lang-actions { display: flex; gap: 10px; margin-top: 10px; }
.step { display: none; }
.step.active { display: block; }
.choices { display: grid; gap: 8px; margin: 12px 0; }
.choices label { display: flex; align-items: center; gap: 10px; }
.choices input { display: none; }
.choices .box { width: 18px; height: 18px; border: 2px solid var(--blue-700); border-radius: 4px; }
.choices input:checked + .box { background: var(--blue-700); }
.confetti { background-image: radial-gradient(circle at 10% 10%, rgba(43,122,179,0.2), transparent 40%), radial-gradient(circle at 90% 20%, rgba(30,93,136,0.2), transparent 40%); }
@media (max-width: 900px) {
  .hero-grid { grid-template-columns: 1fr; }
  .grid.two, .grid.three { grid-template-columns: 1fr; }
  .nav { display: none; }
  .footer-grid { flex-direction: column; }
}
'@
$css | Out-File -FilePath (Join-Path $assetDir "styles.css") -Encoding utf8

$js = @'
(function(){
  const overlay = document.getElementById('langOverlay');
  const langButtons = document.querySelectorAll('[data-lang]');
  const stored = localStorage.getItem('mfm_lang');
  const browser = navigator.language || 'de';
  const defaultLang = stored || (browser.startsWith('en') ? 'en' : 'de');

  function setLang(lang){
    localStorage.setItem('mfm_lang', lang);
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });
    if (lang === 'en') {
      alert('English content is coming soon.');
    }
    if (overlay) { overlay.classList.remove('show'); overlay.setAttribute('aria-hidden', 'true'); }
  }

  if (!stored && overlay) {
    overlay.classList.add('show');
    overlay.setAttribute('aria-hidden', 'false');
  }

  if (overlay) {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) setLang(defaultLang);
    });
  }

  langButtons.forEach(btn => {
    btn.addEventListener('click', () => setLang(btn.dataset.lang));
  });

  const form = document.getElementById('onboardingForm');
  if (form) {
    const steps = form.querySelectorAll('.step');
    let index = 0;
    const progress = document.getElementById('onboardingProgress');
    const show = (i) => {
      steps.forEach((s, idx) => s.classList.toggle('active', idx === i));
      if (progress) progress.style.width = ((i+1)/steps.length*100) + '%';
    };
    form.addEventListener('click', (e) => {
      if (e.target.classList.contains('next')) { index = Math.min(index+1, steps.length-1); show(index); }
      if (e.target.classList.contains('finish')) { window.location.href = 'vorwort.html'; }
    });
    show(index);
  }

  document.querySelectorAll('.quiz-check').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.quiz-card').forEach(card => {
        const answer = card.getAttribute('data-answer');
        const checked = card.querySelector('input:checked');
        const explain = card.querySelector('.quiz-explain');
        if (checked && explain) {
          explain.hidden = false;
          if (checked.value === answer) {
            explain.insertAdjacentText('afterbegin', 'Richtig: ');
          } else {
            explain.insertAdjacentText('afterbegin', 'Nicht ganz: ');
          }
        }
      });
    });
  });

  document.querySelectorAll('.tts').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tts');
      const target = document.getElementById(targetId);
      if (!target) return;
      const text = target.innerText;
      if ('speechSynthesis' in window) {
        const u = new SpeechSynthesisUtterance(text);
        u.lang = 'de-DE';
        speechSynthesis.cancel();
        speechSynthesis.speak(u);
      }
    });
  });
})();
'@
$js | Out-File -FilePath (Join-Path $assetDir "app.js") -Encoding utf8

Write-Output "done"
