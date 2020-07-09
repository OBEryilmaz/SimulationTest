% Launcher for a simulation of two coupled dynamic nodes. The rates of
% change in dependence of the node activation are plotted, with attractor
% and repellor states marked.
% Hover over sliders and buttons to see a description of their function.

clear all;
close all;
clc;
%Pick the image for target selection
pwd = 'C:\Users\omer\Desktop\cosivina';
%randperm()
ImageNumber=1; % randi(6); % The image has a target in the middle
ImageName=sprintf('%d.png', ImageNumber);
targetImage = imread(ImageName);
[SizeX, SizeY, colour]=size(targetImage);
fieldSize=[SizeX, SizeY];
currentSelection = 1;

%% setting up the simulator
connectionValue = -2; %Amplitude for connections can be different for each one
historyDuration = 100;
samplingRange = [-10, 10];
samplingResolution = 0.05;
tStimOn=100;

sigmaInhY = 10;
sigmaInhX = 10;
amplitudeInh_dv = 0.8;
sigmaExcY = 5;
sigmaExcX = 5;
amplitudeExc = 5;

amplitudeGlobal_dd=-0.01;
amplitudeGlobal_dv=-0.005;

sim = Simulator();

sim.addElement(BoostStimulus('stimulusRed', 5));
sim.addElement(BoostStimulus('stimulusGreen', 10));

sim.addElement(ModifiedImageLoader('targetImage',pwd,ImageName,fieldSize,currentSelection,[tStimOn, inf]));

% For tunning, input parameters can be controlled by sliders

sim.addElement(SingleNodeDynamics('nodeRed', 100, -1.5, 4, 1, -0.05, samplingRange, samplingResolution), 'targetImage','inputForRed');
sim.addElement(SingleNodeDynamics('nodeGreen', 100, -1.5, 4, 1, -0.05, samplingRange, samplingResolution), 'targetImage','inputForGreen');
% sim.addElement(SingleNodeDynamics('nodeRed', 20, -5, 4, 0, 0, samplingRange, samplingResolution), 'stimulusRed');
% sim.addElement(SingleNodeDynamics('nodeGreen', 20, -5, 4, 0, 0, samplingRange, samplingResolution), 'stimulusGreen');

sim.addElement(Preprocessing('preprocessing'));
sim.addConnection('targetImage','imageRed','preprocessing');
sim.addConnection('targetImage','imageGreen','preprocessing');
sim.addConnection('nodeRed','output','preprocessing');
sim.addConnection('nodeGreen','output','preprocessing');

sim.addElement(NeuralField('targetLocationMap', fieldSize, 5, -1, 4));
sim.addConnection('preprocessing','output','targetLocationMap');

threshold=-5;

sim.addElement(ModifiedGaussStimulus2D('hand', fieldSize, 15,15, (-1*threshold), fieldSize(:,1)/2, fieldSize(:,2)/2));

sim.addElement(ModifiedGaussStimulus2D('fixedStimuli', fieldSize, 15, 15, (-1*threshold), fieldSize(:,1)/2, fieldSize(:,2)/2));
sim.addElement(ModifiedConvolution('handTargetDifferenceMap', fieldSize , 1 ,0,9.3), {'hand', 'targetLocationMap'},{'output','output'});

% add d field

sim.addElement(NeuralField('field d', fieldSize, 20, threshold, 4),{'fixedStimuli','handTargetDifferenceMap'},{'output','output'});
sim.addElement(NeuralField('velocityMap', fieldSize, 5, (threshold+4.8), 4));
% sim.addElement(LateralInteractions2D('d -> d', [100, 150], 5, 5, 5, 10, 10, 5, -0.05), ...
%  'field d', 'output', 'field d', 'output');

%LateralInteractions2D(label, size, sigmaExcY, sigmaExcX, amplitudeExc, ...
%     sigmaInhY, sigmaInhX, amplitudeInh, amplitudeGlobal, ...
%     circularY, circularX, normalized, cutoffFactor)

% there is no local inhibition from d to d
sim.addElement(LateralInteractions2D('d -> d', fieldSize, sigmaExcY,sigmaExcX, amplitudeExc, sigmaInhY, sigmaInhX, 0, amplitudeGlobal_dd), 'field d', 'output', 'field d');
sim.addElement(LateralInteractions2D('d -> v', fieldSize, sigmaExcY,sigmaExcX, amplitudeExc, sigmaInhY, sigmaInhX, amplitudeInh_dv, amplitudeGlobal_dv), 'field d', 'output', 'velocityMap');


%sim.addElement(LateralInteractions2D('v -> d (local)', fieldSize, sigma_inhY,sigma_inhX, 12.5, true, true), 'velocityMap', 'output', 'field d');
%sim.addElement(SumDimension('v -> d (global)', 2,1,fieldSize), 'velocityMap', 'output', 'field d');
%sim.addElement(SumInputs('v -> d (global)', fieldSize), 'velocityMap', 'output', 'field d');
% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise u', fieldSize, 1));
sim.addElement(GaussKernel2D('noise kernel u', fieldSize, 5, 5, 0.1, true, true), 'noise u', 'output', 'field d');
sim.addElement(NormalNoise('noise v', fieldSize, 1));
sim.addElement(GaussKernel2D('noise kernel v', fieldSize, 5, 5, 0.1, true, true), 'noise v', 'output', 'velocityMap');


sim.addElement(ScaleInput('c_21', [1, 1]), 'nodeRed', 'output', 'nodeGreen');
sim.addElement(ScaleInput('c_12', [1, 1]), 'nodeGreen', 'output', 'nodeRed');
% hC_21= sim.getElement('c_21'); hC_21.output=-6;
% hC_12= sim.getElement('c_12'); hC_12.output=-6;


sim.addElement(RunningHistory('historyRedNodeActivation', [1, 1], historyDuration, 1), 'nodeRed', 'activation');
sim.addElement(RunningHistory('historyRedNodeOutput', [1, 1], historyDuration, 1), 'nodeRed', 'output'); % This added
sim.addElement(RunningHistory('historyGreenNodeActivation', [1, 1], historyDuration, 1), 'nodeGreen', 'activation');
sim.addElement(RunningHistory('historyGreenNodeOutput', [1, 1], historyDuration, 1), 'nodeGreen', 'output');

sim.addElement(SumInputs('shiftedStimulusRed', [1, 1]), {'targetImage', 'nodeRed'}, {'inputForRed', 'h'});
sim.addElement(SumInputs('shiftedStimulusGreen', [1, 1]), {'targetImage', 'nodeGreen'}, {'inputForGreen', 'h'});

sim.addElement(RunningHistory('stimulusHistoryRed', [1, 1], historyDuration, 1), 'shiftedStimulusRed');
sim.addElement(RunningHistory('stimulusHistoryGreen', [1, 1], historyDuration, 1), 'shiftedStimulusGreen');


%% setting up the GUI
elementGroups = {'nodeRed', 'nodeGreen', 'stimulusRed', 'stimulusGreen','velocityMap','d -> d','d -> v'};

gui = StandardGUI(sim, [50, 50, 1020, 500], 0, [0.0, 0.0, 0.75, 1.0], [4, 3], [0.02, 0.04], ...
    [0.75, 0.0, 0.25, 1.0], [20, 2], elementGroups, elementGroups);


gui.addVisualization(MultiPlot({'nodeRed', 'stimulusHistoryRed', 'historyRedNodeActivation','historyRedNodeOutput'}, {'activation', 'output','output','output'}, ...
    [1, 1, 1, 1], 'horizontal', ...
    {'XLim', [-historyDuration, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
    { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, ...
    {'b-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, {'r-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1} }, ...
    'nodeRed', 'relative time', 'activation','output'), [1, 2]);
gui.addVisualization(MultiPlot({'nodeGreen', 'stimulusHistoryGreen', 'historyGreenNodeActivation','historyGreenNodeOutput'}, {'activation', 'output', 'output','output'}, ...
    [1, 1, 1, 1], 'horizontal', ...
    {'XLim', [-historyDuration, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
    { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, ...
    {'b-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, {'r-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}},...
    'nodeGreen', 'relative time', 'activation','output'), [2, 2]);

gui.addVisualization(XYPlot({[], 'nodeRed', 'nodeRed', 'nodeRed'}, ...
    {samplingRange(1):samplingResolution:samplingRange(2), 'attractorStates', 'repellorStates', 'activation'}, ...
    {'nodeRed', 'nodeRed', 'nodeRed', 'nodeRed'}, ...
    {'sampledRatesOfChange', 'attractorRatesOfChange', 'repellorRatesOfChange' 'rateOfChange'}, ...
    {'XLim', samplingRange, 'YLim', [-1, 1], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
    { {'r', 'LineWidth', 2}, {'ks'}, {'kd'}, {'ro', 'MarkerFaceColor', 'r'} }, ...
    'activation dynamics node Red', 'activation', 'rate of change'), [3, 2]);
gui.addVisualization(XYPlot({[], 'nodeGreen', 'nodeGreen', 'nodeGreen'}, ...
    {samplingRange(1):samplingResolution:samplingRange(2), 'attractorStates', 'repellorStates', 'activation'}, ...
    {'nodeGreen', 'nodeGreen', 'nodeGreen', 'nodeGreen'}, ...
    {'sampledRatesOfChange', 'attractorRatesOfChange', 'repellorRatesOfChange' 'rateOfChange'}, ...
    {'XLim', samplingRange, 'YLim', [-1, 1], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
    { {'r', 'LineWidth', 2}, {'ks'}, {'kd'}, {'ro', 'MarkerFaceColor', 'r'} }, ...
    'activation dynamics node Green', 'activation', 'rate of change'), [4, 2]);
%'field d'
gui.addVisualization(RGBImage('targetImage', 'image', {'XTick', [], 'YTick', []}, {},'Target Image'), [1, 1], [1, 1]);
gui.addVisualization(ScaledImage('hand', 'output',[0, 1],{},{}, 'hand'), [2, 1],[1, 1]);
gui.addVisualization(ScaledImage('fixedStimuli', 'output',[0, 10],{},{}, 'fixedStimuli'), [3, 1],[1, 1]);
gui.addVisualization(ScaledImage('field d', 'output',[0, 1],{},{}, 'field d Output'), [4, 1],[1, 1]);

gui.addVisualization(ScaledImage('targetLocationMap', 'activation',[0, 10],{},{}, 'TargetLocationMap Activation'), [1, 3],[1, 1]);
gui.addVisualization(ScaledImage('targetLocationMap', 'output',[0, 1], {},{}, 'TargetLocationMap Output'), [2, 3],[1, 1]);
gui.addVisualization(ScaledImage('handTargetDifferenceMap', 'output',[0, 10], {},{}, 'Hand Target Difference Map'), [3, 3],[1, 1]);
gui.addVisualization(ScaledImage('velocityMap', 'output',[0, 1], {},{}, 'Velocity Map Output'), [4, 3],[1, 1]);



% add parameter sliders
gui.addControl(ParameterSlider('h_1', 'nodeRed', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u_1'), [1, 1],[1,1]);
gui.addControl(ParameterSlider('q_1', 'nodeRed', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u_1'), [2, 1]);
gui.addControl(ParameterSlider('c_11', 'nodeRed', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_1 to itself'), [3, 1]);
gui.addControl(ParameterSlider('c_12', 'c_12', 'amplitude', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_2 to node u_1'), [4, 1]);
gui.addControl(ParameterSlider('stim Red', 'stimulusRed', 'amplitude', [0, 20], '%0.1f', 1, ...
    'stimulus strength for node u_1'), [5, 1]);
%

gui.addControl(ParameterSlider('h_2', 'nodeGreen', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u'), [8, 1]);
gui.addControl(ParameterSlider('q_2', 'nodeGreen', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u'), [9, 1]);
gui.addControl(ParameterSlider('c_22', 'nodeGreen', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_2 to itself'), [10, 1]);
gui.addControl(ParameterSlider('c_21', 'c_21', 'amplitude', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_1 to node u_2'), [11, 1]);
gui.addControl(ParameterSlider('stim Green', 'stimulusGreen', 'amplitude', [0, 20], '%0.1f', 1, ...
    'stimulus strength for node u_2'), [12, 1]);

gui.addControl(ParameterSlider('dExcAmp', 'd -> d', 'amplitudeExc', [0, 20], '%0.1f', 1, ...
  'strength of lateral excitation in field d'), [15, 1]);
% gui.addControl(ParameterSlider('dInhAmp', 'd -> d', 'amplitudeInh', [0, 20], '%0.1f', 1, ...
%   'strength of local inhibition in field d'), [14, 1]);
gui.addControl(ParameterSlider('dInhGlobA', 'd -> d', 'amplitudeGlobal', [-0.1, 0], '%0.3f', 1, ...
  'strength of global inhibition in field d'), [16, 1]);

gui.addControl(ParameterSlider('d-vExcA', 'd -> v', 'amplitudeExc', [0, 20], '%0.1f', 1, ...
  'strength of lateral excitation in d -> v'), [18, 1]);

gui.addControl(ParameterSlider('d-vInhAmp', 'd -> v', 'amplitudeInh', [0, 20], '%0.1f', 1, ...
  'strength of lateral excitation in d -> v'), [19, 1]);

gui.addControl(ParameterSlider('d-vInhGlobA', 'd -> v', 'amplitudeGlobal', [-0.1, 0], '%0.3f', 1, ...
  'strength of lateral excitation in d -> v'), [20, 1]);



gui.addControl(ParameterSlider('h_PosX', 'hand', 'positionX', [0, fieldSize(:,1)], '%0.1f', 1, 'hand position on X-axis'), [1, 2],[1, 1]);
gui.addControl(ParameterSlider('h_PosY', 'hand', 'positionY', [0, fieldSize(:,2)], '%0.1f', 1, 'hand position on Y-axis'), [2, 2],[1, 1]);
gui.addControl(ParameterSlider('h_Amp', 'hand', 'amplitude', [0, 10], '%0.1f', 1, 'hand stimuli amplitude'), [3, 2],[1, 1]);
gui.addControl(ParameterSlider('hTConV_Amp', 'handTargetDifferenceMap', 'handAmplitude', [0, 10], '%0.1f', 1, 'handTargetMap stimuli amplitude'), [4, 2],[1, 1]);

gui.addControl(ParameterSlider('h_VarX', 'hand', 'sigmaX', [0, 30], '%0.1f', 1, 'hand stimuli variance X'), [5, 2],[1, 1]);
gui.addControl(ParameterSlider('h_VarY', 'hand', 'sigmaY', [0, 30], '%0.1f', 1, 'hand stimuli variance Y'), [6, 2],[1, 1]);
gui.addControl(ParameterSlider('F_Amp', 'fixedStimuli', 'amplitude', [0, 10], '%0.1f', 1, 'fixed stimuli amplitude'), [8, 2]);
gui.addControl(ParameterSlider('F_VarX', 'fixedStimuli', 'sigmaX', [0, 30], '%0.1f', 1, 'fixed stimuli variance X'), [9, 2]);
gui.addControl(ParameterSlider('F_VarY', 'fixedStimuli', 'sigmaY', [0, 30], '%0.1f', 1, 'fixed stimuli variance Y'), [10, 2]);


% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [15, 2]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [16, 2]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [17, 2]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [18, 2]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [19, 2]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [20, 2]);

gui.run(inf);





