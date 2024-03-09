const fs = require('fs')
const openai = require('@azure/openai')
const readline = require('node:readline/promises')

async function main() {
    // Load OpenAI configuration
    let configurationFileName = `../MagnusLiber.json`

    // Check if `../MagnusLiber.dev.json` exists
    if (fs.existsSync(`../MagnusLiber.dev.json`)) {
        configurationFileName = `../MagnusLiber.dev.json`
    }

    // Load the configuration
    const configuration = require(configurationFileName)

    // Load user messages
    const messages = require(`../Messages.json`)

    // Load system message text
    const systemMessageText = fs.readFileSync(`../SystemMessage.txt`, 'utf8')

    // Create the system message
    const systemMessage = {
        'content': systemMessageText,
        'role': 'system'
    }

    // Create the OpenAI client
    const client = new openai.OpenAIClient(
        configuration.openAiUri,
        new openai.AzureKeyCredential(configuration.openAiKey)
    );

    // Create the chat history.
    const chatHistory = []

    // Greet user
    console.log(messages.greeting)

    // Use node:readline to read user input
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    // Start conversation loop
    let running = true
    while (running) {
        // Get user input
        console.log(messages.prompt)
        let query = await rl.question(``)
        query = query.trim()  // Get rid of whitespace

        switch (query) {
            case '':
                console.log(messages.emptyPrompt)
                break

            case 'exit':
            case 'quit':
                running = false
                break

            default:

                // Create user message
                const userMessage = {
                    'content': query,
                    'role': 'user'
                }

                // Prepare the conversation messages.
                const conversationMessage = [
                    systemMessage,
                    ...chatHistory,
                    userMessage,
                ]

                // Prepare the options
                const options = {
                    // The maximum number of tokens to generate
                    maxTokens: configuration.maxTokens,
                    // The number of responses to generate
                    n: 1,

                    // The following are provided to reference only and as set to their default value
                    // This is not a complete list of options
                    'temperature': 1.0,
                    'top_p': 1.0,
                    'frequency_penalty': 0.0,
                    'presence_penalty': 0.0,
                }

                // Send conversation to OpenAI
                const response = await client.getChatCompletions(configuration.deployment, conversationMessage, options)

                // Get the response text
                const responseText = response.choices[0].message.content

                // Print the response
                console.log(responseText)
                console.log() // Add a blank line after the response

                // Add the user and assistant message to the chat history
                chatHistory.push(userMessage)
                chatHistory.push({
                    'content': responseText,
                    'role': 'assistant'
                })

                // Trim the history if necessary
                if (chatHistory.length > configuration.historyLength) {
                    chatHistory.splice(0, chatHistory.length - configuration.historyLength)
                }
        }
    }

    // Close the readline interface
    rl.close()

    // Display a goodbye message
    console.log(messages.exit)
}

// Call main as a promise so we can use async/await in the demo code.
main().catch((err) => {
    console.error("The sample encountered an error:", err);
})