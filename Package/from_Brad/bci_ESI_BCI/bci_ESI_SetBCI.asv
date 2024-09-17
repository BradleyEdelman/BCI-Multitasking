function [hObject,handles]=bci_ESI_SetBCI(hObject,handles)

CheckBCI=get(handles.CheckBCI,'userdata');
set(hObject,'backgroundcolor','green','userdata',1);

paradigm=get(handles.paradigm,'value');
switch paradigm
    
    case {2,3,4,5,8}
        sigtype={'SMR'};
        userdataidx{1}=1:3;
    case 6
        sigtype={'SMR' 'SSVEP'};
        userdataidx{1}=1:3;
        userdataidx{2}=4;
    case 7
        sigtype={'SSVEP'};
        userdataidx{1}=4;
end


for ii=1:size(sigtype,2)
    
    sigtypetmp=sigtype{ii};
    userdata=CheckBCI(userdataidx{ii});
    
    if isequal(sum(userdata),0)
        
        fprintf(2,'BCI PARAMETERS HAVE NOT BEEN CHECKED FOR %s SIGNALS\n',sigtypetmp);
        set(hObject,'backgroundcolor','red','userdata',0);
        
    else
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % SIGNAL TYPE INDEPENDENT TIMING PARAMETERS
        fsextract=str2double(get(handles.fs,'string'));
        dsfactor=str2double(get(handles.dsfactor,'string'));
        fsprocess=fsextract/dsfactor;

        analysiswindow=str2double(get(handles.analysiswindow,'string'));
        analysiswindowextract=round(analysiswindow/1000*fsextract);
        analysiswindowprocess=round(analysiswindowextract/dsfactor);

        analysiswindowpadding=handles.SYSTEM.analysiswindowpadding;
        analysiswindowpaddingextract=round(analysiswindowpadding/1000*fsextract);
        analysiswindowpaddingprocess=round(analysiswindowpaddingextract/dsfactor);

        updatewindow=str2double(get(handles.updatewindow,'string'));
        updatewindowextract=round(updatewindow/1000*fsextract);

        handles.BCI.param.fsextract=fsextract;
        handles.BCI.param.fsprocess=fsprocess;
        handles.BCI.param.dsfactor=dsfactor;
        handles.BCI.param.analysiswindowpaddingextract=analysiswindowpaddingextract;
        handles.BCI.param.analysiswindowpaddingprocess=analysiswindowpaddingprocess;
        
        switch sigtypetmp
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                        SMR BCI CHECK                        %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 'SMR'
    

                handles.BCI.SMR.param.analysiswindowextract=analysiswindowextract;
                handles.BCI.SMR.param.analysiswindowprocess=analysiswindowprocess;
                handles.BCI.SMR.param.updatewindowextract=updatewindowextract;

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % WEIGHTING PARAMETERS
                locuserdata=userdata;

                bciidx=cell(1,3);
                bciweight=cell(1,3);
                bcioffset=cell(1,3);
                bcifreqidx=cell(1,3);
                bcipcaweight=cell(1,3);
                bcilambda=cell(1,3);
                bcidatainittrials=cell(1,3);
                bcidatainitwindows=cell(1,3);
                bcidatainitbase=cell(1,3);
                bcirunbase=cell(1,3);
                bcilabel=cell(1,3);
                normidx=zeros(1,3);
                for i=1:size(locuserdata,1)
                    if locuserdata(i)~=0

                        dimvar=strcat('bcidim',num2str(i));
                        dim=get(handles.(dimvar),'string');
                        dimval=dim{get(handles.(dimvar),'value')};

                        spatdomainfield=handles.TRAINING.spatdomainfield;
                        switch spatdomainfield
                            case 'Sensor'
                                locidx=(1:size(handles.SYSTEM.Electrodes.current.eLoc,2))';
                                locpca=ones(size(handles.SYSTEM.Electrodes.current.eLoc,2),1);
                            case 'Source'
                                locidx=handles.ESI.vertidxinclude(:);
                                locpca=ones(size(handles.ESI.vertidxinclude(:),1),1);
                            case 'SourceCluster'
                                locidx=(1:size(handles.ESI.CLUSTER.clusters,2)-1)';
                                locpca=ones(size(handles.ESI.CLUSTER.clusters,2)-1,1);
                        end

                        featvar=strcat('bcifeat',num2str(i));
                        featval=get(handles.(featvar),'value');
                        featoptions=cellstr(get(handles.(featvar),'string'));
                        feattype=featoptions{featval};
                        locoffset=0;
                        lambda=0;
                        label=[];
                        datainittrials=[];
                        datainitwindows=[];
                        datainitbase=[];
                        runbase=[];
                        switch feattype

                            case 'Custom'

                                locidx=handles.BCI.SMR.custom(i).Widx;
                                locweight=handles.BCI.SMR.custom(i).W;
                                % locoffset
                                label='Custom';

                                datainittrials=[];
                                datainitwindows=[];
                                datainitbase=[];
                                runbase=[];

                            case 'Regress'

                                locidx=handles.BCI.SMR.regress(i).Widx;
                                locweight=handles.BCI.SMR.regress(i).W;
                                % locoffset
                                label=handles.BCI.SMR.regress(i).label;

                                datainittrials=handles.BCI.SMR.regress(i).trialdatainit;
                                datainitwindows=handles.BCI.SMR.regress(i).windowdatainit;
                                datainitbase=handles.BCI.SMR.regress(i).basedatainit;
                                runbase=handles.BCI.SMR.regress(i).runbase;

                            case 'RLDA'

                                % locidx
                                locweight=handles.BCI.SMR.rlda(i).W;
                                locoffset=handles.BCI.SMR.rlda(i).W0;
                                label=handles.BCI.SMR.rlda(i).label;
                                lambda=handles.BCI.SMR.rlda(i).lambda;

                                datainittrials=handles.BCI.SMR.rlda(i).trialdatainit;
                                datainitwindows=handles.BCI.SMR.rlda(i).windowdatainit;
                                datainitbase=handles.BCI.SMR.rlda(i).basedatainit;
                                runbase=handles.BCI.SMR.rlda(i).runbase;

                            case 'PCA'

                                locpca=handles.BCI.SMR.pca(i).pcaw;

                                % Convert into workable format
                                datainittrials=handles.BCI.SMR.pca(i).trialdatainit;
                                for j=1:size(datainittrials,2)
                                    for k=1:size(datainittrials{j},2)
                                        datainittrialspc{j}{k}=(datainittrials{j}{k}'*locpca)';
                                    end
                                end

                                datainitwindows=handles.BCI.SMR.pca(i).windowdatainit;
                                for j=1:size(datainitwindows,2)
                                    for k=1:size(datainitwindows{j},2)
                                        datainitwindowspc{j}(:,k)=(datainitwindows{j}(:,k)'*locpca)';
                                    end
                                end

                                datainitbase=handles.BCI.SMR.pca(i).basedatainit;
                                for j=1:size(datainitbase,2)
                                    for k=1:size(datainitbase{j},2)
                                        datainitbasepc{j}{k}=(datainitbase{j}{k}'*locpca)';
                                    end
                                end

                                datainittrials=datainittrialspc;
                                datainitwindows=datainitwindowspc;
                                datainitbase=datainitbasepc;
                                runbase=handles.BCI.SMR.pca(i).runbase;

                                % locidx
                                locweight=handles.BCI.SMR.pca(i).pcarldaw;
                                locoffset=handles.BCI.SMR.pca(i).pcarldaw0;
                                label=handles.BCI.SMR.pca(i).label;
                                lambda=handles.BCI.SMR.pca(i).lambda;

                            case 'FDA'

                                % locidx
                                locweight=handles.BCI.SMR.fda(i).W;
                                locoffset=handles.BCI.SMR.fda(i).W0;
                                label=handles.BCI.SMR.fda(i).label;

                            case 'Mahal'

                                % locidx
                                topfeatidx=handles.BCI.SMR.mahal(i).topfeatidx;
                                locweight=zeros(size(locidx,1),1);
                                locweight(topfeatidx)=1;
                                % locoffset
                                label=handles.BCI.SMR.mahal(i).label;

                                datainittrials=handles.BCI.SMR.mahal(i).trialdatainit;
                                datainitwindows=handles.BCI.SMR.mahal(i).windowdatainit;
                                datainitbase=handles.BCI.SMR.mahal(i).basedatainit;
                                runbase=handles.BCI.SMR.mahal(i).runbase;

                        end

                        freqvar=strcat('bcifreq',num2str(i));
                        freqval=get(handles.(freqvar),'value')-1;
                        broadband=handles.SYSTEM.broadband;
                        numfreq=size(handles.SYSTEM.mwparam.freqvect,2);
                        % If broadband signal select, set all frequency indices
                        if freqval>numfreq || isequal(broadband,1)
                            freqval=1:numfreq;
                        end

                        if strcmp(dimval,'Pitch') || strcmp(dimval,'Horizontal')
                            bciidx{1}=locidx;
                            bciweight{1}=locweight;
                            bcioffset{1}=locoffset;
                            bcifreqidx{1}=freqval;
                            bcipcaweight{1}=locpca;
                            bcilambda{1}=lambda;
                            bcidatainittrials{1}=datainittrials;
                            bcidatainitwindows{1}=datainitwindows;
                            bcidatainitbase{1}=datainitbase;
                            bcirunbase{1}=runbase;
                            bcilabel{1}=label;
                            normidx(1)=i;
                        elseif strcmp(dimval,'Roll') || strcmp(dimval,'Vertical')
                            bciidx{2}=locidx;
                            bciweight{2}=locweight;
                            bcioffset{2}=locoffset;
                            bcifreqidx{2}=freqval;
                            bcipcaweight{2}=locpca;
                            bcilambda{2}=lambda;
                            bcidatainittrials{2}=datainittrials;
                            bcidatainitwindows{2}=datainitwindows;
                            bcidatainitbase{2}=datainitbase;
                            bcirunbase{2}=runbase;
                            bcilabel{2}=label;
                            normidx(2)=i;
                        elseif strcmp(dimval,'Yaw') || strcmp(dimval,'Depth')
                            bciidx{3}=locidx;
                            bciweight{3}=locweight;
                            bcioffset{3}=locoffset;
                            bcifreqidx{3}=freqval;
                            bcipcaweight{3}=locpca;
                            bcilambda{3}=lambda;
                            bcidatainittrials{3}=datainittrials;
                            bcidatainitwindows{3}=datainitwindows;
                            bcidatainitbase{3}=datainitbase;
                            bcirunbase{3}=runbase;
                            bcilabel{3}=label;
                            normidx(3)=i;
                        end
                    end
                end

                handles.BCI.SMR.control.freqidx=bcifreqidx;
                handles.BCI.SMR.control.idx=bciidx;
                handles.BCI.SMR.control.w=bciweight;
                handles.BCI.SMR.control.w0=bcioffset;
                handles.BCI.SMR.control.wpca=bcipcaweight;
                handles.BCI.SMR.control.lambda=bcilambda;
                handles.BCI.SMR.control.normidx=normidx;
                handles.BCI.SMR.control.feattype=feattype;
                handles.BCI.SMR.control.label=bcilabel;
                handles.BCI.SMR.control.datainittrials=bcidatainittrials;
                handles.BCI.SMR.control.datainitwindows=bcidatainitwindows;
                handles.BCI.SMR.control.datainitbase=bcidatainitbase;
                handles.BCI.SMR.control.runbase=bcirunbase;

                % Detect task type
                paradigm=get(handles.paradigm,'value');
                targetwords={{'',''},{'',''},{'',''}};
                hitcriteria=[];
                if ~isempty(bciidx{1}) && ~isempty(bciidx{2}) && ~isempty(bciidx{3})

                    targetid{1}=[1 2];
                    targetid{2}=[3 4];
                    targetid{3}=[5 6];

                    task='3D';
                    if ismember(paradigm,4:5)
                        targetwords={{'Bend Out','Bend In'},{'Twist In','Twist Out'},{'Bend Up','Bend Down'}};
                    end

                elseif ~isempty(bciidx{1}) && ~isempty(bciidx{2}) && isempty(bciidx{3})

                    targetid{1}=[1 2];
                    targetid{2}=[3 4];
                    targetid{3}=[];

                    task='2D';
                    if ismember(paradigm,4:5)
                        targetwords={{'Bend Out','Bend In'},{'Twist In','Twist Out'},{'',''}};
                        hitcriteria=[-70*pi/180 70*pi/180 -70*pi/180 70*pi/180];
                    end

                elseif ~isempty(bciidx{1}) && isempty(bciidx{2}) && isempty(bciidx{3})

                    targetid{1}=[1 2];
                    targetid{2}=[];
                    targetid{3}=[];

                    if ismember(paradigm,4:5)
                        task='Pitch';
                        targetwords={{'Bend Out','Bend In'},{'',''},{'',''}};
                        hitcriteria=[-70*pi/180 70*pi/180];
                    else
                        task='Horizontal';
                    end
                elseif isempty(bciidx{1}) && ~isempty(bciidx{2}) && isempty(bciidx{3})

                    targetid{1}=[];
                    targetid{2}=[1 2];
                    targetid{3}=[];

                    if ismember(paradigm,4:5)
                        task='Roll';
                        targetwords={{'Twist In','Twist Out'},{'',''},{'',''}};
                        hitcriteria=[-70*pi/180 70*pi/180];
                    else
                        task='Vertical';
                    end

                elseif isempty(bciidx{1}) && isempty(bciidx{2}) && ~isempty(bciidx{3})

                    targetid{1}=[];
                    targetid{2}=[];
                    targetid{3}=[1 2];

                    if ismember(paradigm,4:5)
                        task='Yaw';
                        targetwords={{'Bend Left','Bend Right'},{'',''},{'',''}};
                        hitcriteria=[];
                    else
                        task='Depth';
                    end

                else
                    fprintf(2,'NO DIMENSIONS SELECTED\n');
                end
                
                handles.BCI.SMR.param.targetwords=targetwords;
                handles.BCI.SMR.param.hitcriteria=hitcriteria;
                handles.BCI.SMR.param.targetid=targetid;
                handles.BCI.SMR.param.task=task;
                
                handles.BCI.SMR.param.chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
                
                
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                       SSVEP BCI CHECK                       %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
            case 'SSVEP'

                decisionwindow=str2double(get(handles.decisionwindow,'string'));
                decisionwindowextract=round(decisionwindow/1000*fsextract);
                decisionwindowprocess=round(decisionwindowextract/dsfactor);

                handles.BCI.SSVEP.param.decisionwindowextract=decisionwindowextract;
                handles.BCI.SSVEP.param.decisionwindowprocess=decisionwindowprocess;

                handles.BCI.SSVEP.param.chanidxinclude=handles.SSVEP.chanidxinclude;
                handles.BCI.SSVEP.param.target=handles.SSVEP.target;
                handles.BCI.SSVEP.param.targetfreq=handles.SSVEP.targetfreq;

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % WEIGHTING PARAMETERS
                ssvepuserdata=CheckBCI(4);
                
                spatdomainfield=handles.TRAINING.spatdomainfield;
                switch spatdomainfield
                    case 'Sensor'
%                         locidx=(1:size(handles.SSVEP.eLoc,2))
    %                     locpca=ones(size(handles.SYSTEM.Electrodes.current.eLoc,2),1);
                    case 'Source'
    %                     locidx=handles.ESI.vertidxinclude(:);
    %                     locpca=ones(size(handles.ESI.vertidxinclude(:),1),1);
                    case 'SourceCluster'
    %                     locidx=(1:size(handles.ESI.CLUSTER.clusters,2)-1)';
    %                     locpca=ones(size(handles.ESI.CLUSTER.clusters,2)-1,1);
                end

                ssvepfeatval=get(handles.ssvepfeat,'value');
                ssvepfeatoptions=cellstr(get(handles.ssvepfeat,'string'));
                ssvepfeattype=ssvepfeatoptions{ssvepfeatval};
                
                bciidx=[];
                bciweight=[];
                bcioffset=0;
                bcifreqidx=[];
                bcipcaweight=[];
                bcilambda=0;
                bcilabel=[];
                bcidatainittrials=[];
                bcidatainitwindows=[];
                bcidatainitbase=[];
                bcirunbase=[];
                normidx=[];
                refsig=[];
                switch ssvepfeattype

                    case 'CCA'
                        
                        numtask=handles.TRAINING.(spatdomainfield).SSVEP.datainfo.numtask;
                        % bciidx;
                        % bciweight
                        % bcioffset
                        bcifreqidx=handles.BCI.SSVEP.cca.freqval;
                        bcilabel=handles.BCI.SSVEP.cca.label;

                        bcidatainittrials=[];
                        bcidatainitwindows=[];
                        bcidatainitbase=[];
                        bcirunbase=[];
                        
                        % Creat reference signals for CCA
                        n=2; % # of harmonics
                        reffreq=bcifreqidx(:); % reference frequencies
                        fsprocess=handles.BCI.param.fsprocess;
                        decisionwindowprocess=handles.BCI.SSVEP.param.decisionwindowprocess;
                        l=decisionwindowprocess/fsprocess;
                        t=1/fsprocess:1/fsprocess:l;
                        
                        % Nuissance frequencies
                        nuissancefreq=handles.SSVEP.nuissancefreq;
                        nuisfreq=[];
                        if isequal(nuissancefreq,1)
                            nuisfreq=zeros(size(reffreq,1)+1,1);
                            nuisfreq(1)=reffreq(1)-1;
                            for i=1:size(reffreq,1)-1
                                nuisfreq(i+1)=mean(reffreq(1+(i-1):2+(i-1)));
                            end
                            nuisfreq(end)=reffreq(end)+1;
                        end
                        
                        % Reference signals for target and nuissance freq
                        totfreq=[reffreq;nuisfreq];

                        refsig=cell(1,size(totfreq,1)*3);
                        for i=1:size(totfreq,1)

                            for j=1:n
                                refsig{1+3*(i-1)}(2*j-1,:)=sin(2*pi*(j*(totfreq(i)-.25))*t);
                                refsig{1+3*(i-1)}(2*j,:)=cos(2*pi*(j*(totfreq(i)-.25))*t);
                            end

                            for j=1:n
                                refsig{2+3*(i-1)}(2*j-1,:)=sin(2*pi*(j*totfreq(i))*t);
                                refsig{2+3*(i-1)}(2*j,:)=cos(2*pi*(j*totfreq(i))*t);
                            end

                            for j=1:n
                                refsig{3+3*(i-1)}(2*j-1,:)=sin(2*pi*(j*(totfreq(i)+.25))*t);
                                refsig{3+3*(i-1)}(2*j,:)=cos(2*pi*(j*(totfreq(i)+.25))*t);
                            end

                        end

                        handles.BCI.SSVEP.control.refsig=refsig;
                        

                    case 'Regress'

                    case 'RLDA'

                        ssveptaskval=handles.BCI.SSVEP.rlda.taskval;
                        numtask=handles.TRAINING.(spatdomainfield).SSVEP.datainfo.numtask;
                        if ssveptaskval>numtask
                            ssveptaskidx=1:numtask;
                        else
                            ssveptaskidx=ssveptaskval;
                        end

                        % bciidx
                        bciweight=handles.BCI.SSVEP.rlda.W;
                        bcioffset=handles.BCI.SSVEP.rlda.W0;
                        % bcifreqidx
                        bcilabel=handles.BCI.SSVEP.rlda.label;
                        bcilambda=handles.BCI.SSVEP.rlda.lambda;

                        bcidatainittrials=handles.BCI.SSVEP.rlda.trialdatainit;
                        bcidatainitwindows=handles.BCI.SSVEP.rlda.windowdatainit;
                        bcidatainitbase=handles.BCI.SSVEP.rlda.basedatainit;
                        bcirunbase=handles.BCI.SSVEP.rlda.runbase;

                end

                handles.BCI.SSVEP.control.freq=bcifreqidx;
                handles.BCI.SSVEP.control.idx=bciidx;
                handles.BCI.SSVEP.control.w=bciweight;
                handles.BCI.SSVEP.control.w0=bcioffset;
                handles.BCI.SSVEP.control.wpca=bcipcaweight;
                handles.BCI.SSVEP.control.lambda=bcilambda;
                handles.BCI.SSVEP.control.normidx=normidx;
                handles.BCI.SSVEP.control.feattype=ssvepfeattype;
                handles.BCI.SSVEP.control.label=bcilabel;
                handles.BCI.SSVEP.control.datainittrials=bcidatainittrials;
                handles.BCI.SSVEP.control.datainitwindows=bcidatainitwindows;
                handles.BCI.SSVEP.control.datainitbase=bcidatainitbase;
                handles.BCI.SSVEP.control.runbase=bcirunbase;
                
                
                targets=handles.SSVEP.target; targets(strcmp(targets,''))=[];
                hits=handles.SSVEP.hits; hits(strcmp(hits,''))=[];
                targetfreq=handles.SSVEP.targetfreq; targetfreq(strcmp(targetfreq,''))=[];
                stimuli=handles.SSVEP.stimuli; stimuli(strcmp(stimuli,''))=[];
                
                % Load stimuli and store
                I=cell(1,numtask+1);
                if ~isempty(stimuli)
                    sz=zeros(numtask,3);
                    for i=1:size(stimuli,1)
                        tmp=imread(stimuli{i});
                        [sz(i,1),sz(i,2),sz(i,3)]=size(tmp);
                        I{i}=tmp;
                    end
                    
                    % Ensure all stimulis are the same size
                    maxsz=max(sz);
                    for i=1:size(stimuli,1)
                        diff=sz(i,:)-maxsz;
                        if diff(1)<0
                            I{i}=[I{i};zeros(abs(diff(1)),size(I{i},2),3,'uint8')];
                        end
                        
                        if diff(2)<0
                            I{i}=[I{i} zeros(size(I{i},1),abs(diff(2)),3,'uint8')];
                        end
                        
                        I{i}=flipud(I{i});
                    end 

                    I{end}=zeros(maxsz,'uint8');
                end
                
                % Establish random order of stimuli
                [taskorder,taskhit]=bci_ESI_SSVEPTaskOrder2(180,4,targets);
                
                handles.BCI.SSVEP.control.targets=targets;
                handles.BCI.SSVEP.control.taskorder=taskorder;
                handles.BCI.SSVEP.control.taskhit=taskhit;
                handles.BCI.SSVEP.control.targetfreq=targetfreq;
                handles.BCI.SSVEP.control.stimuli=stimuli;
                handles.BCI.SSVEP.control.image=I;
                
                % PLOTTING INFO
                nfft=1024;
                handles.BCI.SSVEP.plot.nfft=nfft;
                fftx=(0:nfft/2-1)*fsprocess/nfft;
                lowcutoff=abs(fftx-handles.SYSTEM.lowcutoff);
                lowcutoffidx=find(lowcutoff==min(lowcutoff));
                highcutoff=abs(fftx-handles.SYSTEM.highcutoff);
                highcutoffidx=find(highcutoff==min(highcutoff));
                fftxidx=lowcutoffidx:highcutoffidx;
                fftx=fftx(fftxidx);
                handles.BCI.SSVEP.fftxidx=fftxidx;
                handles.BCI.SSVEP.fftx=fftx;
                
                targetfftx=zeros(1,size(targetfreq,1));
                for i=1:size(targetfreq,1)
                    fftxidx=abs(fftx-str2double(targetfreq(i)));
                    targetfftx(i)=find(fftxidx==min(fftxidx));
                end
                
                handles.BCI.SSVEP.targetfftx=targetfftx;
                

        end

    end
    
    
end

[hObject,handles]=bci_ESI_CreateStimulus(hObject,handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE BCI PARAMETERS TO FILE
savefiledir=handles.SYSTEM.savefiledir;
k=1;
SaveBCIFile=strcat(savefiledir,'\BCI_',num2str(k),'.mat');
% Dont duplicate file (may want to load later)
while exist(SaveBCIFile,'file')
    k=k+1;
    SaveBCIFile=strcat(savefiledir,'\BCI_',num2str(k),'.mat');
end
handles.BCI.savefile=SaveBCIFile;
SaveBCI=handles.BCI;
save(SaveBCIFile,'SaveBCI','-v7.3');





% INFORM OPERATOR
paradigm=get(handles.paradigm,'value');
switch paradigm
    
    case {2,3,4,5,8}
        fprintf(2,'     BCI SET UP FOR "%s" SMR TASK\n',handles.BCI.SMR.param.task);
    case 6
        fprintf(2,'     BCI SET UP FOR "%s" SMR TASK and %.f TARGET SSVEP TASK\n',...
            handles.BCI.SMR.param.task,size(handles.BCI.SSVEP.control.targets,1));
    case 7
        fprintf(2,'     BCI SET UP FOR %.f TARGET SSVEP TASK\n',...
            size(handles.BCI.SSVEP.control.targets,1));
end

% handles=bci_ESI_SetOnlineParam(handles,sigtype);

