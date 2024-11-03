// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IGovStaker } from "../../interfaces/IGovStaker.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract SubDao is Ownable2Step {

    address public immutable core;
    bool public unstakingAllowed;
    string public name;
    IGovStaker public staker;
    IERC20 public govToken;

    event UnstakingAllowed(bool indexed allowed);

    modifier noUnstaking {
        bool shouldCheck = !unstakingAllowed;
        uint256 pre;
        if (shouldCheck) {
            pre = staker.balanceOf(address(this));
        }
        _;
        if (shouldCheck) {
            require(
                staker.balanceOf(address(this)) >= pre, 
                "UnstakingForbidden"
            );
        }
    }

    constructor(address _core, address _owner, address _staker, string memory _name) {
        core = _core;
        name = _name;
        staker = IGovStaker(_staker);
        govToken = IERC20(staker.stakeToken());
        govToken.approve(address(staker), type(uint256).max);
        _transferOwnership(_owner);
    }

    function execute(address target, bytes calldata data) external returns (bool, bytes memory) {
        return _execute(target, data);
    }

    function safeExecute(address target, bytes calldata data) external returns (bytes memory) {
        (bool success, bytes memory result) = _execute(target, data);
        require(success, "CallFailed");
        return result;
    }

    function _execute(address target, bytes calldata data) internal onlyOwner noUnstaking returns (bool success, bytes memory result) {
        require(target != address(0), "Invalid target address");
        (success, result) = target.call(data);
    }

    function allowUnstaking(bool _allowed) external onlyOwner {
        require(msg.sender == core, "!core");
        unstakingAllowed = _allowed;
        emit UnstakingAllowed(_allowed);
    }

    function stake(address account, uint256 amount) external onlyOwner {
        staker.stake(account, amount);
    }

    function stake() external onlyOwner {
        staker.stake(address(this), govToken.balanceOf(address(this)));
    }
}
