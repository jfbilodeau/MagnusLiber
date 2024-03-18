const fs = require('fs')
const openai = require('@azure/openai')
const readline = require('node:readline/promises')

async function main() {
    // Configuration
    const openAiUrl = process.env.OPENAI_URL
    const openAiKey = process.env.OPENAI_KEY
    const openAiDeployment = process.env.OPENAI_DEPLOYMENT

    // Check for missing configuration
    if (!openAiUrl || !openAiKey || !openAiDeployment) {
        console.error("Please set the OPENAI_URL, OPENAI_KEY, and OPENAI_DEPLOYMENT environment variables.")
        process.exit(1)
    }

    const historyLength = 10
    const maxTokens = 1500

    // Load system message text
    const systemMessageText = fs.readFileSync(`../SystemMessage.txt`, `utf-8`)

    // Create the system message
    const systemMessage = {
        'content': systemMessageText,
        'role': 'system'
    }

    // Create the OpenAI client
    const client = new openai.OpenAIClient(
        openAiUrl,
        new openai.AzureKeyCredential(openAiKey)
    );

    // Create the chat history.
    const chatHistory = []

    // Greet user
    console.log("Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?")

    // Use node:readline to read user input
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    // Start conversation loop
    let running = true
    while (running) {
        // Get user input
        console.log("Quaeris quid (What is your question)?")
        let query = await rl.question(``)
        query = query.trim()  // Get rid of whitespace

        switch (query) {
            case '':
                console.log("Me paenitet, non audivi te. (I'm sorry, I didn't hear you)")
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
                const messages = [
                    systemMessage,
                    ...chatHistory,
                    userMessage,
                ]

                // Prepare the options
                const options = {
                    // The maximum number of tokens to generate
                    max_tokens: maxTokens,
                    // The number of responses to generate
                    n: 1,

                    // The following are provided to reference only and as set to their default value
                    // This is not a complete list of options
                    temperature: 1.0,
                    top_p: 1.0,
                    frequency_penalty: 0.0,
                    presence_penalty: 0.0,
                }

                // Send conversation to OpenAI
                const response = await client.getChatCompletions(openAiDeployment, messages, options)

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
                if (chatHistory.length > historyLength) {
                    chatHistory.splice(0, chatHistory.length - historyLength)
                }
        }
    }

    // Close the readline interface
    rl.close()

    // Display a goodbye message
    console.log("Vale et gratias tibi ago for using Magnus Liber Imperatorum.")
}

// Call main as a promise so we can use async/await in the demo code.
main().catch((err) => {
    console.error("The sample encountered an error:", err);
})