function [hObject,handles]=bci_ESI_DataList(hObject,handles,Action,DataList1,DataList2)

switch Action
    case 'Add'
        
    case 'Remove'
        
    case 'Clear'
        
        data=get(handles.(DataList1),'data');
        data(:,1)=repmat({0},[10,1]);
        data(:,2)=repmat({''},[10,1]);
        set(handles.(DataList1),'data',data);
        
        % NEW TRAINING DATA MEANS NEW FEATURES, EMPTY FEATURE VARIABLES
        set(handles.freqfeat,'String','');
        set(handles.timefeat,'String','');
        [hObject,handles]=bci_ESI_DefaultHandles(hObject,handles,{'TRAINING','BCI'});
        [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,[],[],[]);
      
    case 'Copy'
        
        if ~isempty(DataList1) && ~isempty(DataList2) 
            
            data=get(handles.(DataList2),'data');
            data(:,1)=repmat({0},[10,1]);
            set(handles.(DataList1),'data',data);

        end

end
        
 

        
        
        
        
        
        
        