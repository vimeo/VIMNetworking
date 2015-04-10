//
//  UploadState.h
//  Hermes
//
//  Created by Alfred Hanssen on 2/28/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//

typedef NS_ENUM(NSInteger, VIMUploadState)
{
    VIMUploadState_None,
    VIMUploadState_Enqueued,
    VIMUploadState_CreatingRecord,
    VIMUploadState_UploadingFile,
    VIMUploadState_ActivatingRecord,
    VIMUploadState_AddingMetadata,
    VIMUploadState_Succeeded,
    VIMUploadState_Failed
};
