function [handles,hObject,taskorder,taskhit]=bci_ESI_SSVEPTaskOrder(handles,hObject,numtask,targets)

% No repeated stimuli (since will change stimuli will indicate a hit)
idx=randi([1 numtask],1);
taskorder=[taskorder;targets(idx)];
for i=2:numtrial
    options=1:numtask;
    options(options==idx)=[];
    optionidx=randi([1 numtask-1],1);
    taskorder=[taskorder;targets(options(optionidx))];
    idx=find(strcmp(taskorder{end},targets));
end

taskhit=taskorder;