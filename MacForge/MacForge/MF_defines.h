//
//  MF_extra.h
//  Dark Boot
//
//  Created by Wolfgang Baird on 5/8/20.
//

#if DEBUG == 0 // DEBUG is not defined or defined to be 0
static NSString *MF_REPO_URL = @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo";
#else
static NSString *MF_REPO_URL = @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo";
//static NSString *MF_REPO_URL = @"file:///Users/w0lf/Documents/GitHub/MacForgeRepo/repo";
#endif
