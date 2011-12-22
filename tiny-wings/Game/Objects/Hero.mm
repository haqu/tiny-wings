//
//  Tiny Wings Remake
//  http://github.com/haqu/tiny-wings
//
//  Created by Sergey Tikhonov http://haqu.net
//  Released under the MIT License
//

#import "Game.h"
#import "Hero.h"
#import "HeroContactListener.h"
#import "Box2D.h"
#import "Constants.h"
#import "Box2DHelper.h"

@interface Hero()
- (void) createBox2DBody;
@end

@implementation Hero

@synthesize game = _game;
@synthesize sprite = _sprite;
@synthesize awake = _awake;
@synthesize diving = _diving;

+ (id) heroWithGame:(Game*)game {
	return [[[self alloc] initWithGame:game] autorelease];
}

- (id) initWithGame:(Game*)game {
	
	if ((self = [super init])) {

		self.game = game;
		
#ifndef DRAW_BOX2D_WORLD
		self.sprite = [CCSprite spriteWithFile:@"hero.png"];
		[self addChild:_sprite];
#endif
		_body = NULL;
		_radius = 14.0f;

		_contactListener = new HeroContactListener(self);
		_game.world->SetContactListener(_contactListener);

		[self reset];
	}
	return self;
}

- (void) dealloc {

	self.game = nil;
	
#ifndef DRAW_BOX2D_WORLD
	self.sprite = nil;
#endif

	delete _contactListener;
	[super dealloc];
}

- (void) reset {
	_flying = NO;
	_diving = NO;
	_nPerfectSlides = 0;
	if (_body) {
		_game.world->DestroyBody(_body);
	}
	[self createBox2DBody];
	[self updateNode];
	[self sleep];
}

- (void) createBox2DBody {
	
	b2BodyDef bd;
	bd.type = b2_dynamicBody;
	bd.linearDamping = 0.05f;
	bd.fixedRotation = true;
	
	// start position
	CGPoint p = ccp(0, _game.screenH/2+_radius);
	CCLOG(@"start position = %f, %f", p.x, p.y);

	bd.position.Set(p.x * [Box2DHelper metersPerPoint], p.y * [Box2DHelper metersPerPoint]);
	_body = _game.world->CreateBody(&bd);
	
	b2CircleShape shape;
	shape.m_radius = _radius * [Box2DHelper metersPerPoint];
	
	b2FixtureDef fd;
	fd.shape = &shape;
	fd.density = 1.0f;
	fd.restitution = 0; // bounce
	fd.friction = 0;
	
	_body->CreateFixture(&fd);
}

- (void) sleep {
	_awake = NO;
	_body->SetActive(false);
}

- (void) wake {
	_awake = YES;
	_body->SetActive(true);
	_body->ApplyLinearImpulse(b2Vec2(1,2), _body->GetPosition());
}

- (void) updatePhysics {

	// apply force if diving
	if (_diving) {
		if (!_awake) {
			[self wake];
			_diving = NO;
		} else {
			_body->ApplyForce(b2Vec2(0,-40),_body->GetPosition());
		}
	}
	
	// limit velocity
	const float minVelocityX = 3;
	const float minVelocityY = -40;
	b2Vec2 vel = _body->GetLinearVelocity();
	if (vel.x < minVelocityX) {
		vel.x = minVelocityX;
	}
	if (vel.y < minVelocityY) {
		vel.y = minVelocityY;
	}
	_body->SetLinearVelocity(vel);
}

- (void) updateNode {
	
	CGPoint p;
	p.x = _body->GetPosition().x * [Box2DHelper pointsPerMeter];
	p.y = _body->GetPosition().y * [Box2DHelper pointsPerMeter];
	
	// CCNode position and rotation
	self.position = p;
	b2Vec2 vel = _body->GetLinearVelocity();
	float angle = atan2f(vel.y, vel.x);

#ifdef DRAW_BOX2D_WORLD
	_body->SetTransform(_body->GetPosition(), angle);
#else
	self.rotation = -1 * CC_RADIANS_TO_DEGREES(angle);
#endif
	
	// collision detection
	b2Contact *c = _game.world->GetContactList();
	if (c) {
		if (_flying) {
			[self landed];
		}
	} else {
		if (!_flying) {
			[self tookOff];
		}
	}
	
	// TEMP: sleep if below the screen
	if (p.y < -_radius && _awake) {
		[self sleep];
	}
}

- (void) landed {
//	CCLOG(@"landed");
	_flying = NO;
}

- (void) tookOff {
//	CCLOG(@"tookOff");
	_flying = YES;
	b2Vec2 vel = _body->GetLinearVelocity();
//	CCLOG(@"vel.y = %f",vel.y);
	if (vel.y > kPerfectTakeOffVelocityY) {
//		CCLOG(@"perfect slide");
		_nPerfectSlides++;
		if (_nPerfectSlides > 1) {
			if (_nPerfectSlides == 4) {
				[_game showFrenzy];
			} else {
				[_game showPerfectSlide];
			}
		}
	}
}

- (void) hit {
//	CCLOG(@"hit");
	_nPerfectSlides = 0;
	[_game showHit];
}

- (void) setDiving:(BOOL)diving {
	if (_diving != diving) {
		_diving = diving;
		// TODO: change sprite image here
	}
}

@end
