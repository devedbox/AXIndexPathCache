//
//  DetailViewController.h
//  AXCellCacheDemo
//
//  Created by ai on 15/7/9.
//  Copyright © 2015年 ai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

