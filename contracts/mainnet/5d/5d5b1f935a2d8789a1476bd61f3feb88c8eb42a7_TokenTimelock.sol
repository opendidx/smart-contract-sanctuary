pragma solidity ^0.4.23;

contract Clockmaking {
	address public clockmaker;
	address public newClockmaker;

	event ClockmakingTransferred(address indexed oldClockmaker, address indexed newClockmaker);

	constructor() public {
		clockmaker = msg.sender;
		newClockmaker = address(0);
	}

	modifier onlyClockmaker() {
		require(msg.sender == clockmaker, &quot;msg.sender == clockmaker&quot;);
		_;
	}

	function transferClockmaker(address _newClockmaker) public onlyClockmaker {
		require(address(0) != _newClockmaker, &quot;address(0) != _newClockmaker&quot;);
		newClockmaker = _newClockmaker;
	}

	function acceptClockmaker() public {
		require(msg.sender == newClockmaker, &quot;msg.sender == newClockmaker&quot;);
		emit ClockmakingTransferred(clockmaker, msg.sender);
		clockmaker = msg.sender;
		newClockmaker = address(0);
	}
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, &quot;msg.sender == owner&quot;);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, &quot;address(0) != _newOwner&quot;);
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, &quot;msg.sender == newOwner&quot;);
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract ERC20Basic {
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock is Ownable, Clockmaking {
  using SafeERC20 for ERC20Basic;
  ERC20Basic public token;   // ERC20 basic token contract being held
  uint64 public releaseTime; // timestamp when token claim is enabled

  constructor(ERC20Basic _token, uint64 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    owner = msg.sender;
    clockmaker = msg.sender;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to owner.
   */
  function claim() public onlyOwner {
    require(now >= releaseTime, &quot;now >= releaseTime&quot;);

    uint256 amount = token.balanceOf(this);
    require(amount > 0, &quot;amount > 0&quot;);

    token.safeTransfer(owner, amount);
  }
  
  function updateTime(uint64 _releaseTime) public onlyClockmaker {
      releaseTime = _releaseTime;
  }
  
}