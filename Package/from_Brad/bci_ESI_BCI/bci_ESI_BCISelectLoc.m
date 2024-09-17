function [hObject,handles]=bci_ESI_BCISelectLoc(hObject,handles,Dimension,sigtype)

set(hObject,'backgroundcolor',[.94 .94 .94])

Go=1;
% Specify handle in which to store the locations and weights
handles.BCILoc.CurrentObj=strcat('bciloc',num2str(Dimension));
currentobj=handles.BCILoc.CurrentObj;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IDENTIFY SPATIAL DOMAIN
spatdomainfield=handles.TRAINING.spatdomainfield;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IDENTIFY TEMPORAL DOMAIN
tempdomain=get(handles.tempdomain,'value');
switch tempdomain
    case 1 % None
    case 2 % Frequency
        TempDomainField='freq';
    case 3 % Time
        TempDomainField='time';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT SELECTED FREQUENCY
broadband=handles.SYSTEM.broadband;
numfreq=handles.SYSTEM.mwparam.numfreq;
dimfreq=strcat('bcifreq',num2str(Dimension));
freqval=get(handles.(dimfreq),'value');
if isequal(freqval,1); Go=0; end
if isequal(broadband,1)
    freqidx=numfreq+1;
else
    freqidx=freqval-1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT SELECTED TASK PAIRING
dimtask=strcat('bcitask',num2str(Dimension));
taskoptions=cellstr(get(handles.(dimtask),'string'));
taskval=get(handles.(dimtask),'value');
if isequal(taskval,1); Go=0; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT SELECTED FEATURE
dimfeat=strcat('bcifeat',num2str(Dimension));
featoptions=cellstr(get(handles.(dimfeat),'string'));
featval=get(handles.(dimfeat),'value');
if isequal(featval,1); Go=0; end
feattype=featoptions{featval};
if strcmp(feattype,'Custom')
    feattype='custom';
    title='Custom';
elseif strcmp(feattype,'RLDA')
    feattype='rlda';
    title='RLDA Weights';
elseif strcmp(feattype,'Regress')
    feattype='regress';
    title='Regression R-squared values';
elseif strcmp(feattype,'PCA')
    feattype='pca';
    title='PCA Filters';
elseif strcmp(feattype,'FDA')
    feattype='fda';
    title='FDA Weights';
elseif strcmp(feattype,'MI')
    feattype='mi';
    title='Mutual Information';
elseif strcmp(feattype,'Mahal')
    feattype='mahal';
    title='Mahalanobis Distance';
end


if isequal(Go,1)
    
    if strcmp(feattype,'custom')
        
        % Create figure
        handles.BCILocFig=figure;
        set(handles.BCILocFig,'MenuBar','none','ToolBar','none','color',[.94 .94 .94]);
        rotate3d off
        
        % Figure title
        uicontrol('Style','text','string',title,...
            'Position',[110 395 340 25],'FontSize',13.5);
        
        % Assigned plotting axes
        handles.BCILocAxes=axes('Parent',handles.BCILocFig,'Units','pixels',...
            'HandleVisibility','callback','Position',[7.5 30 372.5 365]); axis off
        
        % Close button
        uicontrol('Style','pushbutton','string','Save & Close','Position',...
            [10 10 125 20],'Callback','close');
        
        data=repmat({''},10,2);
        handles.table=uitable('position',[400 115 160 200],'Data',data,'ColumnName',...
            {'Name/#','Weight'},'ColumnWidth',{50,50},...
            'ColumnEditable',true(1,2),'ColumnFormat',{'char','char'},'CellEditCallback',@myCheckCustom);
        
        % Set empty weight matrix if none others exist
        if isempty(get(handles.(currentobj),'userdata'))
            set(handles.(currentobj),'userdata',[]);
        elseif isequal(size(get(handles.(currentobj),'userdata'),2),2)
            userdata=get(handles.(currentobj),'userdata');
            numidx=find(~isnan(userdata));
            for i=1:size(numidx(:),1)
                data{numidx(i)}=num2str(userdata(numidx(i)));
            end
            set(handles.table,'data',data);
        end
        
        switch spatdomainfield
            case 'Sensor'
                
                % select default channels for specific dimensional control
                btn1=uicontrol('style','pushbutton','String','Default Loc/Weight','Position',...
                    [145 10 130 20],'Callback',@myDefaultSensor);
                
                eLoc=handles.SYSTEM.Electrodes.current.eLoc;
                % Plot allcurrent channels
                topoplot([],eLoc,'electrodes','ptlabels');
                set(handles.BCILocFig,'color',[.94 .94 .94]);
                
            case 'Source'
                
                [hObject,handles]=bci_ESI_DispSaved(hObject,handles,'Cortex',handles.BCILocAxes);
                fprintf(2,'CANNOT SELECT CUSTOM LOCATIONS IN UNCLUSTERED SOURCE SPACE\n');
                
            case 'SourceCluster'
                
                [hObject,handles]=bci_ESI_DispSaved(hObject,handles,'Clusters',handles.BCILocAxes);
                 % select default channels for specific dimensional control
                btn1=uicontrol('style','pushbutton','String','Default Loc/Weight','Position',...
                    [145 10 130 20],'Callback',@myDefaultSource);
                
        end

        guidata(handles.BCILocFig,handles)
        
    else

        numtask=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.numtask;
        combinations=combnk(1:numtask,2);
        numcomb=size(combinations,1);

        taskname=taskoptions{taskval};
        taskind=str2double(regexp(taskname,'\d+','match'));

        % Determine which feature file to upload
        if strcmp(taskname,'Custom')
            fileidx=[];
        else
            fileidx=2; % One-vs-One
        end
        handles.BCILoc.fileidx=fileidx;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % CHECK IF FEATURE FILE EXISTS
        if ~isempty(handles.TRAINING.(spatdomainfield).(sigtype).(TempDomainField).(feattype).file) &&...
                ~isempty(handles.TRAINING.(spatdomainfield).(sigtype).(TempDomainField).(feattype).label) &&...
                ~isempty(fileidx)

            % Load one-vs-one feature file
            load(handles.TRAINING.(spatdomainfield).(sigtype).(TempDomainField).(feattype).file{fileidx});

            if isequal(fileidx,1)

                taskidx=taskind;

            elseif isequal(fileidx,2)

                for i=1:size(handles.TRAINING.(spatdomainfield).(sigtype).(TempDomainField).(feattype).label{2},1)
                    if isequal(taskind,str2num(handles.TRAINING.(spatdomainfield).(sigtype).(TempDomainField).(feattype).label{2}(i,:)))
                        % Identify task pairing index within saved data structure
                        taskind=i;
                        % identify numerical task pairings
                        taskidx=str2num(handles.TRAINING.(spatdomainfield).(sigtype).(TempDomainField).(feattype).label{2}(taskind,:));
                    end
                end

            end

            % Create figure
            handles.BCILocFig=figure;
            set(handles.BCILocFig,'MenuBar','none','ToolBar','none','color',[.94 .94 .94]);
            rotate3d on

            % Figure title
            uicontrol('Style','text','string',title,...
                'Position',[110 395 340 25],'FontSize',13.5);

            % Assigned plotting axes
            handles.BCILocAxes=axes('Parent',handles.BCILocFig,'Units','pixels',...
                'HandleVisibility','callback','Position',[15 50 530 325]);
            axis off

            % Close button
            uicontrol('Style','pushbutton','string','Save & Close','Position',...
                [10 10 125 20],'Callback','close');

            handles.BCILoc.taskind=taskind;
            handles.BCILoc.freqidx=freqidx;
            switch feattype
                case 'rlda'

                    % Lambda label
                    uicontrol('Style','text','string','Lambda','Position',...
                        [355 8 60 20],'FontSize',10);

                    % Pop-up menu for different lambda value
                    lambda=cellstr(num2str(handles.TRAINING.(spatdomainfield).(sigtype).param.lambda'));
                    handles.popup=uicontrol('Style','popup','string',lambda,...
                        'Position',[415 12.5 50 20]);

                    % Update button
                    uicontrol('Style','pushbutton','string','Update','Position',...
                        [480 10 75 20],'Callback',@myRLDAUpdate);

                    % Set lambda as lowest value if it doesnt already exist
                    if isempty(get(handles.(currentobj),'userdata'))
                        set(handles.(currentobj),'userdata',1);
                        set(handles.popup,'value',1);
                        lambdatmp=1;
                    elseif isequal(size(get(handles.(currentobj),'userdata'),2),2)
                        userdata=get(handles.(currentobj),'userdata');
                        lambdatmp=userdata(1);
                        set(handles.(currentobj),'userdata',userdata(1));
                        set(handles.popup,'value',userdata(1));
                    else
                        userdata=get(handles.(currentobj),'userdata');
                        set(handles.popup,'value',userdata);
                        lambdatmp=userdata;
                    end

                    % Switch between selected tasks for One-vs-Rest condition
                    if isequal(fileidx,1)

                        % Pop-up menu for viewing different tasks under same lamba
                        TaskStr=['Task ' num2str(taskind(1));'Task ' num2str(taskind(2))];
                        handles.taskselect=uicontrol('Style','popup','string',...
                            TaskStr,'Position',[270 12.5 75 20],'Callback',...
                            @myRLDASwitchTask);

                        % Task switch label
                        uicontrol('Style','text','string','Display Task',...
                            'Position',[185 8 80 20]);

                    end

                    switch spatdomainfield
                        case 'Sensor'

                            W=SaveRLDASensor.W(:,freqidx,taskind,:);
                            handles.BCILoc.W=W;
                            handles.BCILoc.clusters=[];

                            Wtmp=W(:,:,1,lambdatmp);
                            PlotSensor(Wtmp,handles);

                        case 'Source'

                            W=SaveRLDASource.W(:,freqidx,taskind,:); 
                            handles.BCILoc.W=W;
                            handles.BCILoc.clusters=[];

                            Wtmp=W(:,:,1,lambdatmp);
                            PlotBrain(Wtmp,handles);

                        case 'SourceCluster'

                            W=SaveRLDASourceCluster.W(:,freqidx,taskind,:);
                            handles.BCILoc.W=W;
                            clusters=SaveRLDASourceCluster.clusters;
                            handles.BCILoc.clusters=clusters;
                            Wtmp=W(:,:,1,lambdatmp);

                            PlotClusters(Wtmp,handles);

                    end

                case 'regress'

                    % p-value label
                    uicontrol('Style','text','string','p-value Threshold','Position',...
                        [290 8 125 20],'FontSize',10);

                    % Text box for different p-value thresholds
                    handles.edit1=uicontrol('Style', 'edit','string','1',...
                        'Position',[415 10 50 20],'backgroundcolor','white',...
                        'Callback',@myEnterNum);

                    % Update button
                    uicontrol('Style','pushbutton','string','Update','Position',...
                        [480 10 75 20],'Callback',@myRegressUpdate);

                    % Updated R-squared value (multiple regression)
                    handles.edit2=uicontrol('Style','edit','string','',...
                        'Position',[415 32.5 50 20],'backgroundcolor',[.94 .94 .94]);

                    % R-squared value label
                    uicontrol('Style','text','string','R-squared','Position',...
                        [343.5 32.5 60 20],'FontSize',10)

                    switch spatdomainfield
                        case 'Sensor'

                            Rsq=SaveRegressSensor.Rsq(:,freqidx,taskind,:);
                            pval=SaveRegressSensor.pval(:,freqidx,taskind,:);
                            handles.BCILoc.Rsq=Rsq;
                            handles.BCILoc.pval=pval;
                            handles.BCILoc.clusters=[];

                            PlotSensor(Rsq,handles);

                            TotData=SaveRegressSensor.totdata(freqidx).trialdata(taskidx);
                            handles.BCILoc.totdata=TotData;

                        case 'Source'

                            Rsq=SaveRegressSource.Rsq(:,freqidx,taskind,:);
                            pval=SaveRegressSource.pval(:,freqidx,taskind,:);
                            handles.BCILoc.Rsq=Rsq;
                            handles.BCILoc.pval=pval;
                            handles.BCILoc.clusters=[];

                            PlotBrain(Rsq,handles);

                            TotData=SaveRegressSource.totdata(freqidx).trialdata(taskidx);
                            handles.BCILoc.totdata=TotData;

                        case 'SourceCluster'

                            Rsq=SaveRegressSourceCluster.Rsq(:,freqidx,taskind,:);
                            pval=SaveRegressSourceCluster.pval(:,freqidx,taskind,:);
                            handles.BCILoc.Rsq=Rsq;
                            handles.BCILoc.pval=pval;
                            clusters=SaveRegressSourceCluster.clusters;
                            handles.BCILoc.clusters=clusters;

                            PlotClusters(Rsq,handles);

                            TotData=SaveRegressSource.totdata(freqidx).trialdata(taskidx);
                            handles.BCILoc.totdata=TotData;

                    end

                case 'mi'

                    % p-value label
                    uicontrol('Style','text','string','p-value Threshold','Position',...
                        [290 8 125 20],'FontSize',10);

                    % Text box for different p-value thresholds
                    handles.edit1=uicontrol('Style', 'edit','string','1',...
                        'Position',[415 10 50 20],'backgroundcolor','white',...
                        'Callback',@myEnterNum);

                    % Update button
                    uicontrol('Style','pushbutton','string','Update','Position',...
                        [480 10 75 20],'Callback',@myRegressUpdate);

                    % Updated R-squared value (multiple regression)
                    handles.edit2=uicontrol('Style','edit','string','',...
                        'Position',[415 32.5 50 20],'backgroundcolor',[.94 .94 .94]);

                    % R-squared value label
                    uicontrol('Style','text','string','R-squared','Position',...
                        [343.5 32.5 60 20],'FontSize',10)


                case 'pca'

                    % Adjust plotting axes
                    set(handles.BCILocAxes,'Position',[15 50 430 325]);

                    switch spatdomainfield
                        case 'Sensor'
                            numpc=size(handles.TRAINING.(spatdomainfield).param.chanidxinclude,1);
                        case 'Source'
                            numpc=size(handles.TRAINING.(spatdomainfield).param.vertidxinclude,2);
                        case 'SourceCluster'
                            numpc=size(handles.TRAINING.(spatdomainfield).param.clusteridxinclude,2);
                    end

                    for i=1:numpc
                        PC{i}=num2str(i);
                    end
                    PC=PC(:);

                    handles.list1=uicontrol('Parent',handles.BCILocFig,'style','listbox','string',...
                        PC,'Position',[480 195 50 200],'FontSize',9,'Min',1,'Max',size(PC,1));

                    text1=uicontrol('Style','text','string',...
                        'PCs','Position',[450 395 100 20],'FontSize',10);

                    % Pop-up menu for different lambda value
                    lambda=cellstr(num2str(handles.TRAINING.param.lambda'));
                    handles.popup=uicontrol('Style','popup','string',lambda,...
                        'Position',[310 12.5 50 20]);

                    % Update button
                    uicontrol('Style','pushbutton','string','Update','Position',...
                        [370 10 75 20],'Callback',@myPCARLDAUpdate);

                    % Set lambda as lowest value if it doesnt already exist
                    if isempty(get(handles.(currentobj),'userdata'))
                        set(handles.(currentobj),'userdata',1);
                        set(handles.popup,'value',1);
    %                     lambdatmp=1;
                        Data=[];
                    elseif isequal(size(get(handles.(currentobj),'userdata'),2),2)
                        userdata=get(handles.(currentobj),'userdata');
                        set(handles.popup,'value',userdata(1));
    %                     lambdatmp=userdata(1);
                        Data=1:userdata(2);
                    else
                        set(handles.popup,'value',get(handles.(currentobj),'userdata'));
    %                     lambdatmp=get(handles.(currentobj),'userdata');
                        Data=[];
                    end
                    lambdatmp=get(handles.(currentobj),'userdata');

                    handles.BCILoc.Data=Data(:);
                    handles.table1=uitable('Data',Data(:),'ColumnName','PC','Position',...
                        [455 10 100 100],'ColumnWidth',{50 50});

                    switch spatdomainfield
                        case 'Sensor'

                            PCs=SavePCASensor.U(:,:,freqidx,taskind);
                            handles.BCILoc.PCs=PCs;
                            handles.BCILoc.clusters=[];
                            PCstmp=PCs(:,lambdatmp);

                            PlotSensor(PCstmp,handles)

                        case 'Source'

                            PCs=SavePCASource.U(:,:,freqidx,taskind);
                            handles.BCILoc.PCs=PCs;
                            handles.BCILoc.clusters=[];
                            PCstmp=PCs(:,lambdatmp);

                            PlotBrain(PCstmp,handles)

                        case 'SourceCluster'

                            PCs=SavePCASourceCluster.U(:,:,freqidx,taskind);
                            handles.BCILoc.PCs=PCs;
                            clusters=SavePCASourceCluster.clusters;
                            handles.BCILoc.clusters=clusters;
                            PCstmp=PCs(:,lambdatmp);

                            PlotClusters(PCstmp,handles);

                    end

                    btn1=uicontrol('Style','pushbutton','string','Show','Position',...
                        [467.5 170 75 20],'Callback',@myShowPC);

                    btn2=uicontrol('style','pushbutton','string','Select','Position',...
                        [467.5 145 75 20],'Callback',@mySelectPC);

                    btn3=uicontrol('style','pushbutton','string','Remove','Position',...
                        [467.5 120 75 20],'Callback',@myRemovePC);

                case 'fda'

                    switch spatdomainfield
                        case 'Sensor'

                            W=SaveFDASensor.W(:,freqidx,taskind);
                            DB=SaveFDASensor.DB(freqidx,taskind);
                            handles.BCILoc.W=W;
                            handles.BCILoc.W0=DB;
                            handles.BCILoc.clusters=[];

                            PlotSensor(W,handles)

                        case 'Source'

                            W=SaveFDASource.W(:,freqidx,taskind); 
                            DB=SaveFDASource.DB(freqidx,taskind);
                            handles.BCILoc.W=W;
                            handles.BCILoc.W0=DB;
                            handles.BCILoc.clusters=[];

                            PlotBrain(W,handles)

                        case 'SourceCluster'

                            W=SaveFDASource.W(:,freqidx,taskind); 
                            DB=SaveFDASource.DB(freqidx,taskind);
                            handles.BCILoc.W=W;
                            handles.BCILoc.W0=DB;
                            clusters=SavePCASourceCluster.clusters;
                            handles.BCILoc.clusters=clusters;

                            PlotClusters(W,handles);

                    end

                    currentobj=handles.BCILoc.CurrentObj;
                    set(handles.(currentobj),'userdata',1);

                case 'mahal'

                    % Top feature label
                    text1=uicontrol('Style','text','string','Top Mahal Feature','Position',...
                        [295 8 115 20],'FontSize',10);

                    % Pop-up menu for different top feature
                    numtopfeat=int2str((1:handles.TRAINING.param.numtopfeat)');
                    handles.popup=uicontrol('Style','popup','string',numtopfeat,...
                        'Position',[415 12.5 50 20]);

                    % Update button
                    uicontrol('Style','pushbutton','string','Update','Position',...
                        [480 10 75 20],'Callback',@myMahalUpdate);

                    % Total Mahalanobis Distance
                    text2=uicontrol('Style','text','string','Total Distance','Position',...
                        [145 8 95 20],'FontSize',10);

                    handles.edit1=uicontrol('Style','edit','string','',...
                        'Position',[240 10 50 20],'backgroundcolor',[.94 .94 .94]);

                    % Set lambda as lowest value if it doesnt already exist
                    if isempty(get(handles.(currentobj),'userdata'))
                        set(handles.(currentobj),'userdata',1);
                        set(handles.popup,'value',1);
                        topfeattmp=1;
                        Data=[];
                    elseif isequal(size(get(handles.(currentobj),'userdata'),2),2)
                        userdata=get(handles.(currentobj),'userdata');
                        set(handles.popup,'value',userdata(1));
                        topfeattmp=userdata(1);
                        Data=1:userdata(1);
                    else
                        userdata=get(handles.(currentobj),'userdata');
                        set(handles.popup,'value',userdata);
                        topfeattmp=userdata;
                        Data=[];
                    end

                    switch spatdomainfield
                        case 'Sensor'

                            MD=SaveMahalSensor.MD(:,freqidx,taskind);
                            BestMD=SaveMahalSensor.BestMD(:,freqidx,taskind);
                            BestMDidx=SaveMahalSensor.BestMDidx(:,freqidx,taskind);

                            handles.BCILoc.MD=MD;
                            handles.BCILoc.BestMD=BestMD;
                            handles.BCILoc.BestMDidx=BestMDidx;

                            MDtmp=zeros(size(MD,1),1);
                            MDtmp(BestMDidx(1:topfeattmp))=MD(BestMDidx(1:topfeattmp));
                            PlotSensor(MDtmp,handles);

                        case 'Source'

                            MD=SaveMahalSource.MD(:,freqidx,taskind);
                            BestMD=SaveMahalSource.BestMD(:,freqidx,taskind);
                            BestMDidx=SaveMahalSource.BestMDidx(:,freqidx,taskind);

                            handles.BCILoc.MD=MD;
                            handles.BCILoc.BestMD=BestMD;
                            handles.BCILoc.BestMDidx=BestMDidx;
                            handles.BCILoc.clusters=[];

                            MDtmp=zeros(size(MD,1),1);
                            MDtmp(BestMDidx(1:topfeattmp))=MD(BestMDidx(1:topfeattmp));
                            PlotBrain(MDtmp,handles)

                        case 'SourceCluster'

                            MD=SaveMahalSource.MD(:,freqidx,taskind);
                            BestMD=SaveMahalSource.BestMD(:,freqidx,taskind);
                            BestMDidx=SaveMahalSource.BestMDidx(:,freqidx,taskind);

                            handles.BCILoc.MD=MD;
                            handles.BCILoc.BestMD=BestMD;
                            handles.BCILoc.BestMDidx=BestMDidx;
                            clusters=SaveMahalSourceCluster.clusters;
                            handles.BCILoc.clusters=clusters;

                            MDtmp=zeros(size(MD,1),1);
                            MDtmp(BestMDidx(1:topfeattmp))=MD(BestMDidx(1:topfeattmp));
                            PlotClusters(MDtmp,handles);

                    end
                    set(handles.edit1,'string',num2str(BestMD(topfeattmp)));

            end

            guidata(handles.BCILocFig,handles)

        end
    end
    
end
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             HELPER FUNCTIONS                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CUSTOM HELPERS
function myCheckCustom(CheckCustomH,EventData)
handles=guidata(CheckCustomH);

idx=EventData.Indices;
row=idx(1); col=idx(2);
data=get(handles.table,'Data');
input=data{row,col};

% Chan Name/Number
if isequal(col,1)
    
    eLoc=handles.SYSTEM.Electrodes.current.eLoc;
    lab={eLoc.labels};
    num=1:size(eLoc,2);
    
    % check if name or number
    if isnumeric(str2double(input)) && ismember(str2double(input),num)
        data{row,col}=input;
    elseif ischar(input) && ismember(input,lab)
    	labidx=find(strcmp(input,lab)==1);
        data{row,col}=num2str(labidx);
    else
        data{row,col}='';
    end
    
elseif isequal(col,2)
    
    % check if name or number
    if isnumeric(str2double(input)) && ~isequal(str2double(input),0)
        data{row,col}=input;
    else
        data{row,col}='';
    end
    
end

set(handles.table,'data',data);
currentobj=handles.BCILoc.CurrentObj;
data=str2double(data);
if ~ischar(data)
    set(handles.(currentobj),'userdata',data);
end


function myDefaultSensor(DefaultH,EventData)
handles=guidata(DefaultH);

dimvar=strcat('bcidim',handles.BCILoc.CurrentObj(end));
movestr=get(handles.(dimvar),'string');
moveidx=get(handles.(dimvar),'value');
movetype=movestr(moveidx);

elabel={handles.SYSTEM.Electrodes.current.eLoc.labels};
eegsystem=handles.SYSTEM.eegsystem;
switch eegsystem
    case 1 % None
    case 2 % NSL 64
        C3=find(strcmp(elabel,'C3'));
        C4=find(strcmp(elabel,'C4'));
    case 3 % NSL 128
    case 4 % BS 64
        C3=find(strcmp(elabel,'A13'));
        C4=find(strcmp(elabel,'B18'));
    case 5 % BS 128
        C3=find(strcmp(elabel,'D19'));
        C4=find(strcmp(elabel,'B22'));
    case 6 % SG 16
        C3=find(strcmp(elabel,'C3'));
        C4=find(strcmp(elabel,'C4'));
end

Data=cell(10,2);
Data{1,1}=num2str(C3);
Data{2,1}=num2str(C4);

if strcmp(movetype,'Horizontal') || strcmp(movetype,'Pitch')
    
    Data{1,2}='-1';
    Data{2,2}='1';
    
elseif strcmp(movetype,'Vertical') || strcmp(movetype,'Roll')
    
    Data{1,2}='-1';
    Data{2,2}='-1';
    
elseif strcmp(movetype,'Depth') || strcmp(movetype,'Yaw')
    
end
set(handles.table,'Data',Data)

CurrentObj=handles.BCILoc.CurrentObj;
set(handles.(CurrentObj),'UserData',str2double(Data))


function myDefaultSource(DefaultH,EventData)
handles=guidata(DefaultH);
dimvar=strcat('bcidim',handles.BCILoc.CurrentObj(end));
movestr=get(handles.(dimvar),'string');
moveidx=get(handles.(dimvar),'value');
movetype=movestr(moveidx);


% Check for subject specific hand knob seed vertices
rootdir=handles.SYSTEM.rootdir;
SeedFile=[];
defaultanatomy=get(handles.defaultanatomy,'value');
if isequal(defaultanatomy,1)
    SeedFile=strcat(rootdir,'\from_Brad\bci_ESI_Default_Anatomy\Default_Hand_Knob_Seeds.mat');
else
    Subj=handles.SYSTEM.initials;
    BrainFolder=strcat(rootdir,'\BCI_ready_files\',Subj);
    
    if ~exist(BrainFolder,'dir')
        fprintf(2,'\nSUBJECT SPECIFIC ANATOMY FOLDER DOES NOT EXIST IN ROOT DIRECTORY\n');
    else
        SubjSeedFile=strcat(BrainFolder,'\',Subj,'_Hand_Knob_Seeds.mat');
        if ~exist(SubjSeedFile,'file')
            fprintf(2,'SUBJECT SPECIFIC HAND KNOB SEED FILE DOES NOT EXIST IN SUBJECT DIRECTORY\n');
        else
            SeedFile=SubjSeedFile;
        end
    end
end
    
if ~isempty(SeedFile)
    Seeds=load(SeedFile);
    SeedLabels={Seeds.Scouts.Label};
    SeedVert={Seeds.Scouts.Vertices};
    
    parcellation=get(handles.parcellation,'value');
    if isequal(parcellation,2)
        
        clusters=handles.ESI.CLUSTER.clusters;
        Data=cell(10,2);
        idx=1; lidx=[]; ridx=[];
        for i=1:size(SeedVert,2)

            for j=1:size(SeedVert{i},2)
                for k=1:size(clusters,2)-1

                    if ismember(SeedVert{i}(j),clusters{k})
                        
                        if ~isempty(strfind(SeedLabels{i},'L')) ||...
                                ~isempty(strfind(SeedLabels{i},'Left'))

                            if ~ismember(str2double(Data(:,1)),k)
                                Data{idx,1}=num2str(k);
                                lidx=[lidx idx];
                                idx=idx+1;
                            end

                        elseif ~isempty(strfind(SeedLabels{i},'R')) ||...
                                ~isempty(strfind(SeedLabels{i},'Right'))

                            if ~ismember(str2double(Data(:,1)),k)
                                Data{idx,1}=num2str(k);
                                ridx=[ridx idx];
                                idx=idx+1;
                            end

                        end

                    end
                end
            end

        end

        if strcmp(movetype,'Horizontal')
            for i=1:size(lidx,2)
                Data{lidx(i),2}='-1';
            end
            for i=1:size(ridx,2)
                Data{ridx(i),2}='1';
            end
        elseif strcmp(movetype,'Vertical')
            for i=1:size(lidx,2)
                Data{lidx(i),2}='-1';
            end
            for i=1:size(ridx,2)
                Data{ridx(i),2}='-1';
            end
        elseif strcmp(movetype,'Depth')
        end

%         [X,I]=sort(Data(:,1),'ascend');
%         Data(:,1)=Data(I,1);
%         Data(:,2)=Data(I,2);

        set(handles.table,'Data',Data)

        cla
        Cortex=handles.ESI.cortex;

        R=zeros(1,size(Cortex.Vertices,1));
        for i=1:max([lidx,ridx])
            R(clusters{str2double(Data{i,1})})=repmat(str2double(Data{i,2}),[1 size(clusters{str2double(Data{i,1})},2)]);
        end
        h=trisurf(Cortex.Faces,Cortex.Vertices(:,1),...
            Cortex.Vertices(:,2),Cortex.Vertices(:,3),R);
        set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
        axis equal; axis off; view(-90,90); caxis auto; rotate3d on;
        light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
        cmap=jet(128); cmap(63:65,:)=repmat([.85 .85 .85],[3 1]); colormap(cmap)
        colorbar; caxis auto; caxis([-max(abs(R(:))) max(abs(R(:)))]);
        
        CurrentObj=handles.BCILoc.CurrentObj;
        set(handles.(CurrentObj),'UserData',str2double(Data))
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RLDA HELPERS
function myRLDAUpdate(RLDAUpdateH,EventData)
handles=guidata(RLDAUpdateH); cla

lambda=get(handles.popup,'value');
W=handles.BCILoc.W;

fileidx=handles.BCILoc.fileidx;
if isequal(fileidx,1)
    Widx=get(handles.taskselect,'value');
else
    Widx=1;
end
Wtmp=W(:,:,Widx,lambda);

spatdomainfield=handles.TRAINING.spatdomainfield;
switch spatdomainfield
    case 'Sensor'
        
        PlotSensor(Wtmp,handles);
        
    case 'Source'
    
        PlotBrain(Wtmp,handles);
    
    case 'SourceCluster'
        
        PlotClusters(Wtmp,handles);
        
end

currentobj=handles.BCILoc.CurrentObj;
set(handles.(currentobj),'userdata',lambda);


function myRLDASwitchTask(SwitchH,EventData)
handles=guidata(SwitchH);

W=handles.BCILoc.W;
lambda=get(handles.popup,'value');
Widx=get(handles.taskselect,'value');
Wtmp=W(:,:,Widx,lambda);

spatdomainfield=handles.TRAINING.SpatDomainField;
switch spatdomainfield
    case 'Sensor'
        
        PlotSensor(Wtmp,handles);
        
    case 'Source'
        
        PlotBrain(Wtmp,handles);
        
    case 'SourceCluster'
        
        PlotClusters(Wtmp,handles);
        
end


function myEnterNum(EnterNumH,EventData)
handles=guidata(EnterNumH);

value=get(handles.edit1,'string');
value=str2double(value);
if isnan(value) || isempty(value)
    set(handles.edit1,'string','');
elseif isnumeric(value) && value>1 || value<=0
    set(handles.edit1,'string','');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REGRESSION HELPERS
function myRegressUpdate(RegressUpdateH,EventData)
handles=guidata(RegressUpdateH); cla

pvalthresh=str2double(get(handles.edit1,'string'));
Rsq=handles.BCILoc.Rsq;
pval=handles.BCILoc.pval;
remove=find(pval>pvalthresh);
keep=find(pval<pvalthresh);

Rsq(remove)=0;

spatdomainfield=handles.TRAINING.spatdomainfield;
switch spatdomainfield
    case 'Sensor'
        
        PlotSensor(Rsq,handles);
        
    case 'Source'
        
        PlotBrain(Rsq,handles);
        
    case 'SourceCluster'
        
        PlotClusters(Rsq,handles);
        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PERFORM MULTIPLE LINEAR REGRESSION ON LOCATIONS THAT MET P-VAL THRESHOLD
totdata=handles.BCILoc.totdata;
chanval=cell(1,2);   
for i=1:2
    % If trials are windowed
    if iscell(totdata{i})
        % Go through each trial and concatenate windows
        for j=1:size(totdata{i},2)
            chanval{i}=[chanval{i};totdata{i}{j}(keep,:)'];
        end
    else
        % Or select single trial value for each channel
        chanval{i}=totdata{i}(keep,:)';
    end
end
[stats]=LSRegress(chanval{1},chanval{2});
set(handles.edit2,'string',num2str(stats.Rsq));

currentobj=handles.BCILoc.CurrentObj;
userdata(:,1)=keep;
userdata(:,2)=stats.B(1,1:end-1);
set(handles.(currentobj),'userdata',userdata);


function [stats]=LSRegress(X1,X2)

% Create Model
X=[X1;X2]; X=[X ones(size(X,1),1)];
Y=[ones(size(X1,1),1);-1*ones(size(X2,1),1)];
[n,p]=size(X); % n DOF Model, n-p DOF error

% Perform least squares inversion
Bfull=inv(X'*X)*X'*Y;
B=Bfull(1);

Y_hat=X*Bfull; % Estimate
e=Y-Y_hat; % Error
norme=norm(e);
SSE=norme.^2; % Sum of Squared Errors

RSS=norm(Y_hat-repmat(mean(Y),[n,1]))^2; % Regression Sum of Squares
TSS=norm(Y-repmat(mean(Y),[n,1]))^2; % Total Sum of Squares
Rsq=1-SSE/TSS; % Coefficient of correlation

if B>0
    r=sqrt(Rsq);
else
    r=-sqrt(Rsq);
end

rmse=norme/sqrt(n-1); % Standard Error
% Statistics
if p>1
    F_stat=(RSS/(p-1))/(rmse^2);
    t_stat=nan;
    p_stat=1-fcdf(F_stat,p-1,n-p);
else
    F_stat=nan;
    t_stat=B/rmse;
    p_stat=1-tcdf(t_stat,n-1);
end

stats.B=Bfull';
stats.Rsq=Rsq;
stats.r=r;
stats.F=F_stat;
stats.t=t_stat;
stats.p=p_stat;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PCA HELPERS
function myAddPC(AddH,EventData)
handles=guidata(AddH);

select=get(handles.list1,'value');
select=select(:);
data=get(handles.table1,'Data');

for i=1:size(select,1)
    if ~ismember(select(i),data)
        data=sort(unique([data;select]),'ascend');
    end
end

set(handles.table1,'Data',data)

currentobj=handles.BCILoc.CurrentObj;
set(handles.(currentobj),'userdata',data)


function mySelectPC(SelectH,EventData)
handles=guidata(SelectH);

select=get(handles.list1,'value');
select=max(select);
data=1:select;
set(handles.table1,'Data',data(:))

currentobj=handles.BCILoc.CurrentObj;
userdata=get(handles.(currentobj),'userdata');
userdata(2)=select;
set(handles.(currentobj),'userdata',userdata)


function myRemovePC(RemoveH,EventData)
handles=guidata(RemoveH);

data=get(handles.table1,'Data');
select=get(handles.list1,'value');
select=select:max(data);

for i=1:size(select,2)
    if ismember(select(i),data)
        remove=find(data==select(i));
        data(remove)=[];
    end
end

set(handles.table1,'Data',data);

currentobj=handles.BCILoc.CurrentObj;
userdata=get(handles.(currentobj),'userdata');
userdata(2)=max(data);
set(handles.(currentobj),'userdata',userdata)


function myShowPC(ShowH,EventData)
handles=guidata(ShowH);

select=get(handles.list1,'value');
select=select(:);

if isequal(size(select,1),1)
    
    PCs=handles.BCILoc.PCs;
    PCs=PCs(:,select);
    
    spatdomainfield=handles.TRAINING.SpatDomainField;
    switch spatdomainfield
        case 'Sensor'
            
            PlotSensor(PCs,handles);
            
        case 'Source'
            
            PlotBrain(PCs,handles);
            
        case 'SourceCluster'
            
            PlotClusters(PCs,handles);
            
    end
end


function myPCARLDAUpdate(PCARLDAUpdateH,EventData)
handles=guidata(PCARLDAUpdateH);

lambda=get(handles.popup,'value');

currentobj=handles.BCILoc.CurrentObj;
userdata=get(handles.(currentobj),'userdata');
userdata(1)=lambda;
set(handles.(currentobj),'userdata',userdata);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAHALANOBIS DISTANCE HELPERS
function myMahalUpdate(MahalUpdateH,EventData)
handles=guidata(MahalUpdateH);

topfeat=get(handles.popup,'value');

BestMD=handles.BCILoc.BestMD;
BestMDidx=handles.BCILoc.BestMDidx;
set(handles.edit1,'string',num2str(BestMD(topfeat)));

MD=handles.BCILoc.MD;
MDtmp=zeros(size(MD,1),1);
MDtmp(BestMDidx(1:topfeat))=MD(BestMDidx(1:topfeat));

spatdomainfield=handles.TRAINING.SpatDomainField;
switch spatdomainfield
    case 'Sensor'
        
        PlotSensor(MDtmp,handles);
        
    case 'Source'
        
        PlotBrain(MDtmp,handles);
        
    case 'SourceCluster'
        
        PlotClusters(MDtmp,handles);
        
end

currentobj=handles.BCILoc.CurrentObj;
set(handles.(currentobj),'userdata',topfeat);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING HELPERS
function PlotSensor(cdata,handles)
        
eLoc=handles.SYSTEM.Electrodes.current.eLoc;
topoplot(cdata,eLoc,'electrodes','ptlabels','numcontour',0);
view(0,90); axis xy; rotate3d off;
set(gcf,'color',[.94 .94 .94]); colorbar;
caxis([-max(abs(cdata)) max(abs(cdata))]);

    
function PlotBrain(cdata,handles)

cortex=handles.ESI.cortex;
offset=-(max(abs(cdata))+.1*max(abs(cdata)));
cplot=offset*ones(1,size(cortex.Vertices,1));
cplot(handles.TRAINING.Source.SMR.param.vertidxinclude)=cdata;

colorbar off
h=trisurf(cortex.Faces,cortex.Vertices(:,1),...
    cortex.Vertices(:,2),cortex.Vertices(:,3),cplot);
set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
axis equal; axis off; view(-90,90); caxis auto; rotate3d on;
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
cmap=jet(128); cmap=[repmat([.85 .85 .85],[3 1]);cmap]; colormap(cmap)
colorbar; caxis([offset max(cdata)]);


function PlotClusters(cdata,handles)
    
cortex=handles.ESI.cortex;
offset=-(max(abs(cdata))+.1*max(abs(cdata)));
cplot=offset*ones(1,size(cortex.Vertices,1));
clusters=handles.BCILoc.clusters;
for i=1:size(clusters,2)-1
    cplot(clusters{i})=cdata(i);
end

colorbar off
h=trisurf(cortex.Faces,cortex.Vertices(:,1),...
    cortex.Vertices(:,2),cortex.Vertices(:,3),cplot);
set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
axis equal; axis off; view(-90,90); caxis auto; rotate3d on;
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
cmap=jet(128); cmap=[repmat([.85 .85 .85],[3 1]);cmap]; colormap(cmap)
colorbar; caxis([offset max(cdata)]);        
        
        
            