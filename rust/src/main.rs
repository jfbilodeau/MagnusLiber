use std::fs::File;
use std::io;
use std::path::Path;

use reqwest::header::{HeaderMap, HeaderValue};
use reqwest::Url;
use serde::{Deserialize, Serialize};
use serde_json;

#[derive(Serialize, Deserialize)]
struct Configuration {
    #[serde(alias = "openAiUri")]
    open_ai_uri: String,
    #[serde(alias = "openAiKey")]
    open_ai_key: String,
    #[serde(alias = "deployment")]
    deployment: String,

    #[serde(alias = "historyLength")]
    history_length: i32,
    #[serde(alias = "maxTokens")]
    max_tokens: i32,
}

#[derive(Serialize, Deserialize)]
struct UiMessages {
    greeting: String,
    prompt: String,
    #[serde(alias = "emptyPrompt")]
    empty_prompt: String,
    exit: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    System,
    Assistant,
    User,
}

#[derive(Clone, Serialize, Deserialize)]
struct ChatMessage {
    content: String,
    role: Role,
}

#[derive(Serialize, Deserialize)]
struct ChatRequestBody {
    messages: Vec<ChatMessage>,
    max_tokens: i32,
    n: i32,
    temperature: f32,
    top_p: f32,
    frequency_penalty: f32,
    presence_penalty: f32,
}

#[derive(Serialize, Deserialize)]
struct Choice {
    message: ChatMessage,
    // Additional fields omitted...
}

#[derive(Serialize, Deserialize)]
struct ChatResponseBody {
    choices: Vec<Choice>,
    // Additional fields omitted...
}

#[tokio::main]
async fn main() {
    // Read configuration
    let mut path = Path::new("../MagnusLiber.dev.json");

    if !path.exists() {
        path = Path::new("../MagnusLiber.json");
    }

    if !path.exists() {
        panic!("{} file not found", path.to_str().unwrap());
    }

    let reader = File::open(path).unwrap();
    let configuration: Configuration = serde_json::from_reader(reader).unwrap();

    // Load UI messages
    let path = Path::new("../messages.json");

    if !path.exists() {
        panic!("{} messages file not found", path.to_str().unwrap());
    }

    let reader = File::open(path).unwrap();
    let ui_messages: UiMessages = serde_json::from_reader(reader).unwrap();

    // Load system message
    let path = Path::new("../SystemMessage.txt");
    let system_message_text = std::fs::read_to_string(path).unwrap();
    let system_message = ChatMessage {
        content: system_message_text,
        role: Role::System,
    };

    // Initialize OpenAI client
    let url_string = format!(
        "{}openai/deployments/{}/chat/completions?api-version=2023-05-15",
        configuration.open_ai_uri,
        configuration.deployment
    );

    let url = Url::parse(&url_string).unwrap();
    let host = url.host_str().unwrap().to_string();

    // Conversation history
    let mut history: Vec<ChatMessage> = Vec::new();

    // Greet user
    println!("{}", ui_messages.greeting);

    // Start main loop
    let mut running = true;

    while running {
        // Get user input
        println!("{}", ui_messages.prompt);

        let mut input = String::new();
        io::stdin().read_line(&mut input).unwrap();
        input = input.trim().to_string();

        match input.as_str() {
            "" => {
                println!("{}", ui_messages.empty_prompt);
                continue;
            }

            "exit" | "quit" => {
                running = false;
                continue;
            }
            _ => {
                // Create user message
                let user_message = ChatMessage {
                    content: input,
                    role: Role::User,
                };

                // Create conversation
                let mut conversation = vec![
                    system_message.clone(),
                ];

                conversation.append(&mut history.clone());
                conversation.push(user_message.clone());

                // Prepare chat body request
                let chat_body = ChatRequestBody {
                    messages: conversation,
                    max_tokens: configuration.max_tokens,
                    n: 1,  // Number of responses to generate

                    // The following parameters are provide as an example
                    temperature: 0.7,
                    top_p: 0.95,
                    frequency_penalty: 0.0,
                    presence_penalty: 0.0,

                    // There are additional parameters that can be passed to Azure OpenAI
                    // https://learn.microsoft.com/en-us/azure/ai-services/openai/reference
                };

                // Send request to Azure OpenAI
                let mut headers = HeaderMap::new();

                // headers.insert(
                //     HOST,
                //     HeaderValue::from_str(&host).unwrap()
                // );
                headers.insert(
                    "api-key",
                    HeaderValue::from_str(&configuration.open_ai_key).unwrap(),
                );

                let client = reqwest::ClientBuilder::new()
                    .default_headers(headers)
                    .build()
                    .unwrap();

                let response = client.post(url.clone())
                    .json(&chat_body)
                    .send()
                    .await
                    .unwrap();

                if !response.status().is_success() {
                    panic!("Error: {}\nResponse: {}", response.status(), response.text().await.unwrap());
                }

                let completion = response.json::<ChatResponseBody>().await.unwrap();

                // Get assistant message
                let assistant_message = completion.choices[0].message.clone();

                // Print response
                println!("{}", assistant_message.content);

                // Add user and assistant message to history
                history.push(user_message);
                history.push(assistant_message);

                // Trim history
                if history.len() > configuration.history_length as usize {
                    history = history[history.len() - configuration.history_length as usize..].to_vec();
                }
            }
        }
    }

    // Display quit message
    println!("{}", ui_messages.exit);
}
