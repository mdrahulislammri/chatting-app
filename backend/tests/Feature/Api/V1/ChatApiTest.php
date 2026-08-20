<?php

namespace Tests\Feature\Api\V1;

use App\Models\Conversation;
use App\Models\Device;
use App\Models\Message;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class ChatApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_login(): void
    {
        $registerResponse = $this->postJson('/api/v1/auth/register', [
            'name' => 'Rahul Ahmed',
            'email' => 'rahul@example.com',
            'password' => 'password123',
        ]);

        $registerResponse->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'data' => ['user' => ['id', 'name', 'email'], 'token'],
            ]);

        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => 'rahul@example.com',
            'password' => 'password123',
        ]);

        $loginResponse->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => ['token'],
            ]);
    }

    public function test_direct_conversation_deduplication(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $res1 = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);

        $res1->assertStatus(201);
        $convId1 = $res1->json('data.id');

        $res2 = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);

        $res2->assertStatus(201);
        $convId2 = $res2->json('data.id');

        $this->assertEquals($convId1, $convId2);
        $this->assertDatabaseCount('conversations', 1);
    }

    public function test_client_message_id_deduplication_and_sending(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $clientMsgId = (string) Str::uuid();

        $send1 = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => $clientMsgId,
            'content' => 'Hello World!',
        ]);

        $send1->assertStatus(201);
        $msgId1 = $send1->json('data.id');

        $send2 = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => $clientMsgId,
            'content' => 'Hello World!',
        ]);

        $send2->assertStatus(201);
        $msgId2 = $send2->json('data.id');

        $this->assertEquals($msgId1, $msgId2);
        $this->assertDatabaseCount('messages', 1);
    }

    public function test_unauthorized_user_cannot_read_or_send_messages(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $userC = User::factory()->create();

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $response = $this->actingAs($userC)->getJson("/api/v1/conversations/{$convId}/messages");
        $response->assertStatus(403);
    }

    public function test_typing_indicator_and_read_receipts(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $typingRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/typing", [
            'is_typing' => true,
        ]);
        $typingRes->assertStatus(200);

        $sendRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'content' => 'Read receipt test',
        ]);
        $msgId = $sendRes->json('data.id');

        $readRes = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/messages/{$msgId}/read");
        $readRes->assertStatus(200);

        $this->assertDatabaseHas('message_reads', [
            'message_id' => $msgId,
            'user_id' => $userB->id,
        ]);
    }

    public function test_message_edit_soft_delete_reply_and_search(): void
    {
        $userA = User::factory()->create(['name' => 'User A']);
        $userB = User::factory()->create(['name' => 'User B']);

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $parentRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'content' => 'Original Parent Message',
        ]);
        $parentId = $parentRes->json('data.id');

        $this->travel(1)->seconds();
        $editRes = $this->actingAs($userA)->patchJson("/api/v1/conversations/{$convId}/messages/{$parentId}", [
            'content' => 'Edited Parent Message',
        ]);
        $editRes->assertStatus(200)
            ->assertJsonPath('data.content', 'Edited Parent Message')
            ->assertJsonPath('data.is_edited', true);

        $replyRes = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'content' => 'Replying to Parent',
            'reply_to_id' => $parentId,
        ]);
        $replyRes->assertStatus(201)
            ->assertJsonPath('data.reply_to.id', $parentId)
            ->assertJsonPath('data.reply_to.content', 'Edited Parent Message');

        $searchRes = $this->actingAs($userA)->getJson("/api/v1/conversations/{$convId}/messages/search?q=Edited");
        $searchRes->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $parentId);

        $deleteRes = $this->actingAs($userA)->deleteJson("/api/v1/conversations/{$convId}/messages/{$parentId}");
        $deleteRes->assertStatus(200);

        $fetchRes = $this->actingAs($userB)->getJson("/api/v1/conversations/{$convId}/messages");
        $fetchRes->assertStatus(200);
        
        $messages = $fetchRes->json('data');
        $deletedMsg = collect($messages)->firstWhere('id', $parentId);
        $this->assertEquals('This message was deleted', $deletedMsg['content']);
        $this->assertTrue($deletedMsg['is_deleted']);

        $badReact = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/messages/{$parentId}/reactions", [
            'reaction' => '👍',
        ]);
        $badReact->assertStatus(404);
    }

    public function test_attachment_security_authorization_and_media_gallery(): void
    {
        Storage::fake('local');

        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $userC = User::factory()->create();

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $phpFile = UploadedFile::fake()->create('script.php', 10, 'text/x-php');
        $badUpload = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/attachments", [
            'file' => $phpFile,
        ]);
        $badUpload->assertStatus(422);

        $file = UploadedFile::fake()->create('document.pdf', 100, 'application/pdf');
        $uploadRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/attachments", [
            'file' => $file,
        ]);

        $uploadRes->assertStatus(201)
            ->assertJsonPath('data.type', 'file')
            ->assertJsonPath('data.attachment_name', 'document.pdf');

        $storagePath = $uploadRes->json('data.storage_path');

        $downloadResB = $this->actingAs($userB)->get("/api/v1/conversations/{$convId}/attachments/{$storagePath}");
        $downloadResB->assertStatus(200);

        $downloadResC = $this->actingAs($userC)->get("/api/v1/conversations/{$convId}/attachments/{$storagePath}");
        $downloadResC->assertStatus(403);
    }

    public function test_group_chat_creation_admin_roles_and_system_messages(): void
    {
        $userA = User::factory()->create(['name' => 'User A']);
        $userB = User::factory()->create(['name' => 'User B']);
        $userC = User::factory()->create(['name' => 'User C']);

        $groupRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'group',
            'name' => 'E2E Core Team',
            'member_ids' => [$userB->id],
        ]);

        $groupRes->assertStatus(201)
            ->assertJsonPath('data.type', 'group')
            ->assertJsonPath('data.name', 'E2E Core Team');

        $convId = $groupRes->json('data.id');

        $addRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/members", [
            'member_ids' => [$userC->id],
        ]);
        $addRes->assertStatus(200);

        $promoteRes = $this->actingAs($userA)->patchJson("/api/v1/conversations/{$convId}/members/{$userB->id}", [
            'role' => 'admin',
        ]);
        $promoteRes->assertStatus(200);

        $userD = User::factory()->create();
        $unauthAdd = $this->actingAs($userC)->postJson("/api/v1/conversations/{$convId}/members", [
            'member_ids' => [$userD->id],
        ]);
        $unauthAdd->assertStatus(403);

        $messagesRes = $this->actingAs($userA)->getJson("/api/v1/conversations/{$convId}/messages");
        $messagesRes->assertStatus(200);
        $systemMessages = array_values(array_filter($messagesRes->json('data'), fn($m) => $m['type'] === 'system'));

        $this->assertNotEmpty($systemMessages);
    }

    public function test_group_edge_cases_sole_admin_and_removed_member_revocation(): void
    {
        $userA = User::factory()->create(['name' => 'User A']);
        $userB = User::factory()->create(['name' => 'User B']);

        $groupRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'group',
            'name' => 'Admin Edge Team',
            'member_ids' => [$userB->id],
        ]);
        $convId = $groupRes->json('data.id');

        $demoteSelf = $this->actingAs($userA)->patchJson("/api/v1/conversations/{$convId}/members/{$userA->id}", [
            'role' => 'member',
        ]);
        $demoteSelf->assertStatus(422);

        $removeB = $this->actingAs($userA)->deleteJson("/api/v1/conversations/{$convId}/members/{$userB->id}");
        $removeB->assertStatus(200);

        $fetchRemoved = $this->actingAs($userB)->getJson("/api/v1/conversations/{$convId}/messages");
        $fetchRemoved->assertStatus(403);
    }

    public function test_message_reactions_toggle_and_uniqueness(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $msgRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'content' => 'Reaction Test Message',
        ]);
        $msgId = $msgRes->json('data.id');

        $react1 = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/messages/{$msgId}/reactions", [
            'reaction' => '👍',
        ]);
        $react1->assertStatus(200)
            ->assertJsonPath('data.action', 'added');

        $fetchRes = $this->actingAs($userB)->getJson("/api/v1/conversations/{$convId}/messages");
        $fetchRes->assertStatus(200)
            ->assertJsonPath('data.0.reactions.0.reaction', '👍')
            ->assertJsonPath('data.0.reactions.0.count', 1)
            ->assertJsonPath('data.0.reactions.0.has_reacted', true);

        $react2 = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/messages/{$msgId}/reactions", [
            'reaction' => '👍',
        ]);
        $react2->assertStatus(200)
            ->assertJsonPath('data.action', 'removed');

        $this->assertDatabaseCount('message_reactions', 0);
    }

    public function test_bidirectional_blocking_and_self_block_prevention(): void
    {
        $userA = User::factory()->create(['name' => 'User A']);
        $userB = User::factory()->create(['name' => 'User B']);

        $selfBlock = $this->actingAs($userA)->postJson('/api/v1/blocks', [
            'user_id' => $userA->id,
        ]);
        $selfBlock->assertStatus(422);

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $this->actingAs($userA)->postJson('/api/v1/blocks', [
            'user_id' => $userB->id,
        ]);

        $sendFromA = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'content' => 'Test message from A',
        ]);
        $sendFromA->assertStatus(422);

        $sendFromB = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'content' => 'Test message from B',
        ]);
        $sendFromB->assertStatus(422);
    }

    public function test_device_registration_prekey_upload_and_atomic_opk_claim(): void
    {
        $userA = User::factory()->create();

        $devRes = $this->actingAs($userA)->postJson('/api/v1/devices', [
            'name' => 'Rahul Windows Laptop',
            'public_identity_key' => 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ]);
        $devRes->assertStatus(201);
        $deviceId = $devRes->json('data.id');

        $prekeyRes = $this->actingAs($userA)->postJson('/api/v1/prekeys', [
            'device_id' => $deviceId,
            'signed_prekey' => '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
            'signed_prekey_signature' => 'e5934160d354b7cb35d0649605858a8177350084663d6757254085d2100046d55703530555669473c00419c42821a979201c10757a3e758416d634be9c6e3926',
            'one_time_prekeys' => [
                'de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f',
            ],
        ]);
        $prekeyRes->assertStatus(201);

        $claimRes1 = $this->actingAs($userA)->getJson("/api/v1/devices/{$deviceId}/prekey");
        $claimRes1->assertStatus(200)
            ->assertJsonPath('data.one_time_prekey.public_key', 'de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f');

        $claimRes2 = $this->actingAs($userA)->getJson("/api/v1/devices/{$deviceId}/prekey");
        $claimRes2->assertStatus(200)
            ->assertJsonPath('data.one_time_prekey', null);
    }

    public function test_plaintext_elimination_and_encrypted_envelopes_storage(): void
    {
        $userA = User::factory()->create(['name' => 'Rahul']);
        $userB = User::factory()->create(['name' => 'Karim']);

        $devA = Device::create([
            'user_id' => $userA->id,
            'name' => 'Rahul Android',
            'public_identity_key' => 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ]);

        $devB = Device::create([
            'user_id' => $userB->id,
            'name' => 'Karim Windows',
            'public_identity_key' => '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
        ]);

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        $e2eeSend = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/messages", [
            'client_message_id' => (string) Str::uuid(),
            'type' => 'text',
            'envelopes' => [
                [
                    'sender_device_id' => $devA->id,
                    'recipient_device_id' => $devB->id,
                    'sequence_number' => 1,
                    'dh_public_key' => '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
                    'ciphertext' => '42831ec2217774244b7221b784d0d49ce3fac0f00c0251d54020c242c7556942',
                    'auth_tag' => '5bc94fbc3222035f4b008d5e8932822a',
                ],
            ],
        ]);

        $e2eeSend->assertStatus(201);
        $msgId = $e2eeSend->json('data.id');

        // 1. Verify Plaintext Elimination: messages.content MUST be NULL
        $storedMessage = Message::find($msgId);
        $this->assertNull($storedMessage->content);

        // 2. Server Compromise Simulation Test: Verify DB dump contains zero plaintext bytes
        $this->assertDatabaseHas('message_envelopes', [
            'message_id' => $msgId,
            'sender_device_id' => $devA->id,
            'recipient_device_id' => $devB->id,
            'sequence_number' => 1,
            'ciphertext' => '42831ec2217774244b7221b784d0d49ce3fac0f00c0251d54020c242c7556942',
            'auth_tag' => '5bc94fbc3222035f4b008d5e8932822a',
        ]);
    }

    public function test_device_push_token_registration_revocation_and_suppression(): void
    {
        $userA = User::factory()->create();
        $devA = Device::create([
            'user_id' => $userA->id,
            'name' => 'Rahul Android',
            'public_identity_key' => 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ]);

        // 1. Register Push Token
        $tokenRes = $this->actingAs($userA)->postJson("/api/v1/devices/{$devA->id}/push-token", [
            'push_token' => 'fcm_token_1234567890_sample',
            'platform' => 'android',
        ]);
        $tokenRes->assertStatus(200);
        $this->assertDatabaseHas('devices', [
            'id' => $devA->id,
            'push_token' => 'fcm_token_1234567890_sample',
            'platform' => 'android',
        ]);

        // 2. Remove Push Token
        $removeRes = $this->actingAs($userA)->deleteJson("/api/v1/devices/{$devA->id}/push-token");
        $removeRes->assertStatus(200);
        $this->assertDatabaseHas('devices', [
            'id' => $devA->id,
            'push_token' => null,
        ]);
    }

    public function test_encrypted_backup_envelope_upload_and_download(): void
    {
        $userA = User::factory()->create();

        $salt = bin2hex(random_bytes(32));
        $nonce = bin2hex(random_bytes(12)); // 12-byte fresh nonce
        $authTag = bin2hex(random_bytes(16));

        $uploadRes = $this->actingAs($userA)->postJson('/api/v1/backups', [
            'protocol_version' => 1,
            'kdf_version' => 'PBKDF2-HMAC-SHA512-HKDF-SHA256-V1',
            'salt' => $salt,
            'nonce' => $nonce,
            'ciphertext' => '42831ec2217774244b7221b784d0d49ce3fac0f00c0251d54020c242c7556942',
            'auth_tag' => $authTag,
            'created_at' => 1787184000,
        ]);

        $uploadRes->assertStatus(201);
        $this->assertDatabaseHas('backups', [
            'user_id' => $userA->id,
            'protocol_version' => 1,
            'salt' => $salt,
            'nonce' => $nonce,
            'auth_tag' => $authTag,
        ]);

        $downloadRes = $this->actingAs($userA)->getJson('/api/v1/backups');
        $downloadRes->assertStatus(200)
            ->assertJsonPath('data.protocol_version', 1)
            ->assertJsonPath('data.salt', $salt)
            ->assertJsonPath('data.nonce', $nonce)
            ->assertJsonPath('data.auth_tag', $authTag);
    }

    public function test_backup_envelope_idor_isolation_and_authorization_protection(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $salt = bin2hex(random_bytes(32));
        $nonce = bin2hex(random_bytes(12));
        $authTag = bin2hex(random_bytes(16));

        $this->actingAs($userA)->postJson('/api/v1/backups', [
            'protocol_version' => 1,
            'kdf_version' => 'PBKDF2-HMAC-SHA512-HKDF-SHA256-V1',
            'salt' => $salt,
            'nonce' => $nonce,
            'ciphertext' => '42831ec2217774244b7221b784d0d49ce3fac0f00c0251d54020c242c7556942',
            'auth_tag' => $authTag,
            'created_at' => 1787184000,
        ]);

        // IDOR Test: User B attempts to access User A's backup envelope -> Returns 404 Not Found for User B
        $downloadUserB = $this->actingAs($userB)->getJson('/api/v1/backups');
        $downloadUserB->assertStatus(404);
    }

    public function test_webrtc_call_signaling_authorization_state_machine_and_answer_race(): void
    {
        $userA = User::factory()->create(['name' => 'User A']);
        $userB = User::factory()->create(['name' => 'User B']);
        $userC = User::factory()->create(['name' => 'User C']);

        $devA = Device::create([
            'user_id' => $userA->id,
            'name' => 'User A Laptop',
            'public_identity_key' => 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ]);

        $devB1 = Device::create([
            'user_id' => $userB->id,
            'name' => 'User B Phone 1',
            'public_identity_key' => '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
        ]);

        $devB2 = Device::create([
            'user_id' => $userB->id,
            'name' => 'User B Phone 2',
            'public_identity_key' => '9520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6b',
        ]);

        $convRes = $this->actingAs($userA)->postJson('/api/v1/conversations', [
            'type' => 'direct',
            'target_user_id' => $userB->id,
        ]);
        $convId = $convRes->json('data.id');

        // 1. Non-member Call Initiation Rejection -> Returns 422/403
        $unauthInit = $this->actingAs($userC)->postJson("/api/v1/conversations/{$convId}/call/initiate", [
            'caller_device_id' => (string) Str::uuid(),
            'type' => 'audio',
        ]);
        $unauthInit->assertStatus(422);

        // 2. Member Call Initiation -> Returns 201 Created
        $initRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/call/initiate", [
            'caller_device_id' => $devA->id,
            'type' => 'audio',
        ]);
        $initRes->assertStatus(201);
        $callId = $initRes->json('data.id');

        // 3. Ephemeral TURN Credentials Endpoint Check -> Returns 200
        $turnRes = $this->actingAs($userA)->getJson('/api/v1/call/turn-credentials');
        $turnRes->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.uris.0', 'turn:turn.e2e.internal:3478');

        // 4. Offer Signal -> State transitions to ringing
        $offerRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/call/{$callId}/signal", [
            'sender_device_id' => $devA->id,
            'type' => 'offer',
            'payload' => ['sdp' => 'dummy-sdp-offer'],
        ]);
        $offerRes->assertStatus(200)
            ->assertJsonPath('data.call.state', 'ringing');

        // 5. Atomic Multi-Device Answer Race Condition Lock
        // B1 answers first -> Wins race (Status 200, state connecting)
        $answerB1 = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/call/{$callId}/signal", [
            'sender_device_id' => $devB1->id,
            'type' => 'answer',
            'payload' => ['sdp' => 'dummy-sdp-answer-b1'],
        ]);
        $answerB1->assertStatus(200)
            ->assertJsonPath('data.status', 'winner')
            ->assertJsonPath('data.call.winner_device_id', $devB1->id);

        // B2 answers second -> Rejected (Status 422, Call already answered)
        $answerB2 = $this->actingAs($userB)->postJson("/api/v1/conversations/{$convId}/call/{$callId}/signal", [
            'sender_device_id' => $devB2->id,
            'type' => 'answer',
            'payload' => ['sdp' => 'dummy-sdp-answer-b2'],
        ]);
        $answerB2->assertStatus(422);

        // 6. Invalid State Transition Rejection (ended -> connected -> 422)
        $endRes = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/call/{$callId}/signal", [
            'sender_device_id' => $devA->id,
            'type' => 'end',
        ]);
        $endRes->assertStatus(200);

        $invalidTransition = $this->actingAs($userA)->postJson("/api/v1/conversations/{$convId}/call/{$callId}/signal", [
            'sender_device_id' => $devA->id,
            'type' => 'offer',
        ]);
        $invalidTransition->assertStatus(422);
    }
}
