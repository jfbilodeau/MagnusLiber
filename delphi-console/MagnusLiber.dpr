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
    // Load configuration from environment variables
    var openAiUrl := GetEnvironmentVariable('OPENAI_URL');
    var openAiKey := GetEnvironmentVariable('OPENAI_KEY');
    var deployment := GetEnvironmentVariable('OPENAI_DEPLOYMENT');

    if (openAiUrl = '') or (openAiKey = '') or (deployment = '') then
      raise Exception.Create('Please set OPENAI_URL, OPENAI_KEY, and OPENAI_DEPLOYMENT environment variables.');

    var HistoryLength := 10;
    var MaxTokens := 150;

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
        openAiUrl,
        deployment
      ]
    );

    // Greet user
    Writeln('Salve, seeker of wisdom. What would you like to know about our glorious Roman and Byzantine leaders?');

    // Start main loop
    var running := True;

    while running do
    begin

      // Prompt user
      WriteLn('Quaeris quid (What is your question)?');

      var input: string;
      ReadLn(input);

      input := input.Trim;

      if input = '' then
        WriteLn('Me paenitet, non audivi te. (I''m sorry, I didn''t hear you)')
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
        requestJson.AddPair('max_tokens', maxTokens);

        // The following settings are not necessary and included for demonstration purpose only.
        requestJson.AddPair('temperature', 0.7);
        requestJson.AddPair('top_p', 0.95);
        requestJson.AddPair('presence_penalty', 0.0);
        requestJson.AddPair('frequency_penalty', 0.0);

        // Create stream for request body
        var requestBodyStream := TStringStream.Create(requestJson.ToString);

        // Prepare headers.
        var headers: Tarray<TNameValuePair> := [
          TNameValuePair.Create('api-key', openAiKey)
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
        if history.Count > historyLength then
          history.DeleteRange(0, 2);  // Remove 2: user and assistant messages

        // Free objects
        httpClient.Free;
        requestJson.Free;
        responseJSON.Free;
        requestBodyStream.Free;
      end;
    
    end;

    WriteLn('Vale et gratias tibi ago for using Magnus Liber Imperatorum.');
    
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
