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

@class Terrain;
@class Hero;

@interface GameLayer : CCLayer {
    float screenW;
    float screenH;
    b2World *world;
    CCSprite *_background;
    Terrain *_terrain;
    Hero *_hero;
    BOOL tapDown;
}
@property (nonatomic, retain) CCSprite *background;
@property (nonatomic, retain) Terrain *terrain;
@property (nonatomic, retain) Hero *hero;

+ (CCScene*) scene;

@end
