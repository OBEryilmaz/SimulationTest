% FZ: code adapted and modified based on cosivina toolbox Example E
clear all
close all
clc

%% moving blob 2D

% shared parameters
fieldSize = [100, 150];

% create simulator object
sim = Simulator();

% create inputs (and sum for visualization)
sim.addElement(GaussStimulus2D('stimulus 1', fieldSize, 15, 15, 6, 50, 75, true, false));
sim.addElement(GaussStimulus2D('stimulus 2', fieldSize, 15, 15, 0, 20, 75, true, false));
sim.addElement(SumInputs('stimulus sum', fieldSize), {'stimulus 1', 'stimulus 2'});

% create neural field
sim.addElement(NeuralField('field d', fieldSize, 20, -2, 4), 'stimulus sum');
sim.addElement(NeuralField('field v', fieldSize, 5, -0.5, 4));

% % create interactions
% c_uu = 5; % between 0 - 50
% c_vu = 5;
% c_uv_loc = -0 ; % between 0 - 50 % add minus somehow
% % c_uv_global = -0.5;% between 0 and 1 % add minus somehow

% % lateral interactions in 2D field for u ->u & u ->v
sim.addElement(LateralInteractions2D('d -> d', [100, 150], 5, 5, 5, 10, 10, 5, -0.05), ...
 'field d', 'output', 'field d', 'output');

sim.addElement(LateralInteractions2D('d -> v', [100, 150], 5, 5, 15, 10, 10, 0, -0.05), ...
 'field d', 'output', 'field v', 'output');

% 
% sim.addElement(LateralInteractions2D('v -> d', [100, 150], 5, 5, 15, 10, 10, 0, -0.05), ...
%  'field v', 'output', 'field d', 'output');

% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise d', fieldSize, 1));
sim.addElement(GaussKernel2D('noise kernel d', fieldSize, 0, 0.1, true, true), 'noise d', 'output', 'field d');
sim.addElement(NormalNoise('noise v', fieldSize, 1));
sim.addElement(GaussKernel2D('noise kernel v', fieldSize, 0, 0.1, true, true), 'noise v', 'output', 'field v');
% initialize the simulator
sim.init();


figure,set(gcf, 'units','normalized','outerposition',[0.2 0.2 0.6 0.6]);
for i = 1 : 50
    sim.step();

    % plot field activation again
    subplot(3,2,1),
    imagesc(sim.getComponent('stimulus 1', 'output'));
    xlabel('stimulus 1');
    
    subplot(3,2,2),
    imagesc(sim.getComponent('stimulus 2', 'output'));
    xlabel('stimulus 2');

    subplot(3,2,3),
    imagesc(sim.getComponent('field d', 'activation'));
    xlabel('u activation'); 


    subplot(3,2,4),
    imagesc(sim.getComponent('field d', 'output'));
    xlabel('u output');

    subplot(3,2,5),
    imagesc(sim.getComponent('field v', 'activation'));
    xlabel('V activation');


    subplot(3,2,6),
    imagesc(sim.getComponent('field v', 'output'));colormap('gray')
    xlabel('V output');

    drawnow;

end

% presenting hand-target difference map
hStim=sim.getElement('stimulus 2');
hStim.amplitude  = 6; 
hStim.init();

set(gcf,'Name','press any key to continue');
Coeff=1;
waitforbuttonpress
set(gcf,'Name','moving stage');
for i = 1 : 150
    sim.step();
    hVelocityOutput=sim.getComponent('field v', 'output');
    [rowOfVelocity, colOfVelocity]=find(hVelocityOutput==max(max(hVelocityOutput)));
    
    hHandOutput=sim.getComponent('stimulus 1', 'output');
    [rowOfHand, colOfHand]=find(hHandOutput==max(max(hHandOutput)));
    
    hHand= sim.getElement('stimulus 1');
    hHand.positionX= colOfHand+round((colOfVelocity-colOfHand)*Coeff);
    hHand.positionY= rowOfHand+round((rowOfVelocity-rowOfHand)*Coeff);
    hHand.init();
    
    % plot field activation again
    subplot(3,2,1),
    imagesc(sim.getComponent('stimulus 1', 'output'));
    xlabel('stimulus 1');
    
    subplot(3,2,2),
    imagesc(sim.getComponent('stimulus 2', 'output'));
    xlabel('stimulus 2');
    subplot(3,2,3),
    imagesc(sim.getComponent('field d', 'activation'));
    xlabel('u activation'); 


    subplot(3,2,4),
    imagesc(sim.getComponent('field d', 'output'));
    xlabel('u output');

    subplot(3,2,5),
    imagesc(sim.getComponent('field v', 'activation'));
    xlabel('V activation');


    subplot(3,2,6),
    imagesc(sim.getComponent('field v', 'output'));colormap('gray')
    xlabel('V output');



    drawnow;
end

