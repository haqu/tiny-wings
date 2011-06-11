/*
 *	Tiny Wings remake
 *	http://github.com/haqu/tiny-wings
 *
 *	Created by Sergey Tikhonov http://haqu.net
 *	Released under the MIT License
 *
 */

// Import the interfaces
#import "HelloWorldLayer.h"
#import "Terrain.h"
#import "Hero.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize background = background_;
@synthesize terrain = terrain_;
@synthesize hero = hero_;

+ (CCScene*) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (CCSprite*) generateBackground {
	
	int textureSize = 512;
	
	ccColor3B c = (ccColor3B){140,205,221};
	
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    [rt beginWithClear:(float)c.r/256.0f g:(float)c.g/256.0f b:(float)c.b/256.0f a:1];
	
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
    glColor4f(1,1,1,1);
	[s visit];
	
    [rt end];
	
	return [CCSprite spriteWithTexture:rt.sprite.texture];
}

- (void) createBox2DWorld {
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -9.8f);
	
	world = new b2World(gravity, true);
	world->SetContinuousPhysics(true);
	
//	debugDraw = new GLESDebugDraw(PTM_RATIO);
//	world->SetDebugDraw(debugDraw);
	
//	uint32 flags = 0;
//	flags += b2DebugDraw::e_shapeBit;
//	debugDraw->SetFlags(flags);
	
}

// on "init" you need to initialize your instance
- (id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
		screenW = size.width;
		screenH = size.height;

		[self createBox2DWorld];
		
		self.background = [self generateBackground];
		background_.position = ccp(screenW/2,screenH/2);
		ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
		[background_.texture setTexParameters:&tp];
		[self addChild:background_];		

		self.terrain = [Terrain terrainWithWorld:world];
		[self addChild:terrain_];

		self.hero = [Hero heroWithWorld:world];
		[terrain_ addChild:hero_];
		
		self.isTouchEnabled = YES;
		tapDown = NO;
		
		[self scheduleUpdate];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	delete world;
	world = NULL;
	
	self.background = nil;
	self.terrain = nil;
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (void) registerWithTouchDispatcher {
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	
//	[terrain_ toggleScrolling];

	tapDown = YES;
	
	return YES;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	
	tapDown = NO;
}

- (void) update:(ccTime)dt {

	if (tapDown) {
		[hero_ run];
	} else {
		[hero_ walk];
	}
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	world->Step(dt, velocityIterations, positionIterations);
	
	[hero_ updatePosition];

	terrain_.offsetX = hero_.position.x - screenW/4;

	CGSize size = background_.textureRect.size;
	background_.textureRect = CGRectMake(terrain_.offsetX*0.2f, 0, size.width, size.height);
}

@end
