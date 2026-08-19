<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->text('public_identity_key');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('prekey_bundles', function (Blueprint $table) {
            $table->id();
            $table->foreignUuid('device_id')->constrained('devices')->cascadeOnDelete();
            $table->text('signed_prekey');
            $table->text('signed_prekey_signature');
            $table->timestamps();
        });

        Schema::create('one_time_prekeys', function (Blueprint $table) {
            $table->id();
            $table->foreignUuid('device_id')->constrained('devices')->cascadeOnDelete();
            $table->text('public_key');
            $table->boolean('is_consumed')->default(false);
            $table->timestamps();
        });

        Schema::create('message_envelopes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('message_id')->constrained('messages')->cascadeOnDelete();
            $table->foreignUuid('sender_device_id')->constrained('devices')->cascadeOnDelete();
            $table->foreignUuid('recipient_device_id')->constrained('devices')->cascadeOnDelete();
            $table->unsignedInteger('sequence_number')->default(0);
            $table->text('dh_public_key')->nullable();
            $table->longText('ciphertext');
            $table->text('auth_tag')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('message_envelopes');
        Schema::dropIfExists('one_time_prekeys');
        Schema::dropIfExists('prekey_bundles');
        Schema::dropIfExists('devices');
    }
};
