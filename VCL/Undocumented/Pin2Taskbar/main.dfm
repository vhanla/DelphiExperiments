object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Pin2Taskbar'
  ClientHeight = 313
  ClientWidth = 634
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 272
    Width = 634
    Height = 41
    Align = alBottom
    TabOrder = 0
    object btnListPinned: TButton
      Left = 0
      Top = 6
      Width = 121
      Height = 25
      Caption = 'List Pinned Buttons'
      TabOrder = 0
      OnClick = btnListPinnedClick
    end
    object btnPinUnpin: TButton
      Left = 127
      Top = 6
      Width = 121
      Height = 25
      Caption = 'Pin me to taskbar'
      TabOrder = 1
      OnClick = btnPinUnpinClick
    end
    object btnShowTaskView: TButton
      Left = 254
      Top = 6
      Width = 121
      Height = 25
      Caption = 'Show TaskView'
      TabOrder = 2
      OnClick = btnShowTaskViewClick
    end
  end
  object ListBox1: TListBox
    Left = 0
    Top = 0
    Width = 634
    Height = 272
    Align = alClient
    ItemHeight = 13
    TabOrder = 1
  end
  object ImageList1: TImageList
    Left = 312
    Top = 160
  end
end
