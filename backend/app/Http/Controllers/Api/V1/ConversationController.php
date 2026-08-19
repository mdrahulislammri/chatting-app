<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\ConversationType;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\CreateConversationRequest;
use App\Http\Resources\Api\V1\ConversationResource;
use App\Models\Conversation;
use App\Models\User;
use App\Services\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    public function __construct(protected ConversationService $conversationService) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $conversations = $user->conversations()
            ->with(['users', 'latestMessage.sender'])
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => ConversationResource::collection($conversations),
        ]);
    }

    public function store(CreateConversationRequest $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validated();

        if ($validated['type'] === ConversationType::DIRECT->value) {
            $conversation = $this->conversationService->getOrCreateDirectConversation(
                $user,
                (int) $validated['target_user_id']
            );
        } else {
            $conversation = $this->conversationService->createGroupConversation(
                $user,
                $validated['name'],
                $validated['member_ids']
            );
        }

        return response()->json([
            'success' => true,
            'data' => new ConversationResource($conversation),
        ], 201);
    }

    public function show(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $conversation->load(['users', 'latestMessage.sender']);

        return response()->json([
            'success' => true,
            'data' => new ConversationResource($conversation),
        ]);
    }

    public function addMembers(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('manageMembers', $conversation);

        $request->validate([
            'member_ids' => ['required', 'array'],
            'member_ids.*' => ['exists:users,id'],
        ]);

        $this->conversationService->addMembers($request->user(), $conversation, $request->input('member_ids'));

        return response()->json([
            'success' => true,
            'message' => 'Members added to group successfully.',
        ]);
    }

    public function removeMember(Request $request, Conversation $conversation, User $user): JsonResponse
    {
        if ($request->user()->id !== $user->id) {
            $this->authorize('manageMembers', $conversation);
        } else {
            $this->authorize('view', $conversation);
        }

        $this->conversationService->removeMember($request->user(), $conversation, $user);

        return response()->json([
            'success' => true,
            'message' => 'Member removed successfully.',
        ]);
    }

    public function updateRole(Request $request, Conversation $conversation, User $user): JsonResponse
    {
        $this->authorize('manageMembers', $conversation);

        $request->validate([
            'role' => ['required', 'in:member,admin'],
        ]);

        $this->conversationService->updateMemberRole($request->user(), $conversation, $user, $request->input('role'));

        return response()->json([
            'success' => true,
            'message' => 'Member role updated successfully.',
        ]);
    }

    public function mute(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $request->validate([
            'muted_until' => ['nullable', 'date'],
        ]);

        $this->conversationService->muteConversation($request->user(), $conversation, $request->input('muted_until'));

        return response()->json([
            'success' => true,
            'message' => 'Conversation mute status updated.',
        ]);
    }

    public function archive(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $request->validate([
            'archive' => ['required', 'boolean'],
        ]);

        $this->conversationService->archiveConversation($request->user(), $conversation, (bool) $request->input('archive'));

        return response()->json([
            'success' => true,
            'message' => 'Conversation archive status updated.',
        ]);
    }
}
