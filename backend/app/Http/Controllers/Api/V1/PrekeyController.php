<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\OneTimePrekey;
use App\Models\PrekeyBundleModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PrekeyController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'device_id' => ['required', 'exists:devices,id'],
            'signed_prekey' => ['required', 'string'],
            'signed_prekey_signature' => ['required', 'string'],
            'one_time_prekeys' => ['required', 'array'],
            'one_time_prekeys.*' => ['string'],
        ]);

        $deviceId = $request->input('device_id');

        DB::transaction(function () use ($request, $deviceId) {
            PrekeyBundleModel::updateOrCreate(
                ['device_id' => $deviceId],
                [
                    'signed_prekey' => $request->input('signed_prekey'),
                    'signed_prekey_signature' => $request->input('signed_prekey_signature'),
                ]
            );

            foreach ($request->input('one_time_prekeys') as $opk) {
                OneTimePrekey::create([
                    'device_id' => $deviceId,
                    'public_key' => $opk,
                    'is_consumed' => false,
                ]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Prekey bundle and pool uploaded successfully.',
        ], 201);
    }

    public function show(Request $request, Device $device): JsonResponse
    {
        if (!$device->is_active) {
            return response()->json(['success' => false, 'message' => 'Device is revoked.'], 410);
        }

        $bundle = $device->prekeyBundle;
        if (!$bundle) {
            return response()->json(['success' => false, 'message' => 'Prekey bundle not found for device.'], 404);
        }

        // Atomic OPK Claim via DB row lock (lockForUpdate)
        $opk = DB::transaction(function () use ($device) {
            $claimed = OneTimePrekey::where('device_id', $device->id)
                ->where('is_consumed', false)
                ->lockForUpdate()
                ->first();

            if ($claimed) {
                $claimed->update(['is_consumed' => true]);
            }

            return $claimed;
        });

        return response()->json([
            'success' => true,
            'data' => [
                'device_id' => $device->id,
                'identity_public_key' => $device->public_identity_key,
                'signed_prekey' => $bundle->signed_prekey,
                'signed_prekey_signature' => $bundle->signed_prekey_signature,
                'one_time_prekey' => $opk ? [
                    'id' => $opk->id,
                    'public_key' => $opk->public_key,
                ] : null,
            ],
        ]);
    }
}
