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
	// Setup configuration
	openAiUrl := os.Getenv("OPENAI_URL")
	openAiKey := os.Getenv("OPENAI_KEY")
	deployment := os.Getenv("OPENAI_DEPLOYMENT")

	// Validate configuration
	if openAiUrl == "" && openAiKey == "" && deployment == "" {
		fmt.Println("OpenAI environment variables are not set")
		os.Exit(1)
	}

	historyLength := 10
	maxTokens := 150

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
	url := openAiUrl + "openai/deployments/" + deployment + "/chat/completions?api-version=2023-05-15"

	// Chat history
	chatHistory := make([]ChatMessage, 0)

	// Create an HTTP client
	httpClient := http.Client{}

	// Run main application loop
	fmt.Println("Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?")

	scanner := bufio.NewScanner(os.Stdin)
	running := true

	// Main application loop
	for running {
		// Prompt user for input
		fmt.Println("Quaeris quid (What is your question)?")
		scanner.Scan()
		prompt := scanner.Text()

		switch prompt {
		case "":
			fmt.Println("Me paenitet, non audivi te. (I'm sorry, I didn't hear you)")

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
				MaxTokens: int32(maxTokens),
				N:         1, // Maximum number of completions to generate

				// The following parameters are provided as examples. They are not required and are set to their default values.
				FrequencyPenalty: 0.0,
				PresencePenalty:  0.0,
				Temperature:      0.7,
				TopP:             0.95,
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
			httpRequest.Header.Set("api-key", openAiKey)

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
			if len(chatHistory) >= historyLength {
				chatHistory = chatHistory[2:] // Remove the top two messages
			}
			chatHistory = append(chatHistory, userMessage, assistantResponse)

			fmt.Println(assistantResponseText)
			fmt.Println() // Add a blank line after the response
		}
	}

	fmt.Println("Vale et gratias tibi ago for using Magnus Liber Imperatorum.")
}
