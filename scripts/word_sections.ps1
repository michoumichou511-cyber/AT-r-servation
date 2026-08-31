# Sections + en-tetes par chapitre via Word COM (valide par construction)
$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
  $doc = $word.Documents.Open("C:\Users\loulou\ProjetFinFormation\Memoir_MASTER.docx")

  # ── 1. inserer un saut de section (page suivante) AVANT chaque titre ──
  $targets = @("CHAPITRE II", "CHAPITRE III", "CHAPITRE IV", "Conclusion Générale")
  foreach ($t in $targets) {
    $find = $word.Selection.Find
    $word.Selection.HomeKey(6) | Out-Null          # wdStory
    $find.ClearFormatting()
    $find.Text = $t
    $find.Forward = $true
    $find.Wrap = 0                                  # wdFindStop
    if ($find.Execute()) {
      $rng = $word.Selection.Range
      $rng.Collapse(1)                              # wdCollapseStart
      $rng.InsertBreak(2)                           # wdSectionBreakNextPage
      Write-Output "section inseree avant : $t"
    } else {
      Write-Output "INTROUVABLE : $t"
    }
  }

  # ── 2. reperer les sections par leur premier texte ──
  $blue  = 10763008    # BGR de #003DA5 -> 0xA53D00
  $green = 5285376     # BGR de #00A650 -> 0x50A600
  $titles = @{
    "CHAPITRE II"  = "Chapitre II " + [char]0x2014 + " Analyse et Sp" + [char]0xE9 + "cification des Besoins"
    "CHAPITRE III" = "Chapitre III " + [char]0x2014 + " Conception de l'application"
    "CHAPITRE IV"  = "Chapitre IV " + [char]0x2014 + " R" + [char]0xE9 + "alisation"
  }
  for ($i = 1; $i -le $doc.Sections.Count; $i++) {
    $sec = $doc.Sections.Item($i)
    $first = $sec.Range.Text.Substring(0, [Math]::Min(40, $sec.Range.Text.Length)).Trim()
    $key = $null
    foreach ($k in $titles.Keys) { if ($first.StartsWith($k)) { $key = $k } }
    if ($key) {
      $hdr = $sec.Headers.Item(1)                   # wdHeaderFooterPrimary
      $hdr.LinkToPrevious = $false
      $r = $hdr.Range
      $r.Text = $titles[$key]
      $r.Font.Name = "Times New Roman"
      $r.Font.Size = 10
      $r.Font.Bold = $true
      $r.Font.Color = $blue
      $r.ParagraphFormat.Alignment = 1              # centre
      $b = $r.ParagraphFormat.Borders.Item(-3)      # wdBorderBottom
      $b.LineStyle = 1                              # wdLineStyleSingle
      $b.LineWidth = 6                              # wdLineWidth075pt
      $b.Color = $green
      # pied : lier au precedent (numeros de page continus)
      $sec.Footers.Item(1).LinkToPrevious = $true
      Write-Output "en-tete pose : section $i ($key)"
    }
    if ($first.StartsWith("Conclusion G")) {
      $hdr = $sec.Headers.Item(1)
      $hdr.LinkToPrevious = $false
      $hdr.Range.Text = ""
      Write-Output "en-tete vide : section $i (Conclusion)"
    }
  }

  $doc.Save()
  $n = $doc.ComputeStatistics(2)
  Write-Output "sauve, pages: $n"
  $doc.Close($false)
} finally {
  $word.Quit()
}
