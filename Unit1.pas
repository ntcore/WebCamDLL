unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,  StdCtrls, ExtCtrls, directshow9, ActiveX, Jpeg, WinInet, IniFiles;


type
  TForm1 = class(TForm)
    ListBox1: TListBox;
    Panel1: TPanel;
    Button1: TButton;
    Panel2: TPanel;
    Image1: TImage;
    Button2: TButton;
    function CreateGraph: HResult;
    function Initializ: HResult;
    function CaptureBitmap: HResult;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  IniFile: TIniFile;
  DeviceName:OleVariant;
  PropertyName:IPropertyBag;
  pDevEnum:ICreateDEvEnum;
  pEnum:IEnumMoniker;
  pMoniker:IMoniker;

MArray1: array of IMoniker; //��� ������ ���������, �� �������
//�� ����� ����� �������� ���������� �������


//����������
    FGraphBuilder:        IGraphBuilder;
    FCaptureGraphBuilder: ICaptureGraphBuilder2;
    FMux:                 IBaseFilter;
    FSink:                IFileSinkFilter;
    FMediaControl:        IMediaControl;
    FVideoWindow:         IVideoWindow;
    FVideoCaptureFilter:  IBaseFilter;
    FAudioCaptureFilter:  IBaseFilter;
//������� ������ �����������
    FVideoRect:           TRect;

    FBaseFilter:          IBaseFilter;
    FSampleGrabber:       ISampleGrabber;
    MediaType:            AM_MEDIA_TYPE;


implementation

{$R *.dfm}

function TForm1.Initializ: HResult;
begin
//������� ������ ��� ������������ ���������
  Result:=CoCreateInstance(CLSID_SystemDeviceEnum, NIL, CLSCTX_INPROC_SERVER,
  IID_ICreateDevEnum, pDevEnum);
  if Result<>S_OK then EXIT;

  //������������� ��������� Video
  Result:=pDevEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, pEnum, 0);
  if Result<>S_OK then EXIT;

  //�������� ������ � ������ ���������
  setlength(MArray1,0);

  //������� ������ �� ������ ���������
  while (S_OK=pEnum.Next(1,pMoniker,Nil)) do
  begin
    setlength(MArray1,length(MArray1)+1); //����������� ������ �� �������
    MArray1[length(MArray1)-1]:=pMoniker; //���������� ������� � ������
    Result:=pMoniker.BindToStorage(NIL, NIL, IPropertyBag, PropertyName); //������� ������� ���������� � ������� �������� IPropertyBag
    if FAILED(Result) then Continue;
    Result:=PropertyName.Read('FriendlyName', DeviceName, NIL); //�������� ��� ����������
    if FAILED(Result) then Continue;
    //��������� ��� ���������� � ������
    Listbox1.Items.Add(DeviceName);
  end;

//�������������� ����� ��������� ��� ������� �����
//�������� �� ����� ������
if ListBox1.Count=0 then
   begin
      ShowMessage('������ �� ����������');
      Result:=E_FAIL;;
      Exit;
   end;
Listbox1.ItemIndex:=0;
//���� ��� ��
Result:=S_OK;
end;

function TForm1.CreateGraph:HResult;
var
  pConfigMux: IConfigAviMux;
begin
//������ ����
  FVideoCaptureFilter  := NIL;
  FVideoWindow         := NIL;
  FMediaControl        := NIL;
  FSampleGrabber       := NIL;
  FBaseFilter          := NIL;
  FCaptureGraphBuilder := NIL;
  FGraphBuilder        := NIL;

//������� ������ ��� ����� ��������
Result:=CoCreateInstance(CLSID_FilterGraph, NIL, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraphBuilder);
if FAILED(Result) then EXIT;
// ������� ������ ��� ���������
Result:=CoCreateInstance(CLSID_SampleGrabber, NIL, CLSCTX_INPROC_SERVER, IID_IBaseFilter, FBaseFilter);
if FAILED(Result) then EXIT;
//������� ������ ��� ����� �������
Result:=CoCreateInstance(CLSID_CaptureGraphBuilder2, NIL, CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
if FAILED(Result) then EXIT;

// ��������� ������ � ����
Result:=FGraphBuilder.AddFilter(FBaseFilter, 'GRABBER');
if FAILED(Result) then EXIT;
// �������� ��������� ������� ���������
Result:=FBaseFilter.QueryInterface(IID_ISampleGrabber, FSampleGrabber);
if FAILED(Result) then EXIT;

  if FSampleGrabber <> NIL then
  begin
    // ������������� ������ ������ ��� ������� ���������
    ZeroMemory(@MediaType, sizeof(AM_MEDIA_TYPE));

    with MediaType do
    begin
      majortype  := MEDIATYPE_Video;
      subtype    := MEDIASUBTYPE_RGB24;
      formattype := FORMAT_VideoInfo;
    end;

    FSampleGrabber.SetMediaType(MediaType);

    // ������ ����� �������� � ����� � ��� ����, � ������� ���
    // �������� ����� ������
    FSampleGrabber.SetBufferSamples(TRUE);

    // ���� �� ����� ���������� ��� ��������� �����
    FSampleGrabber.SetOneShot(FALSE);
  end;

//������ ���� ��������
Result:=FCaptureGraphBuilder.SetFiltergraph(FGraphBuilder);
if FAILED(Result) then EXIT;

//����� ��������� ListBox - ��
if Listbox1.ItemIndex>=0 then
           begin
              //�������� ���������� ��� ������� ����� �� ������ ���������
              MArray1[Listbox1.ItemIndex].BindToObject(NIL, NIL, IID_IBaseFilter, FVideoCaptureFilter);
              //��������� ���������� � ���� ��������
              FGraphBuilder.AddFilter(FVideoCaptureFilter, 'VideoCaptureFilter'); //�������� ������ ����� �������
           end;

//������, ��� ������ ����� �������� � ���� ��� ������ ����������
Result:=FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_PREVIEW, nil, FVideoCaptureFilter ,FBaseFilter  ,nil);
if FAILED(Result) then EXIT;

//�������� ��������� ���������� ����� �����
Result:=FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow);
if FAILED(Result) then EXIT;
//������ ����� ���� ������
FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//����������� ���� ������ ��  Panel1
FVideoWindow.put_Owner(Panel1.Handle);
//������ ������� ���� �� ��� ������
FVideoRect:=Panel1.ClientRect;
FVideoWindow.SetWindowPosition(FVideoRect.Left,FVideoRect.Top, FVideoRect.Right - FVideoRect.Left,FVideoRect.Bottom - FVideoRect.Top);
//���������� ����
FVideoWindow.put_Visible(TRUE);

//����������� ��������� ���������� ������
Result:=FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);
if FAILED(Result) then Exit;
//��������� ����������� ��������� � ��������
FMediaControl.Run();
end;

function TForm1.CaptureBitmap: HResult;
var
  bSize: integer;
  pVideoHeader: TVideoInfoHeader;
  MediaType: TAMMediaType;
  BitmapInfo: TBitmapInfo;
  Buffer: Pointer;
  tmp: array of byte;
  Bitmap: TBitmap;

begin
  // ��������� �� ���������
  Result := E_FAIL;

  // ����  ����������� ��������� ������� ��������� �����������,
  // �� ��������� ������
  if FSampleGrabber = NIL then EXIT;

  // �������� ������ �����
    Result := FSampleGrabber.GetCurrentBuffer(bSize, NIL);
    if (bSize <= 0) or FAILED(Result) then EXIT;
  // ������� �����������
  Bitmap := TBitmap.Create;
  try
  // �������� ��� ����� ������ �� ����� � ������� ���������
  ZeroMemory(@MediaType, sizeof(TAMMediaType));
  Result := FSampleGrabber.GetConnectedMediaType(MediaType);
  if FAILED(Result) then EXIT;

    // �������� ��������� �����������
    pVideoHeader := TVideoInfoHeader(MediaType.pbFormat^);
    ZeroMemory(@BitmapInfo, sizeof(TBitmapInfo));
    CopyMemory(@BitmapInfo.bmiHeader, @pVideoHeader.bmiHeader, sizeof(TBITMAPINFOHEADER));

    Buffer := NIL;

    // ������� ��������� �����������
    Bitmap.Handle := CreateDIBSection(0, BitmapInfo, DIB_RGB_COLORS, Buffer, 0, 0);

    // �������� ������ �� ��������� �������
    SetLength(tmp, bSize);

    try
      // ������ ����������� �� ����� ������ �� ��������� �����
      FSampleGrabber.GetCurrentBuffer(bSize, @tmp[0]);

      // �������� ������ �� ���������� ������ � ���� �����������
      CopyMemory(Buffer, @tmp[0], MediaType.lSampleSize);

      //�������� ����������� �� canvas image1
      image1.Picture.Bitmap:=Bitmap;

    except

      // � ������ ���� ���������� ��������� ���������
      Result := E_FAIL;
    end;
  finally
    // ����������� ������
    SetLength(tmp, 0);
    Bitmap.Free;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
//��������� ���� ���������� ��� ������� �����������
if Listbox1.Count=0 then
    Begin
      ShowMessage('��������! ������ �� ����������.');
      Exit;
    End;
//������ ����
if FAILED(CaptureBitmap) then
    Begin
      ShowMessage('��������! ��������� ������ ��� ��������� �����������');
      Exit;
    End;
end;

procedure TForm1.Button1Click(Sender: TObject);
//����� �������� ������� Web-������
var
  StreamConfig: IAMStreamConfig;
  PropertyPages: ISpecifyPropertyPages;
  Pages: CAUUID;
Begin
  // ���� ����������� ��������� ������ � �����, �� ��������� ������
  if FVideoCaptureFilter = NIL then EXIT;
  // ������������� ������ �����
  FMediaControl.Stop;
  try
    // ���� ��������� ���������� �������� ������ ��������� ������
    // ���� ��������� ������, �� ...
    if SUCCEEDED(FCaptureGraphBuilder.FindInterface(@PIN_CATEGORY_CAPTURE,
      @MEDIATYPE_Video, FVideoCaptureFilter, IID_IAMStreamConfig, StreamConfig)) then
    begin
      // ... �������� ����� ��������� ���������� ���������� ������� ...
      // ... �, ���� �� ������, �� ...
      if SUCCEEDED(StreamConfig.QueryInterface(ISpecifyPropertyPages, PropertyPages)) then
      begin
        // ... �������� ������ ������� �������
        PropertyPages.GetPages(Pages);
        PropertyPages := NIL;

        // ���������� �������� ������� � ���� ���������� �������
        OleCreatePropertyFrame(
           Handle,
           0,
           0,
           PWideChar(ListBox1.Items.Strings[listbox1.ItemIndex]),
           1,
           @StreamConfig,
           Pages.cElems,
           Pages.pElems,
           0,
           0,
           NIL
        );

        // ����������� ������
        StreamConfig := NIL;
        CoTaskMemFree(Pages.pElems);
      end;
    end;

  finally
    // ��������������� ������ �����
    FMediaControl.Run;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//��������� ��������� �� ini �����
  CoInitialize(nil);// ���������������� OLE COM
//�������� ��������� ������ � ������������� ��������� ������� ����� � �����
  if FAILED(Initializ) then
    Begin
      ShowMessage('��������! ��������� ������ ��� �������������');
      Exit;
    End;
//��������� ��������� ������ ���������
if Listbox1.Count>0 then
    Begin
        //���� ����������� ��� ������ ���������� �������,
        //�� �������� ��������� ���������� ����� ��������
        if FAILED(CreateGraph) then
            Begin
              ShowMessage('��������! ��������� ������ ��� ���������� ����� ��������');
              Exit;
            End;
    end else
            Begin
              ShowMessage('��������! ������ �� ����������.');
              //Application.Terminate;
            End;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
// ����������� ������
        pEnum := NIL;
        pDevEnum := NIL;
        pMoniker := NIL;
        PropertyName := NIL;
        DeviceName:=Unassigned;
        CoUninitialize;// ������������������ OLE COM
end;


//����� ��������� �� ListBox1
procedure TForm1.ListBox1DblClick(Sender: TObject);
begin
if ListBox1.Count=0 then
    Begin
       ShowMessage('������ �� �������');
       Exit;
    End;
//�������������  ���� ��� ����� ������
if FAILED(CreateGraph) then
    Begin
      ShowMessage('��������! ��������� ������ ��� ���������� ����� ��������');
      Exit;
    End;
end;


end.
