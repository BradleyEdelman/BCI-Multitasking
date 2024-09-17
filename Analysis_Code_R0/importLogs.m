
datadir='M:\_bci_Multitasking\_Multi_Data\';
Subj={'BE' 'DS' 'HL' 'JM' 'NG' 'NG2' 'NJ' 'PS' 'TS'};

for i=1:size(Subj,2)
    
    subjdir=strcat(datadir,Subj{i});
    subjsession=dir(subjdir)
    subjsession=subjsession(arrayfun(@(x) x.name(1),subjsession)~='.');
    
    for j=1:size(subjsession,1)
        
        sessiondir=strcat(subjdir,'\',subjsession(j).name);
        sessionfolders=dir(sessiondir);
        sessionfolders=sessionfolders(arrayfun(@(x) x.name(1),sessionfolders)~='.');
        sessionfoldernames={sessionfolders.name};
        
        for k=1:size(sessionfoldernames,2)
            if ~isempty(strfind(sessionfoldernames{k},'ET'))
                ETdir=strcat(sessiondir,'\',sessionfoldernames{k});
                break
            end
        end

        logdir=dir(ETdir);
        logdir=logdir(arrayfun(@(x) x.name(1),logdir)~='.');
        logdir=logdir(arrayfun(@(x) x.name(end),logdir)=='d');
        logdir=logdir(arrayfun(@(x) x.name(end-1),logdir)~='a');
        
        logNames={logdir.name};

        for k=1:size(logNames,2)

            fileName = logNames{k}(1:end-4);
            logFile = [ETdir '\' fileName '.etd'];

            if strcmp(logFile(end-3:end),'.etd')
                matFile = [logFile(1:end-4) '.mat'];
            else
                matFile = [logFile '.mat'];
                logFile = [logFile '.etd'];
            end
            matFile
            %% Import data 
            if ~exist(matFile,'file') %% convert the raw log file to a .mat if it hasn't already been done
                tic
                d = EyeTracker.convertLogToMat(logFile,matFile); %% this is (unfortunately) slow
                toc
                matSave = [ETdir '\' fileName '.mat'];
                save(matSave,'d','-v7.3');
            else
                load(matFile); % this is much faster, so ideal to store most data in this format
            end
        end
    end
end