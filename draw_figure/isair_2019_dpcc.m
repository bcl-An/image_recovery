% ISAIR 2019���ģ�˫α�����������ͼ
clc;        % ��������д���
clear;      % �������
close all;  % �����ͼ

% ����ͼƬ
image256x256= imread('Lena256x256.bmp');      % ��ȡLenaͼƬ
[image_height,image_width] = size(image256x256);

% ͼ��黮��
block_height = 2;
block_width = 2;
table_height = image_height/block_height;
table_width = image_width/block_width;

% ���� α�����
% [logistic_sequence_output]=get_logistic_sequence(0.3,3.991,image_height,image_width);
% logistic_sequence_dpcc = [logistic_sequence_output+1;1:image_height*image_width];
% save('logistic_sequence_dpcc.mat','logistic_sequence_dpcc');
load('logistic_sequence_dpcc.mat');

% ��ʾ����ͼ��
image_data = image256x256(1 : table_height*block_height,1 : table_width*block_width);
figure('NumberTitle', 'off', 'Name', 'Image Data'); % ȷ��ͼƬ�������ʽ 
imshow(image_data);                          % ͼƬ��ʾ
title('Image Data');

% ��α���ѭ������ԭͼ���������
image_data_vector = reshape(image_data',1,image_height*image_width);
image_data_reconstruct_vector = zeros(1,image_height*image_width,'uint8');
for i = 1 : image_height*image_width
    image_data_reconstruct_vector(i) = image_data_vector(logistic_sequence_dpcc(1,i));
end
image_data_reconstruct = reshape(image_data_reconstruct_vector,image_height,image_width)';

% ��ʾ���ҵ�ͼ��
figure('NumberTitle', 'off', 'Name', 'Image Data Reconstruct'); % ȷ��ͼƬ�������ʽ 
imshow(image_data_reconstruct);                          % ͼƬ��ʾ
title('Image Data Reconstruct');




