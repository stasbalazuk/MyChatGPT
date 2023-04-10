unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, OpenAI,
  FMX.Objects, FMX.Layouts, FMX.ListBox, FMX.Controls.Presentation,
  FMX.StdCtrls, System.ImageList, FMX.ImgList, FMX.SVGIconImageList, ChatGPT.FrameChat,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Effects, FMX.Filter.Effects,
  FMX.Ani, System.Math, System.Permissions,
  Androidapi.JNI.Java.Security, Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes, Androidapi.JNIBridge,
  FMX.Edit, DCPblockciphers, DCPrijndael, DCPsha256;

const
  AniInterpolation = TInterpolationType.Quadratic;
  RSA_KEY = 'MIIBI...';
  API_TOKEN = 'sk-pI...';
  URL_API_KEY = 'https://platform.openai.com/account/api-keys';

type
  TForm1 = class(TForm)
    LayoutChats: TLayout;
    Rectangle1: TRectangle;
    LayoutHead: TLayout;
    ButtonMenu: TButton;
    ButtonNewChatCompact: TButton;
    LabelChatName: TLabel;
    LayoutChatsBox: TLayout;
    StyleBook: TStyleBook;
    LayoutMenuContent: TLayout;
    RectangleMenuBG: TRectangle;
    LayoutMenuContainer: TLayout;
    RectangleMenu: TRectangle;
    LayoutMenu: TLayout;
    ButtonNewChat: TButton;
    ListBoxChatList: TListBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    Line1: TLine;
    ButtonUseKey: TButton;
    ButtonDiscord: TButton;
    Layout1: TLayout;
    ButtonCloseMenu: TButton;
    SVGIconImageList: TSVGIconImageList;
    ButtonClear: TButton;
    Layout3: TLayout;
    ButtonClearConfirm: TButton;
    ButtonClearCancel: TButton;
    ButtonGenApiKey: TButton;
    procedure ButtonGenApiKeyClick(Sender: TObject);
    procedure ShowClearConfirm;
    procedure FormResize(Sender: TObject);
    procedure FormConstrainedResize(Sender: TObject;
      var MinWidth, MinHeight, MaxWidth, MaxHeight: Single);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure ButtonNewChatClick(Sender: TObject);
    procedure ButtonCloseMenuClick(Sender: TObject);
    procedure ButtonNewChatCompactClick(Sender: TObject);
    procedure ButtonClearCancelClick(Sender: TObject);
    procedure ButtonClearConfirmClick(Sender: TObject);
    procedure ButtonMenuClick(Sender: TObject);
    procedure RectangleMenuBGClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonUseKeyClick(Sender: TObject);
  private
    { Private declarations }
    FOpenAI: TOpenAIComponent;
    FMode: TWindowMode;
    FChatIdCount: Integer;
    procedure Clear;
    procedure UpdateMode;
    function NextChatId: Integer;
    function CreateChat: string;
    procedure CloseMenu;
    procedure SelectChat(const ChatId: string);
    procedure SetMode(const Value: TWindowMode);
    procedure HideClearConfirm;
    procedure FOnChatItemClick(Sender: TObject);
{$HINTS OFF}
    procedure FOnChatItemTap(Sender: TObject; const Point: TPointF);
{$HINTS ON}
  public
    { Public declarations }
    property OpenAI: TOpenAIComponent read FOpenAI;
    constructor Create(AOwner: TComponent); override;
    property Mode: TWindowMode read FMode write SetMode;
  end;

var
  Form1: TForm1;
  Frame: TFrameChat;
  SettingsFilePath: string;

implementation

{$R *.fmx}

uses modURL, System.IOUtils, System.JSON, System.NetEncoding,
             Prism.Crypto.AES, System.Hash, FMX.DialogService, IniFiles;

function TForm1.NextChatId: Integer;
begin
  try
    Inc(FChatIdCount);
    Result := FChatIdCount;
  except
    Result := FChatIdCount;
    Exit;
  end;
end;

function EncryptString(Source, Password: string): RawByteString;
var
  DCP_rijndael1: TDCP_rijndael;
  PasswordBytes,SourceBytes: TBytes;
  PasswordRaw,SourceRaw: RawByteString;
begin
  DCP_rijndael1 := TDCP_rijndael.Create(nil);    // создаём объект
  PasswordBytes := TEncoding.UTF8.GetBytes(Password);
  SetString(PasswordRaw, PAnsiChar(PasswordBytes), Length(PasswordBytes));
  DCP_rijndael1.InitStr(PasswordRaw, TDCP_sha256);  // инициализируем
  SourceBytes := TEncoding.UTF8.GetBytes(Source);
  SetString(SourceRaw, PAnsiChar(SourceBytes), Length(SourceBytes));
  Result := DCP_rijndael1.EncryptString(SourceRaw); // шифруем
  DCP_rijndael1.Burn;                            // стираем инфо о ключе
  DCP_rijndael1.Free;                            // уничтожаем объект
end;

function DecryptString(Source, Password: string): RawByteString;
var
  DCP_rijndael1: TDCP_rijndael;
  PasswordBytes,SourceBytes: TBytes;
  PasswordRaw,SourceRaw: RawByteString;
begin
  DCP_rijndael1 := TDCP_rijndael.Create(nil);    // создаём объект
  PasswordBytes := TEncoding.UTF8.GetBytes(Password);
  SetString(PasswordRaw, PAnsiChar(PasswordBytes), Length(PasswordBytes));
  DCP_rijndael1.InitStr(PasswordRaw, TDCP_sha256);  // инициализируем
  SourceBytes := TEncoding.UTF8.GetBytes(Source);
  SetString(SourceRaw, PAnsiChar(SourceBytes), Length(SourceBytes));
  Result := DCP_rijndael1.DecryptString(SourceRaw); // дешифруем
  DCP_rijndael1.Burn;                            // стираем инфо о ключе
  DCP_rijndael1.Free;                            // уничтожаем объект
end;

// Запись значения в INI-файл
procedure SaveSettingString(Section, Name, Value: string);
var
  ini: TIniFile;
begin
try
  ini := TIniFile.Create(SettingsFilePath);
  try
    ini.WriteString(Section, Name, string(EncryptString(Value,'852456')));
  finally
    ini.Free;
  end;
except
  Exit;
end;
end;

// Чтение значения из INI-файла
function LoadSettingString(Section, Name: string): string;
var
  ini: TIniFile;
begin
try
  ini := TIniFile.Create(SettingsFilePath);
  try
    Result := string(DecryptString(ini.ReadString(Section, Name, ''),'852456'));
  finally
    ini.Free;
  end;
except
  Exit;
end;
end;

procedure TForm1.RectangleMenuBGClick(Sender: TObject);
begin
  CloseMenu;
end;

procedure TForm1.CloseMenu;
begin
  try
    TAnimator.AnimateFloat(RectangleMenuBG, 'Opacity', 0, 0.2,
      TAnimationType.InOut, AniInterpolation);
    TAnimator.AnimateFloat(ButtonCloseMenu, 'Opacity', 0, 0.2,
      TAnimationType.InOut, AniInterpolation);
    TAnimator.AnimateFloat(LayoutMenuContainer, 'Opacity', 0, 0.2,
      TAnimationType.InOut, AniInterpolation);
    TAnimator.AnimateFloatWait(LayoutMenuContainer, 'Margins.Left',
      -(LayoutMenuContainer.Width - 45), 0.2, TAnimationType.InOut,
      AniInterpolation);
    LayoutMenuContent.Visible := False;
  except
    Exit;
  end;
end;

procedure TForm1.FOnChatItemClick(Sender: TObject);
var
  Item: TListBoxItem absolute Sender;
begin
  try
    SelectChat(Item.TagString);
    if Mode = wmCompact then
      CloseMenu;
  except
    Exit;
  end;
end;

procedure TForm1.FOnChatItemTap(Sender: TObject; const Point: TPointF);
begin
  try
    FOnChatItemClick(Sender);
  except
    Exit;
  end;
end;

function TForm1.CreateChat: string;
begin
  if Length(FOpenAI.Token) = 0 then
  if Fileexists(SettingsFilePath) then
     FOpenAI.Token := LoadSettingString('Setting','Token');
  try
    Result := TGUID.NewGuid.ToString;
    var
    ChatTitle := 'New chat ' + NextChatId.ToString;
    Frame := TFrameChat.Create(LayoutChatsBox);
    Frame.Align := TAlignLayout.Client;
    Frame.Parent := LayoutChatsBox;
    Frame.API := OpenAI;
    Frame.ChatId := Result;
    Frame.Title := ChatTitle;
    Frame.Mode := Mode;
    var
    ItemList := TListBoxItem.Create(ListBoxChatList);
    ItemList.HitTest := True;
{$IFDEF ANDROID}
    ItemList.OnTap := FOnChatItemTap;
{$ELSE}
    ItemList.OnClick := FOnChatItemClick;
{$ENDIF}
    ItemList.Margins.Bottom := 8;
    ItemList.Text := ChatTitle;
    ItemList.TagString := Result;
    ItemList.ImageIndex := 1;
    ItemList.DisableDisappear := True;
    ListBoxChatList.AddObject(ItemList);
    ItemList.ApplyStyleLookup;
  except
    Exit;
  end;
end;

procedure TForm1.SelectChat(const ChatId: string);
begin
  try
    for var Control in LayoutChatsBox.Controls do
      if Control is TFrameChat then
      begin
        var
        Frame := Control as TFrameChat;
        Frame.Visible := Frame.ChatId = ChatId;
      end;
    for var i := 0 to Pred(ListBoxChatList.Count) do
      if ListBoxChatList.ListItems[i].TagString = ChatId then
      begin
        ListBoxChatList.ListItems[i].IsSelected := True;
        LabelChatName.Text := ListBoxChatList.ListItems[i].Text;
        Exit;
      end;
  except
    Exit;
  end;
end;

procedure TForm1.SetMode(const Value: TWindowMode);
begin
  try
    if FMode = Value then
      Exit;
    FMode := Value;
    UpdateMode;
  except
    Exit;
  end;
end;

procedure TForm1.ButtonCloseMenuClick(Sender: TObject);
begin
  CloseMenu;
end;

procedure TForm1.ButtonMenuClick(Sender: TObject);
begin
  try
    RectangleMenuBG.Opacity := 0;
    LayoutMenuContainer.Opacity := 0;
    LayoutMenuContainer.Margins.Left := -(LayoutMenuContainer.Width - 45);
    ButtonCloseMenu.Opacity := 0;
    LayoutMenuContent.Visible := True;
    TAnimator.AnimateFloat(RectangleMenuBG, 'Opacity', 1, 0.2,
      TAnimationType.InOut, AniInterpolation);
    TAnimator.AnimateFloat(ButtonCloseMenu, 'Opacity', 1, 0.2,
      TAnimationType.InOut, AniInterpolation);
    TAnimator.AnimateFloat(LayoutMenuContainer, 'Opacity', 1, 0.2,
      TAnimationType.InOut, AniInterpolation);
    TAnimator.AnimateFloat(LayoutMenuContainer, 'Margins.Left', 0, 0.2,
      TAnimationType.InOut, AniInterpolation);
  except
    Exit;
  end;
end;

procedure TForm1.ButtonNewChatClick(Sender: TObject);
begin
  try
    SelectChat(CreateChat);
    if Mode = wmCompact then
      CloseMenu;
  except
    Exit;
  end;
end;

procedure TForm1.ButtonNewChatCompactClick(Sender: TObject);
begin
  try
    SelectChat(CreateChat);
  except
    Exit;
  end;
end;

procedure TForm1.ButtonUseKeyClick(Sender: TObject);
var
   str :  string;
begin
try
 if Fileexists(SettingsFilePath) then begin
    str := LoadSettingString('Setting','Token');
    if Length(str) = 0 then
    TDialogservice.InputQuery('Attention', ['Your APIKey:'], [''],
    procedure(const AResult: TModalResult; const AValues: array of string)
      begin
        case AResult of
          mrOk:
            begin
              str := AValues[0];
              FOpenAI.Token := str;
              if Length(str) > 0 then SaveSettingString('Setting','Token',str);
            end;
          mrCancel:
            begin
              Exit;
            end;
        end;
      end
    )
    else
    TDialogservice.InputQuery('Attention', ['Your APIKey:'], [''+str],
    procedure(const AResult: TModalResult; const AValues: array of string)
      begin
        case AResult of
          mrOk:
            begin
              str := AValues[0];
              FOpenAI.Token := str;
              if Length(str) > 0 then SaveSettingString('Setting','Token',str);
            end;
          mrCancel:
            begin
              Exit;
            end;
        end;
      end
    );
 end else begin
    TDialogservice.InputQuery('Attention', ['Please enter your APIKey:'], [''],
    procedure(const AResult: TModalResult; const AValues: array of string)
      begin
        case AResult of
          mrOk:
            begin
              str := AValues[0];
              FOpenAI.Token := str;
              if Length(str) > 0 then SaveSettingString('Setting','Token',str);
            end;
          mrCancel:
            begin
              Exit;
            end;
        end;
      end
    );
 end;
except
  Exit;
end;
end;

procedure TForm1.Clear;
begin
  try
    FChatIdCount := 0;
    HideClearConfirm;
    ListBoxChatList.Clear;
    while LayoutChatsBox.ControlsCount > 0 do
      LayoutChatsBox.Controls[0].Free;
    SelectChat(CreateChat);
  except
    Exit;
  end;
end;

procedure TForm1.UpdateMode;
begin
  try
    for var Control in LayoutChatsBox.Controls do
      if Control is TFrameChat then
      begin
        var
        Frame := Control as TFrameChat;
        Frame.Mode := FMode;
      end;
    case FMode of
      wmCompact:
        begin
          RectangleMenu.Align := TAlignLayout.Client;
          RectangleMenu.Parent := LayoutMenuContainer;
          LayoutHead.Visible := True;
          ButtonCloseMenu.Visible := True;
        end;
      wmFull:
        begin
          RectangleMenu.Align := TAlignLayout.Left;
          RectangleMenu.Width := 260;
          RectangleMenu.Parent := Self;
          LayoutHead.Visible := False;
          ButtonCloseMenu.Visible := False;
          LayoutMenuContent.Visible := False;
        end;
    end;
  except
    Exit;
  end;
end;

constructor TForm1.Create(AOwner: TComponent);
begin
  try
    // Получаем путь к директории, доступной для общего чтения и записи на устройстве
    SettingsFilePath := TPath.Combine(TPath.GetDocumentsPath, 'config.ini');
    inherited;
    if Fileexists(SettingsFilePath) then begin
       FChatIdCount := 0;
       FOpenAI := TOpenAIComponent.Create(Self);
       FOpenAI.Token := LoadSettingString('Setting','Token');
       ListBoxChatList.AniCalculations.Animation := True;
       Clear;
       FMode := wmFull;
       UpdateMode;
    end else begin
       FChatIdCount := 0;
       FOpenAI := TOpenAIComponent.Create(Self);
       FOpenAI.Token := API_TOKEN;
       ListBoxChatList.AniCalculations.Animation := True;
       Clear;
       FMode := wmFull;
       UpdateMode;
    end;
  except
    Exit;
  end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  try
    LayoutMenuContainer.Width := Min(320, ClientWidth - 45);
    if ClientWidth < 768 then
      Mode := wmCompact
    else
      Mode := wmFull;
  except
    Exit;
  end;
end;

procedure TForm1.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  Padding.Bottom := 0;
end;

procedure TForm1.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  Padding.Bottom := Bounds.Height;
end;

procedure TForm1.FormConstrainedResize(Sender: TObject;
  var MinWidth, MinHeight, MaxWidth, MaxHeight: Single);
begin
  try
    FormResize(Sender);
  except
    Exit;
  end;
end;

procedure TForm1.ShowClearConfirm;
begin
  ButtonClear.Text := 'Confirm clear';
  ButtonClearConfirm.Visible := True;
  ButtonClearCancel.Visible := True;
end;

procedure TForm1.HideClearConfirm;
begin
  ButtonClear.Text := 'Clear conversations';
  ButtonClearConfirm.Visible := False;
  ButtonClearCancel.Visible := False;
end;

procedure TForm1.ButtonClearCancelClick(Sender: TObject);
begin
  HideClearConfirm;
end;

procedure TForm1.ButtonGenApiKeyClick(Sender: TObject);
begin
  try
    OpenUrl(URL_API_KEY);
  except
    Exit;
  end;
end;

procedure TForm1.ButtonClearClick(Sender: TObject);
begin
  try
    ShowClearConfirm;
  except
    Exit;
  end;
end;

procedure TForm1.ButtonClearConfirmClick(Sender: TObject);
begin
  Clear;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.
