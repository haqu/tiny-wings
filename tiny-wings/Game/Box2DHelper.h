//
//  Tiny Wings Remake
//  http://github.com/haqu/tiny-wings
//
//  Created by Sergey Tikhonov http://haqu.net
//  Released under the MIT License
//

@interface Box2DHelper : NSObject

// ignore CC_CONTENT_SCALE_FACTOR
+ (float) pointsPerMeter;
+ (float) metersPerPoint;

// consider CC_CONTENT_SCALE_FACTOR
+ (float) pixelsPerMeter;
+ (float) metersPerPixel;

@end
