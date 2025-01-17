pragma solidity 0.4.25;

// File: contracts/lib/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

// File: contracts/lib/SafeMath.sol

/// @title SafeMath v0.1.9
/// @dev Math operations with safety checks that throw on error
/// change notes: original SafeMath library from OpenZeppelin modified by Inventor
/// - added sqrt
/// - added sq
/// - added pwr 
/// - changed asserts to requires with error log outputs
/// - removed div, its useless
library SafeMath {
    
    /// @dev Multiplies two numbers, throws on overflow.
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }


    /// @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }


    /// @dev Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    

    /// @dev gives square root of given x.
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }


    /// @dev gives square. multiplies x by x
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }


    /// @dev x to the power of y 
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x == 0) {
            return (0);
        } else if (y == 0) {
            return (1);
        } else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) {
                z = mul(z,x);
            }
            return (z);
        }
    }
}

// File: contracts/TinyBanker.sol

// 这是个简化版的Banker，只是为了对接接口，正式使用待议

contract TinyBanker is Ownable {
    using SafeMath for uint256;

    event RefundValue(address, uint256 value);
    event DepositValue(address investor, uint256 value);

    address public wallet;

    constructor(address _wallet)
        public
    {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    mapping (address => uint256) public deposited;

    function deposit(address investor) public payable {
        emit DepositValue(investor, msg.value);
    }

    function setWallet(address _wallet) onlyOwner public  {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function withDraw() onlyOwner public {
        wallet.transfer(address(this).balance);
        emit RefundValue(wallet, address(this).balance);
    }
}