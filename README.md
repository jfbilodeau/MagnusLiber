# Magnus Liber Imperatorum
# A set of Azure OpenAI demos

Welcome to **Magnus Liber Imperatorum**, a set of Azure OpenAI demos written in different programming languages. The goal of the demos is to illustrate basic use of the [OpenAI chat completion API](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference#chat-completions), including request parameters, response and conversation management.

## Getting started

To run Magnus Liber in any programming language, an Azure Subscription and an Azure OpenAI deployment will be necessary.

1. If necessary, get a [free Azure subscription](https://azure.microsoft.com/en-ca/free).
2. Create an [Azure OpenAI service resource](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource).
3. Deploy either an [OpenAI `gpt-4` or `gpt-3-turbo` model](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/provisioned-get-started).
4. Run `git clone https://github.com/jfbilodeau/MagnusLiber.git`
5. Run `cd MagnusLiber`
6. Edit `MagnusLiber.json` with your Azure OpenAI configuration
    - Note: To avoid accidently committing keys to git, consider copying `MagnusLiber.json` to `MagnusLiber.dev.json` and configuring the later. The file `MagnusLiber.dev.json` will not be included in a `git commit`.
7. Change directory in the demo you would like to execute and run it.
    - For example:
    ```sh
    cd powershell
    ./MagnusLiber.ps1
    ```

## Design Goal

- Consistent functionality across demos
- Share resources files:
    - Configuration file (`./MagnusLiber.json`)
    - UI Messages (`./Messages.json`)
    - System message (`./SystemMessage.txt`)
- Idiomatic code
- Minimize local dependencies
- Favour Azure OpenAI SDK when available
- For simplicity, written as one function
- For simplicity, there is very little error handling


## Programming Languages demos
- [C++](./cpp/README.md)
- [C# (Console)](./csharp-console/README.md)
- [Go](./go/README.md)
- [Java](./java/README.md)
- [Node.js (JavaScript)](./node.js/README.md)
- [PowerShell](./powershell/README.md)
- [Python](./python/README.md)
- [Rust](./rust/README.md)

## Suggested prompts
`Who was the first emperor?`
followed by
`Who followed him?`
to demonstrate converstion state

`Who were the five great emperors?`

`Who are you?`
`What can you do?`
`What does your name mean?`

Demonstrate support for multiple languages:
`Quis fuit primus Romanorum imperator?` ('Who was the first Roman Emperor' in Latin)

To get a answer in Latin, try:
`Quis es tu?` (Who are you?)