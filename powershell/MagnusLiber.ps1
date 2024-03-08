# Assuming configuration and messages are stored in JSON files
if (Test-Path "../MagnusLiber.dev.json") {
    $configurationPath = "../MagnusLiber.dev.json"
} else {
    $configurationPath = "../MagnusLiber.json"
}

# Load configuration
$configuration = Get-Content $configurationPath | ConvertFrom-Json

# Load messages
$messagesPath = "../Messages.json"
$messages = Get-Content $messagesPath | ConvertFrom-Json

# Load system message
$systemMessagePath = "../SystemMessage.txt"
$systemMessageText = Get-Content $systemMessagePath

$systemMessage = @{
    role = "system"
    content = "$systemMessageText"
}

# Initialize chat history
$chatHistory = @()

function Get-AssistantResponse {
    param (
        [string]$Prompt
    )

    # Simplified to show structure - actual API call to OpenAI would go here
    # This is a placeholder to represent an API call
    $Response = "Simulated response to '$Prompt'"

    # Update chat history, maintaining the configured history length
    $ChatHistory += $Prompt, $Response
    while ($ChatHistory.Count -gt $configuration.historyLength) {
        $ChatHistory = $ChatHistory | Select-Object -Skip 2
    }

    return $Response
}

# Display greeting
Write-Host $messages.Greeting

# Start chat loop
$running = $true
while ($running) {
    # Prompt user for question
    $query = Read-Host -Prompt "$($messages.prompt)"

    switch ($query) {
        "" {
            # Empty input, display message and continue loop 
            Write-Host $messages.emptyInput 

            break
        }

        { $_ -in "quit", "exit" } { 
            # User entered `exit` or `quit`, display message and exit loop
            $running = $false

            break
        }

        default {
            # User entered a question, get response and display it

            # Prepare user message
            $userMessage = @{
                role = "user"
                content = "$query"
            }

            # Prepare conversation history
            $messages = @( $systemMessage ) + $chatHistory + @( $userMessage )

            # URI to OpenAI API
            $uri = "$($configuration.openAiUri)/openai/deployments/$($configuration.deployment)/chat/completions?api-version=2023-05-15"

            # Request body
            $body = @{
                # Conversation history
                messages = $messages

                # Number of responses to generate
                n = 1
                # Max number of tokens in response
                max_tokens = $configuration.maxTokens

                # Sample optional parameters with their default values
                temperature = 1
                presence_penalty = 0
                frequency_penalty = 0
            } | ConvertTo-Json

            # Prepare headers
            $headers = @{
                "Content-Type" = "application/json"
                "api-key" = $configuration.openAiKey
            }

            # Send request to OpenAI API
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

            # Get the first response
            $responseText = $response.choices[0].message.content

            # Display response
            Write-Host $responseText
            # Add a blank line
            Write-Host

            # Update chat history
            $ChatHistory += @( 
                $userMessage, 
                @{
                    role = "assistant"
                    content = "$responseText"
                }
            )

            # Make sure chat history is not more than $configuration.historyLength
            while ($chatHistory.Count -gt $configuration.historyLength * 2) {
                $chatHistory = $chatHistory | Select-Object -Skip 2
            }
        }
    }
}

Write-Host $messages.Exit
