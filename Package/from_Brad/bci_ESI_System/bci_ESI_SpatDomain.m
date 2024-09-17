function [hObject,handles]=bci_ESI_SpatDomain(hObject,handles)


spatdomain=get(handles.spatdomain,'value');
switch spatdomain
    
    case 1 % None
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % TURN OFF ALL FIELDS
        fields={'initials','session','run','year','month','day',...
            'savepath','tempdomain','eegsystem','fs','freqtrans',...
            'lowcutoff','highcutoff','dsfactor','analysiswindow',...
            'updatewindow','defaultanatomy','cortexfile','cortexlrfile',...
            'headmodelfile','fmrifile','fmriweight','brainregionfile',...
            'roifile','parcellation','noise','noisefile',...
            'vizsource','lrvizsource'};
        
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'off');
        
        
    case 2 % Sensor
        
        handles.TRAINING.spatdomainfield='Sensor';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % CHECK FOR REQUIRED SENSOR FIELDS
        fields={'initials','session','run','year','month','day',...
            'savepath','tempdomain','eegsystem','fs','freqtrans',...
            'lowcutoff','highcutoff','dsfactor','analysiswindow',...
            'updatewindow'};
        
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'on');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % TURN ESI FIELDS OFF
        fields={'cortexfile','cortexlrfile',...
            'headmodelfile','fmrifile','fmriweight','brainregionfile',...
            'roifile','parcellation','noise','noisefile',...
            'vizsource','lrvizsource'};
        
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'off');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % REPOPULATE BCI OPTIONS FOR CURRENT DOMAIN IF THEY EXIST
        for i=1:3
            featvar=strcat('bcifeat',num2str(i));
            set(handles.(featvar),'string',handles.BCI.featureoptions.feat.Sensor)
            
            freqvar=strcat('bcifreq',num2str(i));
            set(handles.(freqvar),'string',handles.BCI.featureoptions.freq.Sensor)
            
            taskvar=strcat('bcitask',num2str(i));
            set(handles.(taskvar),'string',handles.BCI.featureoptions.task.Sensor)
            
            [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,i,'Reset');
        end
        

    case 3 % ESI
        
        handles.TRAINING.spatdomainfield='Source';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % CHECK FOR REQUIRED ESI FIELDS
        fields={'initials','session','run','year','month','day',...
            'savepath','tempdomain','eegsystem','fs','freqtrans',...
            'lowcutoff','highcutoff','dsfactor','analysiswindow',...
            'updatewindow','defaultanatomy','cortexfile','cortexlrfile',...
            'headmodelfile','fmriweight','brainregionfile','parcellation',...
            'noise','vizsource','lrvizsource'};
        
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'on');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % HIGHLIGHT OPTIONAL ESI FIELDS
        fields={'fmrifile','roifile','noisefile'};
        
        [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'option');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % A FEW SPECIFIC CASES
        parcellation=get(handles.parcellation,'value');
        if ismember(parcellation,[2,3])
%             [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'esifiles'},'on');
            handles.TRAINING.spatdomainfield='SourceCluster';
%         else
%             [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'esifiles'},'off');
        end
        
        noise=get(handles.noise,'value');
        set(handles.noisefile,'string','')
        if ismember(noise,[3,4])
            [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'noisefile'},'on');
        else
            [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'noisefile'},'off');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % REPOPULATE BCI OPTIONS FOR CURRENT DOMAIN IF THEY EXIST 
        for i=1:3
            
            featvar=strcat('bcifeat',num2str(i));
            freqvar=strcat('bcifreq',num2str(i));
            taskvar=strcat('bcitask',num2str(i));
            
            parcellation=get(handles.parcellation,'value');
            if isequal(parcellation,1)
                set(handles.(featvar),'string',handles.BCI.featureoptions.feat.Source)
                set(handles.(freqvar),'string',handles.BCI.featureoptions.freq.Source)
                set(handles.(taskvar),'string',handles.BCI.featureoptions.task.Source)
            else
                set(handles.(featvar),'string',handles.BCI.featureoptions.feat.SourceCluster)
                set(handles.(freqvar),'string',handles.BCI.featureoptions.freq.SourceCluster)
                set(handles.(taskvar),'string',handles.BCI.featureoptions.task.SourceCluster)
            end
            
            [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,i,'Reset');
        end

        
end