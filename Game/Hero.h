/*
 *	Tiny Wings remake
 *	http://github.com/haqu/tiny-wings
 *
 *	Created by Sergey Tikhonov http://haqu.net
 *	Released under the MIT License
 *
 */

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"

@interface Hero : CCNode {
    b2World *world;
	b2Body *body;
	float radius;
}

+ (id) heroWithWorld:(b2World*)w;
- (id) initWithWorld:(b2World*)w;

- (void) updatePosition;
- (void) walk;
- (void) run;

@end
