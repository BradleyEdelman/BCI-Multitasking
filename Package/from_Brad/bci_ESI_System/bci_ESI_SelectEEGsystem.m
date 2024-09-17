function [hObject,handles]=bci_ESI_SelectEEGsystem(hObject,handles)

set(handles.selectsensors,'userdata',[]);

rootdir=handles.SYSTEM.rootdir;

eegsystem=get(hObject,'value');
switch eegsystem
    case 1 % None
        set(handles.fs,'string','')
        set(hObject,'backgroundcolor','red');
        if isfield(handles,'Electrodes')
            handles=rmfield(handles,'Electrodes');
        end
    case 2 % Neuroscan 64
        % Automatically update sampling rate based on EEG system
        set(handles.fs,'backgroundcolor','white','string',num2str(1000))
        % Adjust high cutoff to nyquist frequency if set at value above
        if isempty(get(handles.highcutoff,'string'))
        elseif str2double(get(handles.highcutoff,'string'))>=1000
            set(handles.highcutoff,'string',num2str(500))
        end
        set(hObject,'backgroundcolor','white');
        
        chanidxautoexclude=[33 43 65:68]; % M1-2,VEO,HEO,EKG,EMG 
        chanidxautoexclude=sort(chanidxautoexclude,'ascend');
        eFILE=strcat(rootdir,'\from_Brad\bci_ESI_Electrodes\bci_ESI_neuroscan68.loc');
        
    case 3 % neuroscan 128
        set(handles.fs,'backgroundcolor','white','string',num2str(1000))
        if isempty(get(handles.highcutoff,'string'))
        elseif str2double(get(handles.highcutoff,'string'))>=1000
            set(handles.highcutoff,'string',num2str(500))
        end
        set(hObject,'backgroundcolor','white');
        
        chanidxautoexclude=[10 11 84 85 110 111 129:132];
        chanidxautoexclude=sort(chanidxautoexclude,'ascend');
        eFILE=strcat(rootdir,'\from_Brad\bci_ESI_Electrodes\bci_ESI_neuroscan132.loc');
        
    case 4 % BioSemi 64
        set(handles.fs,'backgroundcolor','white','string',num2str(1024))
        if isempty(get(handles.highcutoff,'string'))
        elseif str2double(get(handles.highcutoff,'string'))>=1024
            set(handles.highcutoff,'string',num2str(512))
        end
        set(hObject,'backgroundcolor','white');
        
        chanidxautoexclude=[];
        chanidxautoexclude=sort(chanidxautoexclude,'ascend');
        eFILE=strcat(rootdir,'\from_Brad\bci_ESI_Electrodes\bci_ESI_BioSemi64.xyz');
        
    case 5 % BioSemi 128
        set(handles.fs,'backgroundcolor','white','string',num2str(1024))
        if isempty(get(handles.highcutoff,'string'))
        elseif str2double(get(handles.highcutoff,'string'))>=1024
            set(handles.highcutoff,'string',num2str(512))
        end
        set(hObject,'backgroundcolor','white');
        
        chanidxautoexclude=[];
        chanidxautoexclude=sort(chanidxautoexclude,'ascend');
        eFILE=strcat(rootdir,'\from_Brad\bci_ESI_Electrodes\bci_ESI_BioSemi128.xyz');
        
    case 6 % Signal Generator
        set(handles.fs,'backgroundcolor','white','string',num2str(256));
        if isempty(get(handles.highcutoff,'string'))
        elseif str2double(get(handles.highcutoff,'string'))>=256
            set(handles.highcutoff,'string',num2str(128))
        end
        set(hObject,'backgroundcolor','white');
        
        chanidxautoexclude=[];
        chanidxautoexclude=sort(chanidxautoexclude,'ascend');
        eFILE=strcat(rootdir,'\from_Brad\bci_ESI_Electrodes\bci_ESI_SigGen16.xyz');
end

switch eegsystem
    case 1
        axes(handles.axes3); cla
    case {2,3,4,5,6}
        if exist(eFILE,'file')
            eLoc=readlocs(eFILE);
        else
            fprintf(2,'%s SENSOR LOCATION FILE NOT IN ROOT FOLDER\n',eFILE);
            set(hObject,'backgroundcolor','red','userdata',2);
            set(hObject,'userdata',2);
        end

        % Save electrode montage
        eLoc(chanidxautoexclude)=[];
        handles.Electrodes.chanidxautoexclude=chanidxautoexclude;
        handles.Electrodes.original.eLoc=eLoc;
        handles.Electrodes.current.eLoc=eLoc;
        handles.Electrodes.current.plotX=cell2mat({eLoc.X});
        handles.Electrodes.current.plotY=cell2mat({eLoc.Y});
        handles.Electrodes.current.plotZ=cell2mat({eLoc.Z});
        handles.Electrodes.chanidxinclude=1:size(eLoc,2);

        % Plot electrode montage
        axes(handles.axes3); cla
        hold off; view(2); colorbar off; rotate3d off
        topoplot([],eLoc,'electrodes','ptlabels');
        set(gcf,'color',[.94 .94 .94])
        set(handles.Axis3Label,'string','Electrode Montage');
        title('')
end

