function [eeg,varargout]=bci_ESI_EEG(action,eeg,varargin)


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
        
        if ~ismember('signal',str)
            error('Need signal type to create EEG structure\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ~ismember('handles',str)
            error('Need handles to create EEG structure\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if isempty(eeg)
            eeg=struct;
        end
        
        eeg.general.dsfactor=handles.BCI.param.dsfactor;
        eeg.general.fsprocess=handles.BCI.param.fsprocess;
        eeg.general.analysiswindowpaddingextract=handles.BCI.param.analysiswindowpaddingextract;
        eeg.general.analysiswindowpaddingprocess=handles.BCI.param.analysiswindowpaddingprocess;
        eeg.general.filter.a=handles.SYSTEM.filterds.a;
        eeg.general.filter.b=handles.SYSTEM.filterds.b;
        eeg.general.chanidxextract=1:size(handles.Electrodes.chanidxinclude,2);
        
        if ismember('SMR',signal) || strcmp('SMR',signal)
    
            eeg.SMR.data=[];
            eeg.SMR.targetidx=[];
            eeg.SMR.startidx=[];
            eeg.SMR.endidx=[];
            eeg.SMR.updatewindowextract=handles.BCI.SMR.param.updatewindowextract;
            eeg.SMR.analysiswindowextract=handles.BCI.SMR.param.analysiswindowextract;
            eeg.SMR.analysiswindowprocess=handles.BCI.SMR.param.analysiswindowprocess;
            eeg.SMR.chanidxinclude=handles.BCI.SMR.param.chanidxinclude;
            eeg.SMR.numchan=size(handles.BCI.SMR.param.chanidxinclude,1);

        end

        if ismember('SSVEP',signal) || strcmp('SSVEP',signal)

            eeg.SSVEP.data=[];
            eeg.SSVEP.targetidx=[];
            eeg.SSVEP.startidx=[];
            eeg.SSVEP.endidx=[];
            eeg.SSVEP.decisionwindowextract=handles.BCI.SSVEP.param.decisionwindowextract;
            eeg.SSVEP.decisionwindowprocess=handles.BCI.SSVEP.param.decisionwindowprocess;
            eeg.SSVEP.gazewindowprocess=ceil(500/1000*eeg.general.fsprocess*eeg.general.dsfactor);
            eeg.SSVEP.chanidxinclude=handles.BCI.SSVEP.param.chanidxinclude;
            eeg.SSVEP.numchan=size(handles.BCI.SSVEP.param.chanidxinclude,1);

        end
        
    elseif strcmp(action,'preprocess')
    
        if ~ismember('signal',str)
            error('Need signal type to store data\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        v2struct(eeg.general);
        
        % DOWNSAMPLE DATA
        eeg.(signal).data=eeg.(signal).data(:,1:dsfactor:end);
        
        % BANDPASS FILTER DATA
        eeg.(signal).data=filtfilt(filter.b,filter.a,double(eeg.(signal).data'));
        eeg.(signal).data=eeg.(signal).data';
        
        % MEAN-CORRECT DATA
        eeg.(signal).data=eeg.(signal).data-repmat(mean(eeg.(signal).data,2),[1,size(eeg.(signal).data,2)]);
        
        % COMMON AVERAGE REFERENCE
        eeg.(signal).data=eeg.(signal).data-repmat(mean(eeg.(signal).data,1),[size(eeg.(signal).data,1),1]);
        
        eeg.(signal).data=eeg.(signal).data(eeg.(signal).chanidxinclude,:);
        
    end
end