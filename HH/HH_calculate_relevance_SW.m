function relevance_input = HH_calculate_relevance_SW(X, weights, bias, relevance_output)
    % Calculate relevance scores for input features in linear regression using LRP.
    %
    % Parameters:
    % - X: Matrix of input features (n_samples x n_features)
    % - weights: Vector of weights for the regression model (n_features x 1)
    % - bias: Scalar bias term in the regression model
    % - relevance_output: Vector of output relevance scores (n_samples x 1)
    %
    % Returns:
    % - relevance_input: Matrix of relevance scores for input features (n_samples x n_features)

    % Calculate linear output for each input
    linear_output = X * weights + bias;

    % Ensure no division by zero
    linear_output(linear_output == 0) = eps;

    % Propagate relevance scores to input features
    % Using absolute values in the numerator
    relevance_input = (abs(X .* weights')) ./ abs(linear_output) .* relevance_output;

end

% % Example usage
% % Define a simple linear regression model: y = w1*x1 + w2*x2 + b
% weights = [0.4; 0.6];   % weights for features
% bias = 0.1;             % bias term
% X = [1, 2;              % input data
%      3, 4;
%      5, 6];
% 
% % Output relevance (for simplicity, use prediction values as relevance)
% relevance_output = X * weights + bias;
% 
% % Compute relevance for input features
% relevance_scores = calculate_relevance(X, weights, bias, relevance_output);
% 
% % Display results
% disp('Input Features:');
% disp(X);
% 
% disp('Relevance Scores:');
% disp(relevance_scores);