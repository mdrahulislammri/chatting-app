<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SendMessageRequest;
use App\Http\Resources\Api\V1\MessageResource;
use App\Models\Conversation;
use App\Models\Message;
use App\Services\MessageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function __construct(protected MessageService $messageService) {}

    public function index(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $limit = (int) $request->query('limit', 50);
        $messages = $this->messageService->getMessages($conversation, $limit);

        return response()->json([
            'success' => true,
            'data' => MessageResource::collection($messages),
        ]);
    }

    public function store(SendMessageRequest $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $message = $this->messageService->sendMessage(
            $request->user(),
            $conversation,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'data' => new MessageResource($message),
        ], 201);
    }

    public function update(Request $request, Conversation $conversation, Message $message): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $request->validate([
            'content' => ['required', 'string'],
        ]);

        $updated = $this->messageService->editMessage(
            $request->user(),
            $message,
            $request->input('content')
        );

        return response()->json([
            'success' => true,
            'data' => new MessageResource($updated),
        ]);
    }

    public function destroy(Request $request, Conversation $conversation, Message $message): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $this->messageService->deleteMessage($request->user(), $message);

        return response()->json([
            'success' => true,
            'message' => 'Message deleted successfully.',
        ]);
    }

    public function react(Request $request, Conversation $conversation, Message $message): JsonResponse
    {
        $this->authorize('view', $conversation);

        $request->validate([
            'reaction' => ['required', 'string', 'max:32'],
        ]);

        $res = $this->messageService->toggleReaction(
            $request->user(),
            $conversation,
            $message,
            $request->input('reaction')
        );

        return response()->json([
            'success' => true,
            'data' => $res,
        ]);
    }

    public function search(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $q = (string) $request->query('q', '');
        $results = $this->messageService->searchMessages($conversation, $q);

        return response()->json([
            'success' => true,
            'data' => MessageResource::collection($results),
        ]);
    }

    public function markRead(Request $request, Conversation $conversation, Message $message): JsonResponse
    {
        $this->authorize('view', $conversation);

        $this->messageService->markAsRead($request->user(), $conversation, $message);

        return response()->json([
            'success' => true,
            'message' => 'Message marked as read.',
        ]);
    }

    public function typing(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $isTyping = (bool) $request->input('is_typing', true);
        $this->messageService->sendTyping($request->user(), $conversation, $isTyping);

        return response()->json([
            'success' => true,
        ]);
    }
}
