function [plotting,event,control]=bci_ESI_HandMovement(stimulus,flags,event,control,type)

v2struct(flags)

% DEFINE HAND RANGE OF MOTION
ROM=hitcriteria(2)-hitcriteria(1);

if isequal(paradigm,5)
% DETERMINE SIZE OF WORKSPACE
if isempty(event.sqsize) && ~isequal(event.targetpos.orig,[0 0])
    event.sqsize=round(event.targetpos.orig(1)/100)*100*2;
end

switch type
    
    case {'righthand','lefthand'} % Cursor
        
        % NORMALIZE CURSOR POSITION
        cursorpostmp=event.cursorpos.win(end,:);
        cursorpostmp=cursorpostmp/event.sqsize;
        
        % MAP NORMALIZED CURSOR POSITION TO HAND ROTATION
        
        % Control.stim already calculated for DT HM
        if isequal(control,zeros(3,1))
            for i=1:2
                control(i)=hitcriteria(2)-cursorpostmp(i)*ROM;
            end
        end
        
        rotation=control;
        
    case {'righthandtarget','lefthandtarget'} % Target
        
        % NORMALIZE TARGET POSITION
        targetpostmp=event.targetpos.win(end,:);
        targetpostmp=targetpostmp/event.sqsize;
        
        % MAP NORMALIZED TARGET POSITION TO HAND ROTATION
        targpos=zeros(1,3);
        for i=1:2
            targpos(i)=hitcriteria(2)-targetpostmp(i)*ROM;
        end
        
        rotation=targpos;
        
end

elseif isequal(paradigm,4)
    
    rotation=control;
    
end

% GENERATE ROTATION MATRICES
% Flexion(+)/Extension(-)
Rz=[cos(rotation(1)) -sin(rotation(1)) 0;...
    sin(rotation(1)) cos(rotation(1)) 0; 0 0 1];
% Supination(+)/Pronation(-)
Ry=[cos(rotation(2)) 0 sin(rotation(2));...
    0 1 0; -sin(rotation(2)) 0 cos(rotation(2))];
% Abduction(+)/Adduction(-)
Rx=[1 0 0; 0 cos(rotation(3)) -sin(rotation(3));...
    0 sin(rotation(3)) cos(rotation(3))];

% EXTRACT SURFACE TO PLOT
plotting=stimulus.Hand.(type);
pointstmp=plotting.vertices;

% Bring predefined vertex to origin before rotating
offsetfield=strcat(type,'offset');
pointstmp(:,1)=pointstmp(:,1)-stimulus.Hand.(offsetfield)(1);
pointstmp(:,2)=pointstmp(:,2)-stimulus.Hand.(offsetfield)(2);

% Apply Rotation
pointstmp=pointstmp';
pointstmp=Rx*pointstmp;
pointstmp=Ry*pointstmp;
pointstmp=Rz*pointstmp;
pointstmp=pointstmp';

% Add offset back to vertices
pointstmp(:,1)=pointstmp(:,1)+stimulus.Hand.(offsetfield)(1);
pointstmp(:,2)=pointstmp(:,2)+stimulus.Hand.(offsetfield)(2);

plotting.vertices=pointstmp;






