<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Call;
use App\Models\Conversation;
use App\Services\CallService;
use App\Services\TurnCredentialService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CallController extends Controller
{
    protected CallService $callService;
    protected TurnCredentialService $turnService;

    public function __construct(CallService $callService, TurnCredentialService $turnService)
    {
        $this->callService = $callService;
        $this->turnService = $turnService;
    }

    public function initiate(Request $request, Conversation $conversation): JsonResponse
    {
        $request->validate([
            'caller_device_id' => ['required', 'uuid'],
            'type' => ['nullable', 'string', 'in:audio,video'],
        ]);

        $call = $this->callService->initiateCall($request->user(), $conversation, $request->all());

        return response()->json([
            'success' => true,
            'data' => $call,
        ], 201);
    }

    public function signal(Request $request, Conversation $conversation, Call $call): JsonResponse
    {
        $request->validate([
            'sender_device_id' => ['required', 'uuid'],
            'type' => ['required', 'string', 'in:offer,answer,ice_candidate,reject,end'],
            'payload' => ['nullable', 'array'],
            'sequence_number' => ['nullable', 'integer'],
            'timestamp_ms' => ['nullable', 'integer'],
        ]);

        $result = $this->callService->processSignal($request->user(), $call, $request->all());

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }

    public function turnCredentials(Request $request): JsonResponse
    {
        $credentials = $this->turnService->generateCredentials($request->user());

        return response()->json([
            'success' => true,
            'data' => $credentials,
        ]);
    }
}
