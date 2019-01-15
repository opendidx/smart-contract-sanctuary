pragma solidity ^0.4.24;

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}


contract ContractReceiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract IERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal _supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(_InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) public view returns (string);
}

contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param owner owner of the token
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  /**
   * @dev Constructor function
   */
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return _name;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 tokenId) public view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  /**
   * @dev Constructor function
   */
  constructor() public {
    // register the supported interface to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    _ownedTokens[from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to address the beneficiary that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Reorg all tokens array
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

contract ERC721Mintable is ERC721Full, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param tokenId The token id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 tokenId
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, tokenId);
    return true;
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string tokenURI
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    mint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

contract Secondary {
  address private _primary;

  /**
   * @dev Sets the primary account to the one that is creating the Secondary contract.
   */
  constructor() public {
    _primary = msg.sender;
  }

  /**
   * @dev Reverts if called from any account other than the primary.
   */
  modifier onlyPrimary() {
    require(msg.sender == _primary);
    _;
  }

  function primary() public view returns (address) {
    return _primary;
  }

  function transferPrimary(address recipient) public onlyPrimary {
    require(recipient != address(0));

    _primary = recipient;
  }
}

// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cbafaabdae8baaa0a4a6a9aae5a8a4a6">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract ILicenseNFTProxiable {
  function split(
    address tokenOwner,
    uint256 tokenId,
    uint256 secondTokenId,
    uint256 secondDurationSec
  ) public returns(bool);

  function merge(
    address tokenOwner,
    uint256 tokenId,
    uint256 secondTokenId
  ) public returns(bool);

  function setSealableProperty(
    address tokenOwner,
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) public returns(bool);

  function seal(
    address dataStreamSealer,
    address tokenOwner,
    uint256 tokenId
  ) public returns(bool);
}

contract ILicenseNFTSealer {
   // @return `bytes4(keccak256("onSealed(address,address,uint256)"))`
  function onSealed(address licenseNFT, address tokenOwner, uint256 tokenId) public returns(bytes4);
}

contract ILicenseNFT is ERC721Mintable {
  // keccak256(abi.encodePacked("splitParent"))
  bytes32 public constant SPLIT_PARENT_KEY = 0x82f1bb612577f02f2d28d75a6004227778388d11803f2c7faa961f947a84c847;

  // keccak256(abi.encodePacked("durationSec"))
  bytes32 public constant DURATION_SEC_KEY = 0x3354b151081a5dc2572c75853a10ef902217550496efb2ffa54494ae9b3ab99c;

  // keccak256(abi.encodePacked("bidHash"))
  bytes32 public constant BID_HASH_KEY = 0x4eba03e4695ef490bd0d99b2e8fa2d0aa4c54ddfc1a74b32febd9142981e7176;

  event Sealed(uint256 tokenId);

  function mintableProperties(uint256 tokenId, bytes32 key) public view returns(bytes32);
  function sealableProperties(uint256 tokenId, bytes32 key) public view returns(bytes32);
  function tokenSealer(uint256 tokenId) public view returns(address);

  function setMintableProperty(
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) public returns(bool);

  function split(uint256 tokenId, uint256 secondTokenId, uint256 secondDuration) public returns(bool);
  function merge(uint256 tokenId, uint256 secondTokenId) public returns(bool);

  function setSealableProperty(
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) public returns(bool);

  function seal(address dataStreamSealer, uint256 tokenId) public returns(bool);
}

contract ProxyManagerRole {
  using Roles for Roles.Role;

  event ProxyManagerAdded(address indexed account);
  event ProxyManagerRemoved(address indexed account);

  Roles.Role private proxyManagers;

  constructor() public {
    proxyManagers.add(msg.sender);
  }

  modifier onlyProxyManager() {
    require(isProxyManager(msg.sender));
    _;
  }

  function isProxyManager(address account) public view returns (bool) {
    return proxyManagers.has(account);
  }

  function addProxyManager(address account) public onlyProxyManager {
    proxyManagers.add(account);
    emit ProxyManagerAdded(account);
  }

  function renounceProxyManager() public {
    proxyManagers.remove(msg.sender);
  }

  function _removeProxyManager(address account) internal {
    proxyManagers.remove(account);
    emit ProxyManagerRemoved(account);
  }
}

contract Proxiable is ProxyManagerRole {
  mapping(address => bool) private _globalProxies; // proxy -> valid
  mapping(address => mapping(address => bool)) private _senderProxies; // sender -> proxy -> valid

  event ProxyAdded(address indexed proxy, uint256 updatedAt);
  event ProxyRemoved(address indexed proxy, uint256 updatedAt);
  event ProxyForSenderAdded(address indexed proxy, address indexed sender, uint256 updatedAt);
  event ProxyForSenderRemoved(address indexed proxy, address indexed sender, uint256 updatedAt);

  modifier proxyOrSender(address claimedSender) {
    require(isProxyOrSender(claimedSender));
    _;
  }

  function isProxyOrSender(address claimedSender) public view returns (bool) {
    return msg.sender == claimedSender ||
    _globalProxies[msg.sender] ||
    _senderProxies[claimedSender][msg.sender];
  }

  function isProxy(address proxy) public view returns (bool) {
    return _globalProxies[proxy];
  }

  function isProxyForSender(address proxy, address sender) public view returns (bool) {
    return _senderProxies[sender][proxy];
  }

  function addProxy(address proxy) public onlyProxyManager {
    require(!_globalProxies[proxy]);
    _globalProxies[proxy] = true;
    emit ProxyAdded(proxy, now); // solhint-disable-line
  }

  function removeProxy(address proxy) public onlyProxyManager {
    require(_globalProxies[proxy]);
    delete _globalProxies[proxy];
    emit ProxyRemoved(proxy, now); // solhint-disable-line
  }

  function addProxyForSender(address proxy, address sender) public proxyOrSender(sender) {
    require(!_senderProxies[sender][proxy]);
    _senderProxies[sender][proxy] = true;
    emit ProxyForSenderAdded(proxy, sender, now); // solhint-disable-line
  }

  function removeProxyForSender(address proxy, address sender) public proxyOrSender(sender) {
    require(_senderProxies[sender][proxy]);
    delete _senderProxies[sender][proxy];
    emit ProxyForSenderRemoved(proxy, sender, now); // solhint-disable-line
  }
}

contract LicenseNFT is ILicenseNFT {
  event Sealed(uint256 tokenId);

  string private constant NFT_NAME = "Open City License NFT";
  string private constant NFT_SYMBOL = "OCL";

  // Mapping from token ID to key to value
  mapping(uint256 => mapping(bytes32 => bytes32)) private _mintableProperties;
  mapping(uint256 => mapping(bytes32 => bytes32)) private _sealableProperties;

  // Mapping from token Id to sealer address
  mapping(uint256 => address) private _tokenSealer;

  // `bytes4(keccak256("onSealed(address,address,uint256)"))`
  bytes4 private constant LICENSENFT_SEALED = 0x8f3de282;

  modifier onlyTokenOwner(uint256 tokenId) {
    require(ownerOf(tokenId) == msg.sender);
    _;
  }

  // solhint-disable-next-line
  constructor() public ERC721Full(NFT_NAME, NFT_SYMBOL) {}

  function mintableProperties(uint256 tokenId, bytes32 key) public view returns(bytes32) {
    uint256 splitParent = uint256(_mintableProperties[tokenId][SPLIT_PARENT_KEY]);
    if (splitParent == 0 || key == SPLIT_PARENT_KEY || key == DURATION_SEC_KEY) {
      return _mintableProperties[tokenId][key];
    } else {
      return _mintableProperties[splitParent][key];
    }
  }

  function sealableProperties(uint256 tokenId, bytes32 key) public view returns(bytes32) {
    return _sealableProperties[tokenId][key];
  }

  function tokenSealer(uint256 tokenId) public view returns(address) {
    return _tokenSealer[tokenId];
  }

  function transferFrom(address, address, uint256) public {
    revert();
  }

  function setMintableProperty(
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) public onlyMinter onlyBeforeMintingFinished returns(bool) {
    require(!_exists(tokenId));
    _mintableProperties[tokenId][key] = value;
    return true;
  }

  function split(
    uint256 tokenId,
    uint256 secondTokenId,
    uint256 secondDurationSec
  ) public onlyTokenOwner(tokenId) returns(bool) {
    return _split(tokenId, secondTokenId, secondDurationSec);
  }

  function merge(
    uint256 firstTokenId,
    uint256 secondTokenId
  ) public onlyTokenOwner(firstTokenId) onlyTokenOwner(secondTokenId) returns(bool) {
    return _merge(firstTokenId, secondTokenId);
  }

  function setSealableProperty(
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) public onlyTokenOwner(tokenId) returns(bool) {
    return _setSealableProperty(tokenId, key, value);
  }

  function seal(
    address dataStreamSealer,
    uint256 tokenId
  ) public onlyTokenOwner(tokenId) returns(bool) {
    return _seal(dataStreamSealer, msg.sender, tokenId);
  }

  function _split(
    uint256 tokenId,
    uint256 secondTokenId,
    uint256 secondDurationSec
  ) internal returns(bool) {
    require(_exists(tokenId) && !_exists(secondTokenId));
    require(_tokenSealer[tokenId] == 0);
    require(_mintableProperties[secondTokenId][DURATION_SEC_KEY] == 0);
    require(_mintableProperties[secondTokenId][SPLIT_PARENT_KEY] == 0);

    uint256 durationSec = uint256(_mintableProperties[tokenId][DURATION_SEC_KEY]);
    require(secondDurationSec < durationSec);

    uint256 firstDurationSec = durationSec - secondDurationSec;
    _mintableProperties[tokenId][DURATION_SEC_KEY] = bytes32(firstDurationSec);
    _mintableProperties[secondTokenId][DURATION_SEC_KEY] = bytes32(secondDurationSec);

    bytes32 splitParent = _mintableProperties[tokenId][SPLIT_PARENT_KEY];
    if (splitParent == 0) {
      splitParent = bytes32(tokenId);
    }
    _mintableProperties[secondTokenId][SPLIT_PARENT_KEY] = splitParent;

    _mint(ownerOf(tokenId), secondTokenId);
    return true;
  }

  function _merge(uint256 tokenId, uint256 secondTokenId) internal returns(bool) {
    require(tokenId != secondTokenId);
    require(ownerOf(tokenId) == ownerOf(secondTokenId));
    require(_tokenSealer[tokenId] == 0 && _tokenSealer[secondTokenId] == 0);

    bytes32 firstSplitParent = _mintableProperties[tokenId][SPLIT_PARENT_KEY];
    bytes32 secondSplitParent = _mintableProperties[secondTokenId][SPLIT_PARENT_KEY];

    require(secondSplitParent != 0);
    require(bytes32(tokenId) == secondSplitParent || firstSplitParent == secondSplitParent);

    uint256 firstDurationSec = uint256(_mintableProperties[tokenId][DURATION_SEC_KEY]);
    uint256 secondDurationSec = uint256(_mintableProperties[secondTokenId][DURATION_SEC_KEY]);

    uint256 totalDuration = firstDurationSec + secondDurationSec;
    _mintableProperties[secondTokenId][DURATION_SEC_KEY] = 0x0;
    _mintableProperties[tokenId][DURATION_SEC_KEY] = bytes32(totalDuration);

    _burn(ownerOf(secondTokenId), secondTokenId);
    return true;
  }

  function _burn(address owner, uint256 tokenId) internal {
    require(_exists(tokenId));
    delete _mintableProperties[tokenId][SPLIT_PARENT_KEY];
    delete _mintableProperties[tokenId][DURATION_SEC_KEY];
    delete _tokenSealer[tokenId];

    _clearApproval(owner, tokenId);
    require(ownerOf(tokenId) == owner);
    require(1 <= balanceOf(owner));
    _removeTokenFrom(owner, tokenId);
    //_removeTokenFrom(owner, tokenId);
    //emit Transfer(owner, address(0), tokenId);
    //super._burn(owner, tokenId);
  }

  function _setSealableProperty(
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) internal returns(bool) {
    require(_tokenSealer[tokenId] == 0x0);
    _sealableProperties[tokenId][key] = value;
    return true;
  }

  function _seal(
    address dataStreamSealer,
    address tokenOwner,
    uint256 tokenId
  ) internal returns(bool) {
    require(_tokenSealer[tokenId] == 0x0);

    _tokenSealer[tokenId] = dataStreamSealer;

    require(_checkSeal(this, dataStreamSealer, tokenOwner, tokenId));

    emit Sealed(tokenId);
    return true;
  }

  function _checkSeal(
    address licenseNFT,
    address sealer,
    address tokenOwner,
    uint256 tokenId
  ) internal returns(bool) {
    bytes4 retval = ILicenseNFTSealer(sealer).onSealed(licenseNFT, tokenOwner, tokenId);
    return (retval == LICENSENFT_SEALED);
  }
}

contract LicenseNFTProxiable is ILicenseNFTProxiable, LicenseNFT, Proxiable {
  modifier onlyClaimedTokenOwner(address tokenOwner, uint256 tokenId) {
    require(ownerOf(tokenId) == tokenOwner);
    _;
  }

  function split(
    address tokenOwner,
    uint256 tokenId,
    uint256 secondTokenId,
    uint256 secondDurationSec
  ) public proxyOrSender(tokenOwner) onlyClaimedTokenOwner(tokenOwner, tokenId) returns(bool) {
    return _split(tokenId, secondTokenId, secondDurationSec);
  }

  function merge(
    address tokenOwner,
    uint256 tokenId,
    uint256 secondTokenId
  ) public
    proxyOrSender(tokenOwner)
    onlyClaimedTokenOwner(tokenOwner, tokenId)
    onlyClaimedTokenOwner(tokenOwner, secondTokenId) 
    returns(bool)
  {
    return _merge(tokenId, secondTokenId);
  }

  function setSealableProperty(
    address tokenOwner,
    uint256 tokenId,
    bytes32 key,
    bytes32 value
  ) public proxyOrSender(tokenOwner) onlyClaimedTokenOwner(tokenOwner, tokenId) returns(bool) {
    return _setSealableProperty(tokenId, key, value);
  }

  function seal(
    address dataStreamSealer,
    address tokenOwner,
    uint256 tokenId
  ) public proxyOrSender(tokenOwner) onlyClaimedTokenOwner(tokenOwner, tokenId) returns(bool) {
    return _seal(dataStreamSealer, tokenOwner, tokenId);
  }
}