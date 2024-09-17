function [hObject,handles]=bci_ESI_BCISelect(hObject,handles,ParamType,Dimension)

% ParamType='BCITask';
% Dimension=1;
set(hObject,'BackgroundColor',[.94 .94 .94])
if ismember(ParamType,{'dim','task','freq'})
    
    ParamType=strcat('bci',ParamType);

    totdim=1:3;
    totdim(Dimension)=[];
    
    values=zeros(1,2);
    name=cell(1,2);
    for i=1:size(totdim,2)
        
        object=strcat(ParamType,num2str(totdim(i)));
        values(i)=get(handles.(object),'value');
        
        nameoptions=get(handles.(object),'string');
        name{i}=nameoptions{values(i)};
        
    end
    
    currentvalue=get(hObject,'value');
    nameoptions=get(hObject,'string');
    currentname=nameoptions(currentvalue);
    if strcmp(currentname,' ')
    elseif ~strcmp(currentname,'Custom') && ismember(currentvalue,values)
        set(hObject,'value',1)
        fprintf(2,'CANT DO THAT\n');
    end
    
else
    fprintf(2,'NOPE\n');
end
    





