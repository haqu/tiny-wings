//
//  Tiny Wings Remake
//  http://github.com/haqu/tiny-wings
//
//  Created by Sergey Tikhonov http://haqu.net
//  Released under the MIT License
//

#import "Box2DHelper.h"
#import "cocos2d.h"

@implementation Box2DHelper

+ (float) pointsPerMeter {
	return 32.0f;
}

+ (float) metersPerPoint {
	return 1.0f / [self pointsPerMeter];
}

+ (float) pixelsPerMeter {
	return [self pointsPerMeter] * CC_CONTENT_SCALE_FACTOR();
}

+ (float) metersPerPixel {
	return 1.0f / [self pixelsPerMeter];
}

@end
