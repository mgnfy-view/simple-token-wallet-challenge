// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title ISimpleTokenWallet.
/// @author mgnfy-view.
/// @notice Interface to interact with the token wallet.
interface ISimpleTokenWallet {
    event NativeTokenWrapped(address by, uint256 indexed amount);
    event TokensTransferred(address indexed token, uint256 indexed amount, address indexed to);

    error AddressZero();
    error AmountZero();
    error InsufficientTokenAmount(uint256 currentBalance, uint256 amountToTransfer);
    error InsufficientAllowance(uint256 currentAllowance, uint256 amountToSpend);
    error InvalidSignature(bytes signature);
    error InvalidNonce(uint256 givenNonce, uint256 expectedNonce);
    error DeadlinePassed(uint256 deadline, uint256 currentTimestamp);

    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _token, uint256 _amount) external;
    function withdrawWithSignature(
        address _token,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external;
    function transferTokensWithSignature(
        address _token,
        uint256 _amount,
        address _to,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external;
    function transferTokensFromWithSignature(
        address _token,
        address _allowanceProvider,
        uint256 _amount,
        address _to,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature
    )
        external;
    function transferTokens(address _token, uint256 _amount, address _to) external;
    function transferTokensFrom(address _token, address _allowanceProvider, uint256 _amount, address _to) external;
    function getWrappedNativeToken() external view returns (address);
    function getNextNonce() external view returns (uint256);
    function getTokenBalance(address _token) external view returns (uint256);
    function getAllowance(address _token, address _allowanceProvider) external view returns (uint256);
    function getEncodedTransferDataHash(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline
    )
        external
        view
        returns (bytes32);
}
