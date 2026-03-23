<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue sur AT Réservations</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 3px solid #007bff; padding-bottom: 20px; }
        .logo { font-size: 24px; font-weight: bold; color: #007bff; margin-bottom: 10px; }
        .content { line-height: 1.6; color: #333333; }
        .greeting { font-size: 18px; font-weight: bold; margin-bottom: 15px; }
        .info-box { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #007bff; margin: 20px 0; }
        .info-box strong { color: #007bff; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e0e0e0; font-size: 12px; color: #666666; }
        .button { display: inline-block; padding: 12px 30px; background-color: #007bff; color: white; text-decoration: none; border-radius: 4px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">📱 Algérie Télécom</div>
            <div>Plateforme de Réservations</div>
        </div>

        <div class="content">
            <div class="greeting">Bonjour {{ $prenom }} {{ $nom }},</div>

            <p>Votre compte a été créé avec succès sur la plateforme AT Réservations.</p>

            <div class="info-box">
                <p><strong>Email :</strong> {{ $email }}</p>
                <p>Vous pouvez maintenant vous connecter à votre espace personnel.</p>
            </div>

            <p>Bienvenue dans notre plateforme ! Vous pouvez désormais :</p>
            <ul>
                <li>Créer et gérer vos missions</li>
                <li>Réserver des vols, hôtels et restaurants</li>
                <li>Suivre l'état de vos demandes</li>
                <li>Consulter votre budget</li>
            </ul>

            <p style="margin-top: 30px;">Si vous avez des questions, n'hésitez pas à nous contacter.</p>

            <p>Cordialement,<br>L'équipe Algérie Télécom</p>
        </div>

        <div class="footer">
            <p>&copy; 2026 Algérie Télécom. Tous droits réservés.</p>
            <p>Cette plateforme est réservée aux employés d'Algérie Télécom.</p>
        </div>
    </div>
</body>
</html>
