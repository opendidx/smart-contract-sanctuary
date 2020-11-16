pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract KYC is Ownable{
    
    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);
    
    struct ERCToken{
        bool isLocked;
        address addr;
        string name;
    }
    
    struct ExpectedTransfer{
        bool isPaid;
        uint expectedFee;
        uint expectedTime;
        bool isEth;
        address inComingAddress;
    }
    
    struct Customer {
        address addr;
        bool isLocked;
        uint expiredTime;
        bytes32 signature;
        address[] expectedAddresses;
        uint count;
        mapping( uint => ExpectedTransfer) expectedInfo;
    }
    
    string public partnerName;
    address private partnerAddress;

    address private WLAddress;
    
    mapping(address => Customer) private customers;
    mapping(address => address) private linkedAddress;
    mapping(address => ERCToken) private tokens;
    
    uint256 private totalIncomingWei = 0;
    uint256 private totalOutgoingWei = 0;
    
    
    // BEGIN OF CUSTOMERS VALIDATIONS
    
    modifier isCustomerNotAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr == ZERO_ADDRESS);
        require(linkedAddress[addr] == ZERO_ADDRESS);
        _;
    }
    
    modifier isCustomerAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr != ZERO_ADDRESS);
        require(linkedAddress[addr] == addr);
        _;
    }
    
    modifier checkSecondaryAddress(address secondaryAddress){
        require(secondaryAddress != ZERO_ADDRESS);
        require(linkedAddress[secondaryAddress] == ZERO_ADDRESS);
        _;
    }
    
    modifier isSecondaryAddrAdded(address addr, address secondaryAddress){
        require(addr != ZERO_ADDRESS);
        require(secondaryAddress != ZERO_ADDRESS);
        require(secondaryAddress != addr);
        require(linkedAddress[secondaryAddress] == addr);
        _;
    }
    modifier verifiedCustomer(uint _expiredTime, bytes32 _signature) {
        require(_expiredTime > now);
        require(_signature !=ZERO_BYTES);
        _;
    }
    
    modifier isLockedCustomer(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].isLocked);
        _;
    }
    
    modifier isUnLockedCustomer(address addr) {
        require(addr != ZERO_ADDRESS);
        require(!customers[addr].isLocked);
        _; 
    }
    
    modifier isWaitingFee(address addr) {
        require(addr != ZERO_ADDRESS);
        require(customers[addr].addr != ZERO_ADDRESS);
        //require(!customers[addr].isPayed);
        _;
    }
    
    // END OF CUSTOMER VALIDATIONS
    
    // BEGIN OF WHITELIST CONTRACT ADDRESS VALIDATIONS
    /*
    modifier isWhiteListAddress(address newAddr, address oldAddr) {
        require(newAddr != ZERO_ADDRESS);
        require(newAddr != oldAddr);
        require(WLAddress == oldAddr);
        _;
    }
    */
    
    modifier isValidAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isWLAddress(address addr) {
        require(addr == WLAddress);
        _;
    }
    
    // END OF WHITELIST CONTRACT ADDRESS VALIDATIONS
    
    // BEGIN OF ERCTOKEN VALIDATIONS
    
    modifier isContract(address addr){
        require(AddressUtils.isContract(addr));
        _;
    }
    
    modifier isTokenNotAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(tokens[addr].addr == ZERO_ADDRESS);
        _;
    }
    
    modifier isTokenAdded(address addr) {
        require(addr != ZERO_ADDRESS);
        require(tokens[addr].addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isLockedToken(address addr) {
        require(addr != ZERO_ADDRESS);
        require(tokens[addr].isLocked);
        _;
    }
    
    modifier isUnLockedToken(address addr) {
        require(addr != ZERO_ADDRESS);
        require(!tokens[addr].isLocked);
        _; 
    }
    
    // END OF ERCTOKEN VALIDATIONS
    
    // BEGIN OF TRANSFER VALIDATIONS
    
    modifier isAvailableTokenBalance(address tokenAddr, uint tokenAmount) {
        require(tokenAmount > 0);
        require(ERC20(tokenAddr).balanceOf(this) >= tokenAmount);
        _;
    }
    
    modifier isAvailableETHBalance(uint amount) {
        require(amount > 0);
        require(address(this).balance > amount);
        _;
    }
    
    // END OF TRANSFER VALIDATIONS
    
    
    constructor(string _name, address _address, address _wlAddress) public isValidAddress(_address) isContract(_wlAddress) {
        partnerName = _name;
        partnerAddress = _address; 
        WLAddress = _wlAddress;
    }
    
    //BEGIN OF WHITELIST FUNCTIONS
    
    function getWLAddress() public view onlyOwner returns(address){
        return WLAddress;
    }
    
    function setWLAddress(address _wlAddress) public onlyOwner isValidAddress(_wlAddress) isContract(_wlAddress) returns(bool){
        WLAddress = _wlAddress;
        return true;
    }
    
    //END OF WHITELIST FUNCTIONS
    
    // BEGIN OF CUSTOMERS FUNCTIONS
    
    function addCustomerwithETH(address customerAddress, uint expectedFee, uint expectedTime) public onlyOwner isCustomerNotAdded(customerAddress) returns (bool){
        address[] memory addressList = new address[](1);
        addressList[0] = customerAddress;
        customers[customerAddress] = Customer(customerAddress, false, now, ZERO_BYTES, addressList, 1);
        customers[customerAddress].expectedInfo[1]=ExpectedTransfer(false, expectedFee, expectedTime, true, ZERO_ADDRESS);
        linkedAddress[customerAddress] = customerAddress;
        return true;
    }

    function addCustomerwithToken(address customerAddress, uint expectedFee, address tokenContractAddress) public onlyOwner isCustomerNotAdded(customerAddress) returns (bool){
        address[] memory addressList = new address[](1);
        addressList[0] = customerAddress;
        customers[customerAddress] = Customer(customerAddress, false, now, ZERO_BYTES, addressList, 1);
        customers[customerAddress].expectedInfo[1]=ExpectedTransfer(true, expectedFee, 0, false, tokenContractAddress);
        linkedAddress[customerAddress] = customerAddress;
        return true;
    }
    
    /*
    function addCustomerWithSecondaryAddress(address primaryAddress, address secondaryAddress, uint expectedFee, uint expectedTime) public onlyOwner
        isCustomerNotAdded(primaryAddress) checkSecondaryAddress(primaryAddress) checkSecondaryAddress(secondaryAddress) returns (bool){
            address[] memory addressList = new address[](2);
            addressList[0] = primaryAddress;
            addressList[1] = secondaryAddress;
            ExpectedTransfer memory eT = ExpectedTransfer(true, expectedFee, expectedTime, addressList);
            customers[primaryAddress] = Customer(primaryAddress, false, now, ZERO_BYTES, eT);
            linkedAddress[secondaryAddress] = primaryAddress;
            return true;
    }
    */
    
    function addSecondaryAddress(address _customerAddress, address _secondaryAddress) public onlyOwner isCustomerAdded(_customerAddress) 
        checkSecondaryAddress(_secondaryAddress) returns(bool){
            Customer storage c = customers[_customerAddress];
            c.expectedAddresses.push(_secondaryAddress);
            linkedAddress[_secondaryAddress] = _customerAddress;
            return true;
    }
    
    function setETHExpectedFee(address _customerAddress, uint expectedFee, uint expectedTime) public onlyOwner isCustomerAdded(_customerAddress)
        returns(bool){
            Customer storage c = customers[_customerAddress];
            c.count = c.count+1;
            c.expectedInfo[c.count]=ExpectedTransfer(false, expectedFee, expectedTime, true, ZERO_ADDRESS);
            return true;
    }
    
    function setTokenExpectedFee(address _customerAddress, uint expectedFee, uint expectedTime, address tokenContractAddress) public onlyOwner
        isCustomerAdded(_customerAddress) returns(bool){
            Customer storage c = customers[_customerAddress];
            c.count = c.count+1;
            c.expectedInfo[c.count]=ExpectedTransfer(true, expectedFee, expectedTime, false, tokenContractAddress);
            return true;
    }
    
    function deleteSecondaryAddress(address _customerAddress, address _secondaryAddress) public onlyOwner isCustomerAdded(_customerAddress)
        isSecondaryAddrAdded(_customerAddress, _secondaryAddress) returns(bool){
            Customer storage c = customers[_customerAddress];
            bool isExist = false;
            uint length = c.expectedAddresses.length;
            address[] memory addressList = new address[](length-1);
            uint l = 0;
            for (uint k=0; k<length; ++k) {
                if(c.expectedAddresses[k] !=_secondaryAddress){
                    addressList[l] = c.expectedAddresses[k];
                    l++;
                }else{
                    isExist = true;
                }
            }
            //require(isExist); maybe is better option??
            if(isExist){
                c.expectedAddresses = addressList;
                linkedAddress[_secondaryAddress] = ZERO_ADDRESS;
                return true;
            }
            return false;
    }
    
    function setCustomerSignature(address _customerAddress, uint _expiredTime, bytes32 _signature) public onlyOwner
        isCustomerAdded(_customerAddress) verifiedCustomer(_expiredTime, _signature) returns(bool){
            Customer storage c = customers[_customerAddress];
            c.expiredTime = _expiredTime;
            c.signature = _signature;
            return true;
    }
    
    function getCustomer(address _customerAddress) public view onlyOwner isCustomerAdded(_customerAddress) returns (address, bool, uint, bytes32){
        Customer storage c = customers[_customerAddress];
        return (c.addr, c.isLocked, c.expiredTime, c.signature);
    }
    
    function isCustomerHasKYC(address _customerAddress) public view isCustomerAdded(_customerAddress) isWLAddress(msg.sender) returns (bool){
        Customer storage c = customers[_customerAddress];
        return (!c.isLocked && c.expiredTime > now && c.signature!=ZERO_BYTES);
    }
    
    function lockedCustomer(address _customerAddress) public view onlyOwner  
        isCustomerAdded(_customerAddress) isUnLockedCustomer(_customerAddress) returns(bool){
        Customer memory c = customers[_customerAddress];
        c.isLocked = true;
        return true;
    }
    
    function unlockedCustomer(address _customerAddress) public view onlyOwner  
        isCustomerAdded(_customerAddress) isLockedCustomer(_customerAddress) returns(bool){
        Customer memory c = customers[_customerAddress];
        c.isLocked = false;
        return true;
    }
    
    function getLinkedAddress(address _address) public view onlyOwner isValidAddress(_address) returns(address){
        require(linkedAddress[_address] != ZERO_ADDRESS);
        return(linkedAddress[_address]);
    }
    
    // END OF CUSTOMERS FUNCTIONS
    
    // BEGIN OF TOKEN FUNCTIONS
    
    function addToken(address _address, string _name) public onlyOwner isContract(_address) isTokenNotAdded(_address) returns(bool){
        tokens[_address] = ERCToken(false, _address, _name);
        return true;
    } 
    
    function lockedToken(address _address) public view onlyOwner isTokenAdded(_address) isUnLockedCustomer(_address) returns(bool){
        ERCToken memory ercT = tokens[_address];
        ercT.isLocked = true;
        return true;
    }
    
    function unlockedToken(address _address) public view onlyOwner isTokenAdded(_address) isLockedToken(_address) returns(bool){
        ERCToken memory ercT = tokens[_address];
        ercT.isLocked = false;
        return true;
    }
    
    // END OF TOKEN FUNCTIONS
    
    
    // BEGIN OF PAYABLE FUNCTIONS
    
    function() public payable {
        require(msg.sender != ZERO_ADDRESS);
        require(linkedAddress[msg.sender] != ZERO_ADDRESS);
        require(msg.value > 0);
        address customerAddress = linkedAddress[msg.sender];
        Customer storage c = customers[customerAddress];
        require(c.addr != ZERO_ADDRESS);
        require(!c.isLocked);
        uint count = c.count;
        ExpectedTransfer storage eT = c.expectedInfo[count];
        require(eT.expectedTime > now);
        require(msg.value == eT.expectedFee);
        eT.isPaid = true;
        eT.inComingAddress = msg.sender;
        totalIncomingWei += msg.value;
        
        //uint maxFee = (eT.expectedFee * 11)/10;
        //require(maxFee > msg.value);
        
    }
    
    function tokenTransfertoKYC(address tokenAddress, uint tokenAmount) public onlyOwner isTokenAdded(tokenAddress) isUnLockedToken(tokenAddress)
        isAvailableTokenBalance(tokenAddress, tokenAmount) returns(bool){
        ERC20(tokenAddress).transfer(WLAddress, tokenAmount);
        return true;
    }
    
    function ethTransfertoKYC(uint amount) public onlyOwner isAvailableETHBalance(amount) returns(bool){
        address(WLAddress).transfer(amount);
        totalOutgoingWei += amount;
        return true;
    }
    
    function refundETHToCustomer(address _address, uint refundAmount) public onlyOwner isCustomerAdded(_address) returns(bool){
        require(refundAmount > 0);
        Customer storage c = customers[_address];
        require(c.expectedInfo[c.count].isPaid);
        require(c.expectedInfo[c.count].isEth);
        _address.transfer(refundAmount);
        return true;
    }
    
    function refundTokenToCustomer(address _address, uint refundAmount, address tokenAddress) public onlyOwner isCustomerAdded(_address)
        isAvailableTokenBalance(tokenAddress, refundAmount) returns(bool){
            Customer storage c = customers[_address];
            require(c.expectedInfo[c.count].isPaid);
            require(!c.expectedInfo[c.count].isEth);
            require(c.expectedInfo[c.count].inComingAddress == tokenAddress);
            ERC20(tokenAddress).transfer(_address, refundAmount);
            return true;
    }
    
    function getETHBalanceInfo() public view onlyOwner returns(uint, uint){
        return (totalIncomingWei, totalOutgoingWei);
    }
    
     
    
    // END OF PAYABLE FUNCTIONS
    
}