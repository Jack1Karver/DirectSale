
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;



contract DirectSale {    
      
    address static addrOwner;
    address static addrRoot;
    address static addrNftWallet;
    
    uint128 nftId;
    uint64 endUnixTime;
    bool bought;    
    uint128 price;
    uint128 internalMessageFee;
    address addrMarket;
    uint128 walletPerc;

    uint8 only_owner = 101;
    uint8 error_small_amount = 102;
    uint8 error_deal_expired = 103;
    uint8 error_already_bought = 104;
    uint8 error_not_enough_fee = 105;
    uint8 error_canceled = 106;
    uint8 error_need_cancel_or_buy = 107;


    constructor(
        address _addrOwner,
        address _addrRoot,
        uint128 _internalMessageFee, 
        uint128 _walletPerc,
        address _addrMarket) public {

        require(msg.sender == addrRoot, 200); 
       internalMessageFee = _internalMessageFee;
       bought = false;
       endUnixTime = now;
       walletPerc = _walletPerc;
       addrMarket = _addrMarket;      
       tvm.accept();
    }   

    function upForSell(uint128 _price, uint64 duration, bool indefinitely ) public onlyOwner{      
        require(price > 0, 102);               
        price = _price;        
        if (indefinitely == true ){
        endUnixTime = 9999999999;
        }
        else {require(duration > 0, 103); 
        endUnixTime = now + duration; }
        bought = false;
        
    }

    function getInfo() public view returns  (    
    uint64 _endUnixTime,    
    uint128 _price,
    address  _addrOwner,    
    address  _addrNftWallet,    
    address _addrMarket,
    uint128 _walletPerc)
    {        
        _addrOwner = addrOwner;
         _addrNftWallet =  addrNftWallet;
        _addrMarket= addrMarket;
        _price = price;
        _endUnixTime = endUnixTime;
        _walletPerc = walletPerc;
    
    }

    function buy() public {
        require(msg.sender != addrOwner,102);
        require(now < endUnixTime,error_deal_expired);
        require(bought == false, error_already_bought);
        require(msg.value >= price + internalMessageFee, error_not_enough_fee, "Not enough fee");
        tvm.accept();
        tvm.rawReserve(address(this).balance - msg.value, 0);
        uint128 marketReward;
        if (walletPerc > 0)
        {
            marketReward = price / 10000 * walletPerc;
            if (marketReward > 0)
            {
                addrMarket.transfer(marketReward, false, 0);
            }
        }
        changeOwner(price-marketReward);        
        
    }
    function changeOwner(uint128 value) private {
        tvm.accept();
        addrOwner.transfer(value, false, 0);
        addrOwner = msg.sender;
        pullOff();
    }    

        function pullOff() public onlyOwner{            
            endUnixTime = now;
            bought = true;
        }

    modifier onlyOwner() {
        require(msg.sender == addrOwner, only_owner);
        tvm.accept();
        _;
    }



    
}
