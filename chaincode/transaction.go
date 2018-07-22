package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
	"golang.org/x/crypto/sha3"
	//"golang.org/x/crypto/sha3"
)

type SmartContract struct {
}

type Transaction struct {
	OriginBankCode           string `json:"originbankcode"`
	OriginAccountNumber      string `json:"originaccountnumber"`
	DestinationBankCode      string `json:"destinationbankcode"`
	DestinationAccountNumber string `json:"destinationaccountnumber"`
	Amount                   string `json:"amount"`
	Status                   Status `json:"status"`
	Currency                 string `json:"currency"`
	ValueDate                string `json:"valuedate"`
}

type TransactionsList struct {
	Key       string      `json:"key"`
	ValueList Transaction `json:"transaction"`
}

// Status is used to control the state of the transaction
type Status string

const (
	Pending   Status = "Pending"
	Confirmed Status = "Confirmed"
	Reversed  Status = "Reversed"
	Timeout   Status = "Timeout"
)

// Init is called when initialization of the smart contract happends.
func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

// Invoke is the entry point to the smart contract logic and all its methods.
func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

	function, args := APIstub.GetFunctionAndParameters()
	var err error
	var response []byte
	switch function {
	case "CreatePendingTransaction":
		response, err = CreatePendingTransaction(APIstub, args)
	case "ConfirmTransaction":
		response, err = ConfirmTransaction(APIstub, args)
	case "TimeoutPendingTransaction":
		response, err = TimeoutPendingTransaction(APIstub, args)
	case "GetPendingTransactions":
		response, err = GetPendingTransactions(APIstub, args)
	}

	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(response)
}

// main is only used for testing.
func main() {
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("error creating new Smart Contract: %s", err)
	}
}

func CreatePendingTransaction(APIstub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	if len(args) != 6 {
		return nil, errors.New("incorrect number of parameters to create a new pending transaction")
	}
	newTran := Transaction{}
	newTran.OriginBankCode = args[0]
	newTran.OriginAccountNumber = args[1]
	newTran.DestinationBankCode = args[2]
	newTran.DestinationAccountNumber = args[3]
	newTran.Amount = args[4]
	newTran.Currency = args[5]
	newTran.ValueDate = time.Now().Format(time.Stamp)
	newTran.Status = Pending
	tranJson, err := json.Marshal(newTran)
	if err != nil {
		return nil, err
	}
	tranCode := toHash(string(tranJson))
	err = APIstub.PutState(tranCode, tranJson)
	if err != nil {
		return nil, err
	}
	APIstub.SetEvent("Pending", []byte("Transaction pending"))
	return []byte("Success"), nil
}

func ConfirmTransaction(APIstub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	if len(args) != 1 {
		return nil, errors.New("incorrect number of parameters to confirm a pending transaction")
	}
	myKey := args[0]
	tranAsBytes, err := APIstub.GetState(myKey)
	if err != nil {
		return nil, err
	}
	myTran := Transaction{}
	err = json.Unmarshal(tranAsBytes, &myTran)
	if err != nil {
		return nil, err
	}
	if myTran.Status == Pending {
		myTran.Status = Confirmed
	} else {
		return nil, errors.New("transaction is not pending for confirmation")
	}
	myByteTran, err := json.Marshal(myTran)
	if err != nil {
		return nil, err
	}
	err = APIstub.PutState(myKey, myByteTran)
	if err != nil {
		return nil, err
	}
	APIstub.SetEvent("Confirmed", []byte("Transaction confirmed"))
	return []byte("Success"), nil
}

func TimeoutPendingTransaction(APIstub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	if len(args) != 1 {
		return nil, errors.New("incorrect number of parameters to confirm a pending transaction")
	}
	myKey := args[0]
	tranAsBytes, err := APIstub.GetState(myKey)
	if err != nil {
		return nil, err
	}
	myTran := Transaction{}
	err = json.Unmarshal(tranAsBytes, &myTran)
	if err != nil {
		return nil, err
	}
	if myTran.Status == Pending {
		myTran.Status = Timeout
	} else {
		return nil, errors.New("transaction is not pending for confirmation")
	}
	myByteTran, err := json.Marshal(myTran)
	if err != nil {
		return nil, err
	}
	err = APIstub.PutState(myKey, myByteTran)
	if err != nil {
		return nil, err
	}
	return []byte("Success"), nil
}

func toHash(input string) string {
	toencrypt := []byte(input)
	hashkey := sha3.Sum256(toencrypt)
	strhashkey := fmt.Sprintf("%x", hashkey)
	return strhashkey
}

// GetPendingTransactions is used to fetch all transaction with status pending.
func GetPendingTransactions(APIstub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	TxList := []TransactionsList{}
	query := fmt.Sprintf(`{ "selector":{ "status": { "$eq": "%s" } } } `, Pending)
	ResultStates, err := APIstub.GetQueryResult(query)
	defer ResultStates.Close()
	for ResultStates.HasNext() {
		QueryRecord, err := ResultStates.Next()
		myList := TransactionsList{}
		myTx := Transaction{}
		err = json.Unmarshal(QueryRecord.Value, &myTx)
		myList.ValueList = myTx
		myList.Key = QueryRecord.Key
		if err != nil {
			return nil, err
		}
		TxList = append(TxList, myList)
	}
	TxListAsBytes, err := json.Marshal(TxList)
	if err != nil {
		return nil, err
	}
	fmt.Printf("%v \n", string(TxListAsBytes))
	return TxListAsBytes, nil
}

// GetTxHistory fetches all the history of a transaction
func GetTxHistory(APIstub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	if len(args) != 1 {
		return nil, errors.New("incorrect number of arguments. Expecting 2")
	}
	TranList := []TransactionsList{}
	KeyHistory, err := APIstub.GetHistoryForKey(args[0])
	defer KeyHistory.Close()
	for KeyHistory.HasNext() {
		HistoryRecord, err := KeyHistory.Next()
		myTran := TransactionsList{}
		MyTx := Transaction{}
		err = json.Unmarshal(HistoryRecord.Value, &MyTx)
		myTran.ValueList = MyTx
		myTran.Key = HistoryRecord.TxId
		if err != nil {
			return nil, err
		}
		TranList = append(TranList, myTran)

	}
	TranListAsBytes, err := json.Marshal(TranList)
	if err != nil {
		return nil, err
	}
	return TranListAsBytes, nil
}
