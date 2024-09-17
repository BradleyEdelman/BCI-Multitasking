function [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,spatdomain,feattype,tempdomain)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 REMOVE ALL FEATURES FROM A SPATIAL DOMAIN               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(spatdomain)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                REMOVE ALL TIME AND FREQUENCY FEATURES               %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(tempdomain)
        
        set(handles.timefeat,'string','','value',1)
        set(handles.timefeatwindow,'backgroundcolor','white','string','Win','value',1)
        set(handles.timefeatlambda,'backgroundcolor','white','string','Lambda','value',1)
        set(handles.timefeatpc,'backgroundcolor','white','string','PC','value',1)
        set(handles.freqfeat,'string','','value',1)
        set(handles.freqfeatfreq,'backgroundcolor','white','string','Freq','value',1)
        set(handles.freqfeatlambda,'backgroundcolor','white','string','Lambda','value',1)
        set(handles.freqfeatpc,'backgroundcolor','white','string','PC','value',1)
        
        % REMOVE OPTIONS FROM SPATIAL DOMAIN FEATURES
        for i=1:3
            featvar=strcat('bcifeat',num2str(i));
            set(handles.(featvar),'string',handles.BCI.featureoptions.feat.Sensor,'value',1)

            freqvar=strcat('bcifreq',num2str(i));
            set(handles.(freqvar),'string',handles.BCI.featureoptions.freq.Sensor,'value',1)

            taskvar=strcat('bcitask',num2str(i));
            set(handles.(taskvar),'string',handles.BCI.featureoptions.task.Sensor,'value',1)

            [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,i,'Reset');
        end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                       REMOVE ALL TIME FEATURES                      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif strcmp(tempdomain,'Time')
        
        set(handles.timefeat,'string','','value',1)
        set(handles.timefeatwindow,'backgroundcolor','white','string','Win','value',1)
        set(handles.timefeatlambda,'backgroundcolor','white','string','Lambda','value',1)
        set(handles.timefeatpc,'backgroundcolor','white','string','PC','value',1)
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                    REMOVE ALL FREQUENCY FEATURES                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif strcmp(tempdomain,'Freq')
        
        set(handles.timefeat,'string','','value',1)
        set(handles.timefeatwindow,'backgroundcolor','white','string','Win','value',1)
        set(handles.timefeatlambda,'backgroundcolor','white','string','Lambda','value',1)
        set(handles.timefeatpc,'backgroundcolor','white','string','PC','value',1)
        
    end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                REMOVE ALL FEATURES FROM A TEMPORAL DOMAIN               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
else

    if isempty(feattype) || ismember(feattype,{'Regress','Mahal','RLDA','PCA'})

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                   IDENTIFY KEYWORD TO REMOVE                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % REMOVE ALL SENSOR/SOURCE FEATURES IN A TEMPORAL DOMAIN
        if isempty(feattype)
            removekeyword=spatdomain;
        
        % REMOVE SPECIFIC SENSOR/SOURCE FEATURES IN A TEMPORAL DOMAIN
        else
            removekeyword=[feattype ' ' spatdomain];
        end
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                        TIME DOMAIN ONLY                         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmp(tempdomain,'Time')

            timefeat=cell(get(handles.timefeat,'string'));
            for i=size(timefeat,1):-1:1
                if ~isempty(strfind(timefeat{i},removekeyword))
                    timefeat(i)=[];
                end
            end
            set(handles.timefeat,'string',timefeat,'value',1);
            
            % RESET LAMBDA OPTIONS FOR RLDA
            if strcmp(feattype,'RLDA') || isempty(feattype)
                set(handles.timefeatlambda,'backgroundcolor','white','string','Lambda','value',1)
            end
            
            % RESET PC OPTIONS FOR PCA
            if strcmp(feattype,'PCA') || isempty(feattype)
                set(handles.timefeatpc,'backgroundcolor','white','string','PC','value',1)
            end
            
            % RESET TIME WINDOW OPTIONS FOR TIME DOMAIN FEAUTRES
            set(handles.timefeatwindow,'backgroundcolor','white','string','Win','value',1)
                
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                      FREQUENCY DOMAIN ONLY                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        elseif strcmp(tempdomain,'Freq')
            
            freqfeat=cell(get(handles.freqfeat,'string'));
            for i=size(freqfeat,1):-1:1
                if ~isempty(strfind(freqfeat{i},removekeyword))
                    freqfeat(i)=[];
                end
            end
            set(handles.freqfeat,'string',freqfeat,'value',1);
            
            % RESET LAMBDA OPTIONS FOR RLDA
            if strcmp(feattype,'RLDA') || isempty(feattype)
                set(handles.freqfeatlambda,'backgroundcolor','white','string','Lambda','value',1)
            end
            
            % RESET PC OPTIONS FOR PCA
            if strcmp(feattype,'PCA') || isempty(feattype)
                set(handles.freqfeatpc,'backgroundcolor','white','string','PC','value',1)
            end
            
            % RESET FREQUENCY OPTIONS FOR FREQUENCY DOMAIN FEAUTRES
            set(handles.freqfeatfreq,'backgroundcolor','white','string','Freq','value',1)

            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    TIME AND FREQUENCY DOMAIN                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        elseif isempty(tempdomain)

            timefeat=cell(get(handles.timefeat,'string'));
            for i=size(timefeat,1):-1:1
                if ~isempty(strfind(timefeat{i},removekeyword))
                    timefeat(i)=[];
                end
            end
            set(handles.timefeat,'string',timefeat,'value',1);

            freqfeat=cell(get(handles.freqfeat,'string'));
            for i=size(freqfeat,1):-1:1
                if ~isempty(strfind(freqfeat{i},removekeyword))
                    freqfeat(i)=[];
                end
            end
            set(handles.freqfeat,'string',freqfeat,'value',1);
            
            % RESET LAMBDA OPTIONS FOR RLDA
            if strcmp(feattype,'RLDA') || isempty(feattype)
                set(handles.freqfeatlambda,'backgroundcolor','white','string','Lambda','value',1)
                set(handles.timefeatlambda,'backgroundcolor','white','string','Lambda','value',1)
            end
            
            % RESET TIME WINDOW OPTIONS FOR TIME DOMAIN FEAUTRES
            set(handles.timefeatwindow,'backgroundcolor','white','string','Win','value',1)
            
            % RESET FREQUENCY OPTIONS FOR FREQUENCY DOMAIN FEAUTRES
            set(handles.freqfeatfreq,'backgroundcolor','white','string','Freq','value',1)

        end

    else
        
    end
    
end