// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

import {HectorPayV2} from './HectorPayV2.sol';

error INVALID_ADDRESS();

contract HectorPayV2Factory is Ownable {
    bytes32 constant INIT_CODEHASH =
        keccak256(type(TransparentUpgradeableProxy).creationCode);

    address public hectorPayLogic;
    address public upgradeableAdmin;

    address public parameter;
    uint256 public getHectorPayContractCount;
    address[1000000000] public getHectorPayContractByIndex;
    mapping(address => address) public getHectorPayContractByToken;

    event HectorPayCreated(address token, address hectorPay);

    constructor(address _hectorPayLogic, address _upgradeableAdmin) {
        if (_hectorPayLogic == address(0) || _upgradeableAdmin == address(0))
            revert INVALID_ADDRESS();

        hectorPayLogic = _hectorPayLogic;
        upgradeableAdmin = _upgradeableAdmin;
    }

    function setHectorPayLogic(address _hectorPayLogic) external onlyOwner {
        if (_hectorPayLogic == address(0)) revert INVALID_ADDRESS();
        hectorPayLogic = _hectorPayLogic;
    }

    function setUpgradeableAdmin(address _upgradeableAdmin) external onlyOwner {
        if (_upgradeableAdmin == address(0)) revert INVALID_ADDRESS();
        upgradeableAdmin = _upgradeableAdmin;
    }

    /**
        @notice Create a new Hector Pay Streaming instance for `_token`
        @dev Instances are created deterministically via CREATE2 and duplicate
            instances will cause a revert
        @param _token The ERC20 token address for which a Hector Pay contract should be deployed
        @return hectorPayContract The address of the newly created Hector Pay contract
      */
    function createHectorPayContract(address _token)
        external
        returns (address hectorPayContract)
    {
        // set the parameter storage slot so the contract can query it
        parameter = _token;
        // use CREATE2 so we can get a deterministic address based on the token
        hectorPayContract = address(
            new TransparentUpgradeableProxy{
                salt: bytes32(uint256(uint160(_token)))
            }(
                hectorPayLogic,
                upgradeableAdmin,
                abi.encodeWithSignature('initialize()')
            )
        );
        // CREATE2 can return address(0), add a check to verify this isn't the case
        // See: https://eips.ethereum.org/EIPS/eip-1014
        require(hectorPayContract != address(0));

        // Append the new contract address to the array of deployed contracts
        uint256 index = getHectorPayContractCount;
        getHectorPayContractByIndex[index] = hectorPayContract;
        unchecked {
            getHectorPayContractCount = index + 1;
        }

        // Append the new contract address to the mapping of deployed contracts
        getHectorPayContractByToken[_token] = hectorPayContract;

        emit HectorPayCreated(_token, hectorPayContract);
    }

    /**
      @notice Query the address of the Hector Pay contract for `_token` and whether it is deployed
      @param _token An ERC20 token address
      @return isDeployed Boolean denoting whether the contract is currently deployed
      */
    function isDeployedHectorPayContractByToken(address _token)
        external
        view
        returns (bool isDeployed)
    {
        isDeployed = getHectorPayContractByToken[_token] != address(0);
    }
}
