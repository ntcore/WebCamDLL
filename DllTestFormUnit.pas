unit DllTestFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    Button1: TButton;
    Button3: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Button6: TButton;
    Memo1: TMemo;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure CreateObject_(devIndex:Integer); external 'WebCam.dll' name 'CreateObject';
procedure ReleaseObject_; external 'WebCam.dll' name 'ReleaseObject';

function getDevicesLst_:string; external 'WebCam.dll' name 'getDevicesLst';
function CaptureAndSaveBitmap(Path:string) :boolean; external 'WebCam.dll' name 'CaptureAndSaveBitmap';

function CreateCapSaveRelease(aDeviceIndex:integer; aSaveFilePath:string):boolean; external 'WebCam.dll' name 'CreateCapSaveRelease';

function getErrorText_:string; external 'WebCam.dll' name 'getErrorText';
function runOptions_:string; external 'WebCam.dll' name 'runOptions';



var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
begin
  CreateObject_(StrtoInt(edit2.Text));
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
runOptions_;
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
if  CaptureAndSaveBitmap(edit1.Text) then showmessage('ok');
end;

procedure TForm2.Button4Click(Sender: TObject);
begin
  ReleaseObject_;
end;

procedure TForm2.Button6Click(Sender: TObject);
begin
  memo1.Text := getDevicesLst_;
end;

end.
