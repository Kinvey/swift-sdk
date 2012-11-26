//
//  KCSBuilders.h
//  KinveyKit
//
//  Created by Michael Katz on 8/23/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol KCSDataTypeBuilder <NSObject>
+ (id) JSONCompatabileValueForObject:(id)object;
+ (id) objectForJSONObject:(id)object;
@end

@interface KCSAttributedStringBuilder : NSObject <KCSDataTypeBuilder>
@end
@interface KCSMAttributedStringBuilder : KCSAttributedStringBuilder
@end


@interface KCSDateBuilder : NSObject <KCSDataTypeBuilder>
@end


@interface KCSSetBuilder : NSObject <KCSDataTypeBuilder>
@end
@interface KCSMSetBuilder : KCSSetBuilder
@end


@interface KCSOrderedSetBuilder : NSObject <KCSDataTypeBuilder>
@end
@interface KCSMOrderedSetBuilder : KCSOrderedSetBuilder
@end


@interface KCSCLLocationBuilder : NSObject <KCSDataTypeBuilder>
@end

@interface KCSBuilders : NSObject

@end
