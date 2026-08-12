<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pregnancy_checks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('mating_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('doe_id')->constrained('rabbits')->cascadeOnDelete();
            $table->foreignId('examiner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('checked_on');
            $table->string('result');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'checked_on']);
            $table->index(['mating_id', 'checked_on']);
            $table->index(['doe_id', 'checked_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pregnancy_checks');
    }
};
