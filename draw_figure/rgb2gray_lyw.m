clc;        % ��������д���
clear;      % �������
close all;  % �����ͼ

MyYuanLaiPic = imread('School_Motto.bmp');%��ȡRGB��ʽ��ͼ�� 
%��ʾԭ����RGBͼ��  
figure(1);  
imshow(MyYuanLaiPic);  
 
MyFirstGrayPic = rgb2gray(MyYuanLaiPic);%�����еĺ�������RGB���Ҷ�ͼ���ת��   
%��ʾ����ϵͳ����������ĻҶ�ͼ��  
figure(2);  
imshow(MyFirstGrayPic);

 
 
[rows , cols , colors] = size(MyYuanLaiPic);%�õ�ԭ��ͼ��ľ���Ĳ���  
MidGrayPic1 = zeros(rows , cols);%�õõ��Ĳ�������һ��ȫ��ľ���������������洢������ķ��������ĻҶ�ͼ��  
MidGrayPic1 = uint8(MidGrayPic1);%��������ȫ�����ת��Ϊuint8��ʽ����Ϊ���������䴴��֮��ͼ����double�͵�  
 
for i = 1:rows  
    for j = 1:cols  
        sum = 0;  
        for k = 1:colors  
            sum = sum + MyYuanLaiPic(i , j , k) / 3;%����ת���Ĺؼ���ʽ��sumÿ�ζ���Ϊ��������ֶ����ܳ���255  
        end  
        MidGrayPic1(i , j) = sum;  
    end  
end  
%ƽ��ֵ��ת��֮��ĻҶ�ͼ��  
figure(3); 
imshow(MidGrayPic1);
 
MidGrayPic2 = zeros(rows , cols);%�õõ��Ĳ�������һ��ȫ��ľ���������������洢������ķ��������ĻҶ�ͼ��  
MidGrayPic2 = uint8(MidGrayPic2);%��������ȫ�����ת��Ϊuint8��ʽ����Ϊ���������䴴��֮��ͼ����double�͵�  
for i = 1:rows  
    for j = 1:cols  
        MidGrayPic2(i , j) =max(MyYuanLaiPic(i,j,:));  
    end  
end  
%���ֵ��ת��֮��ĻҶ�ͼ��  
figure(4); 
imshow(MidGrayPic2);
 
 
 
MidGrayPic3 = zeros(rows , cols);%�õõ��Ĳ�������һ��ȫ��ľ���������������洢������ķ��������ĻҶ�ͼ��  
MidGrayPic3 = uint8(MidGrayPic3);%��������ȫ�����ת��Ϊuint8��ʽ����Ϊ���������䴴��֮��ͼ����double�͵�  
 
for i = 1:rows  
    for j = 1:cols  
        MidGrayPic3(i , j) = MyYuanLaiPic(i , j , 1)*0.30+MyYuanLaiPic(i , j , 2)*0.59+MyYuanLaiPic(i , j , 3)*0.11;  
    end  
end  
%��Ȩƽ��ֵ��ת��֮��ĻҶ�ͼ��  
figure(5); 
imshow(MidGrayPic3);