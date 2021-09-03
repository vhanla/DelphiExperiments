unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Platform.Win, ActiveX,
  Windows, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, Messages,
  FMX.Effects, FMX.Edit, FMX.ListBox, System.Math.Vectors,
  FMX.Objects3D, FMX.Controls3D, FMX.Layers3D, FMX.Viewport3D,
  FMX.Filter.Effects, FMX.Layouts, FMX.ScrollBox, FMX.Memo, FMX.Ani,
  shadow, FMX.Memo.Types;

type
  TForm2 = class(TForm)
    Rectangle1: TRectangle;
    StyleBook1: TStyleBook;
    Edit1: TEdit;
    Button1: TButton;
    ComboBox1: TComboBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    ListBoxItem4: TListBoxItem;
    ListBoxItem5: TListBoxItem;
    ListBoxItem6: TListBoxItem;
    Selection1: TSelection;
    Layout1: TLayout;
    SwipeTransitionEffect1: TSwipeTransitionEffect;
    Memo1: TMemo;
    SelectionPoint1: TSelectionPoint;
    PathAnimation1: TPathAnimation;
    FloatAnimation1: TFloatAnimation;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Rectangle1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    swl_OldProc: Pointer;

    procedure WindowIsMoving(var Msg: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
  public
    { Public declarations }
    procedure EnableBlur;
  end;

  AccentPolicy = packed record
    AccentState: Integer;
    AccentFlags: Integer;
    GradientColor: Integer;
    AnimationId: Integer;
  end;

  TWinCompAttrData = packed record
    attribute: THandle;
    pData: Pointer;
    dataSize: ULONG;
  end;

var
  Form2: TForm2;
  // Hooking our window
  WndProcHook: THandle;

var
  SetWindowCompositionAttribute: function (Wnd: HWND; const AttrData: TWinCompAttrData): BOOL; stdcall = Nil;

implementation

{$R *.fmx}

{ Hook }
procedure WinEventProc(hWinEventHook: NativeUInt; dwEvent: DWORD; handle: HWND;
  idObject, idChild: LONG; dwEventThread, dwmsEventTime: DWORD);
begin
  if (dwEvent = EVENT_OBJECT_LOCATIONCHANGE)
//  or (dwEvent = EVENT_SYSTEM_MOVESIZESTART)
  then
  begin
    if Assigned(Form1) and Assigned(shadow.Form1) then
    begin
      if Assigned(shadow.Form1.Rectangle1) then
      begin
        shadow.Form1.Left := Form2.Left - (Form2.Width - Form2.ClientWidth) - Round(shadow.Form1.Rectangle1.Position.X);
        shadow.Form1.Top := Form2.Top - (Form2.Height - Form2.ClientHeight) - Round(shadow.Form1.Rectangle1.Position.Y);
      end;
    end;
  end;

end;

//based on answer at https://stackoverflow.com/a/35019598
function WndProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  msg: TCWPRetStruct;
begin
  if (nCode >= HC_ACTION) and (LParam > 0) then
  begin
    msg := PCWPRetStruct(LParam)^;
    if (msg.message = WM_SIZE) and (msg.wParam = SIZE_MINIMIZED) then
    begin
      // app has minimized
      // check msg.wnd = WindowHandleToPlatform(Form1.Handle).wnd if necessary
//      if Assigned(shadow.Form1) then
//        shadow.Form1.Visible := False;
    end;

    if (msg.message = WM_SIZE) and (msg.wParam = SIZE_RESTORED) then
    begin
      // app has minimized
      // check msg.wnd = WindowHandleToPlatform(Form1.Handle).wnd if necessary
//      if Assigned(shadow.Form1) then
//        shadow.Form1.Visible := True;
    end;

    if (msg.message = WM_WINDOWPOSCHANGED) then
    begin
      if Assigned(Form1) and Assigned(shadow.Form1) then
      begin
        if Assigned(shadow.Form1.Rectangle1) then
        begin
          shadow.Form1.Left := Form2.Left - (Form2.Width - Form2.ClientWidth) - Round(shadow.Form1.Rectangle1.Position.X);
          shadow.Form1.Top := Form2.Top - (Form2.Height - Form2.ClientHeight) - Round(shadow.Form1.Rectangle1.Position.Y);
        end;
      end;
    end;
  end;

  Result := CallNextHookEx(WndProcHook, nCode, wParam, lParam);
end;

{ TForm2 }

procedure TForm2.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm2.EnableBlur;
const
  WCA_ACCENT_POLICY = 19;
  ACCENT_ENABLE_BLURBEHIND = 3;
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4;
  DrawLeftBorder = $20;
  DrawTopBorder = $40;
  DrawRightBorder = $80;
  DrawBottomBorder = $100;
var
  dwm10: THandle;
  data : TWinCompAttrData;
  accent: AccentPolicy;
begin

      dwm10 := LoadLibrary('user32.dll');
      try
        @SetWindowCompositionAttribute := GetProcAddress(dwm10, 'SetWindowCompositionAttribute');
        if @SetWindowCompositionAttribute <> nil then
        begin
          accent.AccentState := ACCENT_ENABLE_ACRYLICBLURBEHIND ;
          //accent.GradientColor :=
          //accent.AccentFlags := DrawLeftBorder or DrawTopBorder or DrawRightBorder or DrawBottomBorder;
          accent.AccentFlags := $4000; // this won't show shadows but it will make faster on drag&drop

          data.Attribute := WCA_ACCENT_POLICY;
          data.dataSize := SizeOf(accent);
          data.pData := @accent;
          SetWindowCompositionAttribute(FMX.Platform.Win.FmxHandleToHWND(Handle), data);
        end
        else
        begin
          ShowMessage('Not found Windows 10 blur API');
        end;
      finally
        FreeLibrary(dwm10);
      end;

end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  EnableBlur;
end;

procedure TForm2.FormShow(Sender: TObject);
var
  rgns, rgn: HRGN;
begin
  Form1.Left := Left - Round(Form1.Rectangle1.Position.X);
  Form1.Top := Top - Round(Form1.Rectangle1.Position.Y);
  Form1.Width := Width + 2*Round(Form1.Rectangle1.Position.X);
  Form1.Height := Height + 2*Round(Form1.Rectangle1.Position.Y);
  shadow.Form1.Show;

  rgns := CreateRectRgn(0, 0, // X, Y
    Form1.Width +1, Form1.Height +1
  );
  rgn := CreateRoundRectRgn(Round(Form1.Rectangle1.Position.X), Round(Form1.Rectangle1.Position.Y),
    Round(Form1.Rectangle1.Width)+10, Round(Form1.Rectangle1.Height)+10,
    9, 9
  );
  CombineRgn(rgns, rgns, rgn, RGN_DIFF);
  SetWindowRgn(FmxHandleToHWND(Form1.Handle),rgns, True);

  EnableBlur;

  rgn := CreateRoundRectRgn(0, 0, // X, Y
    ClientWidth +1, ClientHeight +1,
    10, 10 // radius
  );
  SetWindowRgn(FmxHandleToHWND(Handle),rgn, True);
//  EnableBlur;
end;

procedure TForm2.Rectangle1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  ReleaseCapture;
  PostMessage(FmxHandleToHWND(Handle), WM_SYSCOMMAND, $F012, 0);
end;

procedure TForm2.WindowIsMoving(var Msg: TWMWindowPosChanging);
begin
  try
    with Msg.WindowPos^ do
    begin
      shadow.Form1.Left := Left;
      shadow.Form1.Top := Top;
    end;
  except

  end;
end;

initialization
  CoInitialize(nil);
  WndProcHook := 0;
  WndProcHook := SetWindowsHookEx(WH_CALLWNDPROCRET, @WndProc, 0, GetCurrentThreadId);
  // this also works, but it might not really be the proper way
  //WndProcHook := SetWinEventHook(EVENT_MIN, EVENT_MAX, 0, @WinEventProc, GetCurrentProcessId, GetCurrentThreadId, WINEVENT_OUTOFCONTEXT {or WINEVENT_SKIPOWNPROCESS});
  if WndProcHook = 0 then
    raise Exception.Create('Error Message');
finalization
  UnhookWindowsHookEx(WndProcHook);
  CoUninitialize;

end.
