// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract InfinityNFTValut is Ownable {
    struct Deposit {
        address owner;
        address collection;
        uint256 createdAt;
        bool withdrawn;
    }

    uint256 public depositsIndex;

    uint256 public minDepositTime = 1 days;

    mapping(address => bool) public collections;

    mapping(uint256 => Deposit) public deposits;

    mapping(uint256 => uint256) public depositByTokenId;

    event Deposited(uint256 id, address indexed owner, uint256 indexed tokenId, address collection, uint256 timestamp);

    event Withdrawal(uint256 id, address indexed to, uint256 indexed tokenId, address collection, uint256 timestamp);

    modifier isSupportedCollection(address collection) {
        require(collections[collection], "NFTValut: collection is not supported");
        _;
    }

    /* Configuration
     ****************************************************************/

    function setMinDepositTime(uint256 period) external onlyOwner {
        minDepositTime = period;
    }

    function enableCollection(address collection) external onlyOwner {
        collections[collection] = true;
    }

    function disableCollection(address collection) external onlyOwner {
        collections[collection] = false;
    }

    /* Domain
     ****************************************************************/

    function deposit(uint256 tokenId, address collection) external isSupportedCollection(collection) {
        IERC721(collection).safeTransferFrom(_msgSender(), address(this), tokenId);

        deposits[++depositsIndex] = Deposit({ owner: _msgSender(), collection: collection, createdAt: block.timestamp, withdrawn: false });

        depositByTokenId[tokenId] = depositsIndex;

        emit Deposited(depositsIndex, _msgSender(), tokenId, collection, block.timestamp);
    }

    function withdraw(uint256 tokenId, address collection) external isSupportedCollection(collection) {
        require(_msgSender() == getDepositByTokenId(tokenId).owner, "NFTValut: deposit owner mismatch");

        require(block.timestamp - getDepositByTokenId(tokenId).createdAt > minDepositTime, "NFTValut: deposit is locked");

        require(getDepositByTokenId(tokenId).withdrawn == false, "NFTValut: deposit already withdrawn");

        IERC721(collection).safeTransferFrom(address(this), _msgSender(), tokenId);

        deposits[depositByTokenId[tokenId]].withdrawn = true;

        emit Withdrawal(depositByTokenId[tokenId], _msgSender(), tokenId, collection, block.timestamp);
    }

    function getDepositByTokenId(uint256 tokenId) public view returns (Deposit memory) {
        return deposits[depositByTokenId[tokenId]];
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
