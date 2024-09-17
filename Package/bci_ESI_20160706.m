function varargout = bci_ESI_20160706(varargin)
% BCI_ESI_20160706 MATLAB code for bci_ESI_20160706.fig
%      BCI_ESI_20160706, by itself, creates a new BCI_ESI_20160706 or raises the existing
%      singleton*.
%
%      H = BCI_ESI_20160706 returns the handle to a new BCI_ESI_20160706 or the handle to
%      the existing singleton*.
%
%      BCI_ESI_20160706('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BCI_ESI_20160706.M with the given input arguments.
%
%      BCI_ESI_20160706('Property','value',...) creates a new BCI_ESI_20160706 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bci_ESI_20160706_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bci_ESI_20160706_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help bci_ESI_20160706

% Last Modified by GUIDE v2.5 19-May-2017 17:08:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bci_ESI_20160706_OpeningFcn, ...
                   'gui_OutputFcn',  @bci_ESI_20160706_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before bci_ESI_20160706 is made visible.
function bci_ESI_20160706_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bci_ESI_20160706 (see VARARGIN)

% Choose default command line output for bci_ESI_20160706
handles.output=hObject;
% setesi(hObject,'Units','pixels','Position',[50 50 1000 2250]) 

% UIWAIT makes bci_ESI_20160706 wait for user response (see UIRESUME)
% uiwait(handles.bci_ESI_20160706);

handles.axes(1).position=get(handles.axes1,'Position');
handles.axes(2).position=get(handles.axes2,'Position');
handles.axes(3).position=get(handles.axes3,'Position');
axes(handles.axes1); colorbar
handles.axes(1).positioncb=get(handles.axes1,'Position');
colorbar('off'); set(handles.axes1,'Position',handles.axes(1).position);
axes(handles.axes2); colorbar
handles.axes(2).positioncb=get(handles.axes2,'Position');
colorbar('off'); set(handles.axes2,'Position',handles.axes(2).position);
axes(handles.axes3); colorbar
handles.axes(3).positioncb=get(handles.axes3,'Position');
colorbar('off'); set(handles.axes3,'Position',handles.axes(3).position);
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);


% DISPLAY SYSTEM PANEL FIRST
set(handles.panelsystem,'visible','on');
set(handles.panelssvep,'visible','on');
set(handles.panelesi,'visible','off');
set(handles.panelclassifier,'visible','off');
set(handles.panelbci,'visible','off');


% ESTABLISH CUSTOM DEFAULT HANDLES
[hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,[]);

% AUTOMATICALLY FILL IN DATE INFO
format shortg
c=clock;
set(handles.year,'backgroundcolor','green','string',num2str(c(1)))
if size(num2str(c(2)),2)<2
    m=strcat('0',num2str(c(2)));
else
    m=num2str(c(2));
end
set(handles.month,'backgroundcolor','green','string',m)
if size(num2str(c(3)),2)<2
    d=strcat('0',num2str(c(3)));
else
    d=num2str(c(3));
end
set(handles.day,'backgroundcolor','green','string',d)

% AUTOMATICALLY SET SAVEPATH
[filepath,filename,fileext]=fileparts(which('bci_ESI_20160706.m'));
savepath=strcat(filepath,'\Data');
if ~exist(savepath,'dir')
    mkdir(savepath)
end
set(handles.savepath,'backgroundcolor','green','string',savepath)

handles.SYSTEM.rootdir=filepath;

guidata(hObject,handles)


% --- Outputs from this function are returned to the command line.
function varargout = bci_ESI_20160706_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function test_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bci_ESI_20160706 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function panelsubject_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelsubject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called  
    
% --- Executes during object creation, after setting all properties.
function panelsystemtoggle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelsystemtoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% --- Executes during object creation, after setting all properties.

% --- Executes during object creation, after setting all properties.
function panelsystem_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelsystem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function panelbci_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelbci (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function uipanel3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function panelesi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelesi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function panelclassifier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelclassifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function paneldispfiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to paneldispfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function Axis1Label_Callback(hObject, eventdata, handles)
% hObject    handle to Axis1Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of Axis1Label as text
%        str2double(get(hObject,'string')) returns contents of Axis1Label as a double

% --- Executes during object creation, after setting all properties.
function Axis1Label_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Axis1Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function Axis2Label_Callback(hObject, eventdata, handles)
% hObject    handle to Axis2Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of Axis2Label as text
%        str2double(get(hObject,'string')) returns contents of Axis2Label as a double

% --- Executes during object creation, after setting all properties.
function Axis2Label_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Axis2Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function Axis3Label_Callback(hObject, eventdata, handles)
% hObject    handle to Axis3Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of Axis3Label as text
%        str2double(get(hObject,'string')) returns contents of Axis3Label as a double

% --- Executes during object creation, after setting all properties.
function Axis3Label_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Axis3Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                  PANELS                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in panelsystemtoggle.
function panelsystemtoggle_Callback(hObject, eventdata, handles)
% hObject    handle to panelsystemtoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panelesi,'visible','off')
set(handles.panelclassifier,'visible','off')
set(handles.panelbci,'visible','off')
set(handles.panelsystem,'visible','off')
pause(.2)
set(handles.panelsystem,'visible','on')


% --- Executes on button press in panelesitoggle.
function panelesitoggle_Callback(hObject, eventdata, handles)
% hObject    handle to panelesitoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panelsystem,'visible','off')
set(handles.panelclassifier,'visible','off')
set(handles.panelbci,'visible','off')
pause(.2)
set(handles.panelesi,'visible','on')


% --- Executes on button press in panelclassifiertoggle.
function panelclassifiertoggle_Callback(hObject, eventdata, handles)
% hObject    handle to panelclassifiertoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panelsystem,'visible','off')
set(handles.panelesi,'visible','off')
set(handles.panelbci,'visible','off')
pause(.1)
set(handles.panelclassifier,'visible','on')


% --- Executes on button press in panelbcitoggle.
function panelbcitoggle_Callback(hObject, eventdata, handles)
% hObject    handle to panelbcitoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panelsystem,'visible','off')
set(handles.panelesi,'visible','off')
set(handles.panelclassifier,'visible','off')
pause(.1)
set(handles.panelbci,'visible','on')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           SUBJECT INFORMATION                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in LoadESIParam.
function LoadESIParam_Callback(hObject, eventdata, handles)
% hObject    handle to LoadESIParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
guidata(hObject,handles)

function initials_Callback(hObject, eventdata, handles)
% hObject    handle to initials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of initials as text
%        str2double(get(hObject,'string')) returns contents of initials as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
[hObject,handles]=bci_ESI_Initials(hObject,handles);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function initials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function session_Callback(hObject, eventdata, handles)
% hObject    handle to session (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of session as text
%        str2double(get(hObject,'string')) returns contents of session as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
cfg=struct('varname','SESSION','defaultnum','','lowbound',1);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function session_CreateFcn(hObject, eventdata, handles)
% hObject    handle to session (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of run as text
%        str2double(get(hObject,'string')) returns contents of run as a double
% [hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
cfg=struct('varname','RUN','defaultnum','','lowbound',1);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function run_CreateFcn(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function year_Callback(hObject, eventdata, handles)
% hObject    handle to year (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of year as text
%        str2double(get(hObject,'string')) returns contents of year as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
cfg=struct('varname','YEAR','defaultnum','','lowbound',1,'length',4);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function year_CreateFcn(hObject, eventdata, handles)
% hObject    handle to year (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function month_Callback(hObject, eventdata, handles)
% hObject    handle to month (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of month as text
%        str2double(get(hObject,'string')) returns contents of month as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
cfg=struct('varname','MONTH','defaultnum','','lowbound',1);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function month_CreateFcn(hObject, eventdata, handles)
% hObject    handle to month (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function day_Callback(hObject, eventdata, handles)
% hObject    handle to day (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of day as text
%        str2double(get(hObject,'string')) returns contents of day as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
cfg=struct('varname','DAY','defaultnum','','lowbound',1);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function day_CreateFcn(hObject, eventdata, handles)
% hObject    handle to day (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in savepath.
function savepath_Callback(hObject, eventdata, handles)
% hObject    handle to savepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
oldsavepath=get(hObject,'string');
rootdir=handles.SYSTEM.rootdir;
newsavepath=uigetdir(rootdir);
if isequal(newsavepath,0) && isequal(oldsavepath,0)
    set(hObject,'backgroundcolor','red','string','')
elseif isequal(newsavepath,0) && ~isequal(oldsavepath,0)
    set(hObject,'backgroundcolor','white','string',oldsavepath)
else
    set(hObject,'backgroundcolor','white','string',newsavepath)
end
guidata(hObject,handles)




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           SYSTEM PARAMETERS                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in tempdomain.
function tempdomain_Callback(hObject, eventdata, handles)
% hObject    handle to tempdomain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns tempdomain contents as cell array
%        contents{get(hObject,'value')} returns selected item from tempdomain
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);


% --- Executes during object creation, after setting all properties.
function tempdomain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tempdomain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in spatdomain.
function spatdomain_Callback(hObject, eventdata, handles)
% hObject    handle to spatdomain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns spatdomain contents as cell array
%        contents{get(hObject,'value')} returns selected item from spatdomain
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
[hObject,handles]=bci_ESI_SpatDomain(hObject,handles);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function spatdomain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spatdomain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in eegsystem.
function eegsystem_Callback(hObject, eventdata, handles)
% hObject    handle to eegsystem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns eegsystem contents as cell array
%        contents{get(hObject,'value')} returns selected item from eegsystem
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
[hObject,handles]=bci_ESI_SelectEEGsystem(hObject,handles);
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'eegsystem'},'on');
set(handles.selectsensors,'userdata',[]);
set(handles.defaultanatomy,'value',0)
defaultanatomy_Callback(hObject, eventdata, handles)
[hObject,handles]=bci_ESI_DataList(hObject,handles,'Clear','esifiles');
[hObject,handles]=bci_ESI_DataList(hObject,handles,'Clear','trainfiles');
[hObject,handles]=bci_ESI_SpatDomain(hObject,handles);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function eegsystem_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eegsystem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function fs_Callback(hObject, eventdata, handles)
% hObject    handle to fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of fs as text
%        str2double(get(hObject,'string')) returns contents of fs as a double

% --- Executes during object creation, after setting all properties.
function fs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end

% --- Executes on button press in selectsensors.
function selectsensors_Callback(hObject, eventdata, handles)
% hObject    handle to selectsensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
[hObject,handles]=bci_ESI_SelectSensors(hObject,handles);
guidata(hObject,handles)


function dsfactor_Callback(hObject, eventdata, handles)
% hObject    handle to dsfactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of dsfactor as text
%        str2double(get(hObject,'string')) returns contents of dsfactor as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
cfg=struct('varname','DOWNSAMPLE_FACTOR','defaultnum','1','lowbound',1,'highbound',8,'length',1);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'dsfactor'},'on');
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function dsfactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dsfactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in freqtrans.
function freqtrans_Callback(hObject, eventdata, handles)
% hObject    handle to freqtrans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns freqtrans contents as cell array
%        contents{get(hObject,'value')} returns selected item from freqtrans
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'freqtrans'},'on');
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function freqtrans_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqtrans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function lowcutoff_Callback(hObject, eventdata, handles)
% hObject    handle to lowcutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of lowcutoff as text
%        str2double(get(hObject,'string')) returns contents of lowcutoff as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
if ~isempty(get(handles.fs,'string'))
    cfg=struct('varname','LOW_CUTOFF','defaultnum','','length',3,'lowbound',0);
    if ~isnan(str2double(get(handles.highcutoff,'string')))
        cfg.highbound=str2double(get(handles.highcutoff,'string'))-2;
    else
        cfg.highbound=round(str2double(get(handles.fs,'string'))/2)-1;
    end
    [hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
end
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'lowcutoff'},'on');
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function lowcutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowcutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function highcutoff_Callback(hObject, eventdata, handles)
% hObject    handle to highcutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of highcutoff as text
%        str2double(get(hObject,'string')) returns contents of highcutoff as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
if ~isempty(get(handles.fs,'string'))
    cfg=struct('varname','HIGH_CUTOFF','defaultnum','','length',3,...
        'highcutoff',round(str2double(get(handles.fs,'string'))/2));
    if ~isnan(str2double(get(handles.lowcutoff,'string')))
        cfg.lowbound=str2double(get(handles.lowcutoff,'string'))+1;
    else
        cfg.lowbound=2;
    end
    [hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
end
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'highcutoff'},'on');
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function highcutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to highcutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end

% --- Executes on button press in broadband.
function broadband_Callback(hObject, eventdata, handles)
% hObject    handle to broadband (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of broadband


function analysiswindow_Callback(hObject, eventdata, handles)
% hObject    handle to analysiswindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of analysiswindow as text
%        str2double(get(hObject,'string')) returns contents of analysiswindow as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[1,2]);
cfg=struct('varname','ANALYSIS_WINDOW','defaultnum','','lowbound',150,'highbound',5000,'length',4);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'analysiswindow'},'on');
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function analysiswindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to analysiswindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function updatewindow_Callback(hObject, eventdata, handles)
% hObject    handle to updatewindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of updatewindow as text
%        str2double(get(hObject,'string')) returns contents of updatewindow as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[1,2]);
cfg=struct('varname','UPDATE_WINDOW','defaultnum','','lowbound',60,'highbound',1000,'length',4);
if ~isempty(get(handles.analysiswindow,'string'))
    cfg.highbound=str2double(get(handles.analysiswindow,'string'));
end
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'updatewindow'},'on');
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function updatewindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to updatewindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             SSVEP PARAMETERS                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in ssvepon.
function ssvepon_Callback(hObject, eventdata, handles)
% hObject    handle to ssvepon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ssvepon
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
guidata(hObject,handles)

function decisionwindow_Callback(hObject, eventdata, handles)
% hObject    handle to decisionwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of decisionwindow as text
%        str2double(get(hObject,'String')) returns contents of decisionwindow as a double
cfg=struct('varname','DECISION_WINDOW','defaultnum','','lowbound',60,'highbound',4000,'length',4);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
[hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'decisionwindow'},'on');
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function decisionwindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to decisionwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectsensorsssvep.
function selectsensorsssvep_Callback(hObject, eventdata, handles)
% hObject    handle to selectsensorsssvep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_SelectSensorsSSVEP(hObject,handles);
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function ssveptarget_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ssveptarget (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when entered data in editable cell(s) in ssveptarget.
function ssveptarget_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to ssveptarget (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
idx=eventdata.Indices;
row=idx(1); col=idx(2);

data=get(hObject,'Data');
input=data{row,col};

if isequal(col,1) % Target Label
    
    targetbank={'1' '2' '3' '4',...
        'Rock' 'Paper' 'Scissors' 'rock' 'paper' 'scissors',...
        'Left' 'Right' 'Forward' 'Back' 'left' 'right' 'forward' 'back'};
    if ~ismember(input,targetbank)
        data{row,col}='';
    end
    
elseif isequal(col,2) % Target Hit Criteria
    
    targetbank={'1' '2' '3' '4',...
        'Rock' 'Paper' 'Scissors' 'rock' 'paper' 'scissors',...
        'Left' 'Right' 'Forward' 'Back' 'left' 'right' 'forward' 'back'};
    if ~ismember(input,targetbank)
        data{row,col}='';
    end

elseif isequal(col,3) % Frequency Tag
    
    cfg=struct('varname',['Task_' num2str(row) '_FREQUENCY_TAG'],'defaultnum','','lowbound',1,'highbound',30,'length',4);
    lowcutoff=str2double(get(handles.lowcutoff,'string'));
    if ~isnan(lowcutoff); cfg.lowbound=lowcutoff; end
    highcutoff=str2double(get(handles.highcutoff,'string'));
    
    if ~isnan(highcutoff); cfg.highbound=floor(highcutoff/2); end
    [hObject,handles,output]=bci_ESI_EnterNumTable(hObject,handles,cfg,input);
    data{row,col}=output;
    
elseif isequal(col,4)
    
    [filename,pathname]=uigetfile({'*.png';'*.jpg'},strcat(handles.SYSTEM.rootdir,'from_Brad\bci_fESI_Stimulus'));
    if ~isequal(filename,0) && ~isequal(pathname,0)
        data{row,col}=strcat(pathname,filename);
    else
        data{row,col}='';
    end
    
end
set(hObject,'Data',data)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
guidata(hObject,handles)


% --- Executes when selected cell(s) is changed in ssveptarget.
function ssveptarget_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to ssveptarget (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in nuissancefreq.
function nuissancefreq_Callback(hObject, eventdata, handles)
% hObject    handle to nuissancefreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of nuissancefreq
[hObject,handles]=bci_ESI_Reset(hObject,handles,'System',[]);
guidata(hObject,handles)

% --- Executes on button press in SetSystem.
function SetSystem_Callback(hObject, eventdata, handles)
% hObject    handle to SetSystem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
[hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,'Source',[],[]);
TempDomain=get(handles.tempdomain,'value');
switch TempDomain
    case 1 % None
    case 2 % Frequency
        [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,'Sensor',[],'Freq');
    case 3 % Time
        [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,'Sensor',[],'Time');
end
handles.BCI.featuretypes.sensor=cellstr('');
handles.BCI.featuretypes.source=cellstr('');
[hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,{'ESI','TRAINING','BCI'});
[hObject,handles]=bci_ESI_GetInfo(hObject,handles,'SYSTEM');
guidata(hObject,handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        SOURCE IMAGING PARAMETERS                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in defaultanatomy.
function defaultanatomy_Callback(hObject, eventdata, handles)
% hObject    handle to defaultanatomy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of defaultanatomy
spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
end
[hObject,handles]=bci_ESI_DefaultAnatomy(hObject,handles);

guidata(hObject,handles)


% --- Executes on button press in cortexfile.
function cortexfile_Callback(hObject, eventdata, handles)
% hObject    handle to cortexfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.cortexfile=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'cortexfile'},'on');
end

guidata(hObject,handles)


% --- Executes on button press in cortexlrfile.
function cortexlrfile_Callback(hObject, eventdata, handles)
% hObject    handle to cortexlrfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.cortexlrfile=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'cortexlrfile'},'on');
end

guidata(hObject,handles)


% --- Executes on button press in headmodelfile.
function headmodelfile_Callback(hObject, eventdata, handles)
% hObject    handle to headmodelfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.headmodelfile=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'headmodelfile'},'on');
end

guidata(hObject,handles)


% --- Executes on button press in fmrifile.
function fmrifile_Callback(hObject, eventdata, handles)
% hObject    handle to fmrifile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.fmrifile=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'fmrifile'},'on');
end

guidata(hObject,handles)


function fMRIWeightDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to fMRIWeightDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of fMRIWeightDisplay as text
%        str2double(get(hObject,'string')) returns contents of fMRIWeightDisplay as a double
% If slide bar adjusted, setesi new value in text window...if bci_ESI_20160706 window
% adjusted, adjust slide bar
value=get(handles.fmriweight,'value');
set(hObject,'string',num2str(value));

guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function fMRIWeightDisplay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fMRIWeightDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on slider movement.
function fmriweight_Callback(hObject, eventdata, handles)
% hObject    handle to fmriweight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_fESI_Reset(hObject,handles,'ESI',[]);
end
value=get(hObject,'value');
% Make sure slider can only be integers betwen 0 and 99
value=round(value);
if isequal(value,100)
    value=99;
end
set(hObject,'value',value);
set(handles.fMRIWeightDisplay,'string',value);

guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function fmriweight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fmriweight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor',[.9 .9 .9]);
end


function brainregionfile_Callback(hObject, eventdata, handles)
% hObject    handle to brainregionfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of brainregionfile as text
%        str2double(get(hObject,'string')) returns contents of brainregionfile as a double
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.brainregionfile=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'brainregionfile'},'on');
end

guidata(hObject,handles)


% --- Executes on button press in selectbrainregions.
function selectbrainregions_Callback(hObject, eventdata, handles)
% hObject    handle to selectbrainregions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
[hObject,handles]=bci_ESI_SelectBrainRegions(hObject,handles);

guidata(hObject,handles)

% --- Executes on button press in roifile.
function roifile_Callback(hObject, eventdata, handles)
% hObject    handle to roifile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.roifile=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'roifile'},'on');
end

guidata(hObject,handles)


% --- Executes on selection change in parcellation.
function parcellation_Callback(hObject, eventdata, handles)
% hObject    handle to parcellation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns parcellation contents as cell array
%        contents{get(hObject,'value')} returns selected item from parcellation
spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    
    parcellation=get(hObject,'value');
    fields={'parcellation'};
    if isequal(parcellation,1)
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'off');
    else
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'on');
    end
    
end


% --- Executes during object creation, after setting all properties.
function parcellation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parcellation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes during object creation, after setting all properties.
function esifiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to esifiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes when entered data in editable cell(s) in esifiles.
function esifiles_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to esifiles (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'data');
idx=eventdata.Indices;
row=idx(1); col=idx(2);
datatmp=eventdata.EditData;

if isequal(col,2)
    
    if strcmp(datatmp,' ') || strcmp(datatmp,'  ')
        
        [filename,pathname]=uigetfile('MultiSelect','on',{'*.mat';'*.Dat'});
        if ~isequal(filename,0) && ~isequal(pathname,0)
            data{row,col}=strcat(pathname,filename);
        else
            data{row,col}='';
        end
        
    else
        data{row,col}=eventdata.EditData;
    end
    
elseif isequal(col,1)
    
    data{row,col}=eventdata.EditData;
    
end
set(hObject,'data',data)
guidata(hObject,handles)


% --- Executes on button press in copyesi.
function copyesi_Callback(hObject, eventdata, handles)
% hObject    handle to copyesi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_DataList(hObject,handles,'Copy','esifiles','trainfiles');
guidata(hObject,handles)


% --- Executes on selection change in noise.
function noise_Callback(hObject, eventdata, handles)
% hObject    handle to noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns noise contents as cell array
%        contents{get(hObject,'value')} returns selected item from noise
[hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
[hObject,handles]=bci_ESI_Noise(hObject,handles);

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'noise'},'on');
end

guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function noise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in noisefile.
function noisefile_Callback(hObject, eventdata, handles)
% hObject    handle to noisefile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subj=get(handles.initials,'string');
rootdir=handles.SYSTEM.rootdir;
[filename,pathname]=uigetfile(strcat(rootdir,'\from_Brad',subj,'\*.mat*'));
if ~isequal(filename,0) && ~isequal(pathname,0)
    set(hObject,'string',strcat(pathname,filename));
    handles.default.noisedata=strcat(pathname,filename);
end

spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'ESI',[]);
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'noisedata'},'on');
end

guidata(hObject,handles)


% --- Executes on button press in StartNoise.
function StartNoise_Callback(hObject, eventdata, handles)
% hObject    handle to StartNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_RunNoise(hObject,handles);
guidata(hObject,handles)


% --- Executes on button press in vizsource.
function vizsource_Callback(hObject, eventdata, handles)
% hObject    handle to vizsource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of vizsource
spatdomain=get(handles.spatdomain,'value');
switch spatdomain
    case {1,2} % None/Sensor
        set(hObject,'value',0);
    case {3,4} % ESI/fESI
        value=get(hObject,'value');
        if isequal(value,0)
            set(handles.lrvizsource,'value',0);
            set(handles.cortexlrfile,'backgroundcolor','white')
        end
end

guidata(hObject,handles)

% --- Executes on button press in lrvizsource.
function lrvizsource_Callback(hObject, eventdata, handles)
% hObject    handle to lrvizsource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of lrvizsource
spatdomain=get(handles.spatdomain,'value');
if isequal(spatdomain,3)
    [hObject,handles]=bci_fESI_Reset(hObject,handles,'ESI',[]);
    vizsource=get(handles.vizsource,'value');
    if isequal(vizsource,0)
        set(hObject,'value',0);
    end
end

LRVizSource=get(hObject,'value');
CortexLR=get(handles.cortexlrfile,'string');
set(handles.cortexlrfile,'backgroundcolor','white')
if isequal(LRVizSource,1) && isempty(CortexLR)
    set(handles.cortexlrfile,'backgroundcolor','red')
end
guidata(hObject,handles)


% --- Executes on button press in info3.
function info3_Callback(hObject, eventdata, handles)
% hObject    handle to info3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f=figure('Position', [500, 500, 200, 225]);
set(f,'MenuBar','none');
set(f,'ToolBar','none');
set(gcf,'color',[.94 .94 .94]);
btn=uicontrol('style','pushbutton','string','Close','Position',...
    [75 10 50 20],'Callback', 'close');
text1=uicontrol('style','text');
set(text1,'string','Low resolution (LR) source visualization recommended over normal visualization','Position',...
    [2 100 196 125])
text2=uicontrol('style','text');
set(text2,'string','Normal source vizualization should only be selected for replay','Position',...
    [2 100 196 50])
text3=uicontrol('style','text');
set(text3,'string','LR visualization can take ~20-30ms and cause processing delays','Position',...
    [2 35 196 50])


% --- Executes on button press in CheckESI.
function CheckESI_Callback(hObject, eventdata, handles)
% hObject    handle to CheckESI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,'Source',[],[]);
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
[hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,...
    {'TRAINING SOURCE','TRAINING SOURCE CLUSTER','ESI'});
[hObject,handles]=bci_ESI_CheckESI(hObject,handles);
guidata(hObject,handles)


% --- Executes on button press in SetESI.
function SetESI_Callback(hObject, eventdata, handles)
% hObject    handle to SetESI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,'Source',[],[]);
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[1,2]);
[hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,...
    {'TRAINING SOURCE','TRAINING SOURCE CLUSTER'});
[hObject,handles]=bci_ESI_SetESI(hObject,handles);
guidata(hObject,handles)


% --- Executes on button press in DispElecCurrent.
function DispElecCurrent_Callback(hObject, eventdata, handles)
% hObject    handle to DispElecCurrent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.SYSTEM.Electrodes.current.eLoc)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[1,2]);
    eLoc=handles.SYSTEM.Electrodes.current.eLoc;
    axes(handles.axes3); cla
    set(handles.Axis3Label,'string','Current Electrode Montage');
    hold off; view(2); colorbar off; rotate3d off
    topoplot([],eLoc,'electrodes','ptlabels','headrad',.5);
    set(gcf,'color',[.94 .94 .94]); title('')
else
    fprintf(2,'MUST SET SYSTEM PARAMETERS TO PLOT CURRENT ELECTRODES\n');
end

% --- Executes on button press in DispElecOrig.
function DispElecOrig_Callback(hObject, eventdata, handles)
% hObject    handle to DispElecOrig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.Electrodes.original.eLoc) 
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[1,2]);
    eLoc=handles.Electrodes.original.eLoc;
    axes(handles.axes3); cla
    set(handles.Axis3Label,'string','Original Electrode Montage');
    hold off; view(2); colorbar off; rotate3d off
    topoplot([],eLoc,'electrodes','ptlabels','headrad',.5);
    set(gcf,'color',[.94 .94 .94]); title('')
else
    fprintf(2,'MUST SELECT EEG SYSTEM TO PLOT ORIGINAL ELECTRODES\n');
end


function senspikes_Callback(hObject, eventdata, handles)
% hObject    handle to senspikes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of senspikes as text
%        str2double(get(hObject,'string')) returns contents of senspikes as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',0);
cfg.varname='SPIKES'; cfg.defaultnum=''; cfg.lowbound=1;
cfg.highbound=size(handles.SYSTEM.Electrodes.chanidxinclude,2);
cfg.numbers=size(handles.SYSTEM.Electrodes.chanidxinclude,1);
cfg.highbound=size(handles.SYSTEM.Electrodes.chanidxinclude,1);
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function senspikes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to senspikes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in testsource.
function testsource_Callback(hObject, eventdata, handles)
% hObject    handle to testsource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
[hObject,handles]=bci_ESI_TestSource(hObject,handles);
guidata(hObject,handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            TRAIN PARAMETERS                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in baselinetype.
function baselinetype_Callback(hObject, eventdata, handles)
% hObject    handle to baselinetype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns baselinetype contents as cell array
%        contents{get(hObject,'Value')} returns selected item from baselinetype
baselinetype=get(handles.baselinetype,'value');
if ismember(baselinetype,[2 3])
    set(handles.baselinestart,'backgroundcolor','white','string','');
    set(handles.baselineend,'backgroundcolor','white','string','');
end

% --- Executes during object creation, after setting all properties.
function baselinetype_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baselinetype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in normtype.
function normtype_Callback(hObject, eventdata, handles)
% hObject    handle to normtype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns normtype contents as cell array
%        contents{get(hObject,'Value')} returns selected item from normtype

% --- Executes during object creation, after setting all properties.
function normtype_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normtype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function baselinestart_Callback(hObject, eventdata, handles)
% hObject    handle to baselinestart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baselinestart as text
%        str2double(get(hObject,'String')) returns contents of baselinestart as a double
baselinetype=get(handles.baselinetype,'value');
if isequal(baselinetype,2)
    
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
    
    cfg=struct('varname','BASELINE_START','defaultnum','','lowbound',-1);
    baselineend=str2double(get(handles.baselineend,'string'));
    if ~isnan(baselineend)
        cfg.highbound=baselineend-.1;
    else
        cfg.highbound=-.1;
    end
    
elseif isequal(baselinetype,3)
    
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
    
    cfg=struct('varname','BASELINE_START','defaultnum','0','lowbound',0);
    baselineend=str2double(get(handles.baselineend,'string'));
    if ~isnan(baselineend)
        cfg.lowbound=baselineend;
    else
        cfg.lowbound=0;
    end
    
else
    cfg=struct('varname','BASELINE_START','defaultnum','');
end

[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function baselinestart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baselinestart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function baselineend_Callback(hObject, eventdata, handles)
% hObject    handle to baselineend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baselineend as text
%        str2double(get(hObject,'String')) returns contents of baselineend as a double
baselinetype=get(handles.baselinetype,'value');
if isequal(baselinetype,2)
    
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);

    cfg=struct('varname','BASELINE_END','defaultnum','','highbound',0);
    baselinestart=str2double(get(handles.baselinestart,'value'));
    if ~isnan(baselinestart)
        cfg.lowbound=baselinestart;
    else
        cfg.lowbound=-1;
    end
    
elseif isequal(baselinetype,3)
    
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
    
    cfg=struct('varname','BASELINE_END','defaultnum','Max','highbound',inf);
    baselinestart=str2double(get(handles.baselinestart,'string'));
    if ~isnan(baselinestart)
        cfg.lowbound=baselinestart;
    else
        cfg.lowbound=0;
    end
    
else
    cfg=struct('varname','BASELINE_END','defaultnum','');
end

[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function baselineend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baselineend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function trainfiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trainfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when entered data in editable cell(s) in trainfiles.
function trainfiles_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to trainfiles (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'data');
idx=eventdata.Indices;
row=idx(1); col=idx(2);
datatmp=eventdata.EditData;
if isequal(col,2)
    
    if strcmp(datatmp,' ') || strcmp(datatmp,'  ')
        
        [filename,pathname]=uigetfile('MultiSelect','on',{'*.mat';'*.Dat'});
        if ~isequal(filename,0) && ~isequal(pathname,0)
            data{row,col}=strcat(pathname,filename);
        else
            data{row,col}='';
        end
        
    else
        data{row,col}=eventdata.EditData;
    end
    
elseif isequal(col,1)
    
    data{row,col}=eventdata.EditData;
    
end
set(hObject,'data',data);
guidata(hObject,handles)


% --- Executes on button press in copytrain.
function copytrain_Callback(hObject, eventdata, handles)
% hObject    handle to copytrain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_DataList(hObject,handles,'Copy','trainfiles','esifiles');
guidata(hObject,handles)


% --- Executes on selection change in traintype.
function traintype_Callback(hObject, eventdata, handles)
% hObject    handle to traintype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns traintype contents as cell array
%        contents{get(hObject,'value')} returns selected item from traintype
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
set(handles.freqfeatfreq,'backgroundcolor','white','value',1)
set(handles.freqfeatlambda,'backgroundcolor','white','value',1)
set(handles.timefeatwindow,'backgroundcolor','white','value',1)
set(handles.timefeatlambda,'backgroundcolor','white','value',1)
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function traintype_CreateFcn(hObject, eventdata, handles)
% hObject    handle to traintype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in checkvar.
function checkvar_Callback(hObject, eventdata, handles)
% hObject    handle to checkvar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_CheckVar(hObject,handles);
guidata(hObject,handles)


% --- Executes on button press in train.
function train_Callback(hObject, eventdata, handles)
% hObject    handle to train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
[hObject,handles]=bci_ESI_TrainClassifier(hObject,handles,'SMR');
guidata(hObject,handles)


% --- Executes on button press in LoadClass.
function LoadClass_Callback(hObject, eventdata, handles)
% hObject    handle to LoadClass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_fESI_RegressionLoad(hObject,handles);
guidata(hObject,handles)


% --- Executes on selection change in freqfeat.
function freqfeat_Callback(hObject, eventdata, handles)
% hObject    handle to freqfeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns freqfeat contents as cell array
%        contents{get(hObject,'value')} returns selected item from freqfeat

% --- Executes during object creation, after setting all properties.
function freqfeat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqfeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in freqfeatfreq.
function freqfeatfreq_Callback(hObject, eventdata, handles)
% hObject    handle to freqfeatfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns freqfeatfreq contents as cell array
%        contents{get(hObject,'value')} returns selected item from freqfeatfreq

% --- Executes during object creation, after setting all properties.
function freqfeatfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqfeatfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in freqfeatlambda.
function freqfeatlambda_Callback(hObject, eventdata, handles)
% hObject    handle to freqfeatlambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns freqfeatlambda contents as cell array
%        contents{get(hObject,'value')} returns selected item from freqfeatlambda

% --- Executes during object creation, after setting all properties.
function freqfeatlambda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqfeatlambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in freqfeatgamma.
function freqfeatgamma_Callback(hObject, eventdata, handles)
% hObject    handle to freqfeatgamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns freqfeatgamma contents as cell array
%        contents{get(hObject,'value')} returns selected item from freqfeatgamma

% --- Executes during object creation, after setting all properties.
function freqfeatgamma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqfeatgamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in freqfeatpc.
function freqfeatpc_Callback(hObject, eventdata, handles)
% hObject    handle to freqfeatpc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns freqfeatpc contents as cell array
%        contents{get(hObject,'value')} returns selected item from freqfeatpc

% --- Executes during object creation, after setting all properties.
function freqfeatpc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqfeatpc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in dispfreqfeat.
function dispfreqfeat_Callback(hObject, eventdata, handles)
% hObject    handle to dispfreqfeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
[hObject,handles]=bci_ESI_DispFreqFeat(hObject,handles);
guidata(hObject,handles)


% --- Executes on selection change in timefeat.
function timefeat_Callback(hObject, eventdata, handles)
% hObject    handle to timefeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns timefeat contents as cell array
%        contents{get(hObject,'value')} returns selected item from timefeat

% --- Executes during object creation, after setting all properties.
function timefeat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timefeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in timefeatwindow.
function timefeatwindow_Callback(hObject, eventdata, handles)
% hObject    handle to timefeatwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns timefeatwindow contents as cell array
%        contents{get(hObject,'value')} returns selected item from timefeatwindow

% --- Executes during object creation, after setting all properties.
function timefeatwindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timefeatwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in timefeatlambda.
function timefeatlambda_Callback(hObject, eventdata, handles)
% hObject    handle to timefeatlambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns timefeatlambda contents as cell array
%        contents{get(hObject,'value')} returns selected item from timefeatlambda

% --- Executes during object creation, after setting all properties.
function timefeatlambda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timefeatlambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in timefeatpc.
function timefeatpc_Callback(hObject, eventdata, handles)
% hObject    handle to timefeatpc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns timefeatpc contents as cell array
%        contents{get(hObject,'value')} returns selected item from timefeatpc

% --- Executes during object creation, after setting all properties.
function timefeatpc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timefeatpc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in disptimefeat.
function disptimefeat_Callback(hObject, eventdata, handles)
% hObject    handle to disptimefeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
[hObject,handles]=bci_ESI_DispTimeFeat(hObject,handles);
guidata(hObject,handles)


% --- Executes on button press in StartTrainssvep.
function StartTrainssvep_Callback(hObject, eventdata, handles)
% hObject    handle to StartTrainssvep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_RunTrain3(hObject,handles,'SSVEP');
guidata(hObject,handles)


% --- Executes on button press in trainssvep.
function trainssvep_Callback(hObject, eventdata, handles)
% hObject    handle to trainssvep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
[hObject,handles]=bci_ESI_TrainClassifier(hObject,handles,'SSVEP');
guidata(hObject,handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   BRAIN-COMPUTER INTERFACE PARAMETERS                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in paradigm.
function paradigm_Callback(hObject, eventdata, handles)
% hObject    handle to paradigm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns paradigm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from paradigm
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,1,'Reset');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,2,'Reset');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,3,'Reset');
set(hObject,'backgroundcolor','white')
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
[hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,{'Stimulus'});
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function paradigm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to paradigm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in decodescheme.
function decodescheme_Callback(hObject, eventdata, handles)
% hObject    handle to decodescheme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns decodescheme contents as cell array
%        contents{get(hObject,'Value')} returns selected item from decodescheme


% --- Executes during object creation, after setting all properties.
function decodescheme_CreateFcn(hObject, eventdata, handles)
% hObject    handle to decodescheme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in decodeadapt.
function decodeadapt_Callback(hObject, eventdata, handles)
% hObject    handle to decodeadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns decodeadapt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from decodeadapt

% --- Executes during object creation, after setting all properties.
function decodeadapt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to decodeadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in vizelec.
function vizelec_Callback(hObject, eventdata, handles)
% hObject    handle to vizelec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of vizelec
guidata(hObject,handles)


% --- Executes on selection change in bcidim1.
function bcidim1_Callback(hObject, eventdata, handles)
% hObject    handle to bcidim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcidim1 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcidim1
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelect(hObject,handles,'dim',1);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcidim1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcidim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcidim2.
function bcidim2_Callback(hObject, eventdata, handles)
% hObject    handle to bcidim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcidim2 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcidim2
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelect(hObject,handles,'dim',2);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcidim2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcidim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcidim3.
function bcidim3_Callback(hObject, eventdata, handles)
% hObject    handle to bcidim3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcidim3 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcidim3
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelect(hObject,handles,'dim',3);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcidim3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcidim3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcitask1.
function bcitask1_Callback(hObject, eventdata, handles)
% hObject    handle to bcitask1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcitask1 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcitask1
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelect(hObject,handles,'task',1);
set(handles.bciloc1,'backgroundcolor',[.94 .94 .94],'userdata',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcitask1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcitask1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcitask2.
function bcitask2_Callback(hObject, eventdata, handles)
% hObject    handle to bcitask2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcitask2 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcitask2
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelect(hObject,handles,'task',2);
set(handles.bciloc2,'backgroundcolor',[.94 .94 .94],'userdata',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcitask2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcitask2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcitask3.
function bcitask3_Callback(hObject, eventdata, handles)
% hObject    handle to bcitask3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcitask3 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcitask3
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelect(hObject,handles,'task',3);
set(handles.bciloc3,'backgroundcolor',[.94 .94 .94],'userdata',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcitask3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcitask3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcifreq1.
function bcifreq1_Callback(hObject, eventdata, handles)
% hObject    handle to bcifreq1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcifreq1 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcifreq1
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
set(hObject,'backgroundcolor',[.94 .94 .94])
set(handles.bciloc1,'backgroundcolor',[.94 .94 .94],'userdata',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcifreq1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcifreq1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcifreq2.
function bcifreq2_Callback(hObject, eventdata, handles)
% hObject    handle to bcifreq2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcifreq2 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcifreq2
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
set(hObject,'backgroundcolor',[.94 .94 .94])
set(handles.bciloc2,'backgroundcolor',[.94 .94 .94],'userdata',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcifreq2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcifreq2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcifreq3.
function bcifreq3_Callback(hObject, eventdata, handles)
% hObject    handle to bcifreq3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcifreq3 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcifreq3
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
set(hObject,'backgroundcolor',[.94 .94 .94])
set(handles.bciloc3,'backgroundcolor',[.94 .94 .94],'userdata',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcifreq3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcifreq3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcifeat1.
function bcifeat1_Callback(hObject, eventdata, handles)
% hObject    handle to bcifeat1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcifeat1 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcifeat1
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
set(hObject,'backgroundcolor',[.94 .94 .94])
set(handles.bciloc1,'userdata',[])
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcifeat1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcifeat1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcifeat2.
function bcifeat2_Callback(hObject, eventdata, handles)
% hObject    handle to bcifeat2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcifeat2 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcifeat2
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
set(hObject,'backgroundcolor',[.94 .94 .94])
set(handles.bciloc2,'userdata',[])
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcifeat2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcifeat2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on selection change in bcifeat3.
function bcifeat3_Callback(hObject, eventdata, handles)
% hObject    handle to bcifeat3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns bcifeat3 contents as cell array
%        contents{get(hObject,'value')} returns selected item from bcifeat3
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
set(hObject,'backgroundcolor',[.94 .94 .94])
set(handles.bciloc3,'userdata',[])
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bcifeat3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bcifeat3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in bciloc1.
function bciloc1_Callback(hObject, eventdata, handles)
% hObject    handle to bciloc1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelectLoc(hObject,handles,1,'SMR');
guidata(hObject,handles)


% --- Executes on button press in bciloc2.
function bciloc2_Callback(hObject, eventdata, handles)
% hObject    handle to bciloc2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelectLoc(hObject,handles,2,'SMR');
guidata(hObject,handles)


% --- Executes on button press in bciloc3.
function bciloc3_Callback(hObject, eventdata, handles)
% hObject    handle to bciloc3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_BCISelectLoc(hObject,handles,3,'SMR');
guidata(hObject,handles)


% --- Executes on button press in bciclear1.
function bciclear1_Callback(hObject, eventdata, handles)
% hObject    handle to bciclear1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,1,'Reset');
guidata(hObject,handles)


% --- Executes on button press in bciclear2.
function bciclear2_Callback(hObject, eventdata, handles)
% hObject    handle to bciclear2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,2,'Reset');
guidata(hObject,handles)


% --- Executes on button press in bciclear3.
function bciclear3_Callback(hObject, eventdata, handles)
% hObject    handle to bciclear3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI','None');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,3,'Reset');
guidata(hObject,handles)


function gain1_Callback(hObject, eventdata, handles)
% hObject    handle to gain1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of gain1 as text
%        str2double(get(hObject,'string')) returns contents of gain1 as a double
cfg.varname='GAIN_1'; cfg.defaultnum='.01';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function gain1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gain1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function gain2_Callback(hObject, eventdata, handles)
% hObject    handle to gain2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of gain2 as text
%        str2double(get(hObject,'string')) returns contents of gain2 as a double
cfg.varname='GAIN_2'; cfg.defaultnum='.01';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function gain2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gain2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function gain3_Callback(hObject, eventdata, handles)
% hObject    handle to gain3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of gain3 as text
%        str2double(get(hObject,'string')) returns contents of gain3 as a double
cfg.varname='GAIN_3'; cfg.defaultnum='.01';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function gain3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gain3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function offset1_Callback(hObject, eventdata, handles)
% hObject    handle to offset1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of offset1 as text
%        str2double(get(hObject,'string')) returns contents of offset1 as a double
cfg.varname='OFFSET_1'; cfg.defaultnum='0';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function offset1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offset1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function offset2_Callback(hObject, eventdata, handles)
% hObject    handle to offset2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of offset2 as text
%        str2double(get(hObject,'string')) returns contents of offset2 as a double
cfg.varname='OFFSET_2'; cfg.defaultnum='0';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function offset2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offset2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function offset3_Callback(hObject, eventdata, handles)
% hObject    handle to offset3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of offset3 as text
%        str2double(get(hObject,'string')) returns contents of offset3 as a double
cfg.varname='OFFSET_3'; cfg.defaultnum='0';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function offset3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offset3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end
guidata(hObject,handles)


function scale1_Callback(hObject, eventdata, handles)
% hObject    handle to scale1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of scale1 as text
%        str2double(get(hObject,'string')) returns contents of scale1 as a double
cfg.varname='Scale_1'; cfg.defaultnum='1';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function scale1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scale1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function scale2_Callback(hObject, eventdata, handles)
% hObject    handle to scale2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of scale2 as text
%        str2double(get(hObject,'string')) returns contents of scale2 as a double
cfg.varname='Scale_2'; cfg.defaultnum='1';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function scale2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scale2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function scale3_Callback(hObject, eventdata, handles)
% hObject    handle to scale3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of scale3 as text
%        str2double(get(hObject,'string')) returns contents of scale3 as a double
cfg.varname='Scale_3'; cfg.defaultnum='1';
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function scale3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scale3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in resetnormsettings.
function resetnormsettings_Callback(hObject, eventdata, handles)
% hObject    handle to resetnormsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,{'StartBCI' 'StartTrain' 'Stop'},0);
set(handles.gain1,'backgroundcolor',[.94 .94 .94],'string','0.01')
set(handles.gain2,'backgroundcolor',[.94 .94 .94],'string','0.01')
set(handles.gain3,'backgroundcolor',[.94 .94 .94],'string','0.01')
set(handles.offset1,'backgroundcolor',[.94 .94 .94],'string','0')
set(handles.offset2,'backgroundcolor',[.94 .94 .94],'string','0')
set(handles.offset3,'backgroundcolor',[.94 .94 .94],'string','0')
set(handles.scale1,'backgroundcolor',[.94 .94 .94],'string','1')
set(handles.scale2,'backgroundcolor',[.94 .94 .94],'string','1')
set(handles.scale3,'backgroundcolor',[.94 .94 .94],'string','1')
guidata(hObject,handles)


function bufferlength_Callback(hObject, eventdata, handles)
% hObject    handle to bufferlength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'string') returns contents of bufferlength as text
%        str2double(get(hObject,'string')) returns contents of bufferlength as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,{'StartBCI' 'StartTrain' 'Stop'},0);
cfg.varname='BUFFER_LENGTH'; cfg.defaultnum=5; cfg.lowbound=1; cfg.highbound=20;
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function bufferlength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bufferlength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


function cyclelength_Callback(hObject, eventdata, handles)
% hObject    handle to cyclelength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cyclelength as text
%        str2double(get(hObject,'String')) returns contents of cyclelength as a double
[hObject,handles]=bci_ESI_Reset(hObject,handles,{'StartBCI' 'StartTrain' 'Stop'},0);
cfg.varname='CYCLE_LENGTH'; cfg.defaultnum=50; cfg.lowbound=10; cfg.highbound=10000;
[hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function cyclelength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cyclelength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dispcs.
function dispcs_Callback(hObject, eventdata, handles)
% hObject    handle to dispcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of dispcs
guidata(hObject,handles)


% --- Executes on button press in normonoff.
function normonoff_Callback(hObject, eventdata, handles)
% hObject    handle to normonoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of normonoff
value=get(hObject,'value');
if isequal(value,0)
    resetnormsettings_Callback(hObject,eventdata,handles);
end
guidata(hObject,handles)


% --- Executes on button press in fixnorm.
function fixnorm_Callback(hObject, eventdata, handles)
% hObject    handle to fixnorm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of fixnorm
guidata(hObject,handles)


% --- Executes on selection change in ssveptask.
function ssveptask_Callback(hObject, eventdata, handles)
% hObject    handle to ssveptask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ssveptask contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ssveptask
set(hObject,'backgroundcolor','white')
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function ssveptask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ssveptask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ssvepfeat.
function ssvepfeat_Callback(hObject, eventdata, handles)
% hObject    handle to ssvepfeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ssvepfeat contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ssvepfeat
set(hObject,'backgroundcolor','white')
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function ssvepfeat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ssvepfeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in sendtriggers.
function sendtriggers_Callback(hObject, eventdata, handles)
% hObject    handle to sendtriggers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sendtriggers

% --- Executes on button press in CheckBCI.
function CheckBCI_Callback(hObject, eventdata, handles)
% hObject    handle to CheckBCI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,'BCI',[]);
[hObject,handles]=bci_ESI_CheckBCI2(hObject,handles);
guidata(hObject,handles)

% --- Executes on button press in SetBCI.
function SetBCI_Callback(hObject, eventdata, handles)
% hObject    handle to SetBCI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_Reset(hObject,handles,{'StartBCI' 'Stop'},[]);
[hObject,handles]=bci_ESI_SetBCI(hObject,handles);
guidata(hObject,handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          SAVED FILE PARAMETERS                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in dispfiles.
function dispfiles_Callback(hObject, eventdata, handles)
% hObject    handle to dispfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'string')) returns dispfiles contents as cell array
%        contents{get(hObject,'value')} returns selected item from dispfiles

% --- Executes during object creation, after setting all properties.
function dispfiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dispfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'backgroundcolor'), get(0,'defaultUicontrolbackgroundcolor'))
    set(hObject,'backgroundcolor','white');
end


% --- Executes on button press in displaysaved.
function displaysaved_Callback(hObject, eventdata, handles)
% hObject    handle to displaysaved (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_DispSaved(hObject,handles);
guidata(hObject,handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       ONLINE PROCESSING PARAMETERS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in StartBCI.
function StartBCI_Callback(hObject, eventdata, handles)
% hObject    handle to StartBCI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% [hObject,handles]=bci_ESI_RunBCI2(hObject,handles);
[hObject,handles]=bci_ESI_RunBCI_20170502(hObject,handles);
guidata(hObject,handles)


% --- Executes on button press in StartTrain.
function StartTrain_Callback(hObject, eventdata, handles)
% hObject    handle to StartTrain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_ESI_RunTrain3(hObject,handles,'SMR');
guidata(hObject,handles)


% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isequal(get(handles.Stop,'userdata'),1)
    set(handles.Stop,'userdata',0);
elseif isequal(get(handles.Stop,'userdata'),0)
    set(handles.Stop,'userdata',1);
end
guidata(hObject,handles) 


% --- Executes on button press in info1.
function info1_Callback(hObject, eventdata, handles)
% hObject    handle to info1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f=figure('Position', [500, 500, 200, 100]);
set(f,'MenuBar','none');
set(f,'ToolBar','none');
btn=uicontrol('style','pushbutton','string','Close','Position',...
    [75 10 50 20],'Callback', 'close');
text1=uicontrol('style','text');
set(gcf,'color',[.94 .94 .94]);
set(text1,'string','Vizualizing electrode activity can cost ~10-20ms and cause processing delays','Position',...
    [2 50 196 50])


% --- Executes on button press in info2.
function info2_Callback(hObject, eventdata, handles)
% hObject    handle to info2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f=figure('Position', [500, 500, 200, 100]);
set(f,'MenuBar','none');
set(f,'ToolBar','none');
set(gcf,'color',[.94 .94 .94]);
btn=uicontrol('style','pushbutton','string','Close','Position',...
    [75 10 50 20],'Callback', 'close');
text1=uicontrol('style','text');
set(text1,'string','Displaying the control signal can cost ~5-10ms and cause processing delays','Position',...
    [2 50 196 50])

% --- Executes on button press in info4.
function info4_Callback(hObject, eventdata, handles)
% hObject    handle to info4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
f=figure('Position', [500, 500, 200, 100]);
set(f,'MenuBar','none');
set(f,'ToolBar','none');
set(gcf,'color',[.94 .94 .94]);
btn=uicontrol('style','pushbutton','string','Close','Position',...
    [75 10 50 20],'Callback', 'close');
text1=uicontrol('style','text');
set(text1,'string','Indicates size of buffer, in trials, for each dimension in use','Position',...
    [2 50 196 50])


% --- Executes on button press in DispEEG.
function DispEEG_Callback(hObject, eventdata, handles)
% hObject    handle to DispEEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hObject,handles]=bci_fESI_DispEEG(hObject,handles);
guidata(hObject,handles)

   
% --- Executes on button press in AllChanEEG.
function AllChanEEG_Callback(hObject, eventdata, handles)
% hObject    handle to AllChanEEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'value') returns toggle state of AllChanEEG
guidata(hObject,handles)



% --- Executes on button press in LoadSystemParam.
function LoadSystemParam_Callback(hObject, eventdata, handles)
% hObject    handle to LoadSystemParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
