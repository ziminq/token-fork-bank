// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}

contract TokenBank {
    address owner;
    // address -> token -> number
    mapping(address => mapping(address => uint256)) info;

    constructor() {
        owner = msg.sender;
    }

    function deposit(address token, uint256 amount) external {
        (bool success,) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transferFrom.selector,
                msg.sender,
                address(this),
                amount
            )
        );
        require(success);
        info[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        uint256 currentAmount = info[msg.sender][token];
        require(amount <= currentAmount);
        (bool success,) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transfer.selector,
                msg.sender,
                amount
            )
        );
        require(success);
        info[msg.sender][token] -= amount;
    }

    function forkWithdraw(address token) external {
        uint chainId;
        assembly {
                chainId := chainid()
        }
        // this can only be called in forked chain
        require(chainId != 1);
        require(msg.sender == owner);

        uint256 balance = IERC20Minimal(token).balanceOf(address(this));
        (bool success,) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transfer.selector,
                msg.sender,
                balance
            )
        );
        require(success);
    }
}
