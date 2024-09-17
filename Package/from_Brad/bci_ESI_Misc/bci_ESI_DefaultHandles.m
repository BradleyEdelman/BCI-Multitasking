function [hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,HandleField)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE CUSTOM HANDLES


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 SYSTEM                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYSTEM=struct('initials',[],'session',[],'year',[],'month',[],'day',[],...
    'subdir',[],'sessiondir',[],'savefiledir',[],'tempdomain',[],...
    'eegsystem',[],'fs',[],'Electrodes',[],'freqtrans',[],'lowcutoff',[],...
    'highcutoff',[],'broadband',[],'analysiswindow',[],...
    'analysiswindowpadding',[],'updatewindow',[],'filter',[],...
    'filterds',[],'savefile',[]);

    SYSTEM.Electrodes=struct('original',[],'current',[],'ssvep',[],...
        'chanidxexclude',[],'chanidxinclude',[]);
        SYSTEM.Electrodes.original=struct('eLoc',[]);
        SYSTEM.Electrodes.current=struct('eLoc',[]);
        SYSTEM.Electrodes.ssvep=struct('eLoc',[],'chanidxinclude',[],...
            'chanidxexclude',[]);
    SYSTEM.filter=struct('a',[],'b',[]);
    SYSTEM.filter=struct('a',[],'b',[]);
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 SYSTEM                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
SSVEP=struct('eLoc',[],'chanidxinclude',[],'chanidxexclude',[],'target',[],...
    'hit',[],'targetfreq',[],'stimulus',[],'nuissancefreq',[]);
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                   ESI                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ESI=struct('files',[],'cortex',[],'cortexlr',[],'lowresinterp',[],...
    'freqtrans',[],'priorind',[],'priorval',[],'jfrmi',[],'Wfmri',[],...
    'vertidxinclude',[],'vertidxexclude',[],'noisetype',[],'noisedata',[],...
    'noisecov',[],'whitener',[],'leadfield',[],'leadfieldweights',[],...
    'savefile',[],'cortexsavefile',[],'CLUSTER',[],'NOCLUSTER',[]);

    ESI.noisecov=struct('nomodel',[]','real',[],'imag',[]);
    ESI.whitener=struct('nomodel',[]','real',[],'imag',[]);
    ESI.leadfield=struct('original',[],'whitened',[]);

    ESI.CLUSTER=struct('esifiletype',[],'clusters',[],....
        'verticesassigned',[],'clusterleadfield',[],...
        'residualsolution',[],'sourcecov',[],'lambdasq',[],'inv',[]);
        
        ESI.CLUSTER.lambdasq=struct('nomodel',[]','real',[],'imag',[]);
        ESI.CLUSTER.inv=struct('nomodel',[]','real',[],'imag',[]);
        
    ESI.NOCLUSTER=struct('sourcecov',[],'lambdasq',[],'inv',[]);
        
        ESI.NOCLUSTER.lambdasq=struct('nomodel',[]','real',[],'imag',[]);
        ESI.NOCLUSTER.inv=struct('nomodel',[]','real',[],'imag',[]);
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                TRAINING                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

feat=struct('file',[],'label',[],'type',[]);
freq=struct('regress',feat,'rlda',feat,'pca',feat,'fda',feat,'mahal',feat);
time=struct('regress',feat,'rlda',feat,'pca',feat,'fda',feat,'mahal',feat);
datainfo=struct('data',struct('bci2000',[],'esibci',[]),'trainfiles',[],...
    'datatype',[],'taskinfo',[],'trialstruct',[],'taskidx',[],'numtask',[]);

% Default normtype to none, decodescheme to time resolve, decodertype blank (custom)
SMRparam=struct('baselinetype',[],'normtype',1,...
    'baselinestart',[],'baselineend',[],'baseidx',[],...
    'baselinestartidx',[],'baselineendidx',[],'baseidxlength',[],...
    'numtopfeat',[],'lambda',[],'gamma',[],'pc',[],'decodescheme',3,'decodertype',1);
SSVEPparam=struct('targetname',[],'freq',[]','stimulus',[],...
    'baselinetype',[],'normtype',[],...
    'baselinestart',[],'baselineend',[],'baseidx',[],...
    'baselinestartidx',[],'baselineendidx',[],'baseidxlength',[],...
    'numtopfeat',[],'lambda',[],'gamma',[],'pc',[],'decodescheme',[],'decodertype',[]);

SMRfeatures=struct('dir',[],'param',SMRparam,'datainfo',datainfo,'freq',freq,'time',time);
SSVEPfeatures=struct('dir',[],'param',SSVEPparam,'datainfo',datainfo,'freq',freq);

Sensorparam=struct('chanidxinclude',[],'chanidxexclude',[],...
    'mwparam',[],'morwav',[]);
Sourceparam=struct('vertidxinclude',[],'vertidxexclude',...
    [],'mwparam',[],'morwav',[]);
SourceClusterparam=struct('vertidxinclude',[],...
    'vertidxexclude',[],'clusteridxinclude',[],...
    'clusteridxexclude',[],'mwparam',[],'morwav',[]);

Sensor=struct('dir',[],'SMR',SMRfeatures,'SSVEP',SSVEPfeatures,'param',Sensorparam);
Source=struct('dir',[],'SMR',SMRfeatures,'SSVEP',SSVEPfeatures,'param',Sourceparam);
SourceCluster=struct('dir',[],'SMR',SMRfeatures,'SSVEP',SSVEPfeatures,'param',SourceClusterparam);

TRAINING=struct('spatdomainfield',[],'Sensor',Sensor,'Source',Source,...
'SourceCluster',SourceCluster,'dir',[],'param',[]);

                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                   BCI                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
control=struct('freqidx',[],'idx',[],'w',[],'w0',[],'wpca',[],...
    'normidx',[],'feattype',[],'datainittrials',[],'datainitwindows',[],...
    'datainitbase',[],'lambda',[],'label',[],'targets',[],'taskorder',[],...
    'taskhit',[],'targetfreq',[],'stimuli',[],'I',[],'refsig',[]);
    
    runbase=struct('data',[],'meandata',[],'stddata',[]);
    
custom=struct('file',[],'label',[],'freqval',[],'taskval',[],...
    'Widx',[],'Wval',[],'W',[],'trialdatainit',[],'windowdatainit',[],...
    'basedatainit',[],'runbase',runbase);

cca=struct('file',[],'label',[],'freqval',[],'taskval',[],'refsig',[],...
    'trialdatainit',[],'windowdatainit',[],'basedatainit',[],'runbase',runbase);

regress=struct('file',[],'label',[],'freqval',[],'taskval',[],...
    'Widx',[],'Wval',[],'W',[],'trialdatainit',[],'windowdatainit',[],...
    'basedatainit',[],'runbase',runbase);

rlda=struct('file',[],'label',[],'freqval',[],'taskval',[],...
    'lambda',[],'W',[],'W0',[],'trialdatainit',[],'windowdatainit',[],...
    'basedatainit',[],'runbase',runbase);

pca=struct('file',[],'label',[],'freqval',[],'taskval',[],...
    'pcidx',[],'pcaw',[],'lambda',[],'pcarldaw',[],'pcarldaw0',[],...
    'trialdatainit',[],'windowdatainit',[],'basedatainit',[],...
    'runbase',runbase);

fda=struct('file',[],'label',[],'freqval',[],'taskval',[],...
    'W',[],'W0',[],'trialdatainit',[],'windowdatainit',[],...
    'basedatainit',[],'runbase',runbase);

mahal=struct('file',[],'label',[],'freqval',[],'taskval',[],...
    'topfeat',[],'topfeatidx',[],'trialdatainit',[],'windowdatainit',[],...
    'basedatainit',[],'runbase',runbase);

SMR=struct('control',control,'custom',custom,'regress',regress,...
    'rlda',rlda,'pca',pca,'fda',fda,'mahal',mahal,'param',[]);
SSVEP=struct('control',control,'cca',cca,'regress',regress,...
    'rlda',rlda,'pca',pca,'fda',fda,'mahal',mahal);

BCI.SMR=SMR;
BCI.SMR.param=struct('chanidxinclude',[],'analysiswindowextract',[],...
    'analysiswindowprocess',[],'updatewindowextract',[],...
    'performance',[],'targetwords',[],'hitcriteria',[],'targetid',[],...
    'task',[]);

BCI.SSVEP=SSVEP;
BCI.SSVEP.param=struct('chanidxinclude',[],'decisionwindowextract',[],...
    'decisionwindowprocess',[],'updatewindowextract',[],...
    'nuissancefreq',[],'performance',[]);
BCI.SSVEP.plot=struct('nfft',[],'fftx',[],'targetfftx',[],'fftxidx',[],...
    'FFT',[],'targH1t',[],'targH2',[],'targH3',[],'targH4',[]);


BCI.featureoptions=struct('feat',[],'task',[],'freq',[]);
    BCI.featureoptions.feat=struct('Sensor',cell(1),'Source',cell(1),'SourceCluster',cell(1));
    BCI.featureoptions.feat.Sensor{1}=' '; BCI.featureoptions.feat.Sensor{2}='Custom';
    BCI.featureoptions.feat.Source{1}=' '; BCI.featureoptions.feat.Source{2}='Custom';
    BCI.featureoptions.feat.SourceCluster{1}=' '; BCI.featureoptions.feat.SourceCluster{2}='Custom';
    BCI.featureoptions.task=struct('Sensor',cell(1),'Source',cell(1),'SourceCluster',cell(1));
    BCI.featureoptions.task.Sensor{1}=' '; BCI.featureoptions.task.Sensor{2}='Custom';
    BCI.featureoptions.task.Source{1}=' '; BCI.featureoptions.task.Source{2}='Custom';
    BCI.featureoptions.task.SourceCluster{1}=' '; BCI.featureoptions.task.SourceCluster{2}='Custom';
    BCI.featureoptions.freq=struct('Sensor',cell(1),'Source',cell(1),'SourceCluster',cell(1));
    BCI.featureoptions.freq.Sensor{1}=' ';
    BCI.featureoptions.freq.Source{1}=' ';
    BCI.featureoptions.freq.SourceCluster{1}=' ';

BCI.param=struct('tempdomainfield',[],'spatdomainfield',[],...
    'fsextract',[],'dsfactor',[],'fsprocess',[],'freqtrans',[],...
    'analysiswindowpaddingextract',[],'analysiswindowpaddingprocess',[]);
BCI.savefile=[];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 STIMULUS                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
Stimulus.general=struct('fig',[],'fixation',[],'text',[],'go',[]);
Stimulus.Hand=struct('lefthand',[],'lefthandoffset',[],'leftforearm',...
    [],'leftforearmoffset',[],'righthand',[],'righthandoffset',[],...
    'rightforearm',[],'rightforearmoffset',[],'lefthandtargetoffset',...
    [],'righthandtargetoffset',[]);
Stimulus.Cursor=struct('target',[],'cursorpos',[],'cursorsize',[],'cursoroffset',[]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               ONLINE PARAM                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear freq
freq.general=struct('mwparam',[],'morwav',[],'dt',[],'freqvect',[],'numfreq',[]);
freq.SMR=struct('baselinetype',[],'baselinenormtype',[],'baselinestartidx',[],...
    'baselineendidx',[],'basemean',[],'basestd',[],'runbase',[],'dimused',[]);
freq.SSVEP=struct('baselinetype',[],'baselinenormtype',[],'baselinestartidx',[],...
    'baselineendidx',[],'basemean',[],'basestd',[],'runbase',[],'dimused',[]);

spat.Sensor.general=struct('chanidxextract',[]);
spat.Sensor.SMR=struct('chanidxinclude',[],'numchan',[]);
spat.Sensor.SSVEP=struct('chanidxinclude',[],'numchan',[]);
spat.Source=struct('invreal',[],'invimag',[],'vertidxinclude',[]);
spat.SourceCluster=struct('invreal',[],'invimag',[],'clusters',[],...
    'vertidxinclude',[],'clusteridxinclude',[]);


eeg.general=struct('dsfactor',[],'fsprocess',[],'filter',[],...
    'analysiswindowpaddingextract',[],'analysiswindowpaddingprocess',[]);
eeg.SMR=struct('updatewindowextract',[],'analysiswindowextract',[],...
    'analysiswindowprocess',[]);
eeg.SSVEP=struct('gazewindow',[],'decisionwindowextract',[],...
    'decisionwindowprocess',[],'updatewindowextract',[]);


ONLINE=struct('freq',freq,'spat',spat,'eeg',eeg);

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET INDICATED HANDLE FIELDS BACK TO DEFAULT
if isempty(HandleField)
    
    handles.SYSTEM=SYSTEM;
    handles.ESI=ESI;
    handles.TRAINING=TRAINING;
    handles.BCI=BCI;
    handles.Stimulus=Stimulus;
    handles.SSVEP=SSVEP;
    handles.ONLINE=ONLINE;
    
else
    
    for i=1:size(HandleField,2)
        
        if strcmp('SYSTEM',HandleField{i})
            
            handles.SYSTEM=SYSTEM;
            
        elseif strcmp('ESI',HandleField{i})
            
            handles.ESI=ESI;
            
        elseif strcmp('TRAINING',HandleField{i})
            
            handles.TRAINING=TRAINING;
            
        elseif strcmp('TRAINING SENSOR',HandleField{i})
            
            handles.TRAINING.Sensor=TRAINING.Sensor;
            
        elseif strcmp('TRAINING SOURCE',HandleField{i})
            
            handles.TRAINING.Source=TRAINING.Source;
            
        elseif strcmp('TRAINING SOURCE CLUSTER',HandleField{i})
            
            handles.TRAINING.SourceCluster=TRAINING.SourceCluster;

        elseif strcmp('BCI',HandleField{i})
            
            handles.BCI=BCI;
            
        elseif strcmp('Stimulus',HandleField{i})
            
            handles.Stimulus=Stimulus;
            
        end
    end
    
end
    
    
    
    
    
    
    
    
