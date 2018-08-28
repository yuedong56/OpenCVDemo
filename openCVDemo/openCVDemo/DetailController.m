//
//  DetailController.m
//  openCVDemo
//
//  Created by 梁亦明 on 16/8/28.
//  Copyright © 2016年 xiaoming.com. All rights reserved.
//

#import "DetailController.h"
#import "UIImage+OpenCV.h"


@interface DetailController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic,strong) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIImageView *normalView;
@property (weak, nonatomic) IBOutlet UISlider *slideView;
@property (weak, nonatomic) IBOutlet UIImageView *resultView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic,assign) int lastValue;
@end

@implementation DetailController

- (IBAction)openPhotoAsset:(id)sender {

    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    vc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSLog(@"image == %@", image);
        
        float w = 600;
        float h = w*image.size.height/image.size.width;
        // 创建一个bitmap的context，并把它设置成为当前正在使用的context
        UIGraphicsBeginImageContext(CGSizeMake(w, h));
        // 绘制改变大小的图片
        [image drawInRect:CGRectMake(0, 0, w, h)];
        // 从当前context中创建一个改变大小后的图片
        UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        // 使当前的context出堆栈
        UIGraphicsEndImageContext();
        //返回新的改变大小后的图片
        
        scaledImage = [self aaa:scaledImage];
        self.resultView.image = [self imageToTransparent:scaledImage color:[UIColor redColor]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

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
                resalutImage = [self imageToTransparent:resalutImage color:[UIColor redColor]];

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

- (UIImage*) imageToTransparent:(UIImage*) image color:(UIColor *)color
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
        //        //去除白色...将0xFFFFFF00换成其它颜色也可以替换其他颜色。
        //        if ((*pCurPtr & 0xFFFFFF00) >= 0xffffff00) {
        //
        //            uint8_t* ptr = (uint8_t*)pCurPtr;
        //            ptr[0] = 0;
        //        }
        //接近白色
        //将像素点转成子节数组来表示---第一个表示透明度即ARGB这种表示方式。ptr[0]:透明度,ptr[1]:R,ptr[2]:G,ptr[3]:B
        //分别取出RGB值后。进行判断需不需要设成透明。
        float min = 172;
        float max = 173;
//        float g = r;
//        float b = r;
        uint8_t* ptr = (uint8_t*)pCurPtr;
//        if (ptr[1] > min && ptr[1] <= max &&
//            ptr[2] > min && ptr[2] <= max &&
//            ptr[3] > min && ptr[3] <= max) {
        if (ptr[1] == max &&
            ptr[2] == max &&
            ptr[3] == max) {
            //当RGB值都大于240则比较接近白色的都将透明度设为0.-----即接近白色的都设置为透明。某些白色背景具有杂质就会去不干净，用这个方法可以去干净
            //            ptr[0] = 1;//透明度
            const CGFloat *components = CGColorGetComponents(color.CGColor);
            ptr[3] = components[0]*255;//b
            ptr[2] = components[1]*255;//g
            ptr[1] = components[2]*255;//r
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
