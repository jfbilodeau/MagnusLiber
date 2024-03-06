using System.Diagnostics;
using System.Text.Json;
using Azure;
using Azure.AI.OpenAI;

// Application configuration
class Configuration {
    public string OpenAiUri { get; set; } = "";
    public string OpenAiKey { get; set; } = "";
    public string OpenAiDeployment { get; set; } = "";

    public int HistoryLength { get; set; }
}

class Messages {
    // Messages
    public string Greeting { get; set; } = "Greeting not set";
    public string Prompt { get; set; } = "Prompt not set";
    public string EmptyInput { get; set; } = "EmptyPrompt not set";
    public string Exit { get; set; } = "ExitMessage not set";
}

class Program
{
    // The configuration of the application, including the OpenAI endpoint, key, and deployment name.
    private readonly Configuration configuration;

    // Messages
    private readonly Messages messages;

    //The OpenAI client
    private readonly OpenAIClient client;

    // The system message to initialize the conversation.
    // See ../SystemMessage.txt for the content of the system message.
    private readonly ChatRequestSystemMessage systemMessage;

    // The chat history
    // This is essensial to maintain the state of the conversation.
    private readonly List<ChatRequestMessage> chatHistory = [];

    // The constructor of the application.
    public Program(Configuration configuration) {
        // Save configuration to a field
        this.configuration = configuration;

        // Load messages
        var jsonString = File.ReadAllText("../Messages.json");
        messages = JsonSerializer.Deserialize<Messages>(jsonString, new JsonSerializerOptions() {
            PropertyNameCaseInsensitive = true  // Allow camelCase property names
        }) ?? throw new Exception("Could not load messages file");

        // Create OpenAI client
        client = new OpenAIClient(
            new Uri(configuration.OpenAiUri),
            new AzureKeyCredential(configuration.OpenAiKey)
        );

        // Load and initialize the system message
        string systemMessageString = File.ReadAllText("../SystemMessage.txt");
        systemMessage = new ChatRequestSystemMessage(systemMessageString);
    }

    public async Task Run() {
        Console.WriteLine(messages.Greeting);

        bool running = true;

        while (running)
        {
            Console.WriteLine(messages.Prompt);

            string prompt = (Console.ReadLine() ?? "").Trim();

            switch (prompt)
            {
                case "":
                    Console.WriteLine(messages.EmptyInput);
                    break;

                case "quit":
                case "exit":
                    running = false;
                    break;

                default:
                    string response = await GetAssistantResponse(prompt);
                    Console.WriteLine(response);
                    break;
            }
        }

        Console.WriteLine(messages.Exit);
    }

    private async Task<string> GetAssistantResponse(string prompt) {
        // Create user message
        var userMessage = new ChatRequestUserMessage(prompt);

        // Build chat history.
        if (chatHistory.Count >= configuration.HistoryLength)
        {
            // Remove the top two message since they include the user request and
            // the assistant response.
            chatHistory.RemoveRange(0, 2);
        }

        // Create a list that contains the conversation, starting with the system message.
        List<ChatRequestMessage> conversation = [systemMessage, ..chatHistory, userMessage];

        // Prepare chat completions options.
        ChatCompletionsOptions chatCompletionsOptions = new(configuration.OpenAiDeployment, conversation) {
            // The following lines are included for demonstration purposes.
            // Adjust the following as necessary.
            Temperature = 0.7f,
            MaxTokens = 1500,
            FrequencyPenalty = 0,
            PresencePenalty = 0,
            ChoiceCount = 1,  // See note below.
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

        // Return the assistant message
        return response.Content;
    }

    private static async Task Main(string[] args)
    {
        // Load configuration file
        // If the file `MagnusLiber.dev.json` exists, use it. Otherwise, use `MagnusLiber.json`.
        var configurationFileName = File.Exists("../MagnusLiber.dev.json") ? "../MagnusLiber.dev.json" : "../MagnusLiber.json";
        var jsonString = File.ReadAllText(configurationFileName);

        // Create configuration object
        // NB: We are not using IConfiguration since `MagnusLiber.json` is not a standard .NET configuration file. 
        var configuration = JsonSerializer.Deserialize<Configuration>(jsonString, new JsonSerializerOptions() {
            PropertyNameCaseInsensitive = true  // Allow camelCase property names
        }) ??
            throw new Exception("Could not load configuration file");

        // Create application
        var app = new Program(configuration);

        // Run application
        await app.Run();
    }
}