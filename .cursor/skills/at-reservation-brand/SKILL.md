# AT Réservation — Brand & Design System Skill

## Déclenchement automatique
Active cette skill pour TOUT travail UI/UX sur ce projet.

## Palette obligatoire
- Primary Green: #00D47A (boutons CTA, succès, accents)
- Secondary Blue: #0096D6 (liens, info, header)
- Dark BG: #0A0F1E (fond dark mode)
- Surface: #111827 (cards en dark mode)
- Text primary: #F9FAFB (dark) / #111827 (light)

## Typographie
- Display: "Sora" ou "Plus Jakarta Sans" (titres, hero)
- Body: "Inter" uniquement pour le corps de texte (exception accordée ici)
- Taille minimale: 14px body, 12px labels

## Composants standards du projet
- Bouton primaire: bg-[#00D47A] text-black font-semibold rounded-lg hover:opacity-90
- Bouton secondaire: border border-[#0096D6] text-[#0096D6] rounded-lg
- Card: bg-[#111827] border border-white/10 rounded-xl shadow-lg
- Navbar: sticky top-0 z-50 bg-[#0A0F1E]/90 backdrop-blur

## Règles strictes
1. Toujours vérifier z-index navbar (doit être ≥ 50)
2. Sidebar doit respecter le thème dark/light via CSS variables
3. Tous les formulaires de réservation : validation zod + react-hook-form
4. Animations : duration 150-300ms, respect prefers-reduced-motion
5. Mobile-first : tester 375px en priorité

