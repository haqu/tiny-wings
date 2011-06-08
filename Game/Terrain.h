//
// Tiny Wings http://github.com/haqu/tiny-wings
//

#import "cocos2d.h"

#define kMaxHillKeyPoints 100
#define kMaxHillVertices 1000000
#define kMaxHillVisibleVertices 10000 

@interface Terrain : CCNode {
	CGPoint hillKeyPoints[kMaxHillKeyPoints];
	int nHillKeyPoints;
	CGPoint hillVertices[kMaxHillVertices];
	CGPoint hillTexCoords[kMaxHillVertices];
	int nHillVertices;
	CGPoint hillVisibleVertices[kMaxHillVisibleVertices];
	CGPoint hillVisibleTexCoords[kMaxHillVisibleVertices];
	int nHillVisibleVertices;
	CCSprite *stripes_;
	BOOL scrolling;
	float offsetX;
}
@property (nonatomic, retain) CCSprite *stripes;

- (void) toggleScrolling;

@end
