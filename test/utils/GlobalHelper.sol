// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { SimpleTokenWallet } from "../../src/SimpleTokenWallet.sol";
import { ERC20Mintable } from "./ERC20Mintable.sol";
import { WrappedNative } from "./WrappedNative.sol";

contract GlobalHelper is Test {
    address public owner;
    uint256 public ownerPrivateKey;
    address public gasProvider;

    ERC20Mintable public token;
    WrappedNative public wrappedNative;

    SimpleTokenWallet public wallet;

    uint256 deadlineWindow;

    error TransferFailed();

    function setUp() public {
        (owner, ownerPrivateKey) = makeAddrAndKey("owner");
        gasProvider = makeAddr("gas provider");

        string memory tokenName = "Optimism";
        string memory tokenSymbol = "OP";
        token = new ERC20Mintable(tokenName, tokenSymbol);
        wrappedNative = new WrappedNative();

        wallet = new SimpleTokenWallet(owner, address(wrappedNative));

        deadlineWindow = 2 minutes;
    }

    function _dealNativeToken(address _to, uint256 _amount) internal {
        vm.deal(_to, _amount);
    }

    function _depositToken(uint256 _amount) public {
        token.mint(owner, _amount);

        vm.startPrank(owner);
        token.approve(address(wallet), _amount);
        wallet.deposit(address(token), _amount);
        vm.stopPrank();
    }

    function _getSignature(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline
    )
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = wallet.getEncodedTransferDataHash(_token, _from, _to, _amount, _nonce, _deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        return abi.encodePacked(r, s, v);
    }
}