<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignId('assigned_to_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type');
            $table->string('title');
            $table->text('description')->nullable();
            $table->date('due_on');
            $table->time('due_time')->nullable();
            $table->string('priority')->default('normal');
            $table->string('status')->default('open');
            $table->string('related_type')->nullable();
            $table->uuid('related_id')->nullable();
            $table->foreignUuid('rabbit_id')->nullable()->constrained('rabbits')->nullOnDelete();
            $table->foreignUuid('litter_id')->nullable();
            $table->foreignUuid('location_id')->nullable()->constrained('locations')->nullOnDelete();
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['farm_id', 'due_on', 'status']);
            $table->index(['farm_id', 'type']);
            $table->index(['related_type', 'related_id']);
            $table->index(['rabbit_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
