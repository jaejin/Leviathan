//
//  NSData+BMOEDN.m
//  edn-objc
//
//  Created by Ben Mosher on 9/2/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import "NSData+BMOEDN.h"
#import "BMOEDNSerialization.h"

@implementation NSData (BMOEDN)

-(id)ednObject {
    return [BMOEDNSerialization ednObjectWithData:self options:BMOEDNReadingMultipleObjects error:NULL];
}

@end
