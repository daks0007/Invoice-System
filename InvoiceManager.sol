// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
//This contract creates the item 
//This contarct also ensures that an item is getting paid for twice 
contract Item{
uint priceinwei;
    uint public pricepaid;
    uint public index;
    InvoiceManager parentContract;
    constructor(InvoiceManager _parentContract, uint _itempriceinwei, uint _index){
        priceinwei = _itempriceinwei;
        index=_index;
        parentContract =_parentContract;
    }
    receive() external payable{
        require(pricepaid == 0, "item is paid already");
        require(priceinwei == msg.value, "Only full payments allowed"); 
        pricepaid +=priceinwei  ;     
        (bool success, ) = payable(address(parentContract)).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)",index));
        require(success, "The Transaction wasn't successful, canceling");
    }
    fallback() external{

    }
}
//seller's pan is the seller's address
//Buyer's pan is the Buyer's address
contract InvoiceManager is Ownable{
    enum InvoiceState{Created, Paid}
    
    struct Invoice_Data{
        address _BuyerPan;
        address _SellerPan;
        Item _items;
        string _Identifier;
        uint _itemPrice;
        InvoiceManager.InvoiceState _state;
        uint _InvoiceDate;
    }
    mapping (address =>Invoice_Data[]) Buyers_History; //mapping buyer's address(Pan) to Invoice_data
    mapping (uint =>Invoice_Data)public Invoice; //mapping itemidex to Invoice_Data
    Invoice_Data[] internal invoices;
    event Invoice_State(uint _itemindex,uint _step, address itemaddr, uint InvoiceDate, address Buyer, address Seller);
uint itemIndex;
//createItem -Deploys the Item contract(So you can make any type of item you want..Shoes,wallet.. etc)
//anybody can create the item when onlyOwner modifier is not used
    function createItem(string memory _identifier , uint _itemprice) public {//putting onlyowner here will restrict anybody other than owner of the contract from creating the item
        Item item = new Item(this, _itemprice,itemIndex);
        Invoice[itemIndex]._SellerPan =msg.sender;
        Invoice[itemIndex]._items = item;
      Invoice[itemIndex]._Identifier = _identifier;
      Invoice[itemIndex]._itemPrice = _itemprice;
      Invoice[itemIndex]._state = InvoiceState.Created;
      emit Invoice_State(itemIndex, uint(Invoice[itemIndex]._state),address(item),0,address(0),address( Invoice[itemIndex]._SellerPan));//creating item will not give you the timestamp
      itemIndex++;
      
    }
    //anybody can buy the item created except the creater
    //Here we register the buyer and the invoice date(Unix timestamp can be changed to D/M/Y type in the frontend)
    function Buyer(uint _itemindex)public payable {
        require(Invoice[_itemindex]._itemPrice <= msg.value, "Only full payment is allowed");
       require(Invoice[_itemindex]._state==InvoiceState.Created,"Item is further in the line");
       require(Invoice[_itemindex]._SellerPan != msg.sender,"Seller can not buy their own item");
       Invoice[_itemindex]._state=InvoiceState.Paid;
       Invoice[_itemindex]._BuyerPan =msg.sender;
       Invoice[_itemindex]._InvoiceDate =block.timestamp;
       add_Invoice_To_BuyersPan(Invoice[_itemindex]._SellerPan,Invoice[_itemindex]._items,Invoice[_itemindex]._Identifier,Invoice[_itemindex]._itemPrice,Invoice[_itemindex]._state,Invoice[_itemindex]._BuyerPan,Invoice[_itemindex]._InvoiceDate);
       emit Invoice_State(_itemindex, uint(Invoice[_itemindex]._state),address(Invoice[_itemindex]._items),uint(Invoice[_itemindex]._InvoiceDate),address(Invoice[_itemindex]._BuyerPan),address(Invoice[_itemindex]._SellerPan));
    }
    //this function maps the invoices to the buyers address(Pan)
    //it creates a new instance of the Invoice_Data struct and pushes it to the Buyers_history mapping
    //it also keeps a copy of the ledger by pushing the invoice to the "invoices" array of type Invoice_Data(struct)
function add_Invoice_To_BuyersPan(address _seller, Item _items, string memory _identifier, uint _itemPrice, InvoiceManager.InvoiceState _state, address _BuyerPan ,uint _InvoiceDate)internal {
Invoice_Data memory invoice;
invoice = Invoice_Data({_SellerPan:_seller,_items:_items,_Identifier:_identifier,_itemPrice:_itemPrice,_state:_state,_BuyerPan:_BuyerPan ,_InvoiceDate:_InvoiceDate});
invoices.push(invoice);
Buyers_History[_BuyerPan].push(invoice);
}
//view function to check the buyers complete history of invoices
function BuyersHistory(address BuyerAddres)public view returns(Invoice_Data[] memory){
return Buyers_History[BuyerAddres];
}
    function renounceOwnership() public view override onlyOwner {
    revert("can not renounce ownership");
     }
     //to see the complete Invoice Ledger (invoices array)
     function InvoiceLedger() public view returns (Invoice_Data[] memory){
         return invoices;
     }
}