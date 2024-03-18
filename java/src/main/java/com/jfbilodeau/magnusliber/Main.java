package com.jfbilodeau.magnusliber;

import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Main {
    public static void main(String[] args) throws Exception {
        // Read configuration
        var openAiUrl = System.getenv("OPENAI_URL");
        var openAiKey = System.getenv("OPENAI_KEY");
        var deployment = System.getenv("OPENAI_DEPLOYMENT");

        if (openAiUrl == null || openAiKey == null || deployment == null) {
            System.err.println("Please set the following environment variables: OPENAI_URL, OPENAI_KEY, OPENAI_DEPLOYMENT");
            return;
        }

        // Number of chat messages to keep in history
        var historyLength = 10;

        // Maximum number of tokens to generate
        var maxTokens = 150;

        // Create Azure OpenAI client
        var client = new OpenAIClientBuilder()
                .endpoint(openAiUrl)
                .credential(new AzureKeyCredential(openAiKey))
                .buildClient();

        // Load system message
        String systemMessageText = Files.readString(Paths.get("../SystemMessage.txt"));
        var systemMessage = new ChatRequestSystemMessage(systemMessageText).setName(ChatRole.SYSTEM.toString());

        // Create chat history
        List<ChatRequestMessage> chatHistory = new ArrayList<>();

        // Display system message
        System.out.println("Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?");

        // Use a `java.util.Scanner` to get user input
        Scanner scanner = new Scanner(System.in);

        // Main loop
        boolean running = true;
        while (running) {
            // Get user input
            System.out.println("Quaeris quid (What is your question)?");
            String prompt = scanner.nextLine();

            // Process user input
            switch (prompt) {
                case "":
                    // Empty input
                    System.out.println("Me paenitet, non audivi te. (I'm sorry, I didn't hear you)");
                    break;

                case "quit":
                case "exit":
                    // User typed `exit` or `quit`
                    running = false;
                    break;

                default:
                    // Get assistant response
                    // Create user request chat message
                    var userMessage = new ChatRequestUserMessage(prompt)
                            .setName(ChatRole.USER.toString());

                    // Prepare list of chat messages, starting with system message, conversation history, then user request
                    List<ChatRequestMessage> conversation = new ArrayList<>();
                    conversation.add(systemMessage);
                    conversation.addAll(chatHistory);
                    conversation.add(userMessage);

                    // Prepare chat completion options.
                    ChatCompletionsOptions options = new ChatCompletionsOptions(conversation)
                            // The maximum number of tokens to generate
                            .setMaxTokens(maxTokens)
                            // Set the number of desired responses
                            .setN(1)
                            // The following are sample parameters
                            .setTemperature(0.7)
                            .setTopP(1.0);

                    // Create completion
                    ChatCompletions completions = client.getChatCompletions(
                            // The name of the Azure OpenAI deployment (not the name of the model)
                            deployment,
                            // The chat completion options
                            options
                    );

                    // Get the first completion
                    String completion = completions.getChoices().getFirst().getMessage().getContent();
                    var assistantMessage = new ChatRequestAssistantMessage(completion);
                    assistantMessage.setName(ChatRole.ASSISTANT.toString());

                    // Add prompt and response to chat history
                    chatHistory.add(userMessage);
                    chatHistory.add(assistantMessage);

                    // Truncate chat history
                    if (chatHistory.size() > historyLength) {
                        // Remove first two messages (user+assistant)
                        chatHistory = chatHistory.subList(2, chatHistory.size());
                    }

                    System.out.println(assistantMessage.getContent());
                    System.out.println(); // Add a blank line after the response

                    break;
            }
        }

        System.out.println("Vale et gratias tibi ago for using Magnus Liber Imperatorum.");

        System.exit(0);
    }
}
