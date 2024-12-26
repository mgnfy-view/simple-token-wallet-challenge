// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Ownable } from "@openzeppelin/access/Ownable.sol";

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";

import { ISimpleTokenWallet } from "./interfaces/ISimpleTokenWallet.sol";
import { IWNative } from "./interfaces/IWNative.sol";

/// @title SimpleTokenWallet.
/// @author mgnfy-view.
/// @notice A simple token wallet featuring gasless transfers using EIP712 signatures.
contract SimpleTokenWallet is Ownable, EIP712, ISimpleTokenWallet {
    using SafeERC20 for IERC20;

    bytes32 private constant TRANSFER_TYPE_HASH = keccak256(
        bytes(
            "Transfer(address token,address from,address to,uint256 amount,bool isApproval,uint256 nonce,uint256 deadline)"
        )
    );

    /// @dev The address of the wrapped native token contract.
    address private immutable i_wrappedNativeToken;

    /// @dev Nonce to be used by EIP712 signatures which protects against replay attacks.
    uint256 private s_nonce;

    /// @notice Sets the owner and initializes the EIP712 name and version variables.
    /// @param _owner The owner of the wallet.
    /// @param _wrappedNativeToken The address of the wrapped native token.
    constructor(address _owner, address _wrappedNativeToken) Ownable(_owner) EIP712("Simple Token Wallet", "1") {
        if (_owner == address(0) || _wrappedNativeToken == address(0)) revert AddressZero();

        i_wrappedNativeToken = _wrappedNativeToken;
    }

    /// @notice Enables the wallet to receive native token and wraps it.
    receive() external payable {
        IWNative(payable(i_wrappedNativeToken)).deposit{ value: msg.value }();

        emit NativeTokenWrapped(msg.sender, msg.value);
    }

    /// @notice Allows anyone to deposit tokens into this wallet.
    /// @param _token The token address.
    /// @param _amount The amount of token to deposit.
    function deposit(address _token, uint256 _amount) external {
        _transferTokensFrom(_token, msg.sender, _amount, address(this));
    }

    /// @notice Allows the owner to withdraw tokens from this wallet contract.
    /// @param _token The token address.
    /// @param _amount The amount of token to deposit.
    function withdraw(address _token, uint256 _amount) external onlyOwner {
        _transferTokens(_token, _amount, msg.sender);
    }

    /// @notice Enables the owner to conduct a token transfer from this wallet.
    /// @param _token The token address.
    /// @param _amount The amount of token to deposit.
    /// @param _to The token recipient.
    function transferTokens(address _token, uint256 _amount, address _to) external onlyOwner {
        _transferTokens(_token, _amount, _to);
    }

    /// @notice Enables the owner to use the token allowance provided to this wallet.
    /// @param _token The token address.
    /// @param _allowanceProvider The user whose tokens will be used for this trnasfer.
    /// @param _amount The amount of token to deposit.
    /// @param _to The token recipient.
    function transferTokensFrom(
        address _token,
        address _allowanceProvider,
        uint256 _amount,
        address _to
    )
        external
        onlyOwner
    {
        _transferTokensFrom(_token, _allowanceProvider, _amount, _to);
    }

    /// @notice Allows the owner to provide an allowance to the spender.
    /// @param _token The token address.
    /// @param _spender The user to provide a token allowance to.
    /// @param _amount The amount of token to approve.
    function approve(address _token, address _spender, uint256 _amount) external onlyOwner {
        _approve(_token, _spender, _amount);
    }

    /// @notice Allows anyone to conduct a token withdrawal if they can present
    /// a valid signature from the owner.
    /// @param _token The token address.
    /// @param _amount The amount of token to deposit.
    /// @param _nonce A unique number that prevents replay attacks.
    /// @param _deadline The UNIX timestamp (in seconds) after which this signature is
    /// considered invalid.
    /// @param _signature The owner's signature approving this withdrawal.
    function withdrawWithSignature(
        address _token,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external
    {
        _checkSignature(_token, address(this), msg.sender, _amount, false, _nonce, _deadline, _signature);
        _checkNonce(_nonce);
        _checkDeadline(_deadline);

        _transferTokens(_token, _amount, msg.sender);
    }

    /// @notice Allows anyone to conduct a token transfer if they can present
    /// a valid signature from the owner.
    /// @param _token The token address.
    /// @param _amount The amount of token to deposit.
    /// @param _nonce A unique number that prevents replay attacks.
    /// @param _deadline The UNIX timestamp (in seconds) after which this signature is
    /// considered invalid.
    /// @param _signature The owner's signature approving this withdrawal.
    function transferTokensWithSignature(
        address _token,
        uint256 _amount,
        address _to,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external
    {
        _checkSignature(_token, address(this), _to, _amount, false, _nonce, _deadline, _signature);
        _checkNonce(_nonce);
        _checkDeadline(_deadline);

        _transferTokens(_token, _amount, _to);
    }

    /// @notice Allows anyone to conduct a token transfer if they can present
    /// a valid signature from the owner.
    /// @param _token The token address.
    /// @param _allowanceProvider The user whose tokens will be used for this trnasfer.
    /// @param _amount The amount of token to deposit.
    /// @param _nonce A unique number that prevents replay attacks.
    /// @param _deadline The UNIX timestamp (in seconds) after which this signature is
    /// considered invalid.
    /// @param _signature The owner's signature approving this transfer.
    function transferTokensFromWithSignature(
        address _token,
        address _allowanceProvider,
        uint256 _amount,
        address _to,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external
    {
        _checkSignature(_token, _allowanceProvider, _to, _amount, false, _nonce, _deadline, _signature);
        _checkNonce(_nonce);
        _checkDeadline(_deadline);

        _transferTokensFrom(_token, _allowanceProvider, _amount, _to);
    }

    /// @notice Provides allowance to a spender if a valid signature is provided.
    /// @param _token The token address.
    /// @param _spender The user to provide a token allowance to.
    /// @param _amount The amount of token to approve.
    /// @param _nonce A unique number that prevents replay attacks.
    /// @param _deadline The UNIX timestamp (in seconds) after which this signature is
    /// considered invalid.
    /// @param _signature The owner's signature approving this transfer.
    function approveWithSignature(
        address _token,
        address _spender,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external
    {
        _checkSignature(_token, address(this), _spender, _amount, true, _nonce, _deadline, _signature);
        _checkNonce(_nonce);
        _checkDeadline(_deadline);

        _approve(_token, _spender, _amount);
    }

    /// @notice Internal function to conduct token trnasfer from the wallet to any other address.
    /// @param _token The token address.
    /// @param _amount The amount of token to deposit.
    /// @param _to The token recipient.
    function _transferTokens(address _token, uint256 _amount, address _to) internal {
        if (_token == address(0) || _to == address(0)) revert AddressZero();
        if (_amount == 0) revert AmountZero();

        uint256 tokenBalance = getTokenBalance(_token);
        if (tokenBalance < _amount) revert InsufficientTokenAmount(tokenBalance, _amount);

        IERC20(_token).safeTransfer(_to, _amount);

        emit TokensTransferred(_token, _amount, _to);
    }

    /// @notice Internal function which enables the owner to use the token allowance provided to this wallet.
    /// @param _token The token address.
    /// @param _allowanceProvider The user whose tokens will be used for this trnasfer.
    /// @param _amount The amount of token to deposit.
    /// @param _to The token recipient.
    function _transferTokensFrom(address _token, address _allowanceProvider, uint256 _amount, address _to) internal {
        if (_token == address(0) || _allowanceProvider == address(0) || _to == address(0)) revert AddressZero();
        if (_amount == 0) revert AmountZero();

        uint256 allowance = getAllowance(_token, _allowanceProvider);
        if (allowance < _amount) revert InsufficientAllowance(allowance, _amount);

        IERC20(_token).safeTransferFrom(_allowanceProvider, _to, _amount);

        emit TokensTransferredFrom(_token, _allowanceProvider, _amount, _to);
    }

    /// @notice Internal function to approve tokens to a spender.
    /// @dev Any amount can be approved, irrespective of whether the wallet holds that
    /// amount of tokens or not.
    /// @param _token The token address.
    /// @param _spender The user to provide a token allowance to.
    /// @param _amount The amount of token to approve.
    function _approve(address _token, address _spender, uint256 _amount) internal {
        if (_token == address(0) || _spender == address(0)) revert AddressZero();

        IERC20(_token).approve(_spender, _amount);

        emit Approved(_token, _spender, _amount);
    }

    /// @notice Verifies the signature for gas sponsored transfers.
    /// @param _token The token address.
    /// @param _from The address to transfer the tokens from.
    /// @param _to The token recipient.
    /// @param _amount The amount of token to deposit.
    /// @param _isApproval Differentiates a transfer operation with an approval operation.
    /// @param _nonce A unique number that prevents replay attacks.
    /// @param _deadline The UNIX timestamp (in seconds) after which this signature is
    /// considered invalid.
    /// @param _signature The owner's signature approving this transfer.
    function _checkSignature(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bool _isApproval,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        internal
        view
    {
        address recoveredOwner = ECDSA.recover(
            getEncodedTransferDataHash(_token, _from, _to, _amount, _isApproval, _nonce, _deadline), _signature
        );
        if (recoveredOwner != owner()) revert InvalidSignature(_signature);
    }

    /// @notice Validates the nonce value used for signatures. Reverts if the nonce is invalid.
    /// @param _nonce The nonce value.
    function _checkNonce(uint256 _nonce) internal {
        if (_nonce != s_nonce + 1) revert InvalidNonce(_nonce, s_nonce + 1);
        s_nonce++;
    }

    /// @notice Reverts if the deadline has passed.
    /// @param _deadline The deadline before which the operation should be completed.
    function _checkDeadline(uint256 _deadline) internal view {
        if (_deadline < block.timestamp) revert DeadlinePassed(_deadline, block.timestamp);
    }

    /// @notice Gets the wrapped native token address.
    /// @return The wrapped native token address.
    function getWrappedNativeToken() external view returns (address) {
        return i_wrappedNativeToken;
    }

    /// @notice Gets the next valid nonce value.
    /// @return The next valid nonce value.
    function getNextNonce() external view returns (uint256) {
        return s_nonce + 1;
    }

    /// @notice Gets the token balance of this wallet.
    /// @param _token The token address.
    /// @return The token balance.
    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Gets the token allowance provided to this contract.
    /// @param _token The token address.
    /// @param _allowanceProvider The provider of the token allowance.
    function getAllowance(address _token, address _allowanceProvider) public view returns (uint256) {
        return IERC20(_token).allowance(_allowanceProvider, address(this));
    }

    /// @notice Gets the transfer operation digest.
    /// @param _token The token address.
    /// @param _from The address to transfer the tokens from.
    /// @param _to The token recipient.
    /// @param _amount The amount of token to deposit.
    /// @param _isApproval Differentiates a transfer operation with an approval operation.
    /// @param _nonce A unique number that prevents replay attacks.
    /// @param _deadline The UNIX timestamp (in seconds) after which this signature is
    /// considered invalid.
    /// @return The transfer operation digest.
    function getEncodedTransferDataHash(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bool _isApproval,
        uint256 _nonce,
        uint256 _deadline
    )
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(abi.encodePacked(TRANSFER_TYPE_HASH, _token, _from, _to, _amount, _isApproval, _nonce, _deadline))
        );
    }
}
