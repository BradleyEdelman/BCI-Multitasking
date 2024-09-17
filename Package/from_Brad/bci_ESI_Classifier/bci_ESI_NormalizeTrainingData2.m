function [hObject,handles,totdata]=bci_ESI_NormalizeTrainingData2(hObject,handles,data,sigtype,num)

totdata=struct('trialdata',[],'basedata',[],'labels',[],'windata',[]);

spatdomainfield=handles.TRAINING.spatdomainfield;
param=handles.TRAINING.(spatdomainfield).(sigtype).param;

decodescheme=param.decodescheme;
baselinetype=param.baselinetype;
normtype=param.normtype;
baselinestartidx=param.baselinestartidx;
baselineendidx=param.baselineendidx;
baseidx=param.baseidx;
baseidxlength=param.baseidxlength;

numchan=num.chan; numfreq=num.freq; numtask=num.task;
taskidx=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.taskidx;

switch sigtype
    
    case 'SMR'
        
        broadband=handles.SYSTEM.broadband;
        if isequal(broadband,1)
            freqidxstart=numfreq+1;
        else
            freqidxstart=1;
        end
        
        for i=freqidxstart:numfreq+1
            
            switch decodescheme
                case 1 % None
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % SINGLE TRIAL   
                case 2
                    
                    runbasedata=[];
                    for j=1:size(data.runbase,2)
                        runbasedata=[runbasedata mean(data.runbase{j}{i},2)];
                    end
                    
                    basedata=cell(1,numtask);
                    trialdata=cell(1,numtask);
                    windata=cell(1,numtask);
                    
                    for j=1:numtask
                        
                        basedata{j}=data.base(data.targetidx==taskidx(j));
                        trialdata{j}=data.trial(data.targetidx==taskidx(j));
                        
                        trialtmp=size(basedata{j},2);
                        for k=1:trialtmp
                            
                            if isequal(baselinetype,2)
                                basedata{j}{k}=mean(basedata{j}{k}{i}(:,baselinestartidx:baselineendidx),2);
                                trialdata{j}{k}=trialdata{j}{k}{i}./repmat(basedata{j}{k},[1 size(trialdata{j}{k}{i},2)]);
                            else
                                basedata{j}{k}=basedata{j}{k}{i};
                                trialdata{j}{k}=trialdata{j}{k}{i};
                            end
                            
                            trialdata{j}{k}=mean(trialdata{j}{k},2);
                            trialdata{j}{k}=trialdata{j}{k}(:);
                            
                        end
                        
                        windata{j}=vertcat(trialdata{j}');
                        windata{j}=horzcat(windata{j}{:});
                        
                    end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TIME RESOLVED    
                case 3
                    
                    % If run baseline normalized, define run baseline
                    if isequal(baselinetype,3)
                        runbasedata=zeros(numchan,baseidxlength);
                        for j=baseidx
                            runbasedata(:,j)=mean(data.runbase{j}{i},2);
                        end
                    else
                        runbasedata=[];
                    end
                    
                    basedata=cell(1,numtask);
                    trialdata=cell(1,numtask);
                    windata=cell(1,numtask);
                    
                    for j=1:numtask
                        
                        basedata{j}=data.base(data.targetidx==taskidx(j));
                        trialdata{j}=data.trial(data.targetidx==taskidx(j));
                        
                        trialtmp=size(basedata{j},2);
                        for k=1:trialtmp
                            
                            basewin=size(basedata{j}{k},2);%FIND MAX SIZE TRIAL
                            trialwin=size(trialdata{j}{k},2); %FIND MAX SIZE TRIAL
                            
                            switch baselinetype
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % NO BASELINE
                                case 1
                                    
                                    % use trial baseline data to normalize baseline windows
                                    basedatatmp=zeros(numchan,basewin);
                                    for l=1:basewin
                                        basedatatmp(:,l)=mean(basedata{j}{k}{l}{i},2);
                                    end
                                    meanbasedata=mean(basedatatmp,2);
                                    stdbasedata=std(basedatatmp,0,2);

                                    % Use trial data to normalize trial windows
                                    trialdatatmp=zeros(numchan,trialwin);
                                    for l=1:trialwin
                                        trialdatatmp(:,l)=mean(trialdata{j}{k}{l}{i},2);
                                    end
                                    meantrialdata=mean(trialdatatmp,2);
                                    stdtrialdata=std(trialdatatmp,0,2);
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % TRIAL BASELINE    
                                case 2
                                    
                                    % Use trial baseline data to normalize baseline and trial windows
                                    if baseidxlength>basewin; baseidxlength=basewin; end
                                    basedatatmp=zeros(numchan,baseidxlength);
                                    for l=basewin-baseidxlength+1:basewin
                                        basedatatmp(:,l)=mean(basedata{j}{k}{l}{i},2);
                                    end
                                    meanbasedata=mean(basedatatmp,2);
                                    stdbasedata=std(basedatatmp,0,2);

                                    meantrialdata=mean(basedatatmp,2);
                                    stdtrialdata=std(basedatatmp,0,2);
                                   
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % RUN BASELINE  
                                case 3
                                    
                                    % Use run baseline data to normalize baseline and trial windows
                                    meanbasedata=mean(runbasedata,2);
                                    stdbasedata=std(runbasedata,0,2);

                                    meantrialdata=mean(runbasedata,2);
                                    stdtrialdata=std(runbasedata,0,2);
                                    
                            end
                            
                            switch normtype
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % NO NORMALIZATION
                                case 1 % None
                                    
                                    for l=1:basewin
                                        basedata{j}{k}{l}=mean(basedata{j}{k}{l}{i},2);
                                    end
                                    basedata{j}{k}=horzcat(basedata{j}{k}{:});
                                    
                                    for l=1:trialwin
                                        if ~isempty(trialdata{j}{k}{l})
                                            trialdata{j}{k}{l}=mean(trialdata{j}{k}{l}{i},2);
                                        end
                                    end
                                    trialdata{j}{k}=horzcat(trialdata{j}{k}{:});
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % BASELINE RELATIVE
                                case 2
                                            
                                    % Apply normalization to all baseline and trial windows
                                    if baseidxlength>basewin; baseidxlength=basewin; end
                                    for l=basewin-baseidxlength+1:basewin
                                        basedata{j}{k}{l}=mean(basedata{j}{k}{l}{i},2)./meanbasedata;
                                    end
                                    basedata{j}{k}=horzcat(basedata{j}{k}{basewin-baseidxlength+1:basewin});

                                    for l=1:trialwin
                                        trialdata{j}{k}{l}=mean(trialdata{j}{k}{l}{i},2)./meantrialdata;
                                    end
                                    trialdata{j}{k}=horzcat(trialdata{j}{k}{:});

                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % Z-score
                                case 3
                                    
                                    if ~isequal(sum(stdbasedata),0) && ~isequal(sum(stdtrialdata),0)
                                        % Apply normalization to all baseline and trial windows
                                        if isempty(baseidxlength)
                                            baseidxlength=basewin;
                                        elseif baseidxlength>basewin 
                                            baseidxlength=basewin;
                                        end
                                    
                                        for l=basewin-baseidxlength+1:basewin
                                            basedata{j}{k}{l}=(mean(basedata{j}{k}{l}{i},2)-meanbasedata)./stdbasedata;
                                        end
                                        basedata{j}{k}=horzcat(basedata{j}{k}{basewin-baseidxlength+1:basewin});

                                        for l=1:trialwin
                                            trialdata{j}{k}{l}=(mean(trialdata{j}{k}{l}{i},2)-meantrialdata)./stdtrialdata;
                                        end
                                        trialdata{j}{k}=horzcat(trialdata{j}{k}{:});
                                        
                                    else
                                        basedata{j}{k}=[];
                                        trialdata{j}{k}=[];
                                    end
                                    
                            end
                            
                        end
                        
                        % Remove empty trials/baselines
                        emptytrial=find(cellfun(@isempty,trialdata{j}));
                        emptybase=find(cellfun(@isempty,basedata{j}));
                        uniqueempty=unique([emptytrial,emptybase]);
                        trialdata{j}(uniqueempty)=[];
                        basedata{j}(uniqueempty)=[];

                        windata{j}=horzcat(trialdata{j}{:});
                        
                    end
                       
            end

            totdata(i).trialdata=trialdata;
            totdata(i).windata=windata;
            totdata(i).basedata=basedata;
            totdata(i).runbasedata=runbasedata;
            totdata(i).labels=1:numtask;

        end
        
        
    case 'SSVEP'
        
        target=str2double(handles.SSVEP.target);
        target(isnan(target))=[];
        targetfreq=str2double(handles.SSVEP.targetfreq);
        targetfreq(isnan(targetfreq))=[];
        
        switch decodescheme
                case 1 % None
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % SINGLE TRIAL   
                case 2
        
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TIME RESOLVED    
                case 3
                    
                    basedata=cell(1,numtask);
                    trialdata=cell(1,numtask);
                    windata=cell(1,numtask);
                    
                    for j=1:numtask
                        
                        basedata{j}=data.base(data.targetidx==taskidx(j));
                        trialdata{j}=data.trial(data.targetidx==taskidx(j));
                        totwin=0; trialwinstart=1; clear F
                        
                        trialtmp=size(basedata{j},2);
                        for k=1:trialtmp
                            
                            basewin=size(basedata{j}{k},2);
                            trialwin=size(trialdata{j}{k},2);
                            
                            % For each window (in each trial)
                            for l=1:trialwin
                                
                                wintmp=trialdata{j}{k}{l};
                                
                                % For each channel 
                                for m=1:size(wintmp,1)
                                    
                                    % Extract all target frequencies
                                    for n=1:numtask
                                    
                                        t=1/handles.SYSTEM.dsfs:1/handles.SYSTEM.dsfs:size(wintmp,2)/handles.SYSTEM.dsfs;
                                        COS=dot(wintmp(m,:),cos(2*pi*targetfreq(n)*t))^2;
                                        SIN=dot(wintmp(m,:),sin(2*pi*targetfreq(n))*t)^2;

                                        A=sqrt(COS+SIN);

                                        COS2=dot(wintmp(m,:),cos(2*pi*2*targetfreq(n)*t))^2;
                                        SIN2=dot(wintmp(m,:),sin(2*pi*2*targetfreq(n))*t)^2;

                                        B=sqrt(COS2+SIN2);

                                        F(l+totwin,n+(m-1)*2*numtask)=A;
                                        F(l+totwin,n+numtask+(m-1)*2*numtask)=B;
                                        
                                    end
                                    
                                end
                                
                            end
                            totwin=totwin+trialwin;
                            trialdata{j}{k}=F(trialwinstart:totwin,:);
                            trialwinstart=trialwinstart+trialwin;
                            
                        end
                        
                        windata{j}=F;
                        
                        
                        totdata(j).trialdata=trialdata{j};
                        totdata(j).windata=windata{j};
                        totdata(j).basedata=basedata;
                        totdata(j).runbasedata=[];
                        totdata(j).labels=1:numtask;
                        
                    end

                    
        end
            
        
end
