pragma solidity ^0.4.23;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}

contract MrMoneyBagz {

    using SafeMath for uint256;

    uint constant COIN_PRICE = 40000;
    uint constant TYPES_TRONOPOLY = 6;
    uint constant PERIOD = 60 minutes;

    uint[TYPES_TRONOPOLY] prices = [3000, 11750, 44500, 155000, 470000, 950000];
    uint[TYPES_TRONOPOLY] profit = [4, 16, 62, 220, 680, 1400];

    uint public totalPlayers;
    uint public totalTRONOPOLY;
    uint public totalPayout;

    address owner;
   

    struct Player {
        uint coinsForBuy;
        uint coinsForSale;
        uint time;
        uint[TYPES_TRONOPOLY] TRONOPOLY;
    }

    mapping(address => Player) public players;

    constructor(address _owner) public {
        owner = _owner;
    }

    function deposit() public payable {
        require(msg.value >= COIN_PRICE);

        Player storage player = players[msg.sender];
        player.coinsForBuy = player.coinsForBuy.add(msg.value.div(COIN_PRICE));

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
        }
    }

    function buy(uint _type, uint _number) public {
        require(_type < TYPES_TRONOPOLY && _number > 0);
        collect(msg.sender);

        uint paymentCoins = prices[_type].mul(_number);
        Player storage player = players[msg.sender];

        require(paymentCoins <= player.coinsForBuy.add(player.coinsForSale));

        if (paymentCoins <= player.coinsForBuy) {
            player.coinsForBuy = player.coinsForBuy.sub(paymentCoins);
        } else {
            player.coinsForSale = player.coinsForSale.add(player.coinsForBuy).sub(paymentCoins);
            player.coinsForBuy = 0;
        }

        player.TRONOPOLY[_type] = player.TRONOPOLY[_type].add(_number);
        players[owner].coinsForSale = players[owner].coinsForSale.add( paymentCoins.mul(40).div(3000) );
       

        totalTRONOPOLY = totalTRONOPOLY.add(_number);
    }

    function withdraw(uint _coins) public {
        require(_coins > 0);
        collect(msg.sender);
        require(_coins <= players[msg.sender].coinsForSale);

        players[msg.sender].coinsForSale = players[msg.sender].coinsForSale.sub(_coins);
        transfer(msg.sender, _coins.mul(COIN_PRICE));
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        require(player.time > 0);

        uint hoursPassed = ( now.sub(player.time) ).div(PERIOD);
        if (hoursPassed > 0) {
            uint hourlyProfit;
            for (uint i = 0; i < TYPES_TRONOPOLY; i++) {
                hourlyProfit = hourlyProfit.add( player.TRONOPOLY[i].mul(profit[i]) );
            }
            uint collectCoins = hoursPassed.mul(hourlyProfit);
            player.coinsForBuy = player.coinsForBuy.add( collectCoins.div(2) );
            player.coinsForSale = player.coinsForSale.add( collectCoins.div(2) );
            player.time = player.time.add( hoursPassed.mul(PERIOD) );
        }
    }

    function transfer(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                msg.sender.transfer(payout);
            }
        }
    }

    function TRONOPOLYOf(address _addr) public view returns (uint[TYPES_TRONOPOLY]) {
        return players[_addr].TRONOPOLY;
    }

}