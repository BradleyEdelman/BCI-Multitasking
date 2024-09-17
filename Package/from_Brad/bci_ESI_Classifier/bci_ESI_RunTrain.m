function [hObject,handles]=bci_ESI_RunTrain(hObject,handles)

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
    chanidx=handles.SYSTEM.Electrodes.chanidxinclude;

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
            Acomplex=zeros(numfreq,analysiswindowprocess,size(chanidx,1));
            
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % START REAL TIME STREAMING AND PROCESSING
	Count=0;
	PrevSample=1; endsample=0; win=1; null=0; 
    
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
                tic
                
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
                
                % SAMPLES TO PROCESS
                begsample=PrevSample+updatewindowextract;
                endsample=begsample+analysiswindowextract-1;
                PrevSample=begsample;

                % Remember up to where the data was read
                Count=Count+1;
%                 fprintf('processing segment %d from sample %d to %d\n',Count,begsample/hdr.Fs,endsample/hdr.Fs);

                % READ DATA FROM BUFFER
                Data=ft_read_data(filename,'header',hdr,'begsample',...
                    begsample,'endsample',endsample,'chanindx',chanidx);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                    PROCESS RAW DATA                     %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % DOWNSAMPLE DATA
                Data=Data(:,1:dsfactor:end);
                
                % BANDPASS FILTER DATA
                Data=filtfilt(b,a,double(Data'));
                Data=Data';
                
                % MEAN-CORRECT DATA
                Data=Data-repmat(mean(Data,2),[1,size(Data,2)]);
                
                % COMMON AVERAGE REFERENCE
                Data=Data-repmat(mean(Data,1),[size(Data,1),1]);
                
                tic
                switch tempdomain
                    case 1
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %                 FREQUENCY TRANSFORM                 %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    case 2
                        
                        switch freqtrans
                            case 1 % None
                            case 2 % Complex Morlet Wavelet
                                
                                Acomplex=zeros(numfreq,size(Data,2),size(Data,1));
                                for i=1:size(Data,1)
                                    for j=1:numfreq
                                        Acomplex(j,:,i)=conv2(Data(i,:),morwav{j},'same')*dt;
                                    end
                                end
                        
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %             SENSOR ANALYSIS             %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % Find magnitude
                                E=abs(Acomplex);
                                
                                % Extract all frequencies and broadband info
                                ESensor=zeros(size(chanidx,1)*winpnts,numfreq+1);
                                for i=1:numfreq+1
                                    if i<=numfreq
                                        ESensortmp=reshape(squeeze(E(i,:,:))',size(chanidx,1),[]);
                                    else
                                        ESensortmp=reshape(squeeze(sum(E,1))',size(chanidx,1),[]);
                                    end
                                    
                                    % SAVITZKY GOLAY SMOOTHING FILTER
%                                     if isequal(sgsmooth,1)
%                                         ESensortmp=sgolayfilt(ESensortmp',2,size(ESensortmp,2)-1,[],2);
%                                     end
                                    
                                    % RESAMPLE WINDOWED DATA
                                    if isequal(fsresample,0)
                                        ESensortmp=sum(ESensortmp,2);
                                    else
                                        ESensortmp=ESensortmp(:,1:fsresample:end);
                                    end
                                    ESensor(:,i)=ESensortmp(:);
                                end

                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %             SOURCE ANALYSIS             %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                if isequal(spatdomain,3)
                                    switch parcellation
                                        case 1 % None
                                            
                                            ESource=zeros(numvert*winpnts,numfreq+1);
                                            for i=1:numfreq+1

                                                if i<numfreq
                                                    Esourcefreq=Acomplex(i,:,:);
                                                    Erealsourcefreq=reshape(squeeze(real(Esourcefreq))',size(chanidx,1),[]);
                                                    Eimagsourcefreq=reshape(squeeze(imag(Esourcefreq))',size(chanidx,1),[]);
                                                else
                                                    Erealsourcefreq=reshape(squeeze(sum(real(Acomplex),1))',size(chanidx,1),[]);
                                                    Eimagsourcefreq=reshape(squeeze(sum(imag(Acomplex),1))',size(chanidx,1),[]);
                                                end
                                                
                                                % SAVITZKY GOLAY SMOOTHING FILTER
                                                if isequal(sgsmooth,1)
                                                    Erealsourcefreq=sgolayfilt(Erealsourcefreq',2,size(Erealsourcefreq,2)-1)';
                                                    Eimagsourcefreq=sgolayfilt(Eimagsourcefreq',2,size(Eimagsourcefreq,2)-1)';
                                                end

                                                % RESAMPLE WINDOWED DATA
                                                if isequal(fsresample,0)
                                                    Erealsourcefreq=sum(Erealsourcefreq,2);
                                                    Eimagsourcefreq=sum(Eimagsourcefreq,2);
                                                else
                                                    Erealsourcefreq=Erealsourcefreq(:,1:fsresample:end);
                                                    Eimagsourcefreq=Eimagsourcefreq(:,1:fsresample:end);
                                                end

                                                switch noise
                                                    case {1,2} % None or no noise estimation

                                                        Jreal=INV*Erealsourcefreq;
                                                        Jimag=INV*Eimagsourcefreq;
                                                        J=complex(Jreal,Jimag);
                                                        J=abs(J);
                                                        
                                                        ESource(:,i)=J(:);

                                                    case {3,4} % Diagonal or full noise covariance

                                                        Jreal=INVreal*Erealsourcefreq;
                                                        Jimag=INVimag*Eimagsourcefreq;
                                                        J=complex(Jreal,Jimag);
                                                        J=abs(J);
                                                        
                                                        ESource(:,i)=J(:);

                                                end

                                            end

                                        case 2 % MSP
                                    
                                            ESource=zeros(numcluster*(analysiswindowprocess/fsresample),numfreq+1);
                                            for i=1:numfreq+1

                                                if i<numfreq
                                                    Esourcefreq=Atmp(i,:,:);
                                                    Erealsourcefreq=squeeze(real(Esourcefreq));
                                                    Eimagsourcefreq=squeeze(imag(Esourcefreq));
                                                else
                                                    Erealsourcefreq=squeeze(sum(real(Atmp),1));
                                                    Eimagsourcefreq=squeeze(sum(imag(Atmp),1));
                                                end

                                                switch noise
                                                    case {1,2} % None or no noise estimation

                                                        for j=1:numcluster
                                                            Jreal=INV{j}*Erealsourcefreq;
                                                            Jimag=INV{j}*Eimagsourcefreq;
                                                            J=complex(Jreal,Jimag);
                                                            ESource(j,i)=sum(abs(J),1);
                                                        end

                                                    case {3,4} % Diagonal or full noise covariance

                                                        for j=1:numcluster
                                                            Jreal=INVreal{j}*Erealsourcefreq;
                                                            Jimag=INVimag{j}*Eimagsourcefreq;
                                                            J=complex(Jreal,Jimag);
                                                            ESource(j,i)=sum(abs(J),1);
                                                        end

                                                end

                                            end
                                        
                                        case 3 % K-means
                                    end
                            
                                end
                        
                            case 3 % Welch
                            case 4 % DFT
                        end
                
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %                      TIME DOMAIN                    %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    case 3
                        
                        % SAVITZKY GOLAY SMOOTHING FILTER
                        if isequal(sgsmooth,1)
                            J=sgolayfilt(J',2,size(J,2)-1)';
                        end
                        
                        % RESAMPLE WINDOWED DATA
                        J=abs(J(:,1:fsresample:end));

                end
                     toc   
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 READ EVENT FROM BCI2000                 %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                BCI2Event=ft_read_event(filename,'header',hdr);
                % DETERMINE STATE OF TRIAL
                if ~isequal(size(BCI2Event),[0 0])
                    
                    % Determine current target, if any
                    if strcmp(BCI2Event(end).type,'StimulusCode') &&...
                            ~isequal(BCI2Event(end).value,0)
                        StimIdx=BCI2Event(end).value;
                        Performance.targets(TotTrial+1,1)={num2str(TotTrial)};
                        Performance.targets(TotTrial+1,2)={num2str(StimIdx)};
                        Performance.targets
                        if isempty(RunType)
                            RunType='Stimulus';
                        end
                    elseif size(BCI2Event,2)>1 && strcmp(BCI2Event(end-1).type,'StimulusCode') &&...
                        ~isequal(BCI2Event(end-1).value,0)
                        StimIdx=BCI2Event(end-1).value;
                        Performance.targets(TotTrial+1,1)={num2str(TotTrial)};
                        Performance.targets(TotTrial+1,2)={num2str(StimIdx)};
                        Performance.targets
                        if isempty(RunType)
                            RunType='Stimulus';
                        end
                    elseif strcmp(BCI2Event(end).type,'TargetCode') &&...
                            ~isequal(BCI2Event(end).value,0)
                        StimIdx=BCI2Event(end).value;
                        Performance.targets(TotTrial+1,1)={num2str(TotTrial)};
                        Performance.targets(TotTrial+1,2)={num2str(StimIdx)};
                        if isempty(RunType)
                            RunType='Cursor';
                        end
                    end
                    
                    
                    % Differentiate trial from baseline
                    if strcmp(BCI2Event(end).type,'StimulusBegin') &&...
                            isequal(BCI2Event(end).value,0) &&...
                            ~isequal(StimIdx,0)
                        
                        StimStatus(StimIdx,win+1)=1;
                        BaseStatus(win+1)=0;
                        
                    elseif strcmp(BCI2Event(end).type,'StimulusCode') &&...
                            isequal(BCI2Event(end).value,0)
                        
                        StimStatus(1:4,win+1)=zeros(4,1);
                        BaseStatus(win+1)=1;
                        
                    elseif strcmp(BCI2Event(end).type,'Feedback') &&...
                            isequal(BCI2Event(end).value,0)
                        
                        StimStatus(1:4,win+1)=zeros(4,1);
                        BaseStatus(win+1)=0;
                        
                    elseif strcmp(BCI2Event(end).type,'Feedback') &&...
                            isequal(BCI2Event(end).value,1) &&...
                            ~isequal(StimIdx,0)
                        
                        StimStatus(StimIdx,win+1)=1;
                        BaseStatus(win+1)=0;
                        
                    elseif strcmp(BCI2Event(end).type,'TargetCode') &&...
                            isequal(BCI2Event(end).value,0)
                        
                        StimStatus(1:4,win+1)=zeros(4,1);
                        BaseStatus(win+1)=0;
                        
                    else
                        
                        StimStatus(:,win+1)=zeros(4,1);
                        BaseStatus(win+1)=1;
                        
                    end
                    
                else
                    
                    StimStatus(:,win+1)=zeros(4,1);
                    BaseStatus(win+1)=1;
                    
                end     

                % Identify end of trial
                if isequal(1,sum(StimStatus(:,win),1)) && isequal(0,sum(StimStatus(:,win+1),1))
                    TotTrial=TotTrial+1;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %           STORE DATA FROM CURRENT TIME WINDOW           %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Dat(win).eeg=Data;
                Dat(win).psd.Sensor=ESensor;
                if isequal(spatdomain,3)
                    if isequal(parcellation,1)
                        Dat(win).psd.Source=ESource;
                        Dat(win).psd.SourceCluster=[];
                    else
                        Dat(win).psd.Source=[];
                        Dat(win).psd.SourceCluster=ESource;
                    end
                else
                    Dat(win).psd.Source=[];
                    Dat(win).psd.SourceCluster=[];
                end
                Dat(win).begsample=begsample;
                Dat(win).endsample=endsample;
                Dat(win).stimstatus=StimStatus(:,win+1);
                Dat(win).basestatus=BaseStatus(win+1);
                Dat(win).event.bci2event=[];
                
                AcceptedEvents={'StimulusCode','StimulusBegin','TargetCode',...
                    'Feedback'};
                
                if ~isequal(size(BCI2Event),[0 0])
                    if ~exist('PrevBCI2Event','var') ||...
                            ~isequal(PrevBCI2Event,BCI2Event(end))
                        if ismember(BCI2Event(end).type,AcceptedEvents)
                            Dat(win).event.bci2event=BCI2Event(end);
                        end
                    end
                    PrevBCI2Event=BCI2Event(end);
                end

                % UPDATE WINDOW COUNT
                win=win+1; null=0;
%                 toc
                
            else
                null=null+1;
            end
            drawnow
            
        else % SAVE PARAMETERS/DATA IF BUFFER CONTAINS NO NEW DATA - END RUN

            Dat(end).performance=Performance;
            Dat(end).runtype=RunType;
            
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.Stop,'backgroundcolor','red')

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                        SAVE DATA FILE                       %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf(2,'\n     SAVING .MAT FILE FOR CURRENT TRAINING RUN, PLEASE WAIT...\n');
            tic
            save(DatSaveFile,'Dat','-v7.3');
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