%
%   TAE - Final Project
%
%   Giovanni Ballarin, Stefanie Bertele
%

clear;
close all;

train_size = 9000;
test_size  = 1000;

% Import MNIST dataset:

% X_mnist = csvread('digits_data.csv');
% y_mnist = csvread('digits_labels.csv');

mnist_data   = transpose(loadMNISTImages('mnist-train-images-idx3-ubyte'));
mnist_labels = loadMNISTLabels('mnist-train-labels-idx1-ubyte');

X_mnist = mnist_data(1:train_size, :);
y_mnist = mnist_labels(1:train_size, :);

n_mnist = size(X_mnist, 1);
p_mnist = size(X_mnist, 2);

X_mnist_test = mnist_data(train_size+1:train_size+test_size, :);
y_mnist_test = mnist_labels(train_size+1:train_size+test_size, :);

% Import Fashion MNIST dataset:

fashion_data   = transpose(loadMNISTImages('fashion-mnist-images-idx3-ubyte'));
hashion_labels = loadMNISTLabels('fashion-mnist-labels-idx1-ubyte');

X_fashion = fashion_data(1:train_size, :);
y_fashion = hashion_labels(1:train_size, :);

n_fashion = size(X_fashion, 1);
p_fashion = size(X_fashion, 2);

X_fashion_test = fashion_data(train_size+1:train_size+test_size, :);
y_fashion_test = hashion_labels(train_size+1:train_size+test_size, :);

% Import notMNIST dataset:

notMnist_data   = transpose(loadMNISTImages('notmnist-images-idx3-ubyte'));
notMnist_labels = loadMNISTLabels('notmnist-labels-idx1-ubyte');

X_notMnist = notMnist_data(1:train_size, :);
y_notMnist = notMnist_labels(1:train_size, :);

n_notMnist = size(X_notMnist, 1);
p_notMnist = size(X_notMnist, 2);

X_notMnist_test = notMnist_data(train_size+1:train_size+test_size, :);
y_notMnist_test = notMnist_labels(train_size+1:train_size+test_size, :);

clear mnist_data mnist_labels fashion_data hashion_labels ...
        notMnist_data notMnist_labels;
 
% We are using display_network from the autoencoder code
% displayData(X_fashion(1:100, :));
% disp(y_fashion(1:10));

num_labels = 10;

Y_mnist      = zeros(n_mnist, num_labels);
Y_mnist_test = zeros(test_size, num_labels);
for j = 1:train_size+test_size
    if j <= train_size
        Y_mnist(j, y_mnist(j)+1) = 1;
    else
        Y_mnist_test(j, y_mnist_test(j-test_size)+1) = 1;
    end
end

Y_notMnist      = zeros(n_notMnist, num_labels);
Y_notMnist_test = zeros(test_size, num_labels);
for j = 1:train_size+test_size
    if j <= train_size
        Y_notMnist(j, y_notMnist(j)+1) = 1;
    else
        Y_notMnist_test(j, y_notMnist_test(j-test_size)+1) = 1;
    end
end

Y_fashion      = zeros(n_fashion, num_labels);
Y_fashion_test = zeros(test_size, num_labels);
for j = 1:train_size+test_size
    if j <= train_size
        Y_fashion(j, y_fashion(j)+1) = 1;
    else
        Y_fashion_test(j, y_fashion_test(j-test_size)+1) = 1;
    end
end

% Y_fashion = zeros(n_fashion, num_labels);
% for j = 1:train_size+test_size
%     Y_fashion(j, y_fashion(j)+1) = 1;
% end
% 
% Y_notMnist = zeros(n_notMnist, num_labels);
% for j = 1:train_size+test_size
%     Y_notMnist(j, y_notMnist(j)+1) = 1;
% end

%% ANN + test training algorithm:

train_alg = { 'trainrp', 'trainscg', ...
                'traincgb', 'traincgf', 'traincgp', 'trainoss', 'traingdx', ...
                'traingdm', 'traingd'};
            
NN_mnist_error_alg = zeros(length(train_alg),1);
NN_mnist_time_alg = zeros(length(train_alg),1);
            
for k = 1:length(train_alg)
    
    net = feedforwardnet(25, char(train_alg(k)));
    tic
    net = train(net, X_mnist',  Y_mnist', [], [], [], 'useParallel');
    NN_mnist_time_alg(k) = toc;
    [~, NN_class] = max(net(X_mnist_test')', [], 2);
    
    NN_mnist_error_alg(k) = sum(NN_class ~= y_mnist_test)/n_mnist;
    
end

results_test_train_alg = ...
    table(train_alg', NN_mnist_error_alg, NN_mnist_time_alg, ...
            'VariableNames',{'Algorithm','Error','Time'});
        
disp(' ')
disp(' ----------------------------- ')
disp('    Test Training Algorithms   ')
disp(' ----------------------------- ')
disp(' ')
disp(results_test_train_alg)
disp(' ')

%% PCA + ANN:

NN_architecture  = { 10;
                     25;
                     100; 
                     [25, 15];
                     [25, 20, 15];
                     [100, 50, 20] };
                    
PCA_sizes        = [10, 25, 50, 100];

%% MNIST

NN_PCA_mnist_er      = zeros(length(PCA_sizes)*length(NN_architecture),1);
NN_PCA_mnist_er_test = zeros(length(PCA_sizes)*length(NN_architecture),1);
 
tmp_PCA_disp = zeros(length(PCA_sizes)*length(NN_architecture),1);
tmp_Archi_disp = {};

j = 1;

for PC_dim = PCA_sizes
    
    for l = 1:length(NN_architecture)

    % PCA of the MNIST data:
    X_mnist_pca = X_mnist * pca(X_mnist);
    X_mnist_pca = X_mnist_pca(:, 1:PC_dim);

    % Neural network:
    net = feedforwardnet(NN_architecture{l}, 'trainscg');
    net = train(net, X_mnist_pca',  Y_mnist', [], [], [], 'useParallel');
    
    % Test Performance:
    X_mnist_test_pca = X_mnist_test * pca(X_mnist_test);
    X_mnist_test_pca = X_mnist_test_pca(:, 1:PC_dim);
    [~, NN_class]      = max(net(X_mnist_pca')', [], 2);
    [~, NN_class_test] = max(net(X_mnist_test_pca')', [], 2);
    
    NN_PCA_mnist_er(j)      = sum(NN_class ~= (y_mnist+1))/train_size;
    NN_PCA_mnist_er_test(j) = sum(NN_class_test ~= (y_mnist_test+1))/test_size;
    
    tmp_PCA_disp(j) =  PC_dim;
    
    j = j + 1;
    
    end
    
    tmp_Archi_disp = [ tmp_Archi_disp; NN_architecture ];

end

results_PCA_ANN_mnist = ...
    table( tmp_PCA_disp, tmp_Archi_disp,  ...
           NN_PCA_mnist_er, NN_PCA_mnist_er_test, ...
            'VariableNames',{'PCA_Size','NN_Architecture',...
                             'Error_int','Error_test'});
        
disp(' ')
disp(' ----------------------------- ')
disp('       MNIST - PCA + ANN       ')
disp(' ----------------------------- ')
disp(' ')
disp(results_PCA_ANN_mnist)
disp(' ')

%% notMNIST

NN_PCA_notMnist_error = zeros(length(PCA_sizes)*length(NN_architecture),1);

tmp_PCA_disp = zeros(length(PCA_sizes)*length(NN_architecture),1);
tmp_Archi_disp = {};

j = 1;

for PC_dim = PCA_sizes
    
    for l = 1:length(NN_architecture)

    % PCA of the MNIST data:
    X_notMnist_pca = X_notMnist * pca(X_notMnist);
    X_notMnist_pca = X_notMnist_pca(:, 1:PC_dim);

    % Neural network:
    net = feedforwardnet(NN_architecture{l}, 'trainscg');
    net = train(net, X_notMnist_pca',  Y_notMnist', [], [], [], 'useParallel');
    [~, NN_class] = max(net(X_notMnist_pca')', [], 2);
    
    NN_PCA_notMnist_error(j) = sum(NN_class ~= (y_notMnist+1))/n_mnist;
    
    tmp_PCA_disp(j) =  PC_dim;
    
    j = j + 1;
    
    end
    
    tmp_Archi_disp = [ tmp_Archi_disp; NN_architecture ];

end


results_PCA_ANN_notMnist = ...
    table(tmp_PCA_disp, tmp_Archi_disp,  NN_PCA_notMnist_error, ...
            'VariableNames',{'PCA_Size','NN_Architecture','Error'});
        
disp(' ')
disp(' ----------------------------- ')
disp('      notMNIST - PCA + ANN     ')
disp(' ----------------------------- ')
disp(' ')
disp(results_PCA_ANN_notMnist)
disp(' ')

%% FASHION

NN_PCA_fashion_error = zeros(length(PCA_sizes)*length(NN_architecture),1);

tmp_PCA_disp = zeros(length(PCA_sizes)*length(NN_architecture),1);
tmp_Archi_disp = {};

j = 1;

for PC_dim = PCA_sizes
    
    for l = 1:length(NN_architecture)

    % PCA of the MNIST data:
    X_fashion_pca = X_fashion * pca(X_fashion);
    X_fashion_pca = X_fashion_pca(:, 1:PC_dim);

    % Neural network:
    net = feedforwardnet(NN_architecture{l}, 'trainscg');
    net = train(net, X_fashion_pca',  Y_fashion', [], [], [], 'useParallel');
    [~, NN_class] = max(net(X_fashion_pca')', [], 2);
    
    NN_PCA_fashion_error(j) = sum(NN_class ~= (y_fashion+1))/n_mnist;
    
    tmp_PCA_disp(j) =  PC_dim;
    
    j = j + 1;
    
    end
    
    tmp_Archi_disp = [ tmp_Archi_disp; NN_architecture ];

end


results_PCA_ANN_fashion = ...
    table(tmp_PCA_disp, tmp_Archi_disp,  NN_PCA_fashion_error, ...
            'VariableNames',{'PCA_Size','NN_Architecture','Error'});
        
disp(' ')
disp(' ----------------------------- ')
disp('   Fashion MNIST - PCA + ANN   ')
disp(' ----------------------------- ')
disp(' ')
disp(results_PCA_ANN_fashion)
disp(' ')

%% Convolutional Neural Network

rng('default')

X_mnist_datastore    = zeros(28, 28, 1, n_mnist);
X_notMnist_datastore = zeros(28, 28, 1, n_mnist);
X_fashion_datastore  = zeros(28, 28, 1, n_mnist);

X_mnist_test_datastore    = zeros(28, 28, 1, test_size);
X_notMnist_test_datastore = zeros(28, 28, 1, test_size);
X_fashion_test_datastore  = zeros(28, 28, 1, test_size);

options = trainingOptions('sgdm',...
    'LearnRateSchedule', 'piecewise',...
    'LearnRateDropFactor', 0.2,...
    'LearnRateDropPeriod', 5,...
    'MaxEpochs', 20,...
    'MiniBatchSize', 64,...
    'L2Regularization',0.0005...
    );
%     'Plots','training-progress');

CNN_layers = { [ ...
                imageInputLayer([28, 28, 1]);
                convolution2dLayer(3, 3);
                reluLayer;
                fullyConnectedLayer(10);
                softmaxLayer();
                classificationLayer();
              ]; 
              [ ...
                imageInputLayer([28, 28, 1]);
                convolution2dLayer(3, 10);
                reluLayer;
                fullyConnectedLayer(100);
                reluLayer;
                fullyConnectedLayer(10);
                softmaxLayer();
                classificationLayer();
              ];
              [ ...
                imageInputLayer([28, 28, 1]);
                convolution2dLayer(6, 5);
                batchNormalizationLayer
                reluLayer;
                fullyConnectedLayer(10);
                softmaxLayer();
                classificationLayer();
              ];
              [ ...
                imageInputLayer([28, 28, 1]);
                convolution2dLayer(10, 10);
                batchNormalizationLayer
                reluLayer;
                averagePooling2dLayer(2)
                convolution2dLayer(6, 2);
                batchNormalizationLayer
                reluLayer;
                fullyConnectedLayer(100);
                reluLayer;
                fullyConnectedLayer(10);
                softmaxLayer();
                classificationLayer();
              ];
};
% CNN_layers = {
%               [ ...
%                 imageInputLayer([28, 28, 1]);
%                 convolution2dLayer(10,16,'Padding',1)
%                 batchNormalizationLayer
%                 reluLayer
%                 maxPooling2dLayer(2,'Stride',2)
%                 convolution2dLayer(4,32,'Padding',1)
%                 batchNormalizationLayer
%                 reluLayer
%                 fullyConnectedLayer(10);
%                 softmaxLayer();
%                 classificationLayer();
%               ];
% };

%% MNIST

for j = 1:n_mnist
    X_mnist_datastore(:,:,:,j) = reshape(X_mnist(j,:), 28, 28);
end
for j = 1:test_size
    X_mnist_test_datastore(:,:,:,j) = reshape(X_mnist_test(j,:), 28, 28);
end

CNN_mnist_error   = zeros(length(CNN_layers),1);
CNN_predict_mnist = zeros(length(y_mnist_test),length(CNN_layers));

for l = 1:length(CNN_layers)
    
    CNN_net_mnist = ...
        trainNetwork(X_mnist_datastore, categorical(y_mnist), ...
                        CNN_layers{l}, options);
%     disp(' #1 ')           
    CNN_predict_mnist(:,l) = ...
        double(classify(CNN_net_mnist, X_mnist_test_datastore));
%     disp(' #2 ')
    CNN_mnist_error(l) = ...
                sum(CNN_predict_mnist(:,l) ~= (y_mnist_test+1))/test_size;
%     disp(' #3 ')
    
end

% Plot

figure(5)
for l = 1:length(CNN_layers)

    misclass = zeros(10, 10);
    for k = 1:10
        for j = 1:10
            tmp_class = CNN_predict_mnist(:,l);
            misclass(k, j) = ...
                sum(tmp_class((y_mnist+1) == k) == j)/...
                                (n_mnist/10);
        end
    end
    
    subplot(floor(length(CNN_layers)/3), ...
                    length(CNN_layers)/floor(length(CNN_layers)/3), l);
    imagesc(misclass)
    pbaspect([2 2 1])

end
title('CNN classifier - MNIST - Misclassification matrix')

%% notMNIST

for j = 1:n_notMnist
    X_notMnist_datastore(:,:,:,j) = reshape(X_notMnist(j,:), 28, 28);
end

CNN_notMnist_error = zeros(length(CNN_layers),1);
CNN_predict_notMnist = zeros(length(y_fashion_test),length(CNN_layers));

for l = 1:length(CNN_layers)
    
    CNN_net_notMnist = ...
        trainNetwork(X_notMnist_datastore, categorical(y_notMnist), ...
                        CNN_layers{l}, options);
%     disp(' #1 ')           
    CNN_predict_notMnist(:,l) = ...
        double(classify(CNN_net_notMnist, X_notMnist_test_datastore));
%     disp(' #2 ')
    CNN_notMnist_error(l) = ...
                sum(CNN_predict_notMnist(:,l) ~= (y_notMnist_test+1))/n_mnist;
%     disp(' #3 ')
    
end

% Plot

figure(5)
for l = 1:length(CNN_layers)

    misclass = zeros(10, 10);
    for k = 1:10
        for j = 1:10
            tmp_class = CNN_predict_notMnist(:,l);
            misclass(k, j) = ...
                sum(tmp_class((y_notMnist+1) == k) == j)/...
                                (n_notMnist/10);
        end
    end
    
    subplot(floor(length(CNN_layers)/3), ...
                    length(CNN_layers)/floor(length(CNN_layers)/3), l);
    imagesc(misclass)
    pbaspect([2 2 1])

end
title('CNN classifier - notMNIST - Misclassification matrix')

%% FASHION

for j = 1:n_mnist
    X_fashion_datastore(:,:,:,j) = reshape(X_fashion(j,:), 28, 28);
end
  
CNN_fashion_error = zeros(length(CNN_layers),1);
CNN_predict_fashion = zeros(length(y_fashion),length(CNN_layers));

for l = 1:length(CNN_layers)
    
    CNN_net_fashion = ...
        trainNetwork(X_fashion_datastore, categorical(y_fashion), ...
                        CNN_layers{l}, options);
%     disp(' #1 ')           
    CNN_predict_fashion(:,l) = double(classify(CNN_net_fashion, ...
                                                    X_fashion_datastore));
%     disp(' #2 ')
    CNN_fashion_error(l) = ...
                sum(CNN_predict_fashion(:,l) ~= (y_fashion+1))/n_mnist;
%     disp(' #3 ')
    
end

% Plot

figure(5)
for l = 1:length(CNN_layers)

    misclass = zeros(10, 10);
    for k = 1:10
        for j = 1:10
            tmp_class = CNN_predict_fashion(:,l);
            misclass(k, j) = ...
                sum(tmp_class((y_fashion+1) == k) == j)/...
                                (n_mnist/10);
        end
    end
    
    subplot(floor(length(CNN_layers)/3), ...
                    length(CNN_layers)/floor(length(CNN_layers)/3), l);
    imagesc(misclass)
    pbaspect([2 2 1])

end
title('CNN classifier - Fashion - Misclassification matrix')




