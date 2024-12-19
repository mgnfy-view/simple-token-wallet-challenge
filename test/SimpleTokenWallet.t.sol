// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ISimpleTokenWallet } from "../src/interfaces/ISimpleTokenWallet.sol";

import { GlobalHelper } from "./utils/GlobalHelper.sol";

contract SimpleTokenWalletTest is GlobalHelper {
    function test_checkInitialization() public view {
        uint256 expectedNextNonce = 1;

        assertEq(wallet.owner(), owner);
        assertEq(wallet.getWrappedNativeToken(), address(wrappedNative));
        assertEq(wallet.getNextNonce(), expectedNextNonce);
    }

    function test_wrapNativeToken() public {
        uint256 amountToWrap = 1 ether;
        _dealNativeToken(owner, amountToWrap);

        vm.startPrank(owner);
        (bool success,) = payable(wallet).call{ value: amountToWrap }("");
        if (!success) revert TransferFailed();
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(wrappedNative)), amountToWrap);
    }

    function test_depositTokens() public {
        uint256 amountToMint = 10 ether;
        token.mint(owner, amountToMint);

        vm.startPrank(owner);
        token.approve(address(wallet), amountToMint);
        wallet.deposit(address(token), amountToMint);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), amountToMint);
    }

    function test_withdrawTokens() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        vm.startPrank(owner);
        wallet.withdraw(address(token), amountToDeposit);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(owner), amountToDeposit);
    }

    function test_withdrawingWithSignatureFailsIfInvalidSignaturePassed() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amountToDeposit, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidSignature.selector, signature));
        wallet.withdrawWithSignature(address(token), amountToDeposit, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_withdrawingWithSignatureFailsIfInvalidNoncePassed() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce() + 1;
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature =
            _getSignature(address(token), address(wallet), gasProvider, amountToDeposit, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidNonce.selector, nonce, nonce - 1));
        wallet.withdrawWithSignature(address(token), amountToDeposit, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_withdrawingWithSignatureFailsIfDeadlineHasPassed() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature =
            _getSignature(address(token), address(wallet), gasProvider, amountToDeposit, nonce, deadline);

        skip(deadlineWindow + 1);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.DeadlinePassed.selector, deadline, block.timestamp));
        wallet.withdrawWithSignature(address(token), amountToDeposit, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_withdrawingTokensWithSignatureSucceeds() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature =
            _getSignature(address(token), address(wallet), gasProvider, amountToDeposit, nonce, deadline);

        vm.startPrank(gasProvider);
        wallet.withdrawWithSignature(address(token), amountToDeposit, nonce, deadline, signature);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(gasProvider), amountToDeposit);
    }

    function test_transferingTokensWithSignatureFailsIfInvalidSignaturePassed() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature =
            _getSignature(address(token), address(wallet), gasProvider, amountToDeposit, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidSignature.selector, signature));
        wallet.transferTokensWithSignature(address(token), amountToDeposit, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensWithSignatureFailsIfInvalidNoncePassed() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce() + 1;
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amountToDeposit, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidNonce.selector, nonce, nonce - 1));
        wallet.transferTokensWithSignature(address(token), amountToDeposit, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensWithSignatureFailsIfDeadlineHasPassed() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amountToDeposit, nonce, deadline);

        skip(deadlineWindow + 1);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.DeadlinePassed.selector, deadline, block.timestamp));
        wallet.transferTokensWithSignature(address(token), amountToDeposit, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensWithSignatureSucceeds() public {
        uint256 amountToDeposit = 10 ether;
        _depositToken(amountToDeposit);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amountToDeposit, nonce, deadline);

        vm.startPrank(gasProvider);
        wallet.transferTokensWithSignature(address(token), amountToDeposit, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureFailsIfInvalidSignaturePassed() public {
        uint256 amountToMint = 10 ether;
        token.mint(owner, amountToMint);
        vm.startPrank(owner);
        token.approve(address(wallet), amountToMint);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature =
            _getSignature(address(token), address(wallet), gasProvider, amountToMint, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidSignature.selector, signature));
        wallet.transferTokensFromWithSignature(
            address(token), owner, amountToMint, gasProvider, nonce, deadline, signature
        );
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureFailsIfInvalidNoncePassed() public {
        uint256 amountToMint = 10 ether;
        token.mint(owner, amountToMint);
        vm.startPrank(owner);
        token.approve(address(wallet), amountToMint);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce() + 1;
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), owner, gasProvider, amountToMint, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidNonce.selector, nonce, nonce - 1));
        wallet.transferTokensFromWithSignature(
            address(token), owner, amountToMint, gasProvider, nonce, deadline, signature
        );
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureFailsIfDeadlineHasPassed() public {
        uint256 amountToMint = 10 ether;
        token.mint(owner, amountToMint);
        vm.startPrank(owner);
        token.approve(address(wallet), amountToMint);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), owner, gasProvider, amountToMint, nonce, deadline);

        skip(deadlineWindow + 1);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.DeadlinePassed.selector, deadline, block.timestamp));
        wallet.transferTokensFromWithSignature(
            address(token), owner, amountToMint, gasProvider, nonce, deadline, signature
        );
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureSucceeds() public {
        uint256 amountToMint = 10 ether;
        token.mint(owner, amountToMint);
        vm.startPrank(owner);
        token.approve(address(wallet), amountToMint);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), owner, gasProvider, amountToMint, nonce, deadline);

        vm.startPrank(gasProvider);
        wallet.transferTokensFromWithSignature(
            address(token), owner, amountToMint, gasProvider, nonce, deadline, signature
        );
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(gasProvider), amountToMint);
    }
}
