function [hObject,handles]=bci_ESI_DispFreqFeat2(hObject,handles)

freqfeatidx=get(handles.freqfeat,'value');
freqfeatstr=get(handles.freqfeat,'string');
set(hObject,'userdata',1);

% CHECK IF REGRESSION VARIABLE LIST IS POPULATED
if ~isempty(freqfeatstr)
    
    displayvar=freqfeatstr{freqfeatidx};
    
    % CHECK IF A VISUALIZATION METHOD IS SELECTED
    allfreq=0;
    % IDENTIFY FREQUENCY FOR DISPLAY
    freqfeatfreq=get(handles.freqfeatfreq,'value');
    set(handles.freqfeatfreq,'backgroundcolor','white')
    if isequal(freqfeatfreq,1) % None selected ("Frequency")
        fprintf(2,'MUST SELECT A FREQUENCY ANALYSIS RESULT TO VISUALIZE RESULTS\n');
        set(handles.freqfeatfreq,'backgroundcolor','red');
        freqidx=nan;
    elseif isequal(freqfeatfreq,2) % ("All")
        freqidx=nan;
        allfreq=1;
    else % Numerical
        freqidx=freqfeatfreq-2;
    end
    freqvect=handles.SYSTEM.lowcutoff:handles.SYSTEM.highcutoff;

    if isequal(allfreq,1) || ~isnan(freqidx)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PLOT DESIRED RESULT
        
        % DETERMINE SPATIAL DOMAIN OF FEATURES
        if ~isequal(size(strfind(displayvar,'SourceCluster'),2),0)
            spatdomainfield='SourceCluster';
        elseif ~isequal(size(strfind(displayvar,'Source'),2),0)
            spatdomainfield='Source';
        elseif ~isequal(size(strfind(displayvar,'Sensor'),2),0)
            spatdomainfield='Sensor';
        else
            set(hObject,'userdata',0)
        end
        
        % DETERMINE FEATURE TYPE
        if ~isequal(size(strfind(displayvar,'Regress'),2),0)
            feattype='regress';
        elseif ~isequal(size(strfind(displayvar,'Mahal'),2),0)
            feattype='mahal';
        elseif ~isequal(size(strfind(displayvar,'RLDA'),2),0)
            feattype='rlda';
        elseif ~isequal(size(strfind(displayvar,'PCA'),2),0)
            feattype='pca';
        elseif ~isequal(size(strfind(displayvar,'FDA'),2),0)
            feattype='fda';
        else
            set(hObject,'userdata',1);
        end
        
        if isequal(get(hObject,'userdata'),1)
                
            % IDENTIFY ONE-vs-REST, ONE-vs-ONE, or ONE-vs-ALL
            taskidx=str2double(regexp(displayvar,'.\d+','match'));
            vartype=1;
            if ~isempty(strfind(displayvar,'Rest'))
            elseif size(taskidx,2)>1
                for i=1:size(handles.TRAINING.(spatdomainfield).features.freq.(feattype).label{2},1)
                    if isequal(taskidx,str2num(handles.TRAINING.(spatdomainfield).features.freq.(feattype).label{2}(i,:)))
                        taskidx=i;
                    end
                end
                vartype=2;
            elseif ~isempty(strfind(displayvar,'All'))
                vartype=3;
            end
                
            if ~exist(handles.TRAINING.(spatdomainfield).features.freq.(feattype).file{vartype},'file')
                freqfeatstr(freqfeatidx)=[];
                set(handles.FreqFeat,'string',freqfeatstr,'value',size(freqfeatstr,1));
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                fprintf(2,'SAVED FEATURE FILE DOES NOT EXIST FOR TASK "%s"\n',freqfeatstr{freqfeatidx});
            else
                load(handles.TRAINING.(spatdomainfield).features.freq.(feattype).file{vartype});