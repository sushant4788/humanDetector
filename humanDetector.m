classdef humanDetector <handle
    % This is the class that does the human detection given an input image
    properties
        orig; % original input to the class can be an image array or a string
        I; % The grayscale array of the image
        weight; % weight vector
        nRows % The number of rows of I
        nCols % The numer of cols of I
        paddedImage; % The padded image which is a multiple of the image size
        delta % Pixel overlap
        retValue;
        retMat % A structure that contains the startting point and the score of the detected window
    end
    methods
        function this = humanDetector(image, weight, delta)
            if(ischar(image))
                this.orig = imread(image);
                this.I = im2double(rgb2gray(this.orig));
            elseif(length(size(image)) == 3)
                this.orig = image;
                this.I = im2double(rgb2gray(this.orig));
            else
                this.orig = image;
                this.I = im2double(this.orig);
            end
            this.weight = weight;
            this.delta = delta;
            % Step 1 is to get the dimensions of the image and conver it to
            % percent overlap
            getframesToProcess(this);
        end
        function getframesToProcess(this)
            % This function divides the image into frames to process
            % depeneding upon what overlapp we have provided.
            [this.nRows, this.nCols] = size(this.I);
            % We have to create an image which is perfect multiple of 128 x 64
            %             this.delta = 50;
            lX = this.nCols - 64;
            lY = this.nRows - 128;
            rX = mod(lX, this.delta);
            rY = mod(lY, this.delta);
            psX = mod(this.delta - rX, this.delta);
            psY = mod(this.delta - rY, this.delta);
            this.paddedImage = padarray(this.I, [psY psX], 'post');
            [pRows, pCols] = size(this.paddedImage);
            l = 0;
            if(pRows < 128)
                this.paddedImage = padarray(this.paddedImage, [(128-pRows),0], 'post');
            end
            if(pCols < 64)
                this.paddedImage = padarray(this.paddedImage, [0,(64-pCols)], 'post');
            end
            [pRows, pCols] = size(this.paddedImage);
            imshow(this.paddedImage);
            numFramesX = ((pRows - 128)/this.delta) +1;
            numFramesY = ((pCols - 64)/this.delta) +1;
            
            testHOG = cell(numFramesX,numFramesY);
            startX = zeros(numFramesX,numFramesY);
            startY = zeros(numFramesX,numFramesY);
            testResult = cell (numFramesX,numFramesY);
            %load updatedweights.mat;
            imshow(this.paddedImage);
            hold on;
            for i = 128:this.delta:pRows
                l = l+1;
                m = 0;
                for j = 64:this.delta:pCols
                    m = m+1;
                    sx = i-127;
                    sy = j-63;
                    Im = this.paddedImage(sx: sx+127, sy:sy+63);
                    % There is an inversion in the position of sx and sy as
                    % the interpretation of the x and y co-ordinates is
                    % different across different toolboxes.
                    
                    temp = HOG(Im);
                    testHOG{l, m} = temp.histOfOrientedGradients;
                    startX(l) = sx;
                    startY(m) = sy;
                    testResult{l,m} = dotprod(testHOG{l,m},this.weight);
                    
                end% Ends inner for loop
            end% End of outer for
            resMatrix = cell2mat(testResult);
            posMatrix = resMatrix >5;
            %posMatrix2 = resMatrix <100;
            %posMatrix = posMatrix1 .* posMatrix2;
            qq =1;
            for k = 1:l
                for v = 1:m
                    if(posMatrix(k,v) == 1)
                        rectangle('Position', [startY(v), startX(k), 63 127], 'EdgeColor', [0 1 0]);
                        this.retValue{qq,1} = [startX(k), startY(v), resMatrix(k,v)];
                        qq = qq+1;
                    end
                end
            end
            this.retMat = cell2mat(this.retValue);
            hold off;
        end % End of getFrameToProcess
    end% End of methods
end% End of classdef