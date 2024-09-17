function [hObject,handles]=bci_ESI_Noise(hObject,handles)

spatdomain=get(handles.spatdomain,'value');
switch spatdomain
    case 1 % None
    case 2 % Sensor
    case 3 % ESI
        noise=get(hObject,'value');
        switch noise
            case 1 % None
                set(hObject,'backgroundcolor','red')
                set(handles.noisefile,'backgroundcolor','white')
            case 2 % None or no noise estimation
                set(hObject,'backgroundcolor','white')
                set(handles.noisefile,'backgroundcolor','white')
            case {3,4} % Diagonal or full noise covariance
                noisefile=get(handles.noisefile,'string');
                set(hObject,'backgroundcolor','white')
                if isempty(noisefile)
                    set(handles.noisefile,'backgroundcolor',[1 .7 0])
                else
                    set(handles.noisefile,'backgroundcolor','white')
                end
        end
end