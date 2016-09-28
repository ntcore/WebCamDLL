# WebCamDLL
dll for capture from webcam src



procedure CreateObject_(devIndex:Integer); external 'WebCam.dll' name 'CreateObject';
procedure ReleaseObject_; external 'WebCam.dll' name 'ReleaseObject';

function getDevicesLst_:string; external 'WebCam.dll' name 'getDevicesLst';
function CaptureAndSaveBitmap(Path:string) :boolean; external 'WebCam.dll' name 'CaptureAndSaveBitmap';

function CreateCapSaveRelease(aDeviceIndex:integer; aSaveFilePath:string):boolean; external 'WebCam.dll' name 'CreateCapSaveRelease';

function getErrorText_:string; external 'WebCam.dll' name 'getErrorText';
function runOptions_:string; external 'WebCam.dll' name 'runOptions';
