#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import "Offsets.h"

// Game engine coordination frameworks structures definition
struct Vector3 { 
    float x, y, z; 
};
struct Vector2 { 
    float x, y; 
};

// Main function prototype definition declaration
bool WorldToScreen(Vector3 WorldPos, Vector2 &ScreenPos, CGSize screenSize);
void ExecuteMyCleanESP(CGContextRef context, CGSize screenSize);

bool WorldToScreen(Vector3 WorldPos, Vector2 &ScreenPos, CGSize screenSize) {
    uintptr_t BaseAddress = (uintptr_t)_dyld_get_image_header(0);
    uintptr_t CameraMatrixPtr = *(uintptr_t*)(BaseAddress + O_GWorldData);
    if (!CameraMatrixPtr) return false;

    float viewMatrix[16]; 
    memcpy(&viewMatrix, (void*)(CameraMatrixPtr + 0xAE0), sizeof(viewMatrix));

    float w = viewMatrix[3] * WorldPos.x + viewMatrix[7] * WorldPos.y + viewMatrix[11] * WorldPos.z + viewMatrix[15];
    if (w < 0.01f) return false;

    float x = viewMatrix[0] * WorldPos.x + viewMatrix[4] * WorldPos.y + viewMatrix[8] * WorldPos.z + viewMatrix[12];
    float y = viewMatrix[1] * WorldPos.x + viewMatrix[5] * WorldPos.y + viewMatrix[9] * WorldPos.z + viewMatrix[13];

    ScreenPos.x = (screenSize.width / 2) + (screenSize.width / 2) * x / w;
    ScreenPos.y = (screenSize.height / 2) - (screenSize.height / 2) * y / w;
    return true;
}

void ExecuteMyCleanESP(CGContextRef context, CGSize screenSize) {
    uintptr_t BaseAddress = (uintptr_t)_dyld_get_image_header(0);
    uintptr_t GWorld = *(uintptr_t*)(BaseAddress + O_GWorldData);
    if (!GWorld) return;

    typedef uintptr_t (*DecryptActorList)(uintptr_t);
    DecryptActorList decryptFunc = (DecryptActorList)(BaseAddress + O_ActorDecrypt);

    uintptr_t NetDriver = *(uintptr_t*)(GWorld + 0x38); 
    if (!NetDriver) return;

    uintptr_t ServerConnection = *(uintptr_t*)(NetDriver + 0x78);
    if (!ServerConnection) return;

    uintptr_t EncryptedActorArray = *(uintptr_t*)(ServerConnection + O_ActorList);
    int ActorCount = *(int*)(ServerConnection + O_ActorCount);

    uintptr_t ActorArray = decryptFunc ? decryptFunc(EncryptedActorArray) : EncryptedActorArray;
    if (!ActorArray) return;

    for (int i = 0; i < ActorCount; i++) {
        uintptr_t CurrentActor = *(uintptr_t*)(ActorArray + (i * 8));
        if (!CurrentActor) continue;

        uintptr_t RootComp = *(uintptr_t*)(CurrentActor + O_RootComponent);
        if (!RootComp) continue;
        
        Vector3 EnemyPos = *(Vector3*)(RootComp + O_Position);
        Vector2 ScreenPos;

        if (WorldToScreen(EnemyPos, ScreenPos, screenSize)) {
            CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0); 
            CGContextSetLineWidth(context, 1.5); 
            CGContextMoveToPoint(context, screenSize.width / 2, screenSize.height); 
            CGContextAddLineToPoint(context, ScreenPos.x, ScreenPos.y); 
            CGContextStrokePath(context);
        }
    }
}
