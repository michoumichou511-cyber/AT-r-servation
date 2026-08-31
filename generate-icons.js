const fs = require('fs');
const path = require('path');

/**
 * Script pour générer les icônes avec les vraies couleurs
 * Génère des fichiers SVG individuels pour chaque icône
 */

// Couleurs AT Réservations
const colors = {
  'text-blue-600': '#2563EB',
  'text-green-600': '#16A34A',
  'text-red-600': '#DC2626',
  'text-amber-600': '#D97706',
  'text-yellow-600': '#FBBF24',
  'text-purple-600': '#9333EA',
  'text-gray-600': '#4B5563',
};

// Toutes les icônes avec leurs vraies couleurs
const icons = [
  // Navigation
  { name: 'ChevronDown', color: '#4B5563', size: 24 },
  { name: 'ChevronLeft', color: '#4B5563', size: 24 },
  { name: 'ChevronRight', color: '#4B5563', size: 24 },
  { name: 'ChevronsLeft', color: '#4B5563', size: 24 },
  { name: 'ChevronsRight', color: '#4B5563', size: 24 },
  { name: 'ChevronUp', color: '#4B5563', size: 24 },
  { name: 'Menu', color: '#4B5563', size: 24 },
  { name: 'X', color: '#4B5563', size: 24 },
  
  // Dashboard
  { name: 'TrendingUp', color: '#16A34A', size: 24 },
  { name: 'TrendingDown', color: '#DC2626', size: 24 },
  { name: 'BarChart3', color: '#2563EB', size: 24 },
  { name: 'PieChart', color: '#2563EB', size: 24 },
  { name: 'Activity', color: '#D97706', size: 24 },
  { name: 'Award', color: '#FBBF24', size: 24 },
  { name: 'Sparkles', color: '#9333EA', size: 24 },
  
  // Missions
  { name: 'Briefcase', color: '#2563EB', size: 24 },
  { name: 'Plane', color: '#2563EB', size: 24 },
  { name: 'Car', color: '#2563EB', size: 24 },
  { name: 'Truck', color: '#16A34A', size: 24 },
  { name: 'MapPin', color: '#DC2626', size: 24 },
  
  // Communication
  { name: 'Bell', color: '#D97706', size: 24 },
  { name: 'MessageSquare', color: '#2563EB', size: 20 },
  { name: 'Send', color: '#2563EB', size: 20 },
  
  // Actions
  { name: 'CheckCircle2', color: '#16A34A', size: 24 },
  { name: 'XCircle', color: '#DC2626', size: 24 },
  { name: 'AlertTriangle', color: '#D97706', size: 24 },
  { name: 'Download', color: '#2563EB', size: 20 },
  { name: 'Plus', color: '#2563EB', size: 20 },
  { name: 'Pencil', color: '#4B5563', size: 20 },
  { name: 'Trash2', color: '#DC2626', size: 20 },
  
  // Security
  { name: 'Lock', color: '#4B5563', size: 20 },
  { name: 'Eye', color: '#4B5563', size: 20 },
  { name: 'EyeOff', color: '#4B5563', size: 20 },
  { name: 'KeyRound', color: '#2563EB', size: 20 },
  { name: 'ShieldCheck', color: '#16A34A', size: 20 },
];

// Créer le répertoire de sortie
const outputDir = path.join(__dirname, 'icons-generated');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

/**
 * Génère un SVG avec des paramètres spécifiques
 */
function generateSVG(iconName, color, size = 24) {
  // Template SVG basique (vous devrez remplacer par les vrais SVG lucide)
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <!-- SVG pour ${iconName} -->
  <circle cx="12" cy="12" r="10"></circle>
</svg>`;
}

/**
 * Génère tous les icônes en SVG
 */
function generateAllIcons() {
  console.log('📦 Génération des icônes...\n');
  
  let generated = 0;
  
  icons.forEach(icon => {
    const svg = generateSVG(icon.name, icon.color, icon.size);
    const filename = `${icon.name}-${icon.color.replace('#', '')}.svg`;
    const filepath = path.join(outputDir, filename);
    
    fs.writeFileSync(filepath, svg);
    generated++;
    console.log(`✓ ${icon.name} - ${icon.color}`);
  });
  
  console.log(`\n✅ ${generated} icônes générées dans: ${outputDir}`);
  
  // Créer un fichier d'index HTML
  createHTMLPreview();
}

/**
 * Crée une page HTML pour prévisualiser les icônes
 */
function createHTMLPreview() {
  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Aperçu des icônes générées</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 20px; }
    .icon-box { background: white; padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    .icon-box img { width: 48px; height: 48px; margin-bottom: 10px; }
    .icon-name { font-size: 12px; font-weight: bold; margin-top: 10px; }
    .icon-color { font-size: 11px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎨 Aperçu des icônes générées</h1>
    <p>Icônes AT Réservations avec les vraies couleurs</p>
    <div class="grid">
${icons.map(icon => {
  const filename = `${icon.name}-${icon.color.replace('#', '')}.svg`;
  return `      <div class="icon-box">
        <img src="${filename}" alt="${icon.name}">
        <div class="icon-name">${icon.name}</div>
        <div class="icon-color">${icon.color}</div>
      </div>`;
}).join('\n')}
    </div>
  </div>
</body>
</html>`;
  
  const previewPath = path.join(outputDir, 'preview.html');
  fs.writeFileSync(previewPath, html);
  console.log(`\n📄 Aperçu HTML généré: preview.html`);
}

// Pour exporter en PNG, utiliser ImageMagick ou un autre outil
function generatePNGNote() {
  const note = `# 📸 Pour générer des PNG à partir des SVG

## Option 1: ImageMagick (recommandé)
\`\`\`bash
convert icon.svg -background none -size 24x24 icon.png
\`\`\`

## Option 2: Node.js avec sharp
\`\`\`bash
npm install sharp
\`\`\`

\`\`\`javascript
const sharp = require('sharp');
sharp('icon.svg').png().toFile('icon.png');
\`\`\`

## Option 3: Python avec cairosvg
\`\`\`bash
pip install cairosvg pillow
cairosvg icon.svg -o icon.png
\`\`\`

## Option 4: Inkscape (en ligne de commande)
\`\`\`bash
inkscape icon.svg -o icon.png --export-width=24 --export-height=24
\`\`\`
`;
  
  const notePath = path.join(outputDir, 'CONVERSION_PNG.md');
  fs.writeFileSync(notePath, note);
}

// Exécuter
generateAllIcons();
generatePNGNote();

console.log(`
📁 Fichiers créés:
  - icons-generated/ : Dossier avec tous les SVG
  - preview.html : Page de prévisualisation
  - CONVERSION_PNG.md : Guide pour convertir en PNG
`);
