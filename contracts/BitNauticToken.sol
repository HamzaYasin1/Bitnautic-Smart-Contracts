pragma solidity ^0.4.11;
/**
 * @title BitNauticToken
 * @author Junaid Mushtaq || Hamza Yasin || Talha Yusuf
 */
import '../contracts/token/MintableToken.sol';


contract BitNauticToken is MintableToken {

  string public constant name = "BitNautic Token";
  string public constant symbol = "BTNT";
  uint8 public constant decimals = 18;
  uint256 public constant totalSupply = SafeMath.mul(50000000 , 1 ether);
  

}


