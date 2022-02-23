// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Particlon Mint Pass NFT
/// @author 0xapetoshi.eth
contract ParticlonMintPass is ERC1155, Ownable {
    /// @notice With ERC1155, the name and symbol need to be set like this
    string public constant name = "Particlon Mint Pass";

    string public constant symbol = "PAMP";

    /// @notice Sale will be publicly announced
    bool public saleActive;

    /// @notice The maximum number of mints per wallet to 2
    uint256 public constant MAX_PER_WALLET = 2;

    /// @notice Collection limited to 250
    uint256 public constant MAX_TOTAL_SUPPLY = 250;

    /// @notice First one is minted to contract deployer to claim on OpenSea
    uint256 public totalSupply = 1;

    /// @notice The price per one mint, without gas
    uint256 public constant PRICE = 0.15 ether;

    /// @dev Balances can change, mappings are the way to go to limit mints per wallet
    mapping(address => uint256) public walletsMinted;

    /// @notice metadata can't be edited
    constructor()
        ERC1155(
            "ipfs://QmekXtZf3AHMbiqtyidCVJJgCUESdvYjqvtzJBFtZChGK9/{id}.json"
        )
    {
        /**
            @dev msg.sender is the contract deployer,
            @dev ERC1155 supports multiple token types; we only use one (id 0)
            @dev Data is left blank ("")
         */
        _mint(msg.sender, 0, 1, "");
    }

    /// @dev flips boolean with the logical NOT(!) operator
    function flipSale() external onlyOwner {
        saleActive = !saleActive;
    }

    /// @param amount Number of tokens to mint; in this case either 1 or 2
    function mint(uint256 amount) external payable {
        /// @dev smart contracts cannot send signed transactions
        require(msg.sender == tx.origin, "Smart contracts not allowed");
        require(saleActive, "Sale not active");
        require(amount > 0, "Amount can't be 0");
        require(
            walletsMinted[msg.sender] + amount <= 2,
            "Wallet limitation (2)"
        );
        require(msg.value == PRICE * amount, "Incorrect ETH");
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "Total supply (250)");

        walletsMinted[msg.sender] += amount;
        totalSupply += amount;

        /// @dev effects are before interactions to avoid reentrancy attacks
        _mint(msg.sender, 0, amount, "");
    }

    /// @notice Withdraws funds to the team Gnosis Safe Multisig wallet
    /// @dev EDIT: Berlin fork requires `accessList` to send this transaction without running out of gas. See EIP-2929 and EIP-2930.
    /// @notice EDIT: For ordinary wallets this is fine, in this case with it was a small oversight that adds complexity
    /// @notice EDIT: Advised method of ETH transfer is using `call`!
    function withdrawETH() external onlyOwner {
        payable(0xDbaD7CbcA084DFf4E93B0f365978362aD8cc0A35).transfer(
            address(this).balance
        );
    }
}
