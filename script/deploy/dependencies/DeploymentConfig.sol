// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "src/Constants.sol" as Constants;

library DeploymentConfig {
    address constant DEPLOYER = 0xFE11a5009f2121622271e7dd0FD470264e076af6;
    address constant FRAX_VEST_TARGET = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;
    address constant PRISMA_TOKENS_BURN_ADDRESS = address(0xdead);
    uint256 constant EPOCH_LENGTH = 1 weeks;
    uint24 constant STAKER_COOLDOWN_EPOCHS = 2;

    // Token configuration
    uint256 constant GOV_TOKEN_INITIAL_SUPPLY = 60_000_000e18;
    string constant GOV_TOKEN_NAME = "Resupply";
    string constant GOV_TOKEN_SYMBOL = "RSUP";

    // PermaStaker
    string constant PERMA_STAKER_CONVEX_NAME = "Resupply PermaStaker: Convex";
    string constant PERMA_STAKER_YEARN_NAME = "Resupply PermaStaker: Yearn";
    address constant PERMA_STAKER_CONVEX_OWNER = 0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB;
    address constant PERMA_STAKER_YEARN_OWNER = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;

    // Emissions weights (1e4 precision)
    uint256 constant INITIAL_EMISSIONS_WEIGHT_DEBT = 2500;
    uint256 constant INITIAL_EMISSIONS_WEIGHT_INSURANCE_POOL = 2500;
    uint256 constant INITIAL_EMISSIONS_WEIGHT_LP = 5000;

    // Voter configuration (1e4 precision)
    uint256 constant VOTER_MIN_CREATE_PROPOSAL_PCT = 100;
    uint256 constant VOTER_QUORUM_PCT = 3000;

    // Emissions controller configuration (rates are 1e18 precision)
    uint256 constant EMISSIONS_SCHEDULE_YEAR_1 = 183143319640535100;
    uint256 constant EMISSIONS_SCHEDULE_YEAR_2 = 130573632743654969;
    uint256 constant EMISSIONS_SCHEDULE_YEAR_3 = 93429770042296321;
    uint256 constant EMISSIONS_SCHEDULE_YEAR_4 = 64756001614012807;
    uint256 constant EMISSIONS_SCHEDULE_YEAR_5 = 40950214498301975;
    uint256 constant EMISSIONS_CONTROLLER_TAIL_RATE = 19860811573103551;
    uint256 constant EMISSIONS_CONTROLLER_EPOCHS_PER = 52;
    uint256 constant EMISSIONS_CONTROLLER_BOOTSTRAP_EPOCHS = 0;

    // Configs: Protocol
    uint256 constant DEFAULT_BORROW_LIMIT = 0;
    uint256 constant DEFAULT_MAX_LTV = 95_000; // 1e5 precision
    uint256 constant DEFAULT_LIQ_FEE = 5_000;  // 1e5 precision
    uint256 constant DEFAULT_MINT_FEE = 0;     // 1e5 precision
    uint256 constant DEFAULT_PROTOCOL_REDEMPTION_FEE = 1e18 / 2; // portion of fee for stakers (1e18 precision)
    uint256 constant FEE_SPLIT_IP = 2500;      // 1e4 precision
    uint256 constant FEE_SPLIT_TREASURY = 500; // 1e4 precision
    uint256 constant FEE_SPLIT_STAKERS = 7000; // 1e4 precision

    // Tokens
    address constant SCRVUSD = Constants.Mainnet.CURVE_SCRVUSD;
    address constant SFRXUSD = Constants.Mainnet.SFRXUSD_ERC20;
    address constant CURVE_STABLE_FACTORY = Constants.Mainnet.CURVE_STABLE_FACTORY;

    // SafeHelper
    uint256 constant MAX_GAS_PER_BATCH = 15_000_000;
}

library CreateX {
    address internal constant CREATEX_DEPLOYER = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;
    // Salts
    bytes32 internal constant SALT_GOV_TOKEN = 0xfe11a5009f2121622271e7dd0fd470264e076af6007817270164e1790196c4f0; // 0x419905
    bytes32 internal constant SALT_STABLECOIN = 0xfe11a5009f2121622271e7dd0fd470264e076af6007d4a011e1aea8d0220315d; // 0x57ab1e
    bytes32 internal constant SALT_CORE = 0xfe11a5009f2121622271e7dd0fd470264e076af60075182fe1eff89e02ce3cff; // 0xc07e0000
    bytes32 internal constant SALT_REGISTRY = 0xfe11a5009f2121622271e7dd0fd470264e076af60035199030be4b0602635825; // 0x1010101
    bytes32 internal constant SALT_INSURANCE_POOL = 0xfe11a5009f2121622271e7dd0fd470264e076af600bd0b20142b743201bee438; // 0x000000
    bytes32 internal constant SALT_VOTER = 0xfe11a5009f2121622271e7dd0fd470264e076af60005f722dce9505702447be8; // 0x11111
    bytes32 internal constant SALT_GOV_STAKER = 0xfe11a5009f2121622271e7dd0fd470264e076af600ac101fb2686a8c0015ef91; // 0x22222
    bytes32 internal constant SALT_EMISSIONS_CONTROLLER = 0xfe11a5009f2121622271e7dd0fd470264e076af60045a2b62cd5fec002054177; // 0x3333
    bytes32 internal constant SALT_TREASURY = 0xfe11a5009f2121622271e7dd0fd470264e076af6003e18f2a15963dc02ebe90a; // 0x44444
    bytes32 internal constant SALT_PAIR_DEPLOYER = 0xfe11a5009f2121622271e7dd0fd470264e076af6005ae1044d7cd9aa0200df43; // 0x55555
    bytes32 internal constant SALT_VEST_MANAGER = 0xfe11a5009f2121622271e7dd0fd470264e076af6000cc7db37bf283f00158d19; // 0x66666
    bytes32 internal constant SALT_INTEREST_RATE_CALCULATOR = 0xfe11a5009f2121622271e7dd0fd470264e076af6005763a7460bd2b7038a032e; // 0x77777
    bytes32 internal constant SALT_LIQUIDATION_HANDLER = 0xfe11a5009f2121622271e7dd0fd470264e076af600574340f6003cec01964db0; // 0x88888
    bytes32 internal constant SALT_REDEMPTION_HANDLER = 0xfe11a5009f2121622271e7dd0fd470264e076af6002dd74d21d97b27032aca93; // 0x99999
    bytes32 internal constant SALT_PERMA_STAKER_CONVEX = 0xfe11a5009f2121622271e7dd0fd470264e076af600847421d8997e1100819f27; // 0xCCCCC
    bytes32 internal constant SALT_PERMA_STAKER_YEARN = 0xfe11a5009f2121622271e7dd0fd470264e076af6005045c04e56a6ce00770772; // 0x12341234
    bytes32 internal constant SALT_OPERATOR_TREASURY_MANAGER = 0xfe11a5009f2121622271e7dd0fd470264e076af6004743fa1885004c02ae2b7e; // 0x095000
    bytes32 internal constant SALT_OPERATOR_GUARDIAN = 0xfe11a5009f2121622271e7dd0fd470264e076af6001380bed7c94ead020a25f8; // 0x095000
    /** 
        SALTS FOR FUTURE OPERATORS TO FOLLOW 0x0950000 SCHEME
        0xfe11a5009f2121622271e7dd0fd470264e076af6001b04d4d7f44d8c01b71aaa => 0x0950000465476f4470e74aed93e7dd414012bb7d
        0xfe11a5009f2121622271e7dd0fd470264e076af60058385547c1b50603df6c9b => 0x09500002956877b910acec25c4b4dd57950e1d27
        0xfe11a5009f2121622271e7dd0fd470264e076af60022dc4c0dc6a32301563648 => 0x09500002b2ab5fab995484b05891b81d1edca715
        0xfe11a5009f2121622271e7dd0fd470264e076af6002a99d75d961e5701acceda => 0x095000080f12cd151be097d725b584053b41ad35
        0xfe11a5009f2121622271e7dd0fd470264e076af600c9b1f187e88ec700f38fac => 0x09500001256135b85bbec83707345fd865db1f83
        0xfe11a5009f2121622271e7dd0fd470264e076af600973c457185db0b00a8fb81 => 0x0950000bb4a9b3299102bee709181ec1e6100682
        0xfe11a5009f2121622271e7dd0fd470264e076af60070bd561cb52e6a00bd7fe6 => 0x0950000250cd27d27fb4b4f6e41419148d6e1ac3
        0xfe11a5009f2121622271e7dd0fd470264e076af600fec2b4042d1062007f70a5 => 0x0950000bc094568c16767135c45cdef83d8a84c9
        0xfe11a5009f2121622271e7dd0fd470264e076af6002bf63f4a33684a03b44360 => 0x09500007ad20e37398705d6e25f25cdf43210a0f
        0xfe11a5009f2121622271e7dd0fd470264e076af600cd45ff03928a9501cebac0 => 0x0950000920f5c80a46a323fff19f22ca70dabed9
        0xfe11a5009f2121622271e7dd0fd470264e076af6008557be70d183b403e1ac59 => 0x09500001fcc259a0c160a063ae78aec9fdcf69bd
        0xfe11a5009f2121622271e7dd0fd470264e076af600577cf67d63a37b03850fe2 => 0x09500003beb44dba2ac47abe21423ac52e33acee
        0xfe11a5009f2121622271e7dd0fd470264e076af600108ab4fe1e57d703eeb083 => 0x0950000f2f06074ebaf41ffdf15b088448a3084a
        0xfe11a5009f2121622271e7dd0fd470264e076af60081620eb02f479c00137499 => 0x0950000b6eab63f0d4b028bde07df7dbf952428a
        0xfe11a5009f2121622271e7dd0fd470264e076af6004806377bf8da9f016fff92 => 0x095000020e866084a8b2e493a9c8259a5a7eb95b
        0xfe11a5009f2121622271e7dd0fd470264e076af600698b55029a901e00ba9752 => 0x0950000b6cc1c3480cc1c07ab3055a4dce292348
    */
}
