%% For analyzing eye tracker logs
%edited to go through all eyetracker data for one session

%save etd files as txt before running
clear

folderPath = 'M:\_bci_Multitasking\_Multi_Data\NG\NG20170721S04\ET_NG_20170721';
logNames=uigetfile(folderPath,'MultiSelect','on');

for j=1:size(logNames,2)
    logFile=[folderPath '\' logNames{j}(1:end-4) '.txt'];

        %% Handle input arguments

        if (strcmp(logFile(end-3:end),'.txt'))
            matFile = [logFile(1:end-4) '.mat'];
        else
            matFile = [logFile '.mat'];
            logFile = [logFile '.txt'];
        end

        %% Import data 
        if ~exist(matFile,'file') %% convert the raw log file to a .mat if it hasn't already been done
            tic
            d = EyeTracker.convertLogToMat(logFile,matFile); %% this is (unfortunately) slow
            toc
            matSave = [folderPath '\' fileName '.mat'];
            save(matSave,'d','-v7.3');
        else
            load(matFile); % this is much faster, so ideal to store most data in this format
        end

        %% 
        % d.map contains labels for features and their corresponding column numbers
        % to index into d.data
        availableFeatures = d.map.keys;

        % Features are accessed by referencing their label through the map
    % 	bpogx_columnIndex = d.map('BPOGX');
    % 	bpogx = d.data(:,bpogx_columnIndex);
        refTime = d.data(1,1:6);
        t(1,1:size(d.data,1))=zeros;
        for i=1:size(d.data,1)
            t(i) = etime(d.data(i,1:6), refTime);
        end

        if size(d.data,1)<size(t,2)
            d.data(size(d.data,1)+1:size(t,2),:)=zeros;
        end
        % make and plot events/impulses matrix
        events{j}(:,1)=t';
        events{j}(:,2)=d.data(:,d.map('USER'));

        for i=1:size(events{j},1)
            if i == 1
                events{j}(i,3) = events{j}(i,2);
            elseif events{j}(i,2) == events{j}(i-1,2)
                events{j}(i,3) = 0;
            else
                events{j}(i,3) = events{j}(i,2);
            end
        end

    %     figure;
    %     stem(events{j}(:,1),events{j}(:,3));
    %     axis([t(1) t(end) 0 3]);

        %green/red on/off plot
        events{j}(:,4)=zeros;
        events{j}(:,5)=zeros;

        for i=1:size(events{j},1)
            if events{j}(i,3)==1.91||events{j}(i,3)==2.15||events{j}(i,3)==2.25||events{j}(i,3)==2.35||events{j}(i,3)==2.45...
                    ||events{j}(i,3)==1.15||events{j}(i,3)==1.25||events{j}(i,3)==1.35||events{j}(i,3)==1.45
                events{j}(i,4)=events{j}(i,3);
            elseif events{j}(i,3)==1.90||events{j}(i,3)==2.11||events{j}(i,3)==2.21||events{j}(i,3)==2.31||events{j}(i,3)==2.41...
                    ||events{j}(i,3)==1.11||events{j}(i,3)==1.21||events{j}(i,3)==1.31||events{j}(i,3)==1.41
                events{j}(i,5)=events{j}(i,3);
            else
            end
        end

%         figure;
%         stem(events{j}(:,1),[events{j}(:,4) events{j}(:,5)]);
%         axis([t(1) t(end) 0 3]);

        %separating smr, ssvep, and feedback
        events{j}(:,6)=zeros;
        events{j}(:,7)=zeros;
        events{j}(:,8)=zeros;
        for i=1:size(events{j},1)
            if events{j}(i,3)==1.11||events{j}(i,3)==1.21||events{j}(i,3)==1.31||events{j}(i,3)==1.41...
                    ||events{j}(i,3)==1.15||events{j}(i,3)==1.25||events{j}(i,3)==1.35||events{j}(i,3)==1.45
                events{j}(i,6)=events{j}(i,3);
            elseif events{j}(i,3)==2.11||events{j}(i,3)==2.21||events{j}(i,3)==2.31||events{j}(i,3)==2.41...
                    ||events{j}(i,3)==2.15||events{j}(i,3)==2.25||events{j}(i,3)==2.35||events{j}(i,3)==2.45
                events{j}(i,7)=events{j}(i,3);
            elseif events{j}(i,3)==1.90||events{j}(i,3)==1.91
                events{j}(i,8)=events{j}(i,3);
            else
            end
        end

        data.allon=events{j}(:,4);
        data.alloff=events{j}(:,5);
        data.smr=events{j}(:,6);
        data.ssvep=events{j}(:,7);
        data.feedback=events{j}(:,8);

%         figure;
%         subplot(2,1,1);
%         stem(events{j}(:,1),events{j}(:,6));
%         axis([t(1) t(end) 1 2.5]);
%         subplot(2,1,2);
%         stem(events{j}(:,1),events{j}(:,7));
%         axis([t(1) t(end) 1 2.5]);

        % on/off matrices for correlation with ssvep targets
        ssveptargets{j}(1:size(events{j},1),1:5)=zeros;
        for i=1:size(events{j},1)
            if data.ssvep(i)==2.15||data.ssvep(i)==2.25||data.ssvep(i)==2.35||data.ssvep(i)==2.45
                tmp=i;
            elseif data.ssvep(i)==2.11
                ssveptargets{j}(tmp:i,1)=1;
                ssveptargets{j}(tmp:i,5)=1;
            elseif data.ssvep(i)==2.21
                ssveptargets{j}(tmp:i,2)=1;
                ssveptargets{j}(tmp:i,5)=2;
            elseif data.ssvep(i)==2.31
                ssveptargets{j}(tmp:i,3)=1;
                ssveptargets{j}(tmp:i,5)=3;
            elseif data.ssvep(i)==2.41
                ssveptargets{j}(tmp:i,4)=1;
                ssveptargets{j}(tmp:i,5)=4;
            else
            end
        end
        
        
        % % Find first ssvep target
        % firstssvep=find(ssveptargets(:,5)~=0);
        % lasttarget=ssveptargets(firstssvep(1),5);
        % % Fix missing ssvep targets!!!
        % smrtrialidx=1;
        % for i=1:size(events,1)-1
        %     if ~isequal(smrtargets(i,5),0) && isequal(smrtargets(i+1,5),0)
        %         smrtrialidx=smrtrialidx+1;
        %         lasttarget=0;
        %     elseif isequal(smrtargets(i,5),0) && ~isequal(smrtargets(i+1,5),0)
        %         firstssvep=find(ssveptargets(i:end,5)~=0);
        %         if ~isempty(firstssvep)
        %             lasttarget=ssveptargets(i+firstssvep(1),5);
        %         else
        %             lasttarget=0;
        %         end
        %     elseif ~isequal(smrtargets(i,5),0)
        %         if ~isequal(ssveptargets(i,5),0)
        %             lasttarget=ssveptargets(i,5);
        %         elseif isequal(ssveptargets(i,5),0) && ~isequal(lasttarget,0)
        %             ssveptargets(i,5)=lasttarget;
        %         end
        %     end
        % end
    
        
%         figure;
%         suptitle('ssvep targets');
%         subplot(4,1,1);
%         area(ssveptargets{j}(:,1))
%         ylabel(1);
%         subplot(4,1,2);
%         area(ssveptargets{j}(:,2))
%         ylabel(2);
%         subplot(4,1,3);
%         area(ssveptargets{j}(:,3))
%         ylabel(3);
%         subplot(4,1,4);
%         area(ssveptargets{j}(:,4))
%         ylabel(4);

        %same thing for smr
        smrtargets{j}(1:size(events{j},1),1:5)=zeros;
        for i=1:size(events{j},1)
            if data.smr(i)==1.15||data.smr(i)==1.25||data.smr(i)==1.35||data.smr(i)==1.45
                tmp=i;
            elseif data.smr(i)==1.11
                smrtargets{j}(tmp:i,1)=1;
                smrtargets{j}(tmp:i,5)=1;
            elseif data.smr(i)==1.21
                smrtargets{j}(tmp:i,2)=1;
                smrtargets{j}(tmp:i,5)=2;
            elseif data.smr(i)==1.31
                smrtargets{j}(tmp:i,3)=1;
                smrtargets{j}(tmp:i,5)=3;
            elseif data.smr(i)==1.41
                smrtargets{j}(tmp:i,4)=1;
                smrtargets{j}(tmp:i,5)=4;
            else
            end
        end
    %     figure;
    %     suptitle('smr targets');
    %     subplot(4,1,1);
    %     area(smrtargets{j}(:,1))
    %     ylabel(1);
    %     subplot(4,1,2);
    %     area(smrtargets{j}(:,2))
    %     ylabel(2);
    %     subplot(4,1,3);
    %     area(smrtargets{j}(:,3))
    %     ylabel(3);
    %     subplot(4,1,4);
    %     area(smrtargets{j}(:,4))
    %     ylabel(4);

    %     %ssvep/smr subplot with target number on y axis from column 5 of
    %     %smrtargets{j} and ssveptargets{j}
    %     figure;
    %     suptitle('smr and ssvep targets')
    %     subplot(2,1,1);
    %     area(smrtargets{j}(:,5));
    %     ylabel('smr');
    %     subplot(2,1,2);
    %     area(ssveptargets{j}(:,5));
    %     ylabel('ssvep');
    
    %% best point of gaze values
    bpogvals{j}(:,1)=t';
    bpogvals{j}(:,2)=d.data(:,d.map('BPOGV'));
    bpogvals{j}(:,3)=d.data(:,d.map('BPOGX'));
    bpogvals{j}(:,4)=d.data(:,d.map('BPOGY'));
    valid{j}=logical(bpogvals{j}(:,2));
    
end
    

%% bpog heat maps

for i=1:size(bpogvals,2)
    if i==1
        bpogvalsFull=bpogvals{i};
        ssveptargetsFull=ssveptargets{i};
        smrtargetsFull=smrtargets{i};
        validFull=valid{i};
        %add in stuff for smr targets and ssvep targetrs after putting {j}
        %by all of those earlier too!!!
    else
        bpogvalsFull=vertcat(bpogvalsFull,bpogvals{i});
        ssveptargetsFull=vertcat(ssveptargetsFull,ssveptargets{i});
        smrtargetsFull=vertcat(smrtargetsFull,smrtargets{i});
        validFull=vertcat(validFull,valid{i});
    end
end

figure;
suptitle('session');
scatter(bpogvalsFull(validFull,3),bpogvalsFull(validFull,4));

% Heat map for entire session - All targets
figure;
suptitle('session');
histdat=[bpogvalsFull(validFull,3),bpogvalsFull(validFull,4)];
% res=[200 200];
EyeTrackerHist(histdat,'session');

% Heat map for entire session - individual SSVEP targets
figure; subplot(2,2,1)
histdat= [bpogvalsFull(validFull & ssveptargetsFull(:,1),3),bpogvalsFull(validFull & ssveptargetsFull(:,1),4)];
[xb,yb,ssvephist1]=EyeTrackerHist(histdat,'ssvep target1 and valid'); title('1 - 7Hz');
subplot(2,2,2)
histdat= [bpogvalsFull(validFull & ssveptargetsFull(:,2),3),bpogvalsFull(validFull & ssveptargetsFull(:,2),4)];
[xb,yb,ssvephist2]=EyeTrackerHist(histdat,'ssvep target2 and valid'); title('2 - 8.5Hz');
subplot(2,2,3)
histdat= [bpogvalsFull(validFull & ssveptargetsFull(:,3),3),bpogvalsFull(validFull & ssveptargetsFull(:,3),4)];
[xb,yb,ssvephist3]=EyeTrackerHist(histdat,'ssvep target3 and valid'); title('3 - 10.5Hz');
subplot(2,2,4)
histdat= [bpogvalsFull(validFull & ssveptargetsFull(:,4),3),bpogvalsFull(validFull & ssveptargetsFull(:,4),4)];
[xb,yb,ssvephist4]=EyeTrackerHist(histdat,'ssvep target4 and valid'); title('4 - 12.5Hz');
suptitle('SSVEP Targets')

% Heat map for entire session - individual SMR targets
figure; subplot(2,2,1)
histdat= [bpogvalsFull(validFull & smrtargetsFull(:,1),3),bpogvalsFull(validFull & smrtargetsFull(:,1),4)];
[xb,yb,smrhist1]=EyeTrackerHist(histdat,'smr target1 and valid'); title('1 - left');
subplot(2,2,2)
histdat= [bpogvalsFull(validFull & smrtargetsFull(:,2),3),bpogvalsFull(validFull & smrtargetsFull(:,2),4)];
[xb,yb,smrhist2]=EyeTrackerHist(histdat,'smr target2 and valid'); title('2 - right');
subplot(2,2,3)
histdat= [bpogvalsFull(validFull & smrtargetsFull(:,3),3),bpogvalsFull(validFull & smrtargetsFull(:,3),4)];
[xb,yb,smrhist3]=EyeTrackerHist(histdat,'smr target3 and valid'); title('3 - down');
subplot(2,2,4)
histdat= [bpogvalsFull(validFull & smrtargetsFull(:,4),3),bpogvalsFull(validFull & smrtargetsFull(:,4),4)];
[xb,yb,smrhist4]=EyeTrackerHist(histdat,'smr target4 and valid'); title('4 - up');
suptitle('SMR Targets')

xq0=1;
xq1=find(xb==0.25);
xq3=find(xb==0.75);
xq4=size(xb,2);
yq0=1;
yq1=find(yb==0.25);
yq3=find(yb==0.75);
yq4=size(yb,2);

% Percent duration in 4 SSVEPs, 4 SMRs, Center (Y's D1, X's D2)

% SSVEP 1
T1tot=sum(sum(ssvephist1,1),2);
ssvepT1(1)=sum(sum(ssvephist1(yq0:yq1-1,xq0:xq1-1),1),2)/T1tot*100;
ssvepT1(2)=sum(sum(ssvephist1(yq3+1:yq4,xq0:xq1-1),1),2)/T1tot*100;
ssvepT1(3)=sum(sum(ssvephist1(yq0:yq1-1,xq3+1:xq4),1),2)/T1tot*100;
ssvepT1(4)=sum(sum(ssvephist1(yq3+1:yq4,xq3+1:xq4),1),2)/T1tot*100;
ssvepT1(5)=sum(sum(ssvephist1(yq1:yq3,xq0:xq1-1),1),2)/T1tot*100;
ssvepT1(6)=sum(sum(ssvephist1(yq1:yq3,yq3+1:yq4),1),2)/T1tot*100;
ssvepT1(7)=sum(sum(ssvephist1(yq0:yq1-1,xq1:xq3),1),2)/T1tot*100;
ssvepT1(8)=sum(sum(ssvephist1(yq3+1:yq4,xq1:xq3-1),1),2)/T1tot*100;
ssvepT1(9)=sum(sum(ssvephist1(yq1:xq3,xq1:xq3),1),2)/T1tot*100;

T2tot=sum(sum(ssvephist2,1),2);
ssvepT2(1)=sum(sum(ssvephist2(yq0:yq1-1,xq0:xq1-1),1),2)/T2tot*100;
ssvepT2(2)=sum(sum(ssvephist2(yq3+1:yq4,xq0:xq1-1),1),2)/T2tot*100;
ssvepT2(3)=sum(sum(ssvephist2(yq0:yq1-1,xq3+1:xq4),1),2)/T2tot*100;
ssvepT2(4)=sum(sum(ssvephist2(yq3+1:yq4,xq3+1:xq4),1),2)/T2tot*100;
ssvepT2(5)=sum(sum(ssvephist2(yq1:yq3,xq0:xq1-1),1),2)/T2tot*100;
ssvepT2(6)=sum(sum(ssvephist2(yq1:yq3,yq3+1:yq4),1),2)/T2tot*100;
ssvepT2(7)=sum(sum(ssvephist2(yq0:yq1-1,xq1:xq3),1),2)/T2tot*100;
ssvepT2(8)=sum(sum(ssvephist2(yq3+1:yq4,xq1:xq3-1),1),2)/T2tot*100;
ssvepT2(9)=sum(sum(ssvephist2(yq1:xq3,xq1:xq3),1),2)/T2tot*100;

T3tot=sum(sum(ssvephist3,1),2);
ssvepT3(1)=sum(sum(ssvephist3(yq0:yq1-1,xq0:xq1-1),1),2)/T3tot*100;
ssvepT3(2)=sum(sum(ssvephist3(yq3+1:yq4,xq0:xq1-1),1),2)/T3tot*100;
ssvepT3(3)=sum(sum(ssvephist3(yq0:yq1-1,xq3+1:xq4),1),2)/T3tot*100;
ssvepT3(4)=sum(sum(ssvephist3(yq3+1:yq4,xq3+1:xq4),1),2)/T3tot*100;
ssvepT3(5)=sum(sum(ssvephist3(yq1:yq3,xq0:xq1-1),1),2)/T3tot*100;
ssvepT3(6)=sum(sum(ssvephist3(yq1:yq3,yq3+1:yq4),1),2)/T3tot*100;
ssvepT3(7)=sum(sum(ssvephist3(yq0:yq1-1,xq1:xq3),1),2)/T3tot*100;
ssvepT3(8)=sum(sum(ssvephist3(yq3+1:yq4,xq1:xq3-1),1),2)/T3tot*100;
ssvepT3(9)=sum(sum(ssvephist3(yq1:xq3,xq1:xq3),1),2)/T3tot*100;

T4tot=sum(sum(ssvephist4,1),2);
ssvepT4(1)=sum(sum(ssvephist4(yq0:yq1-1,xq0:xq1-1),1),2)/T4tot*100;
ssvepT4(2)=sum(sum(ssvephist4(yq3+1:yq4,xq0:xq1-1),1),2)/T4tot*100;
ssvepT4(3)=sum(sum(ssvephist4(yq0:yq1-1,xq3+1:xq4),1),2)/T4tot*100;
ssvepT4(4)=sum(sum(ssvephist4(yq3+1:yq4,xq3+1:xq4),1),2)/T4tot*100;
ssvepT4(5)=sum(sum(ssvephist4(yq1:yq3,xq0:xq1-1),1),2)/T4tot*100;
ssvepT4(6)=sum(sum(ssvephist4(yq1:yq3,yq3+1:yq4),1),2)/T4tot*100;
ssvepT4(7)=sum(sum(ssvephist4(yq0:yq1-1,xq1:xq3),1),2)/T4tot*100;
ssvepT4(8)=sum(sum(ssvephist4(yq3+1:yq4,xq1:xq3-1),1),2)/T4tot*100;
ssvepT4(9)=sum(sum(ssvephist4(yq1:xq3,xq1:xq3),1),2)/T4tot*100;

DwellT1=zeros(size(ssvephist1));
DwellT1(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT1(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
DwellT1(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT1(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
DwellT1(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT1(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
DwellT1(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT1(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
DwellT1(yq1:yq3,xq0:xq1-1)=repmat(ssvepT1(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
DwellT1(yq1:yq3,yq3+1:yq4)=repmat(ssvepT1(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
DwellT1(yq0:yq1-1,xq1:xq3)=repmat(ssvepT1(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
DwellT1(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT1(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
DwellT1(yq1:xq3,xq1:xq3)=repmat(ssvepT1(9),size(yq1:xq3,2),size(xq1:xq3,2));
figure; subplot(2,2,1); imagesc(xb,yb,DwellT1); caxis([0 100])

DwellT2=zeros(size(ssvephist2));
DwellT2(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT2(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
DwellT2(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT2(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
DwellT2(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT2(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
DwellT2(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT2(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
DwellT2(yq1:yq3,xq0:xq1-1)=repmat(ssvepT2(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
DwellT2(yq1:yq3,yq3+1:yq4)=repmat(ssvepT2(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
DwellT2(yq0:yq1-1,xq1:xq3)=repmat(ssvepT2(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
DwellT2(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT2(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
DwellT2(yq1:xq3,xq1:xq3)=repmat(ssvepT2(9),size(yq1:xq3,2),size(xq1:xq3,2));
subplot(2,2,2); imagesc(xb,yb,DwellT2); caxis([0 100])

DwellT3=zeros(size(ssvephist1));
DwellT3(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT3(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
DwellT3(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT3(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
DwellT3(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT3(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
DwellT3(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT3(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
DwellT3(yq1:yq3,xq0:xq1-1)=repmat(ssvepT3(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
DwellT3(yq1:yq3,yq3+1:yq4)=repmat(ssvepT3(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
DwellT3(yq0:yq1-1,xq1:xq3)=repmat(ssvepT3(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
DwellT3(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT3(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
DwellT3(yq1:xq3,xq1:xq3)=repmat(ssvepT3(9),size(yq1:xq3,2),size(xq1:xq3,2));
subplot(2,2,3); imagesc(xb,yb,DwellT3); caxis([0 100])

DwellT4=zeros(size(ssvephist1));
DwellT4(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT4(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
DwellT4(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT4(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
DwellT4(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT4(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
DwellT4(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT4(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
DwellT4(yq1:yq3,xq0:xq1-1)=repmat(ssvepT4(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
DwellT4(yq1:yq3,yq3+1:yq4)=repmat(ssvepT4(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
DwellT4(yq0:yq1-1,xq1:xq3)=repmat(ssvepT4(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
DwellT4(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT4(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
DwellT4(yq1:xq3,xq1:xq3)=repmat(ssvepT4(9),size(yq1:xq3,2),size(xq1:xq3,2));
subplot(2,2,4); imagesc(xb,yb,DwellT4); caxis([0 100])









