
#ifndef __SYS_CMDS_H__
#define __SYS_CMDS_H__

void D_DrawDebugLines( void );

void KillEntities( const idCmdArgs &args, const idTypeInfo &superClass );

void GiveStuffToPlayer( idPlayer* player, const char* name, const char* value );

// PTP: deploys a fresh protection squad around the player (ptp_squad, mission checkpoints)
int PTP_DeploySquad( idPlayer *player );

#endif /* !__SYS_CMDS_H__ */
