package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
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

// The Azure OpenAI SDK for Go is incomplete at this time so we will define some of the structure
// that would be present in the SDK. This is a temporary measure until the SDK is updated.

// Chat message roles
const (
	ChatRoleSystem    = "system"
	ChatRoleUser      = "user"
	ChatRoleAssistant = "assistant"
)

// ChatMessage chat message structure
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// ChatCompletionsOptions chat completions options
type ChatCompletionsOptions struct {
	Messages  []ChatMessage `json:"messages"`
	MaxTokens int32         `json:"max_tokens"`
	N         int32         `json:"n"` // Maximum number of completions to generate

	// The following parameters are provided as examples. They are not required and are set to their default values.
	FrequencyPenalty float32 `json:"frequency_penalty"`
	PresencePenalty  float32 `json:"presence_penalty"`
	Temperature      float32 `json:"temperature"`
	TopP             float32 `json:"top_p"`
}

type ChatCompletionChoice struct {
	Message      ChatMessage `json:"message"`
	FinishReason string      `json:"finish_reason"`
	Index        int         `json:"index"`
}

type ChatCompletionResponse struct {
	Id      string                 `json:"id"`      // Unique id for the completion
	Object  string                 `json:"object"`  // Set to `text_completion`
	Created int64                  `json:"created"` // Unix timestamp
	Model   string                 `json:"model"`   // The model used for the completion
	Choices []ChatCompletionChoice `json:"choices"` // The completions
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

	// UI messages
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
	systemMessage := ChatMessage{
		Content: systemMessageString,
		Role:    ChatRoleSystem,
	}

	// URL to the OpenAI endpoint
	url := configuration.OpenAiUri + "openai/deployments/" + configuration.Deployment + "/chat/completions?api-version=2023-05-15"

	// Chat history
	chatHistory := make([]ChatMessage, 0)

	// Create an HTTP client
	httpClient := http.Client{}

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
			userMessage := ChatMessage{
				Role:    ChatRoleUser,
				Content: prompt,
			}

			// Create conversation history
			conversation := []ChatMessage{
				systemMessage,
			}

			conversation = append(conversation, chatHistory...)
			conversation = append(conversation, userMessage)

			// Create chat completion context
			chatCompletionOptions := ChatCompletionsOptions{
				Messages:  conversation,
				MaxTokens: configuration.MaxTokens,
				N:         1, // Maximum number of completions to generate

				// The following parameters are provided as examples. They are not required and are set to their default values.
				FrequencyPenalty: 0.0,
				PresencePenalty:  0.0,
				Temperature:      1.0,
				TopP:             1.0,
			}

			// Convert to JSON string
			body, err := json.Marshal(chatCompletionOptions)

			if err != nil {
				panic("Could not marshal chat completion options")
			}

			// Create a new HTTP request
			httpRequest, err := http.NewRequest(http.MethodPost, url, bytes.NewBuffer(body))
			if err != nil {
				panic("Could not create HTTP request")
			}

			// Set the request headers
			httpRequest.Header.Set("Content-Type", "application/json")
			httpRequest.Header.Set("api-key", configuration.OpenAiKey)

			// Send the request
			httpResponse, err := httpClient.Do(httpRequest)
			if err != nil {
				panic("Could not send HTTP request")
			}

			// Read the body
			defer httpResponse.Body.Close()

			buffer, err := io.ReadAll(httpResponse.Body)
			if err != nil {
				panic("Could not read HTTP response body")
			}

			// Print buffer
			fmt.Println(string(buffer))

			// Parse body into ChatCompletionResponse
			var response ChatCompletionResponse
			err = json.Unmarshal(buffer, &response)
			if err != nil {
				panic("Could not unmarshal chat completion response")
			}

			// Get the text of the response
			assistantResponseText := response.Choices[0].Message.Content

			// Create assistant message
			assistantResponse := ChatMessage{
				Content: assistantResponseText,
				Role:    ChatRoleAssistant,
			}

			// Manage chat history, keeping it within the configured history length
			if len(chatHistory) >= configuration.HistoryLength {
				chatHistory = chatHistory[2:] // Remove the top two messages
			}
			chatHistory = append(chatHistory, userMessage, assistantResponse)

			fmt.Println(assistantResponseText)
			fmt.Println() // Add a blank line after the response
		}
	}

	fmt.Println(messages.Exit)
}
