%% make and save a results matrix for a subject folder of matlab data

datadir='M:\_bci_Multitasking\_Multi_Data\';
Subj={'BE' 'DS' 'HL' 'JM' 'NG' 'NG2' 'NJ' 'PS' 'TS'};


for ii=1:size(Subj,2)
    
    subjectFolder=strcat(datadir,Subj{ii});

    sessiondir = dir(subjectFolder);
    sessiondir=sessiondir(arrayfun(@(x) x.name(1),sessiondir)~='.');
    sessiondir=sessiondir(arrayfun(@(x) x.name(end-2),sessiondir)=='S');

    % Default result format for all sessions
    resulttmp=struct('SSVEP',[],'LR',[],'UD',[],'TWOD',[],'mSSVEP',[],'mTWOD',[]);

    sessionNames={sessiondir.name};
    for i=1:size(sessionNames,2)

        % Session Folder
        session=sessionNames{i};
        sessionNum=session(end-2:end);
        sessionFolder = [subjectFolder '\' session];

        % Run Files
        rundir = dir(sessionFolder);
        rundir=rundir(arrayfun(@(x) x.name(1),rundir)~='.');
        rundir=rundir(arrayfun(@(x) x.name(end-2),rundir)=='R');
        runFiles={rundir.name};
        
        datdir=dir(sessionFolder);
        datdir=datdir(arrayfun(@(x) x.name(1),datdir)~='.');
        datdir={datdir.name};
        datdir(~contains(datdir,'Multitask'))=[];
        datdir=strcat(sessionFolder,'\',char(datdir));
        datFiles=dir(datdir);
        datFiles=datFiles(arrayfun(@(x) x.name(1),datFiles)~='.');

        results.(sessionNum)=resulttmp;

        tothitSSVEP=0; totmissSSVEP=0;
        tothitLR=0; totmissLR=0;
        tothitUD=0; totmissUD=0;
        tothitTWOD=0; totmissTWOD=0;
        tothitmSSVEP=0; totmissmSSVEP=0;
        tothitmTWOD=0; totmissmTWOD=0;

        % Extract run files, param files, and run types from .mat data
        for j=1:size(runFiles,2)
            
            run=runFiles{j};
            runNum=run(end-2:end);
            runFolder = [sessionFolder '\' run];
            if isequal(sum(isstrprop(runFolder(end-15:end-14),'alpha')),2)
                runFIle = [runFolder '\' runFolder(end-15:end) '.mat'];
                runFile{j}=dir(runFIle);
                paramFile{j} = [runFolder '\' runFolder(end-15:end) 'Param.mat'];
            else
                runFIle = [runFolder '\' runFolder(end-16:end) '.mat'];
                runFile{j}=dir(runFIle);
                paramFile{j} = [runFolder '\' runFolder(end-16:end) 'Param.mat'];
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
        
        SSVEPidx=find(strcmp(type,'SSVEP'));
        Multiidx=find(strcmp(type,'Multi'));

        if max(SSVEPidx)<min(Multiidx)
            SSVEPidx=1:size(SSVEPidx,2);
            Multiidx=size(SSVEPidx,2)+1:size(SSVEPidx,2)+size(Multiidx,2);
        elseif max(Multiidx)<min(SSVEPidx)
            Multiidx=1:size(Multiidx,2);
            SSVEPidx=size(Multiidx,2)+1:size(Multiidx,2)+size(SSVEPidx,2);
        end

        ETdir = dir(sessionFolder);
        ETdir=ETdir(arrayfun(@(x) x.name(1),ETdir)~='.');
        ETdir=ETdir(arrayfun(@(x) x.name(1),ETdir)=='E');
        ETdir=ETdir(arrayfun(@(x) x.name(2),ETdir)=='T');
        ETdir=strcat(sessionFolder,'\',ETdir.name);
        etdir=dir(ETdir);
        etdir=etdir(arrayfun(@(x) x.name(1),etdir)~='.');
        etdir=etdir(arrayfun(@(x) x.name(end),etdir)=='t');
        etnames={etdir.name};
        
        % Determine SSVEP and Multi run indices
        MultiET=etnames(Multiidx)';
        SSVEPET=etnames(SSVEPidx)';

        Multicount=1;
        for j=1:size(runFiles,2)

            param=load(paramFile{j});

            % SSVEP
            if strcmp(type{j},'SSVEP')
                
                tmphits=sum(strcmp(param.performance.SSVEP(:,3),'Hit'));
                tmpmisses=sum(strcmp(param.performance.SSVEP(:,3),'Miss'));
                results.(sessionNum).SSVEP(end+1).hit=tmphits;
                results.(sessionNum).SSVEP(end).miss=tmpmisses;

                if ~isnan(tmphits/(tmphits+tmpmisses))
                    results.(sessionNum).SSVEP(end).acc=tmphits/(tmphits+tmpmisses);
                    tothitSSVEP=tothitSSVEP+tmphits; totmissSSVEP=totmissSSVEP+tmpmisses;
                end

            end

            % SMR 
            if strcmp(type{j},'SMR')
                
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

            % MULTITASKING
            if strcmp(type{j},'Multi')
                
                % SSVEP
                tmphits=sum(strcmp(param.performance.SSVEP(:,3),'Hit'));
                tmpmisses=sum(strcmp(param.performance.SSVEP(:,3),'Miss'));
                results.(sessionNum).mSSVEP(end+1).hit=tmphits;
                results.(sessionNum).mSSVEP(end).miss=tmpmisses;
                results.(sessionNum).mSSVEP(end).acc=tmphits/(tmphits+tmpmisses);
                tothitmSSVEP=tothitmSSVEP+tmphits; totmissmSSVEP=totmissmSSVEP+tmpmisses;

                % SMR
                tmphits=sum(strcmp(param.performance.SMR.results(:,3),'Hit'));
                tmpmisses=sum(strcmp(param.performance.SMR.results(:,3),'Miss'));
                results.(sessionNum).mTWOD(end+1).hit=tmphits;
                results.(sessionNum).mTWOD(end).miss=tmpmisses;
                results.(sessionNum).mTWOD(end).acc=tmphits/(tmphits+tmpmisses);
                tothitmTWOD=tothitmTWOD+tmphits; totmissmTWOD=totmissmTWOD+tmpmisses;

                matFile=strcat(ETdir,'\',MultiET{Multicount});
                trialOrder=str2double(param.performance.SSVEP(:,1));
                [targets]=ExtractMultiTargets(matFile,trialOrder);

                EEG=pop_loadBCI2000(strcat(datdir,'\',datFiles(Multicount).name),{'TargetCode','ResultCode','Feedback'});
                P=param.performance.SMR.results; P(1,:)=[];
                Event=EEG.event;
                Type={Event.type};
                Value={Event.position};
                Lat={Event.latency};
                R=find(strcmp(Type,'ResultCode')); Rlat=cell2mat(Lat(R));
                S=find(strcmp(Type,'Feedback')); Slat=cell2mat(Lat(S));
                T=find(strcmp(Type,'TargetCode')); Tlat=cell2mat(Lat(T));
                
                for k=1:size(P,1)
                    if strcmp(P(k,3),'Abort')
                        Rlat=[Rlat(1:k-1) Slat(k)+6*1024 Rlat(k:end)];
                    end
                end
                
                Dur=(Rlat-Slat)/1024;
                ssveptar=floor(Dur/1.5)
                
                        
                    
                
                
                
                
                
                
                % Performance of congruent vs. non-congruent targets
                % establish congruency links (SMR)
                % SMR/SSVEP: 1/1,2 2/3,4 3/2,4 4/1,3

                % Find which SSVEP trials are in which SMR trials

                Multicount=Multicount+1;
            end

        end

        %% Session PVC results
        results.(sessionNum).session.SSVEP=tothitSSVEP/(tothitSSVEP+totmissSSVEP);
        results.(sessionNum).session.LR=tothitLR/(tothitLR+totmissLR);
        results.(sessionNum).session.UD=tothitUD/(tothitUD+totmissUD);
        results.(sessionNum).session.TWOD=tothitTWOD/(tothitTWOD+totmissTWOD);
        results.(sessionNum).session.mSSVEP=tothitmSSVEP/(tothitmSSVEP+totmissmSSVEP);
        results.(sessionNum).session.mTWOD=tothitmTWOD/(tothitmTWOD+totmissmTWOD);

    end
    
    %save results
    resultsFile=[subjectFolder '\' 'results.mat']
    save(resultsFile,'results','-v7.3');
end


