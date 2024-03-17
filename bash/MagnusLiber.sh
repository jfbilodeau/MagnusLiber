#!/usr/bin/env bash

# Make sure 'jq' is installed.
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: `jq` is not installed.' >&2
  echo 'Please install `jq` before running this script.' >&2
  echo ' -> Ubuntu: `sudo apt-get install jq`' >&2
  echo ' -> CentOS: `sudo yum install jq`' >&2
  echo ' -> Mac:    `brew install jq`' >&2
  exit 1
fi

# Read configuration
configurationFileName='../MagnusLiber.dev.json'
if [ ! -f $configurationFileName ]; then
    $configurationFileName="../MagnusLiber.json"
fi

configurationJson=$(cat $configurationFileName)

declare -A configuration=(
    [openAiUri]=$(echo $configurationJson | jq -r .openAiUri)
    [openAiKey]=$(echo $configurationJson | jq -r .openAiKey)
    [deployment]=$(echo $configurationJson | jq -r .deployment)
    [historyLength]=$(echo $configurationJson | jq .historyLength)
    [maxTokens]=$(echo $configurationJson | jq -r .maxTokens)
)

# Read UI messages
uiMessagesJson=$(cat "../Messages.json")

declare -A uiMessages=(
    [greeting]=$(echo $uiMessagesJson | jq -r .greeting)
    [prompt]=$(echo $uiMessagesJson | jq -r .prompt)
    [emptyPrompt]=$(echo $uiMessagesJson | jq -r .emptyPrompt)
    [exit]=$(echo $uiMessagesJson | jq -r .exit)
)

# Read system message.
systemMessageText=$(awk '{printf "%s\\n", $0}' ../SystemMessage.txt)
systemMessage="{\"role\":\"system\",\"content\":\"$systemMessageText\"}"
echo "System message: $systemMessageText"

# Create history
history=()

# Create user
echo "${uiMessages["greeting"]}"

# Start loop
running=true

while [ $running = true ]; do
    # Prompt user
    echo "${uiMessages["prompt"]}"
    read -r input

    # Check if input is empty
    if [ -z "$input" ]; then
        echo "${uiMessages["emptyPrompt"]}"
        continue
    fi

    # Check if user wants to exit
    if [[ "$input" = "exit" ]] || [[ "$input" = "quit" ]]; then
        running=false
        break
    fi

    # Prepare user message
    userMessage="{\"role\":\"user\",\"content\":\"$input\"}"

    # Join messages (conversation) in JSON array as a string
    messages="${systemMessage},"

    if [ ${#history[@]} -gt 0 ]; then
        for message in "${history[@]}"; do
            messages+="$message,"
        done
    fi

    messages+="$userMessage"

    # Prepare request
    requestJson="""
        {
            \"messages\": [ $messages ],
            \"model\": \"${configuration["deployment"]}\",
            \"n\": 1,
            \"max_tokens\": ${configuration["maxTokens"]},

            \"temperature\": 0.7,
            \"top_p\": 1,
            \"presence_penalty\": 0,
            \"frequency_penalty\": 0,
        }
    """

    echo "JSON = $requestJson"

    # # Send request
    url="${configuration["openAiUri"]}/openai/deployments/${configuration["deployment"]}/chat/completions?api-version=2023-05-15"
    response=$(curl -s -X POST -H "Api-Key: ${configuration["openAiKey"]}" -H "Content-Type: application/json" -d "$requestJson" "$url")

    # # Parse response
    # responseText=$(echo $response | jq -r .choices[0].text)

    # Print response
    echo "$response"

    # Add response to history
    history+=("$input")

    history+=("$responseText")
done