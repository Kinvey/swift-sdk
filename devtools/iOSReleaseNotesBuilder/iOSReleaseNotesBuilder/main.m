//
//  main.m
//  iOSReleaseNotesBuilder
//
//  Created by Michael Katz on 7/12/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kApiXmlFileName @"api%@.xml"
#define kDiffReportFileName @"diff.html" //todo put ver # in
//todo /Users/mike/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiOS6.0.iOSLibrary.docset/Contents/Resources/Documents/releasenotes/General/iOS60APIDiffs/index.html
#define kApiDir @"../DocTemplates/apis/"

#define kNodeClassName @"class"
#define KNodeMethodName @"sub"

#define kAttributeName @"name"
#define kAttributeDiffType @"diffType"
#define kAttributeAddedValue @"added"
#define kAttributeSameValue @"same"
#define kAttributeRemovedValue @"removed"

void dispHelp()
{
    NSLog(@"iOSReleaseNotesBuilder dirToKinveyKitDocOutput version");
}

NSURL* docDirForBaseDir(NSString* baseDir) 
{
    NSURL* dirUrl = [[[NSURL fileURLWithPath:baseDir] URLByStandardizingPath] URLByResolvingSymlinksInPath];
    dirUrl = [dirUrl URLByAppendingPathComponent:@"doc/output/docset/Contents/Resources"];
    return dirUrl;
}

NSString* evalXpath(NSString* expr, NSXMLNode* node) 
{
    NSError* error = nil;
    NSArray* matches = [node nodesForXPath:expr error:&error];
    NSXMLElement* ret = nil;
    if ([matches count] > 0) {
        ret = [matches objectAtIndex:0];
    }
    return [ret stringValue];
}

NSXMLElement* findClassNode(NSXMLElement* root, NSString* className) {
    NSString* xpath = [NSString stringWithFormat:@"//%@[@%@='%@']",kNodeClassName, kAttributeName, className];
    NSError* error = nil;
    NSArray* matchClasses = [root nodesForXPath:xpath error:&error];
    NSXMLElement* classNode = nil;
    if ([matchClasses count] > 0) {
        classNode = [matchClasses objectAtIndex:0];
    }
    return classNode;
}

NSXMLElement* findMethodNode(NSXMLElement* classNode, NSString* methName) {
    NSString* xpath = [NSString stringWithFormat:@"//%@[@%@='%@']",KNodeMethodName, kAttributeName, methName];
    NSError* error = nil;
    NSArray* matchMethods = [classNode nodesForXPath:xpath error:&error];
    NSXMLElement* methNode = nil;
    if ([matchMethods count] > 0) {
        methNode = [matchMethods objectAtIndex:0];
    }
    return methNode;
}

BOOL diff(NSURL* oldApiFile, NSURL* newApiFile, NSString* kinveyKitDir) 
{    
    NSError* error = nil;
    NSXMLDocument* oldXmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:oldApiFile options:0 error:&error];
    NSXMLDocument* newXmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:newApiFile options:NSXMLDocumentTidyXML error:&error];
    
    NSXMLElement* oldDocRoot = [oldXmlDoc rootElement];
    NSXMLElement* newDocRoot = [newXmlDoc rootElement];
    
    NSXMLElement* diffDocRoot = [NSXMLNode elementWithName:@"APIDiff"];
    NSXMLDocument* diffDocument = [NSXMLDocument documentWithRootElement:diffDocRoot];

    [diffDocRoot addAttribute:[NSXMLNode attributeWithName:@"oldversion" stringValue:evalXpath(@"/API/@version", oldDocRoot)]];
    NSString* newApiVersion = evalXpath(@"/API/@version", newDocRoot);
    [diffDocRoot addAttribute:[NSXMLNode attributeWithName:@"newversion" stringValue:newApiVersion]];
    
    NSArray* classesInNewDoc = [newDocRoot nodesForXPath:[NSString stringWithFormat:@"//%@", kNodeClassName] error:&error];
    
    for (NSXMLElement* el in classesInNewDoc) {
        NSString* className = [[el attributeForName:kAttributeName] stringValue];
        NSXMLElement* oldClass = findClassNode(oldDocRoot, className);
        if (oldClass == nil) {
            //Added a new Class:
            [el detach];
            [diffDocRoot addChild:el];
            [el addAttribute:[NSXMLNode attributeWithName:kAttributeDiffType stringValue:kAttributeAddedValue]];
            for (NSXMLElement* method in [el children]) {
                [method addAttribute:[NSXMLNode attributeWithName:kAttributeDiffType stringValue:kAttributeAddedValue]];
            }
        } else {
            //Class Matches - check children
            for (NSXMLElement* method in [el children]) {
                NSString* methName = [[method attributeForName:kAttributeName] stringValue];
                NSXMLElement* oldMeth = findMethodNode(oldClass, methName);
                if (oldMeth == nil) {
                    //Added a new Method:
                    [el addAttribute:[NSXMLNode attributeWithName:kAttributeDiffType stringValue:kAttributeSameValue]];
                    [el detach];
                    [diffDocRoot addChild:el];
                    [method addAttribute:[NSXMLNode attributeWithName:kAttributeDiffType stringValue:kAttributeAddedValue]];
                } else {
                    //same method
                    //TODO: remove method
                    [method detach];
                    [oldMeth detach];
                }
            }
            //TODO: check for deleted methods - the ones still left in el
            if ([[oldClass children] count] > 0) {
                //There are deleted methods
                for (NSXMLElement* deletedMeth in [oldClass children] ) {
                    [el addAttribute:[NSXMLNode attributeWithName:kAttributeDiffType stringValue:kAttributeSameValue]];
                    [el detach];
                    [diffDocRoot addChild:el];
                    [deletedMeth addAttribute:[NSXMLNode attributeWithName:kAttributeDiffType stringValue:kAttributeRemovedValue]];
                    [deletedMeth detach];
                    [el addChild:deletedMeth];
                }
            }
            
            [oldClass detach];
//            NSUInteger i = [[oldDocRoot children] indexOfObject:oldClass];
//            [oldDocRoot removeChildAtIndex:i];
        }
    }
    //TODO: other than added
    NSString* xstl = @"<?xml version=\"1.0\"?><xsl:stylesheet version=\"1.0\" \
                                                              xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"> \
       <xsl:output method=\"text\"/> \
       <xsl:template match=\"/\"> \
            <div class='diffReport'> \
            <h1>KinveyKit <xsl:value-of select='/APIDiff/@oldversion'/> to KinveyKit <xsl:value-of select='/APIDiff/@newversion'/> API Differences</h1> \
            <h2>KinveyKit</h2> \
              <xsl:for-each select=\"/APIDiff/class\"> \
                <div class='diffReport headerFile'> \
                <div class='diffReport headerName'><xsl:choose><xsl:when test='@diffType=\"added\"'><span class=\"diffReport added\"><xsl:value-of select='@name'/>.h</span></xsl:when><xsl:otherwise><xsl:value-of select='@name'/>.h</xsl:otherwise></xsl:choose></div> \
                </div> \
                <xsl:for-each select='sub'> \
                    <div><xsl:attribute name='class'><xsl:value-of select='@diffType'/></xsl:attribute> \
                    <div class=\"diffReport symbolName\"><span class=\"diffReport diffStatus added\"><xsl:choose><xsl:when test='@diffType=\"added\"'>Added</xsl:when><xsl:otherwise>Removed</xsl:otherwise></xsl:choose></span> <!--a --><xsl:choose><xsl:when test='@type=\"clm\"'> + </xsl:when><xsl:otherwise> - </xsl:otherwise></xsl:choose>[<xsl:value-of select='../@name'/><xsl:text> </xsl:text><xsl:value-of select='@name'/>]<!--/a--> </div> \
                    </div> \
                </xsl:for-each> \
              </xsl:for-each> \
            </div> \
        </xsl:template> \
    </xsl:stylesheet>";
   
    
    NSXMLDocument* html = [diffDocument objectByApplyingXSLTString:xstl arguments:nil error:&error];
    [html setDocumentContentKind:NSXMLDocumentHTMLKind];
    //TODO: check for deleted clasess - the ones still left in OldDocRoot
    NSString* newApiVStr = [newApiVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSURL* newdir = [[NSURL fileURLWithPath:kinveyKitDir] URLByAppendingPathComponent:[NSString stringWithFormat:@"Documents/releasenotes/General/KinveyKit%@APIDiffs/KinveyKit%@APIDiffs-template.html",newApiVStr, newApiVStr]];
    [[NSFileManager defaultManager] createDirectoryAtURL:[newdir URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];

    NSString * htmlStr = [html XMLStringWithOptions:0];
    //need an extra space for appledoc's markdown processing
    BOOL wrote = [[@" " stringByAppendingString:htmlStr] writeToFile:[newdir path] atomically:YES];

    return wrote;
}

void diffInDir(NSString* kinveyKitDir)
{
    NSError* error = nil;
    NSString* path = [kinveyKitDir stringByAppendingString:kApiDir];
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    files = [files sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString*) obj1 compare:obj2 options:NSNumericSearch];
    }];
    NSMutableArray* apiFiles = [NSMutableArray arrayWithCapacity:10];
    for (NSString* file in files) {
        //TODO: remove non apiA.B.C.xml files
        NSLog(@"%@",file);
        if ([file hasPrefix:@"api"] && [file hasSuffix:@".xml"]) {
            [apiFiles addObject:file];
        }
    }
    NSURL* kkDir = [NSURL fileURLWithPath:path];
    for (int i = 1; i < apiFiles.count; i++) {
        NSURL* oldApiFile = [kkDir URLByAppendingPathComponent:[apiFiles objectAtIndex:i-1]];
        NSURL* newApiFile = [kkDir URLByAppendingPathComponent:[apiFiles objectAtIndex:i]];   
        diff(oldApiFile, newApiFile, kinveyKitDir);
    }
}

/*output format
 <div class='headerFile'>
 <div class='headerName' title='/System/Library/Frameworks/AssetsLibrary.framework/Headers/ALAssetRepresentation.h'>ALAssetRepresentation.h</div>
 <div class='added'>
 <div class="symbolName" title="//apple_ref/occ/instm/ALAssetRepresentation/dimensions"><span class="diffStatus">Added</span> <!--a -->-[ALAssetRepresentation dimensions]<!--/a--> </div>
 </div>
 */

void buildAPIXML(NSString* kinveyKitDir, NSString* version) {
    
    NSURL* tokensDirUrl = docDirForBaseDir(kinveyKitDir);
    NSEnumerator* tokensDirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:tokensDirUrl includingPropertiesForKeys:nil options:0 errorHandler:nil];

    NSXMLElement* apiDocRoot = [NSXMLNode elementWithName:@"API"];
    [apiDocRoot addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:version]];
    NSXMLDocument* apiDocument = [NSXMLDocument documentWithRootElement:apiDocRoot];
    [apiDocument setDocumentContentKind:NSXMLDocumentXMLKind];
    [apiDocument setCharacterEncoding:@"UTF-8"];

    for (NSURL * file in tokensDirEnumerator) {
        NSString* filename = [file lastPathComponent];
        if ([filename hasSuffix:@".xml"] && [filename hasPrefix:@"Tokens"]) {
            NSXMLDocument* xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:file options:NSXMLDocumentTidyXML error:nil];
            NSArray* tokens = [[xmlDoc rootElement] nodesForXPath:@"//TokenIdentifier" error:nil];
            for (NSXMLNode* token in tokens) {
                NSString* tokenName = [token stringValue];
                NSURL* appleRefUrl = [NSURL URLWithString:tokenName];
                NSArray* components = [appleRefUrl pathComponents];
                NSString* type = [components objectAtIndex:2];
                if ([[NSSet setWithObjects:@"cl",@"cat",@"intf", nil] containsObject:type]) {
                    //class
                    NSString* class = [components objectAtIndex:3];
                    if (!findClassNode(apiDocRoot, class)) {
                        NSXMLNode* attr = [NSXMLNode attributeWithName:@"name" stringValue:class];
                        NSXMLNode* typeNode = [NSXMLNode attributeWithName:@"type" stringValue:type];
                        NSXMLElement* node = [NSXMLElement elementWithName:@"class" children:nil attributes:[NSArray arrayWithObjects:attr,typeNode, nil]];
                        [apiDocRoot addChild:node];
                    }
                } else if ([[NSSet setWithObjects:@"instm",@"clm",@"intfcm",@"intfm",@"intfp",@"isntp", nil] containsObject:type]) {
                    //method or property
                    NSString* class = [components objectAtIndex:3];
                    NSString* methName = [components objectAtIndex:4];
                    
                    //TODO: could be out of order
                    NSXMLElement* classNode = findClassNode(apiDocRoot, class);
                    if (classNode == nil) {
                        NSXMLNode* attr = [NSXMLNode attributeWithName:kAttributeName stringValue:class];
                        NSXMLNode* typeNode = [NSXMLNode attributeWithName:@"type" stringValue:type];
                        classNode = [NSXMLElement elementWithName:kNodeClassName children:nil attributes:[NSArray arrayWithObjects:attr,typeNode, nil]];
                        [apiDocRoot addChild:classNode];
                    }
                    
                    
                    
                    NSXMLNode* attr = [NSXMLNode attributeWithName:kAttributeName stringValue:methName];
                    NSXMLNode* typeNode = [NSXMLNode attributeWithName:@"type" stringValue:type];
                    NSXMLElement* node = [NSXMLElement elementWithName:KNodeMethodName children:nil attributes:[NSArray arrayWithObjects:attr, typeNode, nil]];
                    [classNode addChild:node];
                }
            }
        }
    }
    NSLog(@"The API: %@", apiDocRoot);
    NSURL* outurl = [[[NSURL fileURLWithPath:kinveyKitDir] URLByStandardizingPath] URLByResolvingSymlinksInPath];
    outurl = [outurl URLByAppendingPathComponent:kApiDir];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:outurl withIntermediateDirectories:YES attributes:0 error:nil];
    
    outurl = [outurl URLByAppendingPathComponent:[NSString stringWithFormat:kApiXmlFileName, version]];
    BOOL wrote = [[apiDocument XMLDataWithOptions:NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration] writeToFile:[outurl path] atomically:YES];
    assert(wrote);
}

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        if (argc < 2) {
            @throw [NSException exceptionWithName:@"TooFewArgumentsException" reason:@"Need more input. Try with help" userInfo:nil];
        }
        
        const char* commandChar = argv[1];
        NSString* command = [NSString stringWithUTF8String:commandChar];
        if ([command isEqualToString:@"buildapi"]) {
            const char* tokensDirChar = argv[2];
            NSString* tokensDir = [NSString stringWithUTF8String:tokensDirChar];
            
            NSString* version = @"";
            if (argc > 2) {
                const char* versionChar = argv[3];
                version = [NSString stringWithUTF8String:versionChar];
            } else {
                version = @"unknown";
            }
            buildAPIXML(tokensDir, version);
        } else if ([command isEqualToString:@"help"]) {
            dispHelp();
        } else if ([command isEqualToString:@"diff"]) {
            const char* kinveyDirChar = argv[2];
            NSString* kinveyKitDir = [NSString stringWithUTF8String:kinveyDirChar];
            diffInDir(kinveyKitDir);
        }
        
    }
    return 0;
}
/*
 cat
 Category name (Objective-C only).
 cl
 Class name.
 Note: In Perl, this is used for the names of packages, and thus the names may contain a double colon between parts of package names. For example:
 //apple_ref/perl/cl/HeaderDoc::APIOwner
 clconst
 Constant values defined inside a class. For example:
 //apple_ref/java/clconst/ClassName/kConstantName
 clm
 Class (or static [in java or c++]) method.
 Note: The formats for method names are described in “Objective-C (occ) Method Name Format” and “C++/Java (cpp/java) Method Name Format.”
 data
 Instance data. For example:
 //apple_ref/cpp/data/MyClass/MyVariable
 intf
 Interface or protocol name.
 intfcm
 Class method defined in a protocol
 Note: The formats for method names are described in “Objective-C (occ) Method Name Format” and “C++/Java (cpp/java) Method Name Format.”
 intfm
 Method defined in an interface (or protocol).
 Note: The formats for method names are described in “Objective-C (occ) Method Name Format” and “C++/Java (cpp/java) Method Name Format.”
 intfp
 Property defined in an interface (or protocol)
 //apple_ref/occ/intfp/ClassName/PropertyName
 instm
 Instance method.
 Note: The formats for method names are described in “Objective-C (occ) Method Name Format” and “C++/Java (cpp/java) Method Name Format.”
 instp
 Instance property. For example:*/


