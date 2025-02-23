import { BaseDeploy } from "./BaseDeploy.s.sol";
import { ResupplyPairDeployer } from "src/protocol/ResupplyPairDeployer.sol";
import { ResupplyPair } from "src/protocol/ResupplyPair.sol";
import { InterestRateCalculator } from "src/protocol/InterestRateCalculator.sol";
import { BasicVaultOracle } from "src/protocol/BasicVaultOracle.sol";
import { RedemptionHandler } from "src/protocol/RedemptionHandler.sol";
import { SimpleReceiver } from "src/dao/emissions/receivers/SimpleReceiver.sol";
import { SimpleReceiverFactory } from "src/dao/emissions/receivers/SimpleReceiverFactory.sol";
import { InsurancePool } from "src/protocol/InsurancePool.sol";
import { LiquidationHandler } from "src/protocol/LiquidationHandler.sol";
import { RewardHandler } from "src/protocol/RewardHandler.sol";
import { FeeDeposit } from "src/protocol/FeeDeposit.sol";
import { FeeDepositController } from "src/protocol/FeeDepositController.sol";
import { SimpleRewardStreamer } from "src/protocol/SimpleRewardStreamer.sol";
import { console } from "forge-std/console.sol";
import { ICore } from "src/interfaces/ICore.sol";
import { ResupplyRegistry } from "src/protocol/ResupplyRegistry.sol";

contract DeployResupplyProtocol is BaseDeploy {

    function deployProtocolContracts() public {

        // ============================================
        // ======= Deploy ResupplyPairDeployer ========
        // ============================================
        bytes memory constructorArgs = abi.encode(
            address(core),
            address(govToken),
            dev
        );
        bytes memory bytecode = abi.encodePacked(vm.getCode("ResupplyPairDeployer.sol:ResupplyPairDeployer"), constructorArgs);
        bytes32 salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("ResupplyPairDeployer"))))
        );
        address predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        pairDeployer = ResupplyPairDeployer(predictedAddress);
        console.log("pairDeployer deployed at", address(pairDeployer));
        writeAddressToJson("PAIR_DEPLOYER", predictedAddress);
        // ============================================
        // ====== Deploy InterestRateCalculator =======
        // ============================================
        constructorArgs = abi.encode(
            "Base",
            2e16 / uint256(365 days),//2%
            2
        );
        bytecode = abi.encodePacked(vm.getCode("InterestRateCalculator.sol:InterestRateCalculator"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("InterestRateCalculator"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        rateCalculator = InterestRateCalculator(predictedAddress);
        console.log("InterestRateCalculator deployed at", address(rateCalculator));
        writeAddressToJson("INTEREST_RATE_CALCULATOR", predictedAddress);
        // ============================================
        // ====== Deploy BasicVaultOracle =============
        // ============================================
        constructorArgs = abi.encode(
            "Basic Vault Oracle"
        );
        bytecode = abi.encodePacked(vm.getCode("BasicVaultOracle.sol:BasicVaultOracle"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("BasicVaultOracle"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        oracle = BasicVaultOracle(predictedAddress);
        console.log("BasicVaultOracle deployed at", address(oracle));
        writeAddressToJson("BASIC_VAULT_ORACLE", predictedAddress);

        // ============================================
        // ====== Deploy RedemptionHandler ============
        // ============================================
        constructorArgs = abi.encode(
            address(core)
        );
        bytecode = abi.encodePacked(vm.getCode("RedemptionHandler.sol:RedemptionHandler"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("RedemptionHandler"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        redemptionHandler = RedemptionHandler(predictedAddress);
        console.log("RedemptionHandler deployed at", address(redemptionHandler));
        writeAddressToJson("REDEMPTION_HANDLER", predictedAddress);
    }

    function deployRewardsContracts() public {
        address[] memory rewards = new address[](3);
        rewards[0] = address(govToken);
        rewards[1] = address(fraxToken);
        rewards[2] = address(crvusdToken);
        bytes memory result;    

        // ============================================
        // ====== Deploy SimpleReceiver =================
        // ============================================
        bytes memory constructorArgs = abi.encode(
            address(core),
            address(emissionsController)
        );
        bytes memory bytecode = abi.encodePacked(vm.getCode("SimpleReceiver.sol:SimpleReceiver"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("SimpleReceiver"))))
        );
        address predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        console.log("SimpleReceiver implementation deployed at", address(predictedAddress));
        writeAddressToJson("SIMPLE_RECEIVER_IMPLEMENTATION", predictedAddress);

        // ============================================
        // ====== Deploy SimpleReceiverFactory ========
        // ============================================
        constructorArgs = abi.encode(
            address(core),
            address(emissionsController),
            address(predictedAddress)
        );
        bytecode = abi.encodePacked(vm.getCode("SimpleReceiverFactory.sol:SimpleReceiverFactory"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("SimpleReceiverFactory"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        receiverFactory = SimpleReceiverFactory(predictedAddress);
        console.log("SimpleReceiverFactory deployed at", address(receiverFactory));
        writeAddressToJson("SIMPLE_RECEIVER_FACTORY", predictedAddress);

        // ============================================
        // ====== Deploy DebtReceiver =================
        // ============================================
        result = _executeCore(
            address(receiverFactory), 
            abi.encodeWithSelector(SimpleReceiverFactory.deployNewReceiver.selector, "Debt Receiver", new address[](0))
        );
        result = abi.decode(result, (bytes)); // our result was double encoded, so we decode it once
        debtReceiver = SimpleReceiver(abi.decode(result, (address))); // decode the bytes result to an address
        console.log("Debt Receiver deployed at", address(debtReceiver));
        writeAddressToJson("DEBT_RECEIVER", predictedAddress);

        // ============================================
        // ====== Deploy InsurancePoolReceiver =============
        // ============================================
        result = _executeCore(
            address(receiverFactory), 
            abi.encodeWithSelector(SimpleReceiverFactory.deployNewReceiver.selector, "Insurance Receiver", new address[](0))
        );
        result = abi.decode(result, (bytes)); // our result was double encoded, so we decode it once
        insuranceEmissionsReceiver = SimpleReceiver(abi.decode(result, (address))); // decode the bytes result to an address
        console.log("Insurance Pool Receiver deployed at", address(insuranceEmissionsReceiver));
        writeAddressToJson("INSURANCE_POOL_RECEIVER", predictedAddress);

        // ============================================
        // ====== Deploy InsurancePool ================
        // ============================================
        constructorArgs = abi.encode(
            address(core),
            address(stablecoin),
            rewards,
            address(insuranceEmissionsReceiver)
        );
        bytecode = abi.encodePacked(vm.getCode("InsurancePool.sol:InsurancePool"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("InsurancePool"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        insurancePool = InsurancePool(predictedAddress);
        console.log("Insurance Pool deployed at", address(insurancePool));
        writeAddressToJson("INSURANCE_POOL", predictedAddress);
        // ============================================
        // ====== Deploy LiquidationHandler ============
        // ============================================
        constructorArgs = abi.encode(
            address(core),
            address(insurancePool)
        );
        bytecode = abi.encodePacked(vm.getCode("LiquidationHandler.sol:LiquidationHandler"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("LiquidationHandler"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        liquidationHandler = LiquidationHandler(predictedAddress);
        console.log("Liquidation Handler deployed at", address(liquidationHandler));
        writeAddressToJson("LIQUIDATION_HANDLER", predictedAddress);

        // ============================================
        // ====== Deploy IPStableStream ===============
        // ============================================
        constructorArgs = abi.encode(
            address(stablecoin),
            address(core),
            address(insurancePool)
        );
        bytecode = abi.encodePacked(vm.getCode("SimpleRewardStreamer.sol:SimpleRewardStreamer"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("IPStableStream"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);   
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        ipStableStream = SimpleRewardStreamer(predictedAddress);
        console.log("IP Stable Stream deployed at", address(ipStableStream));
        writeAddressToJson("IP_STABLE_STREAM", predictedAddress);

        // ============================================
        // ====== Deploy IP Emission Stream ===============
        // ============================================
        constructorArgs = abi.encode(
            address(govToken),
            address(core), 
            address(insurancePool)
        );
        bytecode = abi.encodePacked(vm.getCode("SimpleRewardStreamer.sol:SimpleRewardStreamer"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("IPEmissionStream"))))
        );  
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        ipEmissionStream = SimpleRewardStreamer(predictedAddress);
        console.log("IP Emission Stream deployed at", address(ipEmissionStream));
        writeAddressToJson("EMISSION_STREAM_INSURANCE_POOL", predictedAddress);

        // ============================================
        // ====== Deploy PairEmissionStream =========
        // ============================================
        constructorArgs = abi.encode(
            address(govToken),
            address(core), 
            address(0)
        );
        bytecode = abi.encodePacked(vm.getCode("SimpleRewardStreamer.sol:SimpleRewardStreamer"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChainProtection
            uint88(uint256(keccak256(bytes("PairEmissionStream"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        pairEmissionStream = SimpleRewardStreamer(predictedAddress);
        console.log("Pair Emission Stream deployed at", address(pairEmissionStream));
        writeAddressToJson("EMISSIONS_STREAM_PAIR", predictedAddress);

        // ============================================     
        // ====== Deploy FeeDeposit ==================
        // ============================================
        constructorArgs = abi.encode(
            address(core),
            address(stablecoin)
        );
        bytecode = abi.encodePacked(vm.getCode("FeeDeposit.sol:FeeDeposit"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChain Protection
            uint88(uint256(keccak256(bytes("FeeDeposit"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        feeDeposit = FeeDeposit(predictedAddress);
        console.log("FeeDeposit deployed at", address(feeDeposit));
        writeAddressToJson("FEE_DEPOSIT", predictedAddress);
        // ============================================
        // ====== Deploy FeeDepositController ========
        // ============================================
        constructorArgs = abi.encode(
            address(core),
            address(feeDeposit), 
            FEE_SPLIT_IP,       // 15%
            FEE_SPLIT_TREASURY // 5%
        );
        bytecode = abi.encodePacked(vm.getCode("FeeDepositController.sol:FeeDepositController"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChain Protection
            uint88(uint256(keccak256(bytes("FeeDepositController"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),    
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        feeDepositController = FeeDepositController(predictedAddress);
        console.log("FeeDepositController deployed at", address(feeDepositController));
        writeAddressToJson("FEE_DEPOSIT_CONTROLLER", predictedAddress);

        // ============================================
        // ====== Deploy RewardHandler ================
        // ============================================
        constructorArgs = abi.encode(
            address(core),
            address(insurancePool), 
            address(debtReceiver),
            address(pairEmissionStream),
            address(ipEmissionStream),
            address(ipStableStream)
        );
        bytecode = abi.encodePacked(vm.getCode("RewardHandler.sol:RewardHandler"), constructorArgs);
        salt = buildGuardedSalt(
            dev, 
            true,   // enablePermissionedDeploy
            false,  // enableCrossChain Protection
            uint88(uint256(keccak256(bytes("RewardHandler"))))
        );
        predictedAddress = computeCreate3AddressFromSaltPreimage(salt, dev, true, false);
        if (!addressHasCode(predictedAddress)) {
            addToBatch(
                address(createXFactory),
                encodeCREATE3Deployment(salt, bytecode)
            );
        }
        rewardHandler = RewardHandler(predictedAddress);
        console.log("RewardHandler deployed at", address(rewardHandler));
        writeAddressToJson("REWARD_HANDLER", predictedAddress);
    }

    function deployLendingPair(address _collateral, address _staking, uint256 _stakingId) public returns(address){
        require(address(pairDeployer).code.length > 0, "ResupplyPairDeployer has no code");
        bytes memory result;
        result = _executeCore(
            address(pairDeployer),
            abi.encodeWithSelector(ResupplyPairDeployer.deploy.selector,
                abi.encode(
                    _collateral,
                    address(oracle),
                    address(rateCalculator),
                    DEFAULT_MAX_LTV, //max ltv 75%
                    DEFAULT_BORROW_LIMIT,
                    DEFAULT_LIQ_FEE,
                    DEFAULT_MINT_FEE,
                    DEFAULT_PROTOCOL_REDEMPTION_FEE
                ),
                _staking,
                _stakingId
            )
        );
        result = abi.decode(result, (bytes)); // our result was double encoded, so we decode it once
        address pair = abi.decode(result, (address));
        _executeCore(
            address(registry),
            abi.encodeWithSelector(ResupplyRegistry.addPair.selector, pair)
        );
        return pair;
    }
}
