<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_events', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('rabbit_id')->constrained()->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('observed_on');
            $table->string('symptoms');
            $table->string('diagnosis')->nullable();
            $table->string('severity')->default('moderate');
            $table->string('body_system')->nullable();
            $table->boolean('isolation_required')->default(false);
            $table->string('status')->default('open');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['farm_id', 'observed_on']);
            $table->index(['rabbit_id', 'status']);
            $table->index(['farm_id', 'severity']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_events');
    }
};
