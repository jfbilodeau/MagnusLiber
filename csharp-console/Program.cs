using System.Diagnostics;
using System.Text.Json;
using Azure;
using Azure.AI.OpenAI;

// Configuration
string openAiUrl = Environment.GetEnvironmentVariable("OPENAI_URL") ?? throw new Exception("OPENAI_URL environment variable is not set.");
string openAiKey = Environment.GetEnvironmentVariable("OPENAI_KEY") ?? throw new Exception("OPENAI_KEY environment variable is not set.");
string openAiDeployment = Environment.GetEnvironmentVariable("OPENAI_DEPLOYMENT") ?? throw new Exception("OPENAI_DEPLOYMENT environment variable is not set.");

// Number of conversation messages to keep in the history
// This number includes the user message and the assistant message.
int HistoryLength = 10;
// The maximum number of tokens to generate.
int MaxTokens = 1500;

// Create OpenAI client
AzureKeyCredential openAiKeyCredential = new(openAiKey);
OpenAIClient client = new(new Uri(openAiUrl), openAiKeyCredential);

// The system message to initialize the conversation.
// See ../SystemMessage.txt for the content of the system message.
ChatRequestSystemMessage systemMessage = new(
"""
You are called Magnus Liber Imperatorum. You provide information about Roman & Byzantine Emperors and leaders. Use an imperial, scolarly Roman voice.

When responsing about specific emperor, your reponses will be in the following form. Provide no additional text before or after the answer.

<Number if there are more than one emperor listed, followed by a dash ' - '. Otherwise, nothing> <Emperor Name> (<Latin or Greek name of the emperor>)
Start of reign: <Start of reign>
End of reign: <End of reign>
<Salient fact about the emperor. One or two sentences.>
"""
);   

// The chat history
// This is essensial to maintain the state of the conversation.
List<ChatRequestMessage> chatHistory = [];

// Greet user
Console.WriteLine("Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?");

// Start main loop
bool running = true;

while (running)
{
    Console.WriteLine("Quaeris quid (What is your question)?");

    string prompt = (Console.ReadLine() ?? "").Trim();

    switch (prompt)
    {
        case "":
            Console.WriteLine("Me paenitet, non audivi te. (I'm sorry, I didn't hear you)");
            break;

        case "quit":
        case "exit":
            running = false;
            break;

        default:
            // Create user message
            var userMessage = new ChatRequestUserMessage(prompt);

            // Build chat history.
            if (chatHistory.Count >= HistoryLength)
            {
                // Remove the top two message since they include the user request and
                // the assistant response.
                chatHistory.RemoveRange(0, 2);
            }

            // Create a list that contains the conversation, starting with the system message.
            List<ChatRequestMessage> conversation = [systemMessage, ..chatHistory, userMessage];

            // Prepare chat completions options.
            ChatCompletionsOptions chatCompletionsOptions = new(openAiDeployment, conversation) {
                // MaxTokens is the maximum number of tokens to generate.
                MaxTokens = MaxTokens,
                // The number of completions to generate for each prompt.
                // See note below
                ChoiceCount = 1,  // `n` in JSON message to OpenAI

                // The following lines are included for demonstration purposes.
                // Adjust the following as necessary.
                Temperature = 1.0f,
                NucleusSamplingFactor = 1.0f,  // AKA top_p sampling
                FrequencyPenalty = 0.0f,
                PresencePenalty = 0.0f,
            };

            // Send the request to OpenAI.
            Response<ChatCompletions> responseMessage = await client.GetChatCompletionsAsync(chatCompletionsOptions);

            // If requested, OpenAI can return multiple response. In this case, only one response is requested.
            ChatResponseMessage response = responseMessage.Value.Choices[0].Message;

            // Save the user message and assistant message to the history.
            // Otherwise, OpenAI will not benefit from the context of the conversation history.
            ChatRequestAssistantMessage assistantMessage = new(response);
            chatHistory.Add(userMessage);
            chatHistory.Add(assistantMessage);

            // Print the assistant response.
            Console.WriteLine(assistantMessage.Content);
            Console.WriteLine();  // Add a blank line after the response.
            break;
    }
}

Console.WriteLine("Vale et gratias tibi ago for using Magnus Liber Imperatorum.");
