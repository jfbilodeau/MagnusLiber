# Magnus Liber Imperatorum

# A set of Azure OpenAI demos

Welcome to **Magnus Liber Imperatorum**, the Great Book of Roman Emperors.

Magnus Liber is an Azure OpenAI demos written in different programming languages. The goal of the demos is to illustrate basic use of the [OpenAI chat completion API](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference#chat-completions), including request parameters, response and conversation management.

## Getting started

To run Magnus Liber in any programming language, an Azure Subscription and an Azure OpenAI deployment will be necessary.

1. If necessary, get a [free Azure subscription](https://azure.microsoft.com/en-ca/free).
2. Create an [Azure OpenAI service resource](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource).
3. Deploy either an [OpenAI `gpt-4` or `gpt-3-turbo` model](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/provisioned-get-started).
4. Run `git clone https://github.com/jfbilodeau/MagnusLiber.git`
5. Run `cd MagnusLiber`
6. Enter the directory of the demo you wish to run and review the instructions in `README.md`. All demos will require that the following environment variables be set:
    - `OPENAI_URL`
    - `OPENAI_KEY`
    - `OPENAI_DEPLOYMENT`

## Design Goal

- Consistent functionality across demos
- Idiomatic code
- Minimize local dependencies
- Favour Azure OpenAI SDK when available
- For simplicity, written as one function
- For clarity, there is very little error handling


## Programming Languages demos
- [Bash](./bash/README.md)
- [C++](./cpp/README.md)
- [C# (Console)](./csharp-console/README.md)
- [Delphi (Console)](./delphi-console/README.md)
- [Go](./go/README.md)
- [Java](./java/README.md)
- [Node.js (JavaScript)](./node.js/README.md)
- [PowerShell](./powershell/README.md)
- [Python](./python/README.md)
- [Rust](./rust/README.md)

## Suggested prompts

The following prompts can be used to demonstrates different aspect of Azure OpenAI chat completion.

- Demonstrate the use of the `system` message by using the following prompts:
    - `Who are you?`
    - `What can you do?`

- Demonstrate conversation state by using the following prompts in sequence:
    - `Who was the first emperor?`
    - `Who followed him?`

- Demonstrate optional counting by using the following prompt:
    - `Who were the five great emperors?`

- Demonstrate the `max_token` parameter by reducing it from `1500` to `150` and re-run the above prompt. The answer will exceen the value of `max_token` and will be truncated.

- Demonstrate the ability of OpenAI to understand different languages:
    - `What does your name mean?`
    - `Quis fuit primus Romanorum imperator?` ('Who was the first Roman Emperor' in Latin)

- To get a answer in Latin, try:
    - `Quis es tu?` (Who are you?)

- Finally, type `exit` or `quit` to terminal the demo. `CTRL+C` works as well.