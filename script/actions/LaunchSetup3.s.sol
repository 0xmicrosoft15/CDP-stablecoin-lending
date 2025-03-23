import { BaseAction } from "script/actions/dependencies/BaseAction.sol";
import { Protocol } from "script/protocol/ProtocolConstants.sol";
import { Guardian } from "src/dao/operators/Guardian.sol";
import { ITreasuryManager } from "src/interfaces/ITreasuryManager.sol";
import { ITreasury } from "src/interfaces/ITreasury.sol";
import { IVoter } from "src/interfaces/IVoter.sol";
import { IGuardian } from "src/interfaces/IGuardian.sol";
import { IResupplyRegistry } from "src/interfaces/IResupplyRegistry.sol";
import { TenderlyHelper } from "script/utils/TenderlyHelper.sol";
import { CreateXHelper } from "script/utils/CreateXHelper.sol";
import { CreateX } from "script/deploy/dependencies/DeploymentConfig.sol";
import { IPrismaCore } from "src/interfaces/IPrismaCore.sol";
import { IResupplyPair } from "src/interfaces/IResupplyPair.sol";

contract LaunchSetup3 is TenderlyHelper, CreateXHelper, BaseAction {
    address public constant deployer = Protocol.DEPLOYER;
    address public guardian;
    address public treasuryManager;
    address public rsup = 0x419905009e4656fdC02418C7Df35B1E61Ed5F726;
    
    function run() public isBatch(deployer) {
        deployMode = DeployMode.FORK;
        address grantRecipient = 0xf39Ed30Cc51b65392911fEA9F33Ec1ccceEe1ed5;
        uint256 grantAmount = 1_000e18;

        transferGrant(grantRecipient, grantAmount);
        deployGuardianAndConfigure();
        deployTreasuryManagerAndConfigure();
        acceptPrismaGovernance();
        
        if (deployMode == DeployMode.PRODUCTION) executeBatch(true);
    }

    function transferGrant(address _recipient, uint256 _amount) public {
        _executeCore(
            Protocol.TREASURY,
            abi.encodeWithSelector(
                ITreasury.retrieveTokenExact.selector, 
                rsup,
                _recipient,
                _amount
            )
        );
    }

    function deployGuardianAndConfigure() public {
        // 1 Deploy Guardian
        // 2 Set permissions
        // 3 Set guardian role
        bytes32 salt = CreateX.SALT_OPERATOR_GUARDIAN;
        bytes memory constructorArgs = abi.encode(
            Protocol.CORE,
            Protocol.TREASURY
        );
        bytes memory bytecode = vm.getCode("Guardian.sol:Guardian");
        addToBatch(
            address(createXFactory),
            encodeCREATE3Deployment(salt, bytecode)
        );
        guardian = computeCreate3AddressFromSaltPreimage(salt, deployer, true, false);
        require(guardian.code.length > 0, "deployment failed");
        
        setGuardianPermissions(deployer, false);
        setGuardianPermissions(guardian, true);

        // Set guardian
        _executeCore(
            guardian,
            abi.encodeWithSelector(
                IGuardian.setGuardian.selector,
                deployer
            )
        );
        require(IGuardian(guardian).guardian() == deployer, "Guardian guardian not set");
    }

    function deployTreasuryManagerAndConfigure() public {
        // 1 Deploy TreasuryManager
        // 2 Set permissions
        // 3 Set treasury manager role
        bytes32 salt = CreateX.SALT_OPERATOR_TREASURY_MANAGER;
        bytes memory constructorArgs = abi.encode(
            Protocol.CORE,
            Protocol.TREASURY
        );
        bytes memory bytecode = abi.encodePacked(vm.getCode("TreasuryManager.sol:TreasuryManager"), constructorArgs);
        addToBatch(
            address(createXFactory),
            encodeCREATE3Deployment(salt, bytecode)
        );
        address treasuryManager = computeCreate3AddressFromSaltPreimage(salt, deployer, true, false);
        require(treasuryManager.code.length > 0, "deployment failed");
        
        setTreasuryManagerPermissions(deployer, false); // revoke deployer permissions
        setTreasuryManagerPermissions(treasuryManager, true); // grant permissions to treasury manager operator

        // Set manager
        _executeCore(
            treasuryManager,
            abi.encodeWithSelector(
                ITreasuryManager.setManager.selector,
                deployer
            )
        );
        require(ITreasuryManager(treasuryManager).manager() == deployer, "TreasuryManager manager not set");
    }

    function setTreasuryManagerPermissions(address _caller, bool _approve) internal {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = ITreasury.retrieveToken.selector;
        selectors[1] = ITreasury.retrieveTokenExact.selector;
        selectors[2] = ITreasury.retrieveETH.selector;
        selectors[3] = ITreasury.retrieveETHExact.selector;
        selectors[4] = ITreasury.setTokenApproval.selector;
        selectors[5] = ITreasury.execute.selector;
        selectors[6] = ITreasury.safeExecute.selector;
        for (uint256 i = 0; i < selectors.length; i++) {
            setCorePermissions(
                selectors[i],
                _caller,
                Protocol.TREASURY,
                _approve,
                address(0)
            );
        }
    }

    function setGuardianPermissions(address _caller, bool _approve) internal {
        // Pause pairs (any address)
        if (_approve) {
            setCorePermissions(
                IResupplyPair.pause.selector,
                _caller,
                address(0),
                _approve,
                address(0)
            );
        }
        // Cancel proposals
        setCorePermissions(
            IVoter.cancelProposal.selector,
            _caller,
            Protocol.VOTER,
            _approve,
            address(0)
        );
        setCorePermissions(
            IResupplyRegistry.setAddress.selector,
            _caller,
            Protocol.REGISTRY,
            _approve,
            address(0)
        );
    }

    function acceptPrismaGovernance() public {
        IPrismaCore prismaCore = IPrismaCore(0x5d17eA085F2FF5da3e6979D5d26F1dBaB664ccf8);
        _executeCore(
            address(prismaCore),
            abi.encodeWithSelector(
                IPrismaCore.acceptTransferOwnership.selector
            )
        );
        require(prismaCore.owner() == core, "PrismaCore owner not set");
    }
}