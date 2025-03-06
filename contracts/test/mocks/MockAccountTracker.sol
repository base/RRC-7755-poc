// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MockAccountTracker {
    address constant public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address account => mapping(address token => uint256 balance)) private _balances;

    function balanceOf(address account, address token) public view returns (uint256) {
        return _balances[account][token];
    }

    function deposit(address token, uint256 amount) external payable {
        _deposit(msg.sender, token, amount);
    }

    function deposit(address account, address token, uint256 amount) external payable {
        _deposit(account, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(balanceOf(msg.sender, token) >= amount, "Insufficient balance");

        _balances[msg.sender][token] -= amount;

        if (token == ETH_ADDRESS) {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Withdrawal failed");
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    function request(address to, bytes calldata data, address token, uint256 amount) external {
        uint256 value;

        require(balanceOf(msg.sender, token) >= amount, "Insufficient balance");

        _balances[msg.sender][token] -= amount;

        if (token == ETH_ADDRESS) {
            value = amount;
        } else {
            IERC20(token).approve(to, amount);
        }

        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _deposit(address account, address token, uint256 amount) private {
        if (token == ETH_ADDRESS) {
            require(msg.value == amount, "Invalid ETH amount");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        _balances[account][token] += amount;
    }
}
