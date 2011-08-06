/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "cocos2d.h"
#import "Box2D.h"

#define kMaxHillKeyPoints 101
#define kMaxHillVertices 1000
#define kMaxBorderVertices 5000
#define kHillSegmentWidth 15

#define ccpR(x,y) ccp( (CC_CONTENT_SCALE_FACTOR()*(x)), (CC_CONTENT_SCALE_FACTOR()*(y)) )

@interface Terrain : CCNode {
	CGPoint hillKeyPoints[kMaxHillKeyPoints];
	int nHillKeyPoints;
	int fromKeyPointI;
	int toKeyPointI;
	CGPoint hillVertices[kMaxHillVertices];
	CGPoint hillTexCoords[kMaxHillVertices];
	int nHillVertices;
	CGPoint borderVertices[kMaxBorderVertices];
	int nBorderVertices;
	CCSprite *_stripes;
	float _offsetX;
	b2World *world;
	b2Body *body;
	int screenW;
	int screenH;
	int textureSize;
}
@property (nonatomic, retain) CCSprite *stripes;
@property (nonatomic, assign) float offsetX;

+ (id) terrainWithWorld:(b2World*)w;
- (id) initWithWorld:(b2World*)w;

- (void) reset;

@end
