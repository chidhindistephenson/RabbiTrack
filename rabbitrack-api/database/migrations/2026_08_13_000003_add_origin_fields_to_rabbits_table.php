<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rabbits', function (Blueprint $table) {
            $table->string('origin_type', 40)->default('existing_stock')->after('father_id');
            $table->foreignUuid('origin_litter_id')->nullable()->after('origin_type')->constrained('litters')->nullOnDelete();
            $table->index(['farm_id', 'origin_type']);
            $table->index('origin_litter_id');
        });

        DB::table('rabbits')
            ->where('is_farm_born', true)
            ->update(['origin_type' => 'born_on_farm']);

        DB::table('rabbits')
            ->where('is_farm_born', false)
            ->update(['origin_type' => 'purchased']);
    }

    public function down(): void
    {
        Schema::table('rabbits', function (Blueprint $table) {
            $table->dropForeign(['origin_litter_id']);
            $table->dropIndex(['farm_id', 'origin_type']);
            $table->dropIndex(['origin_litter_id']);
            $table->dropColumn(['origin_type', 'origin_litter_id']);
        });
    }
};
