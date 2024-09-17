function [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype)
%%
tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE SPATIAL DOMAIN
spatdomainfield=handles.TRAINING.spatdomainfield;
switch spatdomainfield
    case 'Sensor'
        chaninclude=handles.TRAINING.(spatdomainfield).(sigtype).param.chanidxinclude;
    case 'Source'
        chaninclude=handles.TRAINING.(spatdomainfield).(sigtype).param.vertidxinclude;
    case 'SourceCluster'
        chaninclude=handles.TRAINING.(spatdomainfield).(sigtype).param.clusteridxinclude;
end

% NUMBER OF CHANNELS
chaninclude=chaninclude(:);
numchan=size(chaninclude,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ???????????????????????
% DEFINE SAVEPATH
featspatdir=handles.TRAINING.(spatdomainfield).dir;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT DATA AND PARAMETERS
taskinfo=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.taskinfo;
datatype=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.datatype;
data=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.data.(datatype);

numtask=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.numtask;
taskidx=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.taskidx;
combinations=combnk(1:numtask,2);
numcomb=size(combinations,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RECALL FREQUENCY TRANSFORM PARAMETERS ONLY FOR BCI2000 DATA
freqtrans=get(handles.freqtrans,'value');
switch freqtrans
    case 1 % None
    case 2 % Complex Morlet Wavelet
        morwav=handles.TRAINING.(spatdomainfield).param.morwav;
        freqvect=handles.TRAINING.(spatdomainfield).param.mwparam.freqvect;
        numfreq=size(freqvect,2);
        fs=handles.TRAINING.(spatdomainfield).param.mwparam.fs;
        dt=1/fs;
        freqres=handles.TRAINING.(spatdomainfield).param.mwparam.freqres;
    case 3 % Welch's PSD
    case 4 % DFT
end

broadband=handles.SYSTEM.broadband;
freqidxstart=1;
if isequal(broadband,1); freqidxstart=numfreq+1; end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE FEATURE/CLASSIFIER TYPE
traintype=get(handles.traintype,'value');
switch traintype
    case 1 % None
    case 2 % Linear Regression
        
        feattype='Regress';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE REGRESSION STORAGE VARIABLES
        % one-vs-rest
        BOVR=zeros(numchan,numfreq,numtask); RsqOVR=zeros(numchan,numfreq,numtask);
        rOVR=zeros(numchan,numfreq,numtask); F_statOVR=zeros(numchan,numfreq,numtask);
        t_statOVR=zeros(numchan,numfreq,numtask); p_statOVR=zeros(numchan,numfreq,numtask);
        % one-vs-one
        switch sigtype
            case 'SMR'
                OVOsize=zeros(numchan,numfreq,numcomb);
            case 'SSVEP'
                numfeat=numchan*numtask*2;
                OVOsize=zeros(numfeat,numcomb);
        end    
        BOVO=OVOsize; RsqOVO=OVOsize;
        rOVO=OVOsize; F_statOVO=OVOsize;
        t_statOVO=OVOsize; p_statOVO=OVOsize;
        % one-vs-all
        BOVA=zeros(numchan,numfreq,numtask); RsqOVA=zeros(numchan,numfreq,numtask);
        rOVA=zeros(numchan,numfreq,numtask); F_statOVA=zeros(numchan,numfreq,numtask);
        t_statOVA=zeros(numchan,numfreq,numtask); p_statOVA=zeros(numchan,numfreq,numtask);
        
        string=['Performing Regression: ' num2str(freqres) ' Hz Resolution'];
        
    case 3 % Mahalanobis Distance
        
        feattype='Mahal';
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE MAHAL STORAGE VARIABLES
        numtopfeat=handles.TRAINING.(spatdomainfield).(sigtype).param.numtopfeat;
        
        % one-vs-rest
        MDOVR=zeros(numchan,numfreq,numtask);
        BestMDidxOVR=zeros(numtopfeat,numfreq,numtask);
        BestMDOVR=zeros(numtopfeat,numfreq,numtask);
        % one-vs-one
        switch sigtype
            case 'SMR'
                OVOsize=zeros(numchan,numfreq,numcomb);
            case 'SSVEP'
                numfeat=numchan*numtask*2;
                OVOsize=zeros(numfeat,numcomb);
        end    
        MDOVO=OVOsize;
        BestMDidxOVO=OVOsize;
        BestMDOVO=OVOsize;
        % one-vs-all
        MDOVA=zeros(numchan,numfreq,numtask);
        BestMDidxOVA=zeros(numtopfeat,numfreq,numtask);
        BestMDOVA=zeros(numtopfeat,numfreq,numtask);
        
        string=['Computing Mahalanobis Distance: ' num2str(freqres) ' Hz Resolution'];
        
    case 4 % Linear Discriminant Analysis
        
        feattype='RLDA';
        % Define regularization options
        lambda=handles.TRAINING.(spatdomainfield).(sigtype).param.lambda;
        numlambda=size(lambda,2);
        gamma=handles.TRAINING.(spatdomainfield).(sigtype).param.gamma;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE RLDA STORAGE VARIABLES
        % one-vs-rest
        W0OVR=zeros(numfreq,numtask,numlambda);
        WOVR=zeros(numchan,numfreq,numtask,numlambda);
        AccOVR=zeros(numfreq,numtask,numlambda);
        PCOVR=1;
%         PCOVR=zeros(numchan,numchan,numfreq,numtask,numlambda);
        % one-vs-one
        switch sigtype
            case 'SMR'
                W0OVO=zeros(numfreq,numcomb,numlambda);
                WOVO=zeros(numchan,numfreq,numcomb,numlambda);
                AccOVO=zeros(numfreq,numcomb,numlambda);
            case 'SSVEP'
                numfeat=numchan*numtask*2;
                W0OVO=zeros(numcomb,numlambda);
                WOVO=zeros(numfeat,numcomb,numlambda);
                AccOVO=zeros(numcomb,numlambda);
        end  
%         PCOVO=zeros(numchan,numchan,numfreq,numcomb,numlambda);
        PCOVO=1;
        % one-vs-all
        W0OVA=zeros(numfreq,numtask,numlambda);
        WOVA=zeros(numchan,numfreq,numtask,numlambda);
%         PCOVA=zeros(numchan,numchan,numfreq,numtask,numlambda);
        PCOVA=1;
        AccOVA=zeros(numfreq,numtask,numlambda);
        
        string=['Performing LDA: ' num2str(freqres) ' Hz Resolution'];
        
    case 5 % Principle Component Analysis
        
        feattype='PCA';
        % Define regularization options
        lambda=handles.TRAINING.(spatdomainfield).(sigtype).param.lambda;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE PCA STORAGE VARIABLES
        numpc=numchan;
        % one-vs-rest
        UOVR=zeros(numchan,numchan,numfreq,numtask);
        SOVR=zeros(numchan,numchan,numfreq,numtask);
        VOVR=zeros(numchan,numchan,numfreq,numtask);
        VEOVR=zeros(numfreq,numtask,numpc);
        TVEOVR=zeros(numfreq,numtask,numpc);
        WOVR=cell(numfreq,numtask,numpc);
        W0OVR=cell(numfreq,numtask,numpc);
        AccOVR=cell(numfreq,numtask,numpc);
        % one-vs-one
        switch sigtype%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 'SMR'
                
            case 'SSVEP'
                
        end
        UOVO=zeros(numchan,numchan,numfreq,numcomb);
        SOVO=zeros(numchan,numchan,numfreq,numcomb);
        VOVO=zeros(numchan,numchan,numfreq,numcomb);
        VEOVO=zeros(numfreq,numcomb,numpc);
        TVEOVO=zeros(numfreq,numcomb,numpc);
        WOVO=cell(numfreq,numcomb,numpc);
        W0OVO=cell(numfreq,numcomb,numpc);
        AccOVO=cell(numfreq,numcomb,numpc);
        % one-vs-all
        UOVA=zeros(numchan,numchan,numfreq,numtask);
        SOVA=zeros(numchan,numchan,numfreq,numtask);
        VOVA=zeros(numchan,numchan,numfreq,numtask);
        VEOVA=zeros(numfreq,numtask,numpc);
        TVEOVA=zeros(numfreq,numtask,numpc);
        WOVA=cell(numfreq,numtask,numpc);
        W0OVA=cell(numfreq,numtask,numpc);
        AccOVA=cell(numfreq,numtask,numpc);
        
        string=['Performing PCA: ' num2str(freqres) ' Hz Resolution'];
        
    case 6 % Fisher LDA
        
        feattype='FDA';
        % Define regularization options
        lambda=handles.TRAINING.(spatdomainfield).(sigtype).param.lambda;
        gamma=handles.TRAINING.(spatdomainfield).(sigtype).param.gamma;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE FDA STORAGE VARIABLES
        % one-vs-rest
        WOVR=zeros(numchan,numfreq,numtask);
        % one-vs-one
        switch sigtype
            case 'SMR'
                WOVO=zeros(numchan,numfreq,numtask);
            case 'SSVEP'
                numfeat=numchan*numtask*2;
                WOVO=zeros(numfeat,numtask);
        end
        % one-vs-all
        WOVA=zeros(numchan,numfreq,numtask);
        
        string=['Performing Fisher LDA: ' num2str(freqres) ' Hz Resolution'];
        
    case 7 % Mutual Information
        
        feattype='MI';
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE MI STORAGE VARIABLES
        % one-vs-rest
        MIOVR=zeros(numchan,numfreq,numtask);
        % one-vs-one
        switch sigtype
            case 'SMR'
                MIOVO=zeros(numchan,numfreq,numtask);
            case 'SSVEP'
                numfeat=numchan*numtask*2;
                MIOVO=zeros(numfeat,numtask);
        end
        % one-vs-all
        MIOVA=zeros(numchan,numfreq,numtask);
        
        string=['Comupting Mutual Information: ' num2str(freqres) 'Hz Resolution'];
        
    case {8,9}
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          POPULATE BCI OPTIONS                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[handles,hObject]=bci_ESI_BCIOptions(handles,hObject,feattype,'Freq',sigtype);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          CONSTRUCT CLASSIFIER                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
freqfeat=cell(get(handles.freqfeat,'string'));

num.chan=numchan; num.freq=numfreq; num.task=numtask;
[hObject,handles,totdata]=bci_ESI_NormalizeTrainingData2(hObject,handles,data,sigtype,num);

switch sigtype
    case 'SMR'

        h=waitbar(freqidxstart/numfreq+1,string);
        for i=freqidxstart:numfreq+1
            waitbar(i/(numfreq+1),h)

            trialdata=totdata(i).trialdata;
            basedata=totdata(i).basedata;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ONE-vs-ONE (OVO) FEATURE EXTRACTION
            for j=1:numcomb

                % ISOLATE TRIAL DATA FROM INDIVIDUAL TASK
                Class=cell(1,2);
                for l=1:2
                    % If trials are windowed
                    if iscell(trialdata{combinations(j,l)})
                        % Go through each trial and concatenate windows
                        Class{l}=horzcat(trialdata{combinations(j,l)}{:})';
                    else
                        Class{l}=trialdata{combinations(j,l)}(:,:)';
                    end
                end

                % CLASSIFIERS WITH ALL CHANNELS
                if ismember(feattype,{'RLDA','PCA','FDA'})

                    X1=Class{1};
                    X2=Class{2};

                    if strcmp(feattype,'RLDA')

                        for k=1:size(lambda,2)

                            [W0OVO(i,j,k),WOVO(:,i,j,k)]=RLDA(X1,X2,lambda(k));
                            AccOVO(i,j,k)=XVal(X1,X2,lambda(k));

                        end

                    elseif strcmp(feattype,'PCA')

                        Compile=[X1;X2];
                        C=cov(Compile);
                        [UOVO(:,:,i,j),SOVO(:,:,i,j),VOVO(:,:,i,j)]=svd(C);

                        Stmp=diag(SOVO(:,:,i,j));
                        for k=1:size(Stmp,1)
                            VEOVO(i,j,k)=Stmp(k)/sum(Stmp,1);
                            TVEOVO(i,j,k)=sum(Stmp(1:k))/sum(Stmp,1);
                        end

                        VEtmp=squeeze(VEOVO(i,j,:));
                        numpctmp=size(find(VEtmp>1e-5));

                        for k=1:numpctmp
                            [WOVO{i,j,k},W0OVO{i,j,k},AccOVO{i,j,k}]=PCALDA(X1,X2,UOVO(:,:,i,j),1:k,lambda);
                        end

                    elseif strcmp(feattype,'FDA')

                        [WOVO(:,i,j),DBOVO(i,j)]=FDA(X1,X2);

                    end

                % CLASSIFIERS WITH LIMITED CHANNELS
                elseif ismember(feattype,{'Mahal','Regress','MI'})

                    for k=1:numchan

                        X1=Class{1}(:,k);
                        X2=Class{2}(:,k);

                        if strcmp(feattype,'Mahal')

                            MDOVO(k,i,j)=Mahal(X1,X2);

                        elseif strcmp(feattype,'Regress')

                            [stats]=LSRegress(X1,X2);
                            BOVO(k,i,j)=stats.B;
                            RsqOVO(k,i,j)=stats.Rsq;
                            rOVO(k,i,j)=stats.r;
                            F_statOVO(k,i,j)=stats.F;
                            t_statOVO(k,i,j)=stats.t;
                            p_statOVO(k,i,j)=stats.p;

                        elseif strcmp(feattype,'MI')

                            MIOVO(k,i,j)=MutInfo(X1,X2);

                        end
                    end

                    % RANKING LOCATIONS BY MD
                    if strcmp(feattype,'Mahal')
                        X1=Class{1};
                        X2=Class{2};
                        [BestMDidxOVO(:,i,j),BestMDOVO(:,i,j)]=bci_ESI_MahalExtract(X1,X2,numchan,numtopfeat);
                    end

                end

                % ADD OVO VARIABLE TO DISPLAY LIST
                NewVar=[feattype ' ' spatdomainfield ' Task ' num2str(combinations(j,1)) ' vs ' num2str(combinations(j,2))];
                if ~ismember(NewVar,freqfeat)
                    freqfeat=sort(vertcat(freqfeat,{NewVar}));
                    set(handles.freqfeat,'string',freqfeat);
                end

            end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ONE-vs-REST (OVR) FEATURE EXTRACTION
            for j=1:numtask

                % ISOLATE BASELINE DATA
                if iscell(basedata{j})
                    Class1=[]; 
                    for l=1:size(basedata,2)
                        Class1=[Class1;horzcat(basedata{l}{:})'];
                    end
                else
                    Class1=basedata{j}(:,:)';
                end

                % ISOLATE TRIAL DATA FROM INDIVIDUAL TASK
                if iscell(trialdata{j})
                    Class2=horzcat(trialdata{j}{:})';
                else
                    Class2=trialdata{j}(:,:)';
                end

                % CLASSIFIERS WITH ALL CHANNELS
                if ismember(feattype,{'RLDA','PCA','FDA'})

                    X1=Class1;
                    X2=Class2;

                    if strcmp(feattype,'RLDA')

                        for k=1:size(lambda,2)

                            [W0OVR(i,j,k),WOVR(:,i,j,k)]=RLDA(X1,X2,lambda(k));
                            AccOVR(i,j,k)=XVal(X1,X2,lambda(k));

                        end

                    elseif strcmp(feattype,'PCA')

                        Compile=[X1;X2];
                        C=cov(Compile);
                        [UOVR(:,:,i,j),SOVR(:,:,i,j),VOVR(:,:,i,j)]=svd(C);

                        Stmp=diag(SOVR(:,:,i,j));
                        for k=1:size(Stmp,1)
                            VEOVR(i,j,k)=Stmp(k)/sum(Stmp,1);
                            TVEOVR(i,j,k)=sum(Stmp(1:k))/sum(Stmp,1);
                        end

                        VEtmp=squeeze(VEOVR(i,j,:));
                        numpctmp=size(find(VEtmp>1e-5));

                        for k=1:numpctmp
                            [WOVR{i,j,k},W0OVR{i,j,k},AccOVR{i,j,k}]=PCALDA(X1,X2,UOVR(:,:,i,j),1:k,lambda);
                        end

                    elseif strcmp(feattype,'FDA')

                        [WOVR(:,i,j),DBOVR(i,j)]=FDA(X1,X2);

                    end

                % CLASSIFIERS WITH LIMITED CHANNELS
                elseif ismember(feattype,{'Mahal','Regress','MI'})

                    for k=1:numchan

                        X1=Class1(:,k);
                        X2=Class2(:,k);

                        if strcmp(feattype,'Mahal')

                            MDOVR(k,i,j)=Mahal(X1,X2);

                        elseif strcmp(feattype,'Regress')

                            [stats]=LSRegress(X1,X2);
                            BOVR(k,i,j)=stats.B;
                            RsqOVR(k,i,j)=stats.Rsq;
                            rOVR(k,i,j)=stats.r;
                            F_statOVR(k,i,j)=stats.F;
                            t_statOVR(k,i,j)=stats.t;
                            p_statOVR(k,i,j)=stats.p;

                        elseif strcmp(feattype,'MI')

                            MIOVR(k,i,j)=MutInfo(X1,X2);

                        end

                    end

                    % RANKING LOCATIONS BY MD
                    if strcmp(feattype,'Mahal')
                        X1=Class1;
                        X2=Class2;
                        [BestMDidxOVR(:,i,j),BestMDOVR(:,i,j)]=bci_ESI_MahalExtract(X1,X2,numchan,numtopfeat);
                    end

                end

                % ADD OVR VARIABLE TO DISPLAY LIST
                NewVar=[feattype ' ' spatdomainfield ' Task ' num2str(j) ' vs Rest'];
                if ~ismember(NewVar,freqfeat)
                    freqfeat=sort(vertcat(freqfeat,{NewVar}));
                    set(handles.freqfeat,'string',freqfeat);
                end

            end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ONE-vs-ALL (OVA) FEATURE EXTRACTION
            TaskInd=1:numtask;
            for j=1:numtask

                % ISOLATE TRIAL DATA FROM INDIVIDUAL ONE-VS-ALL COMPARISONS
                One=j; All=TaskInd; All(j)=[];
                Class=cell(1,2);
                % If trials are windowed
                if iscell(trialdata{j})

                    % Concatenate all windows for task "One"
                    Class{1}=horzcat(trialdata{One}{:})';
                    % Concatenate all windows for task "All"
                    for l=1:size(All,2)
                        Class{2}=[Class{2};horzcat(trialdata{All(l)}{:})'];
                    end

                else

                    % Or select single trial value for each channel
                    Class{1}=trialdata{One}(:,:)';
                    Class{2}=[];
                    for l=1:size(All,2)
                        Class{2}=vertcat(Class{2},trialdata{All(l)}(:,:)');
                    end

                end

                if ismember(feattype,{'RLDA','PCA','FDA'})

                    X1=Class{1};
                    X2=Class{2};

                    if strcmp(feattype,'RLDA')

                        for k=1:size(lambda,2)

                            [W0OVA(i,j,k),WOVA(:,i,j,k)]=RLDA(X1,X2,lambda(k));
                            AccOVA(i,j,k)=XVal(X1,X2,lambda(k));

                        end

                    elseif strcmp(feattype,'PCA')

                        Compile=[X1;X2];
                        C=cov(Compile);
                        [UOVA(:,:,i,j),SOVA(:,:,i,j),VOVA(:,:,i,j)]=svd(C);

                        Stmp=diag(SOVA(:,:,i,j));
                        for k=1:size(Stmp,1)
                            VEOVA(i,j,k)=Stmp(k)/sum(Stmp,1);
                            TVEOVA(i,j,k)=sum(Stmp(1:k))/sum(Stmp,1);
                        end

                        VEtmp=squeeze(VEOVA(i,j,:));
                        numpctmp=size(find(VEtmp>1e-5));

                        for k=1:numpctmp
                            [WOVA{i,j,k},W0OVA{i,j,k},AccOVA{i,j,k}]=PCALDA(X1,X2,UOVA(:,:,i,j),1:k,lambda);
                        end

                    elseif strcmp(feattype,'FDA')

                        [WOVA(:,i,j),DBOVA(i,j)]=FDA(X1,X2);

                    end

                elseif ismember(feattype,{'Mahal','Regress','MI'})

                    for k=1:numchan

                        X1=Class{1}(:,k);
                        X2=Class{2}(:,k);

                        if strcmp(feattype,'Mahal')

                            MDOVA(k,i,j)=Mahal(X1,X2);

                        elseif strcmp(feattype,'Regress')

                            [stats]=LSRegress(X1,X2);
                            BOVA(k,i,j)=stats.B;
                            RsqOVA(k,i,j)=stats.Rsq;
                            rOVA(k,i,j)=stats.r;
                            F_statOVA(k,i,j)=stats.F;
                            t_statOVA(k,i,j)=stats.t;
                            p_statOVA(k,i,j)=stats.p;

                        elseif strcmp(feattype,'MI')

                            MIOVA=MutInfo(X1,X2);

                        end

                    end

                    % RANKING LOCATIONS BY MD
                    if strcmp(feattype,'Mahal')
                        X1=Class{1};
                        X2=Class{2};
                        [BestMDidxOVA(:,i,j),BestMDOVA(:,i,j)]=bci_ESI_MahalExtract(X1,X2,numchan,numtopfeat);
                    end

                end

                % ADD OVA VARIABLE TO DISPLAY LIST
                NewVar=[feattype ' ' spatdomainfield ' Task ' num2str(j) ' vs All'];
                if ~ismember(NewVar,freqfeat)
                    freqfeat=sort(vertcat(freqfeat,{NewVar}));
                    set(handles.freqfeat,'string',freqfeat);
                end

            end

        end
        delete(h)
        set(handles.freqfeat,'value',1)
        
    case 'SSVEP'
        
        h=waitbar(1/numcomb,'SSVEP TRAINING');
        for j=1:numcomb
            waitbar(j/numcomb,h)
            
            trialdata={totdata(:).trialdata};
            windata={totdata(:).windata};
            
            % ISOLATE TRIAL DATA FROM INDIVIDUAL TASK
            Class=cell(1,2);
            for l=1:2
                % If trials are windowed
                if iscell(trialdata{combinations(j,l)})
                    % Go through each trial and concatenate windows
                    Class{l}=vertcat(trialdata{combinations(j,l)}{:});
                else
                    Class{l}=trialdata{combinations(j,l)}(:,:);
                end
            end
            
            % CLASSIFIERS WITH ALL CHANNELS
            if ismember(feattype,{'RLDA','PCA','FDA'})

                X1=Class{1};
                X2=Class{2};

                if strcmp(feattype,'RLDA')

                    for k=1:size(lambda,2)

                        [W0OVO(j,k),WOVO(:,j,k)]=RLDA(X1,X2,lambda(k));
                        AccOVO(j,k)=XVal(X1,X2,lambda(k));

                    end

                elseif strcmp(feattype,'PCA')

                    Compile=[X1;X2];
                    C=cov(Compile);
                    [UOVO(:,:,1,j),SOVO(:,:,1,j),VOVO(:,:,1,j)]=svd(C);

                    Stmp=diag(SOVO(:,:,i,j));
                    for k=1:size(Stmp,1)
                        VEOVO(i,j,k)=Stmp(k)/sum(Stmp,1);
                        TVEOVO(i,j,k)=sum(Stmp(1:k))/sum(Stmp,1);
                    end

                    VEtmp=squeeze(VEOVO(i,j,:));
                    numpctmp=size(find(VEtmp>1e-5));

                    for k=1:numpctmp
                        [WOVO{i,j,k},W0OVO{i,j,k},AccOVO{i,j,k}]=PCALDA(X1,X2,UOVO(:,:,i,j),1:k,lambda);
                    end

                elseif strcmp(feattype,'FDA')

                    [WOVO(:,j),DBOVO(j)]=FDA(X1,X2);

                end

            % CLASSIFIERS WITH LIMITED CHANNELS
            elseif ismember(feattype,{'Mahal','Regress','MI'})

                numfeat=numchan*numtask*2;
                for k=1:numfeat

                    X1=Class{1}(:,k);
                    X2=Class{2}(:,k);

                    if strcmp(feattype,'Mahal')

                        MDOVO(k,j)=Mahal(X1,X2);

                    elseif strcmp(feattype,'Regress')

                        [stats]=LSRegress(X1,X2);
                        BOVO(k,j)=stats.B;
                        RsqOVO(k,j)=stats.Rsq;
                        rOVO(k,j)=stats.r;
                        F_statOVO(k,j)=stats.F;
                        t_statOVO(k,j)=stats.t;
                        p_statOVO(k,j)=stats.p;

                    elseif strcmp(feattype,'MI')

                        MIOVO(k,j)=MutInfo(X1,X2);

                    end
                end

                % RANKING LOCATIONS BY MD
                if strcmp(feattype,'Mahal')
                    X1=Class{1};
                    X2=Class{2};
                    [BestMDidxOVO(:,j),BestMDOVO(:,j)]=bci_ESI_MahalExtract(X1,X2,numchan,numtopfeat);
                end

            end

                % ADD OVO VARIABLE TO DISPLAY LIST
                NewVar=[sigtype ' ' feattype ' ' spatdomainfield ' Task ' num2str(combinations(j,1)) ' vs ' num2str(combinations(j,2))];
                if ~ismember(NewVar,freqfeat)
                    freqfeat=sort(vertcat(freqfeat,{NewVar}));
                    set(handles.freqfeat,'string',freqfeat);
                end

        end
        delete(h)
        set(handles.freqfeat,'value',1)
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE FEATURE FILES

% Save OVO file
clear SaveFeatFile SaveVar tmp
k=1;
SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',sigtype,'_',feattype,'_One_vs_One_',num2str(k),'.mat');
% Dont duplicate file (may want to load later)
while exist(SaveFeatFile,'file')
    k=k+1;
    SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',sigtype,'_',feattype,'_One_vs_One_',num2str(k),'.mat');
end    
    
switch traintype
    case 1 % None
    case 2 % Regression
        
        tmp.B=BOVO; tmp.R=rOVO; tmp.Rsq=RsqOVO; tmp.R=rOVO; tmp.F_stat=F_statOVO;
        tmp.t_stat=t_statOVO; tmp.pval=p_statOVO;
        
        tmphandle='regress';
        
    case 3 % Mahalanobis Distance
        
        tmp.MD=MDOVO;
        tmp.BestMD=BestMDOVO;
        tmp.BestMDidx=BestMDidxOVO;
        
        tmphandle='mahal';
        
    case 4 % Linear Discriminant Analysis
        
        tmp.W0=W0OVO; tmp.W=WOVO; tmp.lambda=lambda;
%         tmp.PC=PCOVO;
        tmp.Acc=AccOVO;
        
        tmphandle='rlda';
        
    case 5 % Principle Component Analysis
        
        tmp.U=UOVO; tmp.S=SOVO; tmp.V=VOVO;
        tmp.VE=VEOVO; tmp.TVE=TVEOVO;
        tmp.W0=W0OVO; tmp.W=WOVO; tmp.Acc=AccOVO;
        
        tmphandle='pca';

    case 6 % Fisher LDA
        
        tmp.W=WOVO; tmp.DB=DBOVO;
        
        tmphandle='fda';
        
    case 7 % Mutual Information
        
        tmp.MI=MIOVO;
        
        tmphandle='mi';
        
    case {8,9}
end
tmp.totdata=totdata; tmp.chaninclude=chaninclude;
if strcmp(spatdomainfield,'SourceCluster')
    clusters=handles.ESI.CLUSTER.clusters;
    clusters{end}=[];
    tmp.clusters=clusters;
end
tmp.label='One-vs-One';

SaveVar=matlab.lang.makeValidName(strcat('Save',feattype,spatdomainfield));
eval([SaveVar ' = tmp;']);
save(SaveFeatFile,SaveVar,'-v7.3');
    
handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).file{2}=SaveFeatFile;
handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).label{2}=num2str(combinations);
handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).type{2}='One-vs-One';

if strcmp(sigtype,'SMR')

    % Save OVR file
    k=1;
    SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',sigtype,'_',feattype,'_One_vs_Rest_',num2str(k),'.mat');
    % Dont duplicate file (may want to load later)
    while exist(SaveFeatFile,'file')
        k=k+1;
        SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',sigtype,'_',feattype,'_One_vs_Rest_',num2str(k),'.mat');
    end

    switch traintype
        case 1 % None
        case 2 % Regression

            tmp.B=BOVR; tmp.R=rOVR; tmp.Rsq=RsqOVR; tmp.R=rOVR; tmp.F_stat=F_statOVR;
            tmp.t_stat=t_statOVR; tmp.pval=p_statOVR;

            tmphandle='regress';

        case 3 % Mahalanobis Distance

            tmp.MD=MDOVR;
            tmp.BestMD=BestMDOVR;
            tmp.BestMDidx=BestMDidxOVR;

            tmphandle='mahal';

        case 4 % Linear Discriminant Analysis

            tmp.W0=W0OVR; tmp.W=WOVR; tmp.lambda=lambda;
    %         tmp.PC=PCOVR;
            tmp.Acc=AccOVR;

            tmphandle='rlda';

        case 5 % Principle Component Analysis

            tmp.U=UOVR; tmp.S=SOVR; tmp.V=VOVR;
            tmp.VE=VEOVR; tmp.TVE=TVEOVR;
            tmp.W0=W0OVR; tmp.W=WOVR; tmp.Acc=AccOVR;

            tmphandle='pca';

        case 6 % Fisher LDA

            tmp.W=WOVR; tmp.DB=DBOVR;

            tmphandle='fda';

        case 7 % Mutual Information

            tmp.MI=MIOVR;

            tmphandle='mi';

        case {8,9}
    end
    tmp.totdata=totdata; tmp.chaninclude=chaninclude;
    if strcmp(spatdomainfield,'SourceCluster')
        clusters=handles.ESI.CLUSTER.clusters;
        clusters{end}=[];
        tmp.clusters=clusters;
    end
    tmp.label='One-vs-Rest';

    SaveVar=matlab.lang.makeValidName(strcat('Save',feattype,spatdomainfield));
    eval([SaveVar ' = tmp;']);
    save(SaveFeatFile,SaveVar,'-v7.3');

    handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).file{1}=SaveFeatFile;
    handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).label{1}=num2str(1:numtask)';
    handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).type{1}='One-vs-Rest';
    
    % Save OVA file
    clear SaveFeatFile SaveVar tmp
    k=1;
    SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',sigtype,'_',feattype,'_One_vs_All_',num2str(k),'.mat');
    % Dont duplicate file (may want to load later)
    while exist(SaveFeatFile,'file')
        k=k+1;
        SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',sigtype,'_',feattype,'_One_vs_All_',num2str(k),'.mat');
    end    

    switch traintype
        case 1 % None
        case 2 % Regression

            tmp.B=BOVA; tmp.R=rOVA; tmp.Rsq=RsqOVA; tmp.R=rOVA; tmp.F_stat=F_statOVA;
            tmp.t_stat=t_statOVA; tmp.pval=p_statOVA;

            tmphandle='regress';

        case 3 % Mahalanobis Distance

            tmp.MD=MDOVA;
            tmp.BestMD=BestMDOVA;
            tmp.BestMDidx=BestMDidxOVA;

            tmphandle='mahal';

        case 4 % Linear Discriminant Analysis

            tmp.W0=W0OVA; tmp.W=WOVA; tmp.lambda=lambda;
    %         tmp.PC=PCOVA;
            tmp.Acc=AccOVA;

            tmphandle='rlda';

        case 5 % Principle Component Analysis

            tmp.U=UOVA; tmp.S=SOVA; tmp.V=VOVA;
            tmp.VE=VEOVA; tmp.TVE=TVEOVA;
            tmp.W0=W0OVA; tmp.W=WOVA; tmp.Acc=AccOVA;

            tmphandle='pca';

        case 6 % Fisher LDA

            tmp.W=WOVA; tmp.DB=DBOVA;

            tmphandle='fda';

        case 7 % Mutual Information

            tmp.MI=MIOVA;

            tmphandle='mi';

        case {8,9}
    end
    tmp.totdata=totdata; tmp.chaninclude=chaninclude;
    if strcmp(spatdomainfield,'SourceCluster')
        clusters=handles.ESI.CLUSTER.clusters;
        clusters{end}=[];
        tmp.clusters=clusters;
    end
    tmp.label='One-vs-All';

    SaveVar=matlab.lang.makeValidName(strcat('Save',feattype,spatdomainfield));
    eval([SaveVar ' = tmp;']);
    save(SaveFeatFile,SaveVar,'-v7.3');

    handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).file{3}=SaveFeatFile;
    handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).label{3}=num2str(1:numtask)';
    handles.TRAINING.(spatdomainfield).(sigtype).freq.(tmphandle).type{3}='One-vs-All';
    
end
    toc
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MUTUAL INFORMATION
function [MI]=MutInfo(X1,X2)

    X1=X1(:); X2=X2(:);
    X=[X1;X2];
    Y=[ones(size(X1,1),1);-1*ones(size(X2,1),1)];
    
    MI=mutualinfo(X,Y);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REGRESSION
function [stats]=LSRegress(X1,X2)

    % Create Model
    X1=X1(:); X2=X2(:);
    X=[X1;X2]; X=[X ones(size(X,1),1)];
    Y=[ones(size(X1,1),1);-1*ones(size(X2,1),1)];
    [n,p]=size(X); % n DOF Model, n-p DOF error

    % Perform least squares inversion
    Bfull=inv(X'*X)*X'*Y;
    B=Bfull(1);

    Y_hat=X*Bfull; % Estimate
    e=Y-Y_hat; % Error
    norme=norm(e);
    SSE=norme.^2; % Sum of Squared Errors

    RSS=norm(Y_hat-repmat(mean(Y),[n,1]))^2; % Regression Sum of Squares
    TSS=norm(Y-repmat(mean(Y),[n,1]))^2; % Total Sum of Squares
    Rsq=1-SSE/TSS; % Coefficient of correlation

    if B>0
        r=sqrt(Rsq);
    else
        r=-sqrt(Rsq);
    end

    rmse=norme/sqrt(n-1); % Standard Error
    % Statistics
    if p>1
        F_stat=(RSS/(p-1))/(rmse^2);
        t_stat=nan;
        p_stat=1-fcdf(F_stat,p-1,n-p);
    else
        F_stat=nan;
        t_stat=B/rmse;
        p_stat=1-tcdf(t_stat,n-1);
    end

    stats.B=B;
    stats.Rsq=Rsq;
    stats.r=r;
    stats.F=F_stat;
    stats.t=t_stat;
    stats.p=p_stat;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAHALANOBIS DISTANCE
function [MD]=Mahal(X1,X2)

    n1=size(X1,1);
    n2=size(X2,1);

    mu1=mean(X1,1);
    mu2=mean(X2,1);

    C1=cov(X1);
    C2=cov(X2);

    PC=(n1*C1+n2*C2)/(n1+n2-2);

    M=(mu2-mu1)*inv(PC)*(mu2-mu1)';

    MD=sqrt(M);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LINEAR DISCRIMINANT ANALYSIS
function [W0,W,PC]=RLDA(X1,X2,lambda)

    X1mean=mean(X1,1);
    X2mean=mean(X2,1);

    n1=size(X1,1);
    n2=size(X2,1);

    pp1=n1/(n1+n2);
    pp2=n2/(n1+n2);

    X1=X1-repmat(X1mean,[n1,1]);
    X2=X2-repmat(X2mean,[n2,1]);
    
    X1cov=1/(n1-1)*(X1'*X1);
    X2cov=1/(n2-1)*(X2'*X2);
    
    PC=(n1*X1cov+n2*X2cov)/(n1+n2);

    % Regularize
    D=(trace(PC)/size(PC,1))*eye(size(PC));
    PC=(1-lambda)*PC+lambda*D;
    
    W0=log(pp2/pp1)-.5*(X2mean-X1mean)/(PC)*(X2mean+X1mean)'; %W0=0;
    W=(X2mean-X1mean)/(PC);
    W=W(:);
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LINEAR DISCRIMINANT ANALYSIS
function [W0,W]=RLDA2(X1,X2,lambda)

    X1mean=mean(X1,1);
    X2mean=mean(X2,1);

    n1=size(X1,1);
    n2=size(X2,1);
    N=n1+n2;

    pp1=n1/(n1+n2);
    pp2=n2/(n1+n2);

    X1=X1-repmat(X1mean,[n1,1]);
    X2=X2-repmat(X2mean,[n2,1]);

    X1cov=1/(n1-1)*(X1'*X1);
    X2cov=1/(n2-1)*(X2'*X2);
    
    PC=(n1*X1cov+n2*X2cov)/N;
    
    % Regularize 
    X11cov=(1-lambda)*X1cov+PC*lambda;
    n11=(1-lambda)*n1+N*lambda;
    
    X22cov=(1-lambda)*X2cov+PC*lambda;
    n22=(1-lambda)*n2+N*lambda;
    
    PC=X11cov/n11+X22cov/n22;

    % Regularize
    gamma=.05;
    D=(trace(PC)/size(PC,1))*eye(size(PC));
    PC=(1-gamma)*PC+gamma*D;

    W0=log(pp2/pp1)-.5*(X2mean+X1mean)/(PC)*(X2mean-X1mean)';
    W=(X2mean-X1mean)/(PC);
    W=W(:);


function [Acc]=XVal(X1,X2,lambda)

    Data=[X1;X2];
    Label=[ones(size(X1,1),1);zeros(size(X2,1),1)];
    Rand=randperm(size(Data,1));

    NumFold=5;
    TestSize=floor(size(Data,1)/NumFold);

    FoldAcc=zeros(NumFold,1);
    for i=1:NumFold

        if ~isequal(i,NumFold)
            TestIdx=1+TestSize*(i-1):TestSize+TestSize*(i-1);
        else
            TestIdx=1+TestSize*(i-1):size(Data,1);
        end

        TestDataIdx=Rand(TestIdx);
        TestData=Data(TestDataIdx,:);
        TestLabel=Label(TestDataIdx);

        TrainDataIdx=Rand; TrainDataIdx(TestIdx)=[];
        TrainData=Data(TrainDataIdx,:);
        TrainLabel=Label(TrainDataIdx);

        X1tmp=TrainData(TrainLabel==1,:);
        X2tmp=TrainData(TrainLabel==0,:);

        [W0,W]=RLDA(X1tmp,X2tmp,lambda);

        Predict=zeros(size(TestData,1),1);
        for j=1:size(TestData,1)
%             TestData(j,:)'; W0
            DF=TestData(j,:)*W+W0;

            if DF<0
                Predict(j)=1;
            else
                Predict(j)=0;
            end

        end

        Correct=size(find((TestLabel-Predict)==0),1);
        FoldAcc(i)=Correct/size(TestData,1)*100;

    end

    Acc=mean(FoldAcc);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FISHER LDA   
function [W,DB]=FDA(X1,X2)

    X1mean=mean(X1,1);
    X2mean=mean(X2,1);
    
    TotMean=mean([X1;X2],1);
    
    n1=size(X1,1);
    n2=size(X2,1);

    X1=X1-repmat(X1mean,[n1,1]);
    X2=X2-repmat(X2mean,[n2,1]);

    X1cov=1/(n1-1)*(X1'*X1);
    X2cov=1/(n2-1)*(X2'*X2);
    
    SW=(n1*X1cov+n2*X2cov)/(n1+n2);
    
    % Regularize
    lambda=0;
%     SW=(X1cov+X2cov)/(n1+n2);
    X11=(1-lambda)*X1cov+lambda*SW;
    n11=(1-lambda)*n1+lambda*(n1+n2);
    X22=(1-lambda)*X2cov+lambda*SW;
    n22=(1-lambda)*n2+lambda*(n1+n2);
    
    SW=X11./n11+X22./n22;
    
    SB=n1*(X1mean-TotMean)'*(X1mean-TotMean)+n2*(X2mean-TotMean)'*(X2mean-TotMean);
    
    [V,U]=eig(SB/SW);
    
    NumDim=1;
    W=V(:,1:NumDim);
    
    DB=.5*(X1mean-X2mean)*W;

    Y1=X1*W;
    Y2=X2*W;
    
%     size(Y1)
%     size(Y2)
    
    figure(1); hold off
    scatter(Y1,zeros(1,size(Y1,1)),'b'); hold on
    scatter(Y2,zeros(1,size(Y2,1)),'r');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRINCIPLE COMPONENT ANALYSIS  
function [W,W0,Acc]=PCALDA(X1,X2,U,PCs,lambda)

    Filters=U(:,PCs); 
    
    if iscell(X1)
        X1=horzcat(X1{:});
    end
    
    if iscell(X2)
        X2=horzcat(X2{:});
    end
    
    X1=X1*Filters;
    X2=X2*Filters;
    
    W0=zeros(1,size(lambda,2));
    W=zeros(size(PCs,2),size(lambda,2));
    Acc=zeros(1,size(lambda,2));
    for i=1:size(lambda,2)
    
        [W0(i),W(:,i)]=RLDA(X1,X2,lambda(i));

        [Acc(i)]=XVal(X1,X2,lambda(i));
        
    end
    
    
