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
#import "GLES-Render.h"

@class Sky;
@class Terrain;
@class Hero;

typedef enum { kFLYING, kLANDED, kGOING_DOWN, kGOING_UP, kSTREAKING } FlyingState;

@interface GameLayer : CCLayer {
    int screenW;
    int screenH;
    b2World *world;
    Sky *_sky;
    Terrain *_terrain;
    Hero *_hero;
    BOOL tapDown;
    GLESDebugDraw *render;
    CCSprite *_resetButton;
    FlyingState flyingState;
    CGPoint lastTouchingSpot;
    int jumpsInARow;
}
@property (nonatomic, retain) Sky *sky;
@property (nonatomic, retain) Terrain *terrain;
@property (nonatomic, retain) Hero *hero;
@property (nonatomic, retain) CCSprite *resetButton;

+ (CCScene*) scene;
- (void) resetEverything;
@end