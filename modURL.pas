unit modURL;

interface

uses
  System.SysUtils
{$IFDEF ANDROID}
    , Androidapi.Helpers, Androidapi.JNI.Net,
  Androidapi.JNI.GraphicsContentViewText;
{$ENDIF}
// ...
{$IFDEF MACOS}
{$IFDEF IOS}
, Macapi.Helpers, iOSapi.Foundation, FMX.Helpers.IOS;
{$ELSE}
, Posix.Stdlib;
{$ENDIF}
{$ENDIF}
// ...
{$IFDEF MSWINDOWS}
, ShellAPI;
{$ENDIF}
procedure openUrl(const aURL: string);

implementation

{$IFDEF ANDROID}
function andUrl(const aURL: string): boolean;
var
  Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, StrToJURI(aURL));
  TAndroidHelper.Context.startActivity(Intent);
  Result := True;
end;
{$ENDIF}
{$IFDEF IOS}

function iosUrl(const aURL: string): boolean;
var
  NSU: NSUrl;
begin
  NSU := TNSURL.Wrap(TNSURL.OCClass.URLWithString(StrToNSStr(aURL)));
  if SharedApplication.canOpenURL(NSU) then
    SharedApplication.openUrl(NSU);
end;
{$ENDIF}
{$IFDEF MSWINDOWS}

function winUrl(const aURL: string): boolean;
begin
  ShellExecute(0, 'open', pchar(aURL), nil, nil, 0);
  Result := True;
end;
{$ENDIF}
{$IF defined(MACOS) AND not defined(IOS)}

procedure macUrl(const aURL: String);
begin
  _system(PAnsiChar(AnsiString('open ' + aURL)));
end;
{$ENDIF}

procedure openUrl(const aURL: string);
begin
{$IFDEF ANDROID}
  andUrl(aURL);
{$ENDIF}
{$IFDEF MACOS}
{$IFDEF IOS}
  iosUrl(aURL);
{$ELSE}
  macUrl(aURL);
{$ENDIF}
{$ENDIF}
{$IFDEF MSWINDOWS} winUrl(aURL); {$ENDIF}
end;

end.