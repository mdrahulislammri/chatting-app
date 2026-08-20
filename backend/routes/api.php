<?php

use App\Http\Controllers\Api\V1\AttachmentController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BackupController;
use App\Http\Controllers\Api\V1\BlockController;
use App\Http\Controllers\Api\V1\CallController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\MessageController;
use App\Http\Controllers\Api\V1\PrekeyController;
use App\Http\Controllers\Api\V1\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public routes
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Protected routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('/users', [UserController::class, 'index']);

        // Device Management & Push Token routes
        Route::post('/devices', [DeviceController::class, 'store']);
        Route::delete('/devices/{device}', [DeviceController::class, 'destroy']);
        Route::post('/devices/{device}/push-token', [DeviceController::class, 'updatePushToken']);
        Route::delete('/devices/{device}/push-token', [DeviceController::class, 'removePushToken']);

        // Prekey Bundle & Atomic Claim routes
        Route::post('/prekeys', [PrekeyController::class, 'store']);
        Route::get('/devices/{device}/prekey', [PrekeyController::class, 'show']);

        // User Blocking routes
        Route::post('/blocks', [BlockController::class, 'store']);
        Route::delete('/blocks/{user}', [BlockController::class, 'destroy']);

        Route::get('/conversations', [ConversationController::class, 'index']);
        Route::post('/conversations', [ConversationController::class, 'store']);
        Route::get('/conversations/{conversation}', [ConversationController::class, 'show']);
        Route::post('/conversations/{conversation}/mute', [ConversationController::class, 'mute']);
        Route::post('/conversations/{conversation}/archive', [ConversationController::class, 'archive']);

        // Group Administration routes
        Route::post('/conversations/{conversation}/members', [ConversationController::class, 'addMembers']);
        Route::delete('/conversations/{conversation}/members/{user}', [ConversationController::class, 'removeMember']);
        Route::patch('/conversations/{conversation}/members/{user}', [ConversationController::class, 'updateRole']);

        Route::get('/conversations/{conversation}/messages', [MessageController::class, 'index']);
        Route::get('/conversations/{conversation}/messages/search', [MessageController::class, 'search']);
        Route::post('/conversations/{conversation}/messages', [MessageController::class, 'store']);
        Route::patch('/conversations/{conversation}/messages/{message}', [MessageController::class, 'update']);
        Route::delete('/conversations/{conversation}/messages/{message}', [MessageController::class, 'destroy']);
        Route::post('/conversations/{conversation}/messages/{message}/reactions', [MessageController::class, 'react']);
        Route::post('/conversations/{conversation}/messages/{message}/read', [MessageController::class, 'markRead']);
        Route::post('/conversations/{conversation}/typing', [MessageController::class, 'typing']);

        // Attachment & Private Download routes
        Route::post('/conversations/{conversation}/attachments', [AttachmentController::class, 'upload']);
        Route::get('/conversations/{conversation}/attachments/{filename}', [AttachmentController::class, 'download'])->name('api.v1.attachments.download');
        Route::get('/conversations/{conversation}/media', [AttachmentController::class, 'media']);

        // Encrypted Backup Envelope routes
        Route::post('/backups', [BackupController::class, 'store']);
        Route::get('/backups', [BackupController::class, 'show']);

        // WebRTC Signaling & Ephemeral TURN Credential routes
        Route::post('/conversations/{conversation}/call/initiate', [CallController::class, 'initiate']);
        Route::post('/conversations/{conversation}/call/{call}/signal', [CallController::class, 'signal']);
        Route::get('/call/turn-credentials', [CallController::class, 'turnCredentials']);
    });
});
