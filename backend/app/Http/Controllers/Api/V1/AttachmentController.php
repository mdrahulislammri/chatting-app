<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class AttachmentController extends Controller
{
    protected array $allowedMimes = [
        // Images
        'image/jpeg', 'image/png', 'image/webp', 'image/gif',
        // Documents
        'application/pdf', 'application/zip', 'text/plain',
        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        // Audio & Video
        'audio/mpeg', 'audio/ogg', 'audio/wav', 'audio/mp4', 'video/mp4', 'video/webm',
    ];

    protected array $blockedExtensions = [
        'php', 'phtml', 'html', 'htm', 'svg', 'exe', 'js', 'sh', 'bat', 'cmd', 'vbs', 'jar', 'phar'
    ];

    public function upload(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $request->validate([
            'file' => ['required', 'file', 'max:25600'], // Max 25MB per file
        ]);

        $file = $request->file('file');
        $extension = strtolower($file->getClientOriginalExtension());
        $mimeType = $file->getMimeType();

        // 1. Strict Extension & MIME Validation
        if (in_array($extension, $this->blockedExtensions)) {
            return response()->json([
                'success' => false,
                'message' => 'Uploaded file extension is prohibited for security reasons.',
            ], 422);
        }

        if (!in_array($mimeType, $this->allowedMimes)) {
            return response()->json([
                'success' => false,
                'message' => 'Uploaded file MIME type is not allowed.',
            ], 422);
        }

        // 2. Generated Storage Filename (Never trust raw client filename in storage path!)
        $safeStorageName = (string) Str::uuid() . '.' . ($extension ?: 'bin');
        $path = $file->storeAs('attachments', $safeStorageName, 'local');

        $originalName = pathinfo($file->getClientOriginalName(), PATHINFO_BASENAME);
        $size = $file->getSize();

        // Determine type
        $type = 'file';
        if (str_starts_with($mimeType, 'image/')) {
            $type = 'image';
        } elseif (str_starts_with($mimeType, 'audio/')) {
            $type = 'audio';
        }

        return response()->json([
            'success' => true,
            'data' => [
                'type' => $type,
                'attachment_url' => route('api.v1.attachments.download', ['conversation' => $conversation->id, 'filename' => $safeStorageName]),
                'attachment_name' => $originalName,
                'attachment_size' => $size,
                'mime_type' => $mimeType,
                'storage_path' => $safeStorageName,
            ],
        ], 201);
    }

    public function download(Request $request, Conversation $conversation, string $filename): BinaryFileResponse|JsonResponse
    {
        // 3. Authorization Check: Ensure request user belongs to conversation!
        $this->authorize('view', $conversation);

        $path = 'attachments/' . basename($filename);

        if (!Storage::disk('local')->exists($path)) {
            return response()->json([
                'success' => false,
                'message' => 'Attachment file not found.',
            ], 44);
        }

        return response()->download(Storage::disk('local')->path($path));
    }

    public function media(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $typeFilter = $request->query('type'); // 'image', 'file', 'audio'

        $query = Message::where('conversation_id', $conversation->id)
            ->whereNotNull('attachment_url');

        if ($typeFilter && in_array($typeFilter, ['image', 'file', 'audio'])) {
            $query->where('type', $typeFilter);
        }

        $mediaMessages = $query->orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $mediaMessages->map(function ($msg) {
                return [
                    'id' => $msg->id,
                    'type' => $msg->type?->value ?? $msg->type,
                    'attachment_url' => $msg->attachment_url,
                    'attachment_name' => $msg->attachment_name,
                    'attachment_size' => $msg->attachment_size,
                    'mime_type' => $msg->mime_type,
                    'created_at' => $msg->created_at?->toIso8601String(),
                ];
            }),
        ]);
    }
}
