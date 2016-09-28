library WebCam;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  System.SysUtils, Messages,
  directshow9,
  ActiveX,
  Vcl.Imaging.jpeg,
  Vcl.Dialogs,
  vcl.graphics,
  WinInet,
  System.Classes,
  Winapi.Windows,
  Vcl.ExtCtrls;

{$R *.res}


type
  TWebCam = class

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


    Image1: TImage;
    fDevicesLst : Tstrings;
    fSelectedIndx : integer;
  private
    function CaptureAndSaveBitmap(Path:string): HResult;
    function CreateGraph: HResult;
    function Initializ: HResult;
    procedure RunOptions;
    constructor create;
    destructor destroy;
  public
    property DeviceLst : Tstrings read fDevicesLst;
  end;

function TWebCam.Initializ: HResult;
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
    fDevicesLst.Add(DeviceName);
  end;

//�������������� ����� ��������� ��� ������� �����
//�������� �� ����� ������
if fDevicesLst.Count=0 then
   begin
      raise Exception.Create('������ �� ����������');
      Result:=E_FAIL;;
      Exit;
   end;
//Listbox1.ItemIndex:=0;
//���� ��� ��
Result:=S_OK;
end;

procedure TWebCam.RunOptions;
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
           0,          //handle
           0,
           0,
           PWideChar(fDevicesLst[fSelectedIndx] ),  //ListBox1.Items.Strings[listbox1.ItemIndex]
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

function TWebCam.CreateGraph:HResult;
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

              //�������� ���������� ��� ������� ����� �� ������ ���������
              MArray1[fSelectedIndx].BindToObject(NIL, NIL, IID_IBaseFilter, FVideoCaptureFilter);  //selected!
              //��������� ���������� � ���� ��������
              FGraphBuilder.AddFilter(FVideoCaptureFilter, 'VideoCaptureFilter'); //�������� ������ ����� �������

  //������, ��� ������ ����� �������� � ���� ��� ������ ����������
  Result:=FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_PREVIEW, nil, FVideoCaptureFilter ,FBaseFilter  ,nil);
  if FAILED(Result) then EXIT;

  //�������� ��������� ���������� ����� �����
  Result:=FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow);
  if FAILED(Result) then EXIT;
  //������ ����� ���� ������
  FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//  //����������� ���� ������ ��  Panel1
//  FVideoWindow.put_Owner(Panel1.Handle);
//  //������ ������� ���� �� ��� ������
//  FVideoRect:=Panel1.ClientRect;
  FVideoWindow.SetWindowPosition(FVideoRect.Left,FVideoRect.Top, FVideoRect.Right - FVideoRect.Left,FVideoRect.Bottom - FVideoRect.Top);
//  //���������� ����
  FVideoWindow.put_Visible(true);

  //����������� ��������� ���������� ������
  Result:=FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);
  if FAILED(Result) then Exit;
  //��������� ����������� ��������� � ��������
  FMediaControl.Run();
end;

function TWebCam.CaptureAndSaveBitmap(Path:string): HResult;
var
  bSize: integer;
  pVideoHeader: TVideoInfoHeader;
  MediaType: TAMMediaType;
  BitmapInfo: TBitmapInfo;
  Buffer: Pointer;
  tmp: array of byte;
  Bitmap: vcl.graphics.TBitmap;

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
  Bitmap := vcl.graphics.TBitmap.Create;
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
      image1.Picture.SaveToFile(path);
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

constructor TWebCam.create;
begin
  fDevicesLst := TStringList.create;
  image1 := TImage.Create(nil);

  //��������� ��������� �� ini �����
  CoInitialize(nil);// ���������������� OLE COM
  //�������� ��������� ������ � ������������� ��������� ������� ����� � �����
  if FAILED(Initializ) then
    Begin
      raise Exception.Create('��������� ������ ��� �������������');
      Exit;
    End;
  //��������� ��������� ������ ���������
  if fDevicesLst.Count = 0 then

                    raise Exception.Create('������ �� ����������.');

        //���� ����������� ��� ������ ���������� �������,
        //�� �������� ��������� ���������� ����� ��������
//        if FAILED(CreateGraph) then
//            Begin
//              raise Exception.Create('��������� ������ ��� ���������� ����� ��������');
//              Exit;
//            End;

end;

destructor TWebCam.destroy;
begin
  FreeAndNil(fDevicesLst);
  FreeAndNil(image1);
end;

{=========================================}
var
  WebCam1 : TWebCam;
  aErrorMessage: string;


function getDevicesLst : string;
begin
  result := WebCam1.fDevicesLst.Text;
end;

function CreateObject(devIndex:Integer):boolean;
begin
  result := false;
  try
    WebCam1 := TWebCam.create;
    WebCam1.fSelectedIndx := devindex;

    if FAILED(webcam1.CreateGraph) then
      Begin
        aErrorMessage := '��������� ������ ��� ���������� ����� ��������';
        Exit;
      End;
     result := true;
  except
    on E: Exception do
    aErrorMessage := e.Message;
  end;
end;

procedure ReleaseObject;
begin
  WebCam1.Free;
end;


function CaptureAndSaveBitmap(Path:string) :boolean;
begin
  result := false;


  if Failed( WebCam1.CaptureAndSaveBitmap(path)) then
    result := false
  else result := true;
end;

function CreateCapSaveRelease(aDeviceIndex:integer; aSaveFilePath:string):boolean;
var
  WebCam2: TWebCam;
begin
  result := false;
  try
    try
      WebCam2 := TWebCam.create;
      WebCam2.fSelectedIndx := aDeviceIndex;
      WebCam2.CreateGraph;
      WebCam2.CaptureAndSaveBitmap(aSaveFilePath);
      result := true;
    except
      on E: Exception do  begin
        aErrorMessage := e.Message;
      end;
    end;
  finally
    FreeAndNil(webcam2);
  end;
end;

function getErrorText:string;
begin
  result := aErrorMessage;
end;


Procedure runOptions;
begin
  webcam1.RunOptions;
end;

exports //��� ��� ������ � ��������� ����������� ��� �������� � ������� ��������
  CaptureAndSaveBitmap,
  getDevicesLst,
  getErrorText,
  CreateCapSaveRelease,
  runOptions,
  getErrorText,

  CreateObject,
  ReleaseObject;

begin

end.
