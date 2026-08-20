<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('calls', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();
            $table->foreignId('caller_id')->constrained('users')->cascadeOnDelete();
            $table->uuid('caller_device_id');
            $table->uuid('winner_device_id')->nullable();
            $table->enum('type', ['audio', 'video'])->default('audio');
            $table->enum('state', ['initiating', 'ringing', 'connecting', 'connected', 'ended', 'failed'])->default('initiating');
            $table->boolean('is_answered')->default(false);
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
        });

        Schema::create('call_signals', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('call_id')->constrained('calls')->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->uuid('sender_device_id');
            $table->enum('type', ['offer', 'answer', 'ice_candidate', 'reject', 'end']);
            $table->text('payload');
            $table->unsignedBigInteger('sequence_number')->default(1);
            $table->unsignedBigInteger('timestamp_ms');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('call_signals');
        Schema::dropIfExists('calls');
    }
};
