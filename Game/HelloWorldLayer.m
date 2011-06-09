//
// Tiny Wings http://github.com/haqu/tiny-wings
//

// Import the interfaces
#import "HelloWorldLayer.h"
#import "Terrain.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize background = background_;
@synthesize terrain = terrain_;

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
	
	CGSize textureSize = CGSizeMake(screenW, screenH);

	ccColor3B c = (ccColor3B){140,205,221};
	
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize.width height:textureSize.height];
    [rt beginWithClear:(float)c.r/256.0f g:(float)c.g/256.0f b:(float)c.b/256.0f a:1];

	// layer 1: gradient

	float gradientAlpha = 0.2f;

	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
    CGPoint vertices[4];
	ccColor4F colors[4];
    int nVertices = 0;
	
	vertices[nVertices] = CGPointMake(0, 0);
	colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	vertices[nVertices] = CGPointMake(textureSize.width, 0);
	colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	vertices[nVertices] = CGPointMake(0, textureSize.height);
	colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
	vertices[nVertices] = CGPointMake(textureSize.width, textureSize.height);
	colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
	
    glVertexPointer(2, GL_FLOAT, 0, vertices);
	glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);	

	// layer 2: noise
	
	CCSprite *s = [CCSprite spriteWithFile:@"noise.png"];
	[s setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
	s.position = ccp(textureSize.width/2, textureSize.height/2);
    glColor4f(1,1,1,1);
	[s visit];
	
    [rt end];
	
	return [CCSprite spriteWithTexture:rt.sprite.texture];
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
		
		self.background = [self generateBackground];
		background_.position = ccp(240,160);
		[self addChild:background_];		

		self.terrain = [Terrain new];
		[self addChild:terrain_];

		self.isTouchEnabled = YES;
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
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

	[terrain_ toggleScrolling];
	
	return YES;
}

@end
