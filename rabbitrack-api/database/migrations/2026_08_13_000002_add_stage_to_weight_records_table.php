<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('weight_records', function (Blueprint $table): void {
            $table->string('stage', 40)->nullable()->after('litter_id');
            $table->index(['litter_id', 'stage']);
        });

        DB::table('weight_records')
            ->whereNotNull('litter_id')
            ->whereNull('stage')
            ->update(['stage' => 'birth']);
    }

    public function down(): void
    {
        Schema::table('weight_records', function (Blueprint $table): void {
            $table->dropIndex(['litter_id', 'stage']);
            $table->dropColumn('stage');
        });
    }
};
