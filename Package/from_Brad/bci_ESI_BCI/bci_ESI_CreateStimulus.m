function [hObject,handles]=bci_ESI_CreateStimulus(hObject,handles)

paradigm=get(handles.paradigm,'value');

% Close all waitbars
close(findall(0,'Tag','TMWWaitbar'))

% Close all figures except for GUI
currentfig=findobj('Type','figure');
for i=size(currentfig,1):-1:1
    close(figure(i))
end

switch paradigm
    
    case {2,3} % Discrete Trial Cursor, Continuous Pursuit Cursor
        
    case {4,5} % Discrete Trial Hand, Continuous Pursuit Hand
        
        handles.Stimulus.general.fig=figure(1); clf

        set(handles.Stimulus.general.fig,'MenuBar','none','ToolBar','none',...
            'color',[.15 .15 .15],'units','normalized','outerposition',[0 0 1 1]);
        delete(findall(gcf,'Type','light'))
        light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
        colormap(jet)
        handles.Stimulus.general.fixation=text(0,450,'+','FontSize',50,...
            'Color','white','HorizontalAlignment','center');
        hold on; set(gca,'color',[.15 .15 .15]);
        axis([-350 350 100 550 -100 100]); axis off; view(0,80); rotate3d on

        load('Left_Hand_Close2_Orient_10per.mat'); lh=lhDS;
        load('Left_Forearm_Orient_10per.mat'); lf=lfDS;
        load('Right_Hand_Close2_Orient_10per.mat'); rh=rhDS;
        load('Right_Forearm_Orient_10per.mat'); rf=rfDS;

        handles.Stimulus.Hand.lefthand=lh;
        handles.Stimulus.Hand.lefthandplot=patch(lh,'FaceColor',[255 224 196]/255,...
            'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
        vertxy=lh.vertices(:,1)+lh.vertices(:,2);
        minvert=find(vertxy==min(vertxy)); minvert=minvert(1);
        handles.Stimulus.Hand.lefthandoffset=lh.vertices(minvert,1:2);

        handles.Stimulus.Hand.leftforearm=lf;
        handles.Stimulus.Hand.leftforearmplot=patch(lf,'FaceColor',[255 224 196]/255,...
            'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
        vertxy=lf.vertices(:,1)+lf.vertices(:,2);
        minvert=find(vertxy==min(vertxy)); minvert=minvert(1);
        handles.Stimulus.Hand.leftforearmoffset=lf.vertices(minvert,1:2);

        handles.Stimulus.Hand.righthand=rh;
        handles.Stimulus.Hand.righthandplot=patch(rh,'FaceColor',[255 224 196]/255,...
            'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
        vertxy=rh.vertices(:,1)+rh.vertices(:,2);
        minvert=find(vertxy==min(vertxy)); minvert=minvert(end);
        handles.Stimulus.Hand.righthandoffset=rh.vertices(minvert,1:2);

        handles.Stimulus.Hand.rightforearm=rf;
        handles.Stimulus.Hand.rightforearmplot=patch(rf,'FaceColor',[255 224 196]/255,...
            'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
        vertxy=rf.vertices(:,1)+rf.vertices(:,2);
        minvert=find(vertxy==min(vertxy)); minvert=minvert(1);
        handles.Stimulus.Hand.rightforearmoffset=rf.vertices(minvert,1:2);

        handles.Stimulus.general.text=text(0,550,'WAITING TO START...',...
            'FontSize',75,'color','yellow','HorizontalAlignment','center');

        gosignal=text(0,350,'','FontSize',50,'color','white',...
            'HorizontalAlignment','center');
        handles.Stimulus.general.go=gosignal;
        
        if isequal(paradigm,5)
            
            % CREATE PHANTOM HAND AS TARGET
           
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CREATE SMALLER TARGET HANDS IN SIDE AXES
            
            % RIGHT HAND
            rhtar=rh;
            rhtar.vertices=rhtar.vertices*.5;
            rhtar.vertices(:,1)=rhtar.vertices(:,1)+185;
            rhtar.vertices(:,2)=rhtar.vertices(:,2)+325;
            rhtar.vertices(:,3)=rhtar.vertices(:,3)+0;
            handles.Stimulus.Hand.righthandtargetplot=rhtar;
            
            vertxy=rhtar.vertices(:,1)+rhtar.vertices(:,2);
            minvert=find(vertxy==min(vertxy)); minvert=minvert(1);
            handles.Stimulus.Hand.righthandtargetoffset=rhtar.vertices(minvert,1:2);
            
            % LEFT HAND
            lhtar=lh;
            lhtar.vertices=lhtar.vertices*.5;
            lhtar.vertices(:,1)=lhtar.vertices(:,1)-185;
            lhtar.vertices(:,2)=lhtar.vertices(:,2)+325;
            lhtar.vertices(:,3)=lhtar.vertices(:,3)+0;
            handles.Stimulus.Hand.lefthandtargetplot=lhtar;
            
            vertxy=lhtar.vertices(:,1)+lhtar.vertices(:,2);
            minvert=find(vertxy==min(vertxy)); minvert=minvert(1);
            handles.Stimulus.Hand.lefthandtargetoffset=lhtar.vertices(minvert,1:2);
            
        end
      

    case {6,7,8} % Discrete Trial Cursor + SSVEP, SSVEP
        
        % Create fig and set up for SSVEP
        handles.Stimulus.general.fig=figure(1); clf
        set(handles.Stimulus.general.fig,'MenuBar','none','ToolBar','none',...
            'color',[0 0 0],'units','normalized','outerposition',[0 0 1 1]);
        set(handles.Stimulus.general.fig,'units','pixels')
        pos=get(handles.Stimulus.general.fig,'position');
        hold on; set(gca,'color',[0 0 0]);

        set(gca,'position',[.01 .01 .98 .98])
        axis([0 pos(3) 0 pos(4)]); axis off; view(2)
        
        % For SSVEP
        if ismember(paradigm,[6 7])
            I=handles.BCI.SSVEP.control.image;
            Isz=size(I{1});
            xdiff=(pos(3)-Isz(2))/2;
            ydiff=(pos(4)-Isz(1))/2;
            handles.Stimulus.SSVEP=struct;
            handles.Stimulus.SSVEP.image=imshow(I{end},'xdata',[xdiff xdiff+Isz(2)],...
                'ydata',[ydiff ydiff+Isz(1)]);
            axis xy
        end
        
        % For Cursor
        if ismember(paradigm,[6 8])
            
            % Always make workspace square
            sz=pos(3:4);
            minidx=find(sz==min(sz));
            offset=(sz-sz(minidx))/2;
            offset(offset==0)=[];

            task=handles.BCI.SMR.param.task;
            
            if strcmp(task,'Horizontal') % 1 left, 2 right
                
                targetsx=[0 .92]*sz(minidx);
                targetsy=[.25 .25]*sz(minidx);
                targetsw=[.08 .08]*sz(minidx);
                targetsh=[.5 .5]*sz(minidx);
                
            elseif strcmp(task,'Vertical') % 3 up, 4 down
                
                targetsx=[.25 .25]*sz(minidx);
                targetsy=[0 .92]*sz(minidx);
                targetsw=[.5 .5]*sz(minidx);
                targetsh=[.08 .08]*sz(minidx);
                
            elseif strcmp(task,'2D') % 1 left, 2 right, 3 up, 4 down
                
                targetsx=[0 .92 .25 .25]*sz(minidx);
                targetsy=[.25 .25 0 .92]*sz(minidx);
                targetsw=[.08 .08 .5 .5]*sz(minidx);
                targetsh=[.5 .5 .08 .08]*sz(minidx);
                
            end
            
            if isequal(minidx,2)
                targetsx=targetsx+offset;
                offset=[offset 0];
            elseif isequal(minidx,1)
                 targetsy=targetsy+offset;
                 offset=[0 offset];
            end
            
            % Create targets and cursor - all invisible to start
            handles.Stimulus.Cursor.target=[];
            for i=1:size(targetsx,2)
                handles.Stimulus.Cursor.target(i)=rectangle('position',...
                    [targetsx(i) targetsy(i) targetsw(i) targetsh(i)],...
                    'facecolor',[.15 .15 .15],'edgecolor',[.15 .15 .15]);
            end
            axis xy
            
            handles.Stimulus.Cursor.cursorpos=scatter(pos(3)/2,pos(4)/2,...
                pi*(.05*sz(minidx))^2,[.15 .15 .15],'filled');
            
            handles.Stimulus.Cursor.cursorsize=sz(minidx);
            handles.Stimulus.Cursor.cursoroffset=offset;
            
        end
        
        handles.Stimulus.general.text=text(pos(3)/2,pos(4)/2,'Be Prepared...',...
            'FontSize',125,'color','green','HorizontalAlignment','center',...
            'VerticalAlignment','middle');
end