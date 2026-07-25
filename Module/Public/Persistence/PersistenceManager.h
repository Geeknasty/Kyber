// Copyright Armchair Developers / Sean Kahler. Licensed under GPLv3.

#pragma once

#include <Network/SocketManager.h>
#include <SDK/SDK.h>
#include <SDK/TypeInfo.h>
#include <Core/Settings.h>
#include <Persistence/PersistenceDatabase.h>
#include <Core/ThreadExecutor.h>

#include <Windows.h>
#include <string>

namespace Kyber
{
PlayerStatsMap GetAllPlayerStats(ServerPlayer* player);
class PersistenceManager
{
public:
    PersistenceManager();

    void Initialize();

    void LoadPlayerStats(void* persistenceInst, ServerPlayer* player);

    void SavePlayerStats(ServerPlayer* player);
    void SavePlayerStats(ServerPlayer* player, const PlayerStatsMap& stats);

private:
    PersistenceDatabase* m_database;
};
} // namespace Kyber