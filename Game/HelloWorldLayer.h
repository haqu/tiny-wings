//
// Tiny Wings http://github.com/haqu/tiny-wings
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@class Terrain;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
	float screenW;
	float screenH;
	CCSprite *background_;
	Terrain *terrain_;
}
@property (nonatomic, retain) CCSprite *background;
@property (nonatomic, retain) Terrain *terrain;

// returns a CCScene that contains the HelloWorldLayer as the only child
+ (CCScene*) scene;

@end
