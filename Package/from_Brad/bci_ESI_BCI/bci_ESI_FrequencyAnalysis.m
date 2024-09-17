function [varargout]=bci_ESI_FrequencyAnalysis(action,freq,varargin)

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
        
        
        if ~ismember('handles',str)
            error('Need handles to create EEG structure\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if isempty(freq)
            freq=struct;
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
        flags.freqtrans=handles.BCI.param.freqtrans;
        flags.feattype=handles.BCI.SMR.control.feattype;
        v2struct(flags)
        
        
        switch freqtrans
            case 1 % None
            case 2 % Complex Morlet wavelet
                freq.mwparam=handles.SYSTEM.mwparam;
                freq.morwav=handles.SYSTEM.morwav;
                freq.dt=1/handles.SYSTEM.mwparam.fs;
                freq.freqvect=handles.SYSTEM.mwparam.freqvect;
                freq.numfreq=size(handles.SYSTEM.mwparam.freqvect,2);
                flags.numfreq=freq.numfreq;
            case 3 % Welch's PSD
        %         WelchParam=handles.TFParam.WelchParam;
        %         WelchParam.winsize=BlockSize;
        %         w=0:1/WelchParam.freqfact:hdr.Fs/2;
        %         LowCutoff=str2double(get(handles.LowCutoff,'string'));
        %         HighCutoff=str2double(get(handles.HighCutoff,'string'));
        %         FreqInterest=find(w>=LowCutoff & w<=HighCutoff);
            case 4 % DFT
        %         nfft=2^(nextpow2(BlockSize)+2);
        %         fs=str2double(get(handles.fs,'string'));
        %         w=0:fs/(nfft):fs-(fs/nfft);
        %         LowCutoff=str2double(get(handles.LowCutoff,'string'));
        %         HighCutoff=str2double(get(handles.HighCutoff,'string'));
        %         FreqInterest=find(w>=LowCutoff & w<=HighCutoff);
        end
        
        varargout{1}=freq;
        varargout{2}=flags;
        
    elseif strcmp(action,'process')
        
    
        if ~ismember('signal',str)
            error('Need signal type to store data\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ~ismember('esi',str)
            error('Need esi structure to complete frequency transform\n');
        else
            esi=val{strcmp(str,'esi')};
        end
        
        if ~ismember('eeg',str)
            error('Need eeg structure type to store data\n');
        else
            eeg=val{strcmp(str,'eeg')};
        end
        v2struct(eeg.general)
        
        if ~ismember('flags',str)
            error('Need flags to update plots\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        v2struct(freq)
        
        switch freqtrans
            case 1 % None
            case 2 % Complex Morlet Wavelet

                Acomplex=zeros(numfreq,size(eeg.(signal).data,2),size(eeg.(signal).data,1));
                for i=1:size(eeg.(signal).data,1)
                    for j=1:numfreq
                        Acomplex(j,:,i)=conv2(eeg.(signal).data(i,:),morwav{j},'same')*dt;
                    end
                end
                Acomplex=Acomplex(:,analysiswindowpaddingprocess+1:end-analysiswindowpaddingprocess,:);
 
        [esi,data,Save]=bci_ESI_ESI('inverse',esi,'data',Acomplex,'flags',flags);
        
        end
        varargout{1}=Save;
        
        %% Select frequency(s) of interest for each control dimension
        if ~ismember('bci',str)
            error('Need bci structure to perform frequency analysis\n');
        else
            bci=val{strcmp(str,'bci')};
        end

        dataselect=cell(3,1);
        for i=dimused
            
            dataselect{i}=sum(data(cell2mat(bci.(signal).freqidx(i)),:,:),1);
            dataselect{i}=sum(squeeze(dataselect{i}),1)';
            
            if strcmp(feattype,'PCA')
                dataselect{i}=(dataselect{i}'*bci.(signal).pcaweight{i})';
            end
            
        end
        varargout{2}=dataselect;
        

    end
    
end
