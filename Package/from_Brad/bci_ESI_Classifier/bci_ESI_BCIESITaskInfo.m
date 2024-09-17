function [handles,taskinfo,Data]=bci_ESI_BCIESITaskInfo(handles,TrainFiles,TrialStruct)
%%

% EXTRACT TRIAL STRUCTURE INFO
length=TrialStruct.length;
chanidxinclude=TrialStruct.chanidxinclude;
vertidxinclude=TrialStruct.vertidxinclude;
clusteridxinclude=TrialStruct.clusteridxinclude;
numfreq=TrialStruct.numfreq;
freqvect=TrialStruct.freqvect;
winpnts=TrialStruct.winpnts;


% totvert=size(handles.ESI.cortex.Vertices,1);
totvert=size(handles.ESI.vertidxinclude,1)+size(handles.ESI.vertidxexclude,1);
totchan=size(handles.SYSTEM.Electrodes.chanidxinclude,1);
if winpnts>1
    vertidxextract=[];
    chanidxextract=[];
    for i=1:winpnts
        vertidxextract=[vertidxextract totvert*(i-1)+vertidxinclude];
        chanidxextract=[chanidxextract totchan*(i-1)+chanidxinclude'];
    end
else
    vertidxextract=vertidxinclude;
    chanidxextract=chanidxinclude;
end
        

% INITIATE TASK INFO STRUCTURE
taskinfo=cell(0);
taskinfo{1,1}='Trial';
taskinfo{1,2}='Targ';
taskinfo{1,3}='Base Start';
taskinfo{1,4}='Base End';
taskinfo{1,5}='Stim Start';
taskinfo{1,6}='Stim End';
taskinfo{1,7}='Duration (win)';

% INITIATE OT
Data.Sensor=zeros(size(chanidxinclude,1)*winpnts,length,numfreq+1);
Data.Source=zeros(size(vertidxinclude,2)*winpnts,length,numfreq+1);
Data.SourceCluster=zeros(size(clusteridxinclude,2)*winpnts,length,numfreq+1);

tottrial=0; totwindows=0; numfiles=size(TrainFiles,1);
stimstatus=cell(1,numfiles);
basestatus=cell(1,numfiles);


for j=1:numfiles
    
    load(TrainFiles{j})
    Dat=Dat;
    targets=Dat(end).performance.targets;
    targets=str2double(targets(2:end,2));
    
    stimstatus{j}=cell2mat({Dat.stimstatus});
    basestatus{j}=cell2mat({Dat.basestatus});
    
    stimtype=find(sum(stimstatus{j},2)~=0);
    numstim=size(stimtype,1);
    
    stimstart=[]; stimend=[];
    for k=1:numstim
        stimstart=[stimstart find(diff(stimstatus{j}(k,:))==1)+1];
        stimend=[stimend find(diff(stimstatus{j}(k,:))==-1)];
    end

    runtype=Dat(end).runtype;
    
    basediff=diff(basestatus{j});
    if strcmp(runtype,'Cursor')
        
        startcount=0;
        for i=1:size(basediff,2)
            if basediff(i)==1
                startcount=startcount+1;
            end

            if basediff(i)==-1 && startcount==0
                basediff(i)=0;
            end
        end
    
        basestart=find(basediff==1);
        baseend=find(basediff==-1);
        
    elseif strcmp(runtype,'Stimulus')
            
        %     BaseStart=StimEnd+1;
        basestart=find(basediff==1)+1;
        basestart=[basestart 1];
        %     BaseEnd=StimStart-1;
        baseend=find(basediff==-1);
        baseend=[baseend size(Dat,2)];
    
    end

    stimstart=sort(stimstart,'ascend');
    stimend=sort(stimend,'ascend');
    basestart=sort(basestart,'ascend');
    baseend=sort(baseend,'ascend');
        
    for i=1:size(targets,1)
        taskinfo{i+tottrial+1,1}=i+tottrial;
        taskinfo{i+tottrial+1,2}=targets(i);
        taskinfo{i+tottrial+1,3}=totwindows+basestart(i);
        taskinfo{i+tottrial+1,4}=totwindows+baseend(i);
        taskinfo{i+tottrial+1,5}=totwindows+stimstart(i);
        taskinfo{i+tottrial+1,6}=totwindows+stimend(i);
        taskinfo{i+tottrial+1,7}=stimend(i)-stimstart(i)+1;
    end
    
    % Extract out online processed data
    for i=1:size(Dat,2)
        PSDSensor=Dat(i).psd.Sensor;
        PSDSource=Dat(i).psd.Source;
        PSDSourcecluster=Dat(i).psd.SourceCluster;
        
        for k=1:numfreq+1
            
            Data.Sensor(:,i+totwindows,k)=PSDSensor(chanidxextract,k);
            
            if ~isequal(PSDSource,[])
                Data.Source(:,i+totwindows,k)=PSDSource(vertidxextract,k);
            end
            
            if ~isequal(PSDSourcecluster,[])
                Data.SourceCluster(:,i+totwindows,k)=PSDSourcecluster(clusteridxinclude,k);
            end
            
        end
    end
    
    tottrial=tottrial+size(targets,1);
    totwindows=totwindows+size(Dat,2);
end


for i=tottrial:-1:1
    if taskinfo{i+1,7}==1 || (taskinfo{i+1,4}-taskinfo{i+1,3})>50
        
        taskinfo(i+1,:)=[];

        for k=size(taskinfo,1):-1:i
            taskinfo{k,1}=taskinfo{k,1}-1;
        end
        
    end
end

% Reconstruct task timings after trials have been removed
stimstatus2=zeros(numstim,totwindows);
basestatus2=zeros(1,totwindows);
for i=2:size(taskinfo,1)
    stimtype=taskinfo{i,2};
    basestatus2(taskinfo{i,3}:taskinfo{i,4})=1;
    stimstatus2(stimtype,taskinfo{i,5}:taskinfo{i,6})=1;
end

plot=[basestatus2;stimstatus2];
figure; imagesc(plot')
title('Task Timings')
ylabel('Time (windows')
colormap(gray)
set(gca,'Xtick',1:1:size(plot,1),...
    'xticklabel',{'Base' 'Task 1' 'Task 2' 'Task 3' 'Task 4'})

disp(taskinfo)
    
