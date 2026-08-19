<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BlockController extends Controller
{
    public function __construct(protected ConversationService $conversationService) {}

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'user_id' => ['required', 'exists:users,id'],
        ]);

        $targetUser = User::findOrFail($request->input('user_id'));
        $this->conversationService->blockUser($request->user(), $targetUser);

        return response()->json([
            'success' => true,
            'message' => 'User blocked successfully.',
        ]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        $this->conversationService->unblockUser($request->user(), $user);

        return response()->json([
            'success' => true,
            'message' => 'User unblocked successfully.',
        ]);
    }
}
