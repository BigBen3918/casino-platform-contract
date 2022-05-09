//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./staking.sol";

contract Treasury is Ownable {
    event Deposit(address from, uint256 amount);

    address public ICICBAddress;

    constructor(address _ICICBAddress) public {
        ICICBAddress = _ICICBAddress;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        ERC20 ICICBToken = ERC20(ICICBAddress);
        ICICBToken.transfer(to, amount);
    }

    function deposit(uint256 amount) external {
        ERC20 ICICBToken = ERC20(ICICBAddress);
        ICICBToken.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }
}

contract StakingRouter is Ownable {
    event AdminChanged(address admin, address newAdmin);
    event GameCreated(address stakingPoolAddress, GameInfo _gameInfo);

    event GameWin(uint256 gameID, uint256 amount);
    event GameLose(uint256 gameID, uint256 amount);

    address public admin;
    address public treasury;
    address public ICICBAddress;

    address[] public games;
    mapping(address => uint256) public gameIds;

    constructor(address _admin, address _ICICBAddress) public {
        admin = _admin;
        ICICBAddress = _ICICBAddress;

        Treasury _treasury = new Treasury(ICICBAddress);
        treasury = address(_treasury);
    }

    function create(GameInfo memory _gameInfo) public {
        StakingPool newGame = new StakingPool(_gameInfo, ICICBAddress);

        gameIds[address(newGame)] = games.length;
        games.push(address(newGame));

        emit GameCreated(address(newGame), _gameInfo);
    }

    /* ------------- admin actions ------------- */

    function gameWin(uint256 gameId, uint256 amount) public onlyAdmin {
        require(games[gameId] != address(0), "Invalide game ID");

        StakingPool game = StakingPool(games[gameId]);
        Treasury _treasury = Treasury(treasury);

        game.gameWithdraw(address(_treasury), amount);
        emit GameWin(gameId, amount);
    }

    function gameLose(uint256 gameId, uint256 amount) public onlyAdmin {
        require(games[gameId] != address(0), "Invalide game ID");

        StakingPool game = StakingPool(games[gameId]);
        Treasury _treasury = Treasury(treasury);

        _treasury.withdraw(address(game), amount);
        emit GameLose(gameId, amount);
    }

    function withdraw(address to, uint256 amount) public onlyAdmin {
        Treasury _treasury = Treasury(treasury);
        _treasury.withdraw(to, amount);
    }

    function batchWithdraw(address[] memory tos, uint256[] memory amounts)
        external
        onlyAdmin
    {
        uint256 length = tos.length;
        require(amounts.length == length, "Request parameter not valid");
        for (uint256 i = 0; i < length; i++) {
            withdraw(tos[i], amounts[i]);
        }
    }

    function batchGameUpdate(
        uint256[] memory _gameIds,
        uint256[] memory _amounts,
        bool[] memory _winstates
    ) external onlyAdmin {
        uint256 length = _gameIds.length;
        require(
            _amounts.length == length && _winstates.length == length,
            "sync error : invalide parameters"
        );

        for (uint256 i = 0; i < length; i++) {
            if(_winstates[i]){
                gameWin(_gameIds[i], _amounts[i]);
            }
            else {
                gameLose(_gameIds[i], _amounts[i]);
            }
        }
    }

    /* ------------- ownable ------------- */

    function changeAdmin(address newAdmin) external {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(admin == _msgSender(), "Factory: caller is not the admin");
        _;
    }

    /* ------------- view ------------ */
    function totalGames() external view returns (uint256) {
        return games.length;
    }

    function stakingInfos(uint256[] memory ids)
        external
        view
        returns (address[] memory pools, GameInfo[] memory infos)
    {
        pools = new address[](ids.length);
        infos = new GameInfo[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            pools[i] = games[i];
            infos[i] = StakingPool(pools[i]).getGameInfo();
        }
    }
}
