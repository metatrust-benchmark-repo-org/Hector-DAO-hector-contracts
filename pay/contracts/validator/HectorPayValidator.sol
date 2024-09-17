// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

import {IHectorValidator} from '../interfaces/IHectorValidator.sol';
import {IHectorPayFactory} from '../interfaces/IHectorPayFactory.sol';
import {IHectorSubscription} from '../interfaces/IHectorSubscription.sol';

error INVALID_ADDRESS();
error INVALID_PARAM();

contract HectorPayValidator is IHectorValidator, Ownable {
    /* ======== STORAGE ======== */

    IHectorSubscription public paySubscription;
    IHectorPayFactory public payFactory;

    /* ======== INITIALIZATION ======== */

    constructor(address _paySubscription, address _payFactory) {
        if (_paySubscription == address(0) || _payFactory == address(0))
            revert INVALID_ADDRESS();

        paySubscription = IHectorSubscription(_paySubscription);
        payFactory = IHectorPayFactory(_payFactory);
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setPaySubscription(address _paySubscription) external onlyOwner {
        if (_paySubscription == address(0)) revert INVALID_ADDRESS();
        paySubscription = IHectorSubscription(_paySubscription);
    }

    function setPayFactory(address _payFactory) external onlyOwner {
        if (_payFactory == address(0)) revert INVALID_ADDRESS();
        payFactory = IHectorPayFactory(_payFactory);
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function isValid(bytes calldata input) external returns (bool) {
        address from = abi.decode(input, (address));

        (uint256 planId, , , , ) = paySubscription.getSubscription(from);
        IHectorSubscription.Plan memory plan = paySubscription.getPlan(planId);
        uint256 limitationOfActiveStreams = abi.decode(plan.data, (uint256));

        return
            limitationOfActiveStreams >
            payFactory.activeStreamsByRemoveEnded(from);
    }
}
