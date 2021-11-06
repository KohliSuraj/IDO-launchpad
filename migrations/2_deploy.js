var IDOLaunchpad = artifacts.require("../contracts/IDOLaunchpad.sol");
module.exports = function(deployer) {
  deployer.deploy(IDOLaunchpad, "IDO Launchpad!!");
};
