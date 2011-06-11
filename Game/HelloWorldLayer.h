/*
 *	Tiny Wings remake
 *	http://github.com/haqu/tiny-wings
 *
 *	Created by Sergey Tikhonov http://haqu.net
 *	Released under the MIT License
 *
 */

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"

@class Terrain;
@class Hero;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
	float screenW;
	float screenH;
	b2World *world;
	CCSprite *background_;
	Terrain *terrain_;
	Hero *hero_;
	BOOL tapDown;
}
@property (nonatomic, retain) CCSprite *background;
@property (nonatomic, retain) Terrain *terrain;
@property (nonatomic, retain) Hero *hero;

// returns a CCScene that contains the HelloWorldLayer as the only child
+ (CCScene*) scene;

@end
