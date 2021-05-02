pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

/* 
In AccountChain SC
*/
contract AccountChain {

    struct client {
        address clientAddress;
        uint clientID;
        uint point;
        uint lastPurchaseTime; // used to determine whether the client is still Active. 
        string status;
        mapping (bytes32 => voucher) voucherListClient;
    }
    
    struct pharmacy {
        address pharmacyAddress;
        uint pharmacyID;
        accrualAccount accrualPoint; //Rückstellung für vergebene Punkte
        KKToppharmAccount accountKKToppharm; //Account against Toppharm
    }
    
    struct accrualAccount {
        int total;
        int taxCat1; // 8% MWST
        int taxCat2; // 7.7% MWST
        int taxCat3; // 2.5% MWST
        int taxCat4; // 0% MWST
    }
    
    struct pointRecord {
        uint pharmacyID;
        uint clientID;
        uint point;
        uint pointValue;
        uint issueTime;
        uint statusChangeTime; //document the lastes status change time to enable query within a certain period.
        uint taxCategory;
        bytes32 hashVoucherCode; // After changing the point into voucher, the hash voucher code is stored here.
        string status; // a point has three status "Active", "Converted to voucher", "Expired"
    }
    
    struct KKToppharmAccount {
        int total; // liability or receivable against Toppharm
        int taxCat1; // negative value is liability against Toppharm
        int taxCat2; // positive value is receivable against Toppharm
        int taxCat3;
        int taxCat4;
    }
    
    struct voucher {
        uint clientID;
        bytes32 hashVoucherCode;
        string status;
        uint issueTime;
        uint voucherValue;
    }
    
    struct product {
        uint productID;
        uint unitPrice;
        uint quantity;
        uint taxCategory; // There are four tax categories for different products. 1 - 8%; 2 - 7.7%; 3 - 2.5%; 4 - 0% 
    }
    
    struct transaction {
        // Transaction data is collected at the pharmacy with pharmacy's POS machine. Therefore, there is only pharmacy's address but no client's address
        uint pharmacyID;
        uint clientID;
        mapping (uint => product) productSold;
        uint point;
        uint pointValue; 
        uint transactionTime;
    }
    
    struct promotion {
        uint productID;
        uint multiple;
        uint pointValue; //(in percent) In case with promotion, the pointValue is no more equal to 0.01 CHF, normally smaller than 0.01 CHF. 
        uint beginTime;
        uint endTime;  // in days
    }
    
    
    address owner = msg.sender;
    mapping (address => uint) clientAddressList;
    mapping (address => uint) pharmacyAddressList;
    mapping (uint => uint) taxCategoryList;
    mapping (uint => transaction) transactionList;
    mapping (uint => client) clientList;
    uint lastUpdatePromotion = 0; //initialize the last update time for the promotionList
    uint lastCheckClientActivity = 0; //initialize the last check time for client activity
    uint timeIntervalPromotion = 1; //set the promotionList update time interval (unit is in hours), the default value is every hour.
    uint timeIntervalClientActivity = 30; //set the time internal to check the client status, the default value is every 30 days.
    uint timeInactivity = 24; //clients' status is set to be inactive if the last purchase with the bonus card is for more than a period time. 
    // The default value is 24 monthes.
    uint startPoint = 499; // clients obtain a start point while joining the program, current value = 499
    uint voucherValue = 5; // Every voucher has a certain value, the default value is 5 CHF.
    uint PointValidityPeriod = 3; // As default, a point has a validity for 3 years
    uint VoucherValidityPeriod = 2; // As default, a voucher has a validity of 2 years.
    uint lengthTransactionList = 0; // This variable is used to document the length of the mapping "TransactionList"
    uint lengthClientList = 0; // This variable is used to document the length of the mapping "ClientList".
    // This also means when voucherValue * 100 points is reached, the voucher is issued.
    
    //It is difficult to query all data from a mapping. Therefore, the following two lists are kept as arrays to simplfy query for the whole list
    promotion[] promotionList; 
    pharmacy[] pharmacyList;
    //The following two lists are kept as array because there is no strict key which can be used for mapping
    voucher[] voucherList;
    pointRecord[] pointRecordList;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    event GenerateVoucherCode(uint _clientID);

    function addNewClient(uint _clientID, address _clientAddress) public  {
        clientList[_clientID].clientAddress = _clientAddress;
        clientList[_clientID].clientID = _clientID;
        clientList[_clientID].point = startPoint;
        clientList[_clientID].lastPurchaseTime = block.timestamp;
        lengthClientList++;
    }
    
    function addClientAddressList(address _address, uint _clientID) public onlyOwner {
        clientAddressList[_address] = _clientID;
    }
    
    function addTaxCategoryList(uint _productID, uint _taxCategory) public onlyOwner {
        taxCategoryList[_productID] = _taxCategory;
    }
    
    function addPharmacy(address _address, uint _pharmacyID) public onlyOwner {
        pharmacyAddressList[_address] = _pharmacyID;
    }
    
    function setStartPoint(uint startpoint) public onlyOwner {
        startPoint = startpoint;
    }
    
    function queryStartPoint() public returns (uint startPoint){
        return startPoint;
    }
    
    function setClientActivityParameter(uint _timeIntervalClientActivity, uint _timeInactivity) public onlyOwner {
        timeIntervalClientActivity = _timeIntervalClientActivity;
        timeInactivity = _timeInactivity;
    }
    
     function queryClientActivityParameter() public returns (uint timeIntervalClientActivity, uint timeInactivity) {
        return(timeIntervalClientActivity, timeInactivity);
    }
    
    function setVoucherValue(uint _voucherValue) public onlyOwner {
        voucherValue = _voucherValue;
    }
        
    // check whether the client is still active, if they haven't made any purchase with their bonus card for more than a period time (default value is 2 years)
    // Their status will be changed to <Inactive>
    function checkClientActivity() internal {
        // check the client status maximal 1 time per month to save the computation resource
        if (block.timestamp - lastCheckClientActivity > timeIntervalClientActivity * 1 days) {
            for (uint i=0; i < lengthClientList; i++) {
                if (block.timestamp - clientList[i].lastPurchaseTime > timeInactivity * 4 weeks) {
                    clientList[i].status = "Inactive";
                    clientList[i].point = 0;
                }
            }
        }
    }
    
    
    function addTransaction(uint _clientID, uint _pharmacyID, product[] memory _product, uint transactionID) public {
        // Add the new transaction at the end of the transactionList
        uint _point;
        uint _pointValue;
        lengthTransactionList++;
        //transactionList.push(transaction(msg.sender, _clientID,_product,0,0 ,block.timestamp));
        for (uint i= 0; i < _product.length; i++){
            transactionList[transactionID].productSold[_product[i].productID] = _product[i];
            _point = calcPoint(_product[i]);
            _pointValue = calcPointValue( _product[i]);            
            addPointRecord(_clientID, _pharmacyID, _point, _pointValue, _product[i]);
            transactionList[transactionID].point = _point;
            transactionList[transactionID].pointValue = _pointValue;
        }
         transactionList[transactionID].pharmacyID = _pharmacyID;
        checkClientActivity();
        expirePoint();
        // Check whether a point is expired.
        // Update the client point statement
            if ((compareStrings(clientList[_clientID].status, "Active"))) {
                clientList[_clientID].point = clientList[_clientID].point + _point;
                clientList[_clientID].lastPurchaseTime = block.timestamp;
                //if the client has more than 500 points, voucher is issued
                //The voucher Code is generated off-chain. The off-Chain program gives a hashVoucherCode back.
                //An Event is used to trigger the process off-chain to generate a voucher Code.
                //Only the client ID is given in the log file to guarantee a higher security.
                if (clientList[_clientID].point >= 100 * voucherValue) {
                    emit GenerateVoucherCode(clientList[_clientID].clientID);
                }
        }
    }
    
    // Add the point record into pointRecordList, the initial status is Active
    // Add book the point at the pharmacy's accrual Account
    function addPointRecord(uint _clientID, uint _pharmacyID, uint _point, uint _pointValue,  product memory  _product) internal {
            pointRecordList[pointRecordList.length].clientID = _clientID;
            pointRecordList[pointRecordList.length].pharmacyID = _pharmacyID;
            pointRecordList[pointRecordList.length].point = _point;
            pointRecordList[pointRecordList.length].pointValue = _pointValue;
            pointRecordList[pointRecordList.length].issueTime = block.timestamp;
            pointRecordList[pointRecordList.length].taxCategory = taxCategoryList[_product.productID];
            pointRecordList[pointRecordList.length].status = "Active";
            bookAccrualAccount(_pharmacyID, int(_pointValue), taxCategoryList[_product.productID]);
    }
    
    // If the point is expred, two actions have to be made:
    // 1. the point must be deducted from the client's point account
    // 2. the accrual account of the pharmacy has to be adjusted.
    function expirePoint() internal {
        for (uint i=0; i<pointRecordList.length; i++) {
            if (pointRecordList[i].issueTime + PointValidityPeriod * 365 days < block.timestamp && compareStrings(pointRecordList[i].status, "Active")) {
                pointRecordList[i].status = "Expired";
                pointRecordList[i].statusChangeTime = block.timestamp;
                clientList[pointRecordList[i].clientID].point = clientList[pointRecordList[i].clientID].point - pointRecordList[i].point;
                for (uint k=0; k<pharmacyList.length; k++) {
                    if (pharmacyList[i].pharmacyID == pointRecordList[i].pharmacyID) {
                    uint _taxCategory = pointRecordList[i].taxCategory;
                    pharmacyList[k].accrualPoint.total = pharmacyList[k].accrualPoint.total - int(pointRecordList[i].pointValue);
                    bookAccrualAccount(pharmacyList[i].pharmacyID, -int(pointRecordList[i].pointValue ), pointRecordList[i].taxCategory);
                    break;
                }
                }
            } 
        }
    }
    // This function changes the point status in pointList from "Active" to "Converted into voucher"
    // Reduce the accrual account of pharmacy and book it into KKToppharmAccount for bill 
    function convertPoint(uint _clientID, bytes32 _hashVoucherCode) internal {
        uint _point = voucherValue * 100;
        for (uint i=0; i<pointRecordList.length; i++) {
            if (_point > 0) { //The point required to issue a voucher is still positive. This means that more point records must be found to issue this voucher.
            if (compareStrings(pointRecordList[i].status,"Active") && pointRecordList[i].clientID == _clientID) {
                //First Case: one point record has less than 500 points.
                //Multiple point records must be combined to issue to voucher
                // The point required to issure a voucher is deducted and it 
                if (pointRecordList[i].point < _point){
                    pointRecordList[i].status = "Coverted into voucher";
                    pointRecordList[i].hashVoucherCode = _hashVoucherCode;
                    pointRecordList[i].statusChangeTime = block.timestamp;
                    bookAccrualAccount(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    bookKKToppharm(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    _point = _point - pointRecordList[i].point; // calculate the remaining points required to issue a voucher
                    // Second case, one point record has exactly 500 points to issue a voucher
                } else if (compareStrings(pointRecordList[i].status,"Active") && pointRecordList[i].point == _point) {
                    pointRecordList[i].status = "Coverted into voucher";
                    pointRecordList[i].hashVoucherCode = _hashVoucherCode;
                    pointRecordList[i].statusChangeTime = block.timestamp;
                    bookAccrualAccount(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    bookKKToppharm(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    break;
                } else if (compareStrings(pointRecordList[i].status,"Active") && pointRecordList[i].point > _point) { 
                // In case, that one point record has more than 500 points (or more than the remaining points required to issue a voucher). Only part of the points from this record is  
                // converted to voucher and the remaining points are stored as a new point record at the end of pointRecordList.
                    pointRecordList[pointRecordList.length] = pointRecordList[i];
                    pointRecordList[pointRecordList.length].point = pointRecordList[i].point - _point;
                    pointRecordList[pointRecordList.length].statusChangeTime = block.timestamp;
                    pointRecordList[i].status = "Coverted into voucher";
                    pointRecordList[i].hashVoucherCode = _hashVoucherCode; 
                    pointRecordList[i].statusChangeTime = block.timestamp;
                    sortPointRecord();
                    bookAccrualAccount(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    bookKKToppharm(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    break;
                }
            }
        }
        }
    }
    // This function sorts the issueTime of point records in pointRecordList in a ascending order 
    // It is used to garantie that the old points are used at first.
    // The algorithmus applied is insert sort.
    function sortPointRecord() internal {
        uint _timestamp = pointRecordList[pointRecordList.length-1].issueTime;
        uint position;
        bool positionFound = false;
        pointRecord[] memory temp = pointRecordList;
        for (uint i = 0; i < pointRecordList.length - 1; i++) {
            if (pointRecordList[i].issueTime < _timestamp) {
            temp[i] = pointRecordList[i];
        } else if (pointRecordList[i].issueTime >= _timestamp && positionFound == false) {
            positionFound = true;
            temp[i] = pointRecordList[pointRecordList.length]; // The last record is inserted to the position based on issueTime
            // the remaining point records are shifted one position back.
        } else if (pointRecordList[i].issueTime >= _timestamp && positionFound == true) {
            temp[i+1] = pointRecordList[i];
        }
        pointRecordList = temp;
    }
    }
    
    function deleteExpiredPointRecord () public onlyOwner {
        for (uint i=0; i<pointRecordList.length; i++) {
            if (compareStrings(pointRecordList[i].status,"Expired")) {
                delete pointRecordList[i];
                i--;
            }
        }
    }
    // This function adds or deducts point accrual from pharmacy´s accrual account
    // The local variable _pointValue can be negative which means deduction
    function bookAccrualAccount(uint _pharmacyID, int _pointValue, uint _taxCategory) internal {
        for (uint i=0; i<pharmacyList.length; i++) {
            if (pharmacyList[i].pharmacyID == _pharmacyID) {
                if (_taxCategory == 1) {
                    pharmacyList[i].accrualPoint.taxCat1 = pharmacyList[i].accrualPoint.taxCat1 + _pointValue;
                    pharmacyList[i].accrualPoint.total = pharmacyList[i].accrualPoint.total + _pointValue;
                } else if (_taxCategory == 2) {
                    pharmacyList[i].accrualPoint.taxCat2 = pharmacyList[i].accrualPoint.taxCat2 + _pointValue;
                    pharmacyList[i].accrualPoint.total = pharmacyList[i].accrualPoint.total + _pointValue;
                } else if (_taxCategory == 3) {
                    pharmacyList[i].accrualPoint.taxCat3 = pharmacyList[i].accrualPoint.taxCat3 + _pointValue;
                    pharmacyList[i].accrualPoint.total = pharmacyList[i].accrualPoint.total + _pointValue;
                } else if (_taxCategory == 4) {
                    pharmacyList[i].accrualPoint.taxCat4 = pharmacyList[i].accrualPoint.taxCat4 + _pointValue;
                    pharmacyList[i].accrualPoint.total = pharmacyList[i].accrualPoint.total + _pointValue;
                }
            }
        }
    }
    // This function calculates the receivable / liability of a pharmacy against Toppharm at the time of issuing or redeeming the voucher
    // positive value means liability and negative value means receivalbe
    function bookKKToppharm(uint _pharmacyID, int _pointValue, uint _taxCategory) internal {
        for (uint i=0; i<pharmacyList.length; i++) {
            if (pharmacyList[i].pharmacyID == _pharmacyID) {
                if (_taxCategory == 1) {
                    pharmacyList[i].accountKKToppharm.taxCat1 = pharmacyList[i].accountKKToppharm.taxCat1 + _pointValue;
                    pharmacyList[i].accountKKToppharm.total = pharmacyList[i].accountKKToppharm.total + _pointValue;
                } else if (_taxCategory == 2) {
                    pharmacyList[i].accountKKToppharm.taxCat2 = pharmacyList[i].accountKKToppharm.taxCat2 + _pointValue;
                    pharmacyList[i].accountKKToppharm.total = pharmacyList[i].accountKKToppharm.total + _pointValue;
                } else if (_taxCategory == 3) {
                    pharmacyList[i].accountKKToppharm.taxCat3 = pharmacyList[i].accountKKToppharm.taxCat3 + _pointValue;
                    pharmacyList[i].accountKKToppharm.total = pharmacyList[i].accountKKToppharm.total + _pointValue;
                } else if (_taxCategory == 4) {
                    pharmacyList[i].accountKKToppharm.taxCat4 = pharmacyList[i].accountKKToppharm.taxCat4 + _pointValue;
                    pharmacyList[i].accountKKToppharm.total = pharmacyList[i].accountKKToppharm.total + _pointValue;
                } else if (_taxCategory == 5) { //Only the total KKToppharm Account is relevant.
                   pharmacyList[i].accountKKToppharm.total = pharmacyList[i].accountKKToppharm.total + _pointValue;
                }
            }
        }
    }
    
    function issueVoucher(uint _clientID, bytes32  _hashVoucherCode) internal {
        uint _nrVoucherIssued = clientList[_clientID].point / (100*voucherValue);
        voucherList[voucherList.length].clientID = _clientID;
        voucherList[voucherList.length].hashVoucherCode = _hashVoucherCode;
        voucherList[voucherList.length].status = "Active";
        voucherList[voucherList.length].issueTime = block.timestamp;
        // deduct points from client´s point statement and set the point record to "Converted to voucher"
        // Adjust the point accrual account for the pharmacy
        bookPointfromClient(_clientID, _nrVoucherIssued * 100 * voucherValue);
        convertPoint(_clientID, _hashVoucherCode);
    }
    
    function bookPointfromClient(uint _clientID, uint _point) internal {
                clientList[_clientID].point = clientList[_clientID].point - _point;
    }
 
    function queryVoucherList(string memory _status) public onlyOwner returns(voucher[] memory voucherList){
        if (compareStrings(_status, "All")) {
            return voucherList;
        } else if (compareStrings(_status, "Active")) {
            voucher[] memory tmp;
            for (uint i=0; i < voucherList.length; i++) {
                if (compareStrings(voucherList[i].status, "Active")) {
                    tmp[tmp.length] = voucherList[i];
                } else if (compareStrings(_status, "Inactive")) {
                    voucher[] memory tmp;
                    for (i=0; i < voucherList.length; i++) {
                    if (compareStrings(voucherList[i].status, "Inactive")) {
                        tmp[tmp.length] = voucherList[i];
                }
            }
        }
    }
        }
    }
    
    function calcPoint(product memory _product) internal returns(uint _point){
        uint _point = 0;
        uint promotionMultiple = 1; // set the initial value for promotion equal to 1
        promotionMultiple = queryPromotionMultiple(_product.productID);
        _point = _point + _product.unitPrice*_product.quantity*promotionMultiple;
        return _point;
    }
    
    function calcPointValue(product memory _product) internal returns(uint _pointValue){
        uint _point = 0;
        uint _pointValue = 100; //Default value in percent, equal to 100 means that one point has value of 0.01 CHF
        uint promotionMultiple = 1; // set the initial value for promotion equal to 1
        promotionMultiple = queryPromotionMultiple(_product.productID);
        _pointValue = queryPromotionPointValue(_product.productID);
        _point = _point + _product.unitPrice*_product.quantity*promotionMultiple*_pointValue/100;
        return _point;
    }
    
    function redeemVoucher(uint _clientID, uint _VoucherCode, uint _pharmacyID, uint _Salt) public returns (bool validVoucher) {
        validVoucher = false; // _pharmacyID here is the pharmacy, where the client redeemed her voucher.
        expireVoucher();
        bytes32 _hashVoucherCode = keccak256(abi.encodePacked(_VoucherCode,_Salt));
        for (uint i=0; i<voucherList.length; i++) {
            if(voucherList[i].hashVoucherCode == _hashVoucherCode && voucherList[i].clientID == _clientID) {
                validVoucher = true;
                uint _voucherValue = voucherList[i].voucherValue;
                    changeVoucherStatus(voucherList[i].hashVoucherCode, "Used");
                for (uint k=0; k<pharmacyList.length; k++) {
                    if (pharmacyList[k].pharmacyID == _pharmacyID) {
                    bookKKToppharm(_pharmacyID, -int(_voucherValue), 0);
                    break;
                    }
                }
            }
        }
    }
    // When Voucher is expired, the voucher status is set to "Expired"
    function expireVoucher() internal {
        for (uint i=0; i<voucherList.length; i++) {
            if (voucherList[i].issueTime + VoucherValidityPeriod * 365 days < block.timestamp && compareStrings(voucherList[i].status, "Active")) {
                voucherList[i].status = "Expired";
                pointRecord[] memory _pointRecord;
                _pointRecord = pointListrelatedtoVoucher(voucherList[i].hashVoucherCode);
                changeVoucherStatus(voucherList[i].hashVoucherCode,  "Expired");
                for (uint j=0; j<_pointRecord.length; j++){
                for (uint k=0; k<pharmacyList.length; k++) {
                    if (pharmacyList[k].pharmacyID == _pointRecord[j].pharmacyID) {
                    uint _taxCategory = _pointRecord[j].taxCategory;
                    pharmacyList[k].accountKKToppharm.total = int(pharmacyList[k].accountKKToppharm.total) - int(_pointRecord[j].pointValue);
                    bookKKToppharm(_pointRecord[j].pharmacyID, -int(_pointRecord[j].pointValue), _taxCategory);
                    break;
                    }
                }
                }
            } 
        }
    }
    
    function pointListrelatedtoVoucher (bytes32 _hashVoucherCode) internal returns(pointRecord[] memory){
        pointRecord[] memory ret;
        uint idx;
        for (uint i=0; i<pointRecordList.length; i++) {
            if (pointRecordList[i].hashVoucherCode == _hashVoucherCode) {
                ret[idx] = pointRecordList[i]; 
                idx++;
            }
        }
        return ret;
    }
    
    function changeVoucherStatus(bytes32 _hashVoucherCode, string memory _newStatus) internal {
        for (uint i=0; i < voucherList.length; i++) {
            if (_hashVoucherCode == voucherList[i].hashVoucherCode){
                voucherList[i].status = _newStatus;
                break;
            }
        }
    }
    
    
    function addPromotion(uint _productID, uint _multiple, uint _pointValue, uint _beginTime, uint _endTime ) public {
        updatePromotion();
        promotionList[promotionList.length].productID = _productID;
        promotionList[promotionList.length].multiple = _multiple;
        promotionList[promotionList.length].pointValue = _pointValue;
        promotionList[promotionList.length].beginTime = _beginTime;
        promotionList[promotionList.length].endTime = _endTime;
    }
    
    function queryPromotionMultiple(uint productID) internal returns(uint){
        uint _multiple = 1;
            for (uint i = 0; i < promotionList.length; i++) {
            if (promotionList[i].productID == productID && promotionList[i].beginTime <= block.timestamp && promotionList[i].endTime >= block.timestamp) {
                    _multiple = promotionList[i].multiple;
                    break;
                }
            }
        return _multiple;
    }
    
    function queryPromotionPointValue(uint productID) internal returns(uint){
        uint _pointValue = 1;
            for (uint i = 0; i < promotionList.length; i++) {
            if (promotionList[i].productID == productID && promotionList[i].beginTime <= block.timestamp && promotionList[i].endTime >= block.timestamp) {
                    _pointValue = promotionList[i].pointValue;
                    break;
                }
            }
        return _pointValue;
    }
    
    function queryPromotionList() public returns(promotion[] memory){
        updatePromotion();
        return promotionList;
    }
    
    function updatePromotion() internal {
        if (block.timestamp - lastUpdatePromotion > timeIntervalPromotion) { // used to avoid too frequent update to promotionList
        // The default setting is maximal one update per hour
            for (uint j = 0; j < promotionList.length; j++) {
                // delete expired promotion from the promotionList
                if (promotionList[j].endTime < block.timestamp) { 
                    delete promotionList[j];
                    j--; // After deleting one expired element, the index stays at the same position for next loop
                }
            }
        lastUpdatePromotion = block.timestamp; //update the last promotionList update time
        }
    }
    
    function setPromotionListUpdateTimeinterval(uint hour) public onlyOwner {
        timeIntervalPromotion = hour * 1 hours;
    }
    
        function setVoucherValidityPeriod(uint _voucherValidity) public onlyOwner {
        VoucherValidityPeriod = _voucherValidity * 365 days;
    }
    
        function setPointValidityPeriod(uint _pointValidity) public onlyOwner {
        PointValidityPeriod = _pointValidity * 365 days;
    }
    
    function compareStrings(string memory s1, string memory s2) public view returns(bool){
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
}
}