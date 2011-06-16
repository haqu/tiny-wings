/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "Hero.h"
#import "Box2D.h"

@interface Hero()
- (void) createBox2DBody;
@end

@implementation Hero

@synthesize awake;

+ (id) heroWithWorld:(b2World*)w {
	return [[[self alloc] initWithWorld:w] autorelease];
}

- (id) initWithWorld:(b2World*)w {
    
	if ((self = [super initWithFile:@"hero.png"])) {
        
		world = w;
		radius = 16.0f;
		awake = NO;

		[self createBox2DBody];
        [self updateNodePosition];
		[self sleep];
	}
	return self;
}

- (void) createBox2DBody {

    CGSize size = [[CCDirector sharedDirector] winSize];
    int screenH = size.height;

    CGPoint startPosition = ccp(0, screenH/2+radius);
    
    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    bd.linearDamping = 0.1f;
    bd.fixedRotation = true;
    bd.position.Set(startPosition.x/PTM_RATIO, startPosition.y/PTM_RATIO);
    body = world->CreateBody(&bd);
    
    b2CircleShape shape;
    shape.m_radius = radius/PTM_RATIO;
    
    b2FixtureDef fd;
    fd.shape = &shape;
    fd.density = 1.0f;
    fd.restitution = 0; // bounce
    fd.friction = 0;
    
    body->CreateFixture(&fd);
}

- (void) sleep {
	awake = NO;
	body->SetActive(false);
}

- (void) wake {
	awake = YES;
	body->SetActive(true);
	body->ApplyLinearImpulse(b2Vec2(1,2), body->GetPosition());
}

- (void) dive {
    body->ApplyForce(b2Vec2(0,-40),body->GetPosition());
}

- (void) limitVelocity {
    const float minVelocityX = 2;
    const float minVelocityY = -40;
    b2Vec2 vel = body->GetLinearVelocity();
    if (vel.x < minVelocityX) {
        vel.x = minVelocityX;
    }
    if (vel.y < minVelocityY) {
        vel.y = minVelocityY;
    }
    body->SetLinearVelocity(vel);
}

- (void) updateNodePosition {
	self.position = ccp(body->GetPosition().x*PTM_RATIO, body->GetPosition().y*PTM_RATIO);
    b2Vec2 vel = body->GetLinearVelocity();
    float angle = atan2f(vel.y, vel.x);
    self.rotation = -1 * CC_RADIANS_TO_DEGREES(angle);
}

@end
