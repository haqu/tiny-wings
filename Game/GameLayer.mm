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
- (CCSprite*) generateBackground;
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

        self.background = [self generateBackground];
        _background.position = ccp(screenW/2,screenH/2);
        ccTexParams tp = {GL_NEAREST, GL_NEAREST, GL_REPEAT, GL_REPEAT};
        [_background.texture setTexParameters:&tp];
        [self addChild:_background];		

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
    int32 positionIterations = 1;
    world->Step(dt, velocityIterations, positionIterations);
    world->ClearForces();
    
    // update hero CCNode position
    [_hero updateNodePosition];

    // terrain scale
    float scale = (screenH*4/5) / _hero.position.y;
    if (scale > 1) scale = 1;
    _terrain.scale = scale;
    
    // terrain offset
    _terrain.offsetX = _hero.position.x;

    // background texture offset
    CGSize size = _background.textureRect.size;
    _background.textureRect = CGRectMake(_terrain.offsetX*0.2f, 0, size.width, size.height);
}

- (ccColor3B) generateDarkColor {
    const int maxValue = 100;
    const int maxSum = 250;
    int r, g, b;
    while (true) {
        r = arc4random()%maxValue;
        g = arc4random()%maxValue;
        b = arc4random()%maxValue;
        if (r+g+b > maxSum) break;
    }
    return ccc3(r, g, b);
}

- (CCSprite*) generateBackground {
    
    int textureSize = 512;
    
    //    ccColor3B c = (ccColor3B){140, 205, 221};
    ccColor3B c = [self generateDarkColor];
    ccColor4F cf = ccc4FFromccc3B(c);
    
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    [rt beginWithClear:cf.r g:cf.g b:cf.b a:cf.a];
    
    // layer 1: gradient
    
    float gradientAlpha = 0.5f;
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(0, textureSize/2);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize, textureSize/2);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
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
    
    return [CCSprite spriteWithTexture:rt.sprite.texture];
}

- (void) createBox2DWorld {
    
    b2Vec2 gravity;
    //    gravity.Set(0.0f, -9.8f);
    gravity.Set(0, -7);
    
    world = new b2World(gravity, true);
    world->SetContinuousPhysics(true);
}

@end
