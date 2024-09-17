function [hObject,handles]=bci_ESI_EnterNum(hObject,handles,cfg)

if ~isfield(cfg,'varname') || isempty(cfg.varname)
    error('Variable name required');
else
    varname=cfg.varname;
end

if ~isfield(cfg,'defaultnum')
    defaultnum=0;
else
    defaultnum=cfg.defaultnum;
end

if ~isfield(cfg,'highbound')
    highbound=inf;
else
    highbound=cfg.highbound;
end

if ~isfield(cfg,'lowbound')
    lowbound=-inf;
else
    lowbound=cfg.lowbound;
end

if ~isfield(cfg,'length')
    length=2;
else
    length=cfg.length;
end

if ~isfield(cfg,'numbers')
    numbers=1;
else
    numbers=cfg.numbers;
end

if numbers>1
    value=sort(unique(str2num(get(hObject,'string'))));
else
	value=str2double(get(hObject,'string'));
end

if isempty(value)
    set(hObject,'backgroundcolor','white')
else
    set(hObject,'backgroundcolor','green')
    % Entered text must be a real and positive number
    newvalue=[];
    for i=1:size(value,2)

        valueidx=value(i);

        if isnan(valueidx) || ~isreal(valueidx) || valueidx<lowbound || valueidx>highbound
        elseif size(num2str(valueidx),2)<length
            tmp=valueidx;
            for j=1:length-size(num2str(tmp),2)
                tmp=strcat('0',num2str(tmp));
            end
            if isempty(newvalue)
                newvalue=tmp;
            else
                newvalue=[newvalue ' ' tmp];
            end
        else
            if isempty(newvalue)
                newvalue=num2str(valueidx);
            else
                newvalue=[newvalue ' ' num2str(valueidx)];
            end
        end

    end

    if isempty(newvalue)
        set(hObject,'backgroundcolor','red','string',num2str(defaultnum));
        fprintf(2,'MUST ENTER NUMERIC VALUE(S) BETWEEN %.2f AND %.2f FOR %s\n',lowbound,highbound,varname);
    else
        set(hObject,'string',newvalue)
    end
end





