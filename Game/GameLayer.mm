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
- (void) reset;
@end

@implementation GameLayer

@synthesize screenW = _screenW;
@synthesize screenH = _screenH;
@synthesize world = _world;
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
		_screenW = screenSize.width;
		_screenH = screenSize.height;

		[self createBox2DWorld];

#ifndef DRAW_BOX2D_WORLD

		self.sky = [Sky skyWithTextureSize:1024];
		[self addChild:_sky z:kSkyLevel];
		
#endif

		self.terrain = [Terrain terrainWithWorld:_world];
		[self addChild:_terrain z:kWorldLevel];
		
		self.hero = [Hero heroWithGame:self];
		[_terrain addChild:_hero z:kWorldLevel];

		self.resetButton = [CCSprite spriteWithFile:@"resetButton.png"];
		[self addChild:_resetButton z:kGUILevel];
		CGSize size = _resetButton.contentSize;
		float padding = 8;
		_resetButton.position = ccp(_screenW-size.width/2-padding, _screenH-size.height/2-padding);
		
		self.isTouchEnabled = YES;
                    
        CCParticleSystem *particle=[[[CCParticleSystemQuad alloc] initWithTotalParticles:200] autorelease];
        ///////**** Assignment Texture Filename!  ****///////
        CCTexture2D *texture=[[CCTextureCache sharedTextureCache] addImage:@"Leaf.png"];
        particle.texture=texture;
        particle.emissionRate=20;
        particle.angle=180.0;
        particle.angleVar=0.0;
        ccBlendFunc blendFunc={GL_ONE,GL_ONE_MINUS_SRC_ALPHA};
        particle.blendFunc=blendFunc;
        particle.duration=-1.00;
        particle.emitterMode=kCCParticleModeGravity;
        ccColor4F startColor={0.15,0.29,0.20,1.00};
        particle.startColor=startColor;
        ccColor4F startColorVar={0.46,0.46,0.45,0.50};
        particle.startColorVar=startColorVar;
        ccColor4F endColor={1.00,0.30,0.26,0.00};
        particle.endColor=endColor;
        ccColor4F endColorVar={0.54,0.60,0.61,0.65};
        particle.endColorVar=endColorVar;
        particle.startSize=5.0;
        particle.startSizeVar=5.00;
        particle.endSize=5.0;
        particle.endSizeVar=5.00;
        particle.gravity=ccp(-40.00,-20.00);
        particle.radialAccel=0.00;
        particle.radialAccelVar=1.00;
        particle.speed=100;
        particle.speedVar=25;
        particle.tangentialAccel= 0;
        particle.tangentialAccelVar= 1;
        particle.totalParticles=20;
        particle.life=2.00;
        particle.lifeVar=15.00;
        particle.startSpin=0.00;
        particle.startSpinVar=0.00;
        particle.endSpin=0.00;
        particle.endSpinVar=0.00;
        particle.position=ccp(468.00,208.00);
        particle.posVar=ccp(20.00,200.00);
        
        [self addChild:particle z:kParticlesLevel];
		
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

	delete _render;
	_render = NULL;
	
#endif
	
	delete _world;
	_world = NULL;
	
	[super dealloc];
}

- (void) registerWithTouchDispatcher {
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (void) reset {
    [_terrain reset];
    [_hero reset];
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
		[self reset];
	} else {
		_hero.diving = YES;
	}
	
	return YES;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	_hero.diving = NO;
}

- (void) update:(ccTime)dt {

	[_hero updatePhysics];
	
	int32 velocityIterations = 8;
	int32 positionIterations = 3;
	_world->Step(dt, velocityIterations, positionIterations);
//	_world->ClearForces();
	
	[_hero updateNode];

	// terrain scale and offset
	float height = _hero.position.y;
	const float minHeight = _screenH*4/5;
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
	
	_world = new b2World(gravity, false);

#ifdef DRAW_BOX2D_WORLD
	
	_render = new GLESDebugDraw(PTM_RATIO);
	_world->SetDebugDraw(_render);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
//	flags += b2Draw::e_jointBit;
//	flags += b2Draw::e_aabbBit;
//	flags += b2Draw::e_pairBit;
//	flags += b2Draw::e_centerOfMassBit;
	_render->SetFlags(flags);
	
#endif
}

- (void) showPerfectSlide {
	NSString *str = @"perfect slide";
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:str fntFile:@"good_dog_plain_32.fnt"];
	label.position = ccp(_screenW/2, _screenH/16);
	[label runAction:[CCScaleTo actionWithDuration:1.0f scale:1.2f]];
	[label runAction:[CCSequence actions:
					  [CCFadeOut actionWithDuration:1.0f],
					  [CCCallFuncND actionWithTarget:label selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
					  nil]];
	[self addChild:label z:kGUILevel];
}

- (void) showFrenzy {
	NSString *str = @"FRENZY!";
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:str fntFile:@"good_dog_plain_32.fnt"];
	label.position = ccp(_screenW/2, _screenH/16);
	[label runAction:[CCScaleTo actionWithDuration:2.0f scale:1.4f]];
	[label runAction:[CCSequence actions:
					  [CCFadeOut actionWithDuration:2.0f],
					  [CCCallFuncND actionWithTarget:label selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
					  nil]];
	[self addChild:label z:kGUILevel];
    [_hero startFrenzy];
}

- (void) showHit {
	NSString *str = @"hit";
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:str fntFile:@"good_dog_plain_32.fnt"];
	label.position = ccp(_screenW/2, _screenH/16);
	[label runAction:[CCScaleTo actionWithDuration:1.0f scale:1.2f]];
	[label runAction:[CCSequence actions:
					  [CCFadeOut actionWithDuration:1.0f],
					  [CCCallFuncND actionWithTarget:label selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
					  nil]];
	[self addChild:label z:kGUILevel];
    [_hero stopFrenzy];
}

@end
