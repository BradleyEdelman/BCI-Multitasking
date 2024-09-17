function [handles,taskinfo,Data]=bci_ESI_BCIESITaskInfo2(handles,trainfiles)
%%

decodescheme=get(handles.decodescheme,'value');
% INITIATE TASK INFO STRUCTURE
taskinfo=cell(0);
taskinfo{1,1}='Trial #';
taskinfo{1,2}='Targ';

switch decodescheme
    case 1 % None
    case 2 % Single Trial
        taskinfo{1,3}='Base ST (ms)';
        taskinfo{1,4}='Base ET (ms)';
        taskinfo{1,5}='Trial ST (ms)';
        taskinfo{1,6}='Trial ET (ms)';
        taskinfo{1,7}='Dur (ms)';
        tottime=0;
    case 3 % Time Resolved
        taskinfo{1,3}='Base ST (win)';
        taskinfo{1,4}='Base ET (win)';
        taskinfo{1,5}='Trial ST (win)';
        taskinfo{1,6}='Trial ET (win)';
        taskinfo{1,7}='Dur (win)';
        totwindows=0;
end
tottrial=0;
numfiles=size(trainfiles,1);

Data=struct('Sensor',[],'Source',[],'SourceCluster',[]);
storage=struct('runbase',[],'base',[],'trial',[],'targetidx',[]);
Data.Sensor=struct('freq',storage,'time',storage);
Data.Source=struct('freq',storage,'time',storage);
Data.SourceCluster=struct('freq',storage,'time',storage);

for j=1:numfiles
    
    load(trainfiles{j})
    
    switch decodescheme
        
        case 1 % None
            
        case 2 % Single Trial
            
            targetidx=cell2mat(dat.psd.Sensor.singletrial.targetidx);
            basestart=cell2mat(dat.psd.Sensor.singletrial.start.baseline);
            baseend=cell2mat(dat.psd.Sensor.singletrial.end.baseline);
            trialstart=cell2mat(dat.psd.Sensor.singletrial.start.trial);
            trialend=cell2mat(dat.psd.Sensor.singletrial.end.trial);
            
            for i=1:size(targetidx,2)
                taskinfo{i+tottrial+1,1}=i+tottrial;
                taskinfo{i+tottrial+1,2}=targetidx(i);
                taskinfo{i+tottrial+1,3}=tottime+basestart(i);
                taskinfo{i+tottrial+1,4}=tottime+baseend(i);
                taskinfo{i+tottrial+1,5}=tottime+trialstart(i);
                taskinfo{i+tottrial+1,6}=tottime+trialend(i);
                taskinfo{i+tottrial+1,7}=(trialend(i)-trialstart(i)+1)/dat.param.fsextract*1000;
            end
            
            Data.Sensor.base=[Data.Sensor.base dat.psd.Sensor.singletrial.baseline];
            Data.Sensor.trial=[Data.Sensor.trial dat.psd.Sensor.singletrial.trial];
            Data.Sensor.targetidx=[Data.Sensor.targetidx targetidx];
            
            Data.Source.base=[Data.Source.base dat.psd.Source.singletrial.baseline];
            Data.Source.trial=[Data.Source.trial dat.psd.Source.singletrial.trial];
            Data.Source.targetidx=[Data.Source.targetidx targetidx];
            
            Data.SourceCluster.base=[Data.SourceCluster.base dat.psd.SourceCluster.singletrial.baseline];
            Data.SourceCluster.trial=[Data.SourceCluster.trial dat.psd.SourceCluster.singletrial.trial];
            Data.SourceCluster.targetidx=[Data.SourceCluster.targetidx targetidx];
            
            tottrial=tottrial+size(targetidx,2);
            tottime=tottime+trialend(end);

        case 3 % Time Resolved
            
            targetval=cell2mat(dat.psd.Sensor.timeresolve.targetidx);
            feedback=cell2mat(dat.psd.Sensor.timeresolve.feedback);
            baseline=cell2mat(dat.psd.Sensor.timeresolve.baseline);
            
            basestart=[]; baseend=[];
            trialstart=[]; trialend=[];
            targetidx=[]; targetcount=1;
%             for i=1:size(targetval,2)-1
%                 if isequal(targetval(i),0) && ~isequal(targetval(i+1),0)
%                     basestart=[basestart i+1];
%                     targetidx(targetcount)=targetval(i+1);
%                     targetcount=targetcount+1;
%                 elseif isequal(feedback(i),0) && isequal(feedback(i+1),1)
%                     baseend=[baseend i];
%                     trialstart=[trialstart i+1];
%                 elseif isequal(feedback(i),1) && isequal(feedback(i+1),0)
%                     trialend=[trialend i];
%                 end
%             end
            
            targettmp=diff(targetval);
            targetidx=targettmp(find(targettmp>0));

            baselinetmp=diff(baseline);
            baseend=find(baselinetmp==-1);
            basestart=find(baselinetmp==1)+1;
            if isequal(baseline(end),1)
                basestart(end)=[];
            end
            
            feedbacktmp=diff(feedback);
            trialend=find(feedbacktmp==-1);
            trialstart=find(feedbacktmp==1)+1;
            
            trialcomplete=min([size(basestart,2) size(baseend,2) size(trialstart,2) size(trialend,2)]);
            basestart=basestart(end-trialcomplete+1:end);
            baseend=baseend(end-trialcomplete+1:end);
            trialstart=trialstart(end-trialcomplete+1:end);
            trialend=trialend(end-trialcomplete+1:end);
%             tartetidx=targetidx(end-trialcomplete+1:end);
            
            for i=1:trialcomplete
                taskinfo{i+tottrial+1,1}=i+tottrial;
                taskinfo{i+tottrial+1,2}=targetidx(i);
                taskinfo{i+tottrial+1,3}=totwindows+basestart(i);
                taskinfo{i+tottrial+1,4}=totwindows+baseend(i);
                taskinfo{i+tottrial+1,5}=totwindows+trialstart(i);
                taskinfo{i+tottrial+1,6}=totwindows+trialend(i);
                taskinfo{i+tottrial+1,7}=(trialend(i)-trialstart(i)+1);
                
                if ~isempty(dat.psd.Sensor.timeresolve.window)
                    Data.Sensor.freq.base{i+tottrial}=dat.psd.Sensor.timeresolve.window(basestart(i):baseend(i));
                    Data.Sensor.freq.trial{i+tottrial}=dat.psd.Sensor.timeresolve.window(trialstart(i):trialend(i));
                    Data.Sensor.freq.targetidx=[Data.Sensor.freq.targetidx targetidx(i)];
                    % Store EEG only in sensor domain (time domain cortical currents later for source)
                    Data.Sensor.time.base{i+tottrial}=dat.eeg.timeresolve.window(basestart(i):baseend(i));
                    Data.Sensor.time.trial{i+tottrial}=dat.eeg.timeresolve.window(trialstart(i):trialend(i));
                    Data.Sensor.time.targetidx=[Data.Sensor.time.targetidx targetidx(i)];
                end
                
                if ~isempty(dat.psd.Source.timeresolve.window)
                    Data.Source.freq.base{i+tottrial}=dat.psd.Source.timeresolve.window(basestart(i):baseend(i));
                    Data.Source.freq.trial{i+tottrial}=dat.psd.Source.timeresolve.window(trialstart(i):trialend(i));
                    Data.Source.freq.targetidx=[Data.Source.freq.targetidx targetidx(i)];
                end
                
                if ~isempty(dat.psd.SourceCluster.timeresolve.window)
                    Data.SourceCluster.freq.base{i+tottrial}=dat.psd.SourceCluster.timeresolve.window(basestart(i):baseend(i));
                    Data.SourceCluster.freq.trial{i+tottrial}=dat.psd.SourceCluster.timeresolve.window(trialstart(i):trialend(i));
                    Data.SourceCluster.freq.targetidx=[Data.SourceCluster.freq.targetidx targetidx(i)];
                end
                
            end
            
            if ~isempty(dat.psd.Sensor.runbaseline.runbaseline)
                Data.Sensor.freq.runbase=[Data.Sensor.freq.runbase dat.psd.Sensor.runbaseline.runbaseline];
                Data.Sensor.time.runbase=[Data.Sensor.time.runbase dat.eeg.runbaseline.runbaseline];
            end
            
            if ~isempty(dat.psd.Source.runbaseline.runbaseline)
                Data.Source.runbase=[Data.Source.freq.runbase dat.psd.Source.runbaseline.runbaseline];
            end
            
            if ~isempty(dat.psd.SourceCluster.runbaseline.runbaseline)
                Data.SourceCluster.runbase=[Data.SourceCluster.freq.runbase dat.psd.SourceCluster.runbaseline.runbaseline];
            end
            
            tottrial=tottrial+size(targetidx,2);
            tmpend=max([trialend(end),baseend(end)]);
            totwindows=totwindows+tmpend;
            
    end

end



switch decodescheme
    
    case 1 % None
    case 2 % Single Trial
        
        % Reconstruct task timings after trials have been removed
        numtask=sum(unique(targetidx)~=0);
        stimstatus=zeros(numtask,tottime);
        basestatus=zeros(1,tottime);
        for i=2:size(taskinfo,1)
            stimtype=taskinfo{i,2};
            basestatus(taskinfo{i,3}:taskinfo{i,4})=1;
            stimstatus(stimtype,taskinfo{i,5}:taskinfo{i,6})=1;
        end
        
    case 3 % Time Resolved
        
        numtask=sum(unique(targetidx)~=0);
        stimstatus=zeros(numtask,totwindows);
        basestatus=zeros(1,totwindows);
        for i=2:size(taskinfo,1)
            stimtype=taskinfo{i,2};
            basestatus(taskinfo{i,3}:taskinfo{i,4})=1;
            stimstatus(stimtype,taskinfo{i,5}:taskinfo{i,6})=1;
        end
        
end

Plot=[basestatus;stimstatus];
axes(handles.axes3); cla; imagesc(Plot')
title('Task Timings')
ylabel('Time (windows)')
colormap(gray)
set(gca,'Xtick',1:1:size(Plot,1),...
    'xticklabel',{'Base' 'Task 1' 'Task 2' 'Task 3' 'Task 4'})

disp(taskinfo)
    
