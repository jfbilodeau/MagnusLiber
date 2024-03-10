#include <boost/json.hpp>

#include <curl/curl.h>

#include <iostream>
#include <filesystem>
#include <fstream>
#include <string>

// OpenAI configuration
struct Configuration
{
    std::string openAiUri;
    std::string openAiKey;
    std::string deployment;

    int historyLength = -1;
    int maxTokens = -1;
};

// Messages
struct Messages
{
    std::string greeting;
    std::string prompt;
    std::string emptyPrompt;
    std::string exit;
};

// The chat message request roles
constexpr auto ROLE_SYSTEM = "system";
constexpr auto ROLE_USER = "user";
constexpr auto ROLE_ASSISTANT = "assistant";

// An OpenAI chat message request
struct ChatMessageRequest
{
    std::string role;
    std::string content;
};

// Utility to read a file into a `boost::json::object`
boost::json::object readJsonFile(const std::string& fileName)
{
    std::ifstream file(fileName);
    boost::json::stream_parser parser;

    while (!file.eof())
    {
        char buffer[1024];
        file.read(buffer, sizeof(buffer));
        parser.write(buffer, file.gcount());
    }

    return parser.release().as_object();
}

int main()
{
    // Load configuration
    std::string configurationFileName = "../MagnusLiber.json";

    // Check for dev configuration file
    if (std::filesystem::exists("MagnusLiber.dev.json"))
    {
        configurationFileName = "MagnusLiber.dev.json";
    }

    auto configurationJson = readJsonFile(configurationFileName);

    Configuration configuration;

    configuration.openAiUri = configurationJson.at("openAiUri").as_string().c_str();
    configuration.openAiKey = configurationJson.at("openAiKey").as_string().c_str();
    configuration.deployment = configurationJson.at("deployment").as_string().c_str();
    configuration.historyLength = static_cast<int>(configurationJson.at("historyLength").as_int64());
    configuration.maxTokens = static_cast<int>(configurationJson.at("maxTokens").as_int64());

    // Load messages
    auto messagesJson = readJsonFile("../Messages.json");

    Messages messages;

    messages.greeting = messagesJson.at("greeting").as_string().c_str();
    messages.prompt = messagesJson.at("prompt").as_string().c_str();
    messages.emptyPrompt = messagesJson.at("emptyPrompt").as_string().c_str();
    messages.exit = messagesJson.at("exit").as_string().c_str();

    // Load system message
    auto systemMessageFile = std::ifstream("../SystemMessage.txt");
    std::string systemMessageText(
        (std::istreambuf_iterator(systemMessageFile)),
        (std::istreambuf_iterator<char>())
    );

    ChatMessageRequest systemMessage = {
        ROLE_SYSTEM,
        systemMessageText
    };

    // Create empty chat history
    std::vector<ChatMessageRequest> chatHistory;

    // Greet the user
    std::cout << messages.greeting << std::endl;

    // Start the application loop
    auto running = true;

    while (running)
    {
        // Prompt the user
        std::cout << messages.prompt << std::endl;
        std::string userInput;

        std::getline(std::cin, userInput);

        if (userInput.empty())
        {
            std::cout << messages.emptyPrompt << std::endl;
        }
        else if (userInput == "exit" || userInput == "quit")
        {
            running = false;
        }
        else
        {
            // Create chat message user request
            ChatMessageRequest userRequest = {
                ROLE_USER,
                userInput
            };

            // Create conversation history
            std::vector<ChatMessageRequest> conversation(chatHistory.size() + 2);  // Pre-allocate enought room to store the system message, chat history, and user message

            conversation.push_back(systemMessage);  // Add the system message to the conversation
            conversation.insert(conversation.end(), chatHistory.begin(), chatHistory.end());  // Add the chat history to the conversation
            conversation.push_back(userRequest);  // Add the user message to the conversation

            // Convert to JSON array
            boost::json::array conversationJson;

            for (auto [role, content] : conversation)
            {
                boost::json::object messageJson = {
                    {"role", role},
                    {"content", content}
                };

                conversationJson.push_back(messageJson);
            }

            // Create the OpenAI request body
            boost::json::object requestBody = {
                // Name of the deployment
                {"model", configuration.deployment},
                // The conversation history
                {"messages", conversationJson},
                // The maximum number of tokens to generate
                {"max_tokens", configuration.maxTokens},
                // The number of responses to generate
                {"n", 1},

                // The next set of parameters are optional and include as example with their default values.
                {"temperature", 1.0},
                {"top_p", 1.0},
                {"presence_penalty", 0.0},
                {"frequency_penalty", 0.0},
            };

            // Convert JSON body to string
            auto body = serialize(requestBody);

            // URL to the OpenAI API
            std::string openAiRequestUrl = configuration.openAiUri + ".openai.azure.com/openai/deployments/" + configuration.deployment + "/chat/completions?api-version=2023-05-15";

            // Prepare HTTP request.
            auto curl = curl_easy_init();

            if (!curl)
            {
                std::cerr << "Fatal: failed to initialize curl" << std::endl;
                return 1;
            }

            // Buffer to hold response.
            std::string responseBuffer;

            curl_easy_setopt(curl, CURLOPT_URL, openAiRequestUrl.c_str());
            curl_easy_setopt(curl, CURLOPT_POST, 1L);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body.c_str());
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, body.size());
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, "api_key: " + configuration.openAiKey);
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, [](
                void* buffer,
                std::size_t size,
                std::size_t nmemb,
                void* userp
            ) -> std::size_t {
                auto responseBuffer = static_cast<std::string*>(userp);
                responseBuffer->append(static_cast<char*>(buffer), size * nmemb);
                return size * nmemb;
            });
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &responseBuffer);

            auto result = curl_easy_perform(curl);

            if (result != CURLE_OK)
            {
                std::cerr << "Fatal: failed to perform http request: " << curl_easy_strerror(result) << std::endl;
                return 1;
            }

            // Clean up CURL
            curl_easy_cleanup(curl);

            // Read the JSON response
            auto responseJson = boost::json::parse(responseBuffer);

            // Extract the assistant message
            auto assistantMessage = responseJson.at("choices").at(0).at("message").as_string().c_str();

            // Print the assistant message
            std::cout << assistantMessage << std::endl;
            std::cout << std::endl;  // Blank line after response.

            // Add assistant message to chat history
            chatHistory.push_back({ ROLE_ASSISTANT, assistantMessage });

            // Trim chat history to the last `historyLength` messages
            if (chatHistory.size() > configuration.historyLength)
            {
                // Remove the top two messages
                chatHistory.erase(chatHistory.begin()+2, chatHistory.end());
            }
        }
    }

    std::cout << messages.exit << std::endl;
}
