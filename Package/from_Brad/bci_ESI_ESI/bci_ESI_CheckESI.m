function [hObject,handles]=bci_ESI_CheckESI(hObject,handles)

SetSystem=get(handles.SetSystem,'userdata');

if isequal(SetSystem,1)

    set(hObject,'backgroundcolor','green','userdata',1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK NOISE
    noise=get(handles.noise,'value');
    set(handles.noisefile,'backgroundcolor','green')
    switch noise
        case 1 % None selected
            fprintf(2,'   NO NOISE ESTIMATION; USING IDENTITY NOISE MATRIX\n');
            set(handles.noise,'backgroundcolor','white','value',2)
            set(handles.noisefile,'backgroundcolor','white')
            
        case 2 % No noise estimation
            fprintf(2,'   NO NOISE ESTIMATION; USING IDENTITY NOISE MATRIX\n');
            set(handles.noisefile,'backgroundcolor','white')
            
        case {3,4} % Diagonal or full noise covariance
            noisefile=get(handles.noisefile,'string');
            [filepath,filename,fileext]=fileparts(noisefile);
            if isempty(noisefile)
                fprintf(2,'   NOISE DATA FILE NOT SPECIFIED\n');
                set(handles.noisefile,'backgroundcolor','red')
                set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                
            elseif ~exist(noisefile,'file')
                fprintf(2,'   NOISE DATA FILE DOES NOT EXIST\n');
                set(handles.noisefile,'backgroundcolor','red')
                set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                    
            elseif ~strcmp(fileext,'.mat')
                fprintf(2,'   NOISE DATA FILE NOT IN .DAT or .mat FORMAT\n');
                set(handles.noisefile,'backgroundcolor','red')
                set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                
            else
                
                noisedatastruct=load(noisefile);
                if ~isfield(noisedatastruct,'Dat') || isempty(noisedatastruct.Dat)
                    fprintf(2,'   "DAT" STRUCTURE MISSING FROM NOISE STRUCTURE OR EMPTY\n');
                    set(handles.noisefile,'backgroundcolor','red')
                	set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                elseif ~isfield(noisedatastruct.Dat,'eeg') || isempty(noisedatastruct.Dat(1).eeg)
                    fprintf(2,'   "EEG" DATA MISSING FROM NOISE DATA STRUCTURE\n');
                    set(handles.noisefile,'backgroundcolor','red')
                	set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                elseif ~isfield(noisedatastruct.Dat,'psd') || isempty(noisedatastruct.Dat(1).psd) ||...
                        ~isfield(noisedatastruct.Dat(1).psd,'Sensor') || isempty(noisedatastruct.Dat(1).psd.Sensor)
                    fprintf(2,'   "SENSOR PSD" DATA MISSING FROM NOISE DATA STRUCTURE\n');
                    set(handles.noisefile,'backgroundcolor','red')
                	set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                else
                    noisechan=size(noisedatastruct.Dat(1).chanidxinclude,1);
                    currentchan=size(handles.SYSTEM.Electrodes.current.eLoc,2);
                    if ~isequal(noisechan,currentchan);
                    	fprintf(2,'NOISE DATA CHANNEL SIZE NOT COMPATIBLE WITH CURRENT SELECTED CHANNELS\n');
                    	set(handles.noisefile,'backgroundcolor','red');
                    	set(handles.CheckESI,'backgroundcolor','red','userdata',0)
                    end
                    
                end
            end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK CORTEX
    cortexfile=get(handles.cortexfile,'string');
    set(handles.cortexfile,'backgroundcolor','green')
    if ~exist(cortexfile,'file')
        fprintf(2,'CORTEX NOT SELECTED\n');
        set(handles.cortexfile,'backgroundcolor','red')
        set(hObject,'backgroundcolor','red','userdata',0)
    else
        cortexfile=load(cortexfile);
        if ~isfield(cortexfile,'Vertices')
            fprintf(2,'CORTEX FILE MISSING VERTICES\n');
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.cortexfile,'backgroundcolor','red')
            
        elseif ~isfield(cortexfile,'Faces')
            fprintf(2,'CORTEX FILE MISSING FACES\n');
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.cortexfile,'backgroundcolor','red')
            
        elseif ~isfield(cortexfile,'SulciMap')
            fprintf(2,'CORTEX FILE MISSING SULCIMAP\n');
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.cortexfile,'backgroundcolor','red')
            
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK LOW RESOLUTION CORTEX
    lrvizsource=get(handles.lrvizsource,'value');
    set(handles.cortexlrfile,'backgroundcolor','white');
    if isequal(lrvizsource,1)
        cortexlrfile=get(handles.cortexlrfile,'string');
        set(handles.cortexlrfile,'backgroundcolor','green')
        if ~exist(cortexlrfile,'file')
            fprintf(2,'LOW RESOLUTION CORTEX NOT SELECTED\n');
            set(hObject,'backgroundcolor','red','userdata',0)
            set(handles.cortexlrfile,'backgroundcolor','red');
        else
            cortexlrfile=load(cortexlrfile);
            if ~isfield(cortexlrfile,'Vertices')
                fprintf(2,'LOW RESOLUTION CORTEX FILE MISSING VERTICES\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.cortexlrfile,'backgroundcolor','red')
                
            elseif size(cortexfile.Vertices,1)/3<size(cortexlrfile.Vertices,1)
                fprintf(2,'LOW RESOLUTION CORTEX MUST BE AT LEAST THREE TIMES ROUGHER THAN ORIGINAL\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.cortexlrfile,'backgroundcolor','red')
                
            elseif ~isfield(cortexlrfile,'Faces')
                fprintf(2,'LOW RESOLUTION CORTEX FILE MISSING FACES\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.cortexlrfile,'backgroundcolor','red')
                
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK EEG SYSTEM
    eegsystem=get(handles.eegsystem,'value');
    if isequal(eegsystem,1)
        set(hObject,'backgroundcolor','red','userdata',0)
        set(handles.eegsystem,'backgroundcolor','red')
    else
        headmodelfile=get(handles.headmodelfile,'string');
        set(handles.headmodelfile,'backgroundcolor','green')
        if ~exist(headmodelfile,'file')
            fprintf(2,'HEADMODEL NOT SELECTED\n');
            set(handles.headmodelfile,'backgroundcolor','red')
            set(hObject,'backgroundcolor','red','userdata',0)
        else
            headmodelfile=load(headmodelfile);
            if ~isfield(headmodelfile,'Gain')
                fprintf(2,'HEADMODEL FILE MISSING GAIN MATRIX\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.headmodelfile,'backgroundcolor','red')
                
            elseif ~isfield(headmodelfile,'GridOrient')
                fprintf(2,'HEADMODEL FILE MISSING GAIN MATRIX\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.headmodelfile,'backgroundcolor','red')
                
            elseif ~isequal(size(headmodelfile.Gain,1),...
                    size(handles.SYSTEM.Electrodes.original.eLoc,2))
                fprintf(2,'ELECTRODE NUMBER DOES NOT MATCH GAIN MATRIX\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.headmodelfile,'backgroundcolor','red')
                
            elseif ~isfield(headmodelfile,'GridLoc')
                fprintf(2,'HEADMODEL FILE MISSING SOURCE LOCATIONS\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.headmodelfile,'backgroundcolor','red')
                
            elseif ~isequal(size(headmodelfile.Gain,2)/3,size(cortexfile.Vertices,1))
                fprintf(2,'INCONSISTENT # OF DIPOLES IN HEADMODEL AND CORTEX\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.headmodelfile,'backgroundcolor','red')
                
            elseif ~isequal(headmodelfile.GridLoc,cortexfile.Vertices)
                fprintf(2,'HEADMODEL AND CORTEX DO NOT HAVE SAME SOURCE LOCATIONS\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.headmodelfile,'backgroundcolor','red')
                
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK fMRI PRIOR
    fmrifile=get(handles.fmrifile,'string');
    set(handles.fmrifile,'backgroundcolor','green')
    if isempty(fmrifile)
        set(handles.fmrifile,'backgroundcolor','white')
    else
        if ~exist(fmrifile,'file')
            fprintf(2,'FMRI FILE DOES NOT EXIST\n');
            set(handles.fmrifile,'backgroundcolor','red')
            set(hObject,'backgroundcolor','red','userdata',0)
            
        elseif ~strcmp(fmrifile(end-2:end),'gii')
            fprintf(2,'FMRI RESULTS NOT .GII FORMAT\n');
            set(handles.fmrifile,'backgroundcolor','red')
            set(hObject,'backgroundcolor','red','userdata',0)
            
        else
            fmrifile=gifti(fmrifile);
            if ~isfield(fmrifile,'cdata')
                fprintf(2,'FMRI PRIOR FILE MISSING DATA\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.fmrifile,'backgroundcolor','red')
                
            elseif ~isfield(fmrifile,'faces')
                fprintf(2,'FMRI PRIOR FILE MISSING FACES\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.fmrifile,'backgroundcolor','red')
                
            elseif ~isfield(fmrifile,'vertices')
                fprintf(2,'FMRI PRIOR FILE MISSING VERTICES\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.fmrifile,'backgroundcolor','red')
                
            elseif ~isequal(size(fmrifile.vertices,1),size(cortexfile.Vertices,1))
                fprintf(2,'INCONSISTENT # OF DIPOLES IN FMRI PRIOR AND CORTEX\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.fmrifile,'backgroundcolor','red')
                
            elseif ~isequal(fmrifile.faces,cortexfile.Faces)
                fprintf(2,'FMRI PRIOR AND CORTEX DO NOT HAVE SAME SOURCE LOCATIONS\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.fmrifile,'backgroundcolor','red')
                
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK BRAIN REGIONS
    brainregions=get(handles.selectbrainregions,'userdata');
    set(handles.selectbrainregions,'backgroundcolor','green')
    if isempty(brainregions) || isequal(sum(brainregions),0)
        fprintf(2,'NO BRAIN REGIONS SELECTED\n');
        set(handles.selectbrainregions,'backgroundcolor','red');
        set(hObject,'backgroundcolor','red','userdata',0); 
    end
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK PARCELLATION
    parcellation=get(handles.parcellation,'value');
    set(handles.parcellation,'backgroundcolor','green');
    switch parcellation
        case 1 % None
            
        case 2 % MSP
            
            set(handles.parcellation,'backgroundcolor','green')
            data=get(handles.esifiles,'data');
            files=cellstr(data(:,2));
            idx=data(:,1);
            for i=1:size(idx,1)
                if islogical(idx{i}); idx{i}=+idx{i}; end
            end
            idx=cell2mat(idx);
            esifiles=files(idx==1);

            for i=size(esifiles,1):-1:1
                if strcmp(esifiles{i},{''})
                    esifiles(i)=[];
                end
            end
            
            if isempty(esifiles) %|| strcmp(esifiles,'')
                fprintf(2,'NO ESI FILES UPLOADED - CANNOT PERFORM MSP PARCELLATION\n');
                set(hObject,'backgroundcolor','red','userdata',0)
                set(handles.parcellation,'backgroundcolor','red')
            else

                numfiles=size(esifiles,1);
                % Extract training file name parts
                for i=1:numfiles
                    [filepath{i},filename{i},fileext{i}]=fileparts(esifiles{i});
                end

                % Check training file compatibility (either .dat or .mat)
                for i=1:numfiles
                    if ~strcmp(fileext{i},'.dat') && ~strcmp(fileext{i},'.mat')
                        fprintf(2,'TRAINING FILE %s NOT .Dat or .mat (%s)\n',num2str(i),fileext{i});
                        set(hObject,'backgroundcolor','red','userdata',0)
                    end
                end

                % Check training file consistency (all same file type)
                combinations=combnk(1:numfiles,2);
                for i=1:combinations
                    if ~strcmp(fileext{combinations(i,1)},fileext{combinations(i,2)});
                        fprintf(2,'INCONSISTENCY AMONG TRAINING FILE FORMAT\n');
                        set(hObject,'backgroundcolor','red','userdata',0)
                    end
                end
                
                filetype=unique(fileext);
                handles.ESI.CLUSTER.esifiletype=filetype;

            end
            
        case 3 % K-means
            set(handles.esifiles,'backgroundcolor','white')
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CHECK CUSTOM ROI
    roifile=get(handles.roifile,'string');
    [filepath,filename,fileext]=fileparts(roifile);
    if ~isempty(roifile) || ~isempty(filepath) && ~isempty(filename) && ~isempty(fileext)
        
        if strcmp(fileext,'.mat') % Brainstorm scout file
            
            roi=load(roifile);
            if ~isfield(roi,'Scouts')
                fprintf(2,'ROI FILE MUST CONTAIN "SCOUTS" - IDENTIFYING REGIONS\n');
                set(handles.roifile,'backgroundcolor','red')
            elseif ~isfield(roi.Scouts,'Label')
                fprintf(2,'ROI FILE MUST CONTAIN LABELS\n');
                set(handles.roifile,'backgroundcolor','red')
            end
            
        elseif strcmp(fileext,'.gii') % fMRI derived ROI
            roi=gifti(roifile);
            %%% FILL IN
        else
            fprintf(2,'ROI FILE MUST BE OF .MAT OR .GII FORMAT, USING SELECTED PREDEFINED BRAIN REGIONS AS GENERAL ROIS\n');
            set(handles.roifile,'backgroundcolor','white')
        end
        
    else
        
        fprintf(2,'   NO ROI FILE LOADED, USING SELECTED PREDEFINED BRAIN REGIONS AS GENERAL ROIS\n');
        set(handles.roifile,'backgroundcolor','white')
        
    end
    
else
    fprintf(2,'SYSTEM PARAMETERS HAVE NOT BEEN SET\n');
    set(hObject,'Backgroundcolor','red')
end











