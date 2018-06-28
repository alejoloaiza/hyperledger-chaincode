package main

import (
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
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
