/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "GameLayer.h"
#import "Hero.h"
#import "HeroContactListener.h"
#import "Box2D.h"

@interface Hero()
- (void) createBox2DBody;
@end

@implementation Hero

@synthesize game = _game;
@synthesize sprite = _sprite;
@synthesize awake = _awake;
@synthesize diving = _diving;

+ (id) heroWithGame:(GameLayer*)game {
	return [[[self alloc] initWithGame:game] autorelease];
}

- (id) initWithGame:(GameLayer*)game {
	
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

- (void) createBox2DBody {

	CGPoint startPosition = ccp(0, _game.screenH/2+_radius);
	
	b2BodyDef bd;
	bd.type = b2_dynamicBody;
	bd.linearDamping = 0.05f;
	bd.fixedRotation = true;
	bd.position.Set(startPosition.x/PTM_RATIO, startPosition.y/PTM_RATIO);
	_body = _game.world->CreateBody(&bd);
	
	b2CircleShape shape;
	shape.m_radius = _radius/PTM_RATIO;
	
	b2FixtureDef fd;
	fd.shape = &shape;
	fd.density = 1.0f;
	fd.restitution = 0; // bounce
	fd.friction = 0;
	
	_body->CreateFixture(&fd);
}

- (void) reset {
    [self stopFrenzy];
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
	float x = _body->GetPosition().x*PTM_RATIO;
	float y = _body->GetPosition().y*PTM_RATIO;

	// CCNode position and rotation
	self.position = ccp(x, y);
	b2Vec2 vel = _body->GetLinearVelocity();
	float angle = atan2f(vel.y, vel.x);

#ifdef DRAW_BOX2D_WORLD
	_body->SetTransform(_body->GetPosition(), angle);
#else
	self.rotation = -1 * CC_RADIANS_TO_DEGREES(angle);
    if( _frenzyParticle )
        _frenzyParticle.rotation = 1 * CC_RADIANS_TO_DEGREES(angle);
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
	if (y < -_radius && _awake) {
		[self sleep];
	}
}

- (void) landed {
//	NSLog(@"landed");
	_flying = NO;
}

- (void) tookOff {
//	NSLog(@"tookOff");
	_flying = YES;
	b2Vec2 vel = _body->GetLinearVelocity();
//	NSLog(@"vel.y = %f",vel.y);
	if (vel.y > kPerfectTakeOffVelocityY) {
//		NSLog(@"perfect slide");
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
//	NSLog(@"hit");
	_nPerfectSlides = 0;
	[_game showHit];
}

- (void) setDiving:(BOOL)diving {
	if (_diving != diving) {
		_diving = diving;
		// TODO: change sprite image here
	}
}

- (void) addFrenzyTrail {
    _frenzyParticle=[[[CCParticleSystemQuad alloc] initWithTotalParticles:400] autorelease];
    
    CCTexture2D *texture=[[CCTextureCache sharedTextureCache] addImage:@"star.png"];
    _frenzyParticle.texture=texture;
    _frenzyParticle.emissionRate=20;
    _frenzyParticle.angle=180.0;
    _frenzyParticle.angleVar=15.0;
    ccBlendFunc blendFunc={GL_SRC_ALPHA,GL_SRC_ALPHA_SATURATE};//GL_ONE};
    _frenzyParticle.blendFunc=blendFunc;
    _frenzyParticle.duration=-1.00;
    _frenzyParticle.emitterMode=kCCParticleModeGravity;
    ccColor4F startColor={1.00,0.13,0.12,1.00};
    _frenzyParticle.startColor=startColor;
    ccColor4F startColorVar={0.1,0.1,0.1,0};
    _frenzyParticle.startColorVar=startColorVar;
    ccColor4F endColor={0,0,0.96,1.00};
    _frenzyParticle.endColor=endColor;
    ccColor4F endColorVar={0.0,0.0,0.0,0};
    _frenzyParticle.endColorVar=endColorVar;
    _frenzyParticle.startSize=5.0;
    _frenzyParticle.startSizeVar=1.00;
    _frenzyParticle.endSize=10.00;
    _frenzyParticle.endSizeVar=5.00;
    _frenzyParticle.gravity=ccp(0.00,-5.00);
    _frenzyParticle.radialAccel=0.00;
    _frenzyParticle.radialAccelVar=0.00;
    _frenzyParticle.speed=200;
    _frenzyParticle.speedVar=20;
    _frenzyParticle.tangentialAccel= 0;
    _frenzyParticle.tangentialAccelVar= 0;
    _frenzyParticle.totalParticles=200;
    _frenzyParticle.life=1.0;
    _frenzyParticle.lifeVar=1.00;
    _frenzyParticle.startSpin=30.00;
    _frenzyParticle.startSpinVar=20.00;
    _frenzyParticle.endSpin=0.00;
    _frenzyParticle.endSpinVar=60.00;
    _frenzyParticle.position=ccp(-20,0);
    _frenzyParticle.posVar=ccp(-15,3.00);
    
    [self addChild:_frenzyParticle];
}

- (void) addFrenzyExplosion {
    CCParticleSystem *explosion=[[[CCParticleSystemQuad alloc] initWithTotalParticles:100] autorelease];

    CCTexture2D *texture=[[CCTextureCache sharedTextureCache] addImage:@"star.png"];
    explosion.texture=texture;
    explosion.emissionRate=-1;
    explosion.angle=90.0;
    explosion.angleVar=360.0;
    ccBlendFunc blendFunc={GL_ONE,GL_ONE_MINUS_SRC_ALPHA};
    explosion.blendFunc=blendFunc;
    explosion.duration=0.01;
    explosion.emitterMode=kCCParticleModeGravity;
    ccColor4F startColor={0.00,0.30,0.86,1.00};
    explosion.startColor=startColor;
    ccColor4F startColorVar={0.00,0.00,0.00,0.00};
    explosion.startColorVar=startColorVar;
    ccColor4F endColor={1.00,0.00,0.08,1.00};
    explosion.endColor=endColor;
    ccColor4F endColorVar={0.00,0.00,0.00,0.00};
    explosion.endColorVar=endColorVar;
    explosion.startSize=7.00;
    explosion.startSizeVar=0.00;
    explosion.endSize=10.00;
    explosion.endSizeVar=0.00;
    explosion.gravity=ccp(0,-10);
    explosion.radialAccel=0.00;
    explosion.radialAccelVar=10.00;
    explosion.speed=250;
    explosion.speedVar= 0;
    explosion.tangentialAccel= 0;
    explosion.tangentialAccelVar=10;
    explosion.totalParticles=100;
    explosion.life=0;
    explosion.lifeVar=1;
    explosion.startSpin=0.00;
    explosion.startSpinVar=0.00;
    explosion.endSpin=0.00;
    explosion.endSpinVar=0.00;
    explosion.position=ccp(0,0);
    explosion.posVar=ccp(0.00,0.00);
    
    [self addChild:explosion];
}
- (void) startFrenzy {
    _frenzy = YES;
    [self addFrenzyExplosion];
    [self addFrenzyTrail];
}

- (void) stopFrenzy {
    _frenzy = NO;
    if( !_frenzyParticle )
        return;
        
    [_frenzyParticle stopSystem];
    [self removeChild:_frenzyParticle cleanup:_frenzy];
}

@end
