//
//  DetailController.m
//  openCVDemo
//
//  Created by 梁亦明 on 16/8/28.
//  Copyright © 2016年 xiaoming.com. All rights reserved.
//

#import "DetailController.h"
#import "UIImage+OpenCV.h"

@interface DetailController ()
@property (nonatomic,strong) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIImageView *normalView;
@property (weak, nonatomic) IBOutlet UISlider *slideView;
@property (weak, nonatomic) IBOutlet UIImageView *resultView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic,assign) int lastValue;
@end

@implementation DetailController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    
    __block UIImage *resalutImage;
    [self.activityView startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        switch (_row) {
                // 均值模糊
            case 0:
                resalutImage = [UIImage blurWithImage:_normalView.image];
                break;
                
                // 高斯模糊
            case 1:
                resalutImage = [UIImage GaussianBlurWithImage:_normalView.image];
                break;
            
                // 双边平滑
            case 2 :
                resalutImage = [UIImage bilateralFilterWithImage: _normalView.image];
                break;
                
                // 实现自己的线性滤波
            case 3:
                resalutImage = [UIImage filterWithImgae:_normalView.image ind:_lastValue];
                break;
                
                // Sobel 导数
            case 4:
                resalutImage = [UIImage sobelWithImage:_normalView.image];
                break;
                
                // Laplacian算子
            case 5:
                resalutImage = [UIImage laplacianWithImage:_normalView.image];
                break;
                
            case 6:
                // Remapping重映射
                resalutImage = [UIImage remappingWithImage:_normalView.image];
                break;
                
                // 卡通
            case 7:
//                resalutImage = [UIImage cartoonWithImage:_normalView.image];
                resalutImage = [self aaa:[UIImage imageNamed:@"2.JPG"]];

                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultView.image = resalutImage;
            [self.activityView stopAnimating];
            [self.activityView removeFromSuperview];
            
            if (_row == 3) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(valueDidChange) userInfo:nil repeats:YES];
            }
        });
    });
}

- (UIImage *)aaa:(UIImage *)image
{
    cv::Mat grayFrame,_lastFrame, mask,bgModel,fgModel;
    NSLog(@"0000000");
    
    _lastFrame = [image CVMat];
    NSLog(@"222222");
    
    cv::cvtColor(_lastFrame, grayFrame,cv::COLOR_RGBA2BGR);//转换成三通道bgr
    cv::Rect rectangle(1,1,grayFrame.cols-2,grayFrame.rows -2);//检测的范围
    NSLog(@"3333333");
    
    //分割图像
    cv::grabCut(grayFrame, mask, rectangle, bgModel, fgModel, 3,cv::GC_INIT_WITH_RECT);//openCv强大的扣图功能
    
    NSLog(@"11111111");
    
    int nrow = grayFrame.rows;
    int ncol = grayFrame.cols * grayFrame.channels();
    for(int j=0; j<nrow; j++){//扣图，不知道这样写对不对，我也是新手，请大家多多指教
        for(int i=0; i<ncol; i++){
            uchar val = mask.at<uchar>(j,i);
            if(val==cv::GC_PR_BGD){
                grayFrame.at<cv::Vec3b>(j,i)[0]= '\255';
                grayFrame.at<cv::Vec3b>(j,i)[1]= '\255';
                grayFrame.at<cv::Vec3b>(j,i)[2]= '\255';
            }
        }
    }
    cv::cvtColor(grayFrame, grayFrame,cv::COLOR_BGR2RGB); //转换成彩色图片
    return [[UIImage alloc] initWithCVMat:grayFrame];//显示结果
}



#pragma mark -

//颜色替换

- (UIImage*) imageToTransparent:(UIImage*) image
{
    // 分配内存
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++)
    {
        //把绿色变成黑色，把背景色变成透明
        if ((*pCurPtr & 0x65815A00) == 0x65815a00)    // 将背景变成透明
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
        else if ((*pCurPtr & 0x00FF0000) == 0x00ff0000)    // 将绿色变成黑色
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = 0; //0~255
            ptr[2] = 0;
            ptr[1] = 0;
        }
        else if ((*pCurPtr & 0xFFFFFF00) == 0xffffff00)    // 将白色变成透明
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
        else
        {
            // 改成下面的代码，会将图片转成想要的颜色
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = 0; //0~255
            ptr[2] = 0;
            ptr[1] = 0;
        }
    }
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // free(rgbImageBuf) 创建dataProvider时已提供释放函数，这里不用free
    return resultUIImage;
}



/** 颜色变化 */

void ProviderReleaseData (void *info, const void *data, size_t size)

{
    
    free((void*)data);
    
}


#pragma mark -


- (IBAction)sliderValueDidChange:(UISlider *)sender {
    int value = (int)sender.value;
    if (self.lastValue == value) return;
    self.lastValue = value;
    self.resultView.image = [UIImage filterWithImgae:_normalView.image ind:sender.value];
}

- (void) valueDidChange {
    self.resultView.image = [UIImage filterWithImgae:_normalView.image ind:_lastValue];
    _lastValue++;
    NSLog(@"");
}


- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
}
@end
