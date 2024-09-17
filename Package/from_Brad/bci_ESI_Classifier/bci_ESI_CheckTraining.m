function [hObject,handles]=bci_ESI_CheckTraining(hObject,handles,sigtype)

set(hObject,'backgroundcolor','green','userdata',1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        CHECK UNIVERSAL PARAMETERS                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK IF SYSTEM PARAMETERS HAVE BEEN SET
SetSystem=get(handles.SetSystem,'userdata');
if isequal(SetSystem,0)
    fprintf(2,'\nSYSTEM PARAMETERS NOT SET\n');
    set(hObject,'backgroundcolor','red','userdata',0);
end


% CHECK IF SPATIAL DOMAIN HAS BEEN SELECTED 
spatdomain=get(handles.spatdomain,'value');
switch spatdomain
    case 1 % None Selected
        
        fprintf(2,'\nSPATIAL DOMAIN NOT SELECTED\n');
        set(hObject,'backgroundcolor','red','userdata',0);
        spatdomainfield='';
        
    case 2 % Sensor
        
        spatdomainfield='Sensor';
        
    case 3 % ESI
        
        % CHECK IF ESI PARAMETERS HAVE BEEN SET
        SetESI=get(handles.SetESI,'userdata');
        if isequal(SetESI,0)
            fprintf(2,'\nESI PARAMETERS NOT SET\n');
            set(hObject,'backgroundcolor','red','userdata',0);
        end
        
        parcellation=get(handles.parcellation,'value');
        if isequal(parcellation,1)
            spatdomainfield='Source';
        else
            spatdomainfield='SourceCluster';
        end
        
end





if isequal(get(hObject,'value'),1)

    handles.TRAINING.spatdomainfield=spatdomainfield;

    % CHECK IF CLASSIFIER HAS BEEN SELECTED
    traintype=get(handles.traintype,'value');
    if isequal(traintype,1)
        fprintf(2,'\nCLASSIFIER TYPE NOT SELECTED\n');
        set(hObject,'backgroundcolor','red','userdata',0);
    end
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'traintype'},'on');

    % CHECK IF DECODING SCHEME HAS BEEN SELECTED
    decodescheme=get(handles.decodescheme,'value');
    switch decodescheme
        case 1 % None
            fprintf(2,'MUST SELECT A DECODING SCHEME\n');
            set(hObject,'backgroundcolor','red','userdata',0);
        case 2 % Single Trial
            fprintf(2,'   TRAINING SET UP FOR SINGLE TRIAL DECODING\n');
        case 3 % Time Resolved
            fprintf(2,'   TRAINING SET UP FOR TIME RESOLVED DECODING\n');
    end
    handles.TRAINING.(spatdomainfield).(sigtype).param.decodescheme=decodescheme;
    [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,{'decodescheme'},'on');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                   CHECK SIGNAL SPECIFIC PARAMETERS                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch sigtype
        case 'SMR'

            % CHECK IF NORMALIZATION PARAMETERS HAVE BEEN SET
            normtype=get(handles.normtype,'value');
            baselinetype=get(handles.baselinetype,'value');
            if isequal(normtype,1) || isequal(baselinetype,1)

                fields={'normtype','baselinetype','baselinestart','baselineend'};
                [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'off');

            else
                
                baselinestart=str2double(get(handles.baselinestart,'string'));
                if isnan(baselinestart)
                    fprintf(2,'\nMUST DEFINE A BASELINE STARTING TIME POINT\n');
                    set(hObject,'backgroundcolor','red','userdata',0);
                else
                    handles.TRAINING.(spatdomainfield).(sigtype).param.baselinestart=baselinestart;
                end

                baselineend=str2double(get(handles.baselineend,'string'));
                if isnan(baselineend)
                    fprintf(2,'\nMUST DEFINED A BASELINE ENDING TIME POINT\n');
                    set(hObject,'backgroundcolor','red','userdata',0)
                else
                    handles.TRAINING.(spatdomainfield).(sigtype).param.baselineend=baselineend;
                end

                fields={'normtype','baselinetype','baselinestart','baselineend'};
                [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,'on');

            end
            handles.TRAINING.(spatdomainfield).(sigtype).param.normtype=normtype;
            handles.TRAINING.(spatdomainfield).(sigtype).param.baselinetype=baselinetype;

        case 'SSVEP'




    end
    
end



