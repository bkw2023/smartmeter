object MainForm: TMainForm
  Left = 504
  Top = 249
  Width = 620
  Height = 422
  Caption = 'Siemens IM350 Smartmeter Wiener Netze'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnClose = OnCloseFrame
  OnCreate = OnCreateForm
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 612
    Height = 352
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 0
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 352
    Width = 612
    Height = 19
    Panels = <>
    SimplePanel = False
  end
  object StringGrid: TStringGrid
    Left = 0
    Top = 0
    Width = 612
    Height = 352
    Align = alClient
    ColCount = 2
    RowCount = 4
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
    ScrollBars = ssNone
    TabOrder = 2
    Visible = False
    OnGetEditMask = OnEditMask
    OnGetEditText = OnGetEditText
  end
  object MainMenu: TMainMenu
    Left = 16
    Top = 16
    object File1: TMenuItem
      Caption = 'File'
      object Save: TMenuItem
        Caption = 'Save'
        OnClick = SaveClick
      end
      object LogAll1: TMenuItem
        Caption = 'LogAll'
        OnClick = LogAll1Click
      end
    end
    object Comport: TMenuItem
      Caption = 'Comport'
      OnClick = ComportClick
    end
    object erminal1: TMenuItem
      Caption = 'Terminal'
      OnClick = Terminal1Click
    end
    object Connect1: TMenuItem
      Caption = 'Connect'
      OnClick = Connect1Click
    end
    object Disconnect1: TMenuItem
      Caption = 'Disconnect'
      OnClick = Disconnect1Click
    end
  end
  object SaveDialog: TSaveDialog
    Left = 48
    Top = 16
  end
  object Timer: TTimer
    Enabled = False
    Interval = 800
    OnTimer = OnTimerDo
    Left = 144
    Top = 16
  end
end
