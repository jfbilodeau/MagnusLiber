#!/usr/bin/env bash

# Make sure `jq` is installed
if ! command -v jq &> /dev/null; then
    echo 'Error: `jq` is not installed.' >&2
    echo 'Please install `jq` before running this script.' >&2
    echo ' -> Ubuntu: `sudo apt-get install jq`' >&2
    echo ' -> CentOS: `sudo yum install jq`' >&2
    echo ' -> Mac:    `brew install jq`' >&2
    exit 1
fi

# Make sure environment variables are set
if [[ -z "$OPENAI_URL" ]] || [[ -z "$OPENAI_KEY" ]] || [[ -z "$OPENAI_DEPLOYMENT" ]]; then
    echo "Please set the OPENAI_URL, OPENAI_KEY and OPENAI_DEPLOYMENT environment variables."
    exit 1
fi

# Note: This script assumes `curl` and `awk` are installed.
historyLength=10
maxTokens=1500

# Set system message.
systemMessageText=$(awk -v RS='\r?\n' '{printf "%s\\n",$0}' ../SystemMessage.txt)
systemMessage="{\"role\":\"system\",\"content\":\"$systemMessageText\"}"

# Create conversation history
history=()

# Create user
echo "Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?"

# Start loop
running=true

while [ $running = true ]; do
    # Prompt user
    echo "Quaeris quid (What is your question)?"
    read -r input

    # Check if input is empty
    if [ -z "$input" ]; then
        echo "Me paenitet, non audivi te. (I'm sorry, I didn't hear you)"
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
    messages="$systemMessage,"

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

            \"n\": 1,
            \"max_tokens\": $maxTokens,

            \"temperature\": 0.7,
            \"top_p\": 1,
            \"presence_penalty\": 0,
            \"frequency_penalty\": 0
        }
    """

    # # Send request
    url="$OPENAI_URL/openai/deployments/$OPENAI_DEPLOYMENT/chat/completions?api-version=2023-05-15"
    response=$(curl -s -X POST -H "Api-Key: $OPENAI_KEY" -H "Content-Type: application/json" -d "$requestJson" "$url")

    # Parse response
    assistantMessage=$(echo "$response" | jq -r '.choices[0].message')

    if [ "null" == "$assistantMessage" ]; then
        echo "Error getting assistant chat response"
        echo "Reason: $response"
        exit 1
    fi
    responseText=$(echo $assistantMessage | jq -r '.content')

    # Print response
    echo "$responseText"
    echo # Blank line

    # Add response to history
    history+=("$assistantMessage")
    history+=("$userMessage")

    # Trim history
    if [ ${#history[@]} -gt $historyLength ]; then
        history=("${history[@]:2}")
    fi
done

echo "Vale et gratias tibi ago for using Magnus Liber Imperatorum."