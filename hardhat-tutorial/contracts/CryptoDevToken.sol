// SPDX-License-Identifier: MIT
// SPDX-Licence-Identifer: MIT 

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    // price of one crypto dev token 
    uint256 public constant tokenPrice = 0.001 ether;
    // Each NFT will give the user 10 tokens 
    // it needs to be represented and 10* (10 ** 18) as ERC20 tokens are represented by the smallest denomination possible of your token
    //By Default, ERC20 tokens habe the smallest denomination of 10^(-18). This means having a balance of (1)
    //is actually eual to (10^ -18) tokens.
    //Owning one full token is equalivalent to owning (10^18) tokens when you account for the decimal places.

    uint256 public constant tokensPerNFT = 10 * 10**18;

    // The max total supply is 10,000 for crypto dev tokens 

    uint256 public constant maxTotalSupply = 10000 * 10**18;

    // Crypto devs contract instance 

    ICryptoDevs CryptoDevsNFT;

    // Mapping to keep track of which tokens have been claimed 

    mapping (uint256 => bool) public tokenIdsClaimed;

    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
          CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
      }


      /**
       * @dev Mints 'amount' number of CryptoDevTokens
       * requirements:
       * - 'msg.value' should be equal or greater than the token price * amount
       */

      function mint(uint256 amount) public payable {
        // the valye of the ether that should be equal or greater than the token price * amount;
        uint256 _requireAmount = tokenPrice * amount;
        require(msg.value >= _requireAmount, "Ether sent is incorrect");
        // total tokens + amount <= 10,000, otherwise revert the transaction 
        uint256 amountWithDecimals = amount * 10**18;
        require(
            (totalSupply() + amountWithDecimals) <= maxTotalSupply,
            "Exceeds the max total supply available."
        );
        // call the internal function from Openzeppelins ERC20 contract
        _mint(msg.sender, amountWithDecimals); 
        }

        /**
        * @dev Mints tokens based on the number of NFT's held by the sender
        * Requirements:
        * balance of Crypto Dev NFT's owned by the sender should be greater than 0
        * Tokens should have not been claimed for all the NFTs owned by the sender
        */
        
function claim() public {
          address sender = msg.sender;
          // Get the number of CryptoDev NFT's held by a given sender address
          uint256 balance = CryptoDevsNFT.balanceOf(sender);
          // If the balance is zero, revert the transaction
          require(balance > 0, "You dont own any Crypto Dev NFT's");
          // amount keeps track of number of unclaimed tokenIds
          uint256 amount = 0;
          // loop over the balance and get the token ID owned by `sender` at a given `index` of its token list.
          for (uint256 i = 0; i < balance; i++) {
              uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
              // if the tokenId has not been claimed, increase the amount
              if (!tokenIdsClaimed[tokenId]) {
                  amount += 1;
                  tokenIdsClaimed[tokenId] = true;
              }
          }
          // If all the token Ids have been claimed, revert the transaction;
          require(amount > 0, "You have already claimed all the tokens");
          // call the internal function from Openzeppelin's ERC20 contract
          // Mint (amount * 10) tokens for each NFT
          _mint(msg.sender, amount * tokensPerNFT);
      }

      /**
        * @dev withdraws all ETH sent to this contract
        * Requirements:
        * wallet connected must be owner's address
        */
      function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw; contract balance empty");
        
        address _owner = owner();
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
      }

      // Function to receive Ether. msg.data must be empty
      receive() external payable {}

      // Fallback function is called when msg.data is not empty
      fallback() external payable {}
  }