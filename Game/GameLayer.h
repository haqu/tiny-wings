/*
 *  Tiny Wings remake
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
    CCSprite *background_;
    Terrain *terrain_;
    Hero *hero_;
    BOOL tapDown;
}
@property (nonatomic, retain) CCSprite *background;
@property (nonatomic, retain) Terrain *terrain;
@property (nonatomic, retain) Hero *hero;

+ (CCScene*) scene;

@end
