package com.jfbilodeau.magnusliber;

// Application configuration class
public class Configuration {
    private String openAiUri;
    private String openAiKey;
    private String deployment;
    private int historyLength;
    private int maxTokens;

    public String getOpenAiUri() {
        return openAiUri;
    }

    public void setOpenAiUri(String openAiUri) {
        this.openAiUri = openAiUri;
    }

    public String getOpenAiKey() {
        return openAiKey;
    }

    public void setOpenAiKey(String openAiKey) {
        this.openAiKey = openAiKey;
    }

    public String getDeployment() {
        return deployment;
    }

    public void setDeployment(String deployment) {
        this.deployment = deployment;
    }

    public int getHistoryLength() {
        return historyLength;
    }

    public void setHistoryLength(int historyLength) {
        this.historyLength = historyLength;
    }

    public int getMaxTokens() {
        return maxTokens;
    }

    public void setMaxTokens(int maxTokens) {
        this.maxTokens = maxTokens;
    }
}
