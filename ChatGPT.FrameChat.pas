﻿unit ChatGPT.FrameChat;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Memo.Types, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, OpenAI, OpenAI.Completions, ChatGPT.FrameMessage,
  System.Threading, FMX.Edit, FMX.ImgList, FMX.Platform, FMX.MediaLibrary;

const
  MicrosoftTranslatorTranslateUri =
    'http://api.microsofttranslator.com/v2/Http.svc/Translate?appId=%s&text=%s&from=%s&to=%s';
  MicrosoftTranslatorDetectUri =
    'http://api.microsofttranslator.com/v2/Http.svc/Detect?appId=%s&text=%s';
  MicrosoftTranslatorGetLngUri =
    'http://api.microsofttranslator.com/v2/Http.svc/GetLanguagesForTranslate?appId=%s';
  MicrosoftTranslatorGetSpkUri =
    'http://api.microsofttranslator.com/v2/Http.svc/GetLanguagesForSpeak?appId=%s';
  MicrosoftTranslatorSpeakUri =
    'http://api.microsofttranslator.com/v2/Http.svc/Speak?appId=%s&text=%s&language=%s';
  BingAppId = '73C8F474CA4D1202AD60747126813B731199ECEA';
  Msxml2_DOMDocument = 'Msxml2.DOMDocument.6.0';

type
  TGoogleLanguages = (Autodetect, Afrikaans, Albanian, Arabic, Basque,
    Belarusian, Bulgarian, Catalan, Chinese, Chinese_Traditional, Croatian,
    Czech, Danish, Dutch, English, Estonian, Filipino, Finnish, French,
    Galician, German, Greek, Haitian_Creole, Hebrew, Hindi, Hungarian,
    Icelandic, Indonesian, Irish, Italian, Japanese, Latvian, Lithuanian,
    Macedonian, Malay, Maltese, Norwegian, Persian, Polish, Portuguese,
    Romanian, Russian, Serbian, Slovak, Slovenian, Spanish, Swahili, Swedish,
    Thai, Turkish, Ukrainian, Vietnamese, Welsh, Yiddish);

const
  GoogleLanguagesArr: array [TGoogleLanguages] of string = ('Autodetect', 'af',
    'sq', 'ar', 'eu', 'be', 'bg', 'ca', 'zh-CN', 'zh-TW', 'hr', 'cs', 'da',
    'nl', 'en', 'et', 'tl', 'fi', 'fr', 'gl', 'de', 'el', 'ht', 'iw', 'hi',
    'hu', 'is', 'id', 'ga', 'it', 'ja', 'lv', 'lt', 'mk', 'ms', 'mt', 'no',
    'fa', 'pl', 'pt', 'ro', 'ru', 'sr', 'sk', 'sl', 'es', 'sw', 'sv', 'th',
    'tr', 'uk', 'vi', 'cy', 'yi');

type
  TWindowMode = (wmCompact, wmFull);

  TButton = class(FMX.StdCtrls.TButton)
  public
    procedure SetBounds(X, Y, AWidth, AHeight: Single); override;
  end;

  TLabel = class(FMX.StdCtrls.TLabel)
  public
    procedure SetBounds(X, Y, AWidth, AHeight: Single); override;
  end;

  TFrameChat = class(TFrame)
    VertScrollBoxChat: TVertScrollBox;
    LayoutSend: TLayout;
    RectangleSendBG: TRectangle;
    MemoQuery: TMemo;
    LayoutQuery: TLayout;
    Rectangle2: TRectangle;
    Layout1: TLayout;
    ButtonSend: TButton;
    Path1: TPath;
    LayoutTyping: TLayout;
    TimerTyping: TTimer;
    LayoutTypingContent: TLayout;
    Layout3: TLayout;
    RectangleBot: TRectangle;
    Path3: TPath;
    Layout4: TLayout;
    RectangleIndicate: TRectangle;
    LabelTyping: TLabel;
    LineBorder: TLine;
    LayoutTranslate: TLayout;
    ButtonTranslate: TButton;
    Path2: TPath;
    LayoutTranslateSet: TLayout;
    EditLangSrc: TEdit;
    ClearEditButton1: TClearEditButton;
    Path4: TPath;
    Label1: TLabel;
    Rectangle3: TRectangle;
    LayoutWelcome: TLayout;
    RectangleBG: TRectangle;
    Label11: TLabel;
    FlowLayoutWelcome: TFlowLayout;
    LayoutExampleTitle: TLayout;
    Label2: TLabel;
    Path6: TPath;
    ButtonExample3: TButton;
    ButtonExample2: TButton;
    ButtonExample1: TButton;
    LayoutCapabilitiesTitle: TLayout;
    Label3: TLabel;
    Path5: TPath;
    Label5: TLabel;
    Label6: TLabel;
    Label9: TLabel;
    LayoutLimitationsTitle: TLayout;
    Label4: TLabel;
    Path7: TPath;
    Label8: TLabel;
    Label7: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    procedure LayoutSendResize(Sender: TObject);
    procedure MemoQueryChange(Sender: TObject);
    procedure ButtonSendClick(Sender: TObject);
    procedure TimerTypingTimer(Sender: TObject);
    procedure LayoutTypingResize(Sender: TObject);
    procedure MemoQueryKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure ButtonTranslateClick(Sender: TObject);
    procedure EditLangSrcChangeTracking(Sender: TObject);
    procedure LayoutWelcomeResize(Sender: TObject);
    procedure FlowLayoutWelcomeResize(Sender: TObject);
    procedure ButtonExample1Click(Sender: TObject);
    procedure ButtonExample2Click(Sender: TObject);
    procedure ButtonExample3Click(Sender: TObject);
    procedure MemoQueryResize(Sender: TObject);
    procedure EditLangSrcKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
  private
    FAPI: IOpenAI;
    FChatId: string;
    FPool: TThreadPool;
    FTitle: string;
    FMode: TWindowMode;
    FLangSrc: string;
    FIsTyping: Boolean;
    FBuffer: TStringList;
    function NewMessage(const Text: string; IsUser: Boolean): TFrameMessage;
    procedure ClearChat;
    procedure SetTyping(const Value: Boolean);
    procedure SetAPI(const Value: IOpenAI);
    procedure SetChatId(const Value: string);
    procedure ShowError(const Text: string);
    procedure AppendMessages(Response: TCompletions);
    procedure ScrollDown;
    procedure SetTitle(const Value: string);
    procedure SetMode(const Value: TWindowMode);
    function ProcText(const Text: string; FromUser: Boolean): string;
    procedure SetLangSrc(const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property API: IOpenAI read FAPI write SetAPI;
    property ChatId: string read FChatId write SetChatId;
    property Title: string read FTitle write SetTitle;
    property Mode: TWindowMode read FMode write SetMode;
    property LangSrc: string read FLangSrc write SetLangSrc;
  end;

const
  MAX_TOKENS = 1024;
  MODEL_TOKENS_LIMIT = 4096;

implementation

uses
  FMX.Ani, System.Math, OpenAI.API, ChatGPT.Translate;
{$R *.fmx}

procedure TFrameChat.ShowError(const Text: string);
begin
  try
    TThread.Queue(nil,
      procedure
      begin
        var
        Frame := NewMessage(Text, False);
        Frame.IsError := True;
      end);
  except
    Exit;
  end;
end;

procedure TFrameChat.AppendMessages(Response: TCompletions);
begin
  try
    try
      for var Item in Response.Choices do
        NewMessage(Item.Text, False);
    finally
      Response.Free;
    end;
  except
    Exit;
  end;
end;

procedure ShareTextWith(const aText: string);
var
  vSharingService: IFMXShareSheetActionsService;
begin
  try
    TPlatformServices.Current.SupportsPlatformService
      (IFMXShareSheetActionsService, vSharingService);
    vSharingService.Share(nil, aText, nil);
  except
    Exit;
  end;
end;

procedure TFrameChat.ScrollDown;
begin
  VertScrollBoxChat.ViewportPosition :=
    TPointF.Create(0, VertScrollBoxChat.ContentBounds.Height);
end;

procedure TFrameChat.ButtonExample1Click(Sender: TObject);
begin
  MemoQuery.Text := 'Explain quantum computing in simple terms';
end;

procedure TFrameChat.ButtonExample2Click(Sender: TObject);
begin
  MemoQuery.Text := 'Got any creative ideas for a 10 year old’s birthday?';
end;

procedure TFrameChat.ButtonExample3Click(Sender: TObject);
begin
  MemoQuery.Text := 'How do I make an HTTP request in Javascript?';
end;

procedure TFrameChat.ButtonSendClick(Sender: TObject);
begin
  try
    if FIsTyping then
      Exit;
    var
    Prompt := MemoQuery.Text;
    if Prompt.IsEmpty then
      Exit;
    MemoQuery.Text := '';
    NewMessage(Prompt, True);
    SetTyping(True);
    ScrollDown;
    TTask.Run(
      procedure
      begin
        try
          var
          Completions := API.Completion.Create(
            procedure(Params: TCompletionParams)
            begin
              Params.Prompt(ProcText(FBuffer.Text, True));
              Params.MaxTokens(MAX_TOKENS);
              Params.Temperature(0.5);
              Params.User(FChatId);
            end);
          if not LangSrc.IsEmpty then
            for var Item in Completions.Choices do
              Item.Text := ProcText(Item.Text, False);
          TThread.Queue(nil,
            procedure
            begin
              AppendMessages(Completions);
            end);
        except
          on E: OpenAIException do
            ShowError(E.Message);
          on E: Exception do
            ShowError('Error: ' + E.Message);
        end;
        TThread.Queue(nil,
          procedure
          begin
            SetTyping(False);
          end);
      end, FPool);
  except
    Exit;
  end;
end;

procedure TFrameChat.ButtonTranslateClick(Sender: TObject);
begin
  if LayoutTranslateSet.Position.Y >= 0 then
  begin
    LayoutTranslateSet.Opacity := 0;
    TAnimator.AnimateFloat(LayoutTranslateSet, 'Position.Y', -70);
    TAnimator.AnimateFloat(LayoutTranslateSet, 'Opacity', 1, 0.4);
  end
  else
  begin
    LayoutTranslateSet.Opacity := 1;
    TAnimator.AnimateFloat(LayoutTranslateSet, 'Position.Y', 0);
    TAnimator.AnimateFloat(LayoutTranslateSet, 'Opacity', 0, 0.1);
  end;
end;

procedure TFrameChat.ClearChat;
begin
  try
    LayoutTyping.Parent := nil;
    LayoutWelcome.Parent := nil;
    while VertScrollBoxChat.Content.ControlsCount > 0 do
      VertScrollBoxChat.Content.Controls[0].Free;
    LayoutTyping.Parent := VertScrollBoxChat;
    LayoutWelcome.Parent := VertScrollBoxChat;
  except
    Exit;
  end;
end;

constructor TFrameChat.Create(AOwner: TComponent);
begin
  try
    inherited;
    FBuffer := TStringList.Create;
    FPool := TThreadPool.Create;
    LangSrc := '';
    Name := '';
    LayoutTranslateSet.Opacity := 0;
    LayoutTranslateSet.Position.Y := 0;
    VertScrollBoxChat.AniCalculations.Animation := True;
    SetTyping(False);
    ClearChat;
  except
    Exit;
  end;
end;

destructor TFrameChat.Destroy;
begin
  try
    FPool.Free;
    FBuffer.Free;
    inherited;
  except
    Exit;
  end;
end;

procedure TFrameChat.EditLangSrcChangeTracking(Sender: TObject);
begin
  LangSrc := EditLangSrc.Text;
end;

procedure TFrameChat.EditLangSrcKeyDown(Sender: TObject; var Key: Word;
var KeyChar: Char; Shift: TShiftState);
begin
  try
    if (Key = vkReturn) and not(ssCtrl in Shift) then
    begin
      Key := 0;
      KeyChar := #0;
      if Length(LangSrc) > 0 then MemoQuery.Text := ProcText(LangSrc, False);
    end;
  except
    Exit;
  end;
end;

procedure TFrameChat.FlowLayoutWelcomeResize(Sender: TObject);
begin
  try
    var
      W: Single := 0;
      case Mode of wmCompact: W := FlowLayoutWelcome.Width;
      wmFull: W := Trunc(FlowLayoutWelcome.Width /
        FlowLayoutWelcome.ControlsCount);
  end;
  for var Control in FlowLayoutWelcome.Controls do
    Control.Width := W;
  var
    B: Single := 0;
  for var Control in LayoutExampleTitle.Controls do
    B := Max(B, Control.Position.Y + Control.Height + Control.Margins.Bottom);
  if LayoutExampleTitle.Height <> B then
    LayoutExampleTitle.Height := B;
  B := 0;
  for var Control in LayoutCapabilitiesTitle.Controls do
    B := Max(B, Control.Position.Y + Control.Height + Control.Margins.Bottom);
  if LayoutCapabilitiesTitle.Height <> B then
    LayoutCapabilitiesTitle.Height := B;
  B := 0;
  for var Control in LayoutLimitationsTitle.Controls do
    B := Max(B, Control.Position.Y + Control.Height + Control.Margins.Bottom);
  if LayoutLimitationsTitle.Height <> B then
    LayoutLimitationsTitle.Height := B;
  B := 0;
  for var Control in FlowLayoutWelcome.Controls do
    B := Max(B, Control.Position.Y + Control.Height);
  B := B + FlowLayoutWelcome.Position.Y;
  if LayoutWelcome.Height <> B then
    LayoutWelcome.Height := B;
except
  Exit;
end;
end;

procedure TFrameChat.LayoutSendResize(Sender: TObject);
begin
  LayoutQuery.Width := Min(768, LayoutSend.Width - 48);
  VertScrollBoxChat.Padding.Bottom := LayoutSend.Height;
end;

procedure TFrameChat.LayoutTypingResize(Sender: TObject);
begin
  LayoutTypingContent.Width :=
    Min(LayoutTyping.Width - (LayoutTyping.Padding.Left +
    LayoutTyping.Padding.Right), 650);
end;

procedure TFrameChat.LayoutWelcomeResize(Sender: TObject);
begin
  FlowLayoutWelcome.Width := Min(720, LayoutWelcome.Width);
end;

procedure TFrameChat.MemoQueryChange(Sender: TObject);
begin
  try
    var
      H: Single := LayoutSend.Padding.Top + LayoutSend.Padding.Bottom +
        MemoQuery.ContentBounds.Height + LayoutQuery.Padding.Top +
        LayoutQuery.Padding.Bottom;
    LayoutSend.Height := Max(LayoutSend.TagFloat, Min(H, 400));
  except
    Exit;
  end;
end;

procedure TFrameChat.MemoQueryKeyDown(Sender: TObject; var Key: Word;
var KeyChar: Char; Shift: TShiftState);
begin
  try
    if (Key = vkReturn) and not(ssCtrl in Shift) then
    begin
      Key := 0;
      KeyChar := #0;
      ButtonSendClick(nil);
    end;
  except
    Exit;
  end;
end;

procedure TFrameChat.MemoQueryResize(Sender: TObject);
begin
  try
    MemoQueryChange(Sender);
  except
    Exit;
  end;
end;

function TFrameChat.NewMessage(const Text: string; IsUser: Boolean)
  : TFrameMessage;
begin
  try
    FBuffer.Add(Text);
    if FBuffer.Text.Length + MAX_TOKENS > MODEL_TOKENS_LIMIT then
      FBuffer.Text := FBuffer.Text.Remove(0, FBuffer.Text.Length -
        (MODEL_TOKENS_LIMIT - MAX_TOKENS));
    LayoutWelcome.Visible := False;
    Result := TFrameMessage.Create(VertScrollBoxChat);
    Result.Position.Y := VertScrollBoxChat.ContentBounds.Height;
    Result.Parent := VertScrollBoxChat;
    Result.Align := TAlignLayout.MostTop;
    Result.Text := Text;
    Result.IsUser := IsUser;
  except
    Result := TFrameMessage.Create(VertScrollBoxChat);
    Result.Position.Y := VertScrollBoxChat.ContentBounds.Height;
    Result.Parent := VertScrollBoxChat;
    Result.Align := TAlignLayout.MostTop;
    Result.Text := Text;
    Result.IsUser := IsUser;
    Exit;
  end;
end;

function TFrameChat.ProcText(const Text: string; FromUser: Boolean): string;
begin
  try
    if LangSrc.IsEmpty then
      Exit(Text);
    var
    Translate := '';
    if FromUser then
      Translate := TranslateGoogle(Text, LangSrc, 'en')
    else
      Translate := TranslateGoogle(Text, 'en', LangSrc);
    if Translate.IsEmpty then
      Result := Text
    else
      Result := Translate;
  except
    Exit;
  end;
end;

procedure TFrameChat.SetAPI(const Value: IOpenAI);
begin
  FAPI := Value;
end;

procedure TFrameChat.SetChatId(const Value: string);
begin
  FChatId := Value;
end;

procedure TFrameChat.SetLangSrc(const Value: string);
begin
  FLangSrc := Value;
end;

procedure TFrameChat.SetMode(const Value: TWindowMode);
begin
  try
    FMode := Value;
    case FMode of
      wmCompact:
        begin
          LayoutSend.TagFloat := 100;
          VertScrollBoxChat.Padding.Bottom := 100;
          LayoutSend.Height := 100;
          LineBorder.Visible := True;
          LayoutSend.Padding.Rect := TRectF.Create(0, 10, 0, 40);
          RectangleSendBG.Fill.Kind := TBrushKind.Solid;
          RectangleSendBG.Fill.Color := $FF343541;
          LayoutTranslateSet.Width := LayoutQuery.Width;
        end;
      wmFull:
        begin
          LayoutSend.TagFloat := 170;
          VertScrollBoxChat.Padding.Bottom := 170;
          LayoutSend.Height := 170;
          LineBorder.Visible := False;
          LayoutSend.Padding.Rect := TRectF.Create(0, 80, 0, 40);
          RectangleSendBG.Fill.Kind := TBrushKind.Gradient;
          LayoutTranslateSet.Width := 153;
        end;
    end;
    FlowLayoutWelcomeResize(nil);
  except
    Exit;
  end;
end;

procedure TFrameChat.SetTitle(const Value: string);
begin
  FTitle := Value;
end;

procedure TFrameChat.SetTyping(const Value: Boolean);
begin
  FIsTyping := Value;
  ButtonSend.Enabled := not Value;
  TimerTyping.Enabled := Value;
  LayoutTyping.Visible := Value;
  LabelTyping.Visible := Value;
end;

procedure TFrameChat.TimerTypingTimer(Sender: TObject);
begin
  try
    RectangleIndicate.Visible := not RectangleIndicate.Visible;
    if LabelTyping.Text.Length > 2 then
      LabelTyping.Text := '.'
    else
      LabelTyping.Text := LabelTyping.Text + '.';
  except
    Exit;
  end;
end;

{ TButton }
procedure TButton.SetBounds(X, Y, AWidth, AHeight: Single);
begin
  try
    inherited;
    if Assigned(Canvas) and (Tag = 1) then
    begin
      var
      H := TRectF.Create(0, 0, Width - 20, 10000);
      Canvas.Font.Size := Font.Size;
      Canvas.MeasureText(H, Text, WordWrap, [], TextAlign, VertTextAlign);
      if AHeight <> H.Height + 24 then
        Height := H.Height + 24;
    end;
  except
    Exit;
  end;
end;

{ TLabel }
procedure TLabel.SetBounds(X, Y, AWidth, AHeight: Single);
begin
  try
    inherited;
    if Assigned(Canvas) and (Tag = 1) then
    begin
      var
      H := TRectF.Create(0, 0, Width - 20, 10000);
      Canvas.Font.Size := Font.Size;
      Canvas.MeasureText(H, Text, WordWrap, [], TextAlign, VertTextAlign);
      if AHeight <> H.Height + 24 then
        Height := H.Height + 24;
    end;
  except
    Exit;
  end;
end;

end.
