<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kindlings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('mating_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUuid('litter_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('doe_id')->constrained('rabbits')->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('kindled_on');
            $table->unsignedInteger('kits_born_alive')->default(0);
            $table->unsignedInteger('kits_stillborn')->default(0);
            $table->unsignedInteger('kits_weak')->default(0);
            $table->string('nest_condition')->nullable();
            $table->string('doe_condition')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'kindled_on']);
            $table->index(['doe_id', 'kindled_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kindlings');
    }
};
