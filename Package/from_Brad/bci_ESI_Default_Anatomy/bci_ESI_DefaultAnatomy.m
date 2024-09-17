function [hObject,handles]=bci_ESI_DefaultAnatomy(hObject,handles)

if ~isempty(handles.SYSTEM.rootdir)

    rootdir=handles.SYSTEM.rootdir;
    
    value=get(hObject,'value');
    if isequal(value,1)
        cortexfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Cortex15000V.mat');
        if exist(cortexfile,'file')
            set(handles.cortexfile,'String',cortexfile)
        else
            fprintf(2,'CORTEX FILE DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n'); 
        end

        cortexlrfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_InflateCortex1000V.mat');
        if exist(cortexlrfile,'file')
            set(handles.cortexlrfile,'String',cortexlrfile)
        else
            fprintf(2,'INFLATED CORTEX FILE DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n'); 
        end

        brainregionfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_BrainRegions.mat');
        if exist(brainregionfile,'file')
            set(handles.brainregionfile,'String',brainregionfile)
        else
            fprintf(2,'BRAIN REGIONS FILE DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n'); 
        end

        eegsystem=get(handles.eegsystem,'value');
        switch eegsystem
            case 1 % None
                fprintf(2,'MUST SELECT AN EEG SYSTEM IN ORDER TO LOAD DEFAULT HEAD MODEL\n');
            case 2 % Neuroscan 64
                headmodelfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Headmodel_NSL64.mat');
                if exist(headmodelfile,'file');
                    set(handles.headmodelfile,'String',headmodelfile);
                else
                    fprintf(2,'HEADMODEL FOR NS64 DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n');
                end
            case 3 % Neuroscan 128
                headmodelfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Headmodel_NSL128.mat');
                if exist(headmodelfile,'file');
                    set(handles.headmodelfile,'String',headmodelfile);
                else
                    fprintf(2,'HEADMODEL FOR NS128 DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n');
                end
            case 4 % BioSemi 64
                headmodelfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Headmodel_BS64.mat');
                if exist(headmodelfile,'file');
                    set(handles.headmodelfile,'String',headmodelfile);
                else
                    fprintf(2,'HEADMODEL FOR BS64 DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n');
                end
            case 5 % BioSemi 128
                headmodelfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Headmodel_BS128.mat');
                if exist(headmodelfile,'file');
                    set(handles.headmodelfile,'String',headmodelfile);
                else
                    fprintf(2,'HEADMODEL FOR BS128 DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n');
                end
            case 6 % SigGen
                headmodelfile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Headmodel_SG16.mat');
                if exist(headmodelfile,'file');
                    set(handles.headmodelfile,'String',headmodelfile);
                else
                    fprintf(2,'HEADMODEL FOR SG16 DOES NOT EXIST IN DEFAULT ANATOMY DIRECTORY\n');
                end
        end

    else

        if isfield(handles,'default')
            if isfield(handles.default,'cortexfile')
                set(handles.cortexfile,'String',handles.default.cortexfile);
            end

            if isfield(handles.default,'cortexlrfile')
                set(handles.cortexlrfile,'String',handles.default.cortexlrfile);
            end

            if isfield(handles.default,'headmodelfile')
                set(handles.headmodelfile,'String',handles.default.headmodelfile);
            end

            if isfield(handles.default,'fmrifile')
                set(handles.fmrifile,'String',handles.default.fmrifile);
            end

            if isfield(handles.default,'brainregionfile')
                set(handles.brainregionfile,'String',handles.default.brainregionfile);
            end

        else
            set(handles.cortexfile,'String','');
            set(handles.cortexlrfile,'String','');
            set(handles.headmodelfile,'String','');
            set(handles.fmrifile,'String','');
            set(handles.brainregionfile,'String','');
        end

    end
    
else
end