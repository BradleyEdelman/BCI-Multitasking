function [taskorder,taskhit]=bci_ESI_SSVEPTaskOrder2(numtrial,numtask,targets)

if isempty(numtrial)
    numtrial=180; % divisible by 2,3,4
end

taskorder=[];
                
% No repeated stimuli (since will change stimuli will indicate a hit)
idx=randi(numtask,1);
taskorder=[taskorder;targets(idx)];
for i=2:numtrial
    options=1:numtask;
    options(options==idx)=[];
    optionidx=randi(numtask-1,1);
    taskorder=[taskorder;targets(options(optionidx))];
    idx=find(strcmp(taskorder{end},targets));
end

taskhit=taskorder;



