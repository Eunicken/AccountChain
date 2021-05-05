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
- [Table](#table)
	- [Account Table](#Account-Table)
	- [Struct Table](#Struct-Table)
	- [List Table](#List-Table)
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
                // First Case: one point record has less than _point amount of points needed to complete voucher issuance.
                // Further point record must be combined to issue the voucher
                // The _point required to issure a voucher is deducted and if it is still positive after deduction, it will be used for next loop 
                if (pointRecordList[i].point < _point){
                    pointRecordList[i].status = "Coverted into voucher";
                    pointRecordList[i].hashVoucherCode = _hashVoucherCode;
                    pointRecordList[i].statusChangeTime = block.timestamp;
                    bookAccrualAccount(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    bookKKToppharm(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    _point = _point - pointRecordList[i].point; // calculate the remaining points required to issue a voucher
                    // Second case, one point record has exactly _point amount of points to issue a voucher. The loop stops.
                } else if (compareStrings(pointRecordList[i].status,"Active") && pointRecordList[i].point == _point) {
                    pointRecordList[i].status = "Coverted into voucher";
                    pointRecordList[i].hashVoucherCode = _hashVoucherCode;
                    pointRecordList[i].statusChangeTime = block.timestamp;
                    bookAccrualAccount(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    bookKKToppharm(pointRecordList[i].pharmacyID, - int(pointRecordList[i].pointValue), pointRecordList[i].taxCategory);
                    break;
                } else if (compareStrings(pointRecordList[i].status,"Active") && pointRecordList[i].point > _point) { 
                // In case, that one point record has more than needed points. Only part of the points from this record is  
                // converted to the voucher and the remaining points are stored as a new point record at the end of pointRecordList.
	        // The loop stops.
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

Like it is the case with points, also vouchers can expire. The expireVoucher function is called by [redeemVoucher](#redeemVoucher). This means that, before redeeming a voucher, it needs to be ensured that it has not yet expired. The expireVoucher function makes sure that unused vouchers expire after a certain period (2 years in our case). In contrast to the expirePoint function, it only involves one booking activity; the current account KKToppharm is adjusted down by the respective value of the voucher. This means that the pharmacy’s liability is reduced. Remember that we apply the FIFO ruling in a customer’s point transaction history. This becomes an important aspect when thinking of a case, in which several pharmacies have contributed to the point balance which was needed to issue a voucher. If such a voucher expires, the respective liabilities can be reduced proportionally since its transaction history has been fully recorded. 
```solidity
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
``` 
### redeemVoucher

Customers receive vouchers in the form of a QR code which consists of the Client ID, the clean voucher code, and the salt which has been appended to the latter before it has been hashed. (Note: The hashing process takes place in an off-chain environment to avoid that not the clean but hashed voucher codes are stored on-chain.) The redeemVoucher function verifies the voucher validity and adjusts the current account KKToppharm after a voucher has been redeemed. During the redemption process, the voucher clean code and the salt are received by redeemVoucher function as input to re-calculate the hash voucher code. Subsequently, the calculated hash voucher code is compared with the hash voucher codes stored in VoucherList. If the hash voucher code is valid and the corresponding voucher has a status equal to “Active”, the voucher is valid and it thus can be redeemed. After redeeming the voucher, the pharmacy who receives the voucher, books the voucher value as receivable into its current account KKToppharm.
```solidity
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
``` 
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

# Table
## Account Table
|Account|Description|Attributes|
|:---:|:---:|:---:|
|Point Accrual Account| The point accrual Account denotes the issued points as a sell discount, which is VAT-deductible.| int total <br /> int taxCat1 <br /> int taxCat2 <br /> int taxCat3 <br /> int taxCat4 | 
|KKToppharm | KKToppharm Account denotes the current account of the pharmacy, containing consolidated receivables and liabilities against other entities in the network. | int total <br /> int taxCat1 <br /> int taxCat2 <br /> int taxCat3 <br /> int taxCat4 |

## Struct Table
|Struct|Attributes|
|:---:|:---:|
|client| address clientAddress <br /> uint clientID <br /> uint point <br /> uint lastPurchaseTime <br /> string status  <br /> mapping (bytes32 => voucher) voucherListClient| 
|pharmacy | uint pharmacyID <br /> accrualAccount accrualPoint <br /> KKToppharmAccount accountKKToppharm | 
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


# Links for User Interfaces

:page_facing_up: [AccountChain App](https://xd.adobe.com/view/b63ae9ae-8d0c-4d6c-b447-ee5eade2a5d9-e369/?fullscreen&hints=off)

:page_facing_up: [AccountChain WebApp](https://public.tableau.com/profile/dominik.merz#!/vizhome/shared/354DZRXPK)




