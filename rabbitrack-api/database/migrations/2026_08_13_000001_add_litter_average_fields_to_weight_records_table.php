<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('weight_records', function (Blueprint $table): void {
            $table->unsignedInteger('kit_count')->nullable()->after('weight_unit');
            $table->decimal('average_weight_value', 8, 3)->nullable()->after('kit_count');
        });
    }

    public function down(): void
    {
        Schema::table('weight_records', function (Blueprint $table): void {
            $table->dropColumn(['kit_count', 'average_weight_value']);
        });
    }
};
