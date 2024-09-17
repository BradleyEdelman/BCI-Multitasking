function [bufferbci,varargout]=bci_ESI_ModBuffer(action,bufferbci,varargin)


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
        %% INITIATE BUFFER
        if ~ismember('handles',str)
            error('Need handles to initiate buffer(s)\n');
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
        
        flags.decodeadapt=get(handles.decodeadapt,'value');
        flags.task=handles.BCI.SMR.param.task;
        flags.normonoff=get(handles.normonoff,'value');
        flags.fixnorm=get(handles.fixnorm,'value');
        flags.bufferlength=str2double(get(handles.bufferlength,'string'));
        flags.cyclelength=str2double(get(handles.cyclelength,'string'));
        flags.targetid=handles.BCI.SMR.param.targetid;
        v2struct(flags)
        
        datainittrials=handles.BCI.SMR.control.datainittrials;
        datainitwindows=handles.BCI.SMR.control.datainitwindows;
        
        if isempty(bufferbci)
            bufferbci=struct;
        end
        
        % CREATE EMPTY BUFFERS
        
        % control signal
        cs.trial=cell(3,2);
        cs.trial{1,1}=cell(1,bufferlength); cs.trial{1,2}=cell(1,bufferlength);
        cs.trial{2,1}=cell(1,bufferlength); cs.trial{2,2}=cell(1,bufferlength);
        cs.trial{3,1}=cell(1,bufferlength); cs.trial{3,2}=cell(1,bufferlength);
        cs.window=cell(3,2); cs.windowcount=[];
        cs.trialcount=ones(3,2); cs.mintrial=zeros(3,1); cs.totaltrial=cell(3,1);
        % "raw" data
        data.trial=cell(3,2);
        data.trial{1,1}=cell(1,bufferlength); data.trial{1,2}=cell(1,bufferlength);
        data.trial{2,1}=cell(1,bufferlength); data.trial{2,2}=cell(1,bufferlength);
        data.trial{3,1}=cell(1,bufferlength); data.trial{3,2}=cell(1,bufferlength);
        data.window=cell(3,2); data.windowcount=[];
        data.trialcount=ones(3,2); data.mintrial=zeros(3,1); data.totaltrial=cell(3,1);
        
        % CREATE BUFFER COUNTS
        switch task
            case '3D'
                dimused=1:3;
            case '2D'
                dimused=1:2;
                data.trialcount(3,:)=[2,2];
                cs.trialcount(3,:)=[2,2];
            case {'Pitch','Horizontal'}
                dimused=1;
                data.trialcount([2 3],:)=2*ones(2,2); 
                cs.trialcount([2 3],:)=2*ones(2,2); 
            case {'Roll','Vertical'}
                dimused=2;
                data.trialcount([1 3],:)=2*ones(2,2); 
                cs.trialcount([1 3],:)=2*ones(2,2); 
            case {'Yaw','Depth'}
                dimused=3;
                data.trialcount(1,:)=[2,2]; data.trialcount(2,:)=[2,2];
                cs.trialcount(1,:)=[2,2]; cs.trialcount(2,:)=[2,2];
        end
        flags.dimused=dimused;
        
        % POPULATE DATA BUFFER WITH "TRAINING DATA", IF ANY
        for i=dimused

            % Task Data (two classes per dimension)
            for j=1:2

                % Data trial buffer
                if ~isempty(datainittrials{i})
                    data.trial{i,j}=datainittrials{i}{j};
                    % Limit size to bufferlength defined in GUI
                    if size(data.trial{i,j},2)>bufferlength
                        extraidx=size(data.trial{i,j},2)-bufferlength;
                        % Remove oldest trials in lower indices
                        data.trial{i,j}(1:extraidx)=[];
                    end
                    data.trialcount(i,j)=size(data.trial{i,j},2);
                    data.trial{i,j}(end)=cell(1);
                end

                % Data window buffer
                if ~isempty(datainitwindows{i})
                    data.window{i,j}=datainitwindows{i}{j};
                    % Limit size to bufferlength defined in GUI (assume 30 windows per trial?)
                    if size(data.window{i,j},2)>30*bufferlength
                        extraidx=size(data.window{i,j},2)-30*bufferlength;
                        % Remove oldest windows in lower indices
                        data.window{i,j}(:,1:extraidx)=[];
                    end
                end
            end

        end
        
        % Predefined structure for storage input
        storage=struct('dim',[],'targidx',[],'limit',[],'data',[],...
            'datatype',[],'buffertype',[],'win',[]);

        % Pack variables into BFUFER struct
        bufferbci.storage=storage;
        bufferbci.cs=cs;
        bufferbci.data=data;
        
        varargout{1}=flags;
    
    elseif strcmp(action,'store')
        %% STORE DATA IN BUFFER
        
        datatype=bufferbci.storage.datatype;
        bufferbci.(datatype)=bci_ESI_StoreBuffer(bufferbci.(datatype),bufferbci.storage);

    elseif strcmp(action,'update')
        %% UPDATE BUFFER/CLASSIFIER
        
        if ismember('updatecount',str)
            updatecount=val{strcmp(str,'updatecount')};
            
            if ~isequal(size(updatecount,2),3)
                error('updatecount must contain ''dim'' and ''targetididx''\n')
            else

                datatype=bufferbci.storage.datatype;
                bufferbci.(datatype)=bci_ESI_UpdateBuffer(bufferbci.(datatype),updatecount);

            end
        end
       
    elseif strcmp(action,'reset')
        
        if ~ismember('flags',str)
            error('Need flags to reset buffer(s)\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        
        if ~ismember('handles',str)
            error('Need handles to reset buffer(s)\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if ~ismember('signal',str)
            error('Need signal type to reset buffer(s)\n');
        else
            signal=val{strcmp(str,'signal')};
        end
        
        if ~ismember('bci',str)
            error('Need bci structure to reset buffer(s)\n');
        else
            bci=val{strcmp(str,'bci')};
        end
        
        v2struct(flags)
        
        if ismember('SMR',signal) || strcmp('SMR',signal)
            
            datainittrials=cell(1,3);
            datainitwindows=cell(1,3);
            datainitbase=cell(1,3);
            normonoff=get(handles.normonoff,'value');
            if isequal(normonoff,0)
                switch feattype
                    case 'Regress'
                    case {'RLDA','PCA','FDA'}

                        for i=dimused
                            for j=1:2
                                datainittrials{i}{j}=bufferbci.data.trial{i,j};
                                datainittrials{i}{j}(cellfun('isempty',datainittrials{i}{j}))=[];
                                datainitwindows{i}{j}=bufferbci.data.window{i,j};
                            end
                            datainitbase{i}{1}=bufferbci.base.window{i};
                        end

                        handles.BCI.SMR.param.control.datainitwindows=datainitwindows;
                        handles.BCI.SMR.param.control.datainittrials=datainittrials;
                        handles.BCI.SMR.param.control.datainitbase=basewindows;
                        handles.BCI.SMR.param.control.w=bci.SMR.weight;
                        handles.BCI.SMR.param.control.w0=bci.SMR.offset; 
                end
            end
        
        end
        varargout{1}=handles;
        
        
        
    end
    
end

    
    
    
    
    
    
    