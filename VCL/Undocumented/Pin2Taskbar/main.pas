unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  ShlObj, ActiveX, ShellApi, ComObj, RegChangeThread, DWMApi, TaskbarPinner,
  System.ImageList, Vcl.ImgList;

const
  FOLDERID_AppsFolder: TGUID = '{1E87508D-89C2-42F0-8A7E-645A0F50CA58}';

type
  TForm2 = class(TForm)
    ListBox1: TListBox;
    btnListPinned: TButton;
    Panel1: TPanel;
    btnPinUnpin: TButton;
    btnShowTaskView: TButton;
    ImageList1: TImageList;
    procedure btnListPinnedClick(Sender: TObject);
    procedure btnPinUnpinClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnShowTaskViewClick(Sender: TObject);
  private
    { Private declarations }
    //FPinMonitor: TRegChangeThread;
    FPinMon: TRegMon;
    procedure MonitorRegistry(Sender: TObject);
  public
    { Public declarations }
    procedure PinMonitor(var msg: TMessage); message WM_REGKEYCHANGE;
    function IsImmersivePidl(pidl: PItemIDList): Boolean;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.btnListPinnedClick(Sender: TObject);
var
  hr: HRESULT;
  ls: IFlexibleTaskbarPinnedList;
  iu: IUnknown;
  I: Integer;
  iel: IEnumFullIDList;
  il: PItemIDList;
  ul: ULONG;
  shfi: TSHFileInfoW;
  pl: IPinnedList3;
  pns: string;
  pn: array[0..MAX_PATH] of char;
begin
  ListBox1.Clear;

    hr := ActiveX.CoCreateInstance(CLSID_TaskbandPin, nil, CLSCTX_INPROC_SERVER, IID_IPinnedList3, pl);

    if hr = S_OK then
    begin
      begin
        hr := pl.EnumObjects(iel);
        if hr = S_OK then
        begin
          hr := iel.Reset;
          ul := 0;
          repeat
            hr := iel.Next(1, il, ul);
            if hr = S_OK then
            begin
              FillChar(shfi, SizeOf(shfi), 0);
              ul := SHGetFileInfo(PChar(il), 0, shfi, SizeOf(shfi), SHGFI_PIDL or SHGFI_DISPLAYNAME);
              if ul > 0 then
              begin
                //list.Add(shfi.szDisplayName);
                SHGetPathFromIDList(il, pn);
                pns := shfi.szDisplayName;
                pns := pns + ' ' + pn;
                if IsImmersivePidl(il) then
                  ListBox1.Items.Add(pns + ' - Immersive App')
                else
                  ListBox1.Items.Add(pns);
                CoTaskMemFree(il);
              end;
            end;
          until hr <> S_OK;
//          iel._Release;
        end;
//        ls._Release;
      end;
//      iu._Release;
    end;
end;

procedure TForm2.btnPinUnpinClick(Sender: TObject);
var
  hr: HRESULT;
  pl: IPinnedList3;
  pidl: PItemIDList; // PItemIDList = PCIDLIST_ABSOLUTE
  buffer: array[0..MAX_PATH] of WideChar;
  cc: Cardinal;
begin
  CoInitialize(nil);

  hr := CoCreateInstance(CLSID_TaskbandPin, nil, CLSCTX_INPROC_SERVER, IID_IPinnedList3, pl);
  if Succeeded(hr) then
  begin
//    StringToWideChar('L:\Proyectos\TaskbarDock\TaskbarPinner\Bandizip.lnk', buffer, (High(buffer) - Low(buffer)+1));
    StringToWideChar(ParamStr(0), buffer, (High(buffer) - Low(buffer)+1));
    pidl := ILCreateFromPath(@buffer);

    hr := pl.IsPinned(PCIDLIST_ABSOLUTE(pidl));
    if hr = S_OK then // is already pinned, pet's unpin
      hr := pl.Modify(PCIDLIST_ABSOLUTE(pidl), nil, PLMC_EXPLORER)
    else
      hr := pl.Modify(nil, PCIDLIST_ABSOLUTE(pidl), PLMC_EXPLORER);
    OleCheck(hr);

    pl.GetChangeCount(cc);
    Caption := ('Favorites Changes: ' + IntToStr(cc));

    ILFree(pidl);
  end;

  CoUninitialize;
  btnListPinnedClick(Self);
end;

procedure TForm2.btnShowTaskViewClick(Sender: TObject);
const
  TaskView = $19B;
var
  hr: HRESULT;
  shell: IShellDispatch6; //windows 8+
  taskbar: HWND;
  pid: Cardinal;
begin
//
  taskbar := FindWindow('Shell_TrayWnd', nil);
  if taskbar > 0 then
  begin
    GetWindowThreadProcessId(taskbar, @pid);
    AllowSetForegroundWindow(pid);
    PostMessage(taskbar, $111, TaskView, 0);
  end;
Exit;    // the code below does exactly what is done above, behind the scenes
  CoInitialize(nil);

  hr := CoCreateInstance(CLSID_Shell, nil, CLSCTX_INPROC_SERVER, IID_IShellDispatch5, shell);
  if Succeeded(hr) then
  begin
    shell.SearchCommand;
  end;
  CoUninitialize;
end;

procedure TForm2.FormCreate(Sender: TObject);
var
  dis: BOOL;
begin
  dis := TRUE;
  DwmSetWindowAttribute(Handle, DWMWA_TRANSITIONS_FORCEDISABLED, @dis, SizeOf(dis));
  // the above disables animation on window hide/show, just a demo
//  FPinMonitor := TRegChangeThread.Create;
//  FPinMonitor.RootKey := HKEY_CURRENT_USER;
//  FPinMonitor.Key := 'Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband';
//  FPinMonitor.WatchSub := False;
//  FPinMonitor.Filter := REG_NOTIFY_CHANGE_LAST_SET;// or REG_NOTIFY_THREAD_AGNOSTIC;
//  FPinMonitor.Wnd := Handle;
//  FPinMonitor.Start;
  FPinMon := TRegMon.Create(Self);
  FPinMon.MonitoredKey := 'Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband';
  FPinMon.WatchSubKeys := False;
  FPinMon.OnChange := MonitorRegistry;
//  FPinMon.OnActivate
//  FPinMon.OnDeactivate
  FPinMon.Activate;
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  FPinMon.Deactivate;
  FPinMon.Free;
//  FPinMonitor.Terminate;
//  FPinMonitor.Free;
end;

function TForm2.IsImmersivePidl(pidl: PItemIDList): Boolean;
var
  ppidl: PItemIDList;
  v2: BOOL;
begin
  Result := False;

  if SHGetKnownFolderIDList(FOLDERID_AppsFolder, $4000, 0, ppidl) >= 0 then
  begin
    Result := ILIsParent(ppidl, pidl, True);
    ILFree(ppidl);
  end;
end;

procedure TForm2.MonitorRegistry(Sender: TObject);
begin
  btnListPinnedClick(Sender);
end;

procedure TForm2.PinMonitor(var msg: TMessage);
begin
  btnListPinnedClick(Self);
end;

end.
