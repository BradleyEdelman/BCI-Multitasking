function [hObject,handles]=bci_ESI_SelectSensorsSSVEP(hObject,handles)

set(hObject,'BackgroundColor',[.94 .94 .94]);

eegsystem=get(handles.eegsystem,'value');
if ~isequal(eegsystem,1)
    
    % Create figure
    handles.sensorfig=figure('MenuBar','none','ToolBar','none','color',[.94 .94 .94]);
    eLoc=handles.Electrodes.current.eLoc;
    numsensor=size(eLoc,2);
    
    % Figure title
    txt1=uicontrol('style','text','string',...
            'Select sensors for training data','Position',[105 395 350 25],'FontSize',13.5);
    
    % Close button
    btn1=uicontrol('style','pushbutton','string','Save & Close','Position',...
        [10 10 125 20],'callback',@myClose);
    
    % All electrodes
    btn2=uicontrol('style','pushbutton','string','All','Position',...
        [200 10 50 20],'callback',@myAll);
    
    % Focal occipital
    btn3=uicontrol('style','pushbutton','string','Focal','Position',...
        [260 10 100 20],'callback',@myFocal);
    
    % Small occipital region
    btn4=uicontrol('style','pushbutton','string','Small Occipital','Position',...
        [370 10 100 20],'callback',@myOccipital1);
    
    % Large occiptal region
    btn5=uicontrol('style','pushbutton','string','Large Occipital',...
        'Position',[480 10 100 20],'callback',@myOccipital2);
    
    % Assign plotting axes
    handles.RegionsAxes=axes('Parent',handles.sensorfig,'Units','pixels',...
        'HandleVisibility','callback','Position',[177.5+(ceil(size(eLoc,2)/20))*20 30 372.5 365]); axis off
    
    % Resize figure if needed
    Pos=get(handles.sensorfig,'Position');
    Pos(3)=Pos(3)+(ceil(numsensor/20))*20;
    set(handles.sensorfig,'Position',Pos)

    % Plot all channels
    topoplot([],eLoc,'electrodes','ptlabels');
    set(handles.sensorfig,'color',[.94 .94 .94]);
    if isfield(handles,'regionssensorssvep') && ~isempty(handles.regionssensorssvep)
        handles.regionssensorssvep.radio(numsensor+1:end)=[];
    end
    
    for i=1:numsensor

        if i<=20; x=15;
        elseif i>20 && i<=40; x=60;
        elseif i>40 && i<=60; x=105;
        elseif i>60 && i<=80; x=155;
        elseif i>80 && i<=100; x=200;
        elseif i>100 && i<=120; x=245;
        elseif i>120; x=290;
        end

        y=rem(i,20);
        if y==0; y=20; end

        handles.regionssensorssvep.radio(i)=uicontrol('Style','radiobutton','callback',...
        @myRadio,'Units','pixels','Position',[x,395-y*17.5,50,20],...
        'string',eLoc(i).labels,'value',1,'FontSize',9);
        
    end
    
    % Check if sensors have already been selected - if so, plot
    if isequal(size(get(hObject,'userdata'),1),numsensor) && ~isequal(get(hObject,'userdata'),zeros(numsensor,1))
        OldRadioVal=get(hObject,'userdata');
        for i=1:size(get(hObject,'userdata'),1)
            set(handles.regionssensorssvep.radio(i),'value',OldRadioVal(i));
        end
        
        j=1; eLoctmp=eLoc(1);
        for i=1:size(OldRadioVal,1)
            if isequal(OldRadioVal(i),1)
                eLoctmp(j)=eLoc(i);
                j=j+1;
            end
        end
        cla
        topoplot([],eLoctmp,'electrodes','ptlabels');
        set(handles.sensorfig,'color',[.94 .94 .94]);
    end

    guidata(handles.sensorfig,handles)
    
else
    fprintf(2,'MUST SELECT AN EEG SYSTEM TO SELECT CHANNELS\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS
function myClose(CloseH,EventData)
handles=guidata(CloseH);
set(handles.selectsensorsssvep,'userdata',cell2mat(get(handles.regionssensorssvep.radio,'value')))
close(handles.sensorfig)



function myRadio(RadioH,EventData)
handles=guidata(RadioH);

if isfield(handles,'Electrodes') && isfield(handles.Electrodes,'current') &&...
    ~isempty(handles.Electrodes.current)
    set(handles.sensorfig,'MenuBar','none','ToolBar','none','color',[.94 .94 .94])
    eLoc=handles.Electrodes.current.eLoc; Plot=1;
else
    fprintf(2,'MUST SELECT AN EEG SYSTEM TO SELECT CHANNELS\n'); 
end

if isequal(Plot,1)
    RegionOnOff=cell2mat(get(handles.regionssensorssvep.radio,'value'));
    
    j=1; eLoctmp=eLoc(1);
    for i=1:size(RegionOnOff,1)
        if isequal(RegionOnOff(i),1)
            eLoctmp(j)=eLoc(i);
            j=j+1;
        end
    end
    
    cla
    topoplot([],eLoctmp,'electrodes','ptlabels','emarker',{'.','k',[],1});
    set(handles.sensorfig,'color',[.94 .94 .94]);
end
set(handles.selectsensorsssvep,'userdata',cell2mat(get(handles.regionssensorssvep.radio,'value')))
guidata(RadioH,handles);



function myAll(AllH,EventData)
handles=guidata(AllH);

eLoc=handles.Electrodes.current.eLoc;
for i=1:size(eLoc,2)
    set(handles.regionssensorssvep.radio(i),'value',1);
end

cla
topoplot([],eLoc,'electrodes','ptlabels','emarker',{'.','k',[],1});
set(handles.sensorfig,'color',[.94 .94 .94]);
set(handles.selectsensorsssvep,'userdata',cell2mat(get(handles.regionssensorssvep.radio,'value')))
guidata(AllH,handles);



function myFocal(focalH,EventData)
handles=guidata(focalH);

eLoc=handles.Electrodes.original.eLoc;

eegsystem=get(handles.eegsystem,'value');
switch eegsystem
    case 1 % None
    case 2 % Neuroscan 64
        AutoRemove=[1:60];
    case 3 % Neuroscan 128
        AutoRemove=[];
    case 4 % BioSemi 64
        AutoRemove=[1:27,30:64];
    case 5 % BioSemi 128
        AutoRemove=[1:24,26:128];
    case 6 % Signal Generator
        AutoRemove=[];
end

for i=1:size(eLoc,2)
    set(handles.regionssensorssvep.radio(i),'value',1);
end

for i=1:size(AutoRemove,2)
    set(handles.regionssensorssvep.radio(AutoRemove(i)),'value',0);
end
eLoctmp=eLoc;
eLoctmp(AutoRemove)=[];

cla
topoplot([],eLoctmp,'electrodes','ptlabels','emarker',{'.','k',[],1});
set(handles.sensorfig,'color',[.94 .94 .94]);
set(handles.selectsensorsssvep,'userdata',cell2mat(get(handles.regionssensorssvep.radio,'value')))
guidata(focalH,handles);



function myOccipital1(Occ1H,EventData)
handles=guidata(Occ1H);

eLoc=handles.Electrodes.original.eLoc;

eegsystem=get(handles.eegsystem,'value');
switch eegsystem
    case 1 % None
    case 2 % Neuroscan 64
        AutoRemove=[1:52,56:57];
    case 3 % Neuroscan 128
        AutoRemove=[];
    case 4 % BioSemi 64
        AutoRemove=[1:24,31:61];
    case 5 % BioSemi 128
        AutoRemove=[1:12,17:21,30:128];
    case 6 % Signal Generator
        AutoRemove=[];
end

for i=1:size(eLoc,2)
    set(handles.regionssensorssvep.radio(i),'value',1);
end

for i=1:size(AutoRemove,2)
    set(handles.regionssensorssvep.radio(AutoRemove(i)),'value',0);
end
eLoctmp=eLoc;
eLoctmp(AutoRemove)=[];

cla
topoplot([],eLoctmp,'electrodes','ptlabels','emarker',{'.','k',[],1});
set(handles.sensorfig,'color',[.94 .94 .94]);
set(handles.selectsensorsssvep,'userdata',cell2mat(get(handles.regionssensorssvep.radio,'value')))
guidata(Occ1H,handles);



function myOccipital2(Occ2H,EventData)
handles=guidata(Occ2H);

eLoc=handles.Electrodes.original.eLoc;

eegsystem=get(handles.eegsystem,'value');
switch eegsystem
    case 1 % None
    case 2 % Neuroscan 64
        AutoRemove=[1:50];
    case 3 % Neuroscan 128
        AutoRemove=[];
    case 4 % BioSemi 64
        AutoRemove=[1:19,32:56];
    case 5 % BioSemi 128
        AutoRemove=[1:7,18:20,31:36,42:128];
    case 6 % Signal Generator
        AutoRemove=[];
end

for i=1:size(eLoc,2)
    set(handles.regionssensorssvep.radio(i),'value',1);
end

for i=1:size(AutoRemove,2)
    set(handles.regionssensorssvep.radio(AutoRemove(i)),'value',0);
end
eLoctmp=eLoc;
eLoctmp(AutoRemove)=[];

cla
topoplot([],eLoctmp,'electrodes','ptlabels','emarker',{'.','k',[],1});
set(handles.sensorfig,'color',[.94 .94 .94]);
set(handles.selectsensorsssvep,'userdata',cell2mat(get(handles.regionssensorssvep.radio,'value')))
guidata(Occ2H,handles);




