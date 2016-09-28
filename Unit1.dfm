object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Play Camera'
  ClientHeight = 289
  ClientWidth = 482
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
  object ListBox1: TListBox
    Left = 40
    Top = 173
    Width = 137
    Height = 76
    ItemHeight = 13
    TabOrder = 0
    OnDblClick = ListBox1DblClick
  end
  object Panel1: TPanel
    Left = 32
    Top = 24
    Width = 161
    Height = 113
    TabOrder = 1
  end
  object Button1: TButton
    Left = 8
    Top = 255
    Width = 208
    Height = 25
    Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099' '#1080' '#1088#1072#1079#1088#1077#1096#1077#1085#1080#1077' '#1082#1072#1084#1077#1088#1099
    TabOrder = 2
    OnClick = Button1Click
  end
  object Panel2: TPanel
    Left = 295
    Top = 24
    Width = 146
    Height = 113
    AutoSize = True
    TabOrder = 3
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 144
      Height = 111
      Proportional = True
    end
  end
  object Button2: TButton
    Left = 329
    Top = 173
    Width = 75
    Height = 25
    Caption = #1057#1090#1072#1088#1090
    TabOrder = 4
    OnClick = Button2Click
  end
end
