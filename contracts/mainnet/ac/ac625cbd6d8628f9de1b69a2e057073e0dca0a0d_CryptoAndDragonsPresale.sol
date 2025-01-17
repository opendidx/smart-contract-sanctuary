pragma solidity ^0.4.19;

contract AccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    function AccessControl() public {
        owner = msg.sender;
        moderators[msg.sender] = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract DTT is AccessControl{
  function approve(address _spender, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _addr) public returns (uint);
  mapping (address => mapping (address => uint256)) public allowance;
}

contract DataBase is AccessControl{
  function addMonsterObj(uint64 _monsterId,uint256 _genes,uint32 _classId,address _master,string _name,string _skills) public;
  function getTotalMonster() constant public returns(uint64);
  function setMonsterGene(uint64 _monsterId,uint256 _genes) public;
}
contract NFTToken is AccessControl{
  function transferAuction(address _from, address _to, uint256 _value) external;
  function ownerOf(uint256 _tokenId) public constant returns (address owner);
}

contract CryptoAndDragonsPresale is AccessControl{
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event Hatch(address indexed _owner, uint16 _tableId);

  address public thisAddress;
  address public dragonTreasureToken;
  address public databaseContract;
  address public ERC721Contract;
  uint256 public totalClass;
  uint256 public totalMonster;
  uint256 public totalAuction;
  uint256 private increaseRate = 0.1 ether;
  uint64 public cooldownTime = 2 hours;
  mapping (address => address) public masterToReferral;
  mapping (uint16 => uint32[]) private EggTable;
  mapping (uint8 => uint256) public EggTotal;
  function setNewMonster(uint256 _genes,uint32 _classId,address _master,string _name,string _skills) onlyModerators public returns(uint64 _monsterId) {
    DataBase data = DataBase(databaseContract);
    uint64 monsterId = data.getTotalMonster() + 1;
    data.addMonsterObj(monsterId,_genes,_classId,_master,_name,_skills);
    return monsterId;
  }
  function setMasterToReferral(address _master, address _referral) onlyOwner public{
    masterToReferral[_master] = _referral;
  }
  function setEggTotal(uint8 _tableNum,uint256 _tableVal) onlyOwner public{
    EggTotal[_tableNum] = _tableVal;
  }
  function setAddresses(address _dragonTreasureToken,address _databaseContract,address _ERC721Contract) onlyOwner public{
    dragonTreasureToken = _dragonTreasureToken;
    databaseContract = _databaseContract;
    ERC721Contract = _ERC721Contract;
  }
  function setEggTable(uint16 _tableNum,uint32[] _tableVals) onlyOwner public{
    EggTable[_tableNum] = _tableVals;
  }
  function userWithdraw(uint256 _value) public{
    DTT DTTtoken = DTT(dragonTreasureToken);
    DTTtoken.transferFrom(this,msg.sender,_value);
  }

  struct Egg {
    uint8 tableId;
    uint32 classId;
    uint256 genes;
    uint256 hatchTime;
    uint32 matronId;
    uint32 sireId;
    uint16 generation;
    address master;
  }

  struct Auction {
    uint256 classId;
    uint256 monsterId;
    uint256 price;
    uint256 endTime;
    uint8 rarity;
    address bidder;
  }

  Egg[] public eggs;
  Auction[] public auctions;


  uint randNonce = 0;
  function randMod(uint _modulus) internal returns(uint) {
    randNonce++;
    return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
  }

  function setCooldown(uint64 _time) onlyOwner public{
    cooldownTime = _time;
  }

  function getSortedArray(uint[] storageInt) public pure returns(uint[]) {
      uint[] memory a = getCloneArray(storageInt);
      quicksort(a);
      return a;
  }
  function getCloneArray(uint[] a) private pure returns(uint[]) {
      return a;
  }
  function swap(uint[] a, uint l, uint r) private pure {
      uint t = a[l];
      a[l] = a[r];
      a[r] = t;
  }
  function getPivot(uint a, uint b, uint c) private pure returns(uint) {
      if(a > b){
          if(b > c){
              return b;
          }else{
              return a > c ? c : a ;
          }
      }else{
          if(a > c){
              return a;
          }else{
              return b > c ? c : b ;
          }
      }
  }
  function quicksort(uint[] a) private pure {
      uint left = 0;
      uint right = a.length - 1;
      quicksort_core(a, left, right);
  }
  function quicksort_core(uint[] a, uint left, uint right) private pure {
      if(right <= left){
          return;
      }
      uint l = left;
      uint r = right;
      uint p = getPivot(a[l], a[l+1], a[r]);
      while(true){
          while(a[l] < p){
              l++;
          }
          while(p < a[r]){
              r--;
          }
          if(r <= l){
              break;
          }
          swap(a, l, r);
          l++;
          r--;
      }
      quicksort_core(a, left, l-1);
      quicksort_core(a, r+1, right);
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll () onlyOwner public {
    msg.sender.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner public {
    msg.sender.transfer(_amount);
  }


  function addAuction(uint32 _classId, uint256 _monsterId, uint256 _price, uint8 _rarity, uint8 _endTime) onlyOwner public {
    Auction memory auction = Auction({
      classId: _classId,
      monsterId: _monsterId,
      price: _price,
      rarity: _rarity,
      endTime: 86400 * _endTime + now,
      bidder: msg.sender
    });
    auctions.push(auction);
    totalAuction += 1;
  }

  function burnAuction() onlyOwner external {
    uint256 counter = 0;
    for (uint256 i = 0; i < totalAuction; i++) {
      if(auctions[i].endTime < now - 86400 * 3){
        delete auctions[i];
        counter++;
      }
    }
    totalAuction -= counter;
  }

  /* Buying */

  function ceil(uint a) public pure returns (uint ) {
    return uint(int(a * 100) / 100);
  }
  /*
     Buy a country directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All countries that
     have been listed can be bought by this method. User funds are sent
     directly to the previous owner and are never stored in the contract.
  */
  function setGenes(uint256 _price, uint256 _monsterId) internal{
    DataBase data = DataBase(databaseContract);
    uint256 gene = _price / 10000000000000000;
    if(gene > 255)
      gene = 255;
    uint256 genes = 0;
    genes += gene * 1000000000000000;
    genes += gene * 1000000000000;
    genes += gene * 1000000000;
    genes += gene * 1000000;
    genes += gene * 1000;
    genes += gene;
    if(genes > 255255255255255255)
      genes = 255255255255255255;
    data.setMonsterGene(uint64(_monsterId),genes);
  }

  function buy (uint256 _auctionId, address _referral) payable public {
    NFTToken CNDERC721 = NFTToken(ERC721Contract);
    require(auctions[_auctionId].endTime > now);
    require(CNDERC721.ownerOf(auctions[_auctionId].monsterId) != address(0));
    require(ceil(msg.value) >= ceil(auctions[_auctionId].price + increaseRate));
    require(CNDERC721.ownerOf(auctions[_auctionId].monsterId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    address oldOwner = CNDERC721.ownerOf(auctions[_auctionId].monsterId);
    address newOwner = msg.sender;
    uint256 oldPrice = auctions[_auctionId].price;
    uint256 price = ceil(msg.value);
    setGenes(price,auctions[_auctionId].monsterId);
    CNDERC721.transferAuction(oldOwner, newOwner, auctions[_auctionId].monsterId);
    auctions[_auctionId].price = ceil(price);
    auctions[_auctionId].bidder = msg.sender;
    DTT DTTtoken = DTT(dragonTreasureToken);
    if(masterToReferral[msg.sender] != address(0) && masterToReferral[msg.sender] != msg.sender){
      DTTtoken.approve(masterToReferral[msg.sender], DTTtoken.allowance(this,masterToReferral[msg.sender]) + price / 1000000000 * 5);
    }else if(_referral != address(0) && _referral != msg.sender){
      masterToReferral[msg.sender] = _referral;
      DTTtoken.approve(_referral, DTTtoken.allowance(this,_referral) + price / 1000000000 * 5);
    }

    DTTtoken.approve(msg.sender, DTTtoken.allowance(this,msg.sender) + price / 1000000000 * 5);
    if(oldPrice > 0)
      oldOwner.transfer(oldPrice);
    Bought(auctions[_auctionId].monsterId, newOwner, price);
    Sold(auctions[_auctionId].monsterId, oldOwner, price);
  }

  function buyBlueStarEgg(address _sender, uint256 _tokens, uint16 _amount) isActive public returns(uint256) {
    require(_amount <= 10 && _amount > 0);
    uint256 price = ceil(5 * 10**8);
    if (_tokens < price)
        revert();
    DataBase data = DataBase(databaseContract);
    for (uint8 i = 0; i < _amount; i++) {
      uint256 genes = 0;
      genes += (randMod(205) + 51) * 1000000000000000;
      genes += (randMod(205) + 51) * 1000000000000;
      genes += (randMod(205) + 51) * 1000000000;
      genes += (randMod(205) + 51) * 1000000;
      genes += (randMod(205) + 51) * 1000;
      genes += randMod(205) + 51;
      uint32 classId = EggTable[1][randMod(EggTable[1].length)];
      EggTotal[1] += 1;
      uint64 monsterId = data.getTotalMonster() + 1;
      data.addMonsterObj(monsterId,genes,classId,_sender,"","");
    }
    Hatch(msg.sender, 1);
    return price * _amount;
  }

  function buyRareEgg(uint8 _table, uint _amount, address _referral) isActive payable public {
    require(_amount <= 10 && _amount > 0);
    uint256 price = 0.1 ether;
    if(EggTotal[_table] > 0)
    price += uint((int(EggTotal[_table] / 500) * 10**18) / 20);
    require(msg.value >= price * _amount);

    DTT DTTtoken = DTT(dragonTreasureToken);
    DataBase data = DataBase(databaseContract);
    uint256 bonus = 10;
    if(_amount >= 10){
      bonus = 12;
    }
    if(masterToReferral[msg.sender] != address(0) && masterToReferral[msg.sender] != msg.sender){
      DTTtoken.approve(masterToReferral[msg.sender], DTTtoken.allowance(this,masterToReferral[msg.sender]) + price / 10000000000 * 5 * bonus * _amount);
    }else if(_referral != address(0) && _referral != msg.sender){
      masterToReferral[msg.sender] = _referral;
      DTTtoken.approve(_referral, DTTtoken.allowance(this,_referral) + price / 10000000000 * 5 * bonus * _amount);
    }

    DTTtoken.approve(msg.sender, DTTtoken.allowance(this,msg.sender) + price / 10000000000 * 5 * bonus * _amount);
    for (uint8 i = 0; i < _amount; i++) {
      uint256 genes = 0;
      genes += (randMod(155) + 101) * 1000000000000000;
      genes += (randMod(155) + 101) * 1000000000000;
      genes += (randMod(155) + 101) * 1000000000;
      genes += (randMod(155) + 101) * 1000000;
      genes += (randMod(155) + 101) * 1000;
      genes += randMod(155) + 101;
      uint32 classId = EggTable[_table][randMod(EggTable[_table].length)];
      EggTotal[_table] += 1;
      uint64 monsterId = data.getTotalMonster() + 1;
      data.addMonsterObj(monsterId,genes,classId,msg.sender,"","");
    }
    Hatch(msg.sender, _table);
  }

  function hatchEgg(uint256 _eggId, string _name) public{
    require(eggs[_eggId].hatchTime <= now);
    require(eggs[_eggId].classId != 0 && eggs[_eggId].master == msg.sender);
    DataBase CNDDB = DataBase(databaseContract);
    uint64 monsterId = CNDDB.getTotalMonster() + 1;
    string memory skills = "0:0:0:0";
    CNDDB.addMonsterObj(monsterId,eggs[_eggId].genes,eggs[_eggId].classId,msg.sender,_name,skills);
    eggs[_eggId].classId = 0;
    eggs[_eggId].master = address(0);
  }

  function monstersForSale (uint8 optSort) external view returns (uint256[] _monsters){
    uint256[] memory mcount = new uint256[](totalAuction);
    uint256 counter = 0;
    for (uint256 i = 0; i < totalAuction; i++) {
        mcount[counter] = i;
        counter++;
    }
    if(optSort != 0){
      sortAuction(mcount);
    }
    return mcount;
  }
  function sortAuction (uint256[] _mcount) public view returns (uint256[] _monsters){
    uint256[] memory mcount = new uint256[](_mcount.length);
    for(uint256 i = 0; i < _mcount.length; i++){
      mcount[i] = auctions[i].price * 10000000000 + i;
    }
    uint256[] memory tmps = getSortedArray(_mcount);
    uint256[] memory result = new uint256[](tmps.length);
    for(uint256 i2 = 0; i2 < tmps.length; i2++){
      result[i2] = tmps[i2] % 10000000000;
    }
    return result;
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
}