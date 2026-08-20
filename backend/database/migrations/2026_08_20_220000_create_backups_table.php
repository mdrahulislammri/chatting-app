<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('backups', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('protocol_version')->default(1);
            $table->string('kdf_version')->default('PBKDF2-HMAC-SHA512-HKDF-SHA256-V1');
            $table->string('salt', 64);
            $table->string('nonce', 32); // 12-byte hex-encoded nonce
            $table->text('ciphertext');
            $table->string('auth_tag', 64);
            $table->unsignedBigInteger('created_at_timestamp');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('backups');
    }
};
