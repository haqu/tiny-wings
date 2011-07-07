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

@synthesize sprite = _sprite;
@synthesize awake;

+ (id) heroWithWorld:(b2World*)w {
	return [[[self alloc] initWithWorld:w] autorelease];
}

- (id) initWithWorld:(b2World*)w {
    
	if ((self = [super init])) {

#ifndef DRAW_BOX2D_WORLD
        self.sprite = [CCSprite spriteWithFile:@"hero.png"];
        [self addChild:_sprite];
#endif
        
		world = w;
		radius = 14.0f;
		awake = NO;

		[self createBox2DBody];
        [self updateNodePosition];
		[self sleep];
	}
	return self;
}

- (void) dealloc {

#ifndef DRAW_BOX2D_WORLD
    self.sprite = nil;
#endif

    [super dealloc];
}

- (void) createBox2DBody {

    CGSize size = [[CCDirector sharedDirector] winSize];
    int screenH = size.height;

    CGPoint startPosition = ccp(0, screenH/2+radius);
    
    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    bd.linearDamping = 0.05f;
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
    const float minVelocityX = 3;
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

    float x = body->GetPosition().x*PTM_RATIO;
    float y = body->GetPosition().y*PTM_RATIO;

	self.position = ccp(x, y);
    b2Vec2 vel = body->GetLinearVelocity();
    float angle = atan2f(vel.y, vel.x);

#ifdef DRAW_BOX2D_WORLD
    
    body->SetTransform(body->GetPosition(), angle);
    
#else
    
    self.rotation = -1 * CC_RADIANS_TO_DEGREES(angle);
    
#endif
    
    if (y < -radius && awake) {
        [self sleep];
    }
}

- (void) reset {
    world->DestroyBody(body);
    [self createBox2DBody];
    [self sleep];
}

-(BOOL) isTouchingGround {
    b2ContactEdge *edge = body->GetContactList();
    return edge ? YES : NO;
}

@end
