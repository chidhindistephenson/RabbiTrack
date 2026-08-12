<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rabbits', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->string('identifier');
            $table->string('name')->nullable();
            $table->string('sex');
            $table->date('date_of_birth')->nullable();
            $table->string('breed')->nullable();
            $table->string('colour')->nullable();
            $table->string('markings')->nullable();
            $table->decimal('weight_value', 8, 3)->nullable();
            $table->string('weight_unit', 10)->default('kg');
            $table->string('tag_or_tattoo')->nullable();
            $table->string('status');
            $table->foreignUuid('current_location_id')->nullable()->constrained('locations')->nullOnDelete();
            $table->uuid('mother_id')->nullable();
            $table->uuid('father_id')->nullable();
            $table->boolean('is_farm_born')->default(true);
            $table->string('supplier')->nullable();
            $table->date('acquired_at')->nullable();
            $table->decimal('acquisition_cost', 12, 2)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['farm_id', 'identifier']);
            $table->index(['farm_id', 'sex']);
            $table->index(['farm_id', 'status']);
            $table->index(['farm_id', 'current_location_id']);
        });

        Schema::table('rabbits', function (Blueprint $table) {
            $table->foreign('mother_id')->references('id')->on('rabbits')->nullOnDelete();
            $table->foreign('father_id')->references('id')->on('rabbits')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rabbits');
    }
};
