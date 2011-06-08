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
		
		self.background = [CCSprite spriteWithFile:@"background.png"];
		background_.position = ccp(screenW/2, screenH/2);
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
