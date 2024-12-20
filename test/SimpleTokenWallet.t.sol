// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Ownable } from "@openzeppelin/access/Ownable.sol";

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

        _depositToken(address(wrappedNative), amountToWrap);

        assertEq(wallet.getTokenBalance(address(wrappedNative)), amountToWrap);
    }

    function test_depositTokens() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        assertEq(wallet.getTokenBalance(address(token)), amount);
    }

    function test_withdrawTokens() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        vm.startPrank(owner);
        wallet.withdraw(address(token), amount);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(owner), amount);
    }

    function test_withdrawingWithSignatureFailsIfInvalidSignaturePassed() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidSignature.selector, signature));
        wallet.withdrawWithSignature(address(token), amount, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_withdrawingWithSignatureFailsIfInvalidNoncePassed() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce() + 1;
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), gasProvider, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidNonce.selector, nonce, nonce - 1));
        wallet.withdrawWithSignature(address(token), amount, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_withdrawingWithSignatureFailsIfDeadlineHasPassed() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), gasProvider, amount, nonce, deadline);

        skip(deadlineWindow + 1);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.DeadlinePassed.selector, deadline, block.timestamp));
        wallet.withdrawWithSignature(address(token), amount, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_withdrawingTokensWithSignatureSucceeds() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), gasProvider, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        wallet.withdrawWithSignature(address(token), amount, nonce, deadline, signature);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(gasProvider), amount);
    }

    function test_transferingTokensWithSignatureFailsIfInvalidSignaturePassed() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), gasProvider, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidSignature.selector, signature));
        wallet.transferTokensWithSignature(address(token), amount, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensWithSignatureFailsIfInvalidNoncePassed() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce() + 1;
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidNonce.selector, nonce, nonce - 1));
        wallet.transferTokensWithSignature(address(token), amount, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensWithSignatureFailsIfDeadlineHasPassed() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amount, nonce, deadline);

        skip(deadlineWindow + 1);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.DeadlinePassed.selector, deadline, block.timestamp));
        wallet.transferTokensWithSignature(address(token), amount, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensWithSignatureSucceeds() public {
        uint256 amount = 10 ether;
        _depositToken(address(token), amount);

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), owner, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        wallet.transferTokensWithSignature(address(token), amount, owner, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureFailsIfInvalidSignaturePassed() public {
        uint256 amount = 10 ether;
        token.mint(owner, amount);
        vm.startPrank(owner);
        token.approve(address(wallet), amount);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), address(wallet), gasProvider, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidSignature.selector, signature));
        wallet.transferTokensFromWithSignature(address(token), owner, amount, gasProvider, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureFailsIfInvalidNoncePassed() public {
        uint256 amount = 10 ether;
        token.mint(owner, amount);
        vm.startPrank(owner);
        token.approve(address(wallet), amount);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce() + 1;
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), owner, gasProvider, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InvalidNonce.selector, nonce, nonce - 1));
        wallet.transferTokensFromWithSignature(address(token), owner, amount, gasProvider, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureFailsIfDeadlineHasPassed() public {
        uint256 amount = 10 ether;
        token.mint(owner, amount);
        vm.startPrank(owner);
        token.approve(address(wallet), amount);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), owner, gasProvider, amount, nonce, deadline);

        skip(deadlineWindow + 1);

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.DeadlinePassed.selector, deadline, block.timestamp));
        wallet.transferTokensFromWithSignature(address(token), owner, amount, gasProvider, nonce, deadline, signature);
        vm.stopPrank();
    }

    function test_transferingTokensFromWithSignatureSucceeds() public {
        uint256 amount = 10 ether;
        token.mint(owner, amount);
        vm.startPrank(owner);
        token.approve(address(wallet), amount);
        vm.stopPrank();

        uint256 nonce = wallet.getNextNonce();
        uint256 deadline = block.timestamp + 2 minutes;
        bytes memory signature = _getSignature(address(token), owner, gasProvider, amount, nonce, deadline);

        vm.startPrank(gasProvider);
        wallet.transferTokensFromWithSignature(address(token), owner, amount, gasProvider, nonce, deadline, signature);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(gasProvider), amount);
    }

    function test_transferingTokensFailsIfCallerNotOwner() public {
        uint256 amount = 1 ether;

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, gasProvider));
        wallet.transferTokens(address(token), amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFailsIfTokenIsAddressZero() public {
        uint256 amount = 1 ether;

        vm.startPrank(owner);
        vm.expectRevert(ISimpleTokenWallet.AddressZero.selector);
        wallet.transferTokens(address(0), amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFailsIfAmountIsZero() public {
        vm.startPrank(owner);
        vm.expectRevert(ISimpleTokenWallet.AmountZero.selector);
        wallet.transferTokens(address(token), 0, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFailsIfRecipientIsAddressZero() public {
        uint256 amount = 1 ether;

        vm.startPrank(owner);
        vm.expectRevert(ISimpleTokenWallet.AddressZero.selector);
        wallet.transferTokens(address(token), amount, address(0));
        vm.stopPrank();
    }

    function test_transferingTokensFailsIfWalletHasInsufficientTokenBalance() public {
        uint256 amount = 1 ether;

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InsufficientTokenAmount.selector, 0, amount));
        wallet.transferTokens(address(token), amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensSucceeds() public {
        uint256 amount = 1 ether;
        _depositToken(address(token), amount);

        vm.startPrank(owner);
        wallet.transferTokens(address(token), amount, gasProvider);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(gasProvider), amount);
    }

    function test_transferingTokensEmitsEvent() public {
        uint256 amount = 1 ether;
        _depositToken(address(token), amount);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit ISimpleTokenWallet.TokensTransferred(address(token), amount, gasProvider);
        wallet.transferTokens(address(token), amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFromFailsIfCallerIsNotOwner() public {
        uint256 amount = 1 ether;

        vm.startPrank(gasProvider);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, gasProvider));
        wallet.transferTokensFrom(address(token), owner, amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFromFailsIfTokenIsAddressZero() public {
        uint256 amount = 1 ether;

        vm.startPrank(owner);
        vm.expectRevert(ISimpleTokenWallet.AddressZero.selector);
        wallet.transferTokensFrom(address(0), owner, amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFromFailsIfAmountIsZero() public {
        vm.startPrank(owner);
        vm.expectRevert(ISimpleTokenWallet.AmountZero.selector);
        wallet.transferTokensFrom(address(token), owner, 0, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFromFailsIfRecipientIsAddressZero() public {
        uint256 amount = 1 ether;

        vm.startPrank(owner);
        vm.expectRevert(ISimpleTokenWallet.AddressZero.selector);
        wallet.transferTokensFrom(address(token), owner, amount, address(0));
        vm.stopPrank();
    }

    function test_transferingTokensFromFailsIfWalletHasInsufficientAllowance() public {
        uint256 amount = 1 ether;

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(ISimpleTokenWallet.InsufficientAllowance.selector, 0, amount));
        wallet.transferTokensFrom(address(token), owner, amount, gasProvider);
        vm.stopPrank();
    }

    function test_transferingTokensFromSucceeds() public {
        uint256 amount = 1 ether;
        _approveToken(address(token), amount);

        vm.startPrank(owner);
        wallet.transferTokensFrom(address(token), owner, amount, gasProvider);
        vm.stopPrank();

        assertEq(wallet.getTokenBalance(address(token)), 0);
        assertEq(token.balanceOf(gasProvider), amount);
    }

    function test_transferingTokensFromEmitsEvent() public {
        uint256 amount = 1 ether;
        _approveToken(address(token), amount);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit ISimpleTokenWallet.TokensTransferredFrom(address(token), owner, amount, gasProvider);
        wallet.transferTokensFrom(address(token), owner, amount, gasProvider);
        vm.stopPrank();
    }
}
