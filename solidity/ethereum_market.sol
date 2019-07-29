pragma solidity ^0.4.25;

contract EthereumMarket {

    address owner;
    uint public numItems;
    bool public stopped;

    constructor() public {
        owner = msg.sender;
        numItems = 0;
        stopped = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUser {
        require(accounts[msg.sender].resistered);
        _;
    }

    // ************
    // 取引を行うためのステートと関数
    // ************

    // アカウント情報
    struct account {
        string name;
        string email;
        uint numTransactions;
        int reputations;
        bool resistered;
        int numSell;
        int numBuy;
    }
    mapping(address => account) public accounts;
    mapping(address => uint[]) public sellItems;
    mapping(address => uint[]) public buyItems;

    function registerAccount(string _name, string _email) public isStopped {
        require(!accounts[msg.sender].resistered);

        accounts[msg.sender].resistered = true;
        accounts[msg.sender].name = _name;
        accounts[msg.sender].email = _email;
    }

    // 商品情報
    struct item {
        address sellerAddr;
        address buyerAddr;
        string seller;
        string name;
        string description;
        uint price;
        bool payment;
        bool shipment;
        bool receivement;
        bool sellerReputate;
        bool buyerReputate;
        bool stopSell;
    }
    mapping(uint => item) public items;

    // 商品画像詳細
    struct image {
        string googleDocId;
        string ipfsHash;
    }
    mapping(uint => image) public images;

    function sell(string _name, string _description, uint _price, string _googleDocId, string _ipfsHash) public onlyUser isStopped {
        items[numItems].sellerAddr = msg.sender;
        items[numItems].seller = accounts[msg.sender].name;
        items[numItems].name = _name;
        items[numItems].description = _description;
        items[numItems].price = _price;
        images[numItems].googleDocId = _googleDocId;
        images[numItems].ipfsHash = _ipfsHash;
        accounts[msg.sender].numSell++;
        sellItems[msg.sender].push(numItems);
        numItems++;
    }

    function buy(uint _numItems) public payable onlyUser isStopped {
        require(!items[_numItems].payment);
        require(!items[_numItems].stopSell);
        require(items[_numItems].price == msg.value);

        items[_numItems].payment = true;
        items[_numItems].stopSell = true;
        items[_numItems].buyerAddr = msg.sender;
        accounts[msg.sender].numBuy++;
        buyItems[msg.sender].push(_numItems);
    }

    // 発送完了を通知する関数
    function ship(uint _numItems) public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);
        require(items[_numItems].payment);
        require(!items[_numItems].shipment);

        items[_numItems].shipment = true;
    }

    // 商品受取の通知と出品者へ代金を送金する関数
    function receive(uint _numItems) public payable onlyUser isStopped {
        require(items[_numItems].buyerAddr == msg.sender);
        require(items[_numItems].shipment);
        require(!items[_numItems].receivement);

        items[_numItems].receivement = true;
        items[_numItems].sellerAddr.transfer(items[_numItems].price);
    }

    function sellerEvaluate(uint _numItems, int _reputate) public onlyUser isStopped {
        require(items[_numItems].buyerAddr == msg.sender);
        require(items[_numItems].receivement);
        require(_reputate >= -2 && _reputate <= 2);
        require(!items[_numItems].sellerReputate);

        items[_numItems].sellerReputate = true;
        accounts[items[_numItems].sellerAddr].numTransactions++;
        accounts[items[_numItems].sellerAddr].reputations += _reputate;
    }

    function buyerEvaluate(uint _numItems, int _reputate) public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);
        require(items[_numItems].receivement);
        require(_reputate >= -2 && _reputate <= 2);
        require(!items[_numItems].buyerReputate);

        items[_numItems].buyerReputate = true;
        accounts[items[_numItems].buyerAddr].numTransactions++;
        accounts[items[_numItems].buyerAddr].reputations += _reputate;
    }

    // ************
    // 例外処理を行うためのステートと関数
    // ************

    // アカウント情報を修正する関数
    function modifyAccount(string _name, string _email) public onlyUser isStopped {
        accounts[msg.sender].name = _name;
        accounts[msg.sender].email = _email;
    }

    // 出品内容を変更する関数
    function modifyItem(uint _numItems, string _name, string _description, uint _price, string _googleDocId, string _ipfsHash) public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);
        require(!items[_numItems].payment);
        require(!items[_numItems].stopSell);

        items[_numItems].seller = accounts[msg.sender].name;
        items[_numItems].name = _name;
        items[_numItems].description = _description;
        items[_numItems].price = _price;
        images[_numItems].googleDocId = _googleDocId;
        images[_numItems].ipfsHash = _ipfsHash;
    }

    // 出品を取り消す関数（出品者）
    function sellerStop(uint _numItems) public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);
        require(!items[_numItems].stopSell);
        require(!items[_numItems].payment);

        items[_numItems].stopSell = true;
    }

    // 出品を取り消す関数（オーナー）
    function ownerStop(uint _numItems) public onlyOwner isStopped {
        require(!items[_numItems].stopSell);
        require(!items[_numItems].payment);

        items[_numItems].stopSell = true;
    }

    // 返金する際に参照するステート
    mapping(uint => bool) public refundFlags;

    // 購入者へ返金する関数（出品者）
    // 商品を発送できなくなったときに使用する
    function refundFromSeller(uint _numItems) public payable onlyUser isStopped {
        require(msg.sender == items[_numItems].sellerAddr);
        require(items[_numItems].payment);
        require(!items[_numItems].receivement);
        require(!refundFlags[_numItems]);

        refundFlags[_numItems] = true;
        items[_numItems].buyerAddr.transfer(items[_numItems].price); // 購入者へ返金
    }

    // 購入者へ返金する関数（オーナー）
    function refundFromOwner(uint _numItems) public payable onlyOwner isStopped {
        require(items[_numItems].payment);
        require(!items[_numItems].receivement);
        require(!refundFlags[_numItems]);

        refundFlags[_numItems] = true;
        items[_numItems].buyerAddr.transfer(items[_numItems].price);
    }

    // ************
    // セキュリティー対策
    // ************

    // Circuit Breaker
    modifier isStopped {
        require(!stopped);
        _;
    }

    // Circuit Breaker を発動・停止する関数
    function toggleCircuit(bool _stopped) public onlyOwner {
        stopped = _stopped;
    }

    // コントラクトを破棄して、残金をオーナーに送る関数
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}