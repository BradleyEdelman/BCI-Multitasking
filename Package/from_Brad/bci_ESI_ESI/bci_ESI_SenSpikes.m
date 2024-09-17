function [hObject,handles]=bci_fESI_SenSpikes(hObject,handles)

if isfield(handles,'Electrodes') && isfield(handles.Electrodes,'eLoc')

    eLoc=handles.Electrodes.eLoc2;
    MaxChan=size(eLoc,2);

    Value=get(hObject,'String');
    % Find spaces in the entered text
    Space=strfind(Value,' ');
   
    for i=size(Value,2):-1:1
        if ismember(i,Space)
        % Is the text a real (not imaginary) number > 0
        elseif isnan(str2double(Value(i))) || ~isreal(str2double(Value(i)))
            Value(i)=[];
            if ~exist('h','var')
                h=fprintf(2,'MUST BE A POSITIVE NUMERIC VALUE LESS THAN %s\n',num2str(MaxChan));
            end
        end          
    end

    % Sort unique numbers in ascending order
    Value=str2num(Value);
    Value=sort(Value,'ascend');
    Value=unique(Value);
    % Remove channels numbers equal to 0 or greater than montage size
    Value(Value==0)=[];
    Value(Value>MaxChan)=[];
    ValueNum=Value;
    ValueNum=num2str(ValueNum);

    % Removed double spaces remaining from previous removal
    Space=strfind(ValueNum,' ');
    SpaceRemove=zeros(1,size(Space,2));
    for i=1:size(Space,2)-1
        if Space(i)==Space(i+1)-1
            SpaceRemove(i)=Space(i+1);
        end
    end
    SpaceRemove(SpaceRemove==0)=[];
    ValueNum(SpaceRemove)=[];
    Removed=ValueNum;
    set(hObject,'String',Removed)
    
end