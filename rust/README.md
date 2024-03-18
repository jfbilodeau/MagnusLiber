# Rust Azure OpenAI demo

## Quick Start

Using Bash:
```bash
cd rust
export OPENAI_URL="https://<myresource>.openai.azure.com/"
export OPENAI_KEY="XXXXXXXXXXXXXXXXX"
export OPENAI_DEPLOYMENT="<mydeployment>"
cargo run
```
(Setup the environment variables as appropriate)

Note: There is a crate for OpenAI ChatGPT, but it does not support Azure OpenAI.