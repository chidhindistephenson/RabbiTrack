<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('litter_checks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('litter_id')->constrained()->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('checked_on');
            $table->unsignedInteger('live_count');
            $table->unsignedInteger('dead_count')->default(0);
            $table->unsignedInteger('weak_count')->default(0);
            $table->string('suspected_cause')->nullable();
            $table->string('nest_observation')->nullable();
            $table->string('corrective_action')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'checked_on']);
            $table->index(['litter_id', 'checked_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('litter_checks');
    }
};
