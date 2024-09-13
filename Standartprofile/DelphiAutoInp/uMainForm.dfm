object MainForm: TMainForm
  Left = 590
  Top = 122
  Width = 616
  Height = 349
  Caption = 'Delphi-Auto-Input'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnCreate = DoOnCreate
  OnDestroy = DoOnDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 608
    Height = 279
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 279
    Width = 608
    Height = 19
    Panels = <>
    SimplePanel = False
  end
  object MainMenu: TMainMenu
    Left = 8
    Top = 8
    object File1: TMenuItem
      Caption = 'File'
      object Load1: TMenuItem
        Caption = 'Load'
        OnClick = Load1Click
      end
      object Save1: TMenuItem
        Caption = 'Save'
        OnClick = Save1Click
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
      end
    end
    object Start1: TMenuItem
      Caption = 'Start'
      OnClick = Start1Click
    end
    object Stop1: TMenuItem
      Caption = 'Stop'
      OnClick = Stop1Click
    end
    object Run1: TMenuItem
      Caption = 'Run'
      object Single1: TMenuItem
        Caption = 'Single'
        OnClick = Single1Click
      end
      object Loop1: TMenuItem
        Caption = 'Loop'
      end
      object Repeatn1: TMenuItem
        Caption = 'Repeat n'
        OnClick = Repeatn1Click
      end
    end
  end
  object Timer: TTimer
    Enabled = False
    Interval = 10
    OnTimer = DoOnTimer
    Left = 40
    Top = 8
  end
  object SaveDialog: TSaveDialog
    Left = 72
    Top = 8
  end
  object OpenDialog: TOpenDialog
    Left = 104
    Top = 8
  end
end
