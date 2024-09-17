function [runparam]=bci_ESI_OnlineVar(handles)

%% INITIALIZE "dat" STORAGE STRUCTURE
smrstore=struct('window',[],'targetidx',[],'feedback',[],'start',[],'end',[]);
spatdomainstore=struct('Sensor',smrstore,'Source',smrstore,'SourceCluster',smrstore);
smrparam=struct('chanidxincludesmr',[],'vertidxinclude',[],'clusteridxinclude',[],'freqvect',[],'numfreq',[]);
SMRdat=struct('eeg',smrstore,'psd',spatdomainstore,'param',smrparam);

ssvepstore=struct('window',[],'targetidx',[],'resultidx',[],'start',[],'end',[]);
ssvepparam=struct('chanidxincludessvep',[],'freqvect',[],'numfreq',[],'targetfreq',[],'numtraget',[]);
SSVEPdat=struct('eeg',ssvepstore,'psd',ssvepstore,'param',ssvepparam);

dat=struct('SMR',SMRdat,'SSVEP',SSVEPdat);

%% INITIALIZE EVENT STRUCTURE (ORANIZED INPUT FROM BCI2000)
% real time event storage structure
paradigm=get(handles.paradigm,'value');
event=struct('BCI2Event',[],'eventtype',cell(1),'eventlatency',cell(1),...
    'eventvalue',cell(1),'numevent',ones(1,2),'targetval',0,'feedbackval',0,...
    'baselineval',0,'targetpos',[],'cursorpos',[],'sqsize',[],...
    'basestart',1,'baseend',1,'trialstart',1,'trialend',1,'stimulusword',...
    '','target',0,'targetwords',[],'targetstatus','off','paradigm',paradigm,'dimused',[]);

switch paradigm
    case {2,3,4,5,6,8}
        event.targetwords={handles.BCI.SMR.param.targetwords};
    case {7}
        event.targetwords={{{'',''},{'',''},{'',''}}};
end

event.BCI2Event=struct('type',[],'value',[],'sample',[],'offset',[],...
    'duration',[]);

if ismember(paradigm,[3,5])
    event.cursorpos=struct('orig',-1*ones(1,2),'win',-1*ones(1,2),'current',-1*ones(1,2),'stimcurrent',-1*ones(1,2));
    event.targetpos=struct('orig',-1*ones(1,2),'win',-1*ones(1,2),'current',-1*ones(1,2),'stimcurrent',-1*ones(1,2));
elseif ismember(paradigm,4)
    half=2047.5;
    event.cursorpos=struct('orig',[half;half],'win',[half;half],'current',[half;half],'stimcurrent',[half;half]);
    event.targetpos=struct('orig',[half;half],'win',[half;half],'current',[half;half],'stimcurrent',[half;half]);
elseif ismember(paradigm,[6,8])
    % BCI2000 maps to a 4095 pixel workspace, 2047.5 is half
    half=(2047.5/4095)*handles.Stimulus.Cursor.cursorsize;
    halfx=half+handles.Stimulus.Cursor.cursoroffset(1);
    halfy=half+handles.Stimulus.Cursor.cursoroffset(2);
    event.cursorpos=struct('orig',[halfx;halfy],'win',[halfx;halfy],'current',[halfx;halfy],'stimcurrent',[halfx;halfy]);
    event.targetpos=struct('orig',[halfx;halfy],'win',[halfx;halfy],'current',[halfx;halfy],'stimcurrent',[halfx;halfy]);
end

event.cursorinfo=struct('delay',[],'targetidx',[]);

%% ORGANIZE OUTPUT TO BCI2000
event2bci=struct('type','Signal','sample',1,'offset',0,'duration',1,...
    'value',zeros(3,1));

%% INITIALIZE TRIAL (COUNTS) STRUCTURE
tmp=struct('prevsample',[],'endsample',0,'begsample',0,'win',1,'null',0,...
    'feedback',nan(1,1500),'baseline',nan(1,1500),'targetidx',nan(1,1500),'trialwin',ones(3,2),'tottrial',1);
trial=struct('SMR',tmp,'SSVEP',tmp);
trial.SSVEP.endsampleextract=1e10;

switch paradigm
    case {2,3,4,5,8}
        trial.SSVEP.null=4999;
    case {7}
        trial.SMR.null=299;
end

%% INITIALIZE PROCESS TIMING STRUCUTRE
SMRtoc=struct('eegpreprocess',[],'storeeeg',[],'freqprocess',[],...
    'storepsd',[],'normdata',[],'ctrlraw',[],'buffer',[],...
    'ctrlprocess',[],'ctrlplot',[],'stimulus',[],'total',[]);

SSVEPtoc=struct('eegpreprocess',[],'classify',[],'total',[]);
TOC=struct('SMR',SMRtoc,'SSVEP',SSVEPtoc);

%% INITIALIZE BCI STRUCTURE - CONTROL SIGNAL EXTRACTION
bci.SMR.feattype=handles.BCI.SMR.control.feattype;
bci.SMR.freqidx=handles.BCI.SMR.control.freqidx;
bci.SMR.idx=handles.BCI.SMR.control.idx;
bci.SMR.weight=handles.BCI.SMR.control.w;
bci.SMR.offset=handles.BCI.SMR.control.w0;
bci.SMR.pcaweight=handles.BCI.SMR.control.wpca;
bci.SMR.lambda=handles.BCI.SMR.control.lambda;

bci.SSVEP.feattype=handles.BCI.SSVEP.control.feattype;
bci.SSVEP.freqidx=handles.BCI.SSVEP.control.freqidx;
bci.SSVEP.idx=handles.BCI.SSVEP.control.idx;
bci.SSVEP.weight=handles.BCI.SSVEP.control.w;
bci.SSVEP.offset=handles.BCI.SSVEP.control.w0;
bci.SSVEP.pcaweight=handles.BCI.SSVEP.control.wpca;
bci.SSVEP.lambda=handles.BCI.SSVEP.control.lambda;

%% PARAMTERS!!!!!!
% SYSTEM PARAMETERS
SYSTEM.initials=handles.SYSTEM.initials;
SYSTEM.year=handles.SYSTEM.year;
SYSTEM.month=handles.SYSTEM.month;
SYSTEM.day=handles.SYSTEM.day;
SYSTEM.session=handles.SYSTEM.session;
SYSTEM.run=get(handles.run,'string');

subdir=handles.SYSTEM.subdir;
if ~exist(subdir,'dir'); mkdir(subdir); end

sessiondir=handles.SYSTEM.sessiondir;
if ~exist(sessiondir,'dir'); mkdir(sessiondir); end

SYSTEM.runid=strcat(SYSTEM.initials,SYSTEM.year,SYSTEM.month,...
    SYSTEM.day,'S',SYSTEM.session,'R',SYSTEM.run);

SYSTEM.rundir=strcat(sessiondir,'\',SYSTEM.runid);
if ~exist(SYSTEM.rundir,'dir'); mkdir(SYSTEM.rundir); end

SYSTEM.savefile=strcat(SYSTEM.rundir,'\',SYSTEM.runid,'.mat');

SYSTEM.tempdomain=handles.BCI.param.tempdomainfield;
SYSTEM.spatdomain=handles.BCI.param.spatdomainfield;

eegsystemstr=cellstr(get(handles.eegsystem,'string'));
SYSTEM.eegsystem=eegsystemstr{get(handles.eegsystem,'value')};
SYSTEM.eLoc=handles.SYSTEM.Electrodes.original.eLoc;
SYSTEM.srate=handles.BCI.param.fsextract;
SYSTEM.dsfactor=handles.BCI.param.dsfactor;
SYSTEM.dsrate=handles.BCI.param.fsprocess;

freqtransstr=cellstr(get(handles.freqtrans,'string'));
SYSTEM.freqtrans=freqtransstr{get(handles.freqtrans,'value')};
SYSTEM.lowcutoff=get(handles.lowcutoff,'string');
SYSTEM.highcutoff=get(handles.highcutoff,'string');

SYSTEM.analysiswindowpaddingextract=handles.BCI.param.analysiswindowpaddingextract;
SYSTEM.analysiswindowpaddingprocess=handles.BCI.param.analysiswindowpaddingprocess;
SYSTEM.chanidxextract=1:size(handles.SYSTEM.Electrodes.original.eLoc,2);

% THROW ESI PARAMETERS IN THERE AS WELL
noisestr=cellstr(get(handles.noise,'string'));
SYSTEM.noise=noisestr{get(handles.noise,'value')};
SYSTEM.noisefile=get(handles.noisefile,'string');
SYSTEM.cortex=get(handles.cortexfile,'string');
SYSTEM.cortexlr=get(handles.cortexlrfile,'string');
SYSTEM.headmodel=get(handles.headmodelfile,'string');
SYSTEM.fmri=get(handles.fmrifile,'string');

paradigmstr=cellstr(get(handles.paradigm,'string'));
SYSTEM.paradigm=paradigmstr{get(handles.paradigm,'value')};

% SMR-SPECIFIC PARAMETERS
SMR=handles.BCI.SMR.control;
SMRfields={'analysiswindowextract','analysiswindowprocess','updatewindowextract',...
    'chanidxinclude','decodescheme','decodertype','bufferlength',...
    'cyclelength','gain','offset','scale','performance'};
for i=1:size(SMRfields,2)
    SMR.(SMRfields{i})=[];
end

% SSVEP-SPECIFIC PARAMETERS
SSVEP=handles.BCI.SSVEP.control;
SSVEPfields={'decisionwindowextract','decisionwindowprocess','gazewindow',...
    'chanidxinclude','decodescheme','decodertype','performance'};
for i=1:size(SSVEPfields,2)
    SSVEP.(SSVEPfields{i})=[];
end

% COMPILE STRUCTURE...
Parameters=struct('SYSTEM',SYSTEM,'SMR',SMR,'SSVEP',SSVEP);





%% OUTPUT
runparam.event=event;
runparam.event2bci=event2bci;
runparam.trial=trial;
runparam.bci=bci;
runparam.Parameters=Parameters;
runparam.TOC=TOC;
runparam.dat=dat;



    
    
