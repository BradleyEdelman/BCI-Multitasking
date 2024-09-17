function event=bci_ESI_BCIEvent(event,handles)

if size(event.BCI2Event,2)>1 && ~isempty(cell2mat(event.eventlatency))
    
    % BCI2000 only stores up to 100 previous events - find
    % all new events in buffer
    samp=cell2mat({event.BCI2Event.sample});
    numtmp=find(samp>=max(cell2mat(event.eventlatency)));

    % Only search through new events
    if isempty(numtmp)
        event.numevent(1)=size(event.BCI2Event,2);
    else
        event.numevent(1)=numtmp(1);
    end
    event.numevent(2)=size(event.BCI2Event,2);
    for i=event.numevent(1):event.numevent(2)

        tmptype=event.BCI2Event(i).type;
        tmplatency=event.BCI2Event(i).sample;
        tmpvalue=event.BCI2Event(i).value;
        
        switch tmptype

            case 'Signal'
                
            case 'TargetCode' % Discrete Trial

                if strcmp(event.eventtype{end},'Feedback') && isequal(event.eventvalue{end},0)

                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetval=tmpvalue;
                    event.targetstatus='off';

                elseif strcmp(event.eventtype{end},'TargetCode') && isequal(event.eventvalue{end},0)...
                        && ~isequal(tmpvalue,0)

                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='on';
                    event.targetval=tmpvalue;
                    event.target=event.targetval;
                    if ~isequal(event.targetval,0)
                        if ismember(event.targetval,[1 2])
                            event.stimulusword=event.targetwords{1}{1}{event.targetval};
                        elseif ismember(event.targetval,[3 4])
                            event.stimulusword=event.targetwords{1}{2}{event.targetval-2};
                        end
                    else
                        event.stimulusword='';
                    end
                    event.basestart=tmplatency;
                    event.baselineval=1;
                    
                elseif strcmp(event.eventtype{end},'ResultCode')
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetval=tmpvalue;

                elseif strcmp(event.eventtype{end},'Signal')

                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='on';
                    event.targetval=tmpvalue;
                    event.target=event.targetval;
                    if ~isequal(event.targetval,0)
                        if ismember(event.targetval,[1 2])
                            event.stimulusword=event.targetwords{1}{1}{event.targetval};
                        elseif ismember(event.targetval,[3 4])
                            event.stimulusword=event.targetwords{1}{2}{event.targetval-2};
                        end
                    else
                        event.stimulusword='';
                    end
                    event.basestart=tmplatency;
                    event.baselineval=1;
                
                elseif isequal(size(event.eventtype,2),1) && isempty(event.eventtype{1})
                    
                    event.eventtype{1}=tmptype;
                    event.eventlatency{1}=tmplatency;
                    event.eventvalue{1}=tmpvalue;
                    event.targetstatus='on';
                    event.targetval=tmpvalue;
                    event.target=event.targetval;
                    if ~isequal(event.targetval,0)
                        if ismember(event.targetval,[1 2])
                            event.stimulusword=event.targetwords{1}{1}{event.targetval};
                        elseif ismember(event.targetval,[3 4])
                            event.stimulusword=event.targetwords{1}{2}{event.targetval-2};
                        end
                    else
                        event.stimulusword='';
                    end
                    event.basestart=tmplatency;
                    event.baselineval=1;
                    event.eventvalue{1}=tmpvalue;

                end
                
            case 'ResultCode' % Discrete Trial
                    
                if strcmp(event.eventtype{end},'Feedback')&& ~isequal(tmpvalue,0)

                    event.cursorinfo.delay=5;
                    event.cursorinfo.resultidx=tmpvalue;
                    event.cursorinfo.targetidx=event.target;
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.feedbackval=0;
                    event.baselineval=1;

                end
                    
            case 'StimulusCode' % Stim Pres
                
                if strcmp(event.eventtype{end},'PhaseInSequence') ||...
                        strcmp(event.eventtype{end},'Signal') ||...
                        strcmp(event.eventtype{end},'StimulusCode') &&...
                        ~isequal(tmpvalue,0)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=tmpvalue;
                    event.target=tmpvalue;
                    event.baseend=tmplatency;
                    
                elseif strcmp(event.eventtype{end},'StimulusBegin') && isequal(tmpvalue,0)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=0;
                    event.target=0;
                    event.trialend=tmplatency;
                    event.basestart=tmplatency;
                    
                end
                
            case 'StimulusBegin' % Stim Pres

                if strcmp(event.eventtype{end},'StimulusCode') && isequal(tmpvalue,0)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.feedbackval=1;
                    event.baselineval=0;
                    event.trialstart=tmplatency;
                    
                end

            case 'Feedback' 
                
                % Discrete Trial
                if strcmp(event.eventtype{end},'TargetCode') &&...
                        ~isequal(event.eventvalue{end},0) && isequal(tmpvalue,1)

                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.feedbackval=1;
                    event.baseend=tmplatency-1;
                    event.baselineval=0;
                
                % Discrete Trial
                elseif strcmp(event.eventtype{end},'TargetCode') &&...
                        ~isequal(event.eventvalue{end},0) && isequal(tmpvalue,0)

                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.feedbackval=0;
                    event.baselineval=0;

                % Discrete Trial
                elseif strcmp(event.eventtype{end},'CursorPosX') ||...
                        strcmp(event.eventtype{end},'CursorPosY')

                    event.trialend=tmplatency-1;
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.stimulusword=[];
                    event.feedbackval=0;
                    event.targetval=0;
                
                % Discrete Trial
                elseif strcmp(event.eventtype{end},'Feedback') &&...
                        isequal(tmpvalue,0) && isequal(event.eventvalue{end},1) &&...
                        ~ismember('StartCueOn',event.eventtype) &&...
                        ~ismember('StopCueOn',event.eventtype) &&...
                        ~ismember('BaselineOn',event.eventtype) &&...
                        ~ismember('PreRunOn',event.eventtype)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.stimulusword=[];
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=0;

                % Continuous
                elseif strcmp(event.eventtype{end},'StartCueOn') &&...
                        isequal(tmpvalue,1)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='on';
                    event.stimulusword='GO';
                    event.feedbackval=1;
                    event.baselineval=0;
                    event.targetval=0;
                
                % Continuous
                elseif ~strcmp(event.eventtype{end},'Feedback') &&...
                        isequal(tmpvalue,1)
                    
                    if ismember('StartCueOn',event.eventtype) ||...
                            ismember('StopCueOn',event.eventtype) ||...
                            ismember('BaselineOn',event.eventtype) ||...
                            ismember('PreRunOn',event.eventtype)
                    
                        event.eventtype{end+1}=tmptype;
                        event.eventlatency{end+1}=tmplatency;
                        event.eventvalue{end+1}=tmpvalue;
                        event.targetstatus='on';
                        event.stimulusword=[];
                        event.feedbackval=1;
                        event.baselineval=0;
                        event.targetval=0;
                        
                    end
                    
                elseif strcmp(event.eventtype{end},'Feedback') &&...
                        isequal(tmpvalue,0)
                    
                    if ismember('StartCueOn',event.eventtype) ||...
                            ismember('StopCueOn',event.eventtype) ||...
                            ismember('BaselineOn',event.eventtype) ||...
                            ismember('PreRunOn',event.eventtype)
                    
                        event.eventtype{end+1}=tmptype;
                        event.eventlatency{end+1}=tmplatency;
                        event.eventvalue{end+1}=tmpvalue;
                        event.targetstatus='off';
                        event.stimulusword=[];
                        event.feedbackval=0;
                        event.baselineval=1;
                        event.targetval=0;
                        
                    end
                
                end
                
            case 'PreRunOn' % Continuous
                
                if strcmp(event.eventtype{end},'AppStartTime')
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.stimulusword=[];
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=0;
                    
                end
                
            case 'BaselineOn' % Continuous
                
                if strcmp(event.eventtype{end},'PreRunOn') ||...
                        strcmp(event.eventtype{end},'StopCueOn') ||...
                        strcmp(event.eventtype{end},'BaselineOn') &&...
                        isequal(event.eventvalue{end},1) && isequal(tmpvalue,0)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='off';
                    event.stimulusword=[];
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=0;
                    
                end
                
            case 'StartCueOn' % Continuous
                
                if strcmp(event.eventtype{end},'BaselineOn') &&...
                        isequal(event.eventvalue{end},0)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='on';
                    event.stimulusword='Prepare';
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=0;
                    
                end
                
            case 'StopCueOn' % Continuous
                
                if strcmp(event.eventtype{end},'Feedback') &&...
                        isequal(event.eventvalue{end},0)
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    event.targetstatus='on';
                    event.stimulusword='Stop';
                    event.feedbackval=0;
                    event.baselineval=1;
                    event.targetval=0;
                    
                end
                
            case {'Target_PosX_u','Target_PosY_u'} % Continuous
                
                dimused=event.dimused;
                
                recenteventtype={event.BCI2Event(i:end).type};
                recenteventvalue={event.BCI2Event(i:end).value};

%                 event.cursorpos.current=nan(1,2);
                event.targetpos.current=event.targetpos.orig;
                for j=1:size(recenteventtype,2)
                    if strcmp(recenteventtype{j},'Target_PosX_u')
                        
                        % Check if original X position defined yet
                        if isequal(event.targetpos.orig(1),-1)
                            event.targetpos.orig(1)=cell2mat(recenteventvalue(j));
                        end
                        event.targetpos.current(1)=cell2mat(recenteventvalue(j));
                        
                    elseif strcmp(recenteventtype{j},'Target_PosY_u')
                        
                        % Check if original Y position defined yet
                        if isequal(event.targetpos.orig(2),-1)
                            event.targetpos.orig(2)=cell2mat(recenteventvalue(j));
                        end
                        event.targetpos.current(2)=cell2mat(recenteventvalue(j));
                        
                    elseif strcmp(recenteventtype{j},'Cursor_PosX_u')
                        event.cursorpos.current(1)=cell2mat(recenteventvalue(j));
                    elseif strcmp(recenteventtype(j),'Cursor_PosY_u')
                        event.cursorpos.current(2)=cell2mat(recenteventvalue(j));
                    end
                end
                
                % Fill in "other" original target position if absent
                if ismember(-1,event.targetpos.orig)
                    for j=1:2
                        tmptargetpos=circshift(event.targetpos.orig,[0,j-1]);
                        if isequal(tmptargetpos(1),-1) && ~isequal(tmptargetpos(2),-1)
                            tmptargetpos(1)=tmptargetpos(2);
                        end
                        event.targetpos.orig=tmptargetpos;
                    end
                end
                
                % Fill in original cursor position if absent
                if isequal(event.cursorpos.orig,zeros(1,2)) &&...
                        ~isequal(event.targetpos.orig,zeros(1,2))
                    event.cursorpos.orig=event.targetpos.orig;
                end
                
                posdiff=zeros(1,2);
                for j=1:2

                    % If no current cursor position
                    if isequal(event.cursorpos.current(j),-1)
                        % If dim not in use, assign to target position
                        if ~ismember(j,dimused)
                            event.cursorpos.current(j)=event.targetpos.current(j);
                        % If previous position exist, assign to it
                        elseif ~isequal(event.cursorpos.win(end,j),-1)
                            event.cursorpos.current(j)=event.cursorpos.win(end,j);
                        % If dim in use, but not previous cursor pos, assign to target position
                        elseif ~isequal(event.targetpos.current(j),-1)
                            event.cursorpos.current(j)=event.targetpos.current(j);
                        end
                    end
                    
                    if isequal(event.targetpos.current(j),-1)
                        event.targetpos.current(j)=event.targetpos.orig(j);
                    end

                    posdiff(j)=event.cursorpos.current(j)-event.targetpos.current(j);
                    
                end

                absposdiff=abs(posdiff);
                maxdim=find(absposdiff==max(absposdiff)); maxdim=maxdim(1);
                if isequal(maxdim,1) && isequal(dimused,1)
                    if posdiff(1)>0
                        event.target=1;
                    elseif posdiff(1)<0
                        event.target=2;
                    end
                elseif isequal(maxdim,2)
                    if isequal(dimused,2)
                        if posdiff(2)>0
                            event.target=1;
                        elseif posdiff(2)<0
                            event.target=2;
                        end
                    elseif isequal(dimused,[1 2])
                        if posdiff(2)>0
                            event.target=3;
                        elseif posdiff(2)<0
                            event.target=4;
                        end
                    end
                elseif isequal(maxdim,3)
                    event.target=0;
                end
                event.targetval=event.target;
                
            case {'CursorPosX','CursorPosY'} % Discrete Trial
                
                if ~isempty(handles.Stimulus.Cursor.cursorpos) &&...
                        ~isempty(handles.Stimulus.Cursor.cursorsize) &&...
                        ~isempty(handles.Stimulus.Cursor.cursoroffset)
                    
                    if strcmp(tmptype,'CursorPosX') % 0 = left
                        event.cursorpos.current(1)=tmpvalue;
                        event.cursorpos.stimcurrent(1)=(tmpvalue/4095)*handles.Stimulus.Cursor.cursorsize+handles.Stimulus.Cursor.cursoroffset(1);
                    elseif strcmp(tmptype,'CursorPosY') % 0 = top
                        event.cursorpos.current(2)=tmpvalue;
                        event.cursorpos.stimcurrent(2)=(tmpvalue/4095)*handles.Stimulus.Cursor.cursorsize+handles.Stimulus.Cursor.cursoroffset(2);
                    end
                    
                else
                    
                    if strcmp(tmptype,'CursorPosX') % 0 = left
                        event.cursorpos.current(1)=tmpvalue;
                    elseif strcmp(tmptype,'CursorPosY') % 0 = top
                        event.cursorpos.current(2)=tmpvalue;
                    end
                    
                end
                
                if strcmp(event.eventtype{end},'Feedback') && isequal(event.eventvalue{end},1)

                    event.trialstart=tmplatency;
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;
                    
                    % If a "feedback - on" event is skipped
                elseif strcmp(event.eventtype{end},'TargetCode') && ~isequal(event.eventvalue{end},0)
                    
                    event.trialstart=tmplatency;
                    
                    event.eventtype{end+1}='Feedback';
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=1;
                    
                    event.eventtype{end+1}=tmptype;
                    event.eventlatency{end+1}=tmplatency;
                    event.eventvalue{end+1}=tmpvalue;

                end
                
        end
    end
    event.numevent(1)=event.numevent(2);

elseif size(event.BCI2Event,2)>1 && isempty(cell2mat(event.eventlatency))
    
    event.numevent(1)=1;
    event.numevent(2)=1;
    tmptype=event.BCI2Event(1).type;
    tmplatency=event.BCI2Event(1).sample;
    tmpvalue=event.BCI2Event(1).value;
    
    event.eventtype{1}=tmptype;
    event.eventlatency{1}=tmplatency;
    event.eventvalue{1}=tmpvalue;
    if ismember(event.eventtype{1},['PhaseInSequence','AppStartTime'])
        event.baselineval=1;
    end
    
elseif isequal(size(event.BCI2Event,2),1)

    event.numevent(1)=1;
    event.numevent(2)=1;
    tmptype=event.BCI2Event(1).type;
    tmplatency=event.BCI2Event(1).sample;
    tmpvalue=event.BCI2Event(1).value;

    event.eventtype{1}=tmptype;
    event.eventlatency{1}=tmplatency;
    event.eventvalue{1}=tmpvalue;
    if strcmp(event.eventtype{1},'TargetCode')
        event.targetstatus='on';
        event.targetval=tmpvalue;
        event.target=tmpvalue;
%         event.stimulusword=event.targetwords{event.targetval};
        event.basestart=tmplatency;
        event.baselineval=1;
    elseif strcmp(event.eventtype{1},'PhaseInSequence')
        event.baselineval=0;
    elseif strcmp(event.eventtype{1},'AppStartTime')
        event.baselineval=1;
    end

end






