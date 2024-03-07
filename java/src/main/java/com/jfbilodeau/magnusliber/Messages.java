package com.jfbilodeau.magnusliber;

// Messages class
public class Messages {
    String greeting = "Greeting not set";
    String prompt = "Prompt not set";
    String emptyInput = "EmptyPrompt not set";
    String exit = "ExitMessage not set";

    public String getGreeting() {
        return greeting;
    }

    public void setGreeting(String greeting) {
        this.greeting = greeting;
    }

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public String getEmptyInput() {
        return emptyInput;
    }

    public void setEmptyInput(String emptyInput) {
        this.emptyInput = emptyInput;
    }

    public String getExit() {
        return exit;
    }

    public void setExit(String exit) {
        this.exit = exit;
    }
}
