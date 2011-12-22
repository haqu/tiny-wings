//
//  Tiny Wings Remake
//  http://github.com/haqu/tiny-wings
//
//  Created by Sergey Tikhonov http://haqu.net
//  Released under the MIT License
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

@class Sky;
@class Terrain;
@class Hero;

@interface Game : CCLayer {
	int _screenW;
	int _screenH;
	b2World *_world;
	Sky *_sky;
	Terrain *_terrain;
	Hero *_hero;
	GLESDebugDraw *_render;
	CCSprite *_resetButton;
}
@property (readonly) int screenW;
@property (readonly) int screenH;
@property (nonatomic, readonly) b2World *world;
@property (nonatomic, retain) Sky *sky;
@property (nonatomic, retain) Terrain *terrain;
@property (nonatomic, retain) Hero *hero;
@property (nonatomic, retain) CCSprite *resetButton;

+ (CCScene*) scene;

- (void) showPerfectSlide;
- (void) showFrenzy;
- (void) showHit;

@end
