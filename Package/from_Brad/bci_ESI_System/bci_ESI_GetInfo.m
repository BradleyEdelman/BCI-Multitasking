function [hObject,handles]=bci_ESI_GetInfo(hObject,handles,field)

if ~isfield(handles,field)
    handles.(field)=[];
end

set(hObject,'userdata',1);

initials=get(handles.initials,'string');
set(handles.initials,'backgroundcolor','green');
if isempty(initials)
    fprintf(2,'INITIALS NOT SPECIFIED\n');
    set(handles.initials,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

session=get(handles.session,'string');
set(handles.session,'backgroundcolor','green');
if isempty(session)
    fprintf(2,'SESSION # NOT SPECIFIED\n');
    set(handles.session,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

% Run=get(handles.Run,'string');
% set(handles.Run,'backgroundcolor','green');
% if isempty(Run)
%     fprintf(2,'RUN # NOT SPECIFIED\n');
%     set(handles.Run,'backgroundcolor','red');
%     set(hObject,'backgroundcolor','red','userdata',0);
% end

year=get(handles.year,'string');
set(handles.year,'backgroundcolor','green');
if isempty(year)
    fprintf(2,'YEAR NOT SPECIFIED\n');
    set(handles.year,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

month=get(handles.month,'string');
set(handles.month,'backgroundcolor','green');
if isempty(month)
    fprintf(2,'MONTH NOT SPECIFIED\n');
    set(handles.month,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

day=get(handles.day,'string');
set(handles.day,'backgroundcolor','green');
if isempty(day)
    fprintf(2,'DAY NOT SPECIFIED\n');
    set(handles.day,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

savepath=get(handles.savepath,'string');
set(handles.savepath,'backgroundcolor','green');
if isempty(savepath) || ~isequal(exist(savepath,'dir'),7)
    fprintf(2,'SAVEPATH NOT SPECIFIED\n');
    set(handles.Savepath,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

eegsystem=get(handles.eegsystem,'value');
set(handles.eegsystem,'backgroundcolor','green');
if isequal(eegsystem,1)
    fprintf(2,'EEG SYSTEM NOT SPECIFIED\n');
    set(handles.eegsystem,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end
fs=get(handles.fs,'string');

dsfactor=str2double(get(handles.dsfactor,'string'));
set(handles.dsfactor,'backgroundcolor','green');
dsfs=str2double(fs)/dsfactor;

currentelectrodes=get(handles.selectsensors,'userdata');
set(handles.selectsensors,'backgroundcolor','green')
if isempty(currentelectrodes) || isequal(sum(currentelectrodes),0)
    fprintf(2,'NO ELECTRODES SELECTED\n');
    set(handles.selectsensors,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
else
    chanidxinclude=find(currentelectrodes==1);
    chanidxexclude=find(currentelectrodes==0)';
    currenteloc=handles.Electrodes.original.eLoc;
    currenteloc(chanidxexclude)=[];
end

freqtrans=get(handles.freqtrans,'value');
set(handles.freqtrans,'backgroundcolor','green');
if isequal(freqtrans,1)
    fprintf(2,'FREQUENCY TRANSFORM NOT SPECIFIED\n');
    set(handles.freqtrans,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
end

filterpasstype='BP';
lowcutoff=str2double(get(handles.lowcutoff,'string'));
set(handles.lowcutoff,'backgroundcolor','green');
if isempty(lowcutoff) || strcmp(lowcutoff,'Low') || isnan(lowcutoff)
    fprintf(2,'LOW FREQUENCY BOUND NOT SPECIFIED\n');
    set(handles.lowcutoff,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
elseif isequal(lowcutoff,0)
    fprintf(2,'LOW FREQUENCY BOUND SET TO 0 - USING LOWPASS FILTER\n');
    filterpasstype='LP';
end

highcutoff=str2double(get(handles.highcutoff,'string'));
set(handles.highcutoff,'backgroundcolor','green');
if isempty(highcutoff) || strcmp(highcutoff,'High') || isnan(highcutoff)
    fprintf(2,'HIGH FREQUENCY BOUND NOT SPECIFIED\n');
    set(handles.highcutoff,'backgroundcolor','red');
    set(hObject,'backgroundcolor','red','userdata',0);
elseif isequal(highcutoff,str2double(fs)/2)
    fprintf(2,'HIGH FREQUENCY BOUND EQUAL TO NYQUIST FREQUENCY - USING HIGHPASS FILTER\n');
    filterpasstype='HP';
end

analysiswindow=str2double(get(handles.analysiswindow,'string'));
set(handles.analysiswindow,'backgroundcolor','green')
if isempty(analysiswindow) || isnan(analysiswindow)
    fprintf(2,'ANALYSIS WINDOW LENGTH NOT SPECIFIED\n');
    set(handles.analysiswindow,'backgroundcolor','red')
    set(hObject,'backgroundcolor','red','userdata',0)
end

% If Morlet Wavelet, add 100ms to beg/end of window to account for edge effects
if isequal(freqtrans,2)
    analysiswindowpadding=100;
end

updatewindow=str2double(get(handles.updatewindow,'string'));
set(handles.updatewindow,'backgroundcolor','green')
if isempty(updatewindow) || isnan(updatewindow)
    fprintf(2,'UPDATE WINDOW LENGTH NOT SPECIFIED\n');
    set(handles.updatewindow,'backgroundcolor','red')
    set(hObject,'backgroundcolor','red','userdata',0)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SSVEP PARAMETERS
ssvepon=get(handles.ssvepon,'value');
if isequal(ssvepon,1)
    
    % SSVEP specific electrodes
    ssvepelectrodes=get(handles.selectsensorsssvep,'userdata');
    set(handles.selectsensorsssvep,'backgroundcolor','green');
    if isempty(ssvepelectrodes) || isequal(sum(ssvepelectrodes),0)
        fprintf(2,'NO SSVEP ELECTRODES SELECTED\n');
        set(handles.selectsensorsssvep,'backgroundcolor','red');
        set(hObject,'backgroundcolor','red','userdata',0);
        ssvepeloc=[];
        chanidxincludessvep=[];
        chanidxexcludessvep=[];
    else
        chanidxincludessvep=find(ssvepelectrodes==1);
        chanidxexcludessvep=find(ssvepelectrodes==0)';
        ssvepeloc=handles.Electrodes.original.eLoc;
        ssvepeloc(chanidxexcludessvep)=[];
    end
    
    handles.(field).Electrodes.ssvep.eLoc=ssvepeloc;
    handles.(field).Electrodes.ssvep.chanidxinclude=chanidxincludessvep;
    handles.(field).Electrodes.ssvep.chanidxexclude=chanidxexcludessvep;
    
    handles.SSVEP.eLoc=ssvepeloc;
    handles.SSVEP.chanidxinclude=chanidxincludessvep;
    handles.SSVEP.chanidxexclude=chanidxexcludessvep;
    
    decisionwindow=str2double(get(handles.decisionwindow,'string'));
    set(handles.decisionwindow,'backgroundcolor','green');
    if isempty(decisionwindow) || isnan(decisionwindow)
        fprintf(2,'SSVEP DECISION WINDOW LENGTH NOT SPECIFIED\n');
        set(handles.decisionwindow,'backgroundcolor','red');
        set(hObject,'backgroundcolor','red','userdata',0);
    end
    
    handles.SSVEP.decisionwindow=decisionwindow;
    
    % TARGET INFO
    data=get(handles.ssveptarget,'data');
    targets=data(:,1);
    hits=data(:,2);
    freq=data(:,3);
    stim=data(:,4);
    
    if isempty([targets{:}]) || isempty([freq{:}]) || isempty([hits{:}])% || isempty([stim{:}])
        fprintf(2,'MUST SET SSVEP TARGETS, HIT CRITERIA, FREQUENCIES, AND STIMULI\n');
        set(hObject,'backgroundcolor','red','userdata',0);
    else
        
        % REMOVE INCOMPLETE TARGET/FREQUENCIES
        badtarget=find(strcmp(targets,'')==1);
        badfreq=find(strcmp(freq,'')==1);
        badhit=find(strcmp(hits,'')==1);
        badstim=find(strcmp(stim,'')==1);

        badidx=unique([badtarget(:);badhit(:);badfreq(:)]);
        for i=1:size(badidx(:),1)
            data{badidx(i),1}='';
            data{badidx(i),2}='';
            data{badidx(i),3}='';
            data{badidx(i),4}='';
        end
        set(handles.ssveptarget,'data',data);
        
        % ORGANIZE TASK OPTIONS
        numtask=size(targets,1)-size(badidx,1);
        combinations=combnk(1:numtask,2);
        numcomb=size(combinations,1);
        ssveptask=cell(1,numcomb+1);
        for i=1:numcomb
            ssveptask{i+1}=[num2str(combinations(i,1)) '-vs-' num2str(combinations(i,2))];
        end
        ssveptask{end+1}='All Class';
        set(handles.ssveptask,'string',ssveptask,'value',1)
        
        handles.SSVEP.target=targets;
        handles.SSVEP.hits=hits;
        handles.SSVEP.targetfreq=freq;
        handles.SSVEP.stimuli=stim;
        
        % SET OUP DEFAULT/GENERIC SSVEP ANALYSIS
        handles.TRAINING.spatdomainfield='Sensor';
        handles.TRAINING.Sensor.SSVEP.datainfo.numtask=numtask;
        handles.TRAINING.Sensor.SSVEP.param.freq=freq;
        
        nuissancefreq=get(handles.nuissancefreq,'value');
        handles.SSVEP.nuissancefreq=nuissancefreq;
        
    end
    
else
    chanidxincludessvep=[];
    chanidxexcludessvep=[];
    ssvepeloc=[];
end
handles.TRAINING.spatdomainfield='Sensor';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IF ALL FIELDS ARE VALID, CREATE AND STORE NECESSARY PARAMETERS
if isequal(get(hObject,'userdata'),1)
    
    set(hObject,'backgroundcolor','green');
    subdir=strcat(savepath,'\',initials);

    sessiondir=strcat(subdir,'\',initials,year,month,day,'S',session);
    if ~exist(sessiondir,'dir')
        mkdir(sessiondir)
    end

    savefiledir=strcat(sessiondir,'\Saved');
    if ~exist(savefiledir,'dir')
        mkdir(savefiledir)
    end
    
    % CREATE BANDPASS FILTER
    n=4;
    fstmp=str2double(get(handles.fs,'string'));
    fsdstmp=fstmp/dsfactor;
    if strcmp(filterpasstype,'BP')
        
        Wn=[lowcutoff highcutoff]/(fstmp/2);
        [b,a]=butter(n,Wn);
        
        Wnds=[lowcutoff highcutoff]/(fsdstmp/2);
        [bds,ads]=butter(n,Wnds);
        
        numfreq=size(lowcutoff:highcutoff,2);
        
    elseif strcmp(filterpasstype,'LP')
        
        Wn=highcutoff/(fstmp/2);
        [b,a]=butter(n,Wn,'low');
        
        Wnds=highcutoff/(fsdstmp/2);
        [bds,ads]=butter(n,Wnds,'low');
        
        numfreq=size(1:highcutoff,2);
        lowcutoff=1;
        
    elseif strcmp(filterpasstype,'HP')
        
        Wn=lowcutoff/(fstmp/2);
        [b,a]=butter(n,Wn,'high');
        
        Wnds=lowcutoff/(fsdstmp/2);
        [bds,ads]=butter(n,Wnds,'high');
        
        numfreq=size(lowcutoff:fstmp/2,2);
        
    end
    figure; freqz(b,a)
    
    % ESTABLISH FREQUENCY TRANSFORMATION PARAMETERS
    freqtrans=get(handles.freqtrans,'value');
    handles.ESI.freqtrans=freqtrans;
    switch freqtrans
        case 1 % None
            
        case 2 % Complex Morlet Wavelet
            
            mwparam.freq=[lowcutoff highcutoff];
            mwparam.freqres=1;
            mwparam.freqvect=lowcutoff:mwparam.freqres:highcutoff;
            mwparam.numfreq=size(mwparam.freqvect,2);
            mwparam.fs=str2double(get(handles.fs,'string'))/dsfactor;
            morwav=bci_ESI_MorWav(mwparam);
            handles.(field).mwparam=mwparam;
            handles.(field).morwav=morwav;
            
            bcifreq=[cell(1);cellstr(num2str(mwparam.freqvect'));{'Broadband'}];
            set(handles.bcifreq1,'string',bcifreq,'value',1)
            set(handles.bcifreq2,'string',bcifreq,'value',1)
            set(handles.bcifreq3,'string',bcifreq,'value',1)
            handles.BCI.featureoptions.freq.Sensor=bcifreq;
            handles.BCI.featureoptions.freq.Source=bcifreq;
            handles.BCI.featureoptions.freq.SourceCluster=bcifreq;

        case 3 % Welch's PSD
            
            welchparam.overlap=0;
            welchparam.nfft=2^(nextpow2(str2double(get(handles.AnalysisWindow,'string')))+1);
            welchparam.freqfact=2;
            welchparam.fs=str2double(get(handles.fs,'string'))/dsfactor;
            handles.(field).WelchParam=welchparam;

        case 4 % DFT
            
    end
    broadband=get(handles.broadband,'value');
    
    handles.(field).initials=initials;
    handles.(field).session=session;
    % handles.(SetField).run=Run;
    handles.(field).savepath=savepath;
    handles.(field).year=year;
    handles.(field).month=month;
    handles.(field).day=day;
    handles.(field).subdir=subdir;
    handles.(field).sessiondir=sessiondir;
    handles.(field).savefiledir=savefiledir;
    handles.(field).eegsystem=eegsystem;
    handles.(field).fs=fs;
    handles.(field).dsfactor=dsfactor;
    handles.(field).dsfs=dsfs;
    handles.(field).Electrodes=handles.Electrodes;
    handles.(field).Electrodes.current.eLoc=currenteloc;
    handles.(field).Electrodes.chanidxexclude=chanidxexclude;
    handles.(field).Electrodes.chanidxinclude=chanidxinclude;
    handles.(field).freqtrans=freqtrans;
    handles.(field).filter.a=a;
    handles.(field).filter.b=b;
    handles.(field).filterds.a=ads;
    handles.(field).filterds.b=bds;
    handles.(field).lowcutoff=lowcutoff;
    handles.(field).highcutoff=highcutoff;
    handles.(field).broadband=broadband;
    handles.(field).analysiswindow=analysiswindow;
    handles.(field).analysiswindowpadding=analysiswindowpadding;
    handles.(field).updatewindow=updatewindow;
    
    % SAVE SYSTEM PARAMETERS TO FILE
    k=1;
    savefile=strcat(savefiledir,'\',field,'_',num2str(k),'.mat');
    % Dont duplicate file (may want to load later)
    while exist(savefile,'file')
        k=k+1;
        savefile=strcat(savefiledir,'\',field,'_',num2str(k),'.mat');
    end
    handles.(field).savefile=savefile;
    savevar=matlab.lang.makeValidName(strcat('Save',field));
    eval([savevar ' = handles.(field);']);
    save(savefile,savevar,'-v7.3');
    
end


