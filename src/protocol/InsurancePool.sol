// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";
import { IERC4626 } from "../interfaces/IERC4626.sol";
import { IMintable } from "../interfaces/IMintable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { RewardDistributorMultiEpoch } from "./RewardDistributorMultiEpoch.sol";
import { IResupplyRegistry } from "../interfaces/IResupplyRegistry.sol";
import { CoreOwnable } from '../dependencies/CoreOwnable.sol';


contract InsurancePool is RewardDistributorMultiEpoch, CoreOwnable{
    using SafeERC20 for IERC20;

    address immutable public depositToken;
    address immutable public registry;
    
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 constant public shareRefactor = 1e18;

    uint256 public withdrawTime = 7 days;
    uint256 public withdrawTimeLimit = 1 days;
    mapping(address => uint256) withdrawQueue;

    //events
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 share
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Cooldown(address indexed account, uint amount, uint end);
    event WithdrawTimers(uint256 withdrawTime, uint256 withdrawWindow);

    constructor(address _core, address _depositToken, address[] memory _rewards, address _registry) CoreOwnable(_core){
        depositToken = _depositToken;
        registry = _registry;

        //initialize rewards list with passed in reward tokens
        //NOTE: slot 0 should be emission based extra reward
        for(uint256 i = 0; i < _rewards.length;){
            _insertRewardToken(_rewards[i]);
            unchecked { i += 1; }
        }
        

        //mint unbacked shares to this address
        //deployment should send the outstanding amount
        _mint(address(this), 1e18);
    }

    function setWithdrawTimers(uint256 _withdrawLength, uint256 _withdrawWindow) external onlyOwner{
        require(_withdrawLength <= 14 days, "too high");
        withdrawTime = _withdrawLength;
        withdrawTimeLimit = _withdrawWindow;
        emit WithdrawTimers(_withdrawLength, _withdrawWindow);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    // ============================================================================================
    // Reward Implementation
    // ============================================================================================

    function _isRewardManager() internal view override returns(bool){
        return msg.sender == registry || msg.sender == owner()
        || msg.sender == IResupplyRegistry(registry).rewardHandler();
    }

    function _claimPoolRewards() internal override{
        IResupplyRegistry(registry).claimInsuranceRewards();
    }

    function _totalRewardShares() internal view override returns(uint256){
        return _totalSupply;
    }

    function _userRewardShares(address _account) internal view override returns(uint256){
        return _balances[_account];
    }

    function _increaseUserRewardEpoch(address _account, uint256 _currentUserEpoch) internal override{
        //convert shares to next epoch shares
        //share refactoring will never be 0
        _balances[_account] = _balances[_account] / shareRefactor;
        //update user reward epoch
        userRewardEpoch[_account] = _currentUserEpoch + 1;
    }

    function _checkAddToken(address _address) internal view override returns(bool){
        if(_address == depositToken) return false;
        return true;
    }

    //we cant limit reward types since collaterals could be sent as rewards
    //however reward lists growing too large is undesirable
    //governance should act if too many are added
    function maxRewards() public override returns(uint256){
        return type(uint256).max;
    }


    // ============================================================================================


    // ===============================================================================
    //  Insurance pool methods
    // ===============================================================================

    //burn underlying, liquidationHandler will send rewards in exchange
    function burnAssets(uint256 _amount) external{
        require(msg.sender == IResupplyRegistry(registry).liquidationHandler(), "!liq handler");

        IMintable(depositToken).burn(address(this), _amount);

        //if after many burns the amount to shares ratio has deteriorated too far, then refactor
        if(totalAssets() * shareRefactor < _totalSupply){
            _increaseRewardEpoch(); //will do final checkpoint on previous total supply
            _totalSupply /= shareRefactor;
        }
    }

    // ===============================================================================


    // ===============================================================================
    //  deposit/withdraw
    // ===============================================================================

    function deposit(uint256 _assets, address _receiver) external returns (uint256 shares){

         if (_assets > 0) {
            shares = previewDeposit(_assets);
            if(shares > 0){
                _mint(_receiver, shares);
                IERC20(depositToken).safeTransferFrom(msg.sender, address(this), _assets);
                emit Deposit(msg.sender, _receiver, _assets, shares);
            }
        }
    }

    function mint(uint256 _shares, address _receiver) external returns (uint256 assets){

        if (_shares > 0) {
            assets = previewMint(_shares);
            if(assets > 0){
                _mint(_receiver, _shares);
                IERC20(depositToken).safeTransferFrom(msg.sender, address(this), assets);
                emit Deposit(msg.sender, _receiver, assets, _shares);
            }
        }
    }

    function exit() external{
        uint256 exitTime = block.timestamp + withdrawTime;
        withdrawQueue[msg.sender] = exitTime;

        //claim all rewards now because reward0 will be excluded during
        //the withdraw sequence
        getReward(msg.sender);

        emit Cooldown(msg.sender, balanceOf(msg.sender), exitTime);
    }

    function cancelExit() external{
        _clearWithdrawQueue(msg.sender);
    }

    function _clearWithdrawQueue(address _account) internal{
        _checkpoint(_account);
        //get reward 0 info
        RewardType storage reward = rewards[0];
        //note how much is claimable
        uint256 reward0 = claimable_reward[reward.reward_token][_account];
        //reset claimable
        claimable_reward[reward.reward_token][_account] = 0;
        //redistribute back to pool
        reward.reward_remaining -= reward0;

        withdrawQueue[msg.sender] = 0; //flag as not waiting for withdraw
    }

    function _checkWithdrawReady(address _account) internal{
        require(withdrawQueue[msg.sender] <= block.timestamp, "!withdraw time");
        require(block.timestamp <= withdrawQueue[msg.sender] + withdrawTimeLimit, "withdraw time over");
    }

    function redeem(uint256 _shares, address _receiver, address _owner) public returns (uint256 assets){
        _checkWithdrawReady(msg.sender);
        //note: ignore _owner
        if (_shares > 0) {
            _clearWithdrawQueue(msg.sender);
            
            assets = previewRedeem(_shares);
            require(assets != 0, "ZERO_ASSETS");
            _burn(msg.sender, _shares);
            IERC20(depositToken).safeTransfer(_receiver, assets);
            emit Withdraw(msg.sender, _receiver, msg.sender, _shares, assets);
        }
    }

    function withdraw(uint256 _amount, address _receiver, address _owner) public returns(uint256 shares){
        _checkWithdrawReady(msg.sender);
        //note: ignore _owner
        if (_amount > 0) {
            _clearWithdrawQueue(msg.sender);
            shares = previewWithdraw(_amount);
            _burn(msg.sender, shares);
            IERC20(depositToken).safeTransfer(_receiver, _amount);
            emit Withdraw(msg.sender, _receiver, msg.sender, shares, _amount);
        }
    }

    function getReward(address _account) public override {
        require(withdrawQueue[_account] == 0, "claim while queued");
        super.getReward(_account);
    }

    function getReward(address _account, address _forwardTo) public override {
        require(withdrawQueue[_account] == 0, "claim while queued");
        super.getReward(_account,_forwardTo);
    }

    function earned(address _account) public override returns(EarnedData[] memory claimable) {
        claimable = super.earned(_account);
        if(withdrawQueue[_account] > 0){
            claimable[0].amount = 0;
        }
    }

    //erc4626
    function asset() external view returns(address){
        return depositToken;
    }

    function totalAssets() public view returns(uint256 assets){
        assets = IERC20(depositToken).balanceOf(address(this));
    }

    function convertToShares(uint256 _assets) public view returns (uint256 shares){
        if (totalSupply() == 0) {
            shares = _assets;
        } else {
            shares = _assets * totalSupply() / totalAssets();
        }
    }

    function convertToAssets(uint256 _shares) public view returns (uint256 assets){
        if(totalSupply() > 0){
            assets = totalAssets() * _shares / totalSupply();
        }else{
            assets = _shares;
        }
    }

    function convertToSharesRoundUp(uint256 _assets) internal view returns (uint256 shares){
        if (totalSupply() == 0) {
            shares = _assets;
        } else {
            shares = _assets * totalSupply() / totalAssets();
            if ( shares * totalAssets() / totalSupply() < _assets) {
                shares = shares+1;
            }
        }
    }

    function convertToAssetsRoundUp(uint256 _shares) internal view returns (uint256 assets){
        if(totalSupply() > 0){
            assets = totalAssets() * _shares / totalSupply();
            if ( assets * totalSupply() / totalAssets() < _shares) {
                assets = assets+1;
            }
        }else{
            assets = _shares;
        }
    }

    function maxDeposit(address /*_receiver*/) external pure returns (uint256){
        return type(uint256).max;
    }
    function maxMint(address /*_receiver*/) external pure returns (uint256){
        return type(uint256).max;
    }
    function previewDeposit(uint256 _amount) public view returns (uint256){
        return convertToShares(_amount);
    }
    function previewMint(uint256 _shares) public view returns (uint256){
        return convertToAssetsRoundUp(_shares); //round up
    }
    function maxWithdraw(address _owner) external view returns (uint256){
        return convertToAssets(balanceOf(_owner));
    }
    function previewWithdraw(uint256 _amount) public view returns (uint256){
        return convertToSharesRoundUp(_amount); //round up
    }
    function maxRedeem(address _owner) external view returns (uint256){
        return balanceOf(_owner);
    }
    function previewRedeem(uint256 _shares) public view returns (uint256){
        return convertToAssets(_shares);
    }

}