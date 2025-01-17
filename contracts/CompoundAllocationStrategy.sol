pragma solidity ^0.5.8;

import {IAllocationStrategy} from "./IAllocationStrategy.sol";
import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {CErc20Interface} from "../compound/contracts/CErc20Interface.sol";

contract CompoundAllocationStrategy is IAllocationStrategy {

    CErc20Interface cToken;
    IERC20 token;

    constructor(CErc20Interface cToken_) public {
        cToken = cToken_;
        token = IERC20(cToken.underlying());
    }

    /// @dev ISavingStrategy.underlying implementation
    function underlying() external view returns (address) {
        return cToken.underlying();
    }

    /// @dev ISavingStrategy.exchangeRateStored implementation
    function exchangeRateStored() external view returns (uint256) {
        return cToken.exchangeRateStored();
    }

    /// @dev ISavingStrategy.accrueInterest implementation
    function accrueInterest() external returns (bool) {
        return cToken.accrueInterest() == 0;
    }

    /// @dev ISavingStrategy.investUnderlying implementation
    function investUnderlying(uint256 investAmount) external returns (uint256) {
        token.transferFrom(msg.sender, address(this), investAmount);
        token.approve(address(cToken), investAmount);
        uint256 cTotalBefore = cToken.totalSupply();
        // TODO should we handle mint failure?
        require(cToken.mint(investAmount) == 0, "mint failed");
        uint256 cTotalAfter = cToken.totalSupply();
        uint256 cCreatedAmount;
        if (cTotalAfter > cTotalBefore) {
            cCreatedAmount = cTotalAfter - cTotalBefore;
        } // else can there be case that we mint but we get less cTokens!?\
        return cCreatedAmount;
    }

    /// @dev ISavingStrategy.redeemUnderlying implementation
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
        uint256 cTotalBefore = cToken.totalSupply();
        // TODO should we handle redeem failure?
        require(cToken.redeemUnderlying(redeemAmount) == 0, "redeemUnderlying failed");
        uint256 cTotalAfter = cToken.totalSupply();
        uint256 cBurnedAmount;
        if (cTotalAfter < cTotalBefore) {
            cBurnedAmount = cTotalBefore - cTotalAfter;
        } // else can there be case that we end up with more cTokens ?!
        token.transfer(msg.sender, redeemAmount);
        return cBurnedAmount;
    }

}
