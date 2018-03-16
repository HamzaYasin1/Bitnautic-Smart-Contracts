pragma solidity ^0.4.11;

import '../token/MintableToken.sol';
import '../SafeMath.sol';
import '../Ownable.sol';
import '../Pausable.sol';
/**
 * @title BitNautic Crowdsale
 * @author Junaid Mushtaq || Hamza Yasin || Talha Yusuf
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;

  // The token being sold
  MintableToken private token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
  // Bonuses will be calculated here of ICO and Pre-ICO (both inclusive)
  uint public preICOBonus;
  uint public firstWeekBonus;
  uint public secondWeekBonus;
  uint public thirdWeekBonus;
  uint public forthWeekBonus;
  
  
  // wallet address where funds will be saved
  address internal wallet;
  
  // base-rate of a particular BitNautic token
  uint public rate;

  // amount of raised money in wei
  uint256 public weiRaised; // internal

  // Weeks in UTC
  uint weekOne;
  uint weekTwo;
  uint weekThree;
  uint weekForth;
  
  // total supply of token 
  uint256 public totalSupply = SafeMath.mul(50000000, 1 ether);
  // Public Supply
  uint256 public publicSupply = SafeMath.mul(35000000, 1 ether);
  // preICO supply of token 
  uint256 public preicoSupply = SafeMath.sub(publicSupply,25000000);                       
  // ICO supply of token 
  uint256 public icoSupply = SafeMath.sub(publicSupply,10000000);
  // Team supply of token 
  uint256 public teamSupply = SafeMath.mul(SafeMath.div(totalSupply,100),6);
  // bounty supply of token 
  uint256 public bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
  // reserve supply of token 
  uint256 public reserveSupply = SafeMath.mul(SafeMath.div(totalSupply,100),10);
  // advisor supply of token 
  uint256 public advisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
  // founder supply of token 
  uint256 public founderSupply = SafeMath.mul(SafeMath.div(totalSupply,100),4);
  
  // Time lock or vested period of token for team allocated token
  uint256 public teamTimeLock;
  // Time lock or vested period of token for Advisor allocated token
  uint256 public advisorTimeLock;
  // Time lock or vested period of token for reserve allocated token
  uint256 public reserveTimeLock;

  uint public teamCounter = 0;
  /**
   *  @bool checkBurnTokens
   *  @bool upgradeICOSupply
   *  @bool grantTeamSupply
   *  @bool grantAdvisorSupply     
  */
  bool public checkBurnTokens;
  bool public upgradeICOSupply;
  bool public grantTeamSupply;
  bool public grantAdvisorSupply;
  bool public grantReserveSupply;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // BitNautic Crowdsale constructor
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    // BitNautic token creation 
    token = createTokenContract();

    // Pre-ICO start Time
    preStartTime = _startTime;
    
    // Pre-ICO end time
     preEndTime = preStartTime + 15 days;

    // // ICO start Time
     ICOstartTime = preEndTime + 2 days;

    // ICO end Time
    ICOEndTime = _endTime;

    // Base Rate of BTNT Token
    rate = _rate;

    // Multi-sig wallet where funds will be saved
    wallet = _wallet;

    /** Calculations of Bonuses in ICO or Pre-ICO */
    preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);

    /** ICO bonuses week calculations */
    weekOne = SafeMath.add(ICOstartTime, 1 weeks);
    weekTwo = SafeMath.add(weekOne, 1 weeks);
    weekThree = SafeMath.add(weekTwo, 1 weeks);
    weekForth = SafeMath.add(weekThree, 1 weeks);

    /** Vested Period calculations for team and advisors*/
    teamTimeLock = SafeMath.add(ICOEndTime, 365 days);
    advisorTimeLock = SafeMath.add(ICOEndTime, 365 days);
    reserveTimeLock = SafeMath.add(ICOEndTime, 365 days);

    checkBurnTokens = false;
    upgradeICOSupply = false;
    grantAdvisorSupply = false;
    grantTeamSupply = false;
    grantAdvisorSupply = false;
    grantReserveSupply = false;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
    
  }

  // High level token purchase function
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    // minimum investment should be 0.05 ETH
    require((weiAmount >= (0.05 * 1 ether)) && (weiAmount <= (50 * 1 ether)));
    
    uint256 accessTime = now;
    uint256 tokens = 0;

  // calculating the crowdsale and Pre-crowdsale bonuses on the basis of timing
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) {
        require(preicoSupply > 0);

        tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        
        require(preicoSupply >= tokens);
        
        preicoSupply = preicoSupply.sub(tokens);        
        publicSupply = publicSupply.sub(tokens);

    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
        if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        if ( accessTime <= weekOne ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwo) {
          tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
        } else if ( accessTime <= weekThree ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
        } else if ( accessTime <= weekForth ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        
        publicSupply = publicSupply.sub(tokens);
    } else if ((accessTime > preEndTime) && (accessTime < ICOstartTime)) {
      revert();
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);
    // tokens are minting here
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    // funds are forwarding
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }

  function burnToken() onlyOwner  public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    token.burnTokens(icoSupply);
    totalSupply = SafeMath.sub(totalSupply, icoSupply);
    publicSupply = 0;
    preicoSupply = 0;
    icoSupply = 0;
    checkBurnTokens = true;

    return true;
  }

 function bountyDrop( address[] recipients, uint256[] values) onlyOwner public {
    for (uint256 i = 0; i < recipients.length; i++) {
      values[i] = SafeMath.mul(values[i], 1 ether);
      require(bountySupply >= values[i]);
      bountySupply = SafeMath.sub(bountySupply,values[i]);
  
      token.mint(recipients[i], values[i]);
    }
  }

  function grantAdvisorToken(address beneficiary ) onlyOwner  public {
    require((!grantAdvisorSupply) && (now > advisorTimeLock));
    grantAdvisorSupply = true;
    token.mint(beneficiary, advisorSupply);
    advisorSupply = 0;
  }

  function grantTeamAndFounderToken(address teamAddress, address founderAddress) onlyOwner  public {
        require((teamCounter < 2) && (teamTimeLock < now));
        teamTimeLock = SafeMath.add(teamTimeLock, 5 minutes);
        token.mint(teamAddress,SafeMath.div(teamSupply, 2));
        token.mint(founderAddress,SafeMath.div(founderSupply, 2));
        teamCounter = SafeMath.add(teamCounter, 1);        
    }

    function grantReserveToken(address beneficiary) onlyOwner  public {
    require((!grantReserveSupply) && (now > reserveTimeLock));
    grantReserveSupply = true;
    token.mint(beneficiary,reserveSupply);
    reserveSupply = 0;
    
  }

 function transferFunds(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  } 
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }


}



