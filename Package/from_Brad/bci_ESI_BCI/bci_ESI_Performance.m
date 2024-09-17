function [performance,varargout]=bci_ESI_Performance(action,performance,varargin)

nargs=nargin;
if nargs<2
else
    
    %% EXTRACT INPUT ARGS
    if ~(round((nargs-2)/2) == (nargs-2)/2)
        error('Odd number of input arguments??')
    end
    
    str=cell(0); val=cell(0);
    for i=1:2:length(varargin)
        str{end+1}=varargin{i};
        val{end+1}=varargin{i+1};
    end
    
    if strcmp(action,'initiate')
        %% INITIATE PERFORMANCE STRUCTURES
        if ~ismember('handles',str)
            error('Need handles to create EEG structure\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if ~ismember('signal',str)
            error('Need signal type to create EEG structure\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
            if isempty(flags)
                flags=struct;
            else
                v2struct(flags)
            end
        else
            flags=struct;
        end
        
        if isempty(performance)
            performance=struct;
        end
        
        if ismember('SMR',signal) || strcmp('SMR',signal)
            
            performance.SMR.targets=[];
            performance.SMR.results=[];
            
        end
        
        if ismember('SSVEP',signal) || strcmp('SSVEP',signal)
            flags.targetsssvep=handles.BCI.SSVEP.control.targets;
            flags.targetfreqssvep=handles.BCI.SSVEP.control.targetfreq;
            flags.taskorderssvep=handles.BCI.SSVEP.control.taskorder;
            flags.imagessvep=handles.BCI.SSVEP.control.image;
            performance.SSVEP=[];
            
        end
        
        varargout{1}=flags;
        
    elseif strcmp(action,'update')
        
        if ~ismember('signal',str)
            error('Need signal type to create EEG structure\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ~ismember('flags',str)
            error('Need signal type to create EEG structure\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        
        
        if strcmp('SSVEP',signal)
            
            if ~ismember('trialidx',str)
                error('Need ssvep idx structure to record performance\n');
            else
                trialidx=val{strcmp(str,'trialidx')};
            end
            
            if ~ismember('winner',str)
                error('Need to declare winner to record performance\n');
            else
                winner=double(val{strcmp(str,'winner')});
            end
            
            % Record result and adjust stimulus
            performance.SSVEP{trialidx.result,1}=taskorderssvep{trialidx.target};

            if ~isequal(winner,0)
                performance.SSVEP{trialidx.result,2}=targetsssvep{winner};
            else
                performance.SSVEP{trialidx.result,2}='0';
            end

            if strcmp(performance.SSVEP{trialidx.result,2},'0')
                
                performance.SSVEP{trialidx.result,3}='Abort';
                trialidx.result=trialidx.result+1;
                % If three non-hits in a row, change stimulus
                if size(performance.SSVEP,1)>=3
                    prevres={performance.SSVEP{end-2:end,3}}';
                    prevtar=str2double({performance.SSVEP{end-2:end,1}}');
                    if isequal(sum(strcmp(prevres,'Miss'))+sum(strcmp(prevres,'Abort')),3) &&...
                            isequal(range(prevtar),0)
                        trialidx.target=trialidx.target+1;
                    end
                end
                
            elseif strcmp(taskorderssvep{trialidx.target},targetsssvep{winner})
                
                performance.SSVEP{trialidx.result,3}='Hit';
                trialidx.target=trialidx.target+1;
                trialidx.result=trialidx.result+1;
                
            else
                
                performance.SSVEP{trialidx.result,3}='Miss';
                trialidx.result=trialidx.result+1;
                % If three non-hits in a row, change stimulus
                if size(performance.SSVEP,1)>=3
                    prevres={performance.SSVEP{end-2:end,3}}';
                    prevtar=str2double({performance.SSVEP{end-2:end,1}}');
                    if isequal(sum(strcmp(prevres,'Miss'))+sum(strcmp(prevres,'Abort')),3) &&...
                            isequal(range(prevtar),0)
                        trialidx.target=trialidx.target+1;
                    end
                end
                
            end
            
            stimidx=taskorderssvep{trialidx.target};
            stimidx=find(strcmp(targetsssvep,stimidx));

            stimtmp=imagessvep{stimidx};
            
            varargout{1}=trialidx;
            varargout{2}=stimtmp;
            
        elseif strcmp('SMR',signal)
            
            if ~ismember('event',str)
                error('Need event structure record performance\n');
            else
                event=val{strcmp(str,'event')};
            end
            
            if ~ismember('trial',str)
                error('Need trial structure record performance\n');
            else
                trial=val{strcmp(str,'trial')};
            end
            
            % RECORD SMR PERFORMANCE
            if ~isequal(paradigm,4)
                eventtypetmp=event.eventtype;
                TCidx=find(strcmp(eventtypetmp,'TargetCode'));
                RCidx=find(strcmp(eventtypetmp,'ResultCode'));

                currentTC=max(TCidx);
                performance.SMR.results{trial.SMR.tottrial,1}=num2str(event.eventvalue{currentTC});
                currentRC=max(RCidx);
                if isempty(currentRC) || currentRC<currentTC
                    performance.SMR.results(trial.SMR.tottrial,2)={'0'};
                    performance.SMR.results(trial.SMR.tottrial,3)={'Abort'};
                else
                    performance.SMR.results(trial.SMR.tottrial,2)={num2str(event.eventvalue{currentRC})};

                    if strcmp(performance.SMR.results(trial.SMR.tottrial,1),performance.SMR.results(trial.SMR.tottrial,2))
                        performance.SMR.results(trial.SMR.tottrial,3)={'Hit'};
                    else
                        performance.SMR.results(trial.SMR.tottrial,3)={'Miss'};
                    end

                end

            end
            
        end
     
        
    elseif strcmp(action,'display')
        
        if ~ismember('signal',str)
            error('Need signal type to create EEG structure\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ~ismember('flags',str)
            error('Need signal type to create EEG structure\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        
        
        if ismember('SSVEP',signal) || strcmp('SSVEP',signal)
        
            performance.SSVEP
            P=performance.SSVEP;
            if ~isempty(P)
                H=sum(strcmp(P(:,3),'Hit'));
                M=sum(strcmp(P(:,3),'Miss'));
                Acc=H/(H+M)*100;
                fprintf(2,'\nSSVEP accuracy %.2f%%\n',Acc);
            end
            
        end
        
        if ismember('SMR',signal) || strcmp('SMR',signal)
            
            performance.SMR.results
            P=performance.SMR.results;
            if ~isempty(P)
                H=sum(strcmp(P(:,3),'Hit'));
                M=sum(strcmp(P(:,3),'Miss'));
                Acc=H/(H+M)*100;
                fprintf(2,'\nSMR accuracy %.2f%%\n',Acc);
            end
            
        end
        
    end
end
        
        
        
        
        
        











