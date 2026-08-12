<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('farms')->where('currency', 'ZAR')->update(['currency' => 'USD']);
        DB::table('sales')->where('currency', 'ZAR')->update(['currency' => 'USD']);
        DB::table('expenses')->where('currency', 'ZAR')->update(['currency' => 'USD']);

        Schema::table('farms', function (Blueprint $table) {
            $table->string('currency', 3)->default('USD')->change();
        });
    }

    public function down(): void
    {
        Schema::table('farms', function (Blueprint $table) {
            $table->string('currency', 3)->default('ZAR')->change();
        });
    }
};
