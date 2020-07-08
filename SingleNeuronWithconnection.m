%   SingleNeuronWithconnection 
%   Adapted from NeuralField element(COSIVINA toolbox)
%   Creates a dynamic neural field (or set of discrete dynamic nodes) of
%   arbitrary dimensionality with sigmoid (logistic) output function. The
%   field activation is updated according to the Amari equation.
% 
%   Constructor call:
%   SingleNeuronWithconnection(label, size, tau, h, beta, connection)
%   label - element label
%   size - field size
%   tau - time constant (default = 10)
%   h - resting level (default = -5)
%   beta - steepness of sigmoid output function (default = 4)
%   connection- Amplitude for inhibitory connection. This can be used by
%   building a connection e.g.
%   addConnection('SingleNeuron...','connection', 'target Single Neuron');

classdef SingleNeuronWithconnection < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'tau', ParameterStatus.Changeable, ...
      'h', ParameterStatus.Changeable, 'beta', ParameterStatus.Changeable, 'connection', ParameterStatus.Changeable);
    components = {'activation', 'output', 'h', 'connection'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    tau = 10;
    h = -5;
    beta = 4;
    
    % accessible structures
    activation
    output
    connection
  end
  
  methods
    % constructor
    function obj = SingleNeuronWithconnection(label, size, tau, h, beta,connection)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.tau = tau;
      end
      if nargin >= 4
        obj.h = h;
      end
      if nargin >= 5
        obj.beta = beta;
      end
      if nargin >= 6
        obj.connection = connection;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSL>
      input = 0;
      for i = 1 : obj.nInputs
        input = input + obj.inputElements{i}.(obj.inputComponents{i});
      end
      obj.activation = obj.activation + deltaT/obj.tau * (- obj.activation + obj.h+obj.connection*obj.output + input);
      obj.output = sigmoid(obj.activation, obj.beta, 0);
      
      %obj.connection = (obj.connection*obj.output);
    end
    
    
    % intialization
    function obj = init(obj)
      obj.activation = zeros(obj.size) + obj.h;
      obj.output = sigmoid(obj.activation, obj.beta, 0);
      %obj.connection = (obj.connection*obj.output);
    end
  end
end


