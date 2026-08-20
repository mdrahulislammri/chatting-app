<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->string('push_token')->nullable()->after('is_active');
            $table->enum('platform', ['android', 'ios', 'windows', 'web'])->default('android')->after('push_token');
        });
    }

    public function down(): void
    {
        Schema::table('devices', function (Blueprint $table) {
            $table->dropColumn(['push_token', 'platform']);
        });
    }
};
