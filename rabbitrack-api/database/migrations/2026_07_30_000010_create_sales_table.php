<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sales', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('rabbit_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sold_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('buyer_name')->nullable();
            $table->string('buyer_phone')->nullable();
            $table->date('sold_on');
            $table->decimal('sale_price', 12, 2);
            $table->string('currency', 3)->default('USD');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'sold_on']);
            $table->index(['rabbit_id', 'sold_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sales');
    }
};
