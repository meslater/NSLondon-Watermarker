//
//  PhotoEditingViewController.m
//  NSLondonWatermark
//
//  Created by Michael Slater on 17/06/2014.
//  Copyright (c) 2014 Michael Slater. All rights reserved.
//

#import "PhotoEditingViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface PhotoEditingViewController () <PHContentEditingController>
@property (strong) PHContentEditingInput *input;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PhotoEditingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PHContentEditingController

- (BOOL)canHandleAdjustmentData:(PHAdjustmentData *)adjustmentData {
    // Inspect the adjustmentData to determine whether your extension can work with past edits.
    // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
    return [adjustmentData.formatIdentifier isEqualToString:@"com.NSLondon"];
}

- (void)startContentEditingWithInput:(PHContentEditingInput *)contentEditingInput placeholderImage:(UIImage *)placeholderImage {
  self.input = contentEditingInput;
  //This should be placeholderImage to avoid loading the whole full res image into the view when we don't need to.
  //Here we just do the work to save us having to write more code. We do this exact work again later, obviously don't do that!
  self.imageView.image = [self _renderedUIImage];
    // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
    // If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
    // If you returned NO, the contentEditingInput has past edits "baked in".
}

- (void)finishContentEditingWithCompletionHandler:(void (^)(PHContentEditingOutput *))completionHandler {
    // Update UI to reflect that editing has finished and output is being rendered.
    // Render and provide output on a background queue.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create editing output from the editing input.
        PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput:self.input];
        
        // Provide new adjustments and render output to given location.
      NSDictionary *adjustmentsDic = @{@"applied-effect" : @"NSLondon"};
        output.adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"com.NSLondon" formatVersion:@"1.0" data:[NSKeyedArchiver archivedDataWithRootObject:adjustmentsDic]];
        NSData *renderedJPEGData = [self _renderedJPEGData];
        [renderedJPEGData writeToURL:output.renderedContentURL atomically:YES];
        
        // Call completion handler to commit edit to Photos.
        completionHandler(output);
        
        // Clean up temporary files, etc.
    });
}

- (UIImage *)_renderedUIImage {
  NSData* imputImageData = [[NSData alloc] initWithContentsOfURL:self.input.fullSizeImageURL];
  UIImage *inputImage = [UIImage imageWithData:imputImageData];
  
  UIGraphicsBeginImageContext(inputImage.size);
  NSString *nsLondon = @"NSLondon";
  
  [inputImage drawAtPoint:CGPointZero];
  NSMutableDictionary *outlineAttributes =[@{NSFontAttributeName: [UIFont systemFontOfSize:20.0],
                                      NSStrokeWidthAttributeName : @(3.0),
                                      NSStrokeColorAttributeName : [UIColor blackColor]
                                      } mutableCopy];
  

  
  CGSize size = [nsLondon sizeWithAttributes:outlineAttributes];
  CGFloat fontSize = (inputImage.size.width / size.width) * 20.0 * 0.8;
  outlineAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:fontSize];
  NSDictionary *fillAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                   NSForegroundColorAttributeName : [UIColor colorWithRed:0.9 green:1.0 blue:1.0 alpha:1.0]};
  
  size = [nsLondon sizeWithAttributes:fillAttributes];
  
  CGPoint location = CGPointMake((inputImage.size.width - size.width) / 2.0,
                                 (inputImage.size.height - size.height) / 2.0);
  [nsLondon drawAtPoint:location withAttributes:fillAttributes];
  [nsLondon drawAtPoint:location withAttributes:outlineAttributes];
  
  UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return outputImage;
}

- (NSData *)_renderedJPEGData {
  return UIImageJPEGRepresentation([self _renderedUIImage], 1.0f);
}

- (void)cancelContentEditing {
    // Clean up temporary files, etc.
    // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
}

@end
