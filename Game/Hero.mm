/*
 *	Tiny Wings remake
 *	http://github.com/haqu/tiny-wings
 *
 *	Created by Sergey Tikhonov http://haqu.net
 *	Released under the MIT License
 *
 */

#import "Hero.h"
#import "Box2D.h"

@implementation Hero

+ (id) heroWithWorld:(b2World*)w {
	return [[[self alloc] initWithWorld:w] autorelease];
}

- (id) initWithWorld:(b2World*)w {
	if ((self = [super init])) {
		world = w;
		radius = 16.0f;
		
		// create box2d body

		CGSize size = [[CCDirector sharedDirector] winSize];
		int screenW = size.width;
		int screenH = size.height;
		
		b2BodyDef bd;
		bd.type = b2_dynamicBody;
		bd.position.Set(screenW/4/PTM_RATIO, screenH/2/PTM_RATIO);
		body = world->CreateBody(&bd);
		
		b2CircleShape shape;
		shape.m_radius = radius/PTM_RATIO;
		
		b2FixtureDef fd;
		fd.shape = &shape;
		fd.density = 1.0f;
		fd.restitution = 0; // 0 - no bounce, 1 - perfect bounce
		fd.friction = 1000.0f;
		
		body->CreateFixture(&fd);
		
	}
	return self;
}

- (void) draw {
	glColor4f(0.25f, 0.25f, 1.0f, 1.0f);
	glLineWidth(2);
	ccDrawCircle(ccp(0,0), radius, body->GetAngle(), 16, YES);
}

- (void) updatePosition {
	self.position = ccp(body->GetPosition().x*PTM_RATIO, body->GetPosition().y*PTM_RATIO);
}

- (void) walk {
	body->ApplyTorque(-1);
}

- (void) run {
	body->ApplyTorque(-7);
}

@end
