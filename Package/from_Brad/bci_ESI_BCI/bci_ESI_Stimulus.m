function [stimulus,varargout]=bci_ESI_Stimulus(action,stimulus,varargin)


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
        %% INITIATE STIMULI
        if ~ismember('handles',str)
            error('Need handles to designate stimuli\n');
        else
            handles=val{strcmp(str,'handles')};
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
        
        if isempty(stimulus)
            stimulus=struct;
        end
        flags.paradigm=get(handles.paradigm,'value');
        v2struct(flags)

        if ismember(paradigm,4:8)
            
            % Double check existence of stimulus figure
            if size(findobj('type','figure'),1)<2
                set(handles.SetBCI,'userdata',0)
                error('NO STIMULUS FIGURE CURRENTLY OPEN');
            end
            
            % Make sure handle is current and definde for hand/details
            if ismember(paradigm,4)
                
                stimulus.general.fig=handles.Stimulus.general.fig;
                stimulus.Hand.righthandplot=handles.Stimulus.Hand.righthandplot;
                stimulus.Hand.righthand.vertices=handles.Stimulus.Hand.righthand.vertices;
                stimulus.Hand.righthandoffset=handles.Stimulus.Hand.righthandoffset;
                
                figure(stimulus.general.fig);
                set(stimulus.Hand.righthandplot,'vertices',...
                    stimulus.Hand.righthand.vertices,'facecolor',[255 224 196]/255)
                
                stimulus.general.text=handles.Stimulus.general.text;
                stimulus.general.go=handles.Stimulus.general.go;
                
            elseif isequal(paradigm,5)
                
                stimulus.general.fig=handles.Stimulus.general.fig;
                stimulus.Hand.righthandplot=handles.Stimulus.Hand.righthandplot;
                stimulus.Hand.righthand.vertices=handles.Stimulus.Hand.righthand.vertices;
                stimulus.Hand.righthandoffset=handles.Stimulus.Hand.righthandoffset;
                
                figure(stimulus.general.fig);
                set(stimulus.Hand.righthandplot,'vertices',...
                    stimulus.Hand.righthand.vertices,'facecolor',[255 224 196]/255)
                % TARGET HAND???????
                
                stimulus.general.text=handles.Stimulus.general.text;
                stimulus.general.go=handles.Stimulus.general.go;

            elseif ismember(paradigm,6:8)

                stimulus.general.text=handles.Stimulus.general.text;
                set(stimulus.general.text,'string','');
                
                if ismember(paradigm,[6,7])
                    flags.paradigm=get(handles.paradigm,'value');
                    flags.imagessvep=handles.BCI.SSVEP.control.image;
                    stimulus.SSVEP.image=handles.Stimulus.SSVEP.image;
                end
                
                if ismember(paradigm,[6 8])
                    stimulus.Cursor.cursorpos=handles.Stimulus.Cursor.cursorpos;
                    set(stimulus.Cursor.cursorpos,'cdata',[0 0 0]);
                    
                    stimulus.Cursor.target=handles.Stimulus.Cursor.target;
                    for i=1:size(stimulus.Cursor.target,2)
                        set(stimulus.Cursor.target(i),'facecolor',[0 0 0],'edgecolor',[0 0 0]);
                    end
                end
                
            end

        end
        
        varargout{1}=flags;
        
    elseif strcmp(action,'update')
        
        if ~ismember('flags',str)
            error('Need flags to update stimulus\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        
        if ismember('signal',str)
            signal=val{strcmp(str,'signal')};
        else
            error('Need signal type to update stimulus\n');
        end
        
        if strcmp(signal,'SMR')
            
            if ismember('event',str)
                event=val{strcmp(str,'event')};
            else
                error('Need event structure to update stimulus\n');
            end

            if isequal(paradigm,4)
                %% Discrete or continuous hand manipulation

                if ismember('trial',str)
                    trial=val{strcmp(str,'trial')};
                else
                    error('Need trial structure to update stimulus\n');
                end

                if ismember('control',str)
                    control=val{strcmp(str,'control')};
                else
                    error('Need control structure to update stimulus\n');
                end

                if ismember('flags',str)
                    flags=val{strcmp(str,'flags')};
                else
                    error('Need flags to update stimulus\n');
                end

                if strcmp({event.targetstatus},'on')
                    set(stimulus.general.text,'string',event.stimulusword)
                else
                    set(stimulus.general.text,'string','')
                    set(stimulus.general.go,'string','')
                end

                if isequal(trial.SMR.feedback(trial.SMR.win+1),1)

                    set(stimulus.general.go,'string','GO')
                    [hplot,event]=bci_ESI_HandMovement(stimulus,flags,event,control.stim,'righthand');
                    set(stimulus.Hand.righthandplot,'vertices',hplot.vertices,'facecolor',[255 224 196]/255)

                elseif ~isequal(event.cursorinfo.delay,0) && ~isempty(event.cursorinfo.delay)

                    if ismember(event.cursorinfo.targetidx,event.cursorinfo.resultidx)
                        C='green';
                    else
                        C='red';
                    end

                    [hplot,event]=bci_ESI_HandMovement(stimulus,flags,event,control.stim,'righthand');
                    if ~isequal(stimulus.Hand.righthandplot.Vertices,hplot.vertices)
                        set(stimulus.Hand.righthandplot,'vertices',hplot.vertices,'facecolor',C)
                    end
                    event.cursorinfo.delay=event.cursorinfo.delay-1;

                else

                    if ~isequal(stimulus.Hand.righthandplot.Vertices,stimulus.Hand.righthand.vertices)
                        set(stimulus.Hand.righthandplot,'vertices',stimulus.Hand.righthand.vertices,'facecolor',[255 224 196]/255)
                    end

                    event.cursorpos.current=event.cursorpos.orig;

                end

            elseif isequal(paradigm,5)
                %% Continuous Hand Manipulation

    % %             if isequal(trial.SMR.feedback(trial.SMR.win+1),1) 
    % %                     
    % %                 if exist('ht','var'); delete(ht); clear ht; end
    % %                 [htplot,runparam.event,control.stim]=bci_ESI_HandMovement(handles,event,control.stim,'righthandtarget');
    % %                 ht=patch(htplot,'facecolor',[255 224 196]/255,...
    % %                     'edgecolor','none','facelighting','gouraud','ambientstrength',0.15);
    % %             end
    % %             
    % %             if exist('h','var'); stimulus.h=h; end
    % %             if exist('ht','var'); stimulus.ht=ht; end

            elseif ismember(paradigm,[6 8])
                %% Discrete Cursor +/- SSVEP

                if ismember('trial',str)
                    trial=val{strcmp(str,'trial')};
                else
                    error('Need trial structure to update stimulus\n');
                end

                if ismember('event',str)
                    event=val{strcmp(str,'event')};
                else
                    error('Need event structure to update stimulus\n');
                end

                % Target
                if ~isequal(trial.SMR.targetidx(trial.SMR.win+1),0)

                    set(stimulus.Cursor.target(event.target),'facecolor',[1 1 0],'edgecolor',[1 1 0]);

                elseif ~isequal(event.cursorinfo.delay,0) && ~isempty(event.cursorinfo.delay)

                    set(stimulus.Cursor.target(event.cursorinfo.targetidx),...
                        'facecolor',[1 1 0],'edgecolor',[1 1 0]);

                else

                    for i=1:size(stimulus.Cursor.target,2)
                        set(stimulus.Cursor.target(i),'facecolor',[0 0 0],'edgecolor',[0 0 0]);
                    end

                end

                % Cursor
                if isequal(trial.SMR.feedback(trial.SMR.win+1),1)

                    set(stimulus.Cursor.cursorpos,'xdata',event.cursorpos.stimcurrent(1),...
                        'ydata',event.cursorpos.stimcurrent(2),'cdata',[1 .5 .5]);

                elseif ~isequal(event.cursorinfo.delay,0) && ~isempty(event.cursorinfo.delay)

                    if ismember(event.cursorinfo.targetidx,event.cursorinfo.resultidx)
                        C=[1 1 0];
                    else
                        C=[1 .5 .5];
                    end
                    set(stimulus.Cursor.cursorpos,'xdata',event.cursorpos.stimcurrent(1),...
                        'ydata',event.cursorpos.stimcurrent(2),'cdata',C);
                    event.cursorinfo.delay=event.cursorinfo.delay-1;

                else

                    set(stimulus.Cursor.cursorpos,'xdata',event.cursorpos.orig(1),...
                        'ydata',event.cursorpos.orig(2),'cdata',[0 0 0]);
                    event.cursorpos.stimcurrent=event.cursorpos.orig;

                end

            end
            varargout{1}=event;
            
        elseif strcmp(signal,'SSVEP')
            
            if ismember(paradigm,6:7)
                
                if ismember('trial',str)
                    trial=val{strcmp(str,'trial')};
                else
                    error('Need trial structure to update stimulus\n');
                end
                
                if ismember('image',str)
                    image=val{strcmp(str,'image')};
                else
                    error('Need image to update stimulus\n');
                end
                
                if isequal(trial.SSVEP.feedback(trial.SSVEP.win+1),1)
                    set(stimulus.SSVEP.image,'cdata',image)
                else
                    set(stimulus.SSVEP.image,'cdata',imagessvep{end})
                end
                
            end
            varargout{1}=image;
            
        end
        
    elseif strcmp(action,'reset')
        %% Reset
        
        if ismember('handles',str)
            handles=val{strcmp(str,'handles')};
        else
            error('Need handles to reset stimulus\n');
        end
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
        else
            error('Need flags to reset stimulus\n');
        end
        v2struct(flags)
        
        if ismember(paradigm,4:5)
            
%             if ismember('control',str)
%                 control=val{strcmp(str,'control')};
%             else
%                 error('Need control structure to reset stimulus\n');
%             end
            
            set(stimulus.Hand.righthandplot,'vertices',...
                stimulus.Hand.righthand.vertices,'facecolor',[255 224 196]/255)
            
            if isequal(paradigm,5)
                
                set(stimulus.Hand.righthandplot,'vertices',...
                    stimulus.Hand.righthandtarget.vertices,'facecolor',[255 224 196]/255)
                
            end

%             control.stim=zeros(3,1);
            set(stimulus.general.go,'string','')
            set(stimulus.general.text,'string','Waiting to start...')
            
        elseif ismember(paradigm,6:8)
            
            if ismember(paradigm,[6 8])
                
                set(stimulus.Cursor.cursorpos,'cdata',[.15 .15 .15]);
                for i=1:size(stimulus.Cursor.target,2)
                    set(stimulus.Cursor.target(i),'facecolor',[.15 .15 .15],'edgecolor',[.15 .15 .15]);
                end
                
            end
            
            if ismember(paradigm,[6 7])
                
                set(stimulus.SSVEP.image,'cdata',imagessvep{end})
                
                numtrial=180; % divisible by 2,3,4
                taskorder=[];
                targets=handles.SSVEP.target; targets(strcmp(targets,''))=[];
                
                % Reset task order for SSVEPS
                % No repeated stimuli (since will change stimuli will indicate a hit)
                numtask=size(targets,1);
                idx=randi(numtask,1);
                taskorder=[taskorder;targets(idx)];
                for i=2:numtrial
                    options=1:numtask;
                    options(options==idx)=[];
                    optionidx=randi(numtask-1,1);
                    taskorder=[taskorder;targets(options(optionidx))];
                    idx=find(strcmp(taskorder{end},targets));
                end
                
                handles.BCI.SSVEP.control.taskorder=taskorder;
                
                
            end
            
            set(stimulus.general.text,'string','Waiting to start...')
            
        end
        
    end
    
end
        
        
        
        
        
        
        
    







