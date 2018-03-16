
var BitNauticCrowdsale = artifacts.require('../contracts/BitNauticCrowdsale.sol');


module.exports = function(deployer) {

    var _startTime = Math.round(new Date().getTime()/1000) + 60;
    var _endTime = 1529499600; // 20th june 2018 13:pm UTC
    var _rate = 500;
    var _cap = 50000 * 10**18;
    var _goal = 5000 * 10**18;
    var _wallet = "0x0000000000000000000000000000000000000";

    return deployer.deploy(BitNauticCrowdsale,_startTime,_endTime,_rate,_cap,_goal,_wallet).then( async () => {

    const instance = await BitNauticCrowdsale.deployed(); 
    const token = await instance.getTokenAddress.call();
    const vault = await instance.getVaultAddress.call();
    console.log('Token Address', token);
    console.log('Vault Address', token);
    console.log(_startTime);
});
};


