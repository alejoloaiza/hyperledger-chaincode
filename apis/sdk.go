package main

import (
	"fabric-sdk-go/pkg/common/providers/core"
	"fabric-sdk-go/test/integration"
	"testing"

	"github.com/hyperledger/fabric-sdk-go/pkg/client/channel"
	mspclient "github.com/hyperledger/fabric-sdk-go/pkg/client/msp"
	"github.com/hyperledger/fabric-sdk-go/pkg/common/errors/retry"
	"github.com/hyperledger/fabric-sdk-go/pkg/fabsdk"
	"github.com/pkg/errors"
)

const (
	channelID      = "mychannel"
	orgName        = "Org1"
	orgAdmin       = "Admin"
	ordererOrgName = "OrdererOrg"
)

func main() {

}
func setupAndRun(t *testing.T, createChannel bool, configOpt core.ConfigProvider, test testSDKFunc, sdkOpts ...fabsdk.Option) {

	if integration.IsLocal() {
		//If it is a local test then add entity mapping to config backend to parse URLs
		configOpt = integration.AddLocalEntityMapping(configOpt)
	}

	sdk, err := fabsdk.New(integration.ConfigBackend, sdkOpts...)
	if err != nil {
		t.Fatalf("Failed to create new SDK: %s", err)
	}
	defer sdk.Close()

	// Delete all private keys from the crypto suite store
	// and users from the user store at the end
	integration.CleanupUserData(t, sdk)
	defer integration.CleanupUserData(t, sdk)

	if createChannel {
		createChannelAndCC(t, sdk)
	}

	test(t, sdk)
}

func e2eTest(t *testing.T, sdk *fabsdk.FabricSDK) {
	//prepare channel client context using client context
	clientChannelContext := sdk.ChannelContext(channelID, fabsdk.WithUser("User1"), fabsdk.WithOrg(orgName))
	// Channel client is used to query and execute transactions (Org1 is default org)
	client, err := channel.New(clientChannelContext)
	if err != nil {
		t.Fatalf("Failed to create new channel client: %s", err)
	}

	existingValue := queryCC(t, client)
	executeCC(t, client)

}

func executeCC(t *testing.T, client *channel.Client) {
	_, err := client.Execute(channel.Request{ChaincodeID: ccID, Fcn: "invoke", Args: integration.ExampleCCTxArgs()},
		channel.WithRetry(retry.DefaultChannelOpts))
	if err != nil {
		t.Fatalf("Failed to move funds: %s", err)
	}
}

func queryCC(t *testing.T, client *channel.Client, targetEndpoints ...string) []byte {
	response, err := client.Query(channel.Request{ChaincodeID: ccID, Fcn: "invoke", Args: integration.ExampleCCQueryArgs()},
		channel.WithRetry(retry.DefaultChannelOpts),
		channel.WithTargetEndpoints(targetEndpoints...),
	)
	if err != nil {
		t.Fatalf("Failed to query funds: %s", err)
	}
	return response.Payload
}

func setup() error {
	// Create SDK setup for the integration tests
	var err error
	sdk, err = fabsdk.New(integration.ConfigBackend)
	if err != nil {
		return errors.Wrap(err, "Failed to create new SDK")
	}

	org1MspClient, err = mspclient.New(sdk.Context(), mspclient.WithOrg(org1))
	if err != nil {
		return errors.Wrap(err, "failed to create org1MspClient, err")
	}

	org2MspClient, err = mspclient.New(sdk.Context(), mspclient.WithOrg(org2))
	if err != nil {
		return errors.Wrap(err, "failed to create org2MspClient, err")
	}

	return nil
}
