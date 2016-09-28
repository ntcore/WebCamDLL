object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 218
  ClientWidth = 272
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 108
    Height = 25
    Caption = 'Create'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button3: TButton
    Left = 8
    Top = 102
    Width = 108
    Height = 25
    Caption = 'CaptureAndSave'
    TabOrder = 1
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 8
    Top = 170
    Width = 108
    Height = 25
    Caption = 'Release'
    TabOrder = 2
    OnClick = Button4Click
  end
  object Edit1: TEdit
    Left = 122
    Top = 103
    Width = 105
    Height = 21
    TabOrder = 3
    Text = 'c:\1.jpg'
  end
  object Edit2: TEdit
    Left = 122
    Top = 8
    Width = 31
    Height = 21
    TabOrder = 4
    Text = '0'
  end
  object Button6: TButton
    Left = 8
    Top = 39
    Width = 108
    Height = 25
    Caption = 'getDevLst'
    TabOrder = 5
    OnClick = Button6Click
  end
  object Memo1: TMemo
    Left = 122
    Top = 35
    Width = 142
    Height = 62
    Lines.Strings = (
      'Memo1')
    TabOrder = 6
  end
  object Button2: TButton
    Left = 8
    Top = 133
    Width = 108
    Height = 25
    Caption = 'RunOptions'
    TabOrder = 7
    OnClick = Button2Click
  end
end
