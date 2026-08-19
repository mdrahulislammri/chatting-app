<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\ConversationType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;

class CreateConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['required', new Enum(ConversationType::class)],
            'target_user_id' => ['required_if:type,direct', 'nullable', 'exists:users,id'],
            'name' => ['required_if:type,group', 'nullable', 'string', 'max:255'],
            'member_ids' => ['required_if:type,group', 'array'],
            'member_ids.*' => ['exists:users,id'],
        ];
    }
}
