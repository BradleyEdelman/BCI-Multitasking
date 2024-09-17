function [hObject,handles]=bci_ESI_SelectBrainRegions(hObject,handles)

% Extract brain regions from specified file
brainregionfile=get(handles.brainregionfile,'string');
set(handles.brainregionfile,'backgroundcolor','green')
cortexfile=get(handles.cortexfile,'string');
[filepath,filename,fileext]=fileparts(cortexfile);
if isempty(brainregionfile) || strcmp(brainregionfile,'') ||...
        size(brainregionfile,2)<4
    fprintf(2,'BRAIN REGION FILE NOT SELECTED, CANNOT SELECT BRAIN REGIONS\n');
    set(handles.brainregionfile,'backgroundcolor','red');
elseif ~strcmp(fileext,'.mat')
    fprintf(2,'BRAIN REGION FILE MUST BE .MAT FORMAT\n');
    set(handles.brainregionfile,'backgroundcolor','red');
elseif isempty(cortexfile) || strcmp(cortexfile,'') || size(cortexfile,2)<4
    fprintf(2,'CORTEX FILE NOT SELECTED, CANNOT SELECT BRAIN REGIONS\n');
else
    brainregions=load(brainregionfile);
    cortex=load(cortexfile);
    if ~isfield(brainregions,'Scouts')
        fprintf(2,'BRAIN REGION FILE MUST CONTAIN "SCOUTS" - IDENTIFYING REGIONS\n');
        set(handles.brainregionfile,'backgroundcolor','red');
    elseif ~isfield(brainregions.Scouts,'Label')
        fprintf(2,'BRAIN REGION FILE MUST CONTAIN LABELS\n');
        set(handles.brainregionfile,'backgroundcolor','red');
    else
        numregion=size(brainregions.Scouts,2);
        regionlabels={brainregions.Scouts.Label};
        if numregion<=14

            handles.regionsbrain.cortex=cortex;
            handles.regionsbrain.scouts=brainregions.Scouts;

            set(hObject,'backgroundcolor','white');
            handles.regionsbrainfig=figure;
            set(handles.regionsbrainfig,'MenuBar','none','ToolBar','none','color',[.94 .94 .94]);
            rotate3d on

            % Assigned plotting axes
            handles.regionsbrainaxes=axes('Parent',handles.regionsbrainfig,'Units','pixels',...
                'HandleVisibility','callback','Position',[175 25 375 370]); axis off

            if isfield(handles,'regionsbrain') && ~isempty(handles.regionsbrain) &&...
                    isfield(handles.regionsbrain,'radio') && ~isempty(handles.regionsbrain.radio)
                handles.regionsbrain.radio(numregion+1:end)=[];
            end

            % Create radio buttons for each region
            for i=1:numregion
                handles.regionsbrain.radio(i)=uicontrol('Style','radiobutton','Callback',...
                    @myRadio,'Units','pixels','Position',[15,375-25*(i-1),150,25],...
                    'string',regionlabels{i},'value',0,'FontSize',9);
            end

            % Create colormap
            cmap=[.85 .85 .85;1 0 1;1 0 .5;.45 .45 1;.6 .6 0;.55 1 .75;...
                .6 .3 0;1 .8 .8;1 0 0;1 .5 0;1 1 0;0 1 0;0 1 1;0 0 1;.5 0 1];
            cmap1=[2 3 4 5 6 7 8 9 10 11 12 13 14 15];

            % Plot blank brain
            BrainDisplay=zeros(1,size(cortex.Vertices,1));
            h=trisurf(cortex.Faces,cortex.Vertices(:,1),cortex.Vertices(:,2),...
                cortex.Vertices(:,3),BrainDisplay);
            set(h,'FaceColor','flat','EdgeColor','none','FaceLighting','gouraud');
            axis equal; axis off; view(-90,90)
            colormap(cmap); caxis([0 16]); light;
            h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);

            % Check if brain regions have already been selected - if so, plot
            if isequal(size(get(hObject,'userdata'),1),numregion) &&...
                    ~isequal(get(hObject,'userdata'),zeros(numregion,1))
                oldradioval=get(hObject,'userdata');
                for i=1:size(get(hObject,'userdata'),1)
                    set(handles.regionsbrain.radio(i),'value',oldradioval(i));
                end

                BrainDisplay=zeros(1,size(cortex.Vertices,1));
                for i=1:size(oldradioval,1)
                    if isequal(oldradioval(i),1)
                        BrainDisplay(brainregions.Scouts(i).Vertices)=cmap1(i);
                    end
                end

                h=trisurf(cortex.Faces,cortex.Vertices(:,1),cortex.Vertices(:,2),...
                    cortex.Vertices(:,3),BrainDisplay);
                set(h,'FaceColor','flat','EdgeColor','None','FaceLighting','gouraud');
                axis equal; axis off; view(-90,90)
                colormap(cmap); caxis([0 16]);
                light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
            end
                text1=uicontrol('style','text','string',...
                    'Select brain regions for training data','Position',...
                    [105 395 350 25],'FontSize',13.5);

                text2=uicontrol('style','text','string',...
                    '*Must ensure brain region file uses same brain as specified cortex',...
                    'Position',[125 10 350 15],'FontSize',8);

                btn1=uicontrol('style','pushbutton','string','Save & Close','Position',...
                    [10 10 125 20],'Callback','close');

                guidata(handles.regionsbrainfig,handles);

        else
            fprintf(2,'MUST HAVE LESS THAN 15 BRAIN REGIONS...\n');
        end
    end
end


function myRadio(RadioH,EventData)
handles=guidata(RadioH);

if ~isempty(get(handles.cortexfile,'string'))  
    cortex=handles.regionsbrain.cortex;
    scouts=handles.regionsbrain.scouts;
    cmap=[.85 .85 .85;1 0 1;1 0 .5;.45 .45 1;.6 .6 0;.55 1 .75;...
                .6 .3 0;1 .8 .8;1 0 0;1 .5 0;1 1 0;0 1 0;0 1 1;0 0 1;.5 0 1];
    cmap1=[2 3 4 5 6 7 8 9 10 11 12 13 14 15];
    
    BrainDisplay=zeros(1,size(cortex.Vertices,1));
    RegionOnOff=cell2mat(get(handles.regionsbrain.radio,'value'));
        
    for i=1:size(RegionOnOff,1)
        if isequal(RegionOnOff(i),1)
            BrainDisplay(scouts(i).Vertices)=cmap1(i);
        end
    end
    
    h=trisurf(cortex.Faces,cortex.Vertices(:,1),cortex.Vertices(:,2),...
        cortex.Vertices(:,3),BrainDisplay);
    set(h,'FaceColor','flat','EdgeColor','None','FaceLighting','gouraud');
    axis equal; axis off; view(-90,90)
    colormap(cmap); caxis([0 16]); light;
    h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
end
% Save "on/off" state of brain regions for future use
set(handles.selectbrainregions,'userdata',...
    cell2mat(get(handles.regionsbrain.radio,'value')))