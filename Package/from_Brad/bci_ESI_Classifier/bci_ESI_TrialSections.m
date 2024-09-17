function [hObject,handles,baselinedata,trialdata]=bci_ESI_TrialSections(hObject,handles,TaskInfo,TrialStruct,Data,window)

% BREAK DATA INTO BASELINE AND TASK SEGMENTS FOR EACH TRIAL
numtrial=size(TaskInfo,1)-1;
if strcmp(TrialStruct.tasktype,'Cursor')
    for j=1:numtrial
        base{j}=Data(:,TaskInfo{j+1,3}:TaskInfo{j+1,4});
        trial{j}=Data(:,TaskInfo{j+1,4}:TaskInfo{j+1,6});
    end
elseif strcmp(TrialStruct.tasktype,'Stimulus')
    for j=1:numtrial
        base{j}=Data(:,TaskInfo{j+1,7}:TaskInfo{j+1,4});
        trial{j}=Data(:,TaskInfo{j+1,4}:TaskInfo{j+1,5});
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IF WANT TO NORMALIZE DATA
tempdomain=get(handles.tempdomain,'Value');
if isequal(tempdomain,3)
    for j=1:numtrial

        for k=1:size(base{j},2)
            Mean=mean(base{j}(:,k),1);
            SD=std(base{j}(:,k),1);
            base{j}(:,k)=(base{j}(:,k)-repmat(Mean,[size(base{j},1),1]))./SD;
        end
        
        for k=1:size(trial{j},2)
            Mean=mean(trial{j}(:,k),1);
            SD=std(trial{j}(:,k),1);
            trial{j}(:,k)=(trial{j}(:,k)-repmat(Mean,[size(trial{j},1),1]))./SD;
        end
        
    end
end

% SUBDIVIDE EACH TRIAL INTO WINDOWED SEGMENTS
if ischar(window) && strcmp(window,'Full')
    
    % FULL TRIAL DATA
    for j=1:numtrial
        base2(:,j)=sum(base{j},2);
        trial2(:,j)=sum(trial{j},2);
    end
    
elseif isnumeric(window)
    
    % Identify maximum trial length possible within paradigm
    tasktype=TrialStruct.tasktype;
    switch tasktype
        case 'Cursor'
            maxdur=TrialStruct.maxfeed*handles.SYSTEM.dsfs;
        case 'Stimulus'
            maxdur=TrialStruct.stimdur*handles.SYSTEM.dsfs;
    end
    mindur=round(100/1000*handles.SYSTEM.dsfs);
    
    % 100ms minimum
    if window>=mindur && window<=maxdur
        
        for j=1:numtrial

            % Separate Baseline
            startIdx=1;
            endIdx=startIdx+window-1;
            k=1;
            while endIdx<size(base{j},2) % Ignore last window if too small
                base2{j}(:,k)=sum(base{j}(:,startIdx:endIdx),2);
                startIdx=endIdx;
                endIdx=startIdx+window-1;
                k=k+1;
            end

            % Separate Trial
            startIdx=1;
            endIdx=startIdx+window-1;
            k=1;
            while endIdx<size(trial{j},2)
                trial2{j}(:,k)=sum(trial{j}(:,startIdx:endIdx),2);
                startIdx=endIdx;
                endIdx=startIdx+window-1;
                k=k+1;
            end

        end
    end
end

% Separate baseline and trial data into the different tasks
numtask=size(unique(cell2mat((TaskInfo(2:end,2)))),1);
for j=1:numtask
    TaskInd=find(cell2mat(TaskInfo(2:end,2))==j);
    baselinedata{j}=base2(:,TaskInd);
    trialdata{j}=trial2(:,TaskInd);
end