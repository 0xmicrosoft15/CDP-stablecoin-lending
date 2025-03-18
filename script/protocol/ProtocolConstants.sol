// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "src/Constants.sol" as Constants;

library Protocol {
    address constant DEPLOYER = 0xFE11a5009f2121622271e7dd0FD470264e076af6;

    // Core Protocol
    address constant CORE = 0xc07e000044F95655c11fda4cD37F70A94d7e0a7d;
    address constant GOV_TOKEN = 0x419905009e4656fdC02418C7Df35B1E61Ed5F726;
    address constant VEST_MANAGER = 0x6666666677B06CB55EbF802BB12f8876360f919c;
    address constant STABLECOIN = 0x57aB1E0003F623289CD798B1824Be09a793e4Bec;
    address constant REGISTRY = 0x10101010E0C3171D894B71B3400668aF311e7D94;
    address constant GOV_STAKER = 0x22222222E9fE38F6f1FC8C61b25228adB4D8B953;
    address constant AUTO_STAKE_CALLBACK = 0x4888205F02df9832274d470C685baA728f128745;
    address constant VOTER = 0x11111111084a560ea5755Ed904a57e5411888C28;
    address constant EMISSIONS_CONTROLLER = 0x33333333df05b0D52edD13D230461E5A0f5a4706;
    address constant TREASURY = 0x4444444455bF42de586A88426E5412971eA48324;
    address constant PAIR_DEPLOYER = 0x5555555524De7C56C1B20128dbEAace47d2C0417;
    address constant INTEREST_RATE_CALCULATOR = 0x77777777729C405efB6Ac823493e6111F0070D67;
    
    // Oracles
    address constant BASIC_VAULT_ORACLE = 0xcb7E25fbbd8aFE4ce73D7Dac647dbC3D847F3c82;
    address constant UNDERLYING_ORACLE = 0x414CFAFa12FeE1260114BCd22058D5293da27c94;
    
    // Handlers
    address constant REDEMPTION_HANDLER = 0x99999999BeaAE496551793313a7653553d1e0B3A;
    address constant LIQUIDATION_HANDLER = 0x88888888c227c36401493Ed9F3e3Dcc3800B2634;
    address constant REWARD_HANDLER = 0xdBF41092e1E310a2B48B0895095EfF6d341D8F00;
    
    // Receivers
    address constant SIMPLE_RECEIVER_IMPLEMENTATION = 0x2D4e8Bff0c23571016d7b329b9Fd76441f4a37c9;
    address constant SIMPLE_RECEIVER_FACTORY = 0x20d55f2bb72ebDe67A4325FB757348ea3d9014D8;
    address constant DEBT_RECEIVER = 0x70a1879aEeA28072E321d52427f0aC88603dF61b;
    address constant INSURANCE_POOL_RECEIVER = 0x8b36aD6A6605745529908C90cCC90F05901155b4;
    
    // Pools and Streams
    address constant INSURANCE_POOL = 0x00000000efe883b3304aFf71eaCf72Dbc3e1b577;
    address constant IP_STABLE_STREAM = 0xCd32c9bf38AbfEEc2F5691Dcb39cbc9aC55f0685;
    address constant EMISSION_STREAM_INSURANCE_POOL = 0xB96699a960A2b6300889b4FB789A58B506F144Ca;
    address constant EMISSIONS_STREAM_PAIR = 0x11D5Bc6175E416ECCe06d7c94F232E6c7330fDd3;
    
    // Fee Related
    address constant FEE_DEPOSIT = 0x07Ad4630985ADe5B5307806C43E57e0A9A932C52;
    address constant FEE_DEPOSIT_CONTROLLER = 0x7E3D2F480AbbA95863040D763DDe8F30D100C6F5;
    
    // Utilities
    address constant UTILITIES = 0x384e77E48818835cAAf8Ad5cF74AB04cED9af4A5;
    address constant SWAPPER = 0x042f48346be16Be381190a7397A80808243f3b2e;
    
    // Stakers
    address constant PERMA_STAKER_CONVEX = 0xCCCCCccc94bFeCDd365b4Ee6B86108fC91848901;
    address constant PERMA_STAKER_YEARN = 0x12341234B35c8a48908c716266db79CAeA0100E8;
    
    // Pools and Gauges
    address constant REUSD_SCRVUSD_POOL = 0xc522A6606BBA746d7960404F22a3DB936B6F4F50;
    address constant REUSD_SFRXUSD_POOL = 0xed785Af60bEd688baa8990cD5c4166221599A441;
    address constant WETH_RSUP_POOL = 0xEe351f12EAE8C2B8B9d1B9BFd3c5dd565234578d;
    address constant REUSD_SCRVUSD_GAUGE = 0xaF01d68714E7eA67f43f08b5947e367126B889b1;
    address constant REUSD_SFRXUSD_GAUGE = 0x5C0B03914f68F2717d779a0211fd98C2CC45a4dD;
    address constant WETH_RSUP_GAUGE = 0x09F62a6777032329C0d49F1FD4fBe9b3468CDa56;

    // CurveLend Pairs
    address constant PAIR_CURVELEND_SFRXUSD_CRVUSD = 0xC5184cccf85b81EDdc661330acB3E41bd89F34A1;
    address constant PAIR_CURVELEND_SDOLA_CRVUSD = 0x08064A8eEecf71203449228f3eaC65E462009fdF;
    address constant PAIR_CURVELEND_SUSDE_CRVUSD = 0x39Ea8e7f44E9303A7441b1E1a4F5731F1028505C;
    address constant PAIR_CURVELEND_USDE_CRVUSD = 0x3b037329Ff77B5863e6a3c844AD2a7506ABe5706;
    address constant PAIR_CURVELEND_TBTC_CRVUSD = 0x22B12110f1479d5D6Fd53D0dA35482371fEB3c7e;
    address constant PAIR_CURVELEND_WBTC_CRVUSD = 0x2d8ecd48b58e53972dBC54d8d0414002B41Abc9D;
    address constant PAIR_CURVELEND_WETH_CRVUSD = 0xCF1deb0570c2f7dEe8C07A7e5FA2bd4b2B96520D;
    address constant PAIR_CURVELEND_WSTETH_CRVUSD = 0x4A7c64932d1ef0b4a2d430ea10184e3B87095E33;
    
    // FraxLend Pairs
    address constant PAIR_FRAXLEND_SFRXETH_FRXUSD = 0x3F2b20b8E8Ce30bb52239d3dFADf826eCFE6A5f7;
    address constant PAIR_FRAXLEND_SUSDE_FRXUSD = 0x212589B06EBBA4d89d9deFcc8DDc58D80E141EA0;
    address constant PAIR_FRAXLEND_WBTC_FRXUSD = 0x55c49c707aA0Ad254F34a389a8dFd0d103894aDb;
    address constant PAIR_FRAXLEND_SCRVUSD_FRXUSD = 0x24CCBd9130ec24945916095eC54e9acC7382c864;
}

library VMConstants {
    address constant FRAX_VEST_TARGET = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;
    uint256 constant MAX_REDEEMABLE = 176_036_676e18;
    uint256 constant TEAM_DURATION = 365 days * 5;
    uint256 constant VICTIMS_DURATION = 365 days * 5;
    uint256 constant LOCK_PENALTY_DURATION = 365 days * 5;

    bytes32 constant TEAM_MERKLE_ROOT = 0x14feca1e86fd4443d0e3a2048c145242a74e1d3e98bcede716421c826f009c6a;
    bytes32 constant VICTIMS_MERKLE_ROOT = 0x706fe5d7fc617632ac4600bf675ece0a444b89de29ca64e264af97e61665b6bb;
    bytes32 constant PENALTY_MERKLE_ROOT = 0x550558788f6e04718c149a11379110155dfd5ee25d811abbe671a0073767473f;

    uint256 constant DURATION_PERMA_STAKER = uint256(365 days * 5);
    uint256 constant DURATION_LICENSING = uint256(365 days * 1);
    uint256 constant DURATION_TREASURY = uint256(365 days * 5);
    uint256 constant DURATION_REDEMPTIONS = uint256(365 days * 3);
    uint256 constant DURATION_AIRDROP_TEAM = uint256(365 days * 1);
    uint256 constant DURATION_AIRDROP_VICTIMS = uint256(365 days * 2);
    uint256 constant DURATION_AIRDROP_LOCK_PENALTY = uint256(365 days * 5);

    uint256 constant ALLOC_PERMA_STAKER_1 = uint256(333333333333333333);
    uint256 constant ALLOC_PERMA_STAKER_2 = uint256(166666666666666666);
    uint256 constant ALLOC_LICENSING = uint256(8333333333333334);
    uint256 constant ALLOC_TREASURY = uint256(175000000000000000);
    uint256 constant ALLOC_REDEMPTIONS = uint256(250000000000000000);
    uint256 constant ALLOC_AIRDROP_TEAM = uint256(33333333333333333);
    uint256 constant ALLOC_AIRDROP_VICTIMS = uint256(33333333333333334);
    uint256 constant ALLOC_AIRDROP_LOCK_PENALTY = uint256(0);
}