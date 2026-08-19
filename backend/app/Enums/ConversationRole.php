<?php

namespace App\Enums;

enum ConversationRole: string
{
    case MEMBER = 'member';
    case ADMIN = 'admin';
}
