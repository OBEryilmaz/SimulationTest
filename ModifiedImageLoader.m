% backup

% ImageLoader (COSIVINA toolbox)
%   Element to load images from file and switch between them.
%
% Constructor call:
% ImageLoader(label, filePath, fileNames, imageSize, currentSelection)
%   label - element label
%   filePath - path to the image files
%   fileNames - cell array of image file names
%   imageSize - size of output image (camera image is resized if required)
%   currentSelection - index of initially selected image

classdef ModifiedImageLoader < Element
    
    properties (Constant)
        parameters = struct('fileNames', ParameterStatus.Fixed, 'size', ParameterStatus.Fixed, ...
            'currentSelection', ParameterStatus.InitRequired,'onTimes',...
            bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix));
        components = {'image','imageRed','imageGreen','inputForRed','inputForGreen','sumOfRed','sumOfGreen','onTimes'};
        defaultOutputComponent = 'image';
    end
    
    properties
        % parameters
        filePath = '';
        fileNames = {};
        size = [1, 1];
        currentSelection = 1;
        onTimes = zeros(0, 2);
        
        on = false;
        
        % accessible structures
        image
        imageRed
        imageGreen
        inputForRed
        inputForGreen
        sumOfRed
        sumOfGreen
        
    end
    
    methods
        % constructor
        function obj = ModifiedImageLoader(label, filePath, fileNames, imageSize, currentSelection,onTimes)
            if nargin > 0
                obj.label = label;
                obj.fileNames = fileNames;
                if ~iscell(obj.fileNames)
                    obj.fileNames = cellstr(obj.fileNames);
                end
                obj.size = imageSize;
            end
            if nargin >= 5
                obj.currentSelection = currentSelection;
                obj.onTimes = onTimes;
            end
            if size(obj.onTimes, 2) ~= 2 %#ok<CPROP>
                error('TimedCustomStimulus:constructor:invalidArgument', 'Argument onTimes must be an Nx2 matrix.');
            end
            
            
            for i = 1 : numel(obj.fileNames)
                obj.fileNames{i} = fullfile(filePath, obj.fileNames{i});
            end
        end
        
        
        % step function
        function obj = step(obj, time, deltaT) %#ok<INUSD>
            shouldBeOn = any(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2));
            if ~obj.on && shouldBeOn
                obj.image = imread(obj.fileNames{obj.currentSelection});
                %obj.image=double(obj.image);
                
                obj.imageRed=obj.image(:,:,1);
                obj.imageGreen=obj.image(:,:,2);
                obj.sumOfRed=sum(sum(obj.imageRed));
                obj.sumOfGreen=sum(sum(obj.imageGreen));
                
                %Calculate the inputs for the uRed and uGreen
                Coeff=5.446623093681918e-04;
                
                obj.inputForGreen=Coeff.*obj.sumOfRed;
                obj.inputForRed=Coeff.*obj.sumOfGreen;
                
%                 obj.inputForRed = obj.inputElements{1}.(obj.inputComponents{1});
%                 obj.inputForGreen = obj.inputElements{2}.(obj.inputComponents{2});
                
                obj.on = true;
            elseif obj.on && ~shouldBeOn
                obj.image(:,:,1)=zeros(120);
                obj.image(:,:,2)=zeros(120);
                obj.image(:,:,3)=zeros(120);
                obj.imageRed=obj.image(:,:,1);
                obj.imageGreen=obj.image(:,:,2);
                obj.sumOfRed=sum(sum(obj.imageRed));
                obj.sumOfGreen=sum(sum(obj.imageGreen));
                
                Coeff=5.446623093681918e-04;
                
                obj.inputForGreen=Coeff.*obj.sumOfRed;
                obj.inputForRed=Coeff.*obj.sumOfGreen;
                
                
                obj.on = false;
            end
            
        end
        
        
        % initialization
        function obj = init(obj)
            if mod(obj.currentSelection, 1) == 0 && obj.currentSelection > 0 && obj.currentSelection <= numel(obj.fileNames)
                obj.image = imread(obj.fileNames{obj.currentSelection});
                obj.image(:,:,1)=zeros(120);
                obj.image(:,:,2)=zeros(120);
                obj.image(:,:,3)=zeros(120);
                obj.imageRed=obj.image(:,:,1);
                obj.imageGreen=obj.image(:,:,2);
                obj.sumOfRed=sum(sum(obj.imageRed));
                obj.sumOfGreen=sum(sum(obj.imageGreen));
                %
                %                 %Calculate the inputs for the uRed and uGreen
                Coeff=5.446623093681918e-04;
                
                obj.inputForGreen=Coeff.*obj.sumOfRed;
                obj.inputForRed=Coeff.*obj.sumOfGreen;
                
                
            end
        end
        
    end
end


