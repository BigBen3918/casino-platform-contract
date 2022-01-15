//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

struct GameInfo {
    address gameOwner;
    uint feeRate;
    string gameName;
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () public {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract StakingPool is Context, ERC20, Ownable{

    event Stake(address staker, uint amount);
    event UnStake(address staker, uint amount);
    event Win(uint amount);
    event Lose(uint amount);


    using SafeMath for uint256;

    GameInfo public gameInfo;
    address public atariAddress;

    constructor(GameInfo memory _gameInfo, address _atariAddress) ERC20(string(abi.encodePacked("sATARI", _gameInfo.gameName)), "sATRI" ,0 ,0) public {
        gameInfo.gameOwner = _gameInfo.gameOwner;
        gameInfo.feeRate = _gameInfo.feeRate;
        gameInfo.gameName = _gameInfo.gameName;
        atariAddress = _atariAddress;        
    }

    function stake(uint256 amount) public returns (bool) {
        ERC20 AtariToken = ERC20(atariAddress);
        
        //fee count
        uint feeAmount = amount * gameInfo.feeRate/1000000;
        
        uint256 mintAmount = 0;
        
        if(_totalSupply == 0) mintAmount = amount.sub(feeAmount);
        else mintAmount = (amount.sub(feeAmount)) * _totalSupply / AtariToken.balanceOf(address(this));

        AtariToken.transferFrom(msg.sender,address(this),amount);
        AtariToken.transfer(owner(),feeAmount/2);
        AtariToken.transfer(gameInfo.gameOwner,feeAmount/2);

        _mint(_msgSender(), mintAmount);
        return true;
    }
    
    function unstake(uint256 amount) public returns (bool) {
        ERC20 AtariToken = ERC20(atariAddress);
        
        uint256 withdrawAmount;
        withdrawAmount = AtariToken.balanceOf(address(this)) * amount / _totalSupply;
        AtariToken.transfer(msg.sender,withdrawAmount);

        _burn(_msgSender(), amount);
        return true;
    }

    // atari/sATARI rate (1000000)
    function getRate() public view returns (uint256 rate) {
        ERC20 AtariToken = ERC20(atariAddress);
        rate = AtariToken.balanceOf(address(this))*1000000/_totalSupply;
    }
    
    /* ------------- game Actions ------------- */
    function gameWithdraw(address to, uint amount) public onlyOwner{
        ERC20 AtariToken = ERC20(atariAddress);
        AtariToken.transfer(to,amount);
    }

    /* ------------- view ------------- */
    function getGameInfo() public view returns (GameInfo memory) {
        return gameInfo;
    }

}