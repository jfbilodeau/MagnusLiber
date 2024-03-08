package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	azopenai "github.com/Azure/azure-sdk-for-go/sdk/ai/azopenai"
	azcore "github.com/Azure/azure-sdk-for-go/sdk/azcore"
	"os"
)

// Configuration structure
type Configuration struct {
	OpenAiUri     string `json:"openAiUri"`
	OpenAiKey     string `json:"openAiKey"`
	Deployment    string `json:"deployment"`
	HistoryLength int    `json:"historyLength"`
	// MaxTokens needs to be passed as an `int32` pointer to `azopenai.ChatCompletionsOptions`
	MaxTokens int32 `json:"maxTokens"`
}

// Messages structure
type Messages struct {
	Greeting   string `json:"greeting"`
	Prompt     string `json:"prompt"`
	EmptyInput string `json:"emptyInput"`
	Exit       string `json:"exit"`
}

func main() {
	// Load configuration file
	configurationFilePath := "../MagnusLiber.json"

	// Check for the presence of "../MagnusLiber.dev.json"
	devConfigurationFound, err := os.Stat("../MagnusLiber.dev.json")

	if err == nil && devConfigurationFound != nil {
		configurationFilePath = "../MagnusLiber.dev.json"
	}

	configurationFile, err := os.ReadFile(configurationFilePath)
	if err != nil {
		panic("Could not load configuration file")
	}

	// OpenAI configuration
	var configuration Configuration

	err = json.Unmarshal(configurationFile, &configuration)
	if err != nil {
		panic("Failed to parse configuration file")
	}

	// Load user messages
	messageFilePath := "../Messages.json"
	messageFile, err := os.ReadFile(messageFilePath)
	if err != nil {
		panic("Could not load messages file")
	}

	// User messages
	var messages Messages

	err = json.Unmarshal(messageFile, &messages)
	if err != nil {
		panic("Could not parse message file")
	}

	// Load system message
	systemMessagePath := "../SystemMessage.txt"
	systemMessageBytes, err := os.ReadFile(systemMessagePath)
	if err != nil {
		panic("Cloud not load system message")
	}

	systemMessageString := string(systemMessageBytes)

	// Create system message
	chatRequestSystemMessage := azopenai.ChatRequestSystemMessage{
		Content: &systemMessageString,
		//role:    &azopenai.ChatRoleSystem,
	}

	systemMessage := chatRequestSystemMessage.GetChatRequestMessage()

	// Chat history
	chatHistory := make([]azopenai.ChatRequestMessageClassification, 0)

	// Prepare OpenAI client options
	options := azopenai.ClientOptions{}

	// Create OpenAI client
	client, err := azopenai.NewClientWithKeyCredential(
		configuration.OpenAiUri,
		azcore.NewKeyCredential(configuration.OpenAiKey),
		&options,
	)

	if err != nil {
		panic("Could not create OpenAI client")
	}

	// Run main application loop
	fmt.Println(messages.Greeting)

	scanner := bufio.NewScanner(os.Stdin)
	running := true

	// Main application loop
	for running {
		// Prompt user for input
		fmt.Println(messages.Prompt)
		scanner.Scan()
		prompt := scanner.Text()

		switch prompt {
		case "":
			fmt.Println(messages.EmptyInput)

		case "quit", "exit":
			running = false

		default:
			// Create user message
			chatRequestUserMessage := azopenai.ChatRequestUserMessage{
				Content: azopenai.NewChatRequestUserMessageContent(prompt),
			}
			userMessage := chatRequestUserMessage.GetChatRequestMessage()

			// Create conversation history
			conversation := []azopenai.ChatRequestMessageClassification{
				systemMessage,
			}
			conversation = append(conversation, chatHistory...)
			conversation = append(conversation, userMessage)

			// Number of completions to generate
			n := int32(1)

			// Sample parameters
			frequencyPenalty := float32(0.0)
			presencePenalty := float32(0.0)
			temperature := float32(1.0)
			topP := float32(1.0)

			// Create chat completion context
			chatCompletionOptions := azopenai.ChatCompletionsOptions{
				Messages:       conversation,
				MaxTokens:      &configuration.MaxTokens,
				DeploymentName: &configuration.Deployment,
				N:              &n, // Maximum number of completions to generate

				// The following parameters are provided as examples. They are not required and are set to their default values.
				FrequencyPenalty: &frequencyPenalty,
				PresencePenalty:  &presencePenalty,
				Temperature:      &temperature,
				TopP:             &topP,
			}

			// Get chat completions
			response, err := client.GetChatCompletions(
				context.Background(),
				chatCompletionOptions,
				nil,
			)

			// Check for error
			if err != nil {
				panic("Could not get chat completions. Reason: " + err.Error())
			}

			// Get the text of the response
			assistantResponseText := response.Choices[0].Message.Content

			// Create assistant message
			chatRequestAssistantMessage := azopenai.ChatRequestAssistantMessage{
				Content: assistantResponseText,
			}
			assistantResponse := chatRequestAssistantMessage.GetChatRequestMessage()

			// Manage chat history, keeping it within the configured history length
			if len(chatHistory) >= configuration.HistoryLength {
				chatHistory = chatHistory[2:] // Remove the top two messages
			}
			chatHistory = append(chatHistory, userMessage, assistantResponse)

			fmt.Println(response)
			fmt.Println() // Add a blank line after the response
		}
	}

	fmt.Println(messages.Exit)
}
