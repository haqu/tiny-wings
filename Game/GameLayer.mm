/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "GameLayer.h"
#import "Sky.h"
#import "Terrain.h"
#import "Hero.h"

@interface GameLayer()
- (void) createBox2DWorld;
@end

@implementation GameLayer

@synthesize sky = _sky;
@synthesize terrain = _terrain;
@synthesize hero = _hero;
@synthesize resetButton = _resetButton;

+ (CCScene*) scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[GameLayer node]];
    return scene;
}

- (id) init {
    
	if ((self = [super init])) {
		
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        screenW = screenSize.width;
        screenH = screenSize.height;

        [self createBox2DWorld];

#ifndef DRAW_BOX2D_WORLD

        self.sky = [Sky skyWithTextureSize:1024];
        [self addChild:_sky];
        
#endif

        self.terrain = [Terrain terrainWithWorld:world];
        [self addChild:_terrain];
		
        self.hero = [Hero heroWithWorld:world];
        [_terrain addChild:_hero];

        self.resetButton = [CCSprite spriteWithFile:@"resetButton.png"];
        [self addChild:_resetButton];
        CGSize size = _resetButton.contentSize;
        float padding = 8;
        _resetButton.position = ccp(screenW-size.width/2-padding, screenH-size.height/2-padding);
        
        self.isTouchEnabled = YES;
        tapDown = NO;
        
        [self resetEverything];

        [self scheduleUpdate];
    }
    return self;
}

- (void) dealloc {
    
	self.sky = nil;
	self.terrain = nil;
    self.hero = nil;
    self.resetButton = nil;

#ifdef DRAW_BOX2D_WORLD

    delete render;
    render = NULL;
    
#endif
    
	delete world;
	world = NULL;
	
	[super dealloc];
}

- (void) registerWithTouchDispatcher {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (void) resetEverything {
    [_terrain reset];
    [_hero reset];
    flyingState = kFLYING;
    jumpsInARow = 0;
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    CGPoint pos = _resetButton.position;
    CGSize size = _resetButton.contentSize;
    float padding = 8;
    float w = size.width+padding*2;
    float h = size.height+padding*2;
    CGRect rect = CGRectMake(pos.x-w/2, pos.y-h/2, w, h);
    if (CGRectContainsPoint(rect, location)) {
        [self resetEverything];
    } else {
        tapDown = YES;
    }
    
    return YES;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    tapDown = NO;
}

- (BOOL) isGoingDown:(Hero*)hero
{
    return hero.position.y <= lastTouchingSpot.y ? YES : NO;
}

- (BOOL) isGoingUp:(Hero*)hero
{
    return hero.position.y >= lastTouchingSpot.y ? YES : NO;
}

- (void) heroJumped
{
    jumpsInARow++;
    
    NSString *jumpString = [NSString stringWithFormat:@"JUMP x %d", jumpsInARow];
    CCLabelBMFont *jumpLabel = [CCLabelBMFont labelWithString:jumpString fntFile:@"good_dog_plain_32.fnt"];
    [jumpLabel setString:jumpString];

    jumpLabel.position = CGPointMake(70, 120 );
    [jumpLabel runAction:[CCRotateBy actionWithDuration:0.25f angle:(abs(arc4random()%20)-10)]];
    [jumpLabel runAction:[CCScaleBy actionWithDuration:0.25f scale:1.1f]];
    [jumpLabel runAction:[CCSequence actions:
                          [CCFadeOut actionWithDuration:0.4f],
                          [CCCallFuncND actionWithTarget:jumpLabel selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
                          nil] ];
    
    [self addChild:jumpLabel];
}

- (void) handleLandings
{
    switch (flyingState) {
            
        case kFLYING:
            jumpsInARow = 0;
        case kSTREAKING:
            if([_hero isTouchingGround] ) {
                flyingState = kLANDED;
            }
            break;
            
        case kLANDED:
            if([_hero isTouchingGround]) {
                if( [self isGoingUp:_hero] ) {
                    flyingState = kFLYING;
                    jumpsInARow = 0;
                } else if( [self isGoingDown:_hero] ) {
                    flyingState = kGOING_DOWN;
                }                
            } else {
                flyingState = kFLYING;
            }
            break;
        case kGOING_DOWN:
            if([_hero isTouchingGround]) {
                if( [self isGoingUp:_hero] ) {
                    flyingState = kGOING_UP;
                } else if( [self isGoingDown:_hero] ) {
                    flyingState = kGOING_DOWN;
                } 
            } else {
                flyingState = kFLYING;
            }
            break;
        case kGOING_UP:
            if([_hero isTouchingGround]) {
                if([self isGoingDown:_hero]){
                    flyingState = kFLYING;
                }
            } else {
                [self heroJumped];
                flyingState = kSTREAKING;
            }
            
        default:
            break;
    }
               
    lastTouchingSpot = _hero.position;
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
    
    [self handleLandings];
    
    int32 velocityIterations = 8;
    int32 positionIterations = 3;
    world->Step(dt, velocityIterations, positionIterations);
//    world->ClearForces();
    
    // update hero CCNode position
    [_hero updateNodePosition];

    // terrain scale and offset
    float height = _hero.position.y;
    const float minHeight = screenH*4/5;
    if (height < minHeight) {
        height = minHeight;
    }
    float scale = minHeight / height;
    _terrain.scale = scale;
    _terrain.offsetX = _hero.position.x;

#ifndef DRAW_BOX2D_WORLD

    [_sky setOffsetX:_terrain.offsetX*0.2f];
    [_sky setScale:1.0f-(1.0f-scale)*0.75f];
    
#endif
}

- (void) createBox2DWorld {
    
    b2Vec2 gravity;
    gravity.Set(0.0f, -9.8f);
    
    world = new b2World(gravity, false);

#ifdef DRAW_BOX2D_WORLD
    
    render = new GLESDebugDraw(PTM_RATIO);
    world->SetDebugDraw(render);
    
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
//	flags += b2Draw::e_jointBit;
//	flags += b2Draw::e_aabbBit;
//	flags += b2Draw::e_pairBit;
//	flags += b2Draw::e_centerOfMassBit;
	render->SetFlags(flags);
    
#endif
}

@end
