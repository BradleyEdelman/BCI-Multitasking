function bci_ESI_SendTrigger(handles,et,varargin)

nargs=nargin;
if nargs>2
    
    if ~(round(nargs/2)==nargs/2)
        error('Odd number of input arguments??')
    end
    
    paradigm=get(handles.paradigm,'value');
    switch paradigm
        case {2,3,4,5,8} % DT Cursor, CP Cursor, DT HM, CP HM, DT Cursor - SSVEP
            sigtype={'SMR'};
        case 6 % DT Cursor + SSVEP
            sigtype={'SMR' 'SSVEP'};
        case 7 % SSVEP
            sigtype={'SSVEP'};
    end
    
    for i=3:2:size(varargin,2)
        
        param=varargin{i};
        value=varargin{i+1};
        
        if ~isstr(param)
            error('Flag arguments must be strings')
        end
        
        % SMR triggers begin with 100
        if ismember('SMR',sigtype) && strcmp(param,'event')
                
            tmptype=event.eventtype(end);
            tmpvalue=event.eventvalue{end};

            if strcmp(tmptype,'Feedback') % Feedback 1

                if isequal(tmpvalue,1)
                    trig1=111;
                elseif isequal(tmpvalue,0)
                    trig1=110;
                end

            elseif strcmp(tmptype,'TargetCode') % TargetCode 5 - 8

                if ~isequal(tmpvalue,0)
                    trig1=100+(tmpvalue+4)*10+1;
                end

            end
        
        % SSVEP triggers begin with 200
        elseif ismember('SSVEP',sigtype) && strcmp(param,'ssvepidx')
        
            taskorder=handles.BCI.SSVEP.control.taskorder;
    
            % Target On
            tmpvalue1=taskorder{ssvepidx.target-1};
            trig1=200+(tmpvalue1*10);
            
            % Target Off
            tmpvalue2=taskorder{ssvepidx.target};
            trig2=200+(tmpvalue*10)+1;
            
        end
    
    end
    
end


if exist('var','trig1')
    
    if exist('var','trig2')
        et.sendUserData(trig1,trig2,.1);
    else
        et.sendUserData(trig1);
    end
    
end





