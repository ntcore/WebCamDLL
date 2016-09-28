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

  MArray1: array of IMoniker; //Это список моникеров, из которго
  //мы потом будем получать необходмый моникер

  //интерфейсы
    FGraphBuilder:        IGraphBuilder;
    FCaptureGraphBuilder: ICaptureGraphBuilder2;
    FMux:                 IBaseFilter;
    FSink:                IFileSinkFilter;
    FMediaControl:        IMediaControl;
    FVideoWindow:         IVideoWindow;
    FVideoCaptureFilter:  IBaseFilter;
    FAudioCaptureFilter:  IBaseFilter;
//область вывода изображения
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
//Создаем объект для перечисления устройств
  Result:=CoCreateInstance(CLSID_SystemDeviceEnum, NIL, CLSCTX_INPROC_SERVER,
  IID_ICreateDevEnum, pDevEnum);
  if Result<>S_OK then EXIT;

  //Перечислитель устройств Video
  Result:=pDevEnum.CreateClassEnumerator(CLSID_VideoInputDeviceCategory, pEnum, 0);
  if Result<>S_OK then EXIT;

  //Обнуляем массив в списке моникеров
  setlength(MArray1,0);

  //Пускаем массив по списку устройств
  while (S_OK=pEnum.Next(1,pMoniker,Nil)) do
  begin
    setlength(MArray1,length(MArray1)+1); //Увеличиваем массив на единицу
    MArray1[length(MArray1)-1]:=pMoniker; //Запоминаем моникер в масиве
    Result:=pMoniker.BindToStorage(NIL, NIL, IPropertyBag, PropertyName); //Линкуем моникер устройства к формату хранения IPropertyBag
    if FAILED(Result) then Continue;
    Result:=PropertyName.Read('FriendlyName', DeviceName, NIL); //Получаем имя устройства
    if FAILED(Result) then Continue;
    //Добавляем имя устройства в списки
    fDevicesLst.Add(DeviceName);
  end;

//Первоначальный выбор устройств для захвата видео
//Выбираем из спика камеру
if fDevicesLst.Count=0 then
   begin
      raise Exception.Create('Камера не обнаружена');
      Result:=E_FAIL;;
      Exit;
   end;
//Listbox1.ItemIndex:=0;
//если все ОК
Result:=S_OK;
end;

procedure TWebCam.RunOptions;
//Вызов страницы свойств Web-камеры
var
  StreamConfig: IAMStreamConfig;
  PropertyPages: ISpecifyPropertyPages;
  Pages: CAUUID;
Begin
  // Если отсутствует интерфейс работы с видео, то завершаем работу
  if FVideoCaptureFilter = NIL then EXIT;
  // Останавливаем работу графа
  FMediaControl.Stop;
  try
    // Ищем интерфейс управления форматом данных выходного потока
    // Если интерфейс найден, то ...
    if SUCCEEDED(FCaptureGraphBuilder.FindInterface(@PIN_CATEGORY_CAPTURE,
      @MEDIATYPE_Video, FVideoCaptureFilter, IID_IAMStreamConfig, StreamConfig)) then
    begin
      // ... пытаемся найти интерфейс управления страницами свойств ...
      // ... и, если он найден, то ...
      if SUCCEEDED(StreamConfig.QueryInterface(ISpecifyPropertyPages, PropertyPages)) then
      begin
        // ... получаем массив страниц свойств
        PropertyPages.GetPages(Pages);
        PropertyPages := NIL;

        // Отображаем страницу свойств в виде модального диалога
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

        // Освобождаем память
        StreamConfig := NIL;
        CoTaskMemFree(Pages.pElems);
      end;
    end;

  finally
    // Восстанавливаем работу графа
    FMediaControl.Run;
  end;

end;

function TWebCam.CreateGraph:HResult;
var
  pConfigMux: IConfigAviMux;
begin
//Чистим граф
  FVideoCaptureFilter  := NIL;
  FVideoWindow         := NIL;
  FMediaControl        := NIL;
  FSampleGrabber       := NIL;
  FBaseFilter          := NIL;
  FCaptureGraphBuilder := NIL;
  FGraphBuilder        := NIL;

//Создаем объект для графа фильтров
Result:=CoCreateInstance(CLSID_FilterGraph, NIL, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraphBuilder);
if FAILED(Result) then EXIT;
// Создаем объект для граббинга
Result:=CoCreateInstance(CLSID_SampleGrabber, NIL, CLSCTX_INPROC_SERVER, IID_IBaseFilter, FBaseFilter);
if FAILED(Result) then EXIT;
//Создаем объект для графа захвата
Result:=CoCreateInstance(CLSID_CaptureGraphBuilder2, NIL, CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraphBuilder);
if FAILED(Result) then EXIT;

// Добавляем фильтр в граф
Result:=FGraphBuilder.AddFilter(FBaseFilter, 'GRABBER');
if FAILED(Result) then EXIT;
// Получаем интерфейс фильтра перехвата
Result:=FBaseFilter.QueryInterface(IID_ISampleGrabber, FSampleGrabber);
if FAILED(Result) then EXIT;

  if FSampleGrabber <> NIL then
  begin
    // Устанавливаем формат данных для фильтра перехвата
    ZeroMemory(@MediaType, sizeof(AM_MEDIA_TYPE));

    with MediaType do
    begin
      majortype  := MEDIATYPE_Video;
      subtype    := MEDIASUBTYPE_RGB24;
      formattype := FORMAT_VideoInfo;
    end;

    FSampleGrabber.SetMediaType(MediaType);

    // Данные будут записаны в буфер в том виде, в котором они
    // проходят через фильтр
    FSampleGrabber.SetBufferSamples(TRUE);

    // Граф не будет остановлен для получения кадра
    FSampleGrabber.SetOneShot(FALSE);
  end;

  //Задаем граф фильтров
  Result:=FCaptureGraphBuilder.SetFiltergraph(FGraphBuilder);
  if FAILED(Result) then EXIT;

              //получаем устройство для захвата видео из списка моникеров
              MArray1[fSelectedIndx].BindToObject(NIL, NIL, IID_IBaseFilter, FVideoCaptureFilter);  //selected!
              //добавляем устройство в граф фильтров
              FGraphBuilder.AddFilter(FVideoCaptureFilter, 'VideoCaptureFilter'); //Получаем фильтр графа захвата

  //Задаем, что откуда будем получать и куда оно должно выводиться
  Result:=FCaptureGraphBuilder.RenderStream(@PIN_CATEGORY_PREVIEW, nil, FVideoCaptureFilter ,FBaseFilter  ,nil);
  if FAILED(Result) then EXIT;

  //Получаем интерфейс управления окном видео
  Result:=FGraphBuilder.QueryInterface(IID_IVideoWindow, FVideoWindow);
  if FAILED(Result) then EXIT;
  //Задаем стиль окна вывода
  FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//  //Накладываем окно вывода на  Panel1
//  FVideoWindow.put_Owner(Panel1.Handle);
//  //Задаем размеры окна во всю панель
//  FVideoRect:=Panel1.ClientRect;
  FVideoWindow.SetWindowPosition(FVideoRect.Left,FVideoRect.Top, FVideoRect.Right - FVideoRect.Left,FVideoRect.Bottom - FVideoRect.Top);
//  //показываем окно
  FVideoWindow.put_Visible(true);

  //Запрашиваем интерфейс управления графом
  Result:=FGraphBuilder.QueryInterface(IID_IMediaControl, FMediaControl);
  if FAILED(Result) then Exit;
  //Запускаем отображение просмотра с вебкамер
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
  // Результат по умолчанию
  Result := E_FAIL;

  // Если  отсутствует интерфейс фильтра перехвата изображения,
  // то завершаем работу
  if FSampleGrabber = NIL then EXIT;

  // Получаем размер кадра
    Result := FSampleGrabber.GetCurrentBuffer(bSize, NIL);
    if (bSize <= 0) or FAILED(Result) then EXIT;
  // Создаем изображение
  Bitmap := vcl.graphics.TBitmap.Create;
  try
  // Получаем тип медиа потока на входе у фильтра перехвата
  ZeroMemory(@MediaType, sizeof(TAMMediaType));
  Result := FSampleGrabber.GetConnectedMediaType(MediaType);
  if FAILED(Result) then EXIT;

    // Копируем заголовок изображения
    pVideoHeader := TVideoInfoHeader(MediaType.pbFormat^);
    ZeroMemory(@BitmapInfo, sizeof(TBitmapInfo));
    CopyMemory(@BitmapInfo.bmiHeader, @pVideoHeader.bmiHeader, sizeof(TBITMAPINFOHEADER));

    Buffer := NIL;

    // Создаем побитовое изображение
    Bitmap.Handle := CreateDIBSection(0, BitmapInfo, DIB_RGB_COLORS, Buffer, 0, 0);

    // Выделяем память во временном массиве
    SetLength(tmp, bSize);

    try
      // Читаем изображение из медиа потока во временный буфер
      FSampleGrabber.GetCurrentBuffer(bSize, @tmp[0]);

      // Копируем данные из временного буфера в наше изображение
      CopyMemory(Buffer, @tmp[0], MediaType.lSampleSize);

      //помещаем изображение на canvas image1
      image1.Picture.Bitmap:=Bitmap;
      image1.Picture.SaveToFile(path);
    except

      // В случае сбоя возвращаем ошибочный результат
      Result := E_FAIL;
    end;
  finally
    // Освобождаем память
    SetLength(tmp, 0);
    Bitmap.Free;
  end;
end;

constructor TWebCam.create;
begin
  fDevicesLst := TStringList.create;
  image1 := TImage.Create(nil);

  //загружаем настройки из ini файла
  CoInitialize(nil);// инициализировать OLE COM
  //вызываем процедуру поиска и инициализации устройств захвата видео и звука
  if FAILED(Initializ) then
    Begin
      raise Exception.Create('Произошла ошибка при инициализации');
      Exit;
    End;
  //проверяем найденный список устройств
  if fDevicesLst.Count = 0 then

                    raise Exception.Create('Камера не обнаружена.');

        //если необходимые для работы устройства найдены,
        //то вызываем процедуру построения графа фильтров
//        if FAILED(CreateGraph) then
//            Begin
//              raise Exception.Create('Произошла ошибка при построении графа фильтров');
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
        aErrorMessage := 'Произошла ошибка при построении графа фильтров';
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

exports //Вот эта секция и указывает компилятору что записать в таблицу экспорта
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
