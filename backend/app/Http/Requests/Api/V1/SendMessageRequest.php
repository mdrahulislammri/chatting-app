<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\MessageType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;

class SendMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'client_message_id' => ['required', 'uuid'],
            'content' => ['required_without_all:attachment_url,envelopes', 'nullable', 'string'],
            'type' => ['sometimes', new Enum(MessageType::class)],
            'attachment_url' => ['nullable', 'string', 'url'],
            'attachment_name' => ['nullable', 'string', 'max:255'],
            'attachment_size' => ['nullable', 'integer'],
            'mime_type' => ['nullable', 'string', 'max:128'],
            'reply_to_id' => ['nullable', 'exists:messages,id'],
            'envelopes' => ['nullable', 'array'],
            'envelopes.*.sender_device_id' => ['required_with:envelopes', 'exists:devices,id'],
            'envelopes.*.recipient_device_id' => ['required_with:envelopes', 'exists:devices,id'],
            'envelopes.*.sequence_number' => ['required_with:envelopes', 'integer'],
            'envelopes.*.dh_public_key' => ['nullable', 'string'],
            'envelopes.*.ciphertext' => ['required_with:envelopes', 'string'],
            'envelopes.*.auth_tag' => ['nullable', 'string'],
        ];
    }
}
