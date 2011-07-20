/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "Box2D.h"

#define kMaxAngleDiff 2.4f // in radians

@class Hero;

class HeroContactListener : public b2ContactListener {
public:
	Hero *_hero;
	
	HeroContactListener(Hero* hero);
	~HeroContactListener();
	
	void BeginContact(b2Contact* contact);
	void EndContact(b2Contact* contact);
	void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
	void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
};