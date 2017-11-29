clc, close all, clear all;
%
positiveSamples = load('posSamples.mat');
negativeSamples = load('negSamples.mat');
%positiveSamples = rand(400, 3780);
%negativeSamples = rand(500, 3780);
positiveSamples = struct2array(positiveSamples);
negativeSamples = struct2array(negativeSamples);
%Consider only the first few training samples as there are errors later

%positiveSamples = positiveSamples(1:400, :);
%negativeSamples = negativeSamples(1:500, :);
[rpos , cpos] = size(positiveSamples);
[rneg , cneg] = size(negativeSamples);
% We check if the dimensions of the features match
if(cpos ~= cneg)
    error('feature dimensions dont match');
end
posLabels = ones(rpos, 1);
negLabels = -1.*ones(rneg, 1);
tNumSamples = rpos + rneg;
A11temp = -1.*positiveSamples;
A12temp = -1.*ones(rpos, 1);
A13temp = -1.*eye(tNumSamples); % include A23
A21temp = negativeSamples;
A22temp = ones(rneg,1);
A1temp = [A11temp A12temp; A21temp A22temp];
A = [A1temp A13temp];
H1temp = eye(cpos);
% 1 col corresponds to b and tNumSamples elements of eta so total of
%|---3780---[b][eta1, ---- eta(tNumsamples)| so 4693 x 4693 dim matrix
padSize = 1+ tNumSamples; % one corresponds to b
H = padarray(H1temp, [padSize, padSize], 'post');
f1temp = zeros(1, cpos);
f2temp = 0;
f3temp = 0.01.*ones(1, tNumSamples);
f = [f1temp f2temp f3temp];
b= -1.*ones(tNumSamples,1);
% TO find the lower bound
lb = -1.*ones(3780 + 1 + tNumSamples,1);
lb = lb./0;
lb(3781,1 ) =0;
opts = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
[X, fval, eflag, output, lambda] = quadprog(H,f,A,b,[],[],lb,[],[],opts);
if(~isempty(X))
    disp('solved the svm problem');
    weight = X(1:3780);
    etas= X(3782:end);
    biasTerm = X(3781);
    bar(weight);
    figure(2), bar(etas);
    disp('Now showing the test for positive sample');
    poshog = HOG('posimg.png');
    result = dotprod(poshog.histOfOrientedGradients, weight) + biasTerm;
    disp('w transpose x + b for positive is ');
    disp(result);
    % repeat for negative sample
    neghog = HOG('negimg.png');
    result = dotprod(neghog.histOfOrientedGradients, weight) + biasTerm;
    disp('w transpose x + b for negative is ');
    disp(result);
else
    disp('Empty X found');
end
