<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Document;
use App\Models\Mission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class DocumentController extends Controller
{
    public function index(Request $request, $mission_id)
    {
        $mission = Mission::findOrFail($mission_id);
        $user = Auth::user();

        // Vérifier accès
        if ($user->role->name === 'utilisateur' && $mission->user_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $documents = Document::where('documentable_type', 'App\Models\Mission')
            ->where('documentable_id', $mission_id)
            ->with('uploadeur')
            ->orderBy('created_at', 'desc')
            ->get();

        $documents = $documents->map(function ($doc) {
            return [
                'id' => $doc->id,
                'nom_fichier' => $doc->nom_fichier,
                'type_document' => $doc->type_document,
                'taille' => $doc->taille,
                'uploaded_by' => $doc->uploadeur ? [
                    'id' => $doc->uploadeur->id,
                    'nom_complet' => $doc->uploadeur->prenom.' '.$doc->uploadeur->nom,
                ] : null,
                'created_at' => $doc->created_at->format('d/m/Y H:i:s'),
            ];
        });

        return response()->json($documents);
    }

    public function store(Request $request, $mission_id)
    {
        $mission = Mission::findOrFail($mission_id);
        $user = Auth::user();

        // Vérifier accès
        if ($user->role->name === 'utilisateur' && $mission->user_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Validation
        $request->validate([
            // max en KB => 5120 = 5MB
            'fichier' => 'required|file|max:5120|mimes:pdf,doc,docx,jpg,jpeg',
            'type_document' => 'required|in:ordre_mission,formulaire,autorisation',
        ]);

        $file = $request->file('fichier');
        $nom_fichier = $file->getClientOriginalName();
        $taille = $file->getSize();

        // Créer le chemin de stockage
        $path = "documents/{$mission_id}";
        $nom_stockage = uniqid($request->type_document.'_').'_'.$nom_fichier;
        $chemin_complet = $file->storeAs($path, $nom_stockage, 'public');

        // Enregistrer en base de données
        $document = Document::create([
            'documentable_type' => 'App\Models\Mission',
            'documentable_id' => $mission_id,
            'nom_fichier' => $nom_fichier,
            'chemin' => $chemin_complet,
            'type_document' => $request->type_document,
            'taille' => $taille,
            'uploaded_by' => $user->id,
            'uploaded_at' => now(),
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'create',
            'module' => 'document',
            'description' => "Document uploadé pour mission {$mission->numero_unique}",
            'old_values' => null,
            'new_values' => [
                'nom' => $nom_fichier,
                'type' => $request->type_document,
                'taille' => $taille,
            ],
        ]);

        return response()->json([
            'id' => $document->id,
            'nom_fichier' => $document->nom_fichier,
            'type_document' => $document->type_document,
            'taille' => $document->taille,
            'created_at' => $document->created_at->format('d/m/Y H:i:s'),
        ], 201);
    }

    public function destroy(Request $request, $id)
    {
        $document = Document::findOrFail($id);
        $user = Auth::user();

        // Vérifier accès
        if ($document->uploaded_by !== $user->id && $user->role->name !== 'admin') {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Supprimer le fichier physique
        Storage::disk('public')->delete($document->chemin);

        // Supprimer l'enregistrement
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'delete',
            'module' => 'document',
            'description' => "Document supprimé : {$document->nom_fichier}",
            'old_values' => ['id' => $document->id, 'nom' => $document->nom_fichier],
            'new_values' => null,
        ]);

        $document->delete();

        return response()->json(['message' => 'Document supprimé']);
    }

    public function telecharger(Request $request, $id)
    {
        $document = Document::findOrFail($id);
        $user = Auth::user();

        // Vérifier accès
        if ($user->role->name === 'utilisateur' && $document->documentable->user_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Vérifier que le fichier existe
        if (! Storage::disk('public')->exists($document->chemin)) {
            return response()->json(['error' => 'Fichier non trouvé'], 404);
        }

        return Storage::disk('public')->download($document->chemin, $document->nom_fichier);
    }
}
