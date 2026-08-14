<?php

namespace Database\Seeders;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Location;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $owner = User::query()->updateOrCreate(
            ['email' => 'owner@rabbitrack.local'],
            [
                'name' => 'RabbiTrack Owner',
                'username' => 'owner',
                'password' => Hash::make('secret-password'),
                'is_active' => true,
            ],
        );

        $farm = Farm::query()->updateOrCreate(
            ['code' => 'DEMO-FARM'],
            [
                'name' => 'RabbiTrack Demo Farm',
                'timezone' => 'Africa/Johannesburg',
                'currency' => 'USD',
                'settings' => [
                    'gestation_days' => 31,
                    'pregnancy_check_start_days' => 10,
                    'pregnancy_check_end_days' => 14,
                    'nest_box_lead_days' => 3,
                    'weaning_days' => 35,
                    'kit_identification_days_after_weaning' => 7,
                ],
            ],
        );

        FarmMembership::query()->updateOrCreate(
            [
                'farm_id' => $farm->id,
                'user_id' => $owner->id,
            ],
            [
                'role' => 'owner',
                'is_active' => true,
                'joined_at' => now(),
            ],
        );

        $teamMembers = [
            [
                'name' => 'RabbiTrack Administrator',
                'email' => 'admin@rabbitrack.local',
                'username' => 'admin',
                'role' => 'administrator',
            ],
            [
                'name' => 'RabbiTrack Administrator Alias',
                'email' => 'administrator@rabbitrack.local',
                'username' => 'administrator',
                'role' => 'administrator',
            ],
            [
                'name' => 'RabbiTrack Manager',
                'email' => 'manager@rabbitrack.local',
                'username' => 'manager',
                'role' => 'manager',
            ],
            [
                'name' => 'RabbiTrack Worker',
                'email' => 'worker@rabbitrack.local',
                'username' => 'worker',
                'role' => 'worker',
            ],
            [
                'name' => 'RabbiTrack Veterinarian',
                'email' => 'vet@rabbitrack.local',
                'username' => 'vet',
                'role' => 'veterinarian',
            ],
            [
                'name' => 'RabbiTrack Veterinarian Alias',
                'email' => 'veterinarian@rabbitrack.local',
                'username' => 'veterinarian',
                'role' => 'veterinarian',
            ],
            [
                'name' => 'RabbiTrack Viewer',
                'email' => 'viewer@rabbitrack.local',
                'username' => 'viewer',
                'role' => 'viewer',
            ],
        ];

        foreach ($teamMembers as $member) {
            $user = User::query()->updateOrCreate(
                ['email' => $member['email']],
                [
                    'name' => $member['name'],
                    'username' => $member['username'],
                    'password' => Hash::make('secret-password'),
                    'is_active' => true,
                ],
            );

            FarmMembership::query()->updateOrCreate(
                [
                    'farm_id' => $farm->id,
                    'user_id' => $user->id,
                ],
                [
                    'role' => $member['role'],
                    'is_active' => true,
                    'joined_at' => now(),
                ],
            );
        }

        Location::query()->updateOrCreate(
            [
                'farm_id' => $farm->id,
                'code' => 'H1',
            ],
            [
                'type' => 'house',
                'name' => 'House 1',
                'capacity' => 40,
                'is_active' => true,
            ],
        );

        Rabbit::query()->updateOrCreate(
            [
                'farm_id' => $farm->id,
                'identifier' => 'DOE-0047',
            ],
            [
                'name' => 'Mjolnir',
                'sex' => 'female',
                'date_of_birth' => '2025-02-14',
                'breed' => 'New Zealand White',
                'colour' => 'White',
                'weight_value' => 4.300,
                'weight_unit' => 'kg',
                'status' => 'pregnant',
            ],
        );

        Rabbit::query()->updateOrCreate(
            [
                'farm_id' => $farm->id,
                'identifier' => 'BUCK-0003',
            ],
            [
                'name' => 'Atlas',
                'sex' => 'male',
                'date_of_birth' => '2025-01-10',
                'breed' => 'New Zealand White',
                'colour' => 'White',
                'weight_value' => 4.800,
                'weight_unit' => 'kg',
                'status' => 'available_for_breeding',
            ],
        );
    }
}
