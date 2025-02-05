import "src/Constants.sol" as Constants;
import { console } from "forge-std/console.sol";
import { DeployResupplyDao } from "./DeployResupplyDao.s.sol";
import { DeployResupplyProtocol } from "./DeployResupplyProtocol.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGovStaker } from "src/interfaces/IGovStaker.sol";
import { ResupplyPair } from "src/protocol/ResupplyPair.sol";
import { ResupplyPairDeployer } from "src/protocol/ResupplyPairDeployer.sol";
import { ResupplyRegistry } from "src/protocol/ResupplyRegistry.sol";
import { SimpleReceiver } from "src/dao/emissions/receivers/SimpleReceiver.sol";
import { ICore } from "src/interfaces/ICore.sol";
import { Stablecoin } from "src/protocol/Stablecoin.sol";

contract DeployResupply is DeployResupplyDao, DeployResupplyProtocol {

    function run() public {
        setEthBalance(dev, 10 ether);
        deployDaoContracts(dev, true); // true for testnet
        deployProtocolContracts(dev);
        configurationStep1(dev);
        deployRewardsContracts(dev);
        configureProtocolContracts(dev);
        (permaStaker1, permaStaker2) = deployPermaStakers(dev);
        deployDefaultLendingPairs(dev);
        handoffGovernance(dev);
    }

    function deployDefaultLendingPairs(address _sender) public {
        address pair;
        pair = deployLendingPair(_sender, address(Constants.Mainnet.FRAXLEND_SFRXETH_FRAX), address(0), 0);
        pair = deployLendingPair(_sender, address(Constants.Mainnet.CURVELEND_SFRAX_CRVUSD), address(Constants.Mainnet.CONVEX_BOOSTER), uint256(Constants.Mainnet.CURVELEND_SFRAX_CRVUSD_ID));
    }

    function configurationStep1(address _sender) public doBroadcast(_sender) {
        ICore _core = ICore(core);
        _core.execute(address(pairDeployer), abi.encodeWithSelector(ResupplyPairDeployer.setCreationCode.selector, type(ResupplyPair).creationCode));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setVestManager.selector, address(vestManager)));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setTreasury.selector, address(treasury)));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setStaker.selector, address(staker)));
    }

    function configureProtocolContracts(address _sender) public doBroadcast(_sender) {
        ICore _core = ICore(core);
        _core.execute(address(feeDeposit), abi.encodeWithSelector(feeDeposit.setOperator.selector, address(feeDepositController)));
        _core.execute(address(staker), abi.encodeWithSelector(IGovStaker.addReward.selector, address(stablecoin), address(rewardHandler), uint256(7 days)));
        _core.execute(address(debtReceiver), abi.encodeWithSelector(SimpleReceiver.setApprovedClaimer.selector, address(rewardHandler), true));
        _core.execute(address(insuranceEmissionsReceiver), abi.encodeWithSelector(SimpleReceiver.setApprovedClaimer.selector, address(rewardHandler), true));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setRedemptionHandler.selector, address(redemptionHandler)));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setLiquidationHandler.selector, address(liquidationHandler)));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setInsurancePool.selector, address(insurancePool)));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setFeeDeposit.selector, address(feeDeposit)));
        _core.execute(address(registry), abi.encodeWithSelector(ResupplyRegistry.setRewardHandler.selector, address(rewardHandler)));
        _core.execute(address(stablecoin), abi.encodeWithSelector(Stablecoin.setOperator.selector, address(registry), true));
    }

    function handoffGovernance(address _sender) public doBroadcast(_sender) {
        ICore _core = ICore(core);
        _core.execute(address(core), abi.encodeWithSelector(ICore.setVoter.selector, address(voter)));
    }

    function isForkedNetwork() public view returns (bool) {
        try vm.activeFork() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }
}
