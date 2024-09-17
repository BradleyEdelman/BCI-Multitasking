function [baseline,varargout]=bci_ESI_Baseline(action,baseline,varargin)


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
        %% INITIATE BASELINE STRUCTURE
        
        if ~ismember('handles',str)
            error('Need handles to create baseline structure\n');
        else
            handles=val{strcmp(str,'handles')};
        end
        
        if ~ismember('signal',str)
            error('Need signal to create baseline structure\n');
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
        flags.bufferlength=str2double(get(handles.bufferlength,'string'));
        flags.spatdomainfield=handles.TRAINING.spatdomainfield;
        v2struct(flags)
        
        % baseline
        basemean=cell(3,1); basestd=cell(3,1);
        switch spatdomainfield
            case 'Sensor'
                
                chanidxinclude=handles.TRAINING.Sensor.param.chanidxinclude;
                if isempty(chanidxinclude)
                    chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
                end
                numchan=size(chanidxinclude,1);
                
                basemean{1}=ones(numchan,1); basestd{1}=ones(numchan,1);
                basemean{2}=ones(numchan,1); basestd{2}=ones(numchan,1);
                basemean{3}=ones(numchan,1); basestd{3}=ones(numchan,1);
                
                flags.numchan=numchan;
                flags.chanidxinclude=chanidxinclude;
                
            case 'Source'
                
                chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
                numchan=size(chanidxinclude,1);
                
                vertidxinclude=handles.TRAINING.Source.param.vertidxinclude;
                if isempty(vertidxinclude)
                    vertidxinclude=handles.ESI.vertidxinclude;
                end
                numvert=size(vertidxinclude,2);
                
                basemean{1}=ones(numvert,1); basestd{1}=ones(numvert,1);
                basemean{2}=ones(numvert,1); basestd{2}=ones(numvert,1);
                basemean{3}=ones(numvert,1); basestd{3}=ones(numvert,1);
                
                flags.numvert=numvert;
                flags.vertidxinclude=vertidxinclude;
                flags.numchan=numchan;
                flags.chanidxinclude=chanidxinclude;
                
            case 'SourceCluster'
                
                chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
                numchan=size(chanidxinclude,1);
                
                clusteridxinclude=handles.TRAINING.SourceCluster.SMR.param.clusteridxinclude;
                if isempty(clusteridxinclude)
                    clusteridxinclude=handles.ESI.CLUSTER.clusters;
                end
                numcluster=size(clusteridxinclude,2);
                
                basemean{1}=ones(numcluster,1); basestd{1}=ones(numcluster,1);
                basemean{2}=ones(numcluster,1); basestd{2}=ones(numcluster,1);
                basemean{3}=ones(numcluster,1); basestd{3}=ones(numcluster,1);
                
                flags.numcluster=numcluster;
                flags.clusteridxinclude=clusteridxinclude;
                flags.numchan=numchan;
                flags.chanidxinclude=chanidxinclude;
        end
        
        SMR=struct; SSVEP=struct;
        
        if ismember('SMR',signal) || isequal('SMR',signal)
            datainitbase=handles.BCI.SMR.control.datainitbase;
            runbase=handles.BCI.SMR.control.runbase;
            basewindow=cell(1,3);
            for i=3
                if ~isempty(datainitbase{i})
                    % Task Data (two classes per dimension)
                    for j=1:2

                        % Baseline data
                        if iscell(datainitbase{i})
                            basewindow{i}=horzcat(datainitbase{i}{:}{:});
                        else
                            basewindow{i}=datainitbase{i};
                        end

                        if size(basewindow{i},2)>20*bufferlength
                            extraidx=size(basewindow{i},2)-20*bufferlength;
                            % Remove oldest windows in lower indices
                            basewindow{i}(:,1:extraidx)=[];
                        end

                    end
                end
            end

            SMR.baselinetype=handles.TRAINING.(spatdomainfield).SMR.param.baselinetype;
            SMR.baselinenormtype=1;%handles.TRAINING.(spatdomainfield).SMR.param.normtype;
            SMR.baselinestartidx=handles.TRAINING.(spatdomainfield).SMR.param.baselinestartidx;
            SMR.baselineendidx=handles.TRAINING.(spatdomainfield).SMR.param.baselineendidx;
            SMR.basewindow=basewindow;
            SMR.basemean=basemean;
            SMR.basestd=basestd;
            SMR.runbase=runbase;
            
        end
            
        if ismember('SSVEP',signal) || strcmp('SSVEP',signal)

            SSVEP.baselinetype=handles.TRAINING.(spatdomainfield).SSVEP.param.baselinetype;
            SSVEP.baselinenormtype=handles.TRAINING.(spatdomainfield).SSVEP.param.normtype;
            SSVEP.baselinestartidx=handles.TRAINING.(spatdomainfield).SSVEP.param.baselinestartidx;
            SSVEP.baselineendidx=handles.TRAINING.(spatdomainfield).SSVEP.param.baselineendidx;
            SSVEP.basedata=[];
            SSVEP.basemean=[];
            SSVEP.basestd=[];
            SSVEP.runbase=[];
            
        end

        baseline=v2struct(SMR,SSVEP);
        
        varargout{1}=flags;

    elseif strcmp(action,'store')
        
        if ismember('signal',str)
            signal=val{strcmp(str,'signal')};
        else
            error('Need signal type to store data\n');
        end
        
        if ismember('data',str)
            data=val{strcmp(str,'data')};
        else
            error('Need data structure to store data\n');
        end
        
        if ~ismember('flags',str)
            error('Need flags to update plots\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)

        for i=dimused
            baseline.(signal).basewindow{i}=[baseline.(signal).basewindow{i} data{i}];
        end

        
    elseif strcmp(action,'normalize')
        
        if ismember('signal',str)
            signal=val{strcmp(str,'signal')};
        else
            error('Need signal type to update baseline\n');
        end
        
        if ismember('data',str)
            data=val{strcmp(str,'data')};
        else
            error('Need data structure to store data\n');
        end
        
        if ~ismember('flags',str)
            error('Need flags to update plots\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        v2struct(baseline.(signal))
        
        for i=dimused
        
            switch baselinenormtype
                case 1 % None
                    
                case 2 % Baseline relative

                    switch baselinetype
                        case 1 % None
                        case 2 % Trial Baseline
                            meantmp=basemean{i};
                        case 3 % Run Baseline

                            if isempty(runbase{i})
                                meantmp=basemean{i};
                            else
                                meantmp=runbase{i}.meandata;
                            end

                    end

                    data{i}=data{i}./repmat(meantmp,[1 size(data{i},2)]);

                case 3 % Z-score

                    switch baselinetype
                        case 1 % None - use trial data
%                             meantmp=mean(dataselect{i},2);
%                             stdtmp=std(dataselect{i},0,2);

                        case 2 % Trial Baseline
                            meantmp=basemean{i};
                            stdtmp=basestd{i};

                        case 3 % Run Baseline

                            if isempty(runbase{i})
                                meantmp=basemean{i};
                                stdtmp=basestd{i};
                            else
                                meantmp=runbase{i}.meandata;
                                stdtmp=runbase{i}.stddata;
                            end

                    end

                    data{i}=(data{i}-repmat(meantmp,[1 size(data{i},2)]))./...
                        repmat(stdtmp,[1 size(data{i},2)]);
                    
            end
        end
        varargout{1}=data;
        
    elseif strcmp(action,'update')
        
        if ismember('signal',str)
            signal=val{strcmp(str,'signal')};
        else
            error('Need signal type to update baseline\n');
        end
        
        if ~ismember('flags',str)
            error('Need flags to update plots\n');
        else
            flags=val{strcmp(str,'flags')};
        end
        v2struct(flags)
        v2struct(baseline.(signal));
        
        for i=dimused
            
            if ~isempty(baselinestartidx) && ~isempty(baselineendidx)
                baseline.(signal).basewindow{i}=baseline.(signal).basewindow{i}(:,baselinsstartidx:baselinendidx);
            end
            
            baseline.(signal).basemean{i}=mean(baseline.(signal).basewindow{i},2);
            baseline.(signal).basestd{i}=std(baseline.(signal).basewindow{i},0,2);
        end
        baseline.(signal).basewindow=cell(1,3);

    end
    
end
