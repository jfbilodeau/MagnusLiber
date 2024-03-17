program MagnusLiber;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.SysUtils;

type
  TConfiguration = record
    OpenAiUri: string;
    OpenAiKey: string;
    Deployment: string;

    HistoryLength: Integer;
    MaxTokens: Integer;
  end;

  TUiMessages = record
    Greeting: string;
    Prompt: string;
    EmptyPrompt: string;
    ExitMessage: string;
  end;

  // Since there is not an Azure OpenAI SDK for Delphi, we will re-create
  // the basic functionality here.
const
  RoleSystem    = 'system';
  RoleUser      = 'user';
  RoleAssistant = 'assistant';

type
  TChatMessage = record
    Role: string;
    Content: string;
  end;

  TChatRequest = record
    Messages: array of TChatMessage;
    n: Integer;
    MaxTokens: Integer;

    // These fields are not necessary for the demo
    Temperature: Single;
    TopP: Single;
    PresentPenalty: Single;
    FrequencyPenalty: Single;
  end;

begin
  try
    // Load configuration
    var configurationFileName := '../MagnusLiber.dev.json';

    if not TFile.Exists(configurationFileName) then
      configurationFileName := '../MagusLiber.json';

    var configurationText := TFile.ReadAllText(configurationFileName);

    var configurationJson := TJSONObject.ParseJSONValue(configurationText);

    var configuration: TConfiguration;

    configuration.OpenAiUri := configurationJson.GetValue<string>('openAiUri');
    configuration.OpenAiKey := configurationJson.GetValue<string>('openAiKey');
    configuration.Deployment := configurationJson.GetValue<string>('deployment');
    configuration.HistoryLength := configurationJson.GetValue<Integer>('historyLength');
    configuration.MaxTokens := configurationJson.GetValue<Integer>('maxTokens');

    // Load UI messages
    var uiMessagesJson := TJSONObject.ParseJSONValue(TFile.ReadAllText('../Messages.json'));

    var uiMessages: TUiMessages;

    uiMessages.Greeting := uiMessagesJson.GetValue<string>('greeting');
    uiMessages.Prompt := uiMessagesJson.GetValue<string>('prompt');
    uiMessages.EmptyPrompt := uiMessagesJson.GetValue<string>('emptyPrompt');
    uiMessages.ExitMessage := uiMessagesJson.GetValue<string>('exit');

    // Load system message
    var systemMessageText := TFile.ReadAllText('../SystemMessage.txt');
    var systemMessage: TChatMessage;
    systemMessage.Role := RoleSystem;
    systemMessage.Content := systemMessageText;
    
    // Message history
    var history := TList<TChatMessage>.Create();

    // Base URL
    var URL := Format(
      '%s/openai/deployments/%s/chat/completions?api-version=2023-05-15',
      [
        configuration.OpenAiUri,
        configuration.Deployment
      ]
    );

    // Greet user
    Writeln(uiMessages.Greeting);

    // Start main loop
    var running := True;

    while running do
    begin

      // Prompt user
      WriteLn(uiMessages.Prompt);

      var input: string;
      ReadLn(input);

      input := input.Trim;

      if input = '' then
        WriteLn(uiMessages.EmptyPrompt)
      else if (input = 'exit') or (input = 'quit') then
        running := False
      else begin
        // Prepare conversation.
        var userMessage: TChatMessage;
        userMessage.Role := RoleUser;
        userMessage.Content := input;    

        var messages := TList<TChatMessage>.Create;
        messages.Add(systemMessage);
        messages.AddRange(history);
        messages.Add(userMessage);  

        // Convert conversation to JSON array.
        var messagesJson := TJSONArray.Create;

        for var conversationMessage in messages do begin
          var messageObject := TJSONObject.Create;
          messageObject.AddPair('role', conversationMessage.Role);
          messageObject.AddPair('content', conversationMessage.Content);

          messagesJson.Add(messageObject);
        end;

        // Prepare HTTP request
        var requestJson := TJSONObject.Create;
        requestJson.AddPair('messages', messagesJson);
        requestJson.AddPair('n', 1); // Request one response (choice)
        requestJson.AddPair('max_tokens', configuration.MaxTokens);

        // The following settings are not necessary and included for demonstration purpose only.
        requestJson.AddPair('temperature', 0.7);
        requestJson.AddPair('top_p', 0.95);
        requestJson.AddPair('presence_penalty', 0.0);
        requestJson.AddPair('frequency_penalty', 0.0);

        // Create stream for request body
        var requestBodyStream := TStringStream.Create(requestJson.ToString);

        // Prepare headers.
        var headers: Tarray<TNameValuePair> := [
          TNameValuePair.Create('api-key', configuration.OpenAiKey)
        ];
          
        // Create base HTTP request
        var httpClient := THTTPClient.Create;
        var response := httpClient.Post(URL, requestBodyStream, nil, headers);

        var responseText := response.ContentAsString(TEncoding.UTF8);

        if response.StatusCode <> 200 then
          raise Exception.Create('Could not send HTTP request to Azure OpenAI. Reason: ' + responseText);

        // Extract response JSON
        var responseJSON := TJSONObject.ParseJSONValue(responseText);

        // Extrat assistant message
        var assistantMessage: TChatMessage;
        assistantMessage.Role := RoleAssistant;
        assistantMessage.Content := responseJSON.FindValue('choices[0].message.content').GetValue<string>;

        // Display response.
        WriteLn(assistantMessage.Content);
        WriteLn; // Add blank line

        // Add user message and assistant message to conversation history
        history.Add(userMessage);
        history.Add(assistantMessage);

        // Trim history
        if history.Count > configuration.HistoryLength then
          history.DeleteRange(0, 2);

        // Free objects
        httpClient.Free;
        requestJson.Free;
        responseJSON.Free;
        requestBodyStream.Free;
      end;
    
    end;

    WriteLn(uiMessages.ExitMessage);
    
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
