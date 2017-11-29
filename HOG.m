classdef HOG < handle
    % This is the class to compute the histogram of oriented gradients for
    % the given image. One thing to ensure is that the input to this class
    % is a rgb image with its size 128 x 64.
    % Expected usage
    % obj = HOG('image.jpg');
    properties (Hidden)
        % optiional Visualization parameter
        visualize = 1;
        % HOG parameters
        cellSize = 8;
        blockSize = 16;
        binSize = 9;
        dX; % deriative in X dir
        dY; % deriative in Y dir
        % Parameters for Gaussian filtering (optional)
        hSize % size of the gaussian filter
        hSigma % Std deviation of the filter
        hGaussFilter; % the gaussian filter
        
        % other parameters useful in the code
        negVals; % Array of all neagtive values
        addMat; % Addition matrix
        hist % Temp array of histograms
        gradDirOrig; % Original gradient direction
        
        % Visualization parameters
        bs = 10; % Sqauare size for visualization
        bim; % Matrix of lines drawn at various angles (visualization)
        
    end
    properties
        % These are the visible properties of this class
        % HOG parameters
        orig;
        I; % Image to be read
        gradMag; % gradient Magnitude
        gradDir; % gradient direction
        blocksMag; % blocks for magnitude
        blocksDir; % blocks for direction
        gradDirBin; % Quantized gradient direction bins
        
        % Internal parameters
        cellGradDir; % Stores gradient directions of every cell
        cellGradMag; % Stores gradient Magnitude of every cell
        cellHOG; % Stores 9x9 histogram of every cell
        
        % Parameters useful for visualization
        tempLongHist; % Concatenated histogram datastructure of all the cells
        tempVisl; % Intermediate Data structure for visualization
        vis;
        
        % Actual HOG of [1x 3780]
        histOfOrientedGradients % actual hog
    end
    methods
        function hog = HOG(image)
            % Default constructor. This will run all the necessary methods
            % that are written down below
            
            % Get the image and convert it to the correct format
            % First check if the input is image or a location.
            if(ischar(image))
                hog.orig = imread(image);
                hog.I = im2double(rgb2gray(hog.orig));
            elseif (length(size(image)) == 3)
                hog.orig = image;
                hog.I = im2double(rgb2gray(hog.orig));
            else
                hog.orig = image;
                hog.I = hog.orig;
            end
            % Preprocess the image to remove some noise (optional)
            %hog.I = medfilt2(hog.I);
            % Take the derivatives
            takeDerivative(hog);
            % Calculate the Gaussian mask for weighting the histograms
            initializeGaussianFilter(hog);
            % Get blocks and cells and histograms and compute the 9x9
            % histograms for each cell. Then reconstruct the final feature
            % vector from this.
            getBlocksAndCells(hog);
            % Visualize the histogram by constructing the bims angles
            visualizeHOG(hog);
            
        end
        function takeDerivative (hog)
            % Take the central difference to construct the derivative image
            [hog.dX , hog.dY] = imgradientxy(hog.I, 'CentralDifference');
            [hog.gradMag, hog.gradDirOrig] = imgradient(hog.dX , hog.dY);
            %figure(1), imshow(hog.gradDir ./ 360);
            hog.negVals = hog.gradDirOrig < 0;
            hog.addMat = 180.* double(hog.negVals);
            hog.gradDir = hog.addMat + hog.gradDirOrig;
            %figure(2), imshow(hog.gradDir ./360);
            hog.gradDirBin = ones(size(hog.gradDir))+ floor(hog.gradDir./20);
            % FIX ME find a elegant way for this
            hog.gradDir = hog.gradDirBin;
            
        end
        function initializeGaussianFilter(hog)
            % Initializes the gaussian fiter parameters. This functions is
            % used to filter the gradient magnitude so as to get a better
            % response from the HOG. %% FIXME : Not yet included.
            hog.hSize = [16, 16];
            hog.hSigma = 5;
            hog.hGaussFilter = fspecial('gaussian', hog.hSize, hog.hSigma);
        end
        function getBlocksAndCells(hog)
            % Converts the gradient image into 16 x 16 block with 50%
            % overlap. First divides the gradient magnitude and the
            % gradient orientations images into 50% overlapping blocks.
            % Hence for a 64 x 128 image we get 7 blocks travelling along
            % columns and 15 blocks travelling alsong rows. Hence total of
            % 15 x 7 = 105. Each of these blocks is divided into cells of
            % 8x8 size. Hence in each block we get 4 cells. Hence total
            % number of cells is 105 x 4 = 420 cells.
            hog.blocksDir = cell(15,7);
            hog.blocksMag = cell(15,7);
            k = 1;
            
            for row = 1: 15
                for col = 1: 7
                    hog.blocksDir{row, col} = hog.gradDir(8*(row-1)+1: 8*(row-1)+16, 8*(col-1)+1: 8*(col-1)+16);
                    hog.blocksMag{row, col} = hog.gradMag(8*(row-1)+1: 8*(row-1)+16, 8*(col-1)+1: 8*(col-1)+16);
                    %hog.blocksMag{row, col} = imfilter(hog.blocksMag{row, col}, hog.hGaussFilter);
                    for m = 1:2
                        for n = 1:2
                            hog.cellGradDir{row, col}{m,n} = hog.blocksDir{row, col}(8* (m-1) +1:8* (m-1)+8, 8* (n-1) +1:8* (n-1)+8  );
                            hog.cellGradMag{row, col}{m,n} = hog.blocksMag{row, col}(8* (m-1) +1:8* (m-1)+8, 8* (n-1) +1:8* (n-1)+8  );
                            currHist = zeros(1, hog.binSize);
                            currCellDir = hog.cellGradDir{row, col}{m,n};
                            currCellMag = hog.cellGradMag{row, col}{m,n};
                            for cRow = 1: hog.cellSize
                                for cCol = 1:hog.cellSize
                                    currHist(currCellDir(cRow, cCol)) = currHist(currCellDir(cRow, cCol)) + currCellMag(cRow, cCol);
                                end
                            end
                            hog.cellHOG{row, col}{m,n} = currHist;
                            k = k+1;
                        end
                    end
                end
            end
        end
        
        function visualizeHOG(hog)
            % This function visualizes the histogram. The first part is to
            % create a "glyph"
            
            % optional visualization
            
                getGlyph(hog);
            
            
            k = 1;
            for row = 1: 15
                for col = 1: 7
                    for m = 1: 2
                        for n =1:2
                            hog.tempLongHist{1, k} = hog.cellHOG{row, col}{m,n};
                            k = k +1;
                            
                                hog.vis{row,col}{m,n} = zeros(hog.bs, hog.bs);
                                for j = 1:hog.binSize
                                    hog.vis{row,col}{m,n} = hog.vis{row,col}{m,n} + hog.cellHOG{row,col}{m,n}(j).*hog.bim(:,:,j);
                                end
                                hog.tempVisl{2*(row-1) + m, 2*(col-1) + n} = hog.vis{row,col}{m,n};
                            
                            
                        end
                    end
                end
            end
            hog.histOfOrientedGradients =cell2mat(hog.tempLongHist);
            figure(1), imshow(hog.orig);
            figure(2), bar(hog.histOfOrientedGradients);
            figure(3), imshow(cell2mat(hog.tempVisl));
        end
        function getGlyph(hog)
            % This method creates a reference bim that can be used for
            % later referencing to display the HOG of the image.
            bim1 = zeros(hog.bs,hog.bs);
            bim1(round(hog.bs/2):round(hog.bs/2)+1,:) = 1;
            hog.bim = zeros([size(bim1) hog.binSize]);
            hog.bim(:,:,1) = bim1;
            for i = 2:hog.binSize
                hog.bim(:,:,i) = imrotate(bim1, -(i-1)*20, 'crop');
            end
        end
    end
end