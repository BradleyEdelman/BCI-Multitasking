function Dwell=ET_DwellTime_Cong(ETmatfile,ExcelFile,idx)

load(ETmatfile)

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

%separating smr, ssvep, and feedback
events(:,6)=zeros;
events(:,7)=zeros;
events(:,8)=zeros;
for i=1:size(events,1)
    if events(i,3)==1.11||events(i,3)==1.21||events(i,3)==1.31||events(i,3)==1.41...
            ||events(i,3)==1.15||events(i,3)==1.25||events(i,3)==1.35||events(i,3)==1.45
        events(i,6)=events(i,3);
    elseif events(i,3)==2.11||events(i,3)==2.21||events(i,3)==2.31||events(i,3)==2.41...
            ||events(i,3)==2.15||events(i,3)==2.25||events(i,3)==2.35||events(i,3)==2.45
        events(i,7)=events(i,3);
    elseif events(i,3)==1.90||events(i,3)==1.91
        events(i,8)=events(i,3);
    else
    end
end

data.allon=events(:,4);
data.alloff=events(:,5);
data.smr=events(:,6);
data.ssvep=events(:,7);
data.feedback=events(:,8);

% figure;
% stem(events(:,1),[events(:,4) events(:,5)]);
% axis([t(1) t(end) 0 3]);

% on/off matrices for ssvep targets
smrtargets(1:size(events,1),1:5)=zeros;
clear tmp
for i=1:size(events,1)
    
    if data.feedback(i)==1.91
        tmp=i;
    end
    
    if exist('tmp','var')
        if data.smr(i)==1.11
            smrtargets(tmp:i,1)=1;
            smrtargets(tmp:i,5)=1;
        elseif data.smr(i)==1.21
            smrtargets(tmp:i,2)=1;
            smrtargets(tmp:i,5)=2;
        elseif data.smr(i)==1.31
            smrtargets(tmp:i,3)=1;
            smrtargets(tmp:i,5)=3;
        elseif data.smr(i)==1.41
            smrtargets(tmp:i,4)=1;
            smrtargets(tmp:i,5)=4;
        end
    end
    
end

% on/off matrices for ssvep targets
ssveptargets(1:size(events,1),1:5)=zeros;
clear tmpon tmpon2 tmpoffssvep tmpoffsmr
Ons=[]; Offs=[];
for i=1:size(events,1)
    
    if ismember(data.ssvep(i),[2.15,2.25,2.35,2.45])
        
        if ~exist('tmpon','var')
            tmpon=i;
            target=round((data.ssvep(i)-2.05)*10);
        elseif exist('tmpon','var') && ~exist('tmpoff','var')
            tmpon2=i;
            target2=round((data.ssvep(i)-2.05)*10);
            
            % Check if forgot to turn off last ssvep?
            SMR=data.smr(tmpon:tmpon2);
            smroff=find(ismember(SMR,[1.11,1.21,1.31,1.41]));
            if ~isempty(smroff)
                tmpoffsmr=tmpon+smroff-1;
            end
        end
    
    elseif ismember(data.ssvep(i),[2.11,2.21,2.31,2.41])
        tmpoff=i;
    end
    
    if exist('tmpon','var') && exist('tmpoffsmr','var')
        ssveptargets(tmpon:tmpoffsmr,target)=1;
        ssveptargets(tmpon:tmpoffsmr,5)=target;
        tmpon=tmpon2;
        Ons=[Ons tmpon];
        Offs=[Offs tmpoffsmr];
        target=target2;
        clear tmpoffsmr target2 tmpon2
    elseif exist('tmpon','var') && exist('tmpon2','var')
        ssveptargets(tmpon:tmpon2,target)=1;
        ssveptargets(tmpon:tmpon2,5)=target;
       
        % Determine if missed entire on and off
        trialstmp=round((tmpon2-tmpon)/100);
        if trialstmp>1
            for j=1:trialstmp
                
                if isequal(j,1)
                    Ons=[Ons tmpon];
                    Offs=[Offs tmpon+100];
                else
                    Ons=[Ons Ons(end)+101];
                    Offs=[Offs Offs(end)+101];
                end
            end
        else
            Ons=[Ons tmpon];
            Offs=[Offs tmpon2];
        end
        tmpon=tmpon2;
        target=target2;
        clear tmpon2 target2
    elseif exist('tmpon','var') && exist('tmpoff','var')
        ssveptargets(tmpon:tmpoff,target)=1;
        ssveptargets(tmpon:tmpoff,5)=target;
        
        % Determine if missed entire on and off
        trialstmp=round((tmpoff-tmpon)/100);
        if trialstmp>1
            for j=1:trialstmp
                
                if isequal(j,1)
                    Ons=[Ons tmpon];
                    Offs=[Offs tmpon+103];
                else
                    Ons=[Ons Ons(end)+103];
                    Offs=[Offs Offs(end)+103];
                end
            end
        else
            Ons=[Ons tmpon];
            Offs=[Offs tmpoff];
        end
        clear tmpon tmpoff target
    end
    
end

% figure; hold on
% plot(smrtargets(:,5))
% plot(ssveptargets(:,5),'r')
        
%% SMR hit, miss, abort and congruency
data=xlsread(ExcelFile,idx);
if isequal(size(data,2),7)
    % Identify where SMR trials start
    SMRtrial=find(~isnan(data(:,1)));
    SMRtrial(end+1)=size(data,1);

    SMR=cell(0);
    for j=1:size(SMRtrial,1)-1

        % Result for SMR
        if isequal(data(SMRtrial(j),3),0)
            SMR{j}=0;
        elseif isnan(data(SMRtrial(j),3))
            SMR{j}=nan;
        elseif isequal(data(SMRtrial(j),2),data(SMRtrial(j),3))
            SMR{j}=1;
        elseif ~isequal(data(SMRtrial(j),2),data(SMRtrial(j),3))
            SMR{j}=-1;
        end

        % Result for SSVEP (per SMR trial)
        if isempty(SMRtrial(j):SMRtrial(j+1)-1)
            SSVEPidx=SMRtrial(j);
        else
            SSVEPidx=SMRtrial(j):SMRtrial(j+1)-1;
        end
        SSVEP{j}=[]; Cong{j}=[];
        if isequal(size(SSVEPidx,2),0)
            Cong{j}=0;
        else
            for l=1:size(SSVEPidx,2)

                if isequal(data(SSVEPidx(l),7),0)
                    SSVEP{j}(end+1)=0;
                elseif isnan(data(SSVEPidx(l),7))
                    SSVEP{j}(end+1)=nan;
                elseif isequal(data(SSVEPidx(l),6),data(SSVEPidx(l),7))
                    SSVEP{j}(end+1)=1;
                elseif ~isequal(data(SSVEPidx(l),6),data(SSVEPidx(l),7))
                    SSVEP{j}(end+1)=-1;
                end

                % Congruency
                if isequal(data(SMRtrial(j),2),1)

                    if ismember(data(SSVEPidx(l),6),[1 2])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isequal(data(SMRtrial(j),2),2)

                    if ismember(data(SSVEPidx(l),6),[3 4])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isequal(data(SMRtrial(j),2),3)

                    if ismember(data(SSVEPidx(l),6),[2 4])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isequal(data(SMRtrial(j),2),4)

                    if ismember(data(SSVEPidx(l),6),[1 3])
                        Cong{j}(end+1)=1;
                    else
                        Cong{j}(end+1)=0;
                    end

                elseif isnan(data(SMRtrial(j),2))

                    Cong{j}=0;

                end

            end
        end
    end
    
    validssvep=Offs-Ons;
    Ons(validssvep<75)=[];
    Offs(validssvep<75)=[];
    
    smrresult=nan(size(events,1),1);
    cong=nan(size(events,1),1);
    smrtrialidx=1; ssveptrialidx=0;
    for j=1:size(events,1)-1
        
        % Vector of SMR results (1 - hit, 0 - abort, -1 - miss)
        if ~isequal(smrtargets(j,5),0) && smrtrialidx<=size(SMR,2)
            smrresult(j)=SMR{smrtrialidx};
        end
        
        % End of SMR trial
        if ~isequal(smrtargets(j,5),0) && isequal(smrtargets(j+1,5),0)
            smrtrialidx=smrtrialidx+1;
            ssveptrialidx=0;
        end
        
        % End of SSVEP trial        
        if ismember(j,Ons)
            ssveptrialidx=ssveptrialidx+1;
        end
        
        if ~isequal(ssveptargets(j,5),0) && smrtrialidx<=size(SMR,2) &&...
                ssveptrialidx<=size(Cong{smrtrialidx},2) && ssveptrialidx>0
            cong(j)=Cong{smrtrialidx}(ssveptrialidx);
        end
        
    end
    
    figure; hold on
    plot(smrtargets(:,5))
    plot(ssveptargets(:,5),'r')
    plot(cong,'k','linewidth',2)
    plot(smrresult+.1,'g','linewidth',2)


    %% best point of gaze values
    bpogvals(:,1)=t';
    bpogvals(:,2)=d.data(:,d.map('BPOGV'));
    bpogvals(:,3)=d.data(:,d.map('BPOGX'));
    bpogvals(:,4)=d.data(:,d.map('BPOGY'));
    valid=logical(bpogvals(:,2));
    % figure;
    % suptitle('session');
    % scatter(bpogvalsFull(validFull,3),bpogvalsFull(validFull,4));

    % Heat map for entire session - All targets
    % figure;
    % suptitle('session');
    histdat=[bpogvals(valid,3),bpogvals(valid,4)];
    % res=[200 200];
    EyeTrackerHist(histdat,'session');


    %% Heat map for entire session - individual SSVEP targets

    % SMR HIT MISS ABORT
    result=[1 0 -1]; % [hits aborts misses]
    t={'Hits','Aborts','Misses'};
    for i=1:3

    %     figure; subplot(2,2,1)
        hitidx=(valid & ssveptargets(:,1) & (smrresult==result(i)));
        histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
        [xb,yb,ssvephist1(:,:,i)]=EyeTrackerHist(histdat,'ssvep target1 and valid'); %title('1 - 7Hz');
    %     subplot(2,2,2)
        hitidx=(valid & ssveptargets(:,2) & (smrresult==result(i)));
        histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
        [xb,yb,ssvephist2(:,:,i)]=EyeTrackerHist(histdat,'ssvep target2 and valid'); %title('2 - 8.5Hz');
    %     subplot(2,2,3)
        hitidx=(valid & ssveptargets(:,3) & (smrresult==result(i)));
        histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
        [xb,yb,ssvephist3(:,:,i)]=EyeTrackerHist(histdat,'ssvep target3 and valid'); %title('3 - 10.5Hz');
    %     subplot(2,2,4)
        hitidx=(valid & ssveptargets(:,4) & (smrresult==result(i)));
        histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
        [xb,yb,ssvephist4(:,:,i)]=EyeTrackerHist(histdat,'ssvep target4 and valid'); %title('4 - 12.5Hz');
    %     suptitle(strcat('SSVEP Targets - SMR ',t{i}))

    end

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

    %{
    1 - 7Hz top left SSVEP
    2 - 8.5Hz bottom left SSVEP
    3 - 10.5Hz top right SSVEP
    4 - 12.5Hz bottom right SSVEP
    5 - Left SMR target
    6 - Right SMR target
    7 - top SMR target
    8 - bottom SMR target
    9 - Center/Other space
    %}

    


    for i=1:3

        ssvepT1=zeros(1,9); ssvepT2=zeros(1,9); ssvepT3=zeros(1,9); ssvepT4=zeros(1,9);
        
        DwellT1=zeros(size(ssvephist1,1),size(ssvephist1,2));
        DwellT2=zeros(size(ssvephist2,1),size(ssvephist2,2));
        DwellT3=zeros(size(ssvephist3,1),size(ssvephist3,2));
        DwellT4=zeros(size(ssvephist4,1),size(ssvephist4,2));
    
        T1tot=sum(sum(ssvephist1(:,:,i),1),2);
        ssvepT1(1)=sum(sum(ssvephist1(yq0:yq1-1,xq0:xq1-1,i),1),2)/T1tot*100;
        ssvepT1(2)=sum(sum(ssvephist1(yq3+1:yq4,xq0:xq1-1,i),1),2)/T1tot*100;
        ssvepT1(3)=sum(sum(ssvephist1(yq0:yq1-1,xq3+1:xq4,i),1),2)/T1tot*100;
        ssvepT1(4)=sum(sum(ssvephist1(yq3+1:yq4,xq3+1:xq4,i),1),2)/T1tot*100;
        ssvepT1(5)=sum(sum(ssvephist1(yq1:yq3,xq0:xq1-1,i),1),2)/T1tot*100;
        ssvepT1(6)=sum(sum(ssvephist1(yq1:yq3,yq3+1:yq4,i),1),2)/T1tot*100;
        ssvepT1(7)=sum(sum(ssvephist1(yq0:yq1-1,xq1:xq3,i),1),2)/T1tot*100;
        ssvepT1(8)=sum(sum(ssvephist1(yq3+1:yq4,xq1:xq3-1,i),1),2)/T1tot*100;
        ssvepT1(9)=sum(sum(ssvephist1(yq1:xq3,xq1:xq3,i),1),2)/T1tot*100;

        T2tot=sum(sum(ssvephist2(:,:,i),1),2);
        ssvepT2(1)=sum(sum(ssvephist2(yq0:yq1-1,xq0:xq1-1,i),1),2)/T2tot*100;
        ssvepT2(2)=sum(sum(ssvephist2(yq3+1:yq4,xq0:xq1-1,i),1),2)/T2tot*100;
        ssvepT2(3)=sum(sum(ssvephist2(yq0:yq1-1,xq3+1:xq4,i),1),2)/T2tot*100;
        ssvepT2(4)=sum(sum(ssvephist2(yq3+1:yq4,xq3+1:xq4,i),1),2)/T2tot*100;
        ssvepT2(5)=sum(sum(ssvephist2(yq1:yq3,xq0:xq1-1,i),1),2)/T2tot*100;
        ssvepT2(6)=sum(sum(ssvephist2(yq1:yq3,yq3+1:yq4,i),1),2)/T2tot*100;
        ssvepT2(7)=sum(sum(ssvephist2(yq0:yq1-1,xq1:xq3,i),1),2)/T2tot*100;
        ssvepT2(8)=sum(sum(ssvephist2(yq3+1:yq4,xq1:xq3-1,i),1),2)/T2tot*100;
        ssvepT2(9)=sum(sum(ssvephist2(yq1:xq3,xq1:xq3,i),1),2)/T2tot*100;

        T3tot=sum(sum(ssvephist3(:,:,i),1),2);
        ssvepT3(1)=sum(sum(ssvephist3(yq0:yq1-1,xq0:xq1-1,i),1),2)/T3tot*100;
        ssvepT3(2)=sum(sum(ssvephist3(yq3+1:yq4,xq0:xq1-1,i),1),2)/T3tot*100;
        ssvepT3(3)=sum(sum(ssvephist3(yq0:yq1-1,xq3+1:xq4,i),1),2)/T3tot*100;
        ssvepT3(4)=sum(sum(ssvephist3(yq3+1:yq4,xq3+1:xq4,i),1),2)/T3tot*100;
        ssvepT3(5)=sum(sum(ssvephist3(yq1:yq3,xq0:xq1-1,i),1),2)/T3tot*100;
        ssvepT3(6)=sum(sum(ssvephist3(yq1:yq3,yq3+1:yq4,i),1),2)/T3tot*100;
        ssvepT3(7)=sum(sum(ssvephist3(yq0:yq1-1,xq1:xq3,i),1),2)/T3tot*100;
        ssvepT3(8)=sum(sum(ssvephist3(yq3+1:yq4,xq1:xq3-1,i),1),2)/T3tot*100;
        ssvepT3(9)=sum(sum(ssvephist3(yq1:xq3,xq1:xq3,i),1),2)/T3tot*100;

        T4tot=sum(sum(ssvephist4(:,:,i),1),2);
        ssvepT4(1)=sum(sum(ssvephist4(yq0:yq1-1,xq0:xq1-1,i),1),2)/T4tot*100;
        ssvepT4(2)=sum(sum(ssvephist4(yq3+1:yq4,xq0:xq1-1,i),1),2)/T4tot*100;
        ssvepT4(3)=sum(sum(ssvephist4(yq0:yq1-1,xq3+1:xq4,i),1),2)/T4tot*100;
        ssvepT4(4)=sum(sum(ssvephist4(yq3+1:yq4,xq3+1:xq4,i),1),2)/T4tot*100;
        ssvepT4(5)=sum(sum(ssvephist4(yq1:yq3,xq0:xq1-1,i),1),2)/T4tot*100;
        ssvepT4(6)=sum(sum(ssvephist4(yq1:yq3,yq3+1:yq4,i),1),2)/T4tot*100;
        ssvepT4(7)=sum(sum(ssvephist4(yq0:yq1-1,xq1:xq3,i),1),2)/T4tot*100;
        ssvepT4(8)=sum(sum(ssvephist4(yq3+1:yq4,xq1:xq3-1,i),1),2)/T4tot*100;
        ssvepT4(9)=sum(sum(ssvephist4(yq1:xq3,xq1:xq3,i),1),2)/T4tot*100;

        DwellT1(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT1(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
        DwellT1(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT1(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
        DwellT1(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT1(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
        DwellT1(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT1(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
        DwellT1(yq1:yq3,xq0:xq1-1)=repmat(ssvepT1(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
        DwellT1(yq1:yq3,yq3+1:yq4)=repmat(ssvepT1(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
        DwellT1(yq0:yq1-1,xq1:xq3)=repmat(ssvepT1(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
        DwellT1(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT1(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
        DwellT1(yq1:xq3,xq1:xq3)=repmat(ssvepT1(9),size(yq1:xq3,2),size(xq1:xq3,2));
        % figure; subplot(2,2,1); imagesc(xb,yb,DwellT1(:,:,i)); caxis([0 100])

        DwellT2(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT2(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
        DwellT2(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT2(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
        DwellT2(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT2(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
        DwellT2(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT2(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
        DwellT2(yq1:yq3,xq0:xq1-1)=repmat(ssvepT2(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
        DwellT2(yq1:yq3,yq3+1:yq4)=repmat(ssvepT2(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
        DwellT2(yq0:yq1-1,xq1:xq3)=repmat(ssvepT2(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
        DwellT2(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT2(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
        DwellT2(yq1:xq3,xq1:xq3)=repmat(ssvepT2(9),size(yq1:xq3,2),size(xq1:xq3,2));
        % subplot(2,2,2); imagesc(xb,yb,DwellT2(:,:,i)); caxis([0 100])

        DwellT3(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT3(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
        DwellT3(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT3(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
        DwellT3(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT3(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
        DwellT3(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT3(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
        DwellT3(yq1:yq3,xq0:xq1-1)=repmat(ssvepT3(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
        DwellT3(yq1:yq3,yq3+1:yq4)=repmat(ssvepT3(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
        DwellT3(yq0:yq1-1,xq1:xq3)=repmat(ssvepT3(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
        DwellT3(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT3(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
        DwellT3(yq1:xq3,xq1:xq3)=repmat(ssvepT3(9),size(yq1:xq3,2),size(xq1:xq3,2));
        % subplot(1,2,3); imagesc(xb,yb,DwellT3(:,:,i)); caxis([0 100])

        DwellT4(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT4(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
        DwellT4(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT4(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
        DwellT4(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT4(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
        DwellT4(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT4(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
        DwellT4(yq1:yq3,xq0:xq1-1)=repmat(ssvepT4(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
        DwellT4(yq1:yq3,yq3+1:yq4)=repmat(ssvepT4(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
        DwellT4(yq0:yq1-1,xq1:xq3)=repmat(ssvepT4(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
        DwellT4(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT4(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
        DwellT4(yq1:xq3,xq1:xq3)=repmat(ssvepT4(9),size(yq1:xq3,2),size(xq1:xq3,2));
        % subplot(2,2,4); imagesc(xb,yb,DwellT4(:,:,i)); caxis([0 100])

        % suptitle(strcat('SSVEP Targets - SMR ',t{i}))

        Dwell.result.percent.(t{i})=[ssvepT1;ssvepT2;ssvepT3;ssvepT4];
        Dwell.result.mat.(t{i})=cat(3,DwellT1,DwellT2,DwellT3,DwellT4);
    end

    % Dwell.result.percent(:,:,1)=ssvepT1;
    % Dwell.result.percent(:,:,2)=ssvepT2;
    % Dwell.result.percent(:,:,3)=ssvepT3;
    % Dwell.result.percent(:,:,4)=ssvepT4;

%     Dwell.result.mat{1}=DwellT1;
%     Dwell.result.mat{2}=DwellT2;
%     Dwell.result.mat{3}=DwellT3;
%     Dwell.result.mat{4}=DwellT4;

    %% Congruency

    % SMR HIT MISS ABORT
    result=[1 0 -1]; % [hits aborts misses]
    congresult=[1 0];
    t={'Hits','Aborts','Misses'};
    t2={'cong','noncong'};

    clear ssvephist1 ssvephist2 ssvephist3 ssvephist4
    for i=1:3
        for j=1:2

    %         figure; subplot(2,2,1)
            hitidx=(valid & ssveptargets(:,1) & (smrresult==result(i)) & (cong==congresult(j)));
            histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
            [xb,yb,ssvephist1{j}(:,:,i)]=EyeTrackerHist(histdat,'ssvep target1 and valid');% title('1 - 7Hz');
    %         subplot(2,2,2)
            hitidx=(valid & ssveptargets(:,2) & (smrresult==result(i)) & (cong==congresult(j)));
            histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
            [xb,yb,ssvephist2{j}(:,:,i)]=EyeTrackerHist(histdat,'ssvep target2 and valid');% title('2 - 8.5Hz');
    %         subplot(2,2,3)
            hitidx=(valid & ssveptargets(:,3) & (smrresult==result(i)) & (cong==congresult(j)));
            histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
            [xb,yb,ssvephist3{j}(:,:,i)]=EyeTrackerHist(histdat,'ssvep target3 and valid'); %title('3 - 10.5Hz');
    %         subplot(2,2,4)
            hitidx=(valid & ssveptargets(:,4) & (smrresult==result(i)) & (cong==congresult(j)));
            histdat=[bpogvals(hitidx,3),bpogvals(hitidx,4)];
            [xb,yb,ssvephist4{j}(:,:,i)]=EyeTrackerHist(histdat,'ssvep target4 and valid');% title('4 - 12.5Hz');
    %         suptitle(strcat('SSVEP Targets - SMR ',t{i},' - ',t2{j}))

        end

    end


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

    %{
    1 - 7Hz top left SSVEP
    2 - 8.5Hz bottom left SSVEP
    3 - 10.5Hz top right SSVEP
    4 - 12.5Hz bottom right SSVEP
    5 - Left SMR target
    6 - Right SMR target
    7 - top SMR target
    8 - bottom SMR target
    9 - Center/Other space
    %}


    DwellT1=zeros(size(ssvephist1,1),size(ssvephist1,2),3,2);
    DwellT2=zeros(size(ssvephist2,1),size(ssvephist2,2),3,2);
    DwellT3=zeros(size(ssvephist3,1),size(ssvephist3,2),3,2);
    DwellT4=zeros(size(ssvephist4,1),size(ssvephist4,2),3,2);

    for i=1:3
        for j=1:2

            ssvepT1=zeros(1,9); ssvepT2=zeros(1,9); ssvepT3=zeros(1,9); ssvepT4=zeros(1,9);
            
            DwellT1=zeros(size(ssvephist1,1),size(ssvephist1,2));
            DwellT2=zeros(size(ssvephist2,1),size(ssvephist2,2));
            DwellT3=zeros(size(ssvephist3,1),size(ssvephist3,2));
            DwellT4=zeros(size(ssvephist4,1),size(ssvephist4,2));
        
            T1tot=sum(sum(ssvephist1{j}(:,:,i),1),2);
            ssvepT1(1)=sum(sum(ssvephist1{j}(yq0:yq1-1,xq0:xq1-1,i),1),2)/T1tot*100;
            ssvepT1(2)=sum(sum(ssvephist1{j}(yq3+1:yq4,xq0:xq1-1,i),1),2)/T1tot*100;
            ssvepT1(3)=sum(sum(ssvephist1{j}(yq0:yq1-1,xq3+1:xq4,i),1),2)/T1tot*100;
            ssvepT1(4)=sum(sum(ssvephist1{j}(yq3+1:yq4,xq3+1:xq4,i),1),2)/T1tot*100;
            ssvepT1(5)=sum(sum(ssvephist1{j}(yq1:yq3,xq0:xq1-1,i),1),2)/T1tot*100;
            ssvepT1(6)=sum(sum(ssvephist1{j}(yq1:yq3,yq3+1:yq4,i),1),2)/T1tot*100;
            ssvepT1(7)=sum(sum(ssvephist1{j}(yq0:yq1-1,xq1:xq3,i),1),2)/T1tot*100;
            ssvepT1(8)=sum(sum(ssvephist1{j}(yq3+1:yq4,xq1:xq3-1,i),1),2)/T1tot*100;
            ssvepT1(9)=sum(sum(ssvephist1{j}(yq1:xq3,xq1:xq3,i),1),2)/T1tot*100;

            T2tot=sum(sum(ssvephist2{j}(:,:,i),1),2);
            ssvepT2(1)=sum(sum(ssvephist2{j}(yq0:yq1-1,xq0:xq1-1,i),1),2)/T2tot*100;
            ssvepT2(2)=sum(sum(ssvephist2{j}(yq3+1:yq4,xq0:xq1-1,i),1),2)/T2tot*100;
            ssvepT2(3)=sum(sum(ssvephist2{j}(yq0:yq1-1,xq3+1:xq4,i),1),2)/T2tot*100;
            ssvepT2(4)=sum(sum(ssvephist2{j}(yq3+1:yq4,xq3+1:xq4,i),1),2)/T2tot*100;
            ssvepT2(5)=sum(sum(ssvephist2{j}(yq1:yq3,xq0:xq1-1,i),1),2)/T2tot*100;
            ssvepT2(6)=sum(sum(ssvephist2{j}(yq1:yq3,yq3+1:yq4,i),1),2)/T2tot*100;
            ssvepT2(7)=sum(sum(ssvephist2{j}(yq0:yq1-1,xq1:xq3,i),1),2)/T2tot*100;
            ssvepT2(8)=sum(sum(ssvephist2{j}(yq3+1:yq4,xq1:xq3-1,i),1),2)/T2tot*100;
            ssvepT2(9)=sum(sum(ssvephist2{j}(yq1:xq3,xq1:xq3,i),1),2)/T2tot*100;

            T3tot=sum(sum(ssvephist3{j}(:,:,i),1),2);
            ssvepT3(1)=sum(sum(ssvephist3{j}(yq0:yq1-1,xq0:xq1-1,i),1),2)/T3tot*100;
            ssvepT3(2)=sum(sum(ssvephist3{j}(yq3+1:yq4,xq0:xq1-1,i),1),2)/T3tot*100;
            ssvepT3(3)=sum(sum(ssvephist3{j}(yq0:yq1-1,xq3+1:xq4,i),1),2)/T3tot*100;
            ssvepT3(4)=sum(sum(ssvephist3{j}(yq3+1:yq4,xq3+1:xq4,i),1),2)/T3tot*100;
            ssvepT3(5)=sum(sum(ssvephist3{j}(yq1:yq3,xq0:xq1-1,i),1),2)/T3tot*100;
            ssvepT3(6)=sum(sum(ssvephist3{j}(yq1:yq3,yq3+1:yq4,i),1),2)/T3tot*100;
            ssvepT3(7)=sum(sum(ssvephist3{j}(yq0:yq1-1,xq1:xq3,i),1),2)/T3tot*100;
            ssvepT3(8)=sum(sum(ssvephist3{j}(yq3+1:yq4,xq1:xq3-1,i),1),2)/T3tot*100;
            ssvepT3(9)=sum(sum(ssvephist3{j}(yq1:xq3,xq1:xq3,i),1),2)/T3tot*100;

            T4tot=sum(sum(ssvephist4{j}(:,:,i),1),2);
            ssvepT4(1)=sum(sum(ssvephist4{j}(yq0:yq1-1,xq0:xq1-1,i),1),2)/T4tot*100;
            ssvepT4(2)=sum(sum(ssvephist4{j}(yq3+1:yq4,xq0:xq1-1,i),1),2)/T4tot*100;
            ssvepT4(3)=sum(sum(ssvephist4{j}(yq0:yq1-1,xq3+1:xq4,i),1),2)/T4tot*100;
            ssvepT4(4)=sum(sum(ssvephist4{j}(yq3+1:yq4,xq3+1:xq4,i),1),2)/T4tot*100;
            ssvepT4(5)=sum(sum(ssvephist4{j}(yq1:yq3,xq0:xq1-1,i),1),2)/T4tot*100;
            ssvepT4(6)=sum(sum(ssvephist4{j}(yq1:yq3,yq3+1:yq4,i),1),2)/T4tot*100;
            ssvepT4(7)=sum(sum(ssvephist4{j}(yq0:yq1-1,xq1:xq3,i),1),2)/T4tot*100;
            ssvepT4(8)=sum(sum(ssvephist4{j}(yq3+1:yq4,xq1:xq3-1,i),1),2)/T4tot*100;
            ssvepT4(9)=sum(sum(ssvephist4{j}(yq1:xq3,xq1:xq3,i),1),2)/T4tot*100;

            DwellT1(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT1(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
            DwellT1(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT1(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
            DwellT1(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT1(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
            DwellT1(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT1(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
            DwellT1(yq1:yq3,xq0:xq1-1)=repmat(ssvepT1(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
            DwellT1(yq1:yq3,yq3+1:yq4)=repmat(ssvepT1(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
            DwellT1(yq0:yq1-1,xq1:xq3)=repmat(ssvepT1(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
            DwellT1(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT1(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
            DwellT1(yq1:xq3,xq1:xq3)=repmat(ssvepT1(9),size(yq1:xq3,2),size(xq1:xq3,2));
            % figure; subplot(2,2,1); imagesc(xb,yb,DwellT1(:,:,i)); caxis([0 100])

            DwellT2(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT2(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
            DwellT2(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT2(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
            DwellT2(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT2(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
            DwellT2(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT2(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
            DwellT2(yq1:yq3,xq0:xq1-1)=repmat(ssvepT2(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
            DwellT2(yq1:yq3,yq3+1:yq4)=repmat(ssvepT2(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
            DwellT2(yq0:yq1-1,xq1:xq3)=repmat(ssvepT2(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
            DwellT2(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT2(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
            DwellT2(yq1:xq3,xq1:xq3)=repmat(ssvepT2(9),size(yq1:xq3,2),size(xq1:xq3,2));
            % subplot(2,2,2); imagesc(xb,yb,DwellT2(:,:,i)); caxis([0 100])

            DwellT3(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT3(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
            DwellT3(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT3(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
            DwellT3(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT3(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
            DwellT3(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT3(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
            DwellT3(yq1:yq3,xq0:xq1-1)=repmat(ssvepT3(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
            DwellT3(yq1:yq3,yq3+1:yq4)=repmat(ssvepT3(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
            DwellT3(yq0:yq1-1,xq1:xq3)=repmat(ssvepT3(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
            DwellT3(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT3(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
            DwellT3(yq1:xq3,xq1:xq3)=repmat(ssvepT3(9),size(yq1:xq3,2),size(xq1:xq3,2));
            % subplot(1,2,3); imagesc(xb,yb,DwellT3(:,:,i)); caxis([0 100])

            DwellT4(yq0:yq1-1,xq0:xq1-1)=repmat(ssvepT4(1),size(yq0:yq1-1,2),size(xq0:xq1-1,2));
            DwellT4(yq3+1:yq4,xq0:xq1-1)=repmat(ssvepT4(2),size(yq3+1:yq4,2),size(xq0:xq1-1,2));
            DwellT4(yq0:yq1-1,xq3+1:xq4)=repmat(ssvepT4(3),size(yq0:yq1-1,2),size(xq3+1:xq4,2));
            DwellT4(yq3+1:yq4,xq3+1:xq4)=repmat(ssvepT4(4),size(yq3+1:yq4,2),size(xq3+1:xq4,2));
            DwellT4(yq1:yq3,xq0:xq1-1)=repmat(ssvepT4(5),size(yq1:yq3,2),size(xq0:xq1-1,2));
            DwellT4(yq1:yq3,yq3+1:yq4)=repmat(ssvepT4(6),size(yq1:yq3,2),size(yq3+1:yq4,2));
            DwellT4(yq0:yq1-1,xq1:xq3)=repmat(ssvepT4(7),size(yq0:yq1-1,2),size(xq1:xq3,2));
            DwellT4(yq3+1:yq4,xq1:xq3-1)=repmat(ssvepT4(8),size(yq3+1:yq4,2),size(xq1:xq3-1,2));
            DwellT4(yq1:xq3,xq1:xq3)=repmat(ssvepT4(9),size(yq1:xq3,2),size(xq1:xq3,2));
            % subplot(2,2,4); imagesc(xb,yb,DwellT4(:,:,i)); caxis([0 100])

            % suptitle(strcat('SSVEP Targets - SMR ',t{i}))


            Dwell.(t2{j}).percent.(t{i})=[ssvepT1;ssvepT2;ssvepT3;ssvepT4];
            
            Dwell.(t2{j}).mat.(t{i})=cat(3,DwellT1,DwellT2,DwellT3,DwellT4);

        end
    end



    % Dwell.cong.percent(:,:,1)=ssvepT1(:,:,1);
    % Dwell.cong.percent(:,:,2)=ssvepT2(:,:,1);
    % Dwell.cong.percent(:,:,3)=ssvepT3(:,:,1);
    % Dwell.cong.percent(:,:,4)=ssvepT4(:,:,1);
    % 
    % Dwell.noncong.percent(:,:,1)=ssvepT1(:,:,2);
    % Dwell.noncong.percent(:,:,2)=ssvepT2(:,:,2);
    % Dwell.noncong.percent(:,:,3)=ssvepT3(:,:,2);
    % Dwell.noncong.percent(:,:,4)=ssvepT4(:,:,2);


%     Dwell.cong.mat{1}=DwellT1;
%     Dwell.cong.mat{2}=DwellT2;
%     Dwell.cong.mat{3}=DwellT3;
%     Dwell.cong.mat{4}=DwellT4;

else
    
    Dwell.result.percent.Hits=nan(4,9);
    Dwell.result.percent.Aborts=nan(4,9);
    Dwell.result.percent.Misses=nan(4,9);
    
    Dwell.cong.percent.Hits=nan(4,9);
    Dwell.cong.percent.Aborts=nan(4,9);
    Dwell.cong.percent.Misses=nan(4,9);
    
    Dwell.noncong.percent.Hits=nan(4,9);
    Dwell.noncong.percent.Aborts=nan(4,9);
    Dwell.noncong.percent.Misses=nan(4,9);
    
    Dwell.noncong.mat{1}=[];
    Dwell.noncong.mat{2}=[];
    Dwell.noncong.mat{3}=[];
    Dwell.noncong.mat{4}=[];
    
    Dwell.cong.mat{1}=[];
    Dwell.cong.mat{2}=[];
    Dwell.cong.mat{3}=[];
    Dwell.cong.mat{4}=[];
    
end
