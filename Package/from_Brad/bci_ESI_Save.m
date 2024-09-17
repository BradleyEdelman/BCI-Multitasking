function [saveparam]=bci_ESI_Save(varargin)

nargs=nargin;
if nargs<1
else
    
    str=cell(0); val=cell(0);
    for i=1:2:length(varargin)
        str{end+1}=varargin{i};
        val{end+1}=varargin{i+1};
    end
    
    % Save eeg parameters
    if ismember('eeg',str)
        
        if ~ismember('signal',str)
            error('Need signal type to save parameters\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        eeg=val{strcmp(str,'eeg')};
        removefields={'data','targetidx','startidx','endidx'};
        
        if ismember('SSVEP',signal) || strcmp('SSVEP',signal)
            for i=1:size(removefields,2)
                eeg.SSVEP=rmfield(eeg.SSVEP,removefields{i});
            end
        end
        
        if ismember('SMR',signal) || strcmp('SMR',signal)
            for i=1:size(removefields,2)
                eeg.SMR=rmfield(eeg.SMR,removefields{i});
            end
        end
        
        saveparam.eeg=eeg;
        
    end
    
    % Save flags
    if ismember('flags',str)
        saveparam.flags=val{strcmp(str,'flags')};
    end
    
    if ismember('trial',str)
        saveparam.trial=val{strcmp(str,'trial')};
    end
    
    if ismember('bci',str)
        saveparam.bci=val{strcmp(str,'bci')};
    end
    
    if ismember('esi',str)
        saveparam.esi=val{strcmp(str,'esi')};
    end
    
    if ismember('control',str)
        saveparam.control=val{strcmp(str,'control')};
    end
    
    if ismember('freq',str)
        saveparam.freq=val{strcmp(str,'freq')};
    end
    
    if ismember('performance',str)
        saveparam.performance=val{strcmp(str,'performance')};
    end
    
    if ismember('TOC',str)
        saveparam.TOC=val{strcmp(str,'TOC')};
    end
    
end
    
    
    
    
    
    
    
    
    
    
    