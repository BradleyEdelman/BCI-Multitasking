function [hObject,handles]=bci_ESI_HighlightOptions(hObject,handles,fields,highlight)

if ~isempty(fields)
    
    for i=1:size(fields,2)
        
        style=get(handles.(fields{i}),'style');
        
        if strcmp(style,'popupmenu')
            
            value=get(handles.(fields{i}),'value');
            
            switch highlight
                
                case 'on'
                    
                    if isequal(value,1)
                        set(handles.(fields{i}),'backgroundcolor','red')
                    else
                        set(handles.(fields{i}),'backgroundcolor','green')
                    end
                    
                case 'option'
                    
                    if isequal(value,1)
                        set(handles.(fields{i}),'backgroundcolor',[1 .7 0])
                    else
                        set(handles.(fields{i}),'backgroundcolor','green');
                    end
                    
                case 'off'
                    
                    set(handles.(fields{i}),'backgroundcolor','white')
            end
            
        
        elseif strcmp(style,'edit') || strcmp(style,'pushbutton') || strcmp(style,'listbox')
            
            string=get(handles.(fields{i}),'string');
            
            switch highlight
                
                case 'on'
                    
                    if isempty(string) %|| strcmp(string,'')
                        set(handles.(fields{i}),'backgroundcolor','red')
                    else
                        set(handles.(fields{i}),'backgroundcolor','green')
                    end
                    
                case 'option'
                    
                    if isempty(string) || strcmp(string,'')
                        set(handles.(fields{i}),'backgroundcolor',[1 .7 0])
                    else
                        set(handles.(fields{i}),'backgroundcolor','green');
                    end
                    
                case 'off'
                    
                    set(handles.(fields{i}),'backgroundcolor','white')
            end
                    
        elseif strcmp(style,'checkbox')
            
            switch highlight
                
                case 'on'
                case 'option'
                case 'off'
                    set(handles.(fields{i}),'value',0)
            end
            
%         elseif strcmp(style,'pushbutton')
%             
%             switch highlight
%                 
%                 case 'on'
%                 case 'off'
%             end
            
        end
        
    end
    
end
            
            
            
            
            
            
            
            
            
            
            
            
            
            