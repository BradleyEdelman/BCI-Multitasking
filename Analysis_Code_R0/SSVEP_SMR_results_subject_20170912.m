%% make and save a results matrix for a subject folder of matlab data
clear all
datadir='M:\_bci_Multitasking\_Multi_Data\';
Subj={'BE' 'DS' 'HL' 'JM' 'NG' 'NG2' 'NJ' 'PS' 'TS'};


for ii=1:size(Subj,2)
    
    subjectFolder=strcat(datadir,Subj{ii});
    
    % Session folders
    sessiondir=dir(subjectFolder);
    sessiondir=sessiondir(arrayfun(@(x) x.name(1),sessiondir)~='.');
    sessiondir=sessiondir(arrayfun(@(x) x.name(end-2),sessiondir)=='S');
    
    % Excel Files
    exceldir=dir(subjectFolder);
    exceldir=exceldir(arrayfun(@(x) x.name(1),exceldir)~='.');
    exceldir=exceldir(arrayfun(@(x) x.name(1),exceldir)=='C');
    excelNames={exceldir.name};
    
    % Default result format for all sessions
    resulttmp=struct('SSVEP',[],'LR',[],'UD',[],'TWOD',[],'mSSVEP',[],'mTWOD',[]);

    sessionNames={sessiondir.name};
    for i=2:size(sessionNames,2)

        % Session Folder
        session=sessionNames{i};
        sessionNum=session(end-2:end);
        sessionFolder = [subjectFolder '\' session];

        % Run Files
        rundir = dir(sessionFolder);
        rundir=rundir(arrayfun(@(x) x.name(1),rundir)~='.');
        rundir=rundir(arrayfun(@(x) x.name(end-2),rundir)=='R');
        runFiles={rundir.name};

        results.(sessionNum)=resulttmp;

        tothitSSVEP=0; totmissSSVEP=0;
        tothitLR=0; totmissLR=0;
        tothitUD=0; totmissUD=0;
        tothitTWOD=0; totmissTWOD=0;
        tothitmSSVEP=0; totmissmSSVEP=0;
        tothitmTWOD=0; totmissmTWOD=0;

        % Extract run files, param files, and run types from .mat data
        type=cell(1,size(runFiles,1));
        for j=1:size(runFiles,2)
            
            run=runFiles{j};
            runNum=run(end-2:end);
            runFolder = [sessionFolder '\' run];
            if isequal(sum(isstrprop(runFolder(end-15:end-14),'alpha')),2)
                runFIle = [runFolder '\' runFolder(end-15:end) '.mat'];
                runFile{j}=dir(runFIle);
                paramFile{j} = [runFolder '\' runFolder(end-15:end) 'Param.mat'];
                runFile2{j}=strcat(runFile{j}.folder,'\',runFile{j}.name);
            else
                runFIle = [runFolder '\' runFolder(end-16:end) '.mat'];
                runFile{j}=dir(runFIle);
                paramFile{j} = [runFolder '\' runFolder(end-16:end) 'Param.mat'];
                runFile2{j}=strcat(runFile{j}.folder,'\',runFile{j}.name);
            end
            
            if exist(paramFile{j},'file')
                param = load(paramFile{j});
                tasks=fieldnames(param.performance);
                
                if ismember('SSVEP',tasks) && ~ismember('SMR',tasks)
                    type{j}='SSVEP';
                elseif ismember('SMR',tasks) && ~ismember('SSVEP',tasks)
                    type{j}='SMR';
                elseif ismember('SSVEP',tasks) && ismember('SMR',tasks)
                    type{j}='Multi';
                end
            end
            
        end
        
        SSVEPidx{i}=find(strcmp(type,'SSVEP'));
        Multiidx{i}=find(strcmp(type,'Multi'));
        
        FFTSSVEP=zeros(4,512); FFTMulti=zeros(4,512);
        for j=1:size(runFiles,2)

            param=load(paramFile{j});

            % SSVEP
            if strcmp(type{j},'SSVEP')
                
                if ~isempty(param.performance.SSVEP)
                    tmphits=sum(strcmp(param.performance.SSVEP(:,3),'Hit'));
                    tmpmisses=sum(strcmp(param.performance.SSVEP(:,3),'Miss'));
                    results.(sessionNum).SSVEP(end+1).hit=tmphits;
                    results.(sessionNum).SSVEP(end).miss=tmpmisses;

                    if ~isnan(tmphits/(tmphits+tmpmisses))
                        results.(sessionNum).SSVEP(end).acc=tmphits/(tmphits+tmpmisses);
                        tothitSSVEP=tothitSSVEP+tmphits; totmissSSVEP=totmissSSVEP+tmpmisses;
                    end
                    
                    % SSVEP Extraction
                    ssvepT=str2num(cell2mat(param.performance.SSVEP(:,1)));
                    load(runFile2{j})
                    
                    for k=1:size(dat.SSVEP.psd.window,2)
                        dat.SSVEP.psd.window{k}=mean(dat.SSVEP.psd.window{k},1);
                    end
                    
                    for k=1:4
                        tmp=mean(vertcat(dat.SSVEP.psd.window{ssvepT==k}),1);
                        if ~isempty(tmp); FFTSSVEP(k,:,j)=tmp; end
                    end
                    
                end
                
            end

            % SMR 
            if strcmp(type{j},'SMR')
                
                if ~isempty(param.performance.SMR.results)
                    tmphits=sum(strcmp(param.performance.SMR.results(:,3),'Hit'));
                    tmpmisses=sum(strcmp(param.performance.SMR.results(:,3),'Miss'));

                    idx=param.bci.SMR.freqidx;
                    if ~isempty(idx{1}) && ~isempty(idx{2})
                        resulttype='TWOD';
                        tothitTWOD=tothitTWOD+tmphits; totmissTWOD=totmissTWOD+tmpmisses;
                    elseif ~isempty(idx{1}) && isempty(idx{2})
                        resulttype='LR';
                        tothitLR=tothitLR+tmphits; totmissLR=totmissLR+tmpmisses;
                    elseif isempty(idx{1}) && ~isempty(idx{2})
                        resulttype='UD';
                        tothitUD=tothitUD+tmphits; totmissUD=totmissUD+tmpmisses;
                    end

                    results.(sessionNum).(resulttype)(end+1).hit=tmphits;
                    results.(sessionNum).(resulttype)(end).miss=tmpmisses;
                    results.(sessionNum).(resulttype)(end).acc=tmphits/(tmphits+tmpmisses);
                end
            end

            % MULTITASKING
            if strcmp(type{j},'Multi')
                
                % SSVEP
                if ~isempty(param.performance.SSVEP)
                    tmphits=sum(strcmp(param.performance.SSVEP(:,3),'Hit'));
                    tmpmisses=sum(strcmp(param.performance.SSVEP(:,3),'Miss'));
                    results.(sessionNum).mSSVEP(end+1).hit=tmphits;
                    results.(sessionNum).mSSVEP(end).miss=tmpmisses;
                    results.(sessionNum).mSSVEP(end).acc=tmphits/(tmphits+tmpmisses);
                    tothitmSSVEP=tothitmSSVEP+tmphits; totmissmSSVEP=totmissmSSVEP+tmpmisses;
                    
                    % SSVEP Extraction
                    ssvepT=str2num(cell2mat(param.performance.SSVEP(:,1)));
                    load(runFile2{j})
                    
                    for k=1:size(dat.SSVEP.psd.window,2)
                        dat.SSVEP.psd.window{k}=mean(dat.SSVEP.psd.window{k},1);
                    end
                    
                    for k=1:4
                        tmp=mean(vertcat(dat.SSVEP.psd.window{ssvepT==k}),1);
                        if ~isempty(tmp); FFTMulti(k,:,j)=tmp; end
                    end
                end

                % SMR
                if ~isempty(param.performance.SMR.results)
                    tmphits=sum(strcmp(param.performance.SMR.results(:,3),'Hit'));
                    tmpmisses=sum(strcmp(param.performance.SMR.results(:,3),'Miss'));
                    results.(sessionNum).mTWOD(end+1).hit=tmphits;
                    results.(sessionNum).mTWOD(end).miss=tmpmisses;
                    results.(sessionNum).mTWOD(end).acc=tmphits/(tmphits+tmpmisses);
                    tothitmTWOD=tothitmTWOD+tmphits; totmissmTWOD=totmissmTWOD+tmpmisses;
                end
                
            end

        end
 
        % SSVEP
        results.(sessionNum).FFT=FFTSSVEP(:,:,SSVEPidx{i});
        results.(sessionNum).mFFT=FFTMulti(:,:,Multiidx{i});
        
        %% Session PVC results
        results.(sessionNum).session.SSVEP=tothitSSVEP/(tothitSSVEP+totmissSSVEP);
        results.(sessionNum).session.LR=tothitLR/(tothitLR+totmissLR);
        results.(sessionNum).session.UD=tothitUD/(tothitUD+totmissUD);
        results.(sessionNum).session.TWOD=tothitTWOD/(tothitTWOD+totmissTWOD);
        results.(sessionNum).session.mSSVEP=tothitmSSVEP/(tothitmSSVEP+totmissmSSVEP);
        results.(sessionNum).session.mTWOD=tothitmTWOD/(tothitmTWOD+totmissmTWOD);
        results.(sessionNum).session.FFT=mean(FFTSSVEP(:,:,SSVEPidx{i}),3);
        results.(sessionNum).session.mFFT=mean(FFTMulti(:,:,Multiidx{i}),3);

    end
    
    % CONGRUENCY AND Trial-by-trial Multi Accuracy ANALYSIS
    for i=2:size(sessionNames,2)
        
        % Session Folder
        session=sessionNames{i};
        sessionNum=session(end-2:end);
        
        ExcelFile=strcat(subjectFolder,'\',excelNames(i-1));
        [smrhit,smrmiss,smrabort]=SSVEP_Congruency(ExcelFile{1});

        results.(sessionNum).smrhit=smrhit;
        results.(sessionNum).smrabort=smrabort;
        results.(sessionNum).smrmiss=smrmiss;

    end
    
    % EYE TRACKER ANALYSIS
    for i=2:size(sessionNames,2)
        
        % Session Folder
        session=sessionNames{i};
        sessionNum=session(end-2:end);
        sessionFolder=[subjectFolder '\' session];
        
        etfolder=dir(sessionFolder);
        etfolder=etfolder(arrayfun(@(x) x.name(1),etfolder)~='.');
        etfolder=etfolder(arrayfun(@(x) x.name(1),etfolder)=='E');
        etfolder=strcat(sessionFolder,'\',etfolder.name);
        
        etfiles=dir(etfolder);
        etfiles=etfiles(arrayfun(@(x) x.name(1),etfiles)~='.');
        etfiles=etfiles(arrayfun(@(x) x.name(end),etfiles)=='t');
        for j=1:size(etfiles,1)
            etfilename{j}=strcat(etfolder,'\',etfiles(j).name);
        end
        
        if strcmp(Subj{ii},'BE') && strcmp(sessionNum,'S02')
            Multiidx{i}=1:4;
            SSVEPidx{i}=5:12;
        elseif strcmp(Subj{ii},'NJ') && strcmp(sessionNum,'S02')
            Multiidx{i}=1:7;
            SSVEPidx{i}=8:15;
        elseif strcmp(Subj{ii},'PS') && strcmp(sessionNum,'S02')
            Multiidx{i}=3:10;
            SSVEPidx{i}=1:2;
        elseif strcmp(Subj{ii},'PS') && strcmp(sessionNum,'S04')
            Multiidx{i}=[];
            SSVEPidx{i}=[];
        elseif max(Multiidx{i})<min(SSVEPidx{i})
            Multiidx{i}=1:size(Multiidx{i},2);
            SSVEPidx{i}=size(Multiidx{i},2)+1:size(Multiidx{i},2)+size(SSVEPidx{i},2);
        elseif max(SSVEPidx{i})<min(Multiidx{i})
            SSVEPidx{i}=1:size(SSVEPidx{i},2);
            Multiidx{i}=size(SSVEPidx{i},2)+1:size(SSVEPidx{i},2)+size(Multiidx{i},2);
        end
        
        
        % SSVEP only files 
        etssvep=etfilename(SSVEPidx{i});
        for j=1:size(etssvep,2)
            Dwellssvep(j)=ET_DwellTime(etssvep{j}); close all
        end
        
        % Multitask files
        etmulti=etfilename(Multiidx{i});
        for j=1:size(etmulti,2)
            Dwellmulti(j)=ET_DwellTime(etmulti{j}); close all
        end
        
        % CONGRUENCY AND Trial-by-trial Multi Eyetracker ANALYSIS
        ExcelFile=strcat(subjectFolder,'\',excelNames(i-1));
        for j=1:size(etmulti,2)
            
            if strcmp(Subj{ii},'BE') && strcmp(sessionNum,'S02'); idx=j+4;
            else; idx=j; end
            
            Dwellmulticong(j)=ET_DwellTime_Cong(etmulti{j},ExcelFile{1},idx);
            
        end
        
        results.(sessionNum).Dwellssvep=Dwellssvep;
        results.(sessionNum).Dwellmulti=Dwellmulti;
        results.(sessionNum).Dwellmulticong=Dwellmulticong;
        
    end
        

    %save results
    resultsFile=[subjectFolder '\' 'results.mat']
    save(resultsFile,'results','-v7.3');
end


%%
S='S02'
S='S03'
S='S04'

%%
S
% SSVEP and Multi Total Sessions
nonanmean(results.(S).Dwellssvep(:).percent)
nonanmean(results.(S).Dwellmulti(:).percent)

% SMR HIT MISS ABORT DURING MULTI
clear H A M
for i=1:size(results.(S).Dwellmulticong,2)
    H(:,:,i)=results.(S).Dwellmulticong(i).result.percent.Hits;
    A(:,:,i)=results.(S).Dwellmulticong(i).result.percent.Aborts;
    M(:,:,i)=results.(S).Dwellmulticong(i).result.percent.Misses;
end
nonanmean(H)
nonanmean(A)
nonanmean(M)


% SMR HIT MISS ABORT DURING CONGRUENT MULTI
clear Hcong Acong Mcong
for i=1:size(results.(S).Dwellmulticong,2)
    Hcong(:,:,i)=results.(S).Dwellmulticong(i).cong.percent.Hits;
    Acong(:,:,i)=results.(S).Dwellmulticong(i).cong.percent.Aborts;
    Mcong(:,:,i)=results.(S).Dwellmulticong(i).cong.percent.Misses;
end
nonanmean(Hcong)
nonanmean(Acong)
nonanmean(Mcong)

% SMR HIT MISS ABORT DURING NONCONGRUENT MULTI
clear Hnoncong Anoncong Mnoncong
for i=1:size(results.(S).Dwellmulticong,2)
    Hnoncong(:,:,i)=results.(S).Dwellmulticong(i).noncong.percent.Hits;
    Anoncong(:,:,i)=results.(S).Dwellmulticong(i).noncong.percent.Aborts;
    Mnoncong(:,:,i)=results.(S).Dwellmulticong(i).noncong.percent.Misses;
end
nonanmean(Hnoncong)
nonanmean(Anoncong)
nonanmean(Mnoncong)

%%
datadir='M:\_bci_Multitasking\_Multi_Data\';
Subj={'BE' 'DS' 'HL' 'JM' 'NG' 'NG2' 'NJ' 'TS'};

S=cell(1,4); M=cell(1,4);
mh=cell(1,4); mm=cell(1,4); ma=cell(1,4);

for ii=1:size(Subj,2)

    
    subjectFolder=strcat(datadir,Subj{ii});
    %save results
    resultsFile=[subjectFolder '\' 'results.mat'];
    load(resultsFile)
    
    for j=1:3
        sessionNum=strcat('S0',num2str(j+1));
        
        % Session average
        % ssvep alone
        Dwellssvep=results.(sessionNum).Dwellssvep;
        stmp=mean(cat(4,Dwellssvep(:).mat),4);
        
        % multi alone
        Dwellmulti=results.(sessionNum).Dwellmulti;
        mtmp=mean(cat(4,Dwellmulti(:).mat),4);
        
        % multi hits misses aborts
        h=zeros(202,202,4);
        m=zeros(202,202,4);
        a=zeros(202,202,4);
        for k=1:size(Dwellmulticong,2)
            h=cat(4,h,Dwellmulticong(k).result.mat.Hits);
            m=cat(4,m,Dwellmulticong(k).result.mat.Hits);
            a=cat(4,a,Dwellmulticong(k).result.mat.Hits);
        end
        h(:,:,:,1)=[]; m(:,:,:,1)=[]; a(:,:,:,1)=[];
        h=mean(h,4); m=mean(m,4); a=mean(a,4);
        
        for k=1:4
            if isequal(j,1) && isequal(ii,1)
                S{k}(:,:,end)=stmp(:,:,k);
                M{k}(:,:,end)=mtmp(:,:,k);
                mh{k}(:,:,end)=h(:,:,k);
                mm{k}(:,:,end)=m(:,:,k);
                ma{k}(:,:,end)=a(:,:,k);
            else
                S{k}(:,:,end+1)=stmp(:,:,k);
                M{k}(:,:,end+1)=mtmp(:,:,k);
                mh{k}(:,:,end+1)=h(:,:,k);
                mm{k}(:,:,end+1)=m(:,:,k);
                ma{k}(:,:,end+1)=a(:,:,k);
            end
        end

    end
    
end




[results.(S).smrhit.count;
results.(S).smrhit.ssvephit;
results.(S).smrhit.ssvepmiss;
results.(S).smrhit.ssvepabort;
results.(S).smrhit.conghits;
results.(S).smrhit.congmisses;
results.(S).smrhit.nonconghits;
results.(S).smrhit.noncongmisses]

[results.(S).smrabort.count;
results.(S).smrabort.ssvephit;
results.(S).smrabort.ssvepmiss;
results.(S).smrabort.ssvepabort;
results.(S).smrabort.conghits;
results.(S).smrabort.congmisses;
results.(S).smrabort.nonconghits;
results.(S).smrabort.noncongmisses]

[results.(S).smrmiss.count;
results.(S).smrmiss.ssvephit;
results.(S).smrmiss.ssvepmiss;
results.(S).smrmiss.ssvepabort;
results.(S).smrmiss.conghits;
results.(S).smrmiss.congmisses;
results.(S).smrmiss.nonconghits;
results.(S).smrmiss.noncongmisses]








