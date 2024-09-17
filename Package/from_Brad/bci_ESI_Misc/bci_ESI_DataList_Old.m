function [hObject,handles]=bci_ESI_DataList(hObject,handles,Action,DataList1,DataList2)

switch Action
    case 'Add'
        
        oldlist=cellstr(get(handles.(DataList1),'String'));
        [filename,pathname]=uigetfile('MultiSelect','on',{'*.mat';'*.Dat'});
        if ~isequal(filename,0) && ~isequal(pathname,0)
            newfiles=strcat(pathname,filename);
            if iscell(newfiles); newfiles=newfiles'; end
            newlist=[oldlist;newfiles];
            newlist=newlist(~cellfun('isempty',newlist)); 
            set(handles.(DataList1),'String',newlist,'Value',size(newlist,1))
            
            % NEW TRAINING DATA MEANS NEW FEATURES, EMPTY FEATURE VARIABLES
            [hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,{'TRAINING','BCI'});
            [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,[],[],[]);
            
        else
            set(handles.(DataList1),'String',oldlist);
        end
        
    case 'Remove'
        
        oldlist=cellstr(get(handles.(DataList1),'String'));
        listind=1:size(oldlist,1);
        remove=get(handles.(DataList1),'value');
        if ~isequal(remove,0)
            listind(remove)=[];
            for i=1:size(listind,2)
                newlist{i}=oldlist{listind(i)};
            end
            if ~exist('newlist','var')
                newlist=cell(0);
            end
            set(handles.(DataList1),'Value',size(newlist,2),'String',newlist)
        end
        
        % NEW TRAINING DATA MEANS NEW FEATURES, EMPTY FEATURE VARIABLES
        [hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,{'TRAINING','BCI'});
        [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,[],[],[]);
        
    case 'Clear'
        
        set(handles.(DataList1),'String',cell(0));
        
        % NEW TRAINING DATA MEANS NEW FEATURES, EMPTY FEATURE VARIABLES
        set(handles.freqfeat,'String','');
        set(handles.timefeat,'String','');
        [hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,{'TRAINING','BCI'});
        [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,[],[],[]);
        
    case 'Copy'
        
        if ~isempty(DataList2) && ~isempty(get(handles.(DataList2),'String'))
            set(handles.(DataList1),'String',get(handles.(DataList2),'String'));
        end

end
        
 

        
        
        
        
        
        
        