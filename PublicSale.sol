pragma solidity ^0.6.12;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SherDogePreFairLaunch is ReentrancyGuard {
    using SafeMath for uint256;
    address payable public manager;
    uint public tokenPerBNB;
    uint public saleAmount;
    uint public maxBuyBNB;
    uint public minBuyBNB;
    uint public soldAmount;
    IERC20 public token;
    bool public isPaused;
    
    struct InvestorData {
        uint totalInvested;
        mapping(uint => uint) claimable;
        mapping(uint => bool) isClaimed;
        
    }
    mapping(address => bool) public isInvested;
    mapping(address => InvestorData) public investorData;
    mapping(uint => bool) public isClaimable;
    mapping(uint => uint) public claimableDate;
    address[] public investors;

    receive() external payable {
        buy();
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    modifier nonPaused() {
        require(!isPaused);
        _;
    }
    
    event Bought(address _buyer, uint _amount, uint _bnbAmount, uint _date);
    event Claimed(address _claimer, uint _amount, uint _number, uint _date);

    constructor(address _token, uint _tokenPerBNB, uint _saleAmount, uint _maxBuyBNB, uint _minBuyBNB) public {
        manager = msg.sender;
        token = IERC20(_token);
        tokenPerBNB = _tokenPerBNB;
        saleAmount = _saleAmount;
        maxBuyBNB = _maxBuyBNB;
        minBuyBNB = _minBuyBNB;
    }
    
    function changePause(bool _pause) public onlyManager {
        isPaused = _pause;
    }
    
    function getInvestorClaimable(address _investor, uint _number) public view returns(uint) {
        InvestorData storage investor = investorData[_investor];
        return investor.claimable[_number];
    }
    
    function getInvestorIsClaimed(address _investor, uint _number) public view returns(bool) {
        InvestorData storage investor = investorData[_investor];
        return investor.isClaimed[_number];
    }
    
    function changeClaimable(uint _number,bool _status,  uint _date) public onlyManager nonReentrant {
        isClaimable[_number] = _status;
        claimableDate[_number] = _date;
    }

    function getTokenToManager(uint _amount, address _to) public onlyManager nonReentrant {
        token.transfer(_to, _amount);
    }
    
    function buy() public payable nonReentrant nonPaused {
        InvestorData storage investor = investorData[msg.sender];
        uint amount = msg.value.mul(tokenPerBNB).div(1e18);
        require(msg.value <= maxBuyBNB, "max buy amount!");
        require(msg.value >= minBuyBNB, "min buy amount!");
        require(amount.add(soldAmount) <= saleAmount, "all tokens sold");
        if(!isInvested[msg.sender]) {
            investors.push(msg.sender);
        }
        
        investor.totalInvested = investor.totalInvested.add(amount);
        uint claimAmount = amount.div(4);
        investor.claimable[1] = investor.claimable[1].add(claimAmount);
        investor.claimable[2] = investor.claimable[2].add(claimAmount);
        investor.claimable[3] = investor.claimable[3].add(claimAmount);
        investor.claimable[4] = investor.claimable[4].add(claimAmount);
        
        
        isInvested[msg.sender] = true;
        soldAmount = soldAmount.add(amount);
        manager.transfer(msg.value);
        emit Bought(msg.sender, amount, msg.value, now);

    }
    
    function claim(uint number) public nonReentrant {
        InvestorData storage investor = investorData[msg.sender];
        require(isClaimable[number], "not claimable");
        require(now >= claimableDate[number], "early");
        require(!investor.isClaimed[number], "already claimed");
        if(investor.claimable[number] > 0) {
        token.transfer(msg.sender, investor.claimable[number]);
         investor.claimable[number] = 0;
         investor.isClaimed[number] = true;
         emit Claimed(msg.sender, investor.claimable[number], number, now);
        }
        
        
    }
    
    

   
}
