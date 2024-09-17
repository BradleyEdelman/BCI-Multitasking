function [hObject,handles]=bci_ESI_TrainPrepare(hObject,handles,sigtype)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    CHECK DATA FILES FOR "USABILITY"                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data=get(handles.trainfiles,'data');
files=cellstr(data(:,2));
idx=data(:,1);
for i=1:size(idx,1)
    if islogical(idx{i}); idx{i}=+idx{i}; end
end
idx=cell2mat(idx);
trainfiles=files(idx==1);
set(hObject,'backgroundcolor',[.94 .94 .94],'userdata',1);

if isempty(trainfiles)
    
    fprintf(2,'NO TRAINING FILES UPLOADED - CANNOT PERFORM REGRESSION\n');
    set(hObject,'backgroundcolor','red','userdata',0)
    
else

    numfiles=size(trainfiles,1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % EXTRACT TRAINING FILE EXTENSIONS
    for i=1:numfiles
        [filepath{i},filename{i},fileext{i}]=fileparts(trainfiles{i});
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK TRAINING FILE EXTENSION COMPATIBILITY (.dat OR .mat)
    for i=1:numfiles
        if ~strcmp(fileext{i},'.dat') && ~strcmp(fileext{i},'.mat')
            fprintf(2,'TRAINING FILE %s NOT .Dat or .mat (%s)\n',num2str(i),fileext{i});
            set(hObject,'backgroundcolor','red','userdata',0);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK TRAINING FILE SIGNAL TYPE COMPATIBILITY (SMR OR SSVEP)
    for i=1:numfiles
        if isempty(strfind(filename{i},sigtype))
            fprintf(2,'TRAINING FILE "%s" NOT COMPATIBLE WITH %s CLASSIFIER TRAINING\n',filename{i},sigtype);
            set(hObject,'backgroundcolor','red','userdata',0);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK TRAINING FILE EXTENSION CONSISTENCY (ALL SAME EXTENSIONS)
    combinations=combnk(1:numfiles,2);
    for i=1:combinations
        if ~strcmp(fileext{combinations(i,1)},fileext{combinations(i,2)})
            fprintf(2,'INCONSISTENCY AMONG TRAINING FILE FORMAT\n');
            set(hObject,'backgroundcolor','red','userdata',0);
        end
    end
    
    filetype=unique(fileext);
    if strcmp(filetype,'.dat')
        datatype='bci2000';
    elseif strcmp(filetype,'.mat')
        datatype='esibci';
    end

end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               IF TRAINING FILES ARE VALID AND COMPATIBLE                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isequal(get(hObject,'userdata'),1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    IDENTIFY CHANNELS AND VERTICES INCLUDED/EXCLUDED IN ANALYSIS     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    spatdomainfield=handles.TRAINING.spatdomainfield;
    switch spatdomainfield
        case 'Sensor'
            
            switch sigtype
                case 'SMR'
                    chanidxinclude=handles.SYSTEM.Electrodes.chanidxinclude;
                    chanidxexclude=handles.SYSTEM.Electrodes.chanidxexclude;
                case 'SSVEP'
                    chanidxinclude=handles.SSVEP.chanidxinclude;
                    chanidxexclude=handles.SSVEP.chanidxexclude;
            end
            handles.TRAINING.(spatdomainfield).(sigtype).param.chanidxinclude=chanidxinclude;
            handles.TRAINING.(spatdomainfield).(sigtype).param.chanidxexclude=chanidxexclude;

        case 'Source'

            vertidxinclude=handles.ESI.vertidxinclude;
            vertidxexclude=handles.ESI.vertidxexclude;
            handles.TRAINING.(spatdomainfield).(sigtype).param.vertidxinclude=vertidxinclude;
            handles.TRAINING.(spatdomainfield).(sigtype).param.vertidxexclude=vertidxexclude;
            
        case 'SourceCluster'
            
            vertidxinclude=handles.ESI.vertidxinclude;
            vertidxexclude=handles.ESI.vertidxexclude;
            handles.TRAINING.(spatdomainfield).(sigtype).param.vertidxinclude=vertidxinclude;
            handles.TRAINING.(spatdomainfield).(sigtype).param.vertidxexclude=vertidxexclude;
            
            clusters=handles.ESI.CLUSTER.clusters;
            clusteridxinclude=1:size(clusters,2)-1;
            clusteridxexclude=size(clusters,2);
            handles.TRAINING.(spatdomainfield).(sigtype).param.clusteridxinclude=clusteridxinclude;
            handles.TRAINING.(spatdomainfield).(sigtype).param.clusteridxexclude=clusteridxexclude;

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % COPY FREQUENCY TRANSFORM PARAMETERS
    freqtrans=handles.SYSTEM.freqtrans;
    switch freqtrans
        case 1 % None
        case 2 % Complex Morlet wavelet
            handles.TRAINING.(spatdomainfield).param.mwparam=handles.SYSTEM.mwparam;
            handles.TRAINING.(spatdomainfield).param.morwav=handles.SYSTEM.morwav;
        case 3 % Welch's PSD
        case 4 % DFT
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %         LOAD AND PREPARE DATA AND EXTRACT TIMING PARAMETERS         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(datatype,'bci2000')
    
        [trialstruct]=bci_ESI_BCI2000ExtractParameters(trainfiles);
        [handles,taskinfo,data]=bci_ESI_BCI2000TaskInfo(handles,trainfiles,trialstruct);
        
        switch sigtype
            case 'SMR'
                data(handles.SYSTEM.Electrodes.chanidxexclude,:)=[];
            case 'SSVEP'
                data(handles.SSVEP.chanidxexclude,:)=[];
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % DATA IN RUN AND BASE FORMAT LIKE BCIESI FILES
        [hObject,handles,data]=bci_ESI_SegmentBCI2000Data(hObject,handles,data,taskinfo,trialstruct);
        
    elseif strcmp(datatype,'esibci')
        
        [handles,trialstruct]=bci_ESI_BCIESIExtractParamaters2(handles,trainfiles);
        [handles,taskinfo,data]=bci_ESI_BCIESITaskInfo2(handles,trainfiles);
        
        switch sigtype
            case 'SMR'
                data=data.(spatdomainfield).freq;
            case 'SSVEP'
                data=data.(spatdomainfield).time;
        end
        
        if isempty(data.base) || isempty(data.trial)
            fprintf(2,'SPECIFIED TRAINING DOMAIN DATA DOES NOT EXIST\n');
            set(hObject,'userdata',0);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % STORE TRAINING DATA INFO IN SPAT DOMAIN/SIG TYPE SPECIFIC STRUCTURE %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.trainfiles=trainfiles;
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.datatype=datatype;
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.taskinfo=taskinfo;
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.trialstruct=trialstruct;
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.data.(datatype)=data;
    
    targettypes=unique(cell2mat(taskinfo(2:end,2)));
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.taskidx=targettypes;
    
    numtask=size(targettypes,1);
    handles.TRAINING.(spatdomainfield).(sigtype).datainfo.numtask=numtask;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %              EXTRACT AND STORE NORMALIZATION PARAMETERS             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    decodescheme=handles.TRAINING.(spatdomainfield).(sigtype).param.decodescheme;
    switch sigtype
    
        case 'SMR'
            
            baselinetype=handles.TRAINING.(spatdomainfield).(sigtype).param.baselinetype;
            baselinestart=handles.TRAINING.(spatdomainfield).(sigtype).param.baselinestart;
            baselineend=handles.TRAINING.(spatdomainfield).(sigtype).param.baselineend;

            switch baselinetype
                case 1 % None
                    
                    baselinestartidx=[];
                    baselineendidx=[];
                    baseidx=[];
                    baseidxlength=[];

                case 2 % Trial baseline
                    
                    switch decodescheme
                        case 1 % None
                        case 2 % Single Trial

                            baselinelength=trialstruct.baselength;
                            baseidx=linspace(-baselinelength,0,handles.SYSTEM.dsfs);

                            baselinestartidx=find(abs(baseidx-baselinestart)==min(abs(baseidx-baselinestart)));
                            baselinestartidx=baselinestartidx(end);

                            baselineendidx=find(abs(baseidx-baselineend)==min(abs(baseidx-baselineend)));
                            baselineendidx=baselineendidx(1);
                            
                            baseidx=baselinestartidx:baselineendidx;
                            baseidxlength=size(baselinestartidx:baselineendidx,2);

                        case 3 % Time Resolved

                            basewin=zeros(size(data.base,2),1);
                            for i=1:size(data.base,2)
                                basewin(i)=size(data.base{i},2);
                            end
                            baselength=max(basewin);

                            baselinelength=trialstruct.baselength;
                            baseidx=linspace(-baselinelength,0,baselength);
                            baselinestartidx=find(abs(baseidx-baselinestart)==min(abs(baseidx-baselinestart)));
                            baselinestartidx=baselinestartidx(end);

                            baselineendidx=find(abs(baseidx-baselineend)==min(abs(baseidx-baselineend)));
                            baselineendidx=baselineendidx(1);
                            
                            baseidx=baselinestartidx:baselineendidx;
                            baseidxlength=size(baselinestartidx:baselineendidx,2);

                    end

                case 3 % Run baseline
                    
                    baselinestartidx=baselinestart;
                    if isequal(baselinestart,0); baselinestartidx=1; end
                    
                    baselineendidx=baselineend;
                    if baselineend>size(data.runbase,2); baselineendidx=size(data.runbase,2);end

                    baseidx=baselinestartidx:baselineendidx;
                    baseidxlength=size(baselinestartidx:baselineendidx,2);
                    
                    if isempty(data.runbase)
                        fprintf(2,'NO RUN BASELINE COLLECTED/DEFINED, NO BASELINE NORMALIZATION\n');
                        baselinestartidx=[];
                        baselineendidx=[];
                        baseidx=[];
                        baseidxlength=[];
                        handles.TRAINING.(spatdomainfield).(sigtype).param.normtype=1;
                    end
                    
            end
            
            handles.TRAINING.(spatdomainfield).(sigtype).param.baselinestartidx=baselinestartidx;
            handles.TRAINING.(spatdomainfield).(sigtype).param.baselineendidx=baselineendidx;
            handles.TRAINING.(spatdomainfield).(sigtype).param.baseidx=baseidx;
            handles.TRAINING.(spatdomainfield).(sigtype).param.baseidxlength=baseidxlength;
            
        case 'SSVEP'
            
            
    end 
    
end


