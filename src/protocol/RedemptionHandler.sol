// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CoreOwnable } from '../dependencies/CoreOwnable.sol';
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";
import { IResupplyPair } from "../interfaces/IResupplyPair.sol";
import { IResupplyRegistry } from "../interfaces/IResupplyRegistry.sol";
import { IERC4626 } from "../interfaces/IERC4626.sol";
import { IMintable } from "../interfaces/IMintable.sol";

//Contract that interacts with pairs to perform redemptions
//Can swap out this contract for another to change logic on how redemption fees are calculated.
//for example can give fee discounts based on certain conditions (like utilization) to
//incentivize redemptions across multiple pools etc
contract RedemptionHandler is CoreOwnable{
    using SafeERC20 for IERC20;

    address public immutable registry;
    address public immutable debtToken;

    uint256 public baseRedemptionFee = 1e16; //1%
    uint256 public constant PRECISION = 1e18;

    struct RedeemptionRateInfo {
        uint64 timestamp;  //time since last update
        uint192 usage;  //usage weight, defined by % of pair redeemed. thus a pair redeemed for 2% three times will have a weight of 6
    }
    mapping(address => RedeemptionRateInfo) public ratingData;
    uint256 public usageDecayRate = 1e17 / uint256(7 days); //10% per week
    uint256 public maxUsage = 3e17; //max usage of 30%. any thing above 30% will be 0 discount.  linearly scale between 0 and maxusage
    uint256 public maxDiscount = 1e15; //up to 0.1% discount

    event SetBaseRedemptionFee(uint256 _fee);

    constructor(address _core, address _registry) CoreOwnable(_core){
        registry = _registry;
        debtToken = IResupplyRegistry(_registry).token();
    }

    /// @notice Sets the base redemption fee.
    /// @dev This fee is not the effective fee. The effective fee is calculated at time of redemption via ``getRedemptionFeePct``.
    /// @param _fee The new base redemption fee, must be <= 1e18 (100%)
    function setBaseRedemptionFee(uint256 _fee) external onlyOwner{
        require(_fee <= 1e18, "!fee");
        baseRedemptionFee = _fee;
        emit SetBaseRedemptionFee(_fee);
    }

    /// @notice Estimates the maximum amount of debt that can be redeemed from a pair
    function getMaxRedeemableDebt(address _pair) external view returns(uint256){
        (,,,IResupplyPair.VaultAccount memory _totalBorrow) = IResupplyPair(_pair).previewAddInterest();
        uint256 minLeftoverDebt = IResupplyPair(_pair).minimumLeftoverDebt();
        if (_totalBorrow.amount < minLeftoverDebt) return 0;

        uint256 redeemableDebt = _totalBorrow.amount - minLeftoverDebt;
        uint256 minimumRedemption = IResupplyPair(_pair).minimumRedemption();

        if(redeemableDebt < minimumRedemption){
            return 0;
        }

        return redeemableDebt;
    }

    /// @notice Calculates the total redemption fee as a percentage of the redemption amount.
    function getRedemptionFeePct(address _pair, uint256 _amount) public view returns(uint256){
        //get fee
        (uint256 feePct,) = _getRedemptionFee(_pair, _amount);
        return feePct;
    }

    function _getRedemptionFee(address _pair, uint256 _amount) internal view returns(uint256, RedeemptionRateInfo memory){
        (, , , IResupplyPair.VaultAccount memory _totalBorrow) = IResupplyPair(_pair).previewAddInterest();
        
        //determine the weight of this current redemption by dividing by pair's total borrow
        uint256 weightOfRedeem = _amount * 1e18 / _totalBorrow.amount;

        //update current data with decay rate
        RedeemptionRateInfo memory rdata = ratingData[_pair];
        
        //only decay if this pair has been used before
        if(rdata.timestamp != 0){
            //reduce useage by time difference since last redemption
            uint192 decay = uint192((block.timestamp - rdata.timestamp) * usageDecayRate);
            //set the pair's usage or weight
            rdata.usage = rdata.usage < decay ? 0 : rdata.usage - decay;
        }
        //update timestamp
        rdata.timestamp = uint64(block.timestamp);
        
        //use halfway point as the current weight for fee calc
        //using pre weight would have high discount, using post weight would have low discount
        //just use the half way point by using current + half the newly added weight
        uint256 halfway = rdata.usage + (weightOfRedeem/2);
        
        //add new weight to the struct
        rdata.usage += uint192(weightOfRedeem);
        
        // //write to state
        // ratingData[_pair] = rdata;

        //calculate the discount and final fee (base fee minus discount)
        uint256 _maxusage = maxUsage;
        
        //first get how close we are to _maxusage by taking difference.
        //if halfway is >= to _maxusage then discount is 0.
        //if halfway is == to 0 then discount equals our max usage
        uint256 discount = _maxusage > halfway ? _maxusage - halfway : 0;
        
        //convert the above value to a percentage with precision 1e18
        //if halfway is 8 units of usage then discount is 2 (10-8)
        //thus below should convert to 20%  (2 is 20% of the max usage 10)
        discount = (discount * 1e18 / _maxusage); //discount is now a 1e18 percision % 
        
        //take above percentage of maxDiscount as our final discount
        //above example is 20% so a 0.2 max discount * 20% will be 0.04 discount (2e15 * 20% = 4e14)
        discount = (maxDiscount * discount / 1e18);// get % of maxDiscount
        
        //remove from base fee the discount and return
        //above example will be 1.0 - 0.04 = 0.96% fee (1e16 - 4e14)
        return (baseRedemptionFee - discount, rdata);
    }


    /// @notice Redeem stablecoins for collateral from a pair
    /// @param _pair The address of the pair to redeem from
    /// @param _amount The amount of stablecoins to redeem
    /// @param _maxFeePct The maximum fee pct (in 1e18) that the caller will accept
    /// @param _receiver The address that will receive the withdrawn collateral
    /// @param _redeemToUnderlying Whether to unwrap the collateral to the underlying asset
    /// @return _ amount received of either collateral shares or underlying, depending on `_redeemToUnderlying`
    function redeemFromPair (
        address _pair,
        uint256 _amount,
        uint256 _maxFeePct,
        address _receiver,
        bool _redeemToUnderlying
    ) external returns(uint256){
        //get fee
        (uint256 feePct, RedeemptionRateInfo memory rdata) = _getRedemptionFee(_pair, _amount);
        //write to state
        ratingData[_pair] = rdata;
        //check against maxfee to avoid frontrun
        require(feePct <= _maxFeePct, "fee > maxFee");

        address returnToAddress = address(this);
        if(!_redeemToUnderlying){
            //if directly redeeming lending collateral, send directly to receiver
            returnToAddress = _receiver;
        }
        (address _collateral, uint256 _returnedCollateral) = IResupplyPair(_pair).redeemCollateral(
            msg.sender,
            _amount,
            feePct,
            returnToAddress
        );

        IMintable(debtToken).burn(msg.sender, _amount);

        //withdraw to underlying
        //if false receiver will have already received during redeemCollateral()
        //unwrap only if true
        if(_redeemToUnderlying){
            return IERC4626(_collateral).redeem(_returnedCollateral, _receiver, address(this));
        }
        
        return _returnedCollateral;
    }

}