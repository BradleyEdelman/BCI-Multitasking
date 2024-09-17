function [control,varargout]=bci_ESI_ControlSignal(action,control,varargin)


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
            error('Need handles to create EEG structure\n');
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
        
        if isempty(control)
            control=struct;
        end
        
        switch paradigm
            
            case {2,3,4,5,6,8}
        
                flags.normidx=handles.BCI.SMR.control.normidx;
                flags.hitcriteria=handles.BCI.SMR.param.hitcriteria;
                flags.paradigm=get(handles.paradigm,'value');
                flags.fixnorm=get(handles.fixnorm,'value');
                flags.normonoff=get(handles.normonoff,'value');
                v2struct(flags)

                % NORMALIZER PARAMETERS
                gain=zeros(3,1); offset=zeros(3,1); scale=zeros(3,1);
                for i=1:3
                    if ~isequal(normidx(i),0)
                        gainvar=strcat('gain',num2str(normidx(i)));
                        gain(i)=str2double(get(handles.(gainvar),'string'));
                        offsetvar=strcat('offset',num2str(normidx(i)));
                        offset(i)=str2double(get(handles.(offsetvar),'string'));
                        scalevar=strcat('scale',num2str(normidx(i)));
                        scale(i)=str2double(get(handles.(scalevar),'string'));
                    end
                end

                control.gain=gain;
                control.offset=offset;
                control.scale=scale;
                control.raw=zeros(3,1);
                control.norm=zeros(3,1);
                control.filt=zeros(3,1);
                control.send=zeros(3,1);
                control.disp=zeros(3,1);
                control.stim=zeros(3,1);
                
        end
        
        varargout{1}=flags;
        
    elseif strcmp(action,'raw')
        %% COMPUTE RAW CONTROL SIGNAL
        
        if ismember('data',str)
            data=val{strcmp(str,'data')};
        else
            error('Need data to compute raw control signal\n');
        end
        
        if ismember('bci',str)
            bci=val{strcmp(str,'bci')};
        else
            error('Need bci structure to compute raw control signal\n');
        end
        
        L=size(control.norm,2);
        for i=1:3
            
            % Multiply data by weights and add offset
            rawtmp=(data{i}'*bci.SMR.weight{i})+bci.SMR.offset{i};
            if ~isempty(rawtmp)
                control.raw(i,L+1)=rawtmp;
            end
            
        end

    elseif strcmp(action,'norm')
        %% NORMALIZE CONTROL SIGNAL
        
        if ismember('bufferbci',str)
            bufferbci=val{strcmp(str,'bufferbci')};
        else
            error('Need buffer data to normalize control signal\n');
        end
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
        else
            error('Need flags to normalize control signal\n');
        end
        v2struct(flags)
        
        % If normalizer is not fixed
        if isequal(fixnorm,0) 

            % NORMALIZER ON - NORMALIZE CONTROL SIGNAL
            if isequal(normonoff,1) 
                for i=1:3
                    
                    buffertmp=bufferbci.cs.totaltrial{i};
                    if ~isequal(buffertmp,0) && ~isempty(buffertmp)
                        control.offset(i)=mean(buffertmp);
                        control.gain(i)=1/std(buffertmp);
                    end

                end

            end
        end
        
        L=size(control.norm,2);
        for i=1:3
            control.norm(i,L+1)=control.scale(i)*(control.raw(i,end)-control.offset(i))*control.gain(i);
        end
    	
    elseif strcmp(action,'filt')
        %% FILTER CONTROL SIGNAL
        
        T=2;
        L=size(control.filt,2);
        for i=1:3
            if isequal(size(control.norm,2),1)
                control.filt(i,L+1)=(1-exp(-1/T))*control.norm(i,end);
            else
                control.filt(i,L+1)=exp(-1/T)*control.norm(i,end-1)+...
                    (1-exp(-1/T))*control.norm(i,end);
            end

            if isnan(control.filt(i,L+1))
                control.filt(i,L+1)=0;
            elseif control.filt(i,L+1)>5
                control.filt(i,L+1)=5;
            elseif control.filt(i,L+1)<-5
                control.filt(i,L+1)=-5;
            end
        end
       
    elseif strcmp(action,'stim')
        %% COMPUTE "STIMULUS" CONTROL SIGNAL
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
        else
            error('Need flags to normalize control signal\n');
        end
        
        if ismember('event',str)
            event=val{strcmp(str,'event')};
        else
            error('Need event to normalize control signal\n');
        end
        
        v2struct(flags)
        
        if isequal(paradigm,4)
            
            L=size(control.stim,2);
            control.stim=zeros(3,1);
            for i=1:size(hitcriteria,1)
                control.stim(i,L+1)=(event.cursorpos.current(i)/4095-.5)*2*abs(hitcriteria(i,1));
            end
            
        elseif isequal(paradigm,5)
            
            L=size(control.stim,2);
            control.stim(:,L+1)=zeros(3,1);
            
        end
        
    elseif strcmp(action,'disp')
        %% PREPARE CONTROL SIGNAL TO BE DISPLAYED
        
        if size(control.disp,2)>30
            control.disp=circshift(control.disp,[0 -1]);
            control.disp(:,end)=control.filt(:,end);
        else
            control.disp(:,end+1)=control.filt(:,end);
        end
        
    elseif strcmp(action,'send')
        %% PREPARE CONTROL SIGNAL FOR SENDING TO BCI2000
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
        else
            error('Need flags to send control signal\n');
        end
        v2struct(flags)
        
        for i=1:size(control.send,1)
            
            % Cursor must move in order to receive position events...
            if isequal(control.send(i),0)
                control.send(i)=.0025*((-1)^randi(2,1));
            else
                control.send(i)=control.filt(i,end);
            end
            
        end
        
        if ismember(paradigm,[3 5]) && isequal(size(control.send,1),3)
            control.send(3)=[];
        end
        
    elseif strcmp(action,'reset')
        %% Update normalizer values
        
        if ismember('handles',str)
            handles=val{strcmp(str,'handles')};
        else
            error('Need handles to update normalizer values\n');
        end
        
        if ismember('flags',str)
            flags=val{strcmp(str,'flags')};
        else
            error('Need flags to update normalize values\n');
        end
        v2struct(flags)
        
        for i=1:3
            if ~isequal(normidx(i),0)
                gainvar=strcat('gain',num2str(normidx(i)));
                set(handles.(gainvar),'string',num2str(control.gain(i)));
                offsetvar=strcat('offset',num2str(normidx(i)));
                set(handles.(offsetvar),'string',num2str(control.offset(i)));
            end
        end
        
        varargout{1}=handles;
        
        
    end
end

