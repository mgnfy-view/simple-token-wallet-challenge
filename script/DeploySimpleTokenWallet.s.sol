// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";

import { SimpleTokenWallet } from "../src/SimpleTokenWallet.sol";

contract DeploySimpleTokenWallet is Script {
    // Mainnet WETH address
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function run() public returns (address) {
        vm.startBroadcast();
        SimpleTokenWallet wallet = new SimpleTokenWallet(msg.sender, WETH);
        vm.stopBroadcast();

        return address(wallet);
    }
}
