function [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,dimension,method)

if isnumeric(dimension)

    bcidim=strcat('bcidim',num2str(dimension));
    bcitask=strcat('bcitask',num2str(dimension));
    bcifreq=strcat('bcifreq',num2str(dimension));
    bcifeat=strcat('bcifeat',num2str(dimension));
    bciloc=strcat('bciloc',num2str(dimension));


    paradigm=get(handles.paradigm,'value');
    switch paradigm
        case {1,2,3,6,8} % None or Discrete trial cursor or Continuous pursuit cursor
            dimopt={num2str(dimension),'Horizontal','Vertical','Depth'}';  
        case {4,5} % Discrete trial or Continuous pursuit hand manipulation
            dimopt={num2str(dimension),'Pitch','Roll','Yaw'}';
        case 7 % SSVEP
            dimopt={num2str(dimension)};
    end
    set(handles.(bcidim),'string',dimopt)


    if strcmp(method,'Reset')

        set(handles.(bcidim),'backgroundcolor','white','value',1)
        set(handles.(bcitask),'backgroundcolor',[.94 .94 .94],'value',1)
        set(handles.(bcifreq),'backgroundcolor',[.94 .94 .94],'value',1)
        set(handles.(bcifeat),'backgroundcolor',[.94 .94 .94],'value',1)
        set(handles.(bciloc),'backgroundcolor',[.94 .94 .94],'userdata',[]);

    elseif strcmp(method,'Clear')

        set(handles.(bcidim),'backgroundcolor','white','value',1)
        set(handles.(bcitask),'backgroundcolor',[.94 .94 .94],'string',{' ','Custom'},'value',1)
        set(handles.(bcifreq),'backgroundcolor',[.94 .94 .94],'string',' ','value',1)
        set(handles.(bcifeat),'backgroundcolor',[.94 .94 .94],'string',{' ','Custom'},'value',1)
        set(handles.(bciloc),'backgroundcolor',[.94 .94 .94],'userdata',[]);

    end

    gain=strcat('gain',num2str(dimension));
    offset=strcat('offset',num2str(dimension));
    scale=strcat('scale',num2str(dimension));
    set(handles.(gain),'backgroundcolor',[.94 .94 .94],'string','0.01')
    set(handles.(offset),'backgroundcolor',[.94 .94 .94],'string','0')
    set(handles.(scale),'backgroundcolor',[.94 .94 .94],'string','1');

elseif strcmp(dimension,'SSVEP')

    ssveptask='ssveptask';
    ssvepfeat='ssvepfeat';
    if strcmp(method,'Reset')

        set(handles.(ssveptask),'backgroundcolor','white','value',1)
        set(handles.(ssvepfeat),'backgroundcolor','white','value',1)

    elseif strcmp(method,'Clear')

        set(handles.(ssveptask),'backgroundcolor','white','string',' ','value',1)
        set(handles.(ssvepfeat),'backgroundcolor','white','string',{' ','CCA'},'value',1)

    end

end


