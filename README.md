Welcome to AccountChain
=============================


- [Introduction](#Introduction)
- [Project Description](#Project-Description)
- [Chaincode Description](#Chaincode-Description)
- [Main Functions](#Main-Functions)
	- [addTransaction](#addTransaction)
	- [addPointRecord](#addPointRecord)
	- [expirePoint](#expirePoint)
	- [issueVoucher](#issueVoucher)
	- [convertPoint](#convertPoint)
	- [expireVoucher](#expireVoucher)
	- [redeemVoucher](#redeemVoucher)
- [Other Functions](#Other-Functions)
	- [calcPoint](#calcPoint)
	- [calcPointValue](#calcPointValue)
	- [sortPointRecord](#sortPointRecord)
	- [bookPointfromClient](#bookPointfromClient)
	- [bookKKToppharm](#bookKKToppharm)
	- [bookAccrualAccount](#bookAccrualAccount)
	- [addPromotion](#addPromotion)
	- [queryPromotionMultiple](#queryPromotionMultiple)
	- [queryPromotionPointValue](#queryPromotionPointValue)
	- [setPromotionListUpdateTimeinterval](#setPromotionListUpdateTimeinterval)
	- [setPointValidityPeriod](#setPointValidityPeriod)
	- [setVoucherValidityPeriod](#setVoucherValidityPeriod)
	- [pointListrelatedtoVoucher](#pointListrelatedtoVoucher)
	- [changeVoucherStatus](#changeVoucherStatus)
	- [compareStrings](#compareStrings)
- [Link](#link)
	- [Anchor links](#anchor-links)
- [Blockquote](#blockquote)
- [Image | GIF](#image--gif)
- [Style Text](#style-text)
	- [Italic](#italic)
	- [Bold](#bold)
	- [Strikethrough](#strikethrough)
- [Code](#code)
- [Email](#email)
- [Table](#table)
	- [Table Align](#table-align)
    	- [Align Center](#align-center)
    	- [Align Left](#align-left)
    	- [Align Right](#align-right)
- [Escape Characters](#escape-characters)
- [Emoji](#emoji)
- [Shields Badges](#Shields-Badges)
- [Markdown Editor](#markdown-editor)
- [Links for User Interfaces](#Links-for-User-Interfaces)



# Introduction
Welcome to *AccountChain©*!

*AccountChain©* is a blockchain-based customer loyalty platform where transactions of non-monetized loyalty points are securely processed and immutably recorded in a permissioned ledger environment. The result is a **decentral**, **fully transparent**, and **fraud-protected** real-time accounting system. Moreover, it includes a cryptographically secured redemption process of loyalty points, mitigating risks of counterfeited occurrence of financial liabilities. AccountChain© is based on Hyperledger Fabric Blockchain and operates in a private permissioned ledger environment. 

<img width="1039" alt="rename_screenshot" src="images/3D-mockup.jpg">

# Project Description

Based on the Request for Solution of TopPharm, the main task of this project was to examine the question whether and to what extent blockchain technology can help to improve customer loyalty programs with regard to real-time data integrity, transparency, and security. In this respect, we have evaluated whether blockchain technology in fact delivers a value added compared to a traditional database approach. The result of our assessment clearly underlines that there are significant advantages for all previously mentioned criteria. We have therefore conceptualized *AccountChain©* which is a decentral, fully transparent and fraud-protected loyalty platform, embedded in a permissioned ledger Hyperledger Fabric blockchain environment. It ensures data security through cryptographically signed transaction history and helps to increase efficiency by automating accounting processes. The concept further includes a special focus on a fraud-protected voucher redemption process, applying cryptographic hash functions to mitigate the risk of counterfeited occurrence of financial liabilities in the network. To summarize, the *AccountChain©* ecosystem creates transparency, data security, and increased efficiency further leading to cost savings, for customer loyalty networks consisting of independent legal entities who do not necessarily trust each other but pursue the same business goals. 

# Technical Documentation

This technical documentation mainly contains the explanation to the smart contract. Additionally, the 2 mock-up user interfaces are also shortly described. 
- The Smart Contract code **AccountChain.sol** written in solidity, can be found on the GitHub Page and it has been uploaded through Adam as well.
- The Client User Interface [AccountChain App](https://xd.adobe.com/view/b63ae9ae-8d0c-4d6c-b447-ee5eade2a5d9-e369/?fullscreen&hints=off)
- The Pharmacy User Interface [AccountChain WebApp](https://public.tableau.com/profile/dominik.merz#!/vizhome/shared/354DZRXPK)

# Chaincode Description

Chaincode is the Smart Contract in Hyperledger, which plays a central role in the *AccountChain©* application. It documents transactions, manages promotions, calculates tax and current accounts, and cryptographically verifies the actual existence and validity of vouchers during the redemption process. The main functions contained in our Chaincode are explained in the following.

## Main Functions

The main functions include [addTransaction](#addTransaction), [addPointRecord](#addPointRecord), [expirePoint](#expirePoint), [issueVoucher](#issueVoucher), [convertPoint](#convertPoint), [expireVoucher](#expireVoucher), [redeemVoucher](#redeemVoucher) 7 functions. These functions contain the substantial part of the codes to document transactions, calculate tax and current accounts, and  verify vouchers.

### addTransaction

Everything starts with a purchase in one of the branches in the loyalty network. This function documents transactions on the blockchain, therefore denoting the first step in a loyalty point’s journey. 

The information contained in a transaction is the client ID, the respective pharmacy ID, a list of purchased products and a unique transaction ID. 
```solidity
   struct transaction {
        uint pharmacyID;
        uint clientID;
        mapping (uint => product) productSold;
        uint point;
        uint pointValue; 
        uint transactionTime;
    }
```
All transactions are stored in a mapping <transactionList> using the unique transaction ID as the key. 
```solidity
mapping (uint => transaction) transactionList;
```   
addTransaction further calls the [calcPoint](#calcPoint) and [calcPointValue](#calcPointValue) functions to calculate the points and point values related to the transaction and to store this information as part of a transaction in transactionList. The attribute PointValue is introduced to record the value of points from the issuing pharmacy’s point of view. Let’s elaborate briefly on this. If points issued are not combined with any promotion, a point has a (default) value of CHF 0.01. On the other side, let’s assume that there exists a x20 multi-point promotion. In this case, from a pharmacy’s point of view, one point has a value equal to CHF 0.0005 since the promotion is paid by the producer, not by pharmacies. In other words, the fraction of additional points issued here (19/20) must be charged to third parties. For the pharmacy itself, the points issued in this transaction therefore only have a value (to be paid) of CHF 0.01/20 = CHF 0.0005. Additionally, data related to multi-point promotions is stored in promotionList. The promotions can be added through [addPromotion](#addPromotion) function. After calculating the number of points and their respective point value, the addTransaction function updates the PointRecordList by calling [addPointRecord](#addPointRecord) function and therefore the client’s point account. After checking the point validity through [expirePoint](#expirePoint) function, an event will be triggered to create a clean voucher code in an off-chain application as soon as a client has reached a point balance of 500.  
	
```solidity
   function addTransaction(uint _clientID, uint _pharmacyID, product[] memory _product, uint transactionID) public {
        uint _point;
        uint _pointValue;
        lengthTransactionList++;
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
            if ((compareStrings(clientList[_clientID].status, "Active"))) {
                clientList[_clientID].point = clientList[_clientID].point + _point;
                clientList[_clientID].lastPurchaseTime = block.timestamp;
                if (clientList[_clientID].point >= 100 * voucherValue) {
                    emit GenerateVoucherCode(clientList[_clientID].clientID);
                }
        }
    }
```
### addPointRecord

Let's have a look on how loyalty points are processed in Chaincode. The addPointRecord function is triggered by [addTransaction](#addTransaction) to record points in PointRecordList. Each point has attributes such as the client ID, pharmacy ID, point value, point issue timestamp, tax category of the respective purchased products and a status. 
```solidity
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
```
```solidity
   pointRecord[] pointRecordList;
```
A point can exhibit three different states – “Active”; “Converted into voucher” and “Expired”, whereby the status is set to “Active” at issuance.  After the points have been recorded, the addPointRecord function triggers the [bookAccrualAccount](#bookAccrualAccount) function to book the total value of points issued in the pharmacy’s point accrual account. This accrued balance denotes a sell discount, which is VAT-deductible. 
```solidity
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
```
### expirePoint

If a customer is inactive for three years, the respective points will expire. The expirePoint function makes sure that the status of points whose holding period overrides the expiration date is set to “Expired”. This process involves two booking activities. First, expired points are deducted from the client’s point account and second, the pharmacy’s point accrual account is adjusted down by the embedded point value of the expired points through [bookAccrualAccount](#bookAccrualAccount) function. This function is called by the above-metioned [addTransaction](#addTransaction) function to make sure that expired points are deducted before any point balance is updated. The validity period can be changed through function [setPointValidityPeriod](#setPointValidityPeriod).
```solidity
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
```

### issueVoucher

The points' journey continue in the system as a voucher, in case the client's point account reaches 500 points. The status in the pointRecordList is changed to "Converted to voucher" through function [convertPoint](#convertPoint). issueVoucher function is called by the off-chain application after generating a hash voucher code. It deducts the amount of points used to issue the respective voucher from a client’s point account through [bookPointfromClient](#bookPointfromClient). Additionally, the [convertPoint](#convertPoint) function (explained below) also executes all necessary accounting calculations. The hash voucher code (and not the clean voucher code of course) is stored into VoucherList, together with the client ID and voucher issuance time. Moreover, the voucher status is set to “Active”. This is important since only vouchers with a valid hash voucher code and status “Active” can be redeemed later on.
```solidity
    struct voucher {
        uint clientID;
        bytes32 hashVoucherCode;
        string status;
        uint issueTime;
        uint voucherValue;
    }
```
```solidity
   function issueVoucher(uint _clientID, bytes32  _hashVoucherCode) internal {
        uint _nrVoucherIssued = clientList[_clientID].point / (100*voucherValue);
        voucherList[voucherList.length].clientID = _clientID;
        voucherList[voucherList.length].hashVoucherCode = _hashVoucherCode;
        voucherList[voucherList.length].status = "Active";
        voucherList[voucherList.length].issueTime = block.timestamp;
        bookPointfromClient(_clientID, _nrVoucherIssued * 100 * voucherValue);
        convertPoint(_clientID, _hashVoucherCode);
    }
```
### convertPoint

Once the amount of points used to issue the respective voucher is deducted from the client’s point account in the [issueVoucher](#issueVoucher) function, the convertPoint function converts these points by changing the status from “Active” to “Converted into voucher”. Subsequently, the corresponding value is deducted from the pharmacy’s point accrual account and is booked as a liability in the pharmacy’s KKToppharm account. This denotes the current account of the pharmacy, containing consolidated receivables and liabilities against other entities in the network. By converting points into a voucher, the FIFO (first-in-first-out) ruling is applied to guarantee that old points are converted first. If a single point record is not yet enough to issue a voucher directly, the convertPoint function combines multiple point records to issue a voucher. On the other side, if a single point record has more points than the required amount to issue a voucher (500 in our case), the status of this point record is directly set to “Converted into voucher”. The unused part of points in this record is written into a new point record at the end of the <PointRecordList> where the point issuance time is equal to the initial point record timestamp. Next, the pointRecordList is sorted through [sortPointRecord](#sortPointRecord).  
```solidity
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
```

### expireVoucher


### redeemVoucher


## Other Functions

The other functions play a supporting role in the Smart Contract to realize the *AccountChain©* functions. 

### calcPoint

The calcPoint function is called by [addTransaction](#addTransaction) to calculate the total points that a client can obtain for one purchase. This function calls [queryPromotionMultiple](#queryPromotionMultiple) to calculate up-to-date promotion applied.
```solidity
   function calcPoint(product memory _product) internal returns(uint _point){
        uint _point = 0;
        uint promotionMultiple = 1; // set the initial value for promotion equal to 1
        promotionMultiple = queryPromotionMultiple(_product.productID);
        _point = _point + _product.unitPrice*_product.quantity*promotionMultiple;
        return _point;
    }
``` 
### calcPointValue

The calcPointValue function is called by [addTransaction](#addTransaction) to calculate the point value that a pharmacy has to book in their point accrual account for one purchase. This function calls [queryPromotionMultiple](#queryPromotionMultiple) to calculate up-to-date promotion applied and calls [queryPromotionPointValue](#queryPromotionPointValue) to calculate the value for each issued point. Ordinarily, the pointValue equals to 1/Promotion_Multiple. However, the producers can set the pointValue smaller than 1/Promotion_Multiple to encourage the pharmacies to sell their products.
```solidity
    function calcPointValue(product memory _product) internal returns(uint _pointValue){
        uint _point = 0;
        uint _pointValue = 100; //Default value in percent, equal to 100 means that one point has value of 0.01 CHF
        uint promotionMultiple = 1; // set the initial value for promotion equal to 1
        promotionMultiple = queryPromotionMultiple(_product.productID);
        _pointValue = queryPromotionPointValue(_product.productID);
        _point = _point + _product.unitPrice*_product.quantity*promotionMultiple*_pointValue/100;
        return _point;
    }
```
### sortPointRecord

The sortPointRecord sorts the pointRecord with its timestamp in a acending order. The algorithms applies is insert sorting.
```solidity
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
```
### bookPointfromClient

This function is called to adjust the client's point account in case of points expiration and issuring voucher.
```solidity
    function bookPointfromClient(uint _clientID, uint _point) internal {
                clientList[_clientID].point = clientList[_clientID].point - _point;
    }
```

### bookKKToppharm

bookKKToppharm function is used to book the current account of one pharmacy. The current account books liabilies of one pharmacy, when the points issued by this pharmacy are converted into voucher and books receivables, when this pharmacy accepts the client voucher. The booking is carried out in 4 different tax categories.
```solidity
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
```

### bookAccrualAccount

This function changes the point accrual account of a pharmacy. The point accrual account denotes the point value issued by a pharmacy. This point value in the point accrual account is considered as sell discount in pharmacy's accounting, which is VAT-deductible. Therefore, the booking is categorized into 4 different tax classes.
```solidity
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
```

### addPromotion

This function is used to add a promotion into the system. A promotion must contain the product ID, on which the promotion is applied for, the corresponding multiple and point value, and the beginning time and ending time of the promotion.
```solidity
    struct promotion {
        uint productID;
        uint multiple;
        uint pointValue; //(in percent) In case with promotion, the pointValue is no more equal to 0.01 CHF, normally smaller than 0.01 CHF. 
        uint beginTime;
        uint endTime;  // in days
    }
```

```solidity
   function addPromotion(uint _productID, uint _multiple, uint _pointValue, uint _beginTime, uint _endTime ) public {
        updatePromotion();
        promotionList[promotionList.length].productID = _productID;
        promotionList[promotionList.length].multiple = _multiple;
        promotionList[promotionList.length].pointValue = _pointValue;
        promotionList[promotionList.length].beginTime = _beginTime;
        promotionList[promotionList.length].endTime = _endTime;
    }
```
### queryPromotionMultiple
This function is called by [calcPoint](#calcPoint) and [calcPointValue](#calcPointValue) functions to calculate the up-to-date promotions. This function sets the multiple = 1 as default. First, the promotion is updated to its latest state by calling  [updatePromotion](#updatePromotion) function.
```solidity
    function queryPromotionMultiple(uint productID) internal returns(uint){
        uint _multiple = 1;
        updatePromotion();
            for (uint i = 0; i < promotionList.length; i++) {
            if (promotionList[i].productID == productID && promotionList[i].beginTime <= block.timestamp && promotionList[i].endTime >= block.timestamp) {
                    _multiple = promotionList[i].multiple;
                    break;
                }
            }
        return _multiple;
    }
```
### queryPromotionPointValue
This function is called by [calcPointValue](#calcPointValue) functions to calculate the up-to-date point value applied to a promotion.
```solidity
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
```
### updatePromotion
updatePromotion function updates the promotion information to its latest state. To avoid too frequent update for a higher efficiency and lower system running cost, the default setting is maximal only one update per hour. This setting fulfills the needs in the reality, because a promotion in the system starts at the beginning of one day at 00:00:00 and ends at 23:59:59 on the same day or on another day. During overnight period (11 pm. to 1 am. on the following), pharmacies are closed and the client cannot make their purchase during this period. Therefore, it is guaranteed that the points calculated are combined with the up-to-date promotion. The default setting of promotion update time interval can be changed through [setPromotionListUpdateTimeinterval](#setPromotionListUpdateTimeinterval) function. We choose maximal 1 update per hour to provide pharmacies the opportunities to set some flash sales.
```solidity
   function updatePromotion() internal {
        if (block.timestamp - lastUpdatePromotion > timeIntervalPromotion) { // used to avoid too frequent update to promotionList to improve the efficiency
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
```
### setPromotionListUpdateTimeinterval

This function is used to set the promotion update time interval. The default setting is maximal 1 promotion list update per hour.
```solidity
   function setPromotionListUpdateTimeinterval(uint hour) public onlyOwner {
        timeIntervalPromotion = hour * 1 hours;
    }
```
### setVoucherValidityPeriod

The voucher validity period can be changed through this function. The default value is 2 years.
```solidity
   function setVoucherValidityPeriod(uint _voucherValidity) public onlyOwner {
        VoucherValidityPeriod = _voucherValidity * 365 days;
    }
```
### setPointValidityPeriod

The voucher validity period can be changed through this function. The default value is 3 years.
```solidity    
   function setPointValidityPeriod(uint _pointValidity) public onlyOwner {
        PointValidityPeriod = _pointValidity * 365 days;
    }
```
### compareStrings
compareStrings function is used to compare the strings in solidity, whether they are identical through its hash value.
```solidity
   function compareStrings(string memory s1, string memory s2) public view returns(bool){
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
   }
```

**GitHub Pages** is a free and easy way to create a website using the code that lives in your GitHub repositories. You can use GitHub Pages to build a portfolio of your work, create a personal website, or share a fun project that you coded with the world. GitHub Pages is automatically enabled in this repository, but when you create new repositories in the future, the steps to launch a GitHub Pages website will be slightly different.

[Learn more about GitHub Pages](https://pages.github.com/)

## Rename this repository to publish your site

We've already set-up a GitHub Pages website for you, based on your personal username. This repository is called `hello-world`, but you'll rename it to: `username.github.io`, to match your website's URL address. If the first part of the repository doesn’t exactly match your username, it won’t work, so make sure to get it right.

Let's get started! To update this repository’s name, click the `Settings` tab on this page. This will take you to your repository’s settings page. 

![repo-settings-image](https://user-images.githubusercontent.com/18093541/63130482-99e6ad80-bf88-11e9-99a1-d3cf1660b47e.png)

Under the **Repository Name** heading, type: `username.github.io`, where username is your username on GitHub. Then click **Rename**—and that’s it. When you’re done, click your repository name or browser’s back button to return to this page.

<img width="1039" alt="rename_screenshot" src="https://user-images.githubusercontent.com/18093541/63129466-956cc580-bf85-11e9-92d8-b028dd483fa5.png">

Once you click **Rename**, your website will automatically be published at: https://your-username.github.io/. The HTML file—called `index.html`—is rendered as the home page and you'll be making changes to this file in the next step.

Congratulations! You just launched your first GitHub Pages website. It's now live to share with the entire world

## Making your first edit

When you make any change to any file in your project, you’re making a **commit**. If you fix a typo, update a filename, or edit your code, you can add it to GitHub as a commit. Your commits represent your project’s entire history—and they’re all saved in your project’s repository.

With each commit, you have the opportunity to write a **commit message**, a short, meaningful comment describing the change you’re making to a file. So you always know exactly what changed, no matter when you return to a commit.

## Practice: Customize your first GitHub website by writing HTML code

Want to edit the site you just published? Let’s practice commits by introducing yourself in your `index.html` file. Don’t worry about getting it right the first time—you can always build on your introduction later.

Let’s start with this template:

```
<p>Hello World! I’m [username]. This is my website!</p>
```

To add your introduction, copy our template and click the edit pencil icon at the top right hand corner of the `index.html` file.

<img width="997" alt="edit-this-file" src="https://user-images.githubusercontent.com/18093541/63131820-0794d880-bf8d-11e9-8b3d-c096355e9389.png">


Delete this placeholder line:

```
<p>Welcome to your first GitHub Pages website!</p>
```

Then, paste the template to line 15 and fill in the blanks.

<img width="1032" alt="edit-githuboctocat-index" src="https://user-images.githubusercontent.com/18093541/63132339-c3a2d300-bf8e-11e9-8222-59c2702f6c42.png">


When you’re done, scroll down to the `Commit changes` section near the bottom of the edit page. Add a short message explaining your change, like "Add my introduction", then click `Commit changes`.


<img width="1030" alt="add-my-username" src="https://user-images.githubusercontent.com/18093541/63131801-efbd5480-bf8c-11e9-9806-89273f027d16.png">

Once you click `Commit changes`, your changes will automatically be published on your GitHub Pages website. Refresh the page to see your new changes live in action.

:tada: You just made your first commit! :tada:

## Extra Credit: Keep on building!

Change the placeholder Octocat gif on your GitHub Pages website by [creating your own personal Octocat emoji](https://myoctocat.com/build-your-octocat/) or [choose a different Octocat gif from our logo library here](https://octodex.github.com/). Add that image to line 12 of your `index.html` file, in place of the `<img src=` link.

Want to add even more code and fun styles to your GitHub Pages website? [Follow these instructions](https://github.com/github/personal-website) to build a fully-fledged static website.

![octocat](./images/create-octocat.png)

## Everything you need to know about GitHub

Getting started is the hardest part. If there’s anything you’d like to know as you get started with GitHub, try searching [GitHub Help](https://help.github.com). Our documentation has tutorials on everything from changing your repository settings to configuring GitHub from your command line.

Getting started with Markdown
=============================


- [Getting started with Markdown](#getting-started-with-markdown)
- [Titles](#titles)
- [Paragraph](#paragraph)
- [List](#list)
	- [List CheckBox](#list-checkbox)
- [Link](#link)
	- [Anchor links](#anchor-links)
- [Blockquote](#blockquote)
- [Image | GIF](#image--gif)
- [Style Text](#style-text)
	- [Italic](#italic)
	- [Bold](#bold)
	- [Strikethrough](#strikethrough)
- [Code](#code)
- [Email](#email)
- [Table](#table)
	- [Table Align](#table-align)
    	- [Align Center](#align-center)
    	- [Align Left](#align-left)
    	- [Align Right](#align-right)
- [Escape Characters](#escape-characters)
- [Emoji](#emoji)
- [Shields Badges](#Shields-Badges)
- [Markdown Editor](#markdown-editor)
- [Some links for more in depth learning](#some-links-for-more-in-depth-learning)

----------------------------------

# Titles 

### Title 1
### Title 2

	Title 1
	========================
	Title 2 
	------------------------

# Title 1
## Title 2
### Title 3
#### Title 4
##### Title 5
###### Title 6

    # Title 1
    ## Title 2
    ### Title 3    
    #### Title 4
    ##### Title 5
    ###### Title 6    

# Paragraph
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit. Phasellus eleifend egestas diam, id tincidunt arcu dictum quis. Pellentesque eu dui tempus, tempus massa sed, eleifend tortor. Donec in sem in erat iaculis tincidunt. Fusce condimentum hendrerit turpis nec vehicula. Aliquam finibus nisi vel eros lobortis dictum. Etiam congue tortor libero, quis faucibus ligula gravida a. Suspendisse non pulvinar nisl. Sed malesuada, felis vitae consequat gravida, dui ligula suscipit ligula, nec elementum nulla sem vel dolor. Vivamus augue elit, venenatis non lorem in, volutpat placerat turpis. Nullam et libero at eros vulputate auctor. Duis sed pharetra lacus. Sed egestas ligula vitae libero aliquet, ac imperdiet est ullamcorper. Sed dapibus sem tempus eros dignissim, ac suscipit lectus dapibus. Proin sagittis diam vel urna volutpat, vel ullamcorper urna lobortis. Suspendisse potenti.

Nulla varius risus sapien, nec fringilla massa facilisis sed. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nunc vel ornare erat, eget rhoncus lectus. Suspendisse interdum scelerisque molestie. Aliquam convallis consectetur lorem ut consectetur. Nullam massa libero, cursus et porta ac, consequat eget nibh. Sed faucibus nisl augue, non viverra justo sagittis venenatis.

    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit. 
    
    Phasellus eleifend egestas diam, id tincidunt arcu dictum quis.

# List 
* Item 1;
	* Item 1.1;
* Item 2;
	* Item 2.1;
	* Item 2.2;
* Item 3
	* Item 3.1;
		* Item 3.1.1;
    
>      * Item 1;
>	      * Item 1.1;
>	    * Item 2;
>	     * Item 2.1;
>	     * Item 2.2;
>	    * Item 3
>		   * Item 3.1;
>			  * Item 3.1.1;

## List CheckBox

 - [ ] Item A
 - [x] Item B
 - [x] Item C
 
>     - [ ] Item A
>     - [x] Item B
>     - [x] Item C


# Link
[Google](https://www.google.com) - _Google | Youtube | Gmail | Maps | PlayStore | GoogleDrive_

[Youtube](https://www.youtube.com) - _Enjoy videos and music you love, upload original content, and share it with friends, family, and the world on YouTube._

[GitHub](https://github.com/fefong/markdown_readme#getting-started-with-markdown) - _Project_

		[Google](https://www.google.com) - _Google | Youtube | Gmail | Maps | PlayStore | GoogleDrive_

## Anchor links

[Markdown - Summary](#Getting-started-with-Markdown)

[Markdown - Markdown Editor](#Markdown-Editor)

		[Markdown - Link](#Link)

# Blockquote
> Lebenslangerschicksalsschatz: Lifelong Treasure of Destiny

    > Lebenslangerschicksalsschatz: Lifelong Treasure of Destiny 

# Image | GIF
![myImage](https://media.giphy.com/media/XRB1uf2F9bGOA/giphy.gif)
    
    ![myImage](https://media.giphy.com/media/XRB1uf2F9bGOA/giphy.gif)
    
See more [Markdown Extras - Image Align](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#image-align)    

# Style Text
### Italic

*Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.*

     *Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.*

### Bold
**Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.**

    **Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dictum, nibh eu commodo posuere, ligula ante dictum neque, vitae pharetra mauris mi a velit.**
    
### Strikethrough
~~strikethrough text~~

    ~~strikethrough text~~
    
# Code

```java
public static void main(String[] args) {
	//TODO
}
```

>   \`\`\`java <br>
>   public static void main(String[] args) {<br>
>	    //TODO<br>
>	}<br>
>   \`\`\`<br>

See more [Markdown Extras - Style Text](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#style-text)

# Email
<email@email.com>

    <email@email.com>

# Table

|Column 1|Column 2|Column 3|
|---|---|---|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|---|---|---|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

## Table Align

## Align Center

|Column 1|Column 2|Column 3|
|:---:|:---:|:---:|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|:---:|:---:|:---:|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

## Align Left

|Column 1|Column 2|Column 3|
|:---|:---|:---|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|:---|:---|:---|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

## Align Right

|Column 1|Column 2|Column 3|
|---:|---:|---:|
|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|
|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|

>\|Column 1|Column 2|Column 3|<br>
>\|---:|---:|---:|<br>
>\|Row 1 Column1| Row 1 Column 2| Row 1 Column 3|<br>
>\|Row 2 Column1| Row 2 Column 2| Row 2 Column 3|<br>

See more [Markdown Extras - Table](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#table)
* [Rownspan](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#table---rowspan)
* [Colspan](https://github.com/fefong/markdown_readme/blob/master/markdown-extras.md#table---colspan)

# Escape Characters

```
\   backslash
`   backtick
*   asterisk
_   underscore
{}  curly braces
[]  square brackets
()  parentheses
#   hash mark
+   plus sign
-   minus sign (hyphen)
.   dot
!   exclamation mark
```

# Emoji

* [Emoji](emoji.md#emoji);
	* [People](emoji.md#people) - (:blush: ; :hushed: ; :shit:);
	* [Nature](emoji.md#nature) - (:sunny: ; :snowman: ; :dog:);
	* [Objects](emoji.md#objects) - (:file_folder: ; :computer: ; :bell:);
	* [Places](emoji.md#places) - (:rainbow: ; :warning: ; :statue_of_liberty:);
	* [Symbols](emoji.md#symbols) - (:cancer: ; :x: ; :shipit:);
* [Kaomoji](emoji.md#kaomoji);
* [Special-Symbols](emoji.md#special-symbols);
	

# Shields Badges

:warning: _We are not responsible for this site_

See more: [https://shields.io/](https://shields.io/)

[![AccountChain App](https://img.shields.io/github/forks/fefong/markdown_readme)](https://github.com/fefong/markdown_readme/network)
![Markdown](https://img.shields.io/badge/markdown-project-red)

# Markdown Editor

[StackEdit](https://stackedit.io) - _StackEdit’s Markdown syntax highlighting is unique. The refined text formatting of the editor helps you visualize the final rendering of your files._

# Links for User Interfaces

:page_facing_up: [AccountChain App](https://xd.adobe.com/view/b63ae9ae-8d0c-4d6c-b447-ee5eade2a5d9-e369/?fullscreen&hints=off)

:page_facing_up: [AccountChain WebApp](https://public.tableau.com/profile/dominik.merz#!/vizhome/shared/354DZRXPK)




