<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('treatments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('health_event_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('rabbit_id')->constrained()->cascadeOnDelete();
            $table->foreignId('prescribed_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('medication');
            $table->string('dosage')->nullable();
            $table->string('route')->nullable();
            $table->string('frequency')->nullable();
            $table->date('started_on');
            $table->date('ended_on')->nullable();
            $table->unsignedInteger('withdrawal_days')->default(0);
            $table->date('withdrawal_ends_on')->nullable();
            $table->string('status')->default('active');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['farm_id', 'status']);
            $table->index(['rabbit_id', 'withdrawal_ends_on']);
            $table->index(['health_event_id', 'started_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('treatments');
    }
};
