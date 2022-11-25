//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LazyNFT is ERC721URIStorage, EIP712, Ownable {
  
  string private constant SIGNING_DOMAIN = "NFT";
  string private constant SIGNATURE_VERSION = "1";

  uint maximumRoyalty = 100;

  mapping (address => uint256) pendingWithdrawals;

  event Minted(uint nftId, address nftOwner, address nftCreator, uint time );

  constructor(string memory name, string memory symbol)
    ERC721(name, symbol) 
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    }

    mapping(uint256 => address) public minter;   //returs minter of a token id
    mapping(uint256 => uint256) public royalty;  //returns royalty of a token id
    mapping(address => uint256[]) public mintedByUser;

 struct NFTVoucher {
    uint256 tokenId;
    uint256 minPrice;
    string uri;
    uint256 royaltyPercentage;
    bytes signature;
  }

    function _mintNft(uint NftId, address creator,  string memory _TokenURI, uint256 _royaltyPercentage)  
    internal
    returns (uint256) 
    {

        _safeMint(creator, NftId);
        mintedByUser[creator].push(NftId);
        royalty[NftId] = _royaltyPercentage;
        minter[NftId] = creator;
        
        emit Minted (NftId,creator,creator,block.timestamp);
        
    
        return (NftId); 
    }
  

  function redeem(address minter, address redeemer, NFTVoucher calldata voucher) public payable returns (uint256) {

    //on the UI, we will have to show minter's address. 
    //in next step it will get confirmed that NFT that is being minted by user is actually the minetr's signed NFT
    address signer = _verify(voucher);
    
    //require(minter == signer, "unauthorized signer") //minter will be fetched from backedn throug IPFS minter

    require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

    _mintNft(voucher.tokenId,signer, voucher.uri, voucher.royaltyPercentage);

    _setTokenURI(voucher.tokenId, voucher.uri);

    _transfer( signer , redeemer, voucher.tokenId);



    pendingWithdrawals[signer] += msg.value;

    return voucher.tokenId;
  }

function withdraw() public {
    // require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can withdraw");
    address payable receiver = payable(msg.sender);

    uint amount = pendingWithdrawals[receiver];
    pendingWithdrawals[receiver] = 0;
    receiver.transfer(amount);
  }

  function availableToWithdraw() public view returns (uint256) {
    return pendingWithdrawals[msg.sender];
  }

  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri,uint256 royaltyPercentage)"),
      voucher.tokenId,
      voucher.minPrice,
      keccak256(bytes(voucher.uri)),
      voucher.royaltyPercentage
    )));
  }

  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
        id := chainid()
    }
    return id;
  }

  function _verify(NFTVoucher calldata voucher) public view returns (address) {
    // bytes32 digest = _hash(voucher);
    // return ECDSA.recover(digest, voucher.signature);
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri,uint256 royaltyPercentage)"),
            voucher.tokenId,
            voucher.minPrice,
            keccak256(bytes(voucher.uri)),
            voucher.royaltyPercentage
        )));
        address signer = ECDSA.recover(digest, voucher.signature);
        return signer;
  }
//[1, 50, "uriAb", "0xeff4ecfd86d3522e0ff7b1e25069b721c14dd2ef10dc5d2a9e97be42ebba8b1d0220bc898518abfa550ecf4b1b5bcdd0fa3a37c804e9fb0c9e6f01666d8a97331c"]
  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId);
  }

  function royaltyForToken(uint256 tokenId) external view returns (uint256 percentage){
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return(royalty[tokenId]);
    }
    // returns minter of a token
  function minterOfToken(uint256 tokenId) external view returns (address _minter){
        return(minter[tokenId]);
    }
    // sets uri for a token

    function setMaxRoyalty(uint256 _royalty) external onlyOwner{
        maximumRoyalty = _royalty;
    }
    
    function getNFTMintedByUser(address user) external view returns (uint256[] memory ids){
        return(mintedByUser[user]);
    }
}