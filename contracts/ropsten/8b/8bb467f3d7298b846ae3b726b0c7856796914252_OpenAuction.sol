pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        _owner = msg.sender;
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
        emit OwnershipRenounced(_owner);
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


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


contract OpenAuction is Pausable {
    using SafeMath for uint256;

    // campaign states
    enum State {
        Running,
        Closed
    }

    State public state = State.Running;

    address public creator;
    address public highestAddress;
    address public bidRecipient;
    uint256 public highest = 0;
    uint256 public minPrice = 0;
    uint256 public stepPrice = 0;
    string public campaignUrl;

    uint256 public totalBid = 0;
    uint256 public currentBalance = 0;

    uint256 public biddingStartTime = 0;
    uint256 public biddingEndTime = 0;

    address[] public biddingAddress;
    mapping(address => uint256) public biddingAmount;

    event LogFundingReceived(address addr, uint256 amount, uint256 currentTotal);
    event LogWinnerPaid(address winnerAddress);
    event LogAuctionInitialized(address creator, address bidRecipient, uint256 minPrice, string campaignUrl, uint256 biddingStartTime, uint256 biddingEndTime, uint stepPrice);
    event AuctionClosed(address highestAddress, uint highest);

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    // Wait 1 day after final contract state before allowing contract destruction
    modifier atEndOfLifecycle() {
        require(state == State.Closed || biddingEndTime + 1 days >= now);
        _;
    }

    constructor(address _bidRecipient, uint256 _minPrice, string _campaignUrl, uint256 _biddingStartTime, uint256 _biddingEndTime, uint256 _stepPrice) public {
        creator = msg.sender;
        bidRecipient = _bidRecipient;
        minPrice = _minPrice;
        stepPrice = _stepPrice;
        campaignUrl = _campaignUrl;
        biddingStartTime = _biddingStartTime;
        biddingEndTime = _biddingEndTime;
        currentBalance = 0;
        highest = 0;
        emit LogAuctionInitialized(creator, bidRecipient, minPrice, campaignUrl, biddingStartTime, biddingEndTime, stepPrice);
    }

    function() public payable {
        bid(msg.sender, msg.value);
    }

    function bid(address _contributor, uint256 _value) public returns (bool success) {
        require(state != State.Closed);
        require(_value > 0);
        require(_value >= stepPrice);
        require(biddingStartTime == 0 || now >= biddingStartTime);
        require(biddingEndTime == 0 || now <= biddingEndTime);

        uint256 prevAmt = biddingAmount[_contributor];
        uint256 biddingAmt = _value;

        require(biddingAmt.add(prevAmt) > highest, "Not high enough");

        biddingAmount[_contributor] = biddingAmt.add(prevAmt);
        highest = biddingAmount[_contributor];
        highestAddress = _contributor;

        totalBid = totalBid.add(biddingAmt);
        currentBalance = currentBalance.add(biddingAmt);
        biddingAddress.push(_contributor);

        return true;
    }

    function closeAuction() public {
        require(now >= biddingEndTime, "Auction not time up yet!");
        require(state != State.Closed, "Auction Closed");
        state = State.Closed;
        emit AuctionClosed(highestAddress, highest);
    }
}