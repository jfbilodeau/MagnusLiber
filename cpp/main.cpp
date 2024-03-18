#include "root_certificates.hpp"

#include "boost/asio.hpp"
#include "boost/asio/ssl.hpp"
#include "boost/beast.hpp"
#include "boost/beast/ssl.hpp"
#include <boost/json.hpp>
#include <boost/url.hpp>

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>

// Since the C++ SDK for OpenAI is not yet available, we will reproduce some basic data structures here.

// The chat message request roles
constexpr auto ROLE_SYSTEM = "system";
constexpr auto ROLE_USER = "user";
constexpr auto ROLE_ASSISTANT = "assistant";

// The following chat roles are not used in the demo but included for completion
constexpr auto ROLE_TOOL = "tool";
constexpr auto ROLE_FUNCTION = "function";

// An OpenAI chat message request
struct ChatMessageRequest
{
    std::string role;
    std::string content;
};

int main()
{
    // Setup configuration
    auto openAiUri = std::getenv("OPENAI_URL");
    auto openAiKey = std::getenv("OPENAI_KEY");
    auto deployment = std::getenv("OPENAI_DEPLOYMENT");
    auto historyLength = 10;
    auto maxTokens = 150;

    // Validate configuration
    if (openAiUri == nullptr || openAiKey == nullptr || deployment == nullptr) {
        std::cerr << "Error: Environment variables OPENAPI_URL, OPENAPI_KEY, and OPENAPI_DEPLOYMENT must be set." << std::endl;
        return 1;
    }

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

    // Initialize ASIO and TLS
    boost::asio::io_context io_context;
    boost::asio::ssl::context ssl_context(boost::asio::ssl::context::tlsv12_client);

    // Load the root certificates
    load_root_certificates(ssl_context);
    ssl_context.set_verify_mode(boost::asio::ssl::verify_peer);

    boost::asio::ip::tcp::resolver resolver(io_context);

    // URL to the OpenAI API
    auto openAiRequestUrl = std::string() + openAiUri + "openai/deployments/" + deployment + "/chat/completions?api-version=2023-05-15";
    auto url = boost::urls::parse_uri(openAiRequestUrl);
    // Decompose URL
    // Forcing the use of `std::string` to avoid the need to use `std::string_view` in the rest of the code. Easier to debug.
    std::string openAiHost = url->host_name();
    std::string openAiProtocol = url->scheme();
    std::string openAiPath = url->path() + "?" + url->query();

    // Resolve the domain name
    auto const resolved_host = resolver.resolve(openAiHost, openAiProtocol);

    // Greet the user
    std::cout << "Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?" << std::endl;

    // Start the application loop
    auto running = true;

    while (running)
    {
        // Prompt the user
        std::cout << "Quaeris quid (What is your question)?" << std::endl;
        std::string userInput;

        std::getline(std::cin, userInput);

        if (userInput.empty())
        {
            std::cout << "Me paenitet, non audivi te. (I'm sorry, I didn't hear you)" << std::endl;
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
            std::vector<ChatMessageRequest> conversation;
            conversation.reserve(chatHistory.size() + 2); // Pre-allocate enought room to store the system message, chat history, and user message

            conversation.push_back(systemMessage);  // Add the system message to the conversation
            conversation.insert(conversation.end(), chatHistory.begin(), chatHistory.end());  // Add the chat history to the conversation
            conversation.push_back(userRequest);  // Add the user message to the conversation

            // Convert to JSON array
            boost::json::array conversationJson;

            for (auto [role, content] : conversation)
            {
                conversationJson.push_back({
                    {"role", role},
                    {"content", content}
                });
            }

            // Create the OpenAI request body
            boost::json::object requestBodyJson = {
                // Name of the deployment
                {"model", deployment},
                // The conversation history
                {"messages", conversationJson},
                // The maximum number of tokens to generate
                {"max_tokens", maxTokens},
                // The number of responses to generate
                {"n", 1},

                // The next set of parameters are optional and include as example with their default values.
                {"temperature", 0.7},
                {"top_p", 0.95},
                {"presence_penalty", 0.0},
                {"frequency_penalty", 0.0},
            };

            // Convert JSON body to string
            std::string requestBody = serialize(requestBodyJson);

            // This section is low level and may seem a bit messy
            // In production code, an HTTP client and OpenSSL or a similar library would be used to simplify this request

            // Create TLS stream.
            boost::beast::ssl_stream<boost::beast::tcp_stream> stream(io_context, ssl_context);

            // Set SNI Hostname (many hosts need this to handshake successfully)
            if(!SSL_set_tlsext_host_name(stream.native_handle(), openAiHost.c_str()))
            {
                std::cerr << "Error: Failed to set SNI hostname for SSL connection." << std::endl;
            }

            // Make the connection on the IP address we get from a lookup
            boost::beast::get_lowest_layer(stream).connect(resolved_host);

            // Perform the SSL handshake
            stream.handshake(ssl::stream_base::client);

            // Set up an HTTP POST request message
            boost::beast::http::request<boost::beast::http::string_body> req {
                boost::beast::http::verb::post,
                openAiPath,
                11  // HTTP/1.1
            };
            req.set(boost::beast::http::field::host, openAiHost);
            req.set("api-key", openAiKey);
            req.body().assign(requestBody);
            req.chunked(true);

            // Send the HTTP request to the remote host
            boost::beast::http::write(stream, req);

            // This buffer is used for reading and must be persisted
            boost::beast::flat_buffer buffer;

            // Declare a container to hold the response
            boost::beast::http::response<boost::beast::http::string_body> httpResponse;

            // Receive the HTTP response
            boost::beast::http::read(stream, buffer, httpResponse);

            // Get the text of the body.
            std::string responseText = httpResponse.body();

            // Read the JSON response
            auto responseJson = boost::json::parse(responseText);

            // Extract the assistant message
            auto pointer = responseJson.at_pointer("/choices/0/message/content");
            auto assistantMessage = pointer.get_string().c_str();

            // Print the assistant message
            std::cout << assistantMessage << std::endl;
            std::cout << std::endl;  // Blank line after response.

            // Add assistant message to chat history
            chatHistory.push_back({ ROLE_ASSISTANT, assistantMessage });

            // Trim chat history to the last `historyLength` messages
            if (chatHistory.size() > historyLength)
            {
                // Remove the top two messages
                chatHistory.erase(chatHistory.begin()+2, chatHistory.end());
            }
        }
    }

    std::cout << "Vale et gratias tibi ago for using Magnus Liber Imperatorum." << std::endl;
}
