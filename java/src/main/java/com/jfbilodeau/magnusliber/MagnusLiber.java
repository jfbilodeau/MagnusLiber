package com.jfbilodeau.magnusliber;

import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;
import com.google.gson.Gson;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class MagnusLiber {
    // The application configuration
    private final Configuration configuration;
    // User messages
    private final Messages messages;
    // OpenAI client
    private final OpenAIClient client;
    // System message to initialize OpenAI chat
    private final ChatRequestSystemMessage systemMessage;
    // Chat (conversation) history
    private List<ChatRequestMessage> chatHistory = new ArrayList<>();

    public MagnusLiber(Configuration configuration) throws Exception {
        // Save configuration
        this.configuration = configuration;

        // Load user messages
        this.messages = new Gson().fromJson(Files.readString(Paths.get("../Messages.json")), Messages.class);

        // Create OpenAI client
        this.client = new OpenAIClientBuilder()
                .endpoint(configuration.getOpenAiUri())
                .credential(new AzureKeyCredential(configuration.getOpenAiKey()))
                .buildClient();

        // Load system message
        String systemMessageText = Files.readString(Paths.get("../SystemMessage.txt"));
        this.systemMessage = new ChatRequestSystemMessage(systemMessageText).setName(ChatRole.SYSTEM.toString());
    }

    public void run() throws Exception {
        // Display system message
        System.out.println(messages.greeting);

        // Use a `java.util.Scanner` to get user input
        Scanner scanner = new Scanner(System.in);

        // Main loop
        boolean running = true;
        while (running) {
            // Get user input
            System.out.println(messages.prompt);
            String prompt = scanner.nextLine();

            // Process user input
            switch (prompt) {
                case "":
                    // Empty input
                    System.out.println(messages.emptyInput);
                    break;

                case "quit":
                case "exit":
                    // User typed `exit` or `quit`
                    running = false;
                    break;

                default:
                    // Get assistant response
                    var response = getAssistantResponse(prompt);

                    System.out.println(response);
                    System.out.println(); // Add a blank line after the response

                    break;
            }
        }

        System.out.println(messages.exit);
    }

    private String getAssistantResponse(String prompt) {
        // Create user request chat message
        ChatRequestMessage userMessage = new ChatRequestUserMessage(prompt)
                .setName(ChatRole.USER.toString());

        // Prepare list of chat messages, starting with system message, conversation history, then user request
        List<ChatRequestMessage> conversation = new ArrayList<>();
        conversation.add(systemMessage);
        conversation.addAll(chatHistory);
        conversation.add(userMessage);

        // Prepare chat completion options.
        ChatCompletionsOptions options = new ChatCompletionsOptions(conversation)
                // The maximum number of tokens to generate
                .setMaxTokens(configuration.getMaxTokens())
                // Set the number of desired responses
                .setN(1)
                // The following are sample parameters
                .setTemperature(0.7)
                .setTopP(1.0);

        // Create completion
        ChatCompletions completions = client.getChatCompletions(
                // The name of the Azure OpenAI deployment (not the name of the model)
                configuration.getDeployment(),
                // The chat completion options
                options
        );

        // Get the first completion
        String completion = completions.getChoices().getFirst().getMessage().getContent();

        // Add prompt and response to chat history
        chatHistory.add(userMessage);
        chatHistory.add(new ChatRequestAssistantMessage(completion).setName(ChatRole.ASSISTANT.toString()));

        // Truncate chat history
        if (chatHistory.size() > configuration.getHistoryLength()) {
            // Remove first two messages (user+assistant)
            chatHistory = chatHistory.subList(2, chatHistory.size());
        }

        return completion;
    }
}
