<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'public_identity_key' => ['required', 'string'],
        ]);

        $device = Device::create([
            'user_id' => $request->user()->id,
            'name' => $request->input('name'),
            'public_identity_key' => $request->input('public_identity_key'),
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'data' => $device,
        ], 201);
    }

    public function destroy(Request $request, Device $device): JsonResponse
    {
        if ($device->user_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $device->update(['is_active' => false, 'push_token' => null]);

        return response()->json([
            'success' => true,
            'message' => 'Device revoked successfully.',
        ]);
    }

    public function updatePushToken(Request $request, Device $device): JsonResponse
    {
        if ($device->user_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'push_token' => ['required', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'in:android,ios,windows,web'],
        ]);

        $device->update([
            'push_token' => $request->input('push_token'),
            'platform' => $request->input('platform', $device->platform ?? 'android'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Push token updated successfully.',
            'data' => $device,
        ]);
    }

    public function removePushToken(Request $request, Device $device): JsonResponse
    {
        if ($device->user_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $device->update(['push_token' => null]);

        return response()->json([
            'success' => true,
            'message' => 'Push token removed successfully.',
        ]);
    }
}
