<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Backup;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BackupController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'protocol_version' => ['required', 'integer', 'in:1'],
            'kdf_version' => ['required', 'string'],
            'salt' => ['required', 'string', 'size:64'],
            'nonce' => ['required', 'string'],
            'ciphertext' => ['required', 'string'],
            'auth_tag' => ['required', 'string'],
            'created_at' => ['required', 'integer'],
        ]);

        $user = $request->user();

        $backup = Backup::updateOrCreate(
            ['user_id' => $user->id],
            [
                'protocol_version' => $request->input('protocol_version'),
                'kdf_version' => $request->input('kdf_version'),
                'salt' => $request->input('salt'),
                'nonce' => $request->input('nonce'),
                'ciphertext' => $request->input('ciphertext'),
                'auth_tag' => $request->input('auth_tag'),
                'created_at_timestamp' => $request->input('created_at'),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Encrypted backup envelope uploaded successfully.',
            'data' => [
                'id' => $backup->id,
                'protocol_version' => $backup->protocol_version,
                'created_at' => $backup->created_at_timestamp,
            ],
        ], 201);
    }

    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $backup = Backup::where('user_id', $user->id)->latest()->first();

        if (!$backup) {
            return response()->json(['success' => false, 'message' => 'No backup envelope found for user.'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'protocol_version' => $backup->protocol_version,
                'kdf_version' => $backup->kdf_version,
                'salt' => $backup->salt,
                'nonce' => $backup->nonce,
                'ciphertext' => $backup->ciphertext,
                'auth_tag' => $backup->auth_tag,
                'created_at' => $backup->created_at_timestamp,
            ],
        ]);
    }
}
