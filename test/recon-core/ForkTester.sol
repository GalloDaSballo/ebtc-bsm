// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {TargetFunctions} from "./TargetFunctions.sol";
import {CryticAsserts} from "@chimera/CryticAsserts.sol";

// echidna . --contract ForkTester --config echidna.yaml --format text --workers 16 --test-limit 1000000 --rpc-url URL
// medusa fuzz
contract ForkTester is TargetFunctions, CryticAsserts {
    constructor() payable {
        setup();
        _setupFork();
        _govFuzzing();
    }
}
