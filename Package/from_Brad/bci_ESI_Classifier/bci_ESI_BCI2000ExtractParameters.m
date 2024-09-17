function [trialstruct]=bci_ESI_BCI2000ExtractParameters(trainfiles)

% LOAD THE SELECTED PARAM FILE
numfiles=size(trainfiles,1);
trialstruct=struct;

for i=1:numfiles
    
    [fid]=fopen(trainfiles{i},'r');
    lines={};
    for j=1:200
        lines=[lines;{fgetl(fid)}];
    end

    clear PreRun PreFeed PostFeed ITI MaxFeed StimDur ISIMin ISIMax 
    clear ISI StimName NewStim TrainTaskType
    % EXTRACT THE TRIAL STRUCUTRE
    for j=1:size(lines,1)

        if ~isempty(strfind(lines{j},'PreRunDuration'))
            PreRun=str2double(regexp(lines{j},'.\d+','match'));
            PreRun=PreRun(1);
        elseif ~isempty(strfind(lines{j},'PreFeedbackDuration'))
            PreFeed=str2double(regexp(lines{j},'.\d+','match'));
            PreFeed=PreFeed(1);
        elseif ~isempty(strfind(lines{j},'PostFeedbackDuration'))
            PostFeed=str2double(regexp(lines{j},'.\d+','match'));
            PostFeed=PostFeed(1);
        elseif ~isempty(strfind(lines{j},'ITIDuration'))
            ITI=str2double(regexp(lines{j},'.\d+','match'));
            ITI=ITI(1);
        elseif ~isempty(strfind(lines{j},'MaxFeedbackDuration'))
            MaxFeed=str2double(regexp(lines{j},'.\d+','match'));
            MaxFeed=MaxFeed(1);
        elseif ~isempty(strfind(lines{j},'StimulusDuration'))
            StimDur=str2double(regexp(lines{j},'.\d+','match'));
            StimDur=StimDur(1);
        elseif ~isempty(strfind(lines{j},'ISIMinDuration'))   
            ISIMin=str2double(regexp(lines{j},'.\d+','match'));
            ISIMin=ISIMin(1);
        elseif ~isempty(strfind(lines{j},'ISIMaxDuration'))   
            ISIMax=str2double(regexp(lines{j},'.\d+','match'));
            ISIMax=ISIMax(1);
        elseif ~isempty(strfind(lines{j},' Targets='))
            Targets=str2double(regexp(lines{j},'.\d+','match'));
            NumTarget=Targets(1);
            TargetField=sum(isnan(Targets));
            Txpos=Targets(2+TargetField:TargetField:end);
            Typos=Targets(3+TargetField:TargetField:end);
            
            Right=find(Txpos==max(Txpos));
            Left=find(Txpos==min(Txpos));
            if isequal(size(Right,2),2) || isequal(size(Left,2),2)
                Right=0; Left=0;
            end
            
            Up=find(Typos==max(Typos));
            Down=find(Typos==min(Typos));
            if isequal(size(Up,2),2) || isequal(size(Down,2),2)
                Up=0; Down=0;
            end
            
        elseif ~isempty(strfind(lines{j},'SourceCh='))
            NumChan=str2double(regexp(lines{j},'.\d+','match'));
            NumChan=NumChan(2);
        elseif ~isempty(strfind(lines{j},'SourceChOffset'))
            ChanOffset=str2double(regexp(lines{j},'.\d+','match'));
            ChanOffset=ChanOffset(end-NumChan:end-1);
        elseif ~isempty(strfind(lines{j},'SourceChGain'))
            ChanGain=str2double(regexp(lines{j},'0.\d+','match'));
            ChanGain=ChanGain(end-NumChan:end-1);
        elseif ~isempty(strfind(lines{j},'SamplingRate'))
            fs=str2double(regexp(lines{j},'.\d+','match'));
            fs=fs(2);
        elseif ~isempty(strfind(lines{j},'matrix Stimuli'))
            
            NewStim=[];
            if ~isempty(strfind(lines{j},'Imagine'))
                NewStim=[NewStim strfind(lines{j},'Imagine')];
            end
            
            if ~isempty(strfind(lines{j},'Rest'))
                NewStim=[NewStim strfind(lines{j},'Rest')];
            end
            
            if ~isempty(strfind(lines{j},'Move'))
                NewStim=[NewStim strfind(lines{j},'Move')];
            end
            
            if ~isempty(strfind(lines{j},'Twist'))
                NewStim=[NewStim strfind(lines{j},'Twist')];
            end
            
            if ~isempty(strfind(lines{j},'Bend'))
                NewStim=[NewStim strfind(lines{j},'Bend')];
            end
            
            if exist('NewStim','var')
                Spaces=regexp(lines{j},' ');
                Spaces=Spaces(Spaces>NewStim(1));
                for k=1:size(NewStim,2)
                    StimName{1,k}=lines{j}(NewStim(k):Spaces(k)-1);
                end
            end
            
%             if ~isempty(strfind(lines{j},'Imagine'))
%                 NewStim=strfind(lines{j},'Imagine');
%                 j
%             elseif ~isempty(strfind(lines{j},'Rest'))
%                 NewStim=strfind(lines{j},'Rest');
%                 j
%             elseif ~isempty(strfind(lines{j},'Move'))
%                 NewStim=strfind(lines{j},'Move');
%             elseif ~isempty(strfind(lines{j},'Right'))
%                 NewStim=strfind(lines{j},'Right');
%             elseif ~isempty(strfind(lines{j},'Twist'))
%                 NewStim=strfind(lines{j},'Twist');
%             elseif ~isempty(strfind(lines{j},'Bend'))
%                 NewStim=strfind(lines{j},'Bend');
%             end
%             
%             if exist('NewStim','var')
%                 Spaces=regexp(lines{j},' ');
%                 Spaces=Spaces(Spaces>NewStim(1));
%                 for k=1:size(NewStim,2)
%                     StimName{1,k}=lines{j}(NewStim(k):Spaces(k)-1);
%                 end
%             end

        elseif ~exist('TrainTaskType','var') && ~isempty(strfind(lines{j},'Stimulus'))
            TrainTaskType='Stimulus';
        elseif ~exist('TrainTaskType','var') && ~isempty(strfind(lines{j},'Cursor'))
            TrainTaskType='Cursor';
        end
    end
    
    if exist('ISIMin','var') && exist('ISIMax','var') && isequal(ISIMin,ISIMax)
        ISI=mean(ISIMin,ISIMax);
    elseif exist('ISIMin','var') && exist('ISIMax','var') && ~isequal(ISIMin,ISIMax)
        error('LENGTH OF ISIMIN AND ISIMAX INCONSISTENT\n')
    end

    if exist('PreRun','var')
        if PreRun>100; PreRun=PreRun/1000; end
        trialstruct(i).prerun=PreRun;
    end

    if exist('PreFeed','var')
        if PreFeed>100; PreFeed=PreFeed/1000; end
        trialstruct(i).prefeed=PreFeed;
    end
    
    if exist('PostFeed','var')
        if PostFeed>100; PostFeed=PostFeed/1000; end
        trialstruct(i).postfeed=PostFeed;
    end
    if exist('ITI','var')
        if ITI>100; ITI=ITI/1000; end
        trialstruct(i).iti=ITI; 
    end
    
    if exist('MaxFeed','var')
        if MaxFeed>100; MaxFeed=MaxFeed/1000; end
        trialstruct(i).maxfeed=MaxFeed;
    end
    
    if exist('StimDur','var')
        if StimDur>100; StimDur=StimDur/1000; end
        trialstruct(i).stimdur=StimDur;
    end
    
    if exist('ISI','var')
        if ISI>100; ISI=ISI/1000; end
        trialstruct(i).isi=ISI;
    end
    
    if exist('Right','var') && exist('Left','var') &&...
            exist('Up','var') && exist('Down','var')
        target.right=Right;
        target.left=Left;
        target.up=Up;
        target.down=Down;
        trialstruct(i).target=target;
    end
    
    if ~exist('NumChan','var') || ~exist('ChanOffset','var') || ~exist('ChanGain','var')
        error('EEG CHANNEL GAIN/OFFSET VALUES DO NOT EXIST\n');
    elseif ~isequal(NumChan,size(ChanOffset,2))
        error('CHANNEL OFFSET VECTOR SIZE INCONSISTENT WITH # OF EEG CHANNELS\n');
    elseif ~isequal(NumChan,size(ChanGain,2))
        error('CHANNEL GAIN VECTOR SIZE INCONSISTENT WITH # OF EEG CHANNELS\N');
    else
        trialstruct(i).numchan=NumChan;
        trialstruct(i).chanoffset=ChanOffset;
        trialstruct(i).changain=ChanGain;
    end
    
    if exist('fs','var')
        trialstruct(i).fs=fs;
    end
    
    if exist('StimName','var'); trialstruct(i).stimname=StimName; end
    
    if exist('TrainTaskType','var'); trialstruct(i).tasktype=TrainTaskType; end

end



% CHECK CONSISTENCY OF PARAMETERS ACROSS TRAINING FILES
if isfield(trialstruct,'tasktype')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).tasktype)
            tmp{i}=trialstruct(i).tasktype;
        else
            tmp{i}='';
        end
    end
    
    combinations=combnk(1:size(trialstruct,2),2);
    Compare=zeros(size(combinations,1),1);
    for i=1:size(combinations,1)
        if strcmp(tmp(combinations(i,1)),tmp(combinations(i,2)))
            Compare(i)=1;
        else
            Compare(i)=0;
        end
    end
    if ~isequal(sum(Compare),size(combinations,1))
        error('INCONSISTENT TASK TYPE AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'prerun')
    for i=1:size(trainfiles,1)
        tmp(i)=trialstruct(i).prerun;
    end
    if range(tmp)>0
        error('PRERUN DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'prefeed')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).prefeed)
            tmp(i)=trialstruct(i).prefeed;
        else
            tmp(i)=0;
        end
    end
    if range(tmp)>0
        error('PRE FEEDBACK DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end
    
clear tmp
if isfield(trialstruct,'postfeed')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).postfeed)
            tmp(i)=trialstruct(i).postfeed;
        else
            tmp(i)=0;
        end
    end
    if range(tmp)>0
        error('POST FEEDBACK DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'iti')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).iti)
            tmp(i)=trialstruct(i).iti;
        else
            tmp(i)=0;
        end
    end
    if range(tmp)>0
        error('ITI DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'maxfeed')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).maxfeed)
            tmp(i)=trialstruct(i).maxfeed;
        else
            tmp(i)=0;
        end
    end
    if range(tmp)>0
        error('MAX FEEDBACK DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'stimdur')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).stimdur)
            tmp(i)=trialstruct(i).stimdur;
        else
            tmp(i)=0;
        end
    end
    if range(tmp)>0
        error('STIMULUS DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'isi')
    for i=1:size(trainfiles,1)
        if ~isempty(trialstruct(i).isi)
            tmp(i)=trialstruct(i).isi;
        else
            tmp(i)=0;
        end
    end
    if range(tmp)>0
        error('ISI DURATION INCONSISTENT AMONG TRAINING FILES');
    end
end

clear tmp
if isfield(trialstruct,'stimname')
    for i=1:size(trainfiles,1)
        if ~isequal(trialstruct(i).stimname,[])
            tmp(i,:)=trialstruct(i).stimname;
        end
    end
    
    for i=1:size(tmp,2)
        if isequal(tmp{1,i},[])
            error('INCONSISTENT TASKS AMONG TRAINING FILES');
        else
            trialstruct(1).stimname=tmp';
            
%             for j=2:size(tmp,1)
%                 if ~ismember(tmp(1,i),tmp(j,:))
%                     error('INCONSISTENT TASKS AMONG TRAINING FILES');
%                 end
%             end
        end
    end
end

trialstruct=trialstruct(1);
        
        
        
        
        
        
        
        
        


