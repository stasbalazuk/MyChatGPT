program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  OpenAI.API.Params in 'OpenAI.API.Params.pas',
  OpenAI.API in 'OpenAI.API.pas',
  OpenAI.Completions in 'OpenAI.Completions.pas',
  OpenAI.Edits in 'OpenAI.Edits.pas',
  OpenAI.Embeddings in 'OpenAI.Embeddings.pas',
  OpenAI.Engines in 'OpenAI.Engines.pas',
  OpenAI.Errors in 'OpenAI.Errors.pas',
  OpenAI.Files in 'OpenAI.Files.pas',
  OpenAI.FineTunes in 'OpenAI.FineTunes.pas',
  OpenAI.Images in 'OpenAI.Images.pas',
  OpenAI.Models in 'OpenAI.Models.pas',
  OpenAI.Moderations in 'OpenAI.Moderations.pas',
  OpenAI in 'OpenAI.pas',
  ChatGPT.FrameChat in 'ChatGPT.FrameChat.pas' {FrameChat: TFrame},
  ChatGPT.FrameMessage in 'ChatGPT.FrameMessage.pas' {FrameMessage: TFrame},
  ChatGPT.Translate in 'ChatGPT.Translate.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
