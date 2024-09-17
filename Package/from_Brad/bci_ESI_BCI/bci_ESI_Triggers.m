function [triggers,varargout]=bci_ESI_Triggers(action,triggers,varargin)


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
        %% INITIATE CONTROL SIGNAL STRUCTURE
        
        if ~ismember('handles',str)
            error('Need handles to initiate trigger connection\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
         if ~ismember('signal',str)
            error('Need signal type to initiate trigger connection\n');
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
        
        if isempty(triggers)
            triggers=struct;
        end
        
        flags.sendtriggers=get(handles.sendtriggers,'value');
        v2struct(flags)
        
        % Establish eyetracker class
        if isequal(sendtriggers,1)
            
            triggers.et=EyeTracker('doRecord',true,'doAutostart',false);
        
            % Organize trigger labels based on task type and target number
            idx=struct;
            if ismember('SMR',signal)

                idx.SMR(1,:)={'Feedback' '1'};
                idx.SMR(2,:)={'TargetCode' '2'};
                idx.SMR(3,:)={'ResultCode' '3'};

                targets=horzcat(handles.BCI.SMR.param.targetid{:});
                for i=1:size(targets,2)
                    idx.SMR(3+i,:)={num2str(i) num2str(i+3)};
                end

            end

            if ismember('SSVEP',signal)

                targets=handles.BCI.SSVEP.control.targets;
                for i=1:size(targets,1)
                    idx.SSVEP(i,:)={num2str(i) num2str(i)};
                end

            end

            triggers.idx=idx;
            
            % Send trigger for start of run
            if triggers.et.isConnected()
                triggers.et.sendUserData(100);
            else
                fprintf(2,'\n100\n');
            end
        
        end
        varargout{1}=flags;
                
        
    elseif strcmp(action,'send')
        
        if ~ismember('flags',str)
            error('Need flags to send triggers\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        
        if ~ismember('signal',str)
            error('Need signal type to send triggers\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ~ismember('trial',str)
            error('Need event structure to send triggers\n');
        else
            trial=val{strcmp(str,'trial')};
        end
        
        switch signal

            case 'SMR'

                if isequal(sendtriggers,1)
                    
                    feedback=trial.SMR.feedback(trial.SMR.win+1);
                    feedbackprev=trial.SMR.feedback(trial.SMR.win);
                    baseline=trial.SMR.baseline(trial.SMR.win+1);
                    baselineprev=trial.SMR.baseline(trial.SMR.win);
                    target=trial.SMR.targetidx(trial.SMR.win+1);
                    targetprev=trial.SMR.targetidx(trial.SMR.win);

                    if ~isequal(target,0) && isequal(targetprev,0) &&...
                            isequal(feedback,0) && isequal(feedbackprev,0) &&...
                            isequal(baseline,1) && isequal(baselineprev,1) ||...
                            ~isequal(target,0) && isequal(targetprev,0) &&...
                            isequal(feedback,0) && isequal(feedbackprev,0) &&...
                            isequal(baseline,1) && isequal(baselineprev,0)

                        % First window of baseline - target pops up
                        targeton=str2double(strcat('1.',num2str(target),'5'));
                        if triggers.et.isConnected()
                            triggers.et.sendUserData(targeton)
                        else
                            fprintf(2,'\n%.2f\n',targeton);
                        end

                    elseif ~isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,1) && isequal(feedbackprev,0) &&...
                            isequal(baseline,0) && isequal(baselineprev,1)

                        % First window of cursor control - feedback starts
                        if triggers.et.isConnected()
                            triggers.et.sendUserData(1.91)
                        else
                            fprintf(2,'\n1.91\n');
                        end

                    elseif isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,0) && isequal(feedbackprev,1) &&...
                            isequal(baseline,1) && isequal(baselineprev,0) ||...
                            isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,0) && isequal(feedbackprev,1) &&...
                            isequal(baseline,0) && isequal(baselineprev,0)

                        % End of cursor control - feedback ends and target off
                        targetoff=str2double(strcat('1.',num2str(targetprev),'1'));
                        if triggers.et.isConnected()
                            triggers.et.sendUserData(1.90,targetoff,.001)
                        else
                            fprintf(2,'\n1.90\n');
                            fprintf(2,'\n%.2f\n',targetoff);
                        end

                    end
                    
                end
                
            case 'SSVEP'

                if ~ismember('ssvepidx',str)
                    error('Need ssvepidx structure to send SSVEP triggers\n');
                else
                    ssvepidx=val{strcmp(str,'ssvepidx')};
                end
                
                if isequal(sendtriggers,1)
                    
                    feedback=trial.SSVEP.feedback(trial.SSVEP.win+1);
                    feedbackprev=trial.SSVEP.feedback(trial.SSVEP.win);
                    baseline=trial.SSVEP.baseline(trial.SSVEP.win+1);
                    baselineprev=trial.SSVEP.baseline(trial.SSVEP.win);
                    target=trial.SSVEP.targetidx(trial.SSVEP.win+1);
                    targetprev=trial.SSVEP.targetidx(trial.SSVEP.win);
                    
                    if ~isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,1) && isequal(feedbackprev,0) &&...
                            isequal(baseline,0) && isequal(baselineprev,1) &&...
                            strcmp(ssvepidx.trial,'off') %%||...
    %                             ~isequal(target,0) && isequal(targetprev,0) &&...
    %                             isequal(feedback,0) && isequal(feedbackprev,0) &&...
    %                             isequal(baseline,1) && isequal(baselineprev,0) &&...
    %                             strcmp(ssvepidx.trial,'off')

                        % First window of baseline - target pops up
                        targettmp=taskorderssvep(ssvepidx.target);
                        targeton=str2double(strcat('2.',targettmp,'5'));
                        
                        if triggers.et.isConnected()
                            triggers.et.sendUserData(targeton)
                        else
                            fprintf(2,'\n%.2f\n',targeton);
                        end

                        ssvepidx.trial='on';
                        ssvepidx.targetprev=targettmp;

                    elseif ~isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,1) && isequal(feedbackprev,1) &&...
                            isequal(baseline,0) && isequal(baselineprev,0)

                        if strcmp(ssvepidx.trial,'off')

                            % First window of target - target pops up
                            % Previous target off
                            if isequal(ssvepidx.target,1)
                                targettmp1=taskorderssvep(ssvepidx.target);
                            else
                                targettmp1=ssvepidx.targetprev;
                            end
                            targetoff=str2double(strcat('2.',targettmp1,'1'));

                            % Current target on
                            targettmp2=taskorderssvep(ssvepidx.target);
                            targeton=str2double(strcat('2.',targettmp2,'5'));
                            
                            if triggers.et.isConnected()
                                triggers.et.sendUserData(targetoff,targeton,.001)
                            else
                                fprintf(2,'\n%.2f %.2f\n',targetoff,targeton);
                            end

                            ssvepidx.trial='on';
                            ssvepidx.targetprev=targettmp2;
                        end

                    elseif isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,0) && isequal(feedbackprev,1) &&...
                            isequal(baseline,1) && isequal(baselineprev,0) &&...
                            strcmp(ssvepidx.trial,'on') ||...
                            isequal(target,0) && ~isequal(targetprev,0) &&...
                            isequal(feedback,0) && isequal(feedbackprev,1) &&...
                            isequal(baseline,0) && isequal(baselineprev,0) &&...
                            strcmp(ssvepidx.trial,'on')

                        % Current target on
                        targettmp=taskorderssvep(ssvepidx.target);
                        targetoff=str2double(strcat('2.',targettmp,'1'));
                        
                        if triggers.et.isConnected()
                            triggers.et.sendUserData(targetoff)
                        else
                            fprintf(2,'\n%.2f\n',targetoff);
                        end
                        ssvepidx.trial='off';

                    end
                    
                end
                
                varargout{1}=ssvepidx;
        end       
        
    elseif strcmp(action,'end')
        
        if ~ismember('flags',str)
            error('Need flags to send triggers\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        
        if isequal(sendtriggers,1)
        
            % Send trigger for end of run
            if triggers.et.isConnected()
                triggers.et.sendUserData(200);
            else
                fprintf(2,'\n200\n');
            end

            % close TCP/IP connection for eyetracker
            triggers.et.close();
            
        end
        
    end
    
end
        
        
        
        
        
        