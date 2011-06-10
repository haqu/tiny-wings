//
// Tiny Wings http://github.com/haqu/tiny-wings
//

#import "cocos2d.h"

#define kMaxHillKeyPoints 100
#define kMaxHillVertices 2000
#define kHillSegmentWidth 3
#define kMaxBorderVertices 400

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
	CCSprite *stripes_;
	BOOL scrolling;
	float offsetX;
}
@property (nonatomic, retain) CCSprite *stripes;
@property (readonly) float offsetX;

- (void) toggleScrolling;

@end
