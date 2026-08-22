#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import "Offsets.h"

struct Vector3 { float x, y, z; };
struct Vector2 { float x, y; };

// WorldToScreen Math: 3D coordinates ko 2D iPhone screen par set karne ke liye
bool WorldToScreen(Vector3 WorldPos, Vector2 &ScreenPos, CGSize screenSize) {
    uintptr_t BaseAddress = (uintptr_t)_dyld_get_image_header(0);
    
    // Naye GWorldFunction se camera matrix calculation framework read karna
    uintptr_t CameraMatrixPtr = *(uintptr_t*)(BaseAddress + O_GWorldData);
    if (!CameraMatrixPtr) return false;

    // Matrix array variables (Temporary calculation template)
    float viewMatrix[4][4]; 
    memcpy(&viewMatrix, (void*)(CameraMatrixPtr + 0xAE0), sizeof(viewMatrix)); // Matrix internal structural offset

    float w = viewMatrix[0][3] * WorldPos.x + viewMatrix[1][3] * WorldPos.y + viewMatrix[2][3] * WorldPos.z + viewMatrix[3][3];
    if (w < 0.01f) return false;

    float x = viewMatrix[0][0] * WorldPos.x + viewMatrix[1][0] * WorldPos.y + viewMatrix[2][0] * WorldPos.z + viewMatrix[3][0];
    float y = viewMatrix[0][1] * WorldPos.x + viewMatrix[1][1] * WorldPos.y + viewMatrix[2][1] * WorldPos.z + viewMatrix[3][1];

    ScreenPos.x = (screenSize.width / 2) + (screenSize.width / 2) * x / w;
    ScreenPos.y = (screenSize.height / 2) - (screenSize.height / 2) * y / w;
    return true;
}

// Main Draw function: Har frame par continuous line process chalane ke liye
void ExecuteMyCleanESP(CGContextRef context, CGSize screenSize) {
    uintptr_t BaseAddress = (uintptr_t)_dyld_get_image_header(0);
    
    // Aapka naya GWorld Data address call
    uintptr_t GWorld = *(uintptr_t*)(BaseAddress + O_GWorldData);
    if (!GWorld) return;

    // Decryption bypass engine hook block
    typedef uintptr_t (*DecryptActorList)(uintptr_t);
    DecryptActorList decryptFunc = (DecryptActorList)(BaseAddress + O_ActorDecrypt);

    uintptr_t NetDriver = *(uintptr_t*)(GWorld + 0x38); // Game internal NetDriver pointer
    if (!NetDriver) return;

    uintptr_t ServerConnection = *(uintptr_t*)(NetDriver + 0x78);
    if (!ServerConnection) return;

    // ActorArray aur ActorCount data extraction
    uintptr_t EncryptedActorArray = *(uintptr_t*)(ServerConnection + O_ActorList);
    int ActorCount = *(int*)(ServerConnection + O_ActorCount);

    // Agar actor encryption function available hai toh use decrypt karein
    uintptr_t ActorArray = decryptFunc ? decryptFunc(EncryptedActorArray) : EncryptedActorArray;
    if (!ActorArray) return;

    // Loop: Saare dushmanon par line process lagana
    for (int i = 0; i < ActorCount; i++) {
        uintptr_t CurrentActor = *(uintptr_t*)(ActorArray + (i * 8));
        if (!CurrentActor) continue;

        // Player position structural read
        uintptr_t RootComp = *(uintptr_t*)(CurrentActor + O_RootComponent);
        if (!RootComp) continue;
        
        Vector3 EnemyPos = *(Vector3*)(RootComp + O_Position);
        Vector2 ScreenPos;

        // Target calculation update check
        if (WorldToScreen(EnemyPos, ScreenPos, screenSize)) {
            // Screen par clean RED LINE draw karna
            CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0); // Pure Red Color
            CGContextSetLineWidth(context, 1.5); // Ek dum patli clean line
            
            // Line kahan se shuru hogi: Screen ke bilkul neeche center se (Crosshair area target)
            CGContextMoveToPoint(context, screenSize.width / 2, screenSize.height); 
            // Line kahan khatam hogi: Enemy ke pairon par
            CGContextAddLineToPoint(context, ScreenPos.x, ScreenPos.y); 
            CGContextStrokePath(context);
        }
    }
}
