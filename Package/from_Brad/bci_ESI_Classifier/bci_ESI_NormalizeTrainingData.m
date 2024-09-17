function [hObject,handles,totdata]=bci_ESI_NormalizeTrainingData(hObject,handles,data,sigtype,num)


switch sigtype
    
    case 'SMR'
        
        spatdomainfield=handles.TRAINING.spatdomainfield;
        param=handles.TRAINING.(spatdomainfield).(sigtype).param;
        
        decodescheme=param.decodescheme;
        baselinetype=param.baselinetype;
        normtype=param.normtype;
        baselinestartidx=param.baselinestartidx;
        baselineendidx=param.baselineendidx;
        baseidx=param.baseidx;
        
        numchan=num.chan; numfreq=num.freq; numtask=num.task;
        taskidx=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.taskidx;
        
        broadband=handles.SYSTEM.broadband;
        if isequal(broadband,1)
            freqidxstart=numfreq+1;
        else
            freqidxstart=1;
        end
        
        totdata=struct('trialdata',[],'basedata',[],'labels',[],'windata',[]);
        for i=freqidxstart:numfreq+1
            
            switch decodescheme
                case 1 % None
                    
                case 2 % Single Trial
                    
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

                case 3 % Time Resolved

                    % If run baseline normalized, define run baseline
                    if isequal(baselinetype,3)
                        runbasedata=zeros(numchan,size(baseidx,2));
                        for j=baselinestartidx:baselineendidx
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
                                            trialdata{j}{k}{l}=trialdata{j}{k}{l}{i};
                                        end
                                    end

                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % BASELINE RELATIVE
                                case 2

                                    switch baselinetype

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        % NO BASELINE
                                        case 1 

                                            fprintf(2,'NO BASELINE DEFINED, NO BASELINE NORMALIZATION\n');

                                            for l=1:basewin
                                                basedata{j}{k}{l}=mean(basedata{j}{k}{l}{i},2);
                                            end
                                            basedata{j}{k}=horzcat(basedata{j}{k}{:});

                                            for l=1:trialwin
                                                trialdata{j}{k}{l}=trialdata{j}{k}{l}{i};
                                            end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        % TRIAL BASELINE
                                        case 2

                                            % Use trial baseline data to normalize baseline and trial windows
                                            basedatatmp=zeros(numchan,basewin);
                                            for l=1:basewin
                                                basedatatmp(:,l)=mean(basedata{j}{k}{l}{i},2);
                                            end
                                            meanbasedata=mean(basedatatmp,2);
                                            meantrialdata=mean(basedatatmp,2);

                                            % Apply normalization to all baseline and trial windows
                                            for l=1:basewin

                                                basedata{j}{k}{l}=(basedata{j}{k}{l}{i}./...
                                                    repmat(meanbasedata,[1 size(basedata{j}{k}{l}{i},2)]));

                                                basedata{j}{k}{l}=mean(basedata{j}{k}{l},2);

                                            end
                                            basedata{j}{k}=horzcat(basedata{j}{k}{:});

                                            for l=1:trialwin

                                                trialdata{j}{k}{l}=(trialdata{j}{k}{l}{i}./...
                                                    repmat(meantrialdata,[1 size(trialdata{j}{k}{l}{i},2)]));

                                            end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        % RUN BASELINE
                                        case 3

                                            % Use run baseline data to normalize baseline and trial windows
                                            meanbasedata=mean(runbasedata,2);
                                            meantrialdata=mean(runbasedata,2);

                                            % Apply normalization to all baseline and trial windows
                                            for l=1:basewin

                                                basedata{j}{k}{l}=(basedata{j}{k}{l}{i}./...
                                                    repmat(meanbasedata,[1 size(basedata{j}{k}{l}{i},2)]));

                                                basedata{j}{k}{l}=mean(basedata{j}{k}{l},2);

                                            end
                                            basedata{j}{k}=horzcat(basedata{j}{k}{:});

                                            for l=1:trialwin

                                                trialdata{j}{k}{l}=(trialdata{j}{k}{l}{i}./...
                                                    repmat(meantrialdata,[1 size(trialdata{j}{k}{l}{i},2)]));

                                            end
                                    end

                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % Z-score
                                case 3

                                    switch baselinetype
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                                            basedatatmp=zeros(numchan,basewin);
                                            for l=1:basewin
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

                                    % Apply normalization to all baseline and trial windows
                                    for l=1:basewin

                                        basedata{j}{k}{l}=(basedata{j}{k}{l}{i}-...
                                            repmat(meanbasedata,[1 size(basedata{j}{k}{l}{i},2)]))./...
                                            repmat(stdbasedata,[1 size(basedata{j}{k}{l}{i},2)]);

                                        basedata{j}{k}{l}=mean(basedata{j}{k}{l},2);

                                    end
                                    basedata{j}{k}=horzcat(basedata{j}{k}{:});

                                    for l=1:trialwin

                                        trialdata{j}{k}{l}=(trialdata{j}{k}{l}{i}-...
                                            repmat(meantrialdata,[1 size(trialdata{j}{k}{l}{i},2)]))./...
                                            repmat(stdtrialdata,[1 size(trialdata{j}{k}{l}{i},2)]);
                %                                             trialdata{j}{k}{l}=mean(trialdata{j}{k}{l},2);

                                    end
                            end

                            for l=1:trialwin

                                trialdata{j}{k}{l}=mean(trialdata{j}{k}{l},2);
                                trialdata{j}{k}{l}=trialdata{j}{k}{l}(:)';

                            end
                            trialdata{j}{k}=vertcat(trialdata{j}{k}{:})';

                        end

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
        
        
end
