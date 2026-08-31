const pdf = require('html-pdf-node');
const fs = require('fs');
const path = require('path');

// Lire le fichier HTML
const htmlPath = path.join(__dirname, 'ICONS_CATALOG.html');
const html = fs.readFileSync(htmlPath, 'utf8');

const options = {
  format: 'A4',
  margin: {
    top: '20mm',
    right: '15mm',
    bottom: '20mm',
    left: '15mm'
  },
  printBackground: true,
  landscape: false,
  timeout: 30000,
  type: 'pdf'
};

// Créer le PDF
pdf.generatePdf({ content: html }, options)
  .then(pdfBuffer => {
    const outputPath = path.join(__dirname, 'ICONS_CATALOG.pdf');
    fs.writeFileSync(outputPath, pdfBuffer);
    console.log(`✅ PDF créé avec succès: ${outputPath}`);
    console.log(`📊 Taille: ${(pdfBuffer.length / 1024 / 1024).toFixed(2)} MB`);
  })
  .catch(err => {
    console.error('❌ Erreur lors de la création du PDF:', err);
    process.exit(1);
  });
