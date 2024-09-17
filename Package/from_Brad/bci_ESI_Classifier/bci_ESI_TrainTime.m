function [hObject,handles]=bci_ESI_TrainTime(hObject,handles)
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE SPATIAL DOMAIN
spatdomainfield=handles.TRAINING.SpatDomainField;
spatdomain=get(handles.spatdomain,'value');
switch spatdomain
    case 1 % None
    case 2 % Sensor
        
        chaninclude=handles.TRAINING.(spatdomainfield).param.chanidxinclude;
        
    case 3 % ESI
        
        % DETERMINE CORTICAL PARCELLATION
        parcellation=get(handles.parcellation,'value');
        if isequal(parcellation,1)
            chaninclude=handles.TRAINING.(spatdomainfield).param.vertidxinclude;
        else
            chaninclude=handles.TRAINING.(spatdomainfield).param.clusteridxinclude;
        end
end

% CHANNEL INDICES MUST BE COLUMN FORMAT
if size(chaninclude,2)>size(chaninclude,1)
    chaninclude=chaninclude';
end
numchan=size(chaninclude,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE SAVEPATH
featspatdir=handles.TRAINING.(spatdomainfield).features.dir;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT DATA AND PARAMETERS
taskinfo=handles.TRAINING.(spatdomainfield).datainfo.taskinfo;
datatype=handles.TRAINING.(spatdomainfield).datainfo.traindatatype;
data=handles.TRAINING.(spatdomainfield).datainfo.data.(datatype);

[numeeg,numpnts,numfreq]=size(data);
numfreq=numfreq-1;
numtask=handles.TRAINING.(spatdomainfield).datainfo.numtask;
combinations=combnk(1:numtask,2);
numcomb=size(combinations,1);


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
        BOVO=zeros(numchan,numfreq,numcomb); RsqOVO=zeros(numchan,numfreq,numcomb);
        rOVO=zeros(numchan,numfreq,numtask); F_statOVO=zeros(numchan,numfreq,numtask);
        t_statOVO=zeros(numchan,numfreq,numcomb); p_statOVO=zeros(numchan,numfreq,numcomb);
        % one-vs-all
        BOVA=zeros(numchan,numfreq,numtask); RsqOVA=zeros(numchan,numfreq,numtask);
        rOVA=zeros(numchan,numfreq,numtask); F_statOVA=zeros(numchan,numfreq,numtask);
        t_statOVA=zeros(numchan,numfreq,numtask); p_statOVA=zeros(numchan,numfreq,numtask);
        
        string=['Performing Regression: ' num2str(freqres) ' Hz Resolution'];
        
    case 3 % Mahalanobis Distance
        
        feattype='Mahal';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE MAHAL STORAGE VARIABLES
        % one-vs-rest
        MDOVR=zeros(numchan,numfreq,numtask);
        % one-vs-one
        MDOVO=zeros(numchan,numfreq,numtask);
        % one-vs-all
        MDOVA=zeros(numchan,numfreq,numtask);
        
        string=['Computing Mahalanobis Distance: ' num2str(freqres) ' Hz Resolution'];
        
    case 4 % Linear Discriminant Analysis
        
        feattype='RLDA';
        % Define regularization options
        lambda=handles.TRAINING.param.lambda;
        numlambda=size(lambda,2);
        gamma=handles.TRAINING.param.gamma;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE RLDA STORAGE VARIABLES
        % one-vs-rest
        W0OVR=zeros(numfreq,numtask,numlambda);
        WOVR=zeros(numchan,numfreq,numtask,numlambda);
        PCOVR=zeros(numchan,numchan,numfreq,numtask,numlambda);
        AccOVR=zeros(numfreq,numtask,numlambda);
        % one-vs-one
        W0OVO=zeros(numfreq,numcomb,numlambda);
        WOVO=zeros(numchan,numfreq,numcomb,numlambda);
        PCOVO=zeros(numchan,numchan,numfreq,numcomb,numlambda);
        AccOVO=zeros(numfreq,numcomb,numlambda);
        % one-vs-all
        W0OVA=zeros(numfreq,numtask,numlambda);
        WOVA=zeros(numchan,numfreq,numtask,numlambda);
        PCOVA=zeros(numchan,numchan,numfreq,numtask,numlambda);
        AccOVA=zeros(numfreq,numtask,numlambda);
        
        string=['Performing LDA: ' num2str(freqres) ' Hz Resolution'];
        
    case 5 % Principle Component Analysis
        
        feattype='PCA';
        
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
        W0OVR=zeros(numfreq,numtask,numpc);
        AccOVR=zeros(numfreq,numtask,numpc);
        % one-vs-one
        UOVO=zeros(numchan,numchan,numfreq,numcomb);
        SOVO=zeros(numchan,numchan,numfreq,numcomb);
        VOVO=zeros(numchan,numchan,numfreq,numcomb);
        VEOVO=zeros(numfreq,numcomb,numpc);
        TVEOVO=zeros(numfreq,numcomb,numpc);
        WOVO=cell(numfreq,numcomb,numpc);
        W0OVO=zeros(numfreq,numcomb,numpc);
        AccOVO=zeros(numfreq,numcomb,numpc);
        % one-vs-all
        UOVA=zeros(numchan,numchan,numfreq,numtask);
        SOVA=zeros(numchan,numchan,numfreq,numtask);
        VOVA=zeros(numchan,numchan,numfreq,numtask);
        VEOVA=zeros(numfreq,numtask,numpc);
        TVEOVA=zeros(numfreq,numtask,numpc);
        WOVA=cell(numfreq,numtask,numpc);
        W0OVA=zeros(numfreq,numtask,numpc);
        AccOVA=zeros(numfreq,numtask,numpc);
        
        string=['Performing PCA: ' num2str(freqres) ' Hz Resolution'];
        
    case 6 % Fisher LDA
        
        feattype='FDA';
        % Define regularization options
        lambda=handles.TRAINING.param.lambda;
        gamma=handles.TRAINING.param.gamma;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INITIALIZE FDA STORAGE VARIABLES
        % one-vs-rest
        WOVR=zeros(numchan,numfreq,numtask);
        % one-vs-one
        WOVO=zeros(numchan,numfreq,numtask);
        % one-vs-all
        WOVA=zeros(numchan,numfreq,numtask);
        
        string=['Performing Fisher LDA: ' num2str(freqres) ' Hz Resolution'];
        
    case {7,8}
end


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          POPULATE BCI OPTIONS                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% REMOVE ALL SELECTED FEATURES FROM DISPLAY LIST - REPOPULATE HERE
[hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,spatdomainfield,feattype,'Time');

% ADD BCI TASKS TO FEATURE OPTIONS
bcitask=cell(1,numcomb+1);
for i=1:numcomb
    bcitask{i+1}=[num2str(combinations(i,1)) '-vs-' num2str(combinations(i,2))];
end

for i=numcomb+2:2*numcomb+1
    bcitask{i}=[num2str(combinations(i-1-numcomb,1)) ' , ' num2str(combinations(i-1-numcomb,2)) ' vs Rest'];
end

% for i=1:2*numcomb+2:3*numcomb+1
%     bcitask{i}=[num2str(combinations(i-1-numcomb,1)) ' , ' num2str(combinations(i-1-numcomb,2)) ' vs All'];
% end

set(handles.bcitask1,'string',bcitask,'value',1)
set(handles.bcitask2,'string',bcitask,'value',1)
set(handles.bcitask3,'string',bcitask,'value',1)
handles.(spatdomainfield).bcitask{1}=bcitask;
handles.(spatdomainfield).bcitask{2}=bcitask;
handles.(spatdomainfield).bcitask{3}=bcitask;

% ADD TASKS TO FEAUTRE OPTIONS
handles.BCI.featureoptions.task.(spatdomainfield)=bcitask;

% BCI WINDOWS
% bciwin=[cell(1);cellstr(num2str(freqvect'));{'Broadband'}];
% set(handles.bcifreq1,'string',bcifreq,'value',1)
% set(handles.bcifreq2,'string',bcifreq,'value',1)
% set(handles.bcifreq3,'string',bcifreq,'value',1)
% handles.(spatdomainfield).bcifreq{1}=[cell(1);cellstr(num2str(freqvect'))];
% handles.(spatdomainfield).bcifreq{2}=[cell(1);cellstr(num2str(freqvect'))];
% handles.(spatdomainfield).bcifreq{3}=[cell(1);cellstr(num2str(freqvect'))];

% ADD FREQUENCIES TO FEAUTRE OPTIONS
% handles.BCI.featureoptions.freq.(spatdomainfield)=bcifreq;

% ORGANIZE FEATURE OPTIONS
for i=1:3
    featvar=strcat('bcifeat',num2str(i));
    bcifeat=cellstr(get(handles.(featvar),'string'));
    if isempty(bcifeat); bcifeat=cell(1); end
    if ~ismember(feattype,bcifeat)
        bcifeat=[bcifeat;feattype];
    end
    set(handles.(featvar),'string',bcifeat)
end

% ADD FEATURE TYPE TO FEATURE OPTIONS
if ~ismember(feattype,handles.BCI.featureoptions.feat.(spatdomainfield))
    handles.BCI.featureoptions.feat.(spatdomainfield){end+1}=feattype;
end

% RESET BCI PARAMETERS
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,1,'Reset');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,2,'Reset');
[hObject,handles]=bci_ESI_ResetBCI(hObject,handles,3,'Reset');


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          CONSTRUCT CLASSIFIER                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TotData=struct('trialdata',[],'basedata',[],'labels',[],'classdata',[]);


h=waitbar(numfreq,string);
for i=1:numfreq+1
    waitbar(i/(numfreq+1))
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CONVERT FILTERED TIME DATA TO FREQUENCY DOMAIN
    
    % PERFORM FOR EACH INDIVIDUAL FREQUENCY
    if strcmp(datatype,'bci2000');
        
        % COMPUTE AMPLITUDE OF FREQUENCY SIGNAL
        TrialStruct=handles.TRAINING.(spatdomainfield).trialstruct;
        spatdomain=get(handles.spatdomain,'value');
        switch spatdomain
            case 1 % None
            case 2 % Sensor
                A=squeeze(A)';
                A=abs(A);
                [hObject,handles,BaselineData,TrialData]=...
                    bci_ESI_TrialSections(hObject,handles,taskinfo,...
                    TrialStruct,A,250/1000*handles.SYSTEM.dsfs);

                TotData(i).trialdata=TrialData;
                TotData(i).labels=1:numtask;

            case {3,4} % ESI or fESI
                Noise=get(handles.Noise,'value');
                switch Noise
                    case 1 % None
                    case 2 % No Noise Modeling
                        ChanExclude=handles.TRAINING.Source.vertidxexclude;

                        INV=handles.ESI.inv.nomodel; 
                        INV(ChanExclude,:)=[];

                        A_real=squeeze(real(A))';
                        A_imag=squeeze(imag(A))';

                        A_real_source=INV*A_real;
                        A_imag_source=INV*A_imag;

                        A_source=sqrt(A_real_source.^2+A_imag_source.^2);

                        [hObject,handles,BaselineData,TrialData]=...
                            bci_ESI_TrialSections(hObject,handles,taskinfo,...
                            TrialStruct,A_source,250/1000*handles.SYSTEM.dsfs);
                        clear A_source

                        TotData(i).trialdata=TrialData;
                        TotData(i).labels=1:numtask;

                    case {3,4} % Diagonal or Full
                        ChanExclude=handles.TRAINING.Source.vertidxexclude;

                        INVreal=handles.ESI.inv.real;
                        INVreal(ChanExclude,:)=[];
                        INVimag=handles.ESI.inv.imag;
                        INVimag(ChanExclude,:)=[];

                        A_real=squeeze(real(A))';
                        A_imag=squeeze(imag(A))';

                        A_real_source=INVreal*A_real;
                        A_imag_source=INVimag*A_imag;

                        A_source=sqrt(A_real_source.^2+A_imag_source.^2);
                        A_source=A_source(chaninclude,:);

                        [hObject,handles,BaselineData,TrialData]=...
                            bci_ESI_TrialSections(hObject,handles,taskinfo,...
                            TrialStruct,A_source,250/1000*handles.SYSTEM.dsfs);
                        clear A_source

                        TotData(i).trialdata=TrialData;
                        TotData(i).labels=1:numtask;

                end
        end
        
    elseif strcmp(datatype,'esibci')
        
        BaselineData=cell(1,numtask);
        TrialData=cell(1,numtask);
        ClassData=cell(1,numtask);
        
        TaskInd=1:numtask;
        l=ones(1,numtask);
        for j=2:size(taskinfo,1)
            for k=1:numtask
                if isequal(taskinfo{j,2},TaskInd(k))
                    BaseStart=taskinfo{j,3};
                    BaseEnd=taskinfo{j,4};
                    TrialStart=taskinfo{j,5};
                    TrialEnd=taskinfo{j,6};
                    
                    % Stored trial baseline data
                    BaselineData{k}=[BaselineData{k} data(:,BaseStart:BaseEnd,i)];
                    % Trial baseline mean (across time)
                    CurrentMeanBase=mean(data(:,BaseStart:BaseEnd,i),2);
                    % Trial online data
                    CurrentTrial=data(:,TrialStart:TrialEnd,i);
                    % Trial online, baseline normalized data
                    clear CurrentTrial2
                    for m=1:size(CurrentTrial,1)
                        CurrentTrial2(m,:)=CurrentTrial(m,:)./CurrentMeanBase(m);
                    end
                    
                    % Stored online normalized data
                    TrialData{k}=[TrialData{k} CurrentTrial2];
                    
                    ClassData{k}{l(k)}=CurrentTrial2;
                    l(k)=l(k)+1;
                end
            end
        end
        
        for j=1:numtask
            if isequal(sum(sum(BaselineData{j},1),2),0) || isequal(sum(sum(TrialData{j},1),2),0)
                error('TRAINING DATA FOR %s DOMAIN IS EMPTY',spatdomainfield)
            end
        end
            
        TotData(i).trialdata=TrialData;
        TotData(i).basedata=BaselineData;
        TotData(i).labels=1:numtask;
        TotData(i).classdata=ClassData;
        
    end
        
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ONE-vs-REST (OVR) FEATURE EXTRACTION
    for j=1:numtask
        
        if ismember(feattype,{'RLDA','PCA','FDA'})
            
            % If trials are windowed
            if iscell(BaselineData{j})
                X1=[]; X2=[];
                % Go through each trial and concatenate windows
                for l=1:size(BaselineData{j},2)
                    X1=[X1;BaselineData{j}{l}(:,:)'];
                    X2=[X2;TrialData{j}{l}(:,:)'];
                end
            else
                X1=horzcat(BaselineData{:})';
                X2=TrialData{j}(:,:)';
            end
            
%             X1outidx=moutlier1(X1,.05);
%             X1(X1outidx,:)=[];
%             X2outidx=moutlier1(X2,.05);
%             X2(X2outidx,:)=[];
%             
            if strcmp(feattype,'RLDA')
                
                for k=1:size(lambda,2)
        
                    [W0OVR(i,j,k),WOVR(:,i,j,k),PCOVR(:,:,i,j,k)]=RLDA(X1,X2,lambda(k));
                    AccOVR(i,j,k)=XVal(X1,X2,lambda(k));
            
                end
                
            elseif strcmp(feattype,'PCA')
                
                Compile=[X1;X2];
%                 [coeff, score, latent, tsquared, explained] = pca(Compile);
                C=cov(Compile);
                [UOVR(:,:,i,j),SOVR(:,:,i,j),VOVR(:,:,i,j)]=svd(C);
                
                Stmp=diag(SOVR(:,:,i,j));
                for k=1:size(Stmp,1)
                    VEOVR(i,j,k)=Stmp(k)/sum(Stmp,1);
                    TVEOVR(i,j,k)=sum(Stmp(1:k))/sum(Stmp,1);
                end
                
                max(VEOVR(i,j,:))
                
                for k=1:numpc
                    [WOVR{i,j,k},W0OVR(i,j,k),AccOVR(i,j,k)]=PCALDA(X1,X2,UOVR(:,:,i,j),1:k);
                end
                
            elseif strcmp(feattype,'FDA')
                
                [WOVR(:,i,j),DBOVR(i,j)]=FDA(X1,X2);
                
            end
                
        elseif ismember(feattype,{'Mahal','Regress'})
            
            for k=1:numchan

                % If trials are windowed
                if iscell(BaselineData{j})
                    X1=[]; X2=[];
                    % Go through each trial and concatenate windows
                    for l=1:size(BaselineData{j},2)
                        X1=[X1;BaselineData{j}{l}(k,:)'];
                        X2=[X2;TrialData{j}{l}(k,:)'];
                    end
                else
                    % Or select single trial value for each channel
                    X1=BaselineData{j}(k,:)';
                    X2=TrialData{j}(k,:)';
                end
                
%                 X1outidx=moutlier1(X1,.05);
%                 X1(X1outidx,:)=[];
%                 X2outidx=moutlier1(X2,.05);
%                 X2(X2outidx,:)=[];
                
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
                    
                end
                
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
    % ONE-vs-ONE (OVO) FEATURE EXTRACTION
    for j=1:numcomb
    
        if ismember(feattype,{'RLDA','PCA','FDA'})
            
            ChanVal=cell(1,2);   
            for l=1:2
                % If trials are windowed
                if iscell(TrialData{combinations(j,l)})
                    % Go through each trial and concatenate windows
                    for m=1:size(TrialData{l},2)
                        ChanVal{l}=[ChanVal{l};TrialData{combinations(j,l)}{m}(:,:)'];
                    end
                else
                    ChanVal{l}=TrialData{combinations(j,l)}(:,:)';
                end
            end

            X1=ChanVal{1};
            X2=ChanVal{2};
            
%             X1outidx=moutlier1(X1,.05);
%             X1(X1outidx,:)=[];
%             X2outidx=moutlier1(X2,.05);
%             X2(X2outidx,:)=[];
            
            if strcmp(feattype,'RLDA')
                
                for k=1:size(lambda,2)
        
                    [W0OVO(i,j,k),WOVO(:,i,j,k),PCOVO(:,:,i,j,k)]=RLDA(X1,X2,lambda(k));
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
                
                for k=1:numpc
                    [WOVO{i,j,k},W0OVO(i,j,k),AccOVO(i,j,k)]=PCALDA(X1,X2,UOVO(:,:,i,j),1:k);
                end

            elseif strcmp(feattype,'FDA')
                
                [WOVO(:,i,j),DBOVO(i,j)]=FDA(X1,X2);
                
            end
            
        elseif ismember(feattype,{'Mahal','Regress'})
            
            for k=1:numchan
            
                ChanVal=cell(1,2);   
                for l=1:2
                    % If trials are windowed
                    if iscell(TrialData{combinations(j,l)})
                        % Go through each trial and concatenate windows
                        for m=1:size(TrialData{l},2)
                            ChanVal{l}=[ChanVal{l};TrialData{combinations(j,l)}{m}(k,:)'];
                        end
                    else
                        % Or select single trial value for each channel
                        ChanVal{l}=TrialData{combinations(j,l)}(k,:)';
                    end
                end

                X1=ChanVal{1};
                X2=ChanVal{2};
                
%                 X1outidx=moutlier1(X1,.05);
%                 X1(X1outidx,:)=[];
%                 X2outidx=moutlier1(X2,.05);
%                 X2(X2outidx,:)=[];
                
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
                    
                end
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
    % ONE-vs-ALL (OVA) FEATURE EXTRACTION
    TaskInd=1:numtask;
    for j=1:numtask
    
        if ismember(feattype,{'RLDA','PCA','FDA'})
            
            One=j; All=TaskInd; All(j)=[];
            
            ChanVal=cell(1,2);
            % If trials are windowed
            if iscell(TrialData{j})

                % Concatenate all windows for task "One"
                for l=1:size(TrialData{j},2)
                    ChanVal{1}=[ChanVal{1};TrialData{One}{l}(:,:)'];
                end

                % Concatenate all windows for task "All"
                for l=1:size(All,2)
                    for m=1:size(TrialData{All(l)},2)
                        ChanVal{2}=[ChanVal{2};TrialData{All(l)}{m}(:,:)'];
                    end
                end

            else

                % Or select single trial value for each channel
                ChanVal{1}=TrialData{One}(:,:)';
                ChanVal{2}=[];
                for l=1:size(All,2)
                    ChanVal{2}=vertcat(ChanVal{2},TrialData{All(l)}(:,:)');
                end

            end

            X1=ChanVal{1};
            X2=ChanVal{2};
            
%             X1outidx=moutlier1(X1,.05);
%             X1(X1outidx,:)=[];
%             X2outidx=moutlier1(X2,.05);
%             X2(X2outidx,:)=[];
%             
            if strcmp(feattype,'RLDA')
                
                for k=1:size(lambda,2)
                    
                    [W0OVA(i,j,k),WOVA(:,i,j,k),PCOVA(:,:,i,j,k)]=RLDA(X1,X2,lambda(k));
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
                
                for k=1:numpc
                    [WOVA{i,j,k},W0OVA(i,j,k),AccOVA(i,j,k)]=PCALDA(X1,X2,UOVA(:,:,i,j),1:k);
                end
                
            elseif strcmp(feattype,'FDA')
                
                [WOVA(:,i,j),DBOVA(i,j)]=FDA(X1,X2);
                
            end
            
        elseif ismember(feattype,{'Mahal','Regress'})
            
            One=j; All=TaskInd; All(j)=[];
            
            for k=1:numchan
                
                ChanVal=cell(1,2);
                % If trials are windowed
                if iscell(TrialData{j})
                    
                    % Concatenate all windows for task "One"
                    for l=1:size(TrialData{j},2)
                        ChanVal{1}=[ChanVal{1};TrialData{One}{l}(k,:)'];
                    end
                    
                    % Concatenate all windows for task "All"
                    for l=1:size(All,2)
                        for m=1:size(TrialData{All(l)},2)
                            ChanVal{2}=[ChanVal{2};TrialData{All(l)}{m}(k,:)'];
                        end
                    end
                    
                else
                    
                    % Or select single trial value for each channel
                    ChanVal{1}=TrialData{One}(k,:)';
                    ChanVal{2}=[];
                    for l=1:size(All,2)
                        ChanVal{2}=vertcat(ChanVal{2},TrialData{All(l)}(k,:)');
                    end
                    
                end
                
                X1=ChanVal{1};
                X2=ChanVal{2};
                
%                 X1outidx=moutlier1(X1,.05);
%                 X1(X1outidx,:)=[];
%                 X2outidx=moutlier1(X2,.05);
%                 X2(X2outidx,:)=[];
                
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
                    
                end
                
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
close(h)
set(handles.freqfeat,'value',1)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE FEATURE FILES

% Save OVR file
k=1;
SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',feattype,'_One_vs_Rest_',num2str(k),'.mat');
% Dont duplicate file (may want to load later)
while exist(SaveFeatFile,'file')
    k=k+1;
    SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',feattype,'_One_vs_Rest_',num2str(k),'.mat');
end

switch traintype
    case 1 % None
    case 2 % Regression
        
        tmp.B=BOVR; tmp.R=rOVR; tmp.Rsq=RsqOVR; tmp.R=rOVR; tmp.F_stat=F_statOVR;
        tmp.t_stat=t_statOVR; tmp.pval=p_statOVR;
        
        tmphandle='regress';
        
    case 3 % Mahalanobis Distance
        
        tmp.MD=MDOVR;
        
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
        
        tmp.W=WOVR;
        
        tmphandle='fda'; tmp.DB=DBOVR;
        
    case {7,8}
end
tmp.totdata=TotData; tmp.chaninclude=chaninclude;
if strcmp(spatdomainfield,'SourceCluster')
    clusters=handles.ESI.CLUSTER.clusters;
    clusters{end}=[];
    tmp.clusters=clusters;
end
tmp.label='One-vs-Rest';

SaveVar=matlab.lang.makeValidName(strcat('Save',feattype,spatdomainfield));
eval([SaveVar ' = tmp;']);
save(SaveFeatFile,SaveVar,'-v7.3');
    
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).file{1}=SaveFeatFile;
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).label{1}=num2str(1:numtask)';
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).type{1}='One-vs-Rest';

    
% Save OVO file
clear SaveFeatFile SaveVar tmp
k=1;
SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',feattype,'_One_vs_One_',num2str(k),'.mat');
% Dont duplicate file (may want to load later)
while exist(SaveFeatFile,'file')
    k=k+1;
    SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',feattype,'_One_vs_One_',num2str(k),'.mat');
end    
    
switch traintype
    case 1 % None
    case 2 % Regression
        
        tmp.B=BOVO; tmp.R=rOVO; tmp.Rsq=RsqOVO; tmp.R=rOVO; tmp.F_stat=F_statOVO;
        tmp.t_stat=t_statOVO; tmp.pval=p_statOVO;
        
        tmphandle='regress';
        
    case 3 % Mahalanobis Distance
        
        tmp.MD=MDOVO;
        
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
        
    case {7,8}
end
tmp.totdata=TotData; tmp.chaninclude=chaninclude;
if strcmp(spatdomainfield,'SourceCluster')
    clusters=handles.ESI.CLUSTER.clusters;
    clusters{end}=[];
    tmp.clusters=clusters;
end
tmp.label='One-vs-One';

SaveVar=matlab.lang.makeValidName(strcat('Save',feattype,spatdomainfield));
eval([SaveVar ' = tmp;']);
save(SaveFeatFile,SaveVar,'-v7.3');
    
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).file{2}=SaveFeatFile;
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).label{2}=num2str(combinations);
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).type{2}='One-vs-One';
    
% Save OVA file
clear SaveFeatFile SaveVar tmp
k=1;
SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',feattype,'_One_vs_All_',num2str(k),'.mat');
% Dont duplicate file (may want to load later)
while exist(SaveFeatFile,'file')
    k=k+1;
    SaveFeatFile=strcat(featspatdir,'\',spatdomainfield,'_Freq_',feattype,'_One_vs_All_',num2str(k),'.mat');
end    
    
switch traintype
    case 1 % None
    case 2 % Regression
        
        tmp.B=BOVA; tmp.R=rOVA; tmp.Rsq=RsqOVA; tmp.R=rOVA; tmp.F_stat=F_statOVA;
        tmp.t_stat=t_statOVA; tmp.pval=p_statOVA;
        
        tmphandle='regress';
        
    case 3 % Mahalanobis Distance
        
        tmp.MD=MDOVA;
        
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
        
    case {7,8}
end
tmp.totdata=TotData; tmp.chaninclude=chaninclude;
if strcmp(spatdomainfield,'SourceCluster')
    clusters=handles.ESI.CLUSTER.clusters;
    clusters{end}=[];
    tmp.clusters=clusters;
end
tmp.label='One-vs-All';

SaveVar=matlab.lang.makeValidName(strcat('Save',feattype,spatdomainfield));
eval([SaveVar ' = tmp;']);
save(SaveFeatFile,SaveVar,'-v7.3');
    
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).file{3}=SaveFeatFile;
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).label{3}=num2str(1:numtask)';
handles.TRAINING.(spatdomainfield).features.freq.(tmphandle).type{3}='One-vs-All';
    
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS


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

    PC=(n1*C1+n2*C2)/(n1+n2);

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
    
%     LinClass=ClassificationDiscriminant.fit([X1;X2],[ones(size(X1,1),1);2*ones(size(X2,1),1)]);
%     W0=LinClass.Coeffs(1,2).Const;
%     W=LinClass.Coeffs(1,2).Linear;
%     pause

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
%     scatter(Y1(:,1),Y1(:,2),'b'); hold on
%     scatter(Y2(:,1),Y2(:,2),'r');
%     quiver(DB,-2,0,4,'k');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRINCIPLE COMPONENT ANALYSIS
    
function [W,W0,Acc]=PCALDA(X1,X2,U,PCs)

    Filters=U(:,PCs); 
    
    if iscell(X1)
        X1=horzcat(X1{:});
    end
    
    if iscell(X2)
        X2=horzcat(X2{:});
    end
    
    X1=X1*Filters;
    X2=X2*Filters;
    
    lambda=.5;
    
    [W0,W]=RLDA(X1,X2,lambda);
    
    [Acc]=XVal(X1,X2,lambda);
    
    
    
    
    
    
    
    
    
    
    

