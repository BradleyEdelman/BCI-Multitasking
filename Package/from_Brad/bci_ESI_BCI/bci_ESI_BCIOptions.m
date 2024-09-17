function [handles,hObject]=bci_ESI_BCIOptions(handles,hObject,feattype,tempdomain,sigtype)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          POPULATE BCI OPTIONS                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spatdomainfield=handles.TRAINING.spatdomainfield;
numtask=handles.TRAINING.(spatdomainfield).(sigtype).datainfo.numtask;
combinations=combnk(1:numtask,2);
numcomb=size(combinations,1);

switch sigtype
    
    case 'SMR'

    % REMOVE ALL SELECTED FEATURES FROM DISPLAY LIST - REPOPULATE HERE
    [hObject,handles]=bci_ESI_RemoveFeature(hObject,handles,spatdomainfield,feattype,tempdomain);
    
    % ADD BCI TASKS TO FEATURE OPTIONS
    bcitask=cell(1,numcomb+1);
    bcitask{2}='Custom';
    for i=1:numcomb
        bcitask{i+2}=[num2str(combinations(i,1)) '-vs-' num2str(combinations(i,2))];
    end

    bcitask{end+1}='All Class';
    % for i=numcomb+2:2*numcomb+1
    %     bcitask{i}=[num2str(combinations(i-1-numcomb,1)) ' , ' num2str(combinations(i-1-numcomb,2)) ' vs Rest'];
    % end

    % for i=1:2*numcomb+2:3*numcomb+1
    %     bcitask{i}=[num2str(combinations(i-1-numcomb,1)) ' , ' num2str(combinations(i-1-numcomb,2)) ' vs All'];
    % end

    set(handles.bcitask1,'string',bcitask,'value',1)
    set(handles.bcitask2,'string',bcitask,'value',1)
    set(handles.bcitask3,'string',bcitask,'value',1)
    handles.(spatdomainfield).bcitask{1}=bcitask;
    handles.(spatdomainfield).bcitask{2}=bcitask;
    handles.(spatdomainfield).bcitask{3}=bcitask;

    % ADD TASKS TO FEAUTRE OPTIONS
    handles.BCI.featureoptions.task.(spatdomainfield)=bcitask;

    % BCI FREQUENCIES
    broadband=get(handles.broadband,'value');
    freqvect=handles.TRAINING.(spatdomainfield).param.mwparam.freqvect;
    if isequal(broadband,1)
        bcifreq=[cell(1),{'Broadband'}];
    else
        bcifreq=[cell(1);cellstr(num2str(freqvect'));{'Broadband'}];
    end
    set(handles.bcifreq1,'string',bcifreq,'value',1)
    set(handles.bcifreq2,'string',bcifreq,'value',1)
    set(handles.bcifreq3,'string',bcifreq,'value',1)
    handles.(spatdomainfield).bcifreq{1}=[cell(1);cellstr(num2str(freqvect'))];
    handles.(spatdomainfield).bcifreq{2}=[cell(1);cellstr(num2str(freqvect'))];
    handles.(spatdomainfield).bcifreq{3}=[cell(1);cellstr(num2str(freqvect'))];

    % ADD FREQUENCIES TO FEAUTRE OPTIONS
    handles.BCI.featureoptions.freq.(spatdomainfield)=bcifreq;

    % ORGANIZE FEATURE OPTIONS
    for i=1:3
        featvar=strcat('bcifeat',num2str(i));
        bcifeat=cellstr(get(handles.(featvar),'string'));
        if isempty(bcifeat); bcifeat=cell(1); end
        if ~ismember(feattype,bcifeat)
            bcifeat=[bcifeat;feattype];
        end
        set(handles.(featvar),'string',bcifeat)
    end

    % ADD FEATURE TYPE TO FEATURE OPTIONS
    if ~ismember(feattype,handles.BCI.featureoptions.feat.(spatdomainfield))
        handles.BCI.featureoptions.feat.(spatdomainfield){end+1}=feattype;
    end

    % RESET BCI PARAMETERS
    [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,1,'Reset');
    [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,2,'Reset');
    [hObject,handles]=bci_ESI_ResetBCI(hObject,handles,3,'Reset');

case 'SSVEP'
    
%     ssveptask=cell(1,numcomb+1);
%     for i=1:numcomb
%         ssveptask{i+1}=[num2str(combinations(i,1)) '-vs-' num2str(combinations(i,2))];
%     end
%     
%     ssveptask{end+1}='All Class';
%     set(handles.ssveptask,'string',ssveptask,'value',1)
%     handles.(spatdomainfield).ssveptask{1}=ssveptask;
    
    ssveptask=get(handles.ssveptask,'string');
    set(handles.ssveptask,'value',1)
%     handles.(spatdomainfield).ssveptask{1}=ssveptask;
    
    
    % ORGANIZE FEATURE OPTIONS
    ssvepfeat=cellstr(get(handles.ssvepfeat,'string'));
    if isempty(ssvepfeat); ssvepfeat=cell(1); end
    if ~ismember(feattype,ssvepfeat)
        ssvepfeat=[ssvepfeat;feattype];
    end
    set(handles.ssvepfeat,'string',ssvepfeat)
    
    
end

    
    
    
    
    
    
    