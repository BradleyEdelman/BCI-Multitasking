function targets=ExtractMultiTargets(matFile,trialOrder)

load(matFile)
%%
% d.map contains labels for features and their corresponding column numbers
% to index into d.data
% availableFeatures = d.map.keys;

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
events(:,1)=t';
events(:,2)=d.data(:,d.map('USER'));

for i=1:size(events,1)
    if i == 1
        events(i,3) = events(i,2);
    elseif events(i,2) == events(i-1,2)
        events(i,3) = 0;
    else
        events(i,3) = events(i,2);
    end
end

%     figure;
%     stem(events(:,1),events(:,3));
%     axis([t(1) t(end) 0 3]);

%green/red on/off plot
events(:,4)=zeros;
events(:,5)=zeros;

for i=1:size(events,1)
    if events(i,3)==1.91||events(i,3)==2.15||events(i,3)==2.25||events(i,3)==2.35||events(i,3)==2.45...
            ||events(i,3)==1.15||events(i,3)==1.25||events(i,3)==1.35||events(i,3)==1.45
        events(i,4)=events(i,3);
    elseif events(i,3)==1.90||events(i,3)==2.11||events(i,3)==2.21||events(i,3)==2.31||events(i,3)==2.41...
            ||events(i,3)==1.11||events(i,3)==1.21||events(i,3)==1.31||events(i,3)==1.41
        events(i,5)=events(i,3);
    else
    end
end

figure;
stem(events(:,1),[events(:,4) events(:,5)]);
axis([t(1) t(end) 0 3]);
%%

% Find smr trial information
totevent=events(:,4)+events(:,5);
smrstart=find(totevent==1.15 | totevent==1.25 | totevent==1.35 | totevent==1.45);
smrend=find(totevent==1.11 | totevent==1.21 | totevent==1.31 | totevent==1.41);
smrtarget=round((totevent(smrstart)-1.05)*10);

% Determine ssvep trial info as a function of smr trial
smrdur=(smrend-smrstart)/60-2.1; % ET samples at 60Hz
smrdur(smrdur>=1.5 & smrdur<=1.625)=1;
smrdur(smrdur>=3 & smrdur<=3.125)=2.5;
smrdur(smrdur>=4.5 & smrdur<=4.625)=4;
smrdur(smrdur>=6 & smrdur<=6.025)=5.5;
% Number of ssvep trials that should be in each smr trial
ssveptrials=floor(smrdur/1.50); sum(ssveptrials)

testTrialOrder=[];
ssveptarget=cell(1,size(smrstart,1));
for i=1:size(smrstart,1)
    
    ssvepidx=smrstart(i):smrend(i);
    ssveptrialstart=find(totevent(ssvepidx)==2.15 | totevent(ssvepidx)==2.25 |...
        totevent(ssvepidx)==2.35 | totevent(ssvepidx)==2.45);
    ssveptrialstart=ssvepidx(ssveptrialstart);
    % targets from current trial identified through ET triggers w/in smr trial time frame
    ssveptarget{i}=round((totevent(ssveptrialstart)-2.05)*10);
    
    % If less targets than time indicates, insert correct target
    if size(ssveptarget{i},1)<ssveptrials(i)
        for j=1:ssveptrials(i)
            if j<=size(ssveptarget{i},1)
                if ~isequal(trialOrder(size(testTrialOrder,1)+j),ssveptarget{i}(j))
                    ssveptarget{i}=[ssveptarget{i}(1:j-1);trialOrder(size(testTrialOrder,1)+j);ssveptarget{i}(j:end)];
                end
            else
                ssveptarget{i}=[ssveptarget{i};trialOrder(size(testTrialOrder,1)+j)];
            end
        end
    end
    testTrialOrder=vertcat(ssveptarget{:});

end

% Remove incomplete ssvep trials at end of smr trials
for i=1:size(smrstart,1)
    if size(ssveptarget{i},1)>=ssveptrials(i)
        ssveptarget{i}=ssveptarget{i}(1:ssveptrials(i));
    end
    
    targets(i).smr=smrtarget(i);
    if isempty(ssveptarget{i})
        targets(i).ssvep=[];
    else
        targets(i).ssvep=ssveptarget{i}';
    end
    
end



    
    
    

% 
% 
% 
% 
% 
% 
% 
% 
% %separating smr, ssvep, and feedback
% events(:,6)=zeros;
% events(:,7)=zeros;
% events(:,8)=zeros;
% for i=1:size(events,1)
%     if events(i,3)==1.11||events(i,3)==1.21||events(i,3)==1.31||events(i,3)==1.41...
%             ||events(i,3)==1.15||events(i,3)==1.25||events(i,3)==1.35||events(i,3)==1.45
%         events(i,6)=events(i,3);
%     elseif events(i,3)==2.11||events(i,3)==2.21||events(i,3)==2.31||events(i,3)==2.41...
%             ||events(i,3)==2.15||events(i,3)==2.25||events(i,3)==2.35||events(i,3)==2.45
%         events(i,7)=events(i,3);
%     elseif events(i,3)==1.90||events(i,3)==1.91
%         events(i,8)=events(i,3);
%     else
%     end
% end
% 
% data.allon=events(:,4);
% data.alloff=events(:,5);
% data.smr=events(:,6);
% data.ssvep=events(:,7);
% data.feedback=events(:,8);
% 
% %         figure;
% %         subplot(2,1,1);
% %         stem(events(:,1),events(:,6));
% %         axis([t(1) t(end) 1 2.5]);
% %         subplot(2,1,2);
% %         stem(events(:,1),events(:,7));
% %         axis([t(1) t(end) 1 2.5]);
% 
% % on/off matrices for correlation with ssvep targets
% ssveptargets(1:size(events,1),1:5)=zeros;
% for i=1:size(events,1)
%     if data.ssvep(i)==2.15||data.ssvep(i)==2.25||data.ssvep(i)==2.35||data.ssvep(i)==2.45
%         tmp=i;
%     elseif data.ssvep(i)==2.11
%         ssveptargets(tmp:i,1)=1;
%         ssveptargets(tmp:i,5)=1;
%     elseif data.ssvep(i)==2.21
%         ssveptargets(tmp:i,2)=1;
%         ssveptargets(tmp:i,5)=2;
%     elseif data.ssvep(i)==2.31
%         ssveptargets(tmp:i,3)=1;
%         ssveptargets(tmp:i,5)=3;
%     elseif data.ssvep(i)==2.41
%         ssveptargets(tmp:i,4)=1;
%         ssveptargets(tmp:i,5)=4;
%     else
%     end
% end
% 
% %         figure;
% %         suptitle('ssvep targets');
% %         subplot(4,1,1);
% %         area(ssveptargets(:,1))
% %         ylabel(1);
% %         subplot(4,1,2);
% %         area(ssveptargets(:,2))
% %         ylabel(2);
% %         subplot(4,1,3);
% %         area(ssveptargets(:,3))
% %         ylabel(3);
% %         subplot(4,1,4);
% %         area(ssveptargets(:,4))
% %         ylabel(4);
% 
% %same thing for smr
% smrtargets(1:size(events,1),1:5)=zeros;
% for i=1:size(events,1)
%     if data.smr(i)==1.15||data.smr(i)==1.25||data.smr(i)==1.35||data.smr(i)==1.45
%         tmp=i;
%     elseif data.smr(i)==1.11
%         smrtargets(tmp:i,1)=1;
%         smrtargets(tmp:i,5)=1;
%     elseif data.smr(i)==1.21
%         smrtargets(tmp:i,2)=1;
%         smrtargets(tmp:i,5)=2;
%     elseif data.smr(i)==1.31
%         smrtargets(tmp:i,3)=1;
%         smrtargets(tmp:i,5)=3;
%     elseif data.smr(i)==1.41
%         smrtargets(tmp:i,4)=1;
%         smrtargets(tmp:i,5)=4;
%     else
%     end
% end
% %     figure;
% %     suptitle('smr targets');
% %     subplot(4,1,1);
% %     area(smrtargets(:,1))
% %     ylabel(1);
% %     subplot(4,1,2);
% %     area(smrtargets(:,2))
% %     ylabel(2);
% %     subplot(4,1,3);
% %     area(smrtargets(:,3))
% %     ylabel(3);
% %     subplot(4,1,4);
% %     area(smrtargets(:,4))
% %     ylabel(4);
% 
% %     %ssvep/smr subplot with target number on y axis from column 5 of
% %     %smrtargets and ssveptargets
% %     figure;
% %     suptitle('smr and ssvep targets')
% %     subplot(2,1,1);
% %     area(smrtargets(:,5));
% %     ylabel('smr');
% %     subplot(2,1,2);
% %     area(ssveptargets(:,5));
% %     ylabel('ssvep');
