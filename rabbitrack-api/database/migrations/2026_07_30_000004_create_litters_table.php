<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('litters', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->string('identifier');
            $table->foreignUuid('doe_id')->constrained('rabbits')->cascadeOnDelete();
            $table->foreignUuid('buck_id')->nullable()->constrained('rabbits')->nullOnDelete();
            $table->foreignUuid('mating_id')->nullable()->constrained()->nullOnDelete();
            $table->date('kindled_on');
            $table->unsignedInteger('kits_born_alive')->default(0);
            $table->unsignedInteger('kits_stillborn')->default(0);
            $table->unsignedInteger('kits_weak')->default(0);
            $table->unsignedInteger('current_live_count')->default(0);
            $table->date('planned_weaning_on');
            $table->string('status')->default('newborn');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['farm_id', 'identifier']);
            $table->index(['farm_id', 'status']);
            $table->index(['doe_id', 'kindled_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('litters');
    }
};
