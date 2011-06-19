/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "GameLayer.h"
#import "Terrain.h"
#import "Hero.h"

@interface GameLayer()
- (ccColor3B) generateDarkColor;
- (void) generateBackground;
- (void) createBox2DWorld;
@end

@implementation GameLayer

@synthesize background = _background;
@synthesize terrain = _terrain;
@synthesize hero = _hero;

+ (CCScene*) scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[GameLayer node]];
    return scene;
}

- (id) init {
    
	if ((self = [super init])) {
		
        CGSize size = [[CCDirector sharedDirector] winSize];
        screenW = size.width;
        screenH = size.height;

        [self createBox2DWorld];

#ifndef DRAW_BOX2D_WORLD
        [self generateBackground];
#endif

        self.terrain = [Terrain terrainWithWorld:world];
        [self addChild:_terrain];
		
        self.hero = [Hero heroWithWorld:world];
        [_terrain addChild:_hero];

        self.isTouchEnabled = YES;
        tapDown = NO;

        [self scheduleUpdate];
    }
    return self;
}

- (void) dealloc {
    
	delete world;
	world = NULL;
	
	self.background = nil;
	self.terrain = nil;
	
	[super dealloc];
}

- (void) registerWithTouchDispatcher {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    tapDown = YES;
    return YES;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    tapDown = NO;
}

- (void) update:(ccTime)dt {

    if (tapDown) {
		if (!_hero.awake) {
			[_hero wake];
			tapDown = NO;
		} else {
			[_hero dive];
		}
    }
    [_hero limitVelocity];
    
    int32 velocityIterations = 8;
    int32 positionIterations = 3;
    world->Step(dt, velocityIterations, positionIterations);
//    world->ClearForces();
    
    // update hero CCNode position
    [_hero updateNodePosition];

    // terrain scale
    float scale = (screenH*4/5) / _hero.position.y;
    if (scale > 1) scale = 1;
    _terrain.scale = scale;
    
    // terrain offset
    _terrain.offsetX = _hero.position.x;

#ifndef DRAW_BOX2D_WORLD
    // background texture offset
    CGSize size = _background.textureRect.size;
    _background.textureRect = CGRectMake(_terrain.offsetX*0.2f, 0, size.width, size.height);
#endif
}

- (ccColor3B) generateDarkColor {
    const int maxValue = 200;
    const int minValue = 100;
    const int maxSum = 350;
    int r, g, b;
    while (true) {
        r = arc4random()%(maxValue-minValue)+minValue;
        g = arc4random()%(maxValue-minValue)+minValue;
        b = arc4random()%(maxValue-minValue)+minValue;
        if (r+g+b > maxSum) break;
    }
    return ccc3(r, g, b);
}

- (void) generateBackground {
    
    int textureSize = 512;
    
    ccColor3B c = (ccColor3B){140, 205, 221};
//    ccColor3B c = [self generateDarkColor];
    ccColor4F cf = ccc4FFromccc3B(c);
    
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    [rt beginWithClear:cf.r g:cf.g b:cf.b a:cf.a];
    
    // layer 1: gradient
    
    float gradientAlpha = 0.25f;
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    
    vertices[nVertices] = ccp(0, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, 0};
    vertices[nVertices] = ccp(textureSize, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, 0};
    vertices[nVertices] = ccp(0, textureSize);
    colors[nVertices++] = (ccColor4F){1, 1, 1, gradientAlpha};
    vertices[nVertices] = ccp(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){1, 1, 1, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);	
    
    // layer 2: noise
    
    CCSprite *s = [CCSprite spriteWithFile:@"noise.png"];
    [s setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    s.position = ccp(textureSize/2, textureSize/2);
    s.scale = (float)textureSize/512.0f;
    glColor4f(1,1,1,1);
    [s visit];
    
    [rt end];

    self.background = [CCSprite spriteWithTexture:rt.sprite.texture];
    ccTexParams tp = {GL_NEAREST, GL_NEAREST, GL_REPEAT, GL_REPEAT};
    [_background.texture setTexParameters:&tp];
    _background.position = ccp(screenW/2,screenH/2);
//    _background.scale = 0.5f;
    
    [self addChild:_background];		
}

- (void) createBox2DWorld {
    
    b2Vec2 gravity;
    gravity.Set(0.0f, -9.8f);
    
    world = new b2World(gravity, false);
//    world->SetWarmStarting(true);
//    world->SetContinuousPhysics(true);
    
    render = new GLESDebugDraw(PTM_RATIO);
    world->SetDebugDraw(render);
    
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
//	flags += b2Draw::e_jointBit;
//	flags += b2Draw::e_aabbBit;
//	flags += b2Draw::e_pairBit;
//	flags += b2Draw::e_centerOfMassBit;
	render->SetFlags(flags);
}

- (void) draw {

    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    

    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);	
}

@end
