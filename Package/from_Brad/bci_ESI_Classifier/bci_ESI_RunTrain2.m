function [hObject,handles]=bci_ESI_RunTrain2(hObject,handles)

set(hObject,'userdata',1);

SetSystem=get(handles.SetSystem,'userdata');
if isequal(SetSystem,0)
    set(hObject,'backgroundcolor','red','userdata',0);
    fprintf(2,'MUST SET SYSTEM PARAMATERS TO COLLECT SENSOR TRAINING DATA\n');
end

spatdomain=get(handles.spatdomain,'value');
switch spatdomain
    case 1 % None
        
        fprintf(2,'MUST SELECT A DOMAIN TO COLLECT TRAINING DATA\n');
        set(hObject,'backgroundcolor','red','userdata',0)
        
    case 2 % Sensor
        
        vertidxinclude=[];
        vertidxexclude=[];
        clusteridxinclude=[];
        clusteridxexclude=[];

    case 3 % ESI
        
        SetESI=get(handles.SetESI,'userdata');
        if isequal(SetESI,0)
            set(hObject,'backgroundcolor','red','userdata',0);
            fprintf(2,'MUST SET ESI PARAMATERS TO COLLECT SOURCE TRAINING DATA\n');
        end
        
end

tempdomain=get(handles.tempdomain,'value');

sgsmooth=get(handles.sgsmooth,'value');




if isequal(get(hObject,'userdata'),1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SET UP DISPLAY LABELS/PARAMETERS
    set(hObject,'backgroundcolor','green','userdata',1)
    [hObject,handles]=bci_ESI_Reset(hObject,handles,{'Stop'},[]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % READ HEADER FOR FIRST TIME TO ESTABLISH BCI2000 DATA PARAMETERS
    filename='buffer://localhost:1972';
    hdr=ft_read_header(filename,'cache',true);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DEFINE SAVE DIRECTORIES
    initials=handles.SYSTEM.initials;
    year=handles.SYSTEM.year;
    month=handles.SYSTEM.month;
    day=handles.SYSTEM.day;
    session=handles.SYSTEM.session;
    subdir=handles.SYSTEM.subdir;
    if ~exist(subdir,'dir')
        mkdir(subdir)
    end
    
    sessiondir=handles.SYSTEM.sessiondir;
    if ~exist(sessiondir,'dir')
        mkdir(sessiondir)
    end
    
    run=get(handles.run,'string');
    rundir=strcat(sessiondir,'\',initials,year,month,day,'S',session,'R',run);
    if ~exist(rundir,'dir')
        mkdir(rundir)
    end

    k=1;
    TrainRun='01';
    DatSaveFile=strcat(sessiondir,'\TRAINING',TrainRun,'.mat');
    while exist(DatSaveFile,'file')
        k=k+1;
        TrainRun=num2str(k);
        if size(TrainRun,2)<2
            TrainRun=strcat('0',TrainRun);
        end
        DatSaveFile=strcat(sessiondir,'\TRAINING',TrainRun,'.mat');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ESTABLISH BCI CONTROL PARAMETERS
    
    % Define data windows
    fsextract=str2double(handles.SYSTEM.fs);
    dsfactor=handles.SYSTEM.dsfactor;
    fsprocess=fsextract/dsfactor;
    fsresample=str2double(get(handles.fsresample,'string'));
    
    analysiswindowextract=round(handles.SYSTEM.analysiswindow/1000*fsextract);
    analysiswindowprocess=round(analysiswindowextract/dsfactor);
    updatewindowextract=round(handles.SYSTEM.updatewindow/1000*fsextract);
    
    if isequal(fsresample,0)
        winpnts=1;
    else
        winpnts=analysiswindowextract/fsresample;
    end
    
    % Identify channel indices to include
    chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % RECALL FREQUENCY DOMAIN TRANSFORMATION PARAMTERS
    
    % INTRODUCE FITLER COEFFICIENTS
    a=handles.SYSTEM.filter.a;
    b=handles.SYSTEM.filter.b;
    
    % FREQUENCY TRANSFORMATION
    freqtrans=get(handles.freqtrans,'value');
    switch freqtrans
        case 1 % None
        case 2 % Complex Morlet wavelet
            mwparam=handles.SYSTEM.mwparam;
            morwav=handles.SYSTEM.morwav;
            dt=1/mwparam.fs;
            freqvect=mwparam.freqvect;
            numfreq=size(freqvect,2);
            Acomplex=zeros(numfreq,analysiswindowprocess,size(chanidxinclude,1));
            
        case 3 % Welch's PSD
%             WelchParam=handles.TFParam.WelchParam;
%             WelchParam.winsize=BlockSize;
%             w=0:1/WelchParam.freqfact:hdr.Fs/2;
%             LowCutoff=str2double(get(handles.LowCutoff,'string'));
%             HighCutoff=str2double(get(handles.HighCutoff,'string'));
%             FreqInterest=find(w>=LowCutoff & w<=HighCutoff);
        case 4 % DFT
%             nfft=2^(nextpow2(BlockSize)+2);
%             fs=str2double(get(handles.fs,'string'));
%             w=0:fs/(nfft):fs-(fs/nfft);
%             LowCutoff=str2double(get(handles.LowCutoff,'string'));
%             HighCutoff=str2double(get(handles.HighCutoff,'string'));
%             FreqInterest=find(w>=LowCutoff & w<=HighCutoff);
    end
    
    
    clusters=[];
	clusteridxinclude=[];
    switch spatdomain
        case 1 % None
        case 2 % Sensor
        case 3 % ESI
            
            noise=get(handles.noise,'value');
            
            parcellation=get(handles.parcellation,'value');
            switch parcellation
                case 1 % None
                    
                    switch noise
                        case {1,2} % None or no noise estimation
                            INV=handles.ESI.NOCLUSTER.inv.nomodel;
                        case {3,4} % Diagonal or full noise covariance
                            INVreal=handles.ESI.NOCLUSTER.inv.real;
                            INVimag=handles.ESI.NOCLUSTER.inv.imag;
                    end
                    
                case 2 % MSP
                    
                    clusters=handles.ESI.CLUSTER.clusters;
                    numcluster=size(clusters,2)-1;
                    clusteridxinclude=1:numcluster;
                    J=zeros(numcluster,3);
                    
                    switch noise
                        case {1,2} % None or no noise estimation
                            INV=handles.ESI.CLUSTER.inv.nomodel;
                        case {3,4} % Diagonal or full noise covariance
                            INVreal=handles.ESI.CLUSTER.inv.real;
                            INVimag=handles.ESI.CLUSTER.inv.imag;
                    end
                    
             
                case 3 % K-means
                    
            end
            numvert=size(handles.ESI.cortex.Vertices,1);
    end
    
    decodescheme=get(handles.decodescheme,'value');
    
    idx=struct('baseline',1,'trial',1,'window',1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INITIALIZE "Dat" DATA STORAGE STRUCTURE
    Dat.eeg=[];
    Dat.psd.Sensor=[];
    Dat.psd.Source=[];
    Dat.psd.SourceCluster=[];
    Dat.srateextract=hdr.Fs;
    Dat.srateprocess=fsprocess;
    Dat.begsample=[];
    Dat.endsample=[];
    Dat.winsizeextract=analysiswindowextract;
    Dat.winsizeprocess=analysiswindowprocess;
    Dat.eLoc=handles.SYSTEM.Electrodes.current.eLoc;
    Dat.clusters=clusters;
    Dat.chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
    Dat.vertidxinclude=handles.ESI.vertidxinclude;
    Dat.clusteridxinclude=clusteridxinclude;
    Dat.winpnts=winpnts;
    Dat.freqvect=freqvect;
    Dat.numfreq=numfreq;
    Dat.event.bci2event=[];
	Dat.event.event2bci=[];
    Dat.performance=[];
    
    Performance.targets=cell(1,2);
    Performance.targets(1,:)={'Trial #','Target #'};
    
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                    INITIALIZE INPUT FROM BCI2000                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % real time event storage structure
    event.BCI2Event=[];
    event.eventtype=cell(1);
    event.eventlatency=cell(1);
    event.eventvalue=cell(1);
    event.numevent=ones(1,2);
    event.targetval=0;
    event.feedbackval=0;
    event.baselineval=0;
    event.basestart=1;
    event.baseend=1;
    event.trialstart=1;
    event.trialend=1;
    event.stimulusword='';
    event.target=0;
    event.targetwords={'' ''};
    event.targetstatus='off';
    
    event.BCI2Event=struct('type',[],'value',[],'sample',[],'offset',[],'duration',[]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                     INITIALIZE OUTPUT TO BCI2000                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    event2bci=struct('type','Signal','sample',1,'offset',0,'duration',1,'value',.05*ones(3,1));
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                   START REAL TIME DATA PROCESSING                   %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    count=0; prevsample=1; endsample=0; win=1; null=0;
    
    feedback(1)=0; trialwin=1; tottrial=1;
    targetidx(1)=0; baseline(1)=0; updatewin=[];
    
    EEG=struct('data',[],'type',[]);
    
    StimIdx=0; TotTrial=1; StimStatus=zeros(4,1); BaseStatus(1)=1;
    
    RunType=[];
    
    pause(1)
	while isequal(get(hObject,'userdata'),1)
        
        if null<1000 && isequal(get(handles.Stop,'userdata'),0)
            
            % determine number of samples available in buffer
            hdr=ft_read_header2(filename,'cache',true);
            NewSamples=(hdr.nSamples*hdr.nTrials-endsample);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %         DETERMINE WHETHER NEW SAMPLES ARE AVAILABLE         %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if NewSamples>=updatewindowextract
                
                if isequal(rem(win,5),1)
                    set(handles.StartTrain,'backgroundcolor','yellow')
                elseif isequal(rem(win,4),1)
                    set(handles.StartTrain,'backgroundcolor','magenta')
                elseif isequal(rem(win,3),1)
                    set(handles.StartTrain,'backgroundcolor','cyan')
                elseif isequal(rem(win,2),1)
                    set(handles.StartTrain,'backgroundcolor','white')
                else
                    set(handles.StartTrain,'backgroundcolor',[1 .7 0])
                end
                drawnow
                
                output=zeros(3,1);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 READ EVENT FROM BCI2000                 %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                event.BCI2Event=ft_read_event(filename,'header',hdr);
                [event]=bci_ESI_BCIEvent(event);
                targetidx(win+1)=event.targetval;
                feedback(win+1)=event.feedbackval;
                baseline(win+1)=event.baselineval;
                
                [event.eventtype' event.eventlatency' event.eventvalue']
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %            DETERMINE TIME SAMPLES TO ANALYZE            %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                begsample=prevsample+updatewindowextract;
                endsample=begsample+analysiswindowextract-1;
                prevsample=begsample;
                
                EEG(1).data=ft_read_data(filename,'header',hdr,'begsample',...
                    begsample,'endsample',endsample,'chanindx',chanidxinclude);
                EEG(1).decodescheme='timeresolve';
                EEG(1).trialsection='window';
                EEG(1).targetidx=event.targetval;
                EEG(1).feedback=feedback(win+1);
                EEG(1).start=begsample;
                EEG(1).end=endsample;
                
                % BASELINE DATA
                if isequal(baseline(win+1),0) && isequal(baseline(win),1);
                    
                    switch decodescheme
                        case 1 % None
                        case 2 % Single-Trial
                            EEG(2).data=ft_read_data(filename,'header',hdr,'begsample',...
                                event.basestart,'endsample',event.baseend,'chanindx',chanidxinclude);
                            EEG(2).decodescheme='singletrial';
                            EEG(2).trialsection='baseline';
                            EEG(2).targetidx=event.target;
                            EEG(2).start=event.basestart;
                            EEG(2).end=event.baseend;
                        case 3 % Time-Resolved
                            EEG(2).data=ft_read_data(filename,'header',hdr,'begsample',...
                                begsample,'endsample',endsample,'chanindx',chanidxinclude);
                            EEG(2).decodescheme='timereseolve';
                            EEG(2).trialsection='baseline';
                            EEG(2).targetidx=event.target;
                            EEG(2).start=begsample;
                            EEG(2).end=endsample;
                    end
                    
                % TRIAL DATA
                elseif isequal(feedback(win+1),0) && isequal(feedback(win),1)
                    
                    switch decodescheme
                        case 1 % None
                        case 2 % Single-Trial
                            EEG(2).data=ft_read_data(filename,'header',hdr,'begsample',...
                                event.trialstart,'endsample',event.trialend,'chanindx',chanidxinclude);
                            EEG(2).decodescheme='singletrial';
                            EEG(2).trialsection='trial';
                            EEG(2).targetidx=event.target;
                            EEG(2).start=event.trialstart;
                            EEG(2).end=event.trialend;
                        case 3 % Time-Resolved
                            EEG(2).data=ft_read_data(filename,'header',hdr,'begsample',...
                                begsample,'endsample',endsample,'chanindx',chanidxinclude);
                            EEG(2).decodescheme='timereseolve';
                            EEG(2).trialsection='trial';
                            EEG(2).targetidx=event.target;
                            EEG(2).start=begsample;
                            EEG(2).end=endsample;
                    end
                    
                else
                    
                    EEG(2).data=[];
                    EEG(2).decodescheme=[];
                    EEG(2).trialsection=[];
                    EEG(2).targetidx=[];
                    EEG(2).start=[];
                    EEG(2).end=[];
                    
                end
                
                    % Remember up to where the data was read
    %                 count=count+1;
    %                 fprintf('processing segment %d from sample %d to %d\n',count,begsample/hdr.Fs,endsample/hdr.Fs);
                
                for i=1:2
                    
                    if ~isempty(EEG(i).data)
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %                    PROCESS RAW DATA                     %
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % DOWNSAMPLE DATA
                        EEG(i).data=EEG(i).data(:,1:dsfactor:end);
                        
                        % BANDPASS FILTER DATA
                        EEG(i).data=filtfilt(b,a,double(EEG(i).data'));
                        EEG(i).data=EEG(i).data';
                        
                        % MEAN-CORRECT DATA
                        EEG(i).data=EEG(i).data-repmat(mean(EEG(i).data,2),[1,size(EEG(i).data,2)]);
                        
                        % COMMON AVERAGE REFERENCE
                        EEG(i).data=EEG(i).data-repmat(mean(EEG(i).data,1),[size(EEG(i).data,1),1]);
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %         STORE RAW DATA FROM CURRENT TIME WINDOW         %
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        dat.eeg.(EEG(i).decodescheme).(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).data;
                        dat.eeg.(EEG(i).decodescheme).targetidx{idx.(EEG(i).trialsection)}=EEG(i).targetidx;
                        dat.eeg.(EEG(i).decodescheme).targetidx{idx.(EEG(i).trialsection)}=EEG(i).feedback;
                        dat.eeg.(EEG(i).decodescheme).start.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).start;
                        dat.eeg.(EEG(i).decodescheme).end.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).end;
                        
                        switch tempdomain
                            case 1

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %                 FREQUENCY TRANSFORM                 %
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            case 2

                                switch freqtrans
                                    case 1 % None
                                    case 2 % Complex Morlet Wavelet

                                        Acomplex=zeros(numfreq,size(EEG(i).data,2),size(EEG(i).data,1));
                                        for j=1:size(EEG(i).data,1)
                                            for k=1:numfreq
                                                Acomplex(k,:,j)=conv2(EEG(i).data(j,:),morwav{k},'same')*dt;
                                            end
                                        end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %         SENSOR ANALYSIS         %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        % Find magnitude
                                        E=abs(Acomplex);

                                        % Extract all frequencies and broadband info
                                        ESensor=cell(1,numfreq+1);
                                        for j=1:numfreq+1

                                            if j<=numfreq
                                                Etmp=reshape(squeeze(E(j,:,:))',size(chanidxinclude,1),[]);
                                            else
                                                Etmp=reshape(squeeze(sum(E,1))',size(chanidxinclude,1),[]);
                                            end

                                            ESensor{j}=Etmp;

                                        end
                                        
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %  STORE FREQUENCY DOMAIN DATA FROM CURRENT TIME WINDOW   %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        dat.psd.Sensor.(EEG(i).decodescheme).(EEG(i).trialsection){idx.(EEG(i).trialsection)}=ESensor;
                                        dat.psd.Sensor.(EEG(i).decodescheme).targetidx{idx.(EEG(i).trialsection)}=EEG(i).targetidx;
                                        dat.psd.Sensor.(EEG(i).decodescheme).start.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).start;
                                        dat.psd.Sensor.(EEG(i).decodescheme).end.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).end;
                                        
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %         SOURCE ANALYSIS         %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        if isequal(spatdomain,3)
                                            switch parcellation
                                                case 1 % None

                                                    ESource=cell(1,numfreq+1);
                                                    for j=1:numfreq+1

                                                        if j<numfreq
                                                            Esourcefreq=Acomplex(j,:,:);
                                                            Erealsourcefreq=reshape(squeeze(real(Esourcefreq))',size(chanidx,1),[]);
                                                            Eimagsourcefreq=reshape(squeeze(imag(Esourcefreq))',size(chanidx,1),[]);
                                                        else
                                                            Erealsourcefreq=reshape(squeeze(sum(real(Acomplex),1))',size(chanidx,1),[]);
                                                            Eimagsourcefreq=reshape(squeeze(sum(imag(Acomplex),1))',size(chanidx,1),[]);
                                                        end
                                                        
                                                        switch noise
                                                            case {1,2} % None or no noise estimation
                                                                
                                                                Jreal=INV*Erealsourcefreq;
                                                                Jimag=INV*Eimagsourcefreq;
                                                                J=complex(Jreal,Jimag);
                                                                J=abs(J);
                                                                ESource{j}=J;
                                                                
                                                            case {3,4} % Diagonal or full noise covariance
                                                                
                                                                Jreal=INVreal*Erealsourcefreq;
                                                                Jimag=INVimag*Eimagsourcefreq;
                                                                J=complex(Jreal,Jimag);
                                                                J=abs(J);
                                                                ESource{j}=J;
                                                                
                                                        end
                                                        
                                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                        %  STORE FREQUENCY DOMAIN DATA FROM CURRENT TIME WINDOW   %
                                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                        dat.psd.Source.(EEG(i).decodescheme).(EEG(i).trialsection){idx.(EEG(i).trialsection)}=ESource;
                                                        dat.psd.Source.(EEG(i).decodescheme).targetidx{idx.(EEG(i).trialsection)}=EEG(i).targetidx;
                                                        dat.psd.Source.(EEG(i).decodescheme).start.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).start;
                                                        dat.psd.Source.(EEG(i).decodescheme).end.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).end;
                                                        
                                                    end

                                                case 2 % MSP
                                    
                                                    ESource=cell(1,numfreq+1);
                                                    for j=1:numfreq+1

                                                        if j<numfreq
                                                            Esourcefreq=Acomplex(j,:,:);
                                                            Erealsourcefreq=squeeze(real(Esourcefreq));
                                                            Eimagsourcefreq=squeeze(imag(Esourcefreq));
                                                        else
                                                            Erealsourcefreq=squeeze(sum(real(Acomplex),1));
                                                            Eimagsourcefreq=squeeze(sum(imag(Acomplex),1));
                                                        end

                                                        switch noise
                                                            case {1,2} % None or no noise estimation

                                                                for k=1:numcluster
                                                                    Jreal=INV{k}*Erealsourcefreq;
                                                                    Jimag=INV{k}*Eimagsourcefreq;
                                                                    J=complex(Jreal,Jimag);
                                                                    Etmp(k,:)=sum(abs(J),1);
                                                                end
                                                                ESource{j}=Etmp;
                                                                

                                                            case {3,4} % Diagonal or full noise covariance

                                                                for k=1:numcluster
                                                                    Jreal=INVreal{k}*Erealsourcefreq;
                                                                    Jimag=INVimag{k}*Eimagsourcefreq;
                                                                    J=complex(Jreal,Jimag);
                                                                    Etmp(k,:)=sum(abs(J),1);
                                                                end
                                                                ESource{j}=Etmp;
                                                                
                                                        end
                                                        
                                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                        %  STORE FREQUENCY DOMAIN DATA FROM CURRENT TIME WINDOW   %
                                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                        dat.psd.Source.(EEG(i).decodescheme).(EEG(i).trialsection){idx.(EEG(i).trialsection)}=ESource;
                                                        dat.psd.Source.(EEG(i).decodescheme).targetidx{idx.(EEG(i).trialsection)}=EEG(i).targetidx;
                                                        dat.psd.Source.(EEG(i).decodescheme).start.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).start;
                                                        dat.psd.Source.(EEG(i).decodescheme).end.(EEG(i).trialsection){idx.(EEG(i).trialsection)}=EEG(i).end;

                                                    end
                                        
                                                case 3 % K-means
                                            end
                            
                                        end
                        
                                    case 3 % Welch
                                    case 4 % DFT
                                end
                
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %                  TIME DOMAIN                %
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            case 3

                        end
                        idx.(EEG(i).trialsection)=idx.(EEG(i).trialsection)+1;
                    end
                end

                % Only send control signal during cursor control (feedback)
%                 if isequal(feedback(win+1),1)
                    ft_write_event(filename,event2bci);
%                 end
                
                

                % UPDATE WINDOW COUNT
                win=win+1; null=0;
%                 toc
                
            else
                null=null+1;
            end
            drawnow
            
        else % SAVE PARAMETERS/DATA IF BUFFER CONTAINS NO NEW DATA - END RUN
            
            switch decodescheme
                case 1 % None
                case 2 % Single-Trial
                    
                    % Determine baseline and trial length
                    basestarts=cell2mat(dat.psd.Sensor.singletrial.start.baseline);
                    baseends=cell2mat(dat.psd.Sensor.singletrial.end.baseline);
                    baselength=round(mean(baseends-basestarts+1)/fsprocess);

                    trialstarts=cell2mat(dat.psd.Sensor.singletrial.start.trial);
                    trialends=cell2mat(dat.psd.Sensor.singletrial.end.trial);
                    triallength=round(mean(trialends-trialstarts+1)/fsprocess);

                    handles.TRAINING.param.baselength=[handles.TRAINING.param.baselength baselength];
                    handles.TRAINING.param.triallength=[handles.TRAINING.param.triallength triallength];
                    
                case 3 % Adaptive
            end
            
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.Stop,'backgroundcolor','red')

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                        SAVE DATA FILE                       %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf(2,'\n     SAVING .MAT FILE FOR CURRENT TRAINING RUN, PLEASE WAIT...\n');
            tic
            save(DatSaveFile,'dat','-v7.3');
            fprintf(2,'\n     FINISHED - Time elapsed: %.2f seconds\n\n',toc);
            trainfiles=cellstr(get(handles.trainfiles,'string'));
            trainfiles=[trainfiles;DatSaveFile];
            trainfiles=trainfiles(~cellfun('isempty',trainfiles));
            set(handles.trainfiles,'string',trainfiles,'value',size(trainfiles,1))
            
            set(hObject,'backgroundcolor',[.94 .94 .94])

            Parameters.initials=initials;
            Parameters.session=session;
            Parameters.run=TrainRun;
            Parameters.year=year;
            Parameters.month=month;
            Parameters.day=day;
            Parameters.savepath=get(handles.savepath,'string');
            
            tempdomainstr=cellstr(get(handles.tempdomain,'string'));
            Parameters.tempdomain=tempdomainstr{get(handles.tempdomain,'value')};

            spatdomainstr=cellstr(get(handles.spatdomain,'string'));
            Parameters.spatdomain=spatdomainstr{get(handles.spatdomain,'value')};

            eegsystemstr=cellstr(get(handles.eegsystem,'string'));
            Parameters.eegsystem=eegsystemstr{get(handles.eegsystem,'value')};

            Parameters.srate=handles.SYSTEM.dsfs;
            Parameters.chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
            Parameters.chanidxexclude=handles.SYSTEM.Electrodes.chanidxexclude;
            
            Parameters.winpnts=winpnts;
            
            freqtransstr=cellstr(get(handles.freqtrans,'string'));
            Parameters.freqtrans=freqtransstr{get(handles.freqtrans,'value')};

            Parameters.analysiswindow=get(handles.analysiswindow,'string');
            Parameters.updatewindow=get(handles.updatewindow,'string');
            Parameters.lowcutoff=get(handles.lowcutoff,'string');
            Parameters.highcutoff=get(handles.highcutoff,'string');
            
            noisestr=cellstr(get(handles.noise,'string'));
            Parameters.noise=noisestr{get(handles.noise,'value')};
            Parameters.noisefile=get(handles.noisefile);
            
            Parameters.cortexfile=get(handles.cortexfile,'string');
            Parameters.cortexlrfile=get(handles.cortexlrfile,'string');
            Parameters.vizsource=get(handles.vizsource,'value');
            Parameters.lrvizsource=get(handles.lrvizsource,'value');
            Parameters.headmodelfile=get(handles.headmodelfile,'string');
            Parameters.fmrifile=get(handles.fmrifile,'string');
            Parameters.brainregionfile=get(handles.brainregionfile,'string');
            Parameters.roifile=get(handles.roifile,'string');
            Parameters.eloc.current=handles.SYSTEM.Electrodes.current.eLoc;
            Parameters.eloc.orig=handles.SYSTEM.Electrodes.original.eLoc;

            ParamSaveFile=strcat(sessiondir,'\TRAINING_Param.mat');
            save(ParamSaveFile,'Parameters','-v7.3');

            guidata(hObject,handles);
            set(handles.Stop,'userdata',0)
                
        end
            
	end
    
elseif isequal(get(hObject,'userdata'),0)
    
    fprintf(2,'PARAMETERS HAVE NOT BEEN SET\n');
    set(hObject,'backgroundcolor','red','userdata',0)
    
end