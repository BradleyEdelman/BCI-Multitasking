%% bci_fESI_StimulusTest



[x,y,z]=meshgrid([-.5 .5],[0 5],[-1 1]);
x=[x(:);0]; y=[y(:);0]; z=[z(:);0];
DT=delaunayTriangulation(x,y,z);
DT2=DT;

figure; set(gcf,'color',[.8 .8 .8])
subplot(1,2,1); 
tetramesh(DT,repmat([0 0 0],[10 1]),'EdgeColor','None','FaceLighting','gouraud');
material('dull');
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
hold on;
scatter3(0,0,0,100,'k','filled')
xlabel('x'); ylabel('y'); zlabel('z'); set(gca,'color',[.8 .8 .8]);
axis([-5 5 -5 5 -5 5]); view(0,35)

theta=25;
theta=theta*pi/180;
Rx=[1 0 0; 0 cos(theta) -sin(theta); 0 sin(theta) cos(theta)];
Ry=[cos(theta) 0 sin(theta); 0 1 0; -sin(theta) 0 cos(theta)];
Rz=[cos(theta) -sin(theta) 0; sin(theta) cos(theta) 0; 0 0 1];

Newpt=Ry*DT.Points';
DT2.Points=Newpt';

subplot(1,2,2); 
hold off
tetramesh(DT2,repmat([0 0 0],[10 1]),'EdgeColor','None','FaceLighting','gouraud');
material('dull');
hold on;
scatter3(0,0,0,100,'k','filled')
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
xlabel('x'); ylabel('y'); zlabel('z'); set(gca,'color',[.8 .8 .8]);
axis([-5 5 -5 5 -5 5]); view(0,35)


%%
lf=stlread('Right_hand_open_LR.stl');

figure; subplot(1,2,1)
xlabel('x'); ylabel('y'); zlabel('z')
p=patch(lf,'FaceColor',       [255 220 177]/255, ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.15);
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
view(0,90);


thetax=-10*pi/180;
Rx=[1 0 0; 0 cos(thetax) -sin(thetax); 0 sin(thetax) cos(thetax)];
thetay=0*pi/180;
Ry=[cos(thetay) 0 sin(thetay); 0 1 0; -sin(thetay) 0 cos(thetay)];
thetaz=-162.5*pi/180;
Rz=[cos(thetaz) -sin(thetaz) 0; sin(thetaz) cos(thetaz) 0; 0 0 1];

lf.vertices=Rz*lf.vertices';
lf.vertices=Rx*lf.vertices;
lf.vertices=Ry*lf.vertices;
lf.vertices=lf.vertices';

subplot(1,2,2)
xlabel('x'); ylabel('y'); zlabel('z')
p=patch(lf,'FaceColor',       [255 220 177]/255, ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.15);
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
view(0,90);

%% RIGHT ARM
close all

DS=.5;
RightOffset=200;

% FOREARM
rf=stlread('Right_forearm_LR.stl');
% Zero the vertix of rotation
VertXY=rf.vertices(:,1)+rf.vertices(:,2);
MaxVert=find(VertXY==max(VertXY));
MaxVert=MaxVert(1);
rf.vertices(:,1)=rf.vertices(:,1)-repmat(rf.vertices(MaxVert,1),[size(rf.vertices,1),1]);
rf.vertices(:,2)=rf.vertices(:,2)-repmat(rf.vertices(MaxVert,2),[size(rf.vertices,1),1]);
rf.vertices(:,3)=rf.vertices(:,3)-repmat(rf.vertices(MaxVert,3),[size(rf.vertices,1),1]);

thetarfx=10*pi/180;
thetarfy=0*pi/180;
thetarfz=-156*pi/180;
Rx=[1 0 0; 0 cos(thetarfx) -sin(thetarfx); 0 sin(thetarfx) cos(thetarfx)];
Ry=[cos(thetarfy) 0 sin(thetarfy); 0 1 0; -sin(thetarfy) 0 cos(thetarfy)];
Rz=[cos(thetarfz) -sin(thetarfz) 0; sin(thetarfz) cos(thetarfz) 0; 0 0 1];

rf.vertices=Rx*rf.vertices';
rf.vertices=Ry*rf.vertices;
rf.vertices=Rz*rf.vertices;
rf.vertices=rf.vertices';
rf.vertices(:,1)=rf.vertices(:,1)+RightOffset;

figure(1); hold on; xlabel('x'); ylabel('y'); zlabel('z'); grid on
rfh=patch(rf,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength',0.15,'FaceAlpha',.5);
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);

% DS
figure(2);
rfDS=reducepatch(rfh,DS);
patch(rfDS,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
 'FaceLighting','gouraud','AmbientStrength',0.15);
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);

% HAND
rh=stlread('Right_hand_close3_LR.stl');
% Zero the vertix of rotation
MaxVert=find(rh.vertices(:,2)==max(rh.vertices(:,2)));
MaxVert=MaxVert(1);
rh.vertices(:,1)=rh.vertices(:,1)-repmat(rh.vertices(MaxVert,1),[size(rh.vertices,1),1]);
rh.vertices(:,2)=rh.vertices(:,2)-repmat(rh.vertices(MaxVert,2),[size(rh.vertices,1),1]);
rh.vertices(:,3)=rh.vertices(:,3)-repmat(rh.vertices(MaxVert,3),[size(rh.vertices,1),1]);

% Apply rotation
thetarhx=10*pi/180;
thetarhy=0*pi/180;
thetarhz=-156*pi/180;
Rx=[1 0 0; 0 cos(thetarhx) -sin(thetarhx); 0 sin(thetarhx) cos(thetarhx)];
Ry=[cos(thetarhy) 0 sin(thetarhy); 0 1 0; -sin(thetarhy) 0 cos(thetarhy)];
Rz=[cos(thetarhz) -sin(thetarhz) 0; sin(thetarhz) cos(thetarhz) 0; 0 0 1];

rh.vertices=Rx*rh.vertices';
rh.vertices=Ry*rh.vertices;
rh.vertices=Rz*rh.vertices;
rh.vertices=rh.vertices';
rh.vertices(:,1)=rh.vertices(:,1)+RightOffset;

% Apply offset to line up with forearm
rh.vertices(:,1)=rh.vertices(:,1)+21;
rh.vertices(:,2)=rh.vertices(:,2)+315;

figure(1);
rhh=patch(rh,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength', 0.15);

figure(2);
rhDS=reducepatch(rhh,DS);
patch(rhDS,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
 'FaceLighting','gouraud','AmbientStrength',0.15);
     
%% LEFT ARM

LeftOffset=-200;

% FOREARM
lf=stlread('Left_forearm_LR.stl');
% Zero the vertix of rotation
VertXY=(500-lf.vertices(:,1))+lf.vertices(:,2);
MaxVert=find(VertXY==max(VertXY));
MaxVert=MaxVert(1);
lf.vertices(:,1)=lf.vertices(:,1)-repmat(lf.vertices(MaxVert,1),[size(lf.vertices,1),1]);
lf.vertices(:,2)=lf.vertices(:,2)-repmat(lf.vertices(MaxVert,2),[size(lf.vertices,1),1]);
lf.vertices(:,3)=lf.vertices(:,3)-repmat(lf.vertices(MaxVert,3),[size(lf.vertices,1),1]);

thetalfx=10*pi/180;
thetalfy=0*pi/180;
thetalfz=156*pi/180;
Rx=[1 0 0; 0 cos(thetalfx) -sin(thetalfx); 0 sin(thetalfx) cos(thetalfx)];
Ry=[cos(thetalfy) 0 sin(thetalfy); 0 1 0; -sin(thetalfy) 0 cos(thetalfy)];
Rz=[cos(thetalfz) -sin(thetalfz) 0; sin(thetalfz) cos(thetalfz) 0; 0 0 1];

lf.vertices=Rx*lf.vertices';
lf.vertices=Ry*lf.vertices;
lf.vertices=Rz*lf.vertices;
lf.vertices=lf.vertices';
lf.vertices(:,1)=lf.vertices(:,1)+LeftOffset;

% figure; hold on; xlabel('x'); ylabel('y'); zlabel('z'); grid on
figure(1)
lfh=patch(lf,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength',0.15,'FaceAlpha',.5);
     
figure(2);
lfDS=reducepatch(lfh,DS);
patch(lfDS,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
 'FaceLighting','gouraud','AmbientStrength',0.15);

% HAND
lh=stlread('Left_hand_close3_LR.stl');
% Zero the vertix of rotation
MaxVert=find(lh.vertices(:,2)==max(lh.vertices(:,2)));
MaxVert=MaxVert(1);
lh.vertices(:,1)=lh.vertices(:,1)-repmat(lh.vertices(MaxVert,1),[size(lh.vertices,1),1]);
lh.vertices(:,2)=lh.vertices(:,2)-repmat(lh.vertices(MaxVert,2),[size(lh.vertices,1),1]);
lh.vertices(:,3)=lh.vertices(:,3)-repmat(lh.vertices(MaxVert,3),[size(lh.vertices,1),1]);

% Apply rotation
thetalhx=10*pi/180;
thetalhy=0*pi/180;
thetalhz=156*pi/180;
Rx=[1 0 0; 0 cos(thetalhx) -sin(thetalhx); 0 sin(thetalhx) cos(thetalhx)];
Ry=[cos(thetalhy) 0 sin(thetalhy); 0 1 0; -sin(thetalhy) 0 cos(thetalhy)];
Rz=[cos(thetalhz) -sin(thetalhz) 0; sin(thetalhz) cos(thetalhz) 0; 0 0 1];

lh.vertices=Rx*lh.vertices';
lh.vertices=Ry*lh.vertices;
lh.vertices=Rz*lh.vertices;
lh.vertices=lh.vertices';
lh.vertices(:,1)=lh.vertices(:,1)+LeftOffset;

% Apply offset to line up with forearm
lh.vertices(:,1)=lh.vertices(:,1)-21;
lh.vertices(:,2)=lh.vertices(:,2)+315;

figure(1)
lhh=patch(lh,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength', 0.15);

figure(2)
lhDS=reducepatch(lhh,DS);
patch(lhDS,'FaceColor',[255 220 177]/255,'EdgeColor','none',...
 'FaceLighting','gouraud','AmbientStrength',0.15);

 
%% CHECK
clear lf lh rf rh

load('Left_Hand_Close2_Orient.mat')
load('Left_Forearm_Orient.mat')
load('Right_Hand_Close2_Orient.mat')
load('Right_Forearm_Orient.mat')

figure;clf

lhh=patch(lh,'FaceColor',[255 224 196]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength', 0.15);

lfh=patch(lf,'FaceColor',[255 224 196]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength', 0.15);
     
rhh=patch(rh,'FaceColor',[255 224 196]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength', 0.15);
     
rfh=patch(rf,'FaceColor',[255 224 196]/255,'EdgeColor','none',...
         'FaceLighting','gouraud','AmbientStrength', 0.15);

light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
axis([-300 300 0 550 -100 100]);
set(gca,'color','k'); set(gcf,'color','k')
     
     
     