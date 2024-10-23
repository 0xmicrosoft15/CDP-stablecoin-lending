// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IOracle {
    function decimals() external view returns (uint8);

    function getPrices(address _vault) external view returns (uint256 _price);

    function name() external view returns (string memory);
}
