//
//  AppDelegate.h
//  tiny-wings-mac
//
//  Created by Sergey Tikhonov on 15.12.11.
//  Copyright iPlayful Inc. 2011. All rights reserved.
//

#import "cocos2d.h"

@interface tiny_wings_macAppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow	*window_;
	MacGLView	*glView_;
}

@property (assign) IBOutlet NSWindow	*window;
@property (assign) IBOutlet MacGLView	*glView;

- (IBAction)toggleFullScreen:(id)sender;

@end
