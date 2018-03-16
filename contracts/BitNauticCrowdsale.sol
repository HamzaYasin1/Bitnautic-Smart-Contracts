pragma solidity ^0.4.13;

/**
 * @titleBitNauticICO
 * @author Junaid Mushtaq || Hamza Yasin || Talha Yusuf
 * @dev BitNauticCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them BNE tokens based
 * on a BNE token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */

import '../contracts/crowdsale/Crowdsale.sol';
import '../contracts/crowdsale/CappedCrowdsale.sol';
import '../contracts/crowdsale/RefundableCrowdsale.sol';
import '../contracts/BitNauticToken.sol';


contract BitNauticCrowdsale is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
    /** Constructor BitNauticICO */
    function BitNauticCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet)
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
    }

    /**BitNauticToken Contract is generating from here */
    function createTokenContract() internal returns (MintableToken) {
        return new BitNauticToken();
    }
}