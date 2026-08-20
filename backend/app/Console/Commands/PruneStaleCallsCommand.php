<?php

namespace App\Console\Commands;

use App\Services\CallService;
use Illuminate\Console\Command;

class PruneStaleCallsCommand extends Command
{
    protected $signature = 'calls:prune-stale {--timeout=60 : Timeout in seconds for abandoned calls}';
    protected $description = 'Prune abandoned calls in non-terminal states older than specified timeout';

    public function handle(CallService $callService): int
    {
        $timeout = (int) $this->option('timeout');
        $count = $callService->pruneStaleCalls($timeout);

        $this->info("Pruned {$count} stale call(s) older than {$timeout} seconds.");

        return Command::SUCCESS;
    }
}
