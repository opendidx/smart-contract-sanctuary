pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d9bdb8afbc99b8b2b6b4bbb8f7bab6b4">[email&#160;protected]</a>
// released under Apache 2.0 licence
// input  /home/masa331/code/solidity/xixoio-contracts/contracts/TokenSale.sol
// flattened :  Thursday, 22-Nov-18 08:58:35 UTC
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

interface ITokenPool {
    function balanceOf(uint128 id) public view returns (uint256);
    function allocate(uint128 id, uint256 value) public;
    function withdraw(uint128 id, address to, uint256 value) public;
    function complete() public;
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
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

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

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract OperatorRole {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Can be called only by contract operator");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function _addOperator(address account) internal {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        operators.remove(account);
        emit OperatorRemoved(account);
    }
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract Pausable is Ownable {

    bool public paused = false;

    event Pause();
    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Has to be unpaused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Has to be paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is ERC20, Pausable {

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract IPCOToken is PausableToken, ERC20Detailed {
    uint256 public hardCap;

    /**
     * Token constructor, newly created token is paused
     * @dev decimals are hardcoded to 18
     */
    constructor(string _name, string _symbol, uint256 _hardCap) ERC20Detailed(_name, _symbol, 18) public {
        require(_hardCap > 0, "Hard cap can&#39;t be zero.");
        require(bytes(_name).length > 0, "Name must be defined.");
        require(bytes(_symbol).length > 0, "Symbol must be defined.");
        hardCap = _hardCap;
        pause();
    }

    /**
     * Minting function
     * @dev doesn&#39;t allow minting of more tokens than hard cap
     */
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(totalSupply().add(value) <= hardCap, "Mint of this amount would exceed the hard cap.");
        _mint(to, value);
        return true;
    }
}


contract TokenSale is Ownable, OperatorRole {
    using SafeMath for uint256;

    bool public finished = false;
    uint256 public dailyLimit = 100000 ether;
    mapping(uint256 => uint256) public dailyThroughput;

    IPCOToken public token;
    ITokenPool public pool;

    event TransactionId(uint128 indexed id);

    /**
     * Constructor
     * @dev contract depends on IPCO Token and Token Pool
     */
    constructor(address tokenAddress, address poolAddress) public {
        addOperator(msg.sender);
        token = IPCOToken(tokenAddress);
        pool = ITokenPool(poolAddress);
    }

    /**
     * @return Today&#39;s throughput of token, tracking both minted tokens and withdraws
     */
    function throughputToday() public view returns (uint256) {
        return dailyThroughput[currentDay()];
    }

    //
    // Limited functions for operators
    //

    function mint(address to, uint256 value, uint128 txId) public onlyOperator amountInLimit(value) {
        _mint(to, value, txId);
    }

    function mintToPool(uint128 account, uint256 value, uint128 txId) public onlyOperator amountInLimit(value) {
        _mintToPool(account, value, txId);
    }

    function withdraw(uint128 account, address to, uint256 value, uint128 txId) public onlyOperator amountInLimit(value) {
        _withdraw(account, to, value, txId);
    }

    function batchMint(address[] receivers, uint256[] values, uint128[] txIds) public onlyOperator amountsInLimit(values) {
        require(receivers.length > 0, "Batch can&#39;t be empty");
        require(receivers.length == values.length && receivers.length == txIds.length, "Invalid batch");
        for (uint i; i < receivers.length; i++) {
            _mint(receivers[i], values[i], txIds[i]);
        }
    }

    function batchMintToPool(uint128[] accounts, uint256[] values, uint128[] txIds) public onlyOperator amountsInLimit(values) {
        require(accounts.length > 0, "Batch can&#39;t be empty");
        require(accounts.length == values.length && accounts.length == txIds.length, "Invalid batch");
        for (uint i; i < accounts.length; i++) {
            _mintToPool(accounts[i], values[i], txIds[i]);
        }
    }

    function batchWithdraw(uint128[] accounts, address[] receivers, uint256[] values, uint128[] txIds) public onlyOperator amountsInLimit(values) {
        require(accounts.length > 0, "Batch can&#39;t be empty.");
        require(accounts.length == values.length && accounts.length == receivers.length && accounts.length == txIds.length, "Invalid batch");
        for (uint i; i < accounts.length; i++) {
            _withdraw(accounts[i], receivers[i], values[i], txIds[i]);
        }
    }

    //
    // Unrestricted functions for the owner
    //

    function unrestrictedMint(address to, uint256 value, uint128 txId) public onlyOwner {
        _mint(to, value, txId);
    }

    function unrestrictedMintToPool(uint128 account, uint256 value, uint128 txId) public onlyOwner {
        _mintToPool(account, value, txId);
    }

    function unrestrictedWithdraw(uint128 account, address to, uint256 value, uint128 txId) public onlyOwner {
        _withdraw(account, to, value, txId);
    }

    function addOperator(address operator) public onlyOwner {
        _addOperator(operator);
    }

    function removeOperator(address operator) public onlyOwner {
        _removeOperator(operator);
    }

    function replaceOperator(address operator, address newOperator) public onlyOwner {
        _removeOperator(operator);
        _addOperator(newOperator);
    }

    function setDailyLimit(uint256 newDailyLimit) public onlyOwner {
        dailyLimit = newDailyLimit;
    }

    /**
     * Concludes the sale - unpauses the token and renounces its ownership, effectively stopping minting indefinitely.
     * @dev theoretically sale can be run with an unpaused token
     */
    function finish() public onlyOwner {
        finished = true;
        if (token.paused()) token.unpause();
        pool.complete();
        token.renounceOwnership();
    }

    //
    // Internal functions
    //

    function _mint(address to, uint256 value, uint128 txId) internal {
        token.mint(to, value);
        emit TransactionId(txId);
    }

    function _mintToPool(uint128 account, uint256 value, uint128 txId) internal {
        token.mint(address(pool), value);
        pool.allocate(account, value);
        emit TransactionId(txId);
    }

    function _withdraw(uint128 account, address to, uint256 value, uint128 txId) internal {
        pool.withdraw(account, to, value);
        emit TransactionId(txId);
    }

    function _checkLimit(uint256 value) internal {
        uint256 newValue = throughputToday().add(value);
        require(newValue < dailyLimit, "Amount to be minted exceeds day limit.");
        dailyThroughput[currentDay()] = newValue;
    }

    //
    // Modifiers
    //

    modifier amountInLimit(uint256 value) {
        _checkLimit(value);
        _;
    }

    modifier amountsInLimit(uint256[] values) {
        uint256 sum = 0;
        for (uint i; i < values.length; i++) {
            sum = sum.add(values[i]);
        }
        _checkLimit(sum);
        _;
    }

    //
    // Private helpers
    //

    function currentDay() private view returns (uint256) {
        // solium-disable-next-line security/no-block-members, zeppelin/no-arithmetic-operations
        return now / 1 days;
    }
}