pragma solidity ^0.4.18;

import "./ERC721.sol";

contract MyNonFungibleToken is ERC721 {
  /*** CONSTANTS ***/

  string public constant name = "MyNonFungibleToken";
  string public constant symbol = "MNFT";

  bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));


  /*** DATA TYPES ***/

  struct Token {
    uint64 mintedAt;
  }


  /*** STORAGE ***/

  Token[] tokens;

  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;
  mapping (uint256 => address) public tokenIndexToApproved;


  /*** EVENTS ***/

  event Mint(address owner, uint256 tokenId);
  event Transfer(address from, address to, uint256 tokenId);
  event Approval(address owner, address approved, uint256 tokenId);


  /*** INTERNAL FUNCTIONS ***/

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToApproved[_tokenId] == _claimant;
  }

  function _approve(uint256 _tokenId, address _approved) internal {
    tokenIndexToApproved[_tokenId] = _approved;

    Approval(tokenIndexToOwner[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownershipTokenCount[_to]++;
    tokenIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      delete tokenIndexToApproved[_tokenId];
    }

    Transfer(_from, _to, _tokenId);
  }

  function _createToken(address _owner) internal returns (uint256) {
    Token memory _token = Token({
      mintedAt: uint64(now)
    });
    uint256 newTokenId = tokens.push(_token) - 1;

    require(newTokenId == uint256(uint32(newTokenId)));

    Mint(_owner, newTokenId);

    _transfer(0, _owner, newTokenId);

    return newTokenId;
  }


  /*** ERC721 IMPLEMENTATION ***/

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function totalSupply() public view returns (uint) {
    return tokens.length;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view returns (address owner) {
    owner = tokenIndexToOwner[_tokenId];

    require(owner != address(0));
  }

  function approve(address _to, uint256 _tokenId) external {
    require(_owns(msg.sender, _tokenId));

    _approve(_tokenId, _to);
  }

  function transfer(address _to, uint256 _tokenId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_owns(msg.sender, _tokenId));

    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));

    _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address _owner) external view returns (uint256[]) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 1; tokenId <= totalTokens; tokenId++) {
        if (tokenIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
    }

    return result;
  }

  function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string) {
    return "";
  }


  /*** OTHER EXTERNAL FUNCTIONS ***/

  function mint() external returns (uint256) {
    return _createToken(msg.sender);
  }
}
