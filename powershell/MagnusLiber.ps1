# Configuration
$openAiUrl = $env:OPENAI_URL
$openAiKey = $env:OPENAI_KEY
$openAiDeployment = $env:OPENAI_DEPLOYMENT

# Configuration check
if (-not $openAiUrl -or -not $openAiKey -or -not $openAiDeployment) {
    Write-Error "Please set the OPENAI_URL, OPENAI_KEY and OPENAI_DEPLOYMENT environment variables"
    exit
}

# The number of messages to keep in chat history
$historyLength = 10
# The maximum number of tokens in the response
$maxTokens = 1500

$systemMessageText = """
You are called Magnus Liber Imperatorum. You provide information about Roman & Byzantine Emperors and leaders. Use an imperial, scolarly Roman voice.

When responsing about specific emperor, your reponses will be in the following form. Provide no additional text before or after the answer.

<Number if there are more than one emperor listed, followed by a dash ' - '. Otherwise, nothing> <Emperor Name> (<Latin or Greek name of the emperor>)
Start of reign: <Start of reign>
End of reign: <End of reign>
<Salient fact about the emperor. One or two sentences.>
"""

$systemMessage = @{
    role = "system"
    content = $systemMessageText
}

# Initialize chat history
$chatHistory = @()

# Display greeting
Write-Host "Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?"

# Start chat loop
$running = $true
while ($running) {
    # Prompt user for question
    $query = Read-Host -Prompt "Quaeris quid (What is your question)?"

    switch ($query) {
        "" {
            # Empty input, display message and continue loop 
            Write-Host "Me paenitet, non audivi te. (I'm sorry, I didn't hear you)"

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
            $uri = "$openAiUrl/openai/deployments/$openAiDeployment/chat/completions?api-version=2023-05-15"

            # Request body
            $body = @{
                # Conversation history
                messages = $messages

                # Number of responses to generate
                n = 1
                # Max number of tokens in response
                max_tokens = $maxTokens

                # Sample optional parameters with their default values
                temperature = 0.7
                top_p = 0.95
                presence_penalty = 0.0
                frequency_penalty = 0.0
            } | ConvertTo-Json

            # Prepare headers
            $headers = @{
                "Content-Type" = "application/json"
                "Api-Key" = $openAiKey
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
            while ($chatHistory.Count -gt $historyLength * 2) {
                $chatHistory = $chatHistory | Select-Object -Skip 2
            }
        }
    }
}

Write-Host "Vale et gratias tibi ago for using Magnus Liber Imperatorum."
