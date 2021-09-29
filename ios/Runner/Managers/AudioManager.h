//
//  AudioManager.h
//  Runner
//
//  Created by yuanyinhua on 2021/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioManager : NSObject

+ (instancetype)shared;

/// 是否开启后台自动播放无声音乐
@property (nonatomic, assign) BOOL  openBackgroundAudioAutoPlay;

@end

NS_ASSUME_NONNULL_END
