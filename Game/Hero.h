/*
 *  Tiny Wings remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"

@interface Hero : CCSprite {
    b2World *world;
    b2Body *body;
    float radius;
	BOOL awake;
}
@property (readonly) BOOL awake;

+ (id) heroWithWorld:(b2World*)w;
- (id) initWithWorld:(b2World*)w;

- (void) sleep;
- (void) wake;
- (void) dive;
- (void) limitVelocity;
- (void) updateNodePosition;

@end
