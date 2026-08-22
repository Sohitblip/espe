#ifndef OFFSETS_H
#define OFFSETS_H
#include <stdint.h>

// Aapke diye gaye naye iOS offsets
uintptr_t O_GUObjectArray = 0x1095B72D0;
uintptr_t O_GNameFunction = 0x10426CD48;
uintptr_t O_GNameData     = 0x109386C70;
uintptr_t O_GWorldData    = 0x1097CFA40;
uintptr_t O_GWorldFunction = 0x1020AEAD4;
uintptr_t O_LineOfSight   = 0x10548DB38;
uintptr_t O_ActorDecrypt  = 0x1055EB9F8;
uintptr_t O_ProcessEvent  = 0x10440FB44;

// Game ke internal loops ke liye basic structures (Common engine values)
uintptr_t O_ActorList     = 0x90;   // NetDriver -> ClientConnection -> ActorList
uintptr_t O_ActorCount    = 0x98;
uintptr_t O_RootComponent = 0x150;  // Actor -> RootComponent
uintptr_t O_Position      = 0x1A0;  // RootComponent -> Position (X,Y,Z)

#endif
