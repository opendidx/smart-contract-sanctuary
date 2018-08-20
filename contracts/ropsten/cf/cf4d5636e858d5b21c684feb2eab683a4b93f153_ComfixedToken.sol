// compiler: 0.4.21+commit.dfe3193c.Emscripten.clang
pragma solidity ^0.4.21;

// https://www.ethereum.org/token
interface tokenRecipient {
  function receiveApproval( address from, uint256 value, bytes data ) external;
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


// ERC223
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

// ERC20 token with added ERC223 and Ethereum-Token support
//
// Blend of multiple interfaces:
// - https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// - https://www.ethereum.org/token (uncontrolled, non-standard)
// - https://github.com/Dexaran/ERC23-tokens/blob/Recommended/ERC223_Token.sol

contract ComfixedToken
{
 // using SafeMath for uint;

  string  public name;
  string  public symbol;
  uint256 public totalBonus;
  address _owner;
  uint8   public decimals;
  uint256 public totalSupply;


  mapping( address => uint256 ) balances_;
  mapping( address => mapping(address => uint256) ) allowances_;

  // ERC20
  event Approval( address indexed owner,
                  address indexed spender,
                  uint value );

  event Transfer( address indexed from,
                  address indexed to,
                  uint256 value );
               // bytes    data ); use ERC20 version instead

  // Ethereum Token
  event Burn( address indexed from, uint256 value );

  constructor ( uint256 initialSupply,
                        uint256 initialBonus,
                        string tokenName,
                        uint8 decimalUnits,
                        string tokenSymbol ) public
  {
    
    totalBonus = initialBonus * 10 ** uint256(decimalUnits);
    totalSupply = SafeMath.add(initialSupply, initialBonus) * (10 ** uint256(decimalUnits));
    balances_[msg.sender] = totalSupply;
    name = tokenName;
    _owner = msg.sender;
    decimals = decimalUnits;
    symbol = tokenSymbol;
    emit Transfer( address(0), msg.sender, totalSupply );
  }

  function() public payable { revert(); } // does not accept money

  // ERC20
  function balanceOf( address owner ) public constant returns (uint) {
    return balances_[owner];
  }

  // ERC20
  //
  // WARNING! When changing the approval amount, first set it back to zero
  // AND wait until the transaction is mined. Only afterwards set the new
  // amount. Otherwise you may be prone to a race condition attack.
  // See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

  function approve( address spender, uint256 value ) public
  returns (bool success)
  {
    allowances_[msg.sender][spender] = value;
    emit Approval( msg.sender, spender, value );
    return true;
  }
 
  // recommended fix for known attack on any ERC20
  function safeApprove( address _spender,
                        uint256 _currentValue,
                        uint256 _value ) public
                        returns (bool success) {

    // If current allowance for _spender is equal to _currentValue, then
    // overwrite it with _value and return true, otherwise return false.

    if (allowances_[msg.sender][_spender] == _currentValue)
      return approve(_spender, _value);

    return false;
  }

  // ERC20
  function allowance( address owner, address spender ) public constant
  returns (uint256 remaining)
  {
    return allowances_[owner][spender];
  }

  // ERC20
  function transfer(address to, uint256 value) public returns (bool success)
  {
    bytes memory empty; // null
    _transfer( msg.sender, to, value, empty );
    return true;
  }

  // ERC20
  function transferFrom( address from, address to, uint256 value ) public
  returns (bool success)
  {
    require( value <= allowances_[from][msg.sender] );

    allowances_[from][msg.sender] -= value;
    bytes memory empty;
    _transfer( from, to, value, empty );

    return true;
  }


    modifier onlyOwner(){
            require(msg.sender == _owner);
            _;
        }

    function updateReferralBonus( uint256 refBonus) onlyOwner public returns (bool success){
        uint256 refDeciBonus = refBonus * 10 ** uint256(decimals); 
        totalSupply += refDeciBonus;
        //  bytes memory empty; // null
         balances_[msg.sender] += refDeciBonus; 
        emit Transfer( address(0), msg.sender, refDeciBonus);  
        // _transfer( address(0), msg.sender, , empty );
        return true;
    }


  function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        uint256 _leftOverTokens = balances_[msg.sender];
        bytes memory empty; // null
        _transfer(msg.sender, newOwner, _leftOverTokens, empty);
        // Transfer(msg.sender, newOwner, _leftOverTokens);     
        _owner = newOwner;
    }

    function distributeToken(address[] addresses, uint256[] _value) onlyOwner public {
         bytes memory empty; // null
        for (uint i = 0; i < addresses.length; i++) {
        _transfer(msg.sender, addresses[i], _value[i] * 10 ** uint256(decimals), empty);
        }
    }





  // Ethereum Token
  function approveAndCall( address spender,
                           uint256 value,
                           bytes context ) public
  returns (bool success)
  {
    if ( approve(spender, value) )
    {
      tokenRecipient recip = tokenRecipient( spender );
      recip.receiveApproval( msg.sender, value, context );
      return true;
    }
    return false;
  }        

  // Ethereum Token
  function burn( uint256 value ) public
  returns (bool success)
  {
    require( balances_[msg.sender] >= value );
    balances_[msg.sender] -= value;
    totalSupply -= value;

    emit Burn( msg.sender, value );
    return true;
  }

  // Ethereum Token
  function burnFrom( address from, uint256 value ) public
  returns (bool success)
  {
    require( balances_[from] >= value );
    require( value <= allowances_[from][msg.sender] );

    balances_[from] -= value;
    allowances_[from][msg.sender] -= value;
    totalSupply -= value;

    emit Burn( from, value );
    return true;
  }

  // ERC223 Transfer and invoke specified callback
  function transfer( address to,
                     uint value,
                     bytes data,
                     string custom_fallback ) public returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    if ( isContract(to) )
    {
      ContractReceiver rx = ContractReceiver( to );
      require( address(rx).call.value(0)(bytes4(keccak256(abi.encodePacked(custom_fallback))),
               msg.sender,
               value,
               data) );
    }

    return true;
  }

  // ERC223 Transfer to a contract or externally-owned account
  function transfer( address to, uint value, bytes data ) public
  returns (bool success)
  {
    if (isContract(to)) {
      return transferToContract( to, value, data );
    }

    _transfer( msg.sender, to, value, data );
    return true;
  }

  // ERC223 Transfer to contract and invoke tokenFallback() method
  function transferToContract( address to, uint value, bytes data ) private
  returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    ContractReceiver rx = ContractReceiver(to);
    rx.tokenFallback( msg.sender, value, data );

    return true;
  }

  


  // ERC223 fetch contract size (must be nonzero to be a contract)
  function isContract( address _addr ) private constant returns (bool)
  {
    uint length;
    assembly { length := extcodesize(_addr) }
    return (length > 0);
  }

  function _transfer( address from,
                      address to,
                      uint value,
                      bytes data ) internal
  {
    require( to != 0x0 );
    require( balances_[from] >= value );
    require( balances_[to] + value > balances_[to] ); // catch overflow

    balances_[from] -= value;
    balances_[to] += value;

    //Transfer( from, to, value, data ); ERC223-compat version
    bytes memory empty;
    empty = data;
    emit Transfer( from, to, value ); // ERC20-compat version
  }
}