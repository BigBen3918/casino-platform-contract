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
    address public ICICBAddress;

    constructor(GameInfo memory _gameInfo, address _ICICBAddress) ERC20(string(abi.encodePacked("sICICB", _gameInfo.gameName)), "sATRI" ,0 ,0) public {
        gameInfo.gameOwner = _gameInfo.gameOwner;
        gameInfo.feeRate = _gameInfo.feeRate;
        gameInfo.gameName = _gameInfo.gameName;
        ICICBAddress = _ICICBAddress;
    }

    function stake(uint256 amount) public returns (bool) {
        ERC20 ICICBToken = ERC20(ICICBAddress);
        
        //fee count
        uint feeAmount = amount * gameInfo.feeRate/1000000;
        
        uint256 mintAmount = 0;
        
        if(_totalSupply == 0) mintAmount = amount.sub(feeAmount);
        else mintAmount = (amount.sub(feeAmount)) * _totalSupply / ICICBToken.balanceOf(address(this));

        ICICBToken.transferFrom(msg.sender,address(this),amount);
        ICICBToken.transfer(owner(),feeAmount/2);
        ICICBToken.transfer(gameInfo.gameOwner,feeAmount/2);

        _mint(_msgSender(), mintAmount);
        return true;
    }
    
    function unstake(uint256 amount) public returns (bool) {
        ERC20 ICICBToken = ERC20(ICICBAddress);
        
        uint256 withdrawAmount;
        withdrawAmount = ICICBToken.balanceOf(address(this)) * amount / _totalSupply;
        ICICBToken.transfer(msg.sender,withdrawAmount);

        _burn(_msgSender(), amount);
        return true;
    }

    // ICICB/sICICB rate (1000000)
    function getRate() public view returns (uint256 rate) {
        ERC20 ICICBToken = ERC20(ICICBAddress);
        rate = ICICBToken.balanceOf(address(this))*1000000/_totalSupply;
    }
    
    /* ------------- game Actions ------------- */
    function gameWithdraw(address to, uint amount) public onlyOwner{
        ERC20 ICICBToken = ERC20(ICICBAddress);
        ICICBToken.transfer(to,amount);
    }

    /* ------------- view ------------- */
    function getGameInfo() public view returns (GameInfo memory) {
        return gameInfo;
    }

}