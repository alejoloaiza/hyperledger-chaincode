package main

import (
	"encoding/json"
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
	case "RemovePendingTransaction":
		response, err = RemovePendingTransaction(APIstub, args)
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

func CreatePendingTransaction(APIstub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 6 {
		return nil, new.Errors("incorrect number of parameters to create a new pending transaction")
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
	return "Success", nil
}

func ConfirmTransaction(APIstub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 1 {
		return nil, new.Errors("incorrect number of parameters to confirm a pending transaction")
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
		return nil, Errors.new("transaction is not pending for confirmation")
	}
	myByteTran, err := json.Marshal(myTran)
	if err != nil {
		return nil, err
	}
	err = APIstub.PutState(myKey, myByteTran)
	if err != nil {
		return nil, err
	}
	return "Success", nil
}

func toHash(input string) string {
	toencrypt := []byte(input)
	hashkey := sha3.Sum256(toencrypt)
	strhashkey := fmt.Sprintf("%x", hashkey)
	return strhashkey
}
