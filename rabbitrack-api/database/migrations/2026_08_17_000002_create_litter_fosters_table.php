<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('litter_fosters', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('from_litter_id')->constrained('litters')->cascadeOnDelete();
            $table->foreignUuid('to_litter_id')->constrained('litters')->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('fostered_on');
            $table->unsignedInteger('kit_count');
            $table->string('reason')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'fostered_on']);
            $table->index(['from_litter_id', 'fostered_on']);
            $table->index(['to_litter_id', 'fostered_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('litter_fosters');
    }
};
