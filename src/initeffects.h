/***************************************************************************
                          initeffects.h  -  description
                             -------------------
    begin                :  Jul 2006
    copyright            : (C) 2006 by Jean-Baptiste Mardelle
    email                : jb@ader.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef InitEffects_H
#define InitEffects_H

#include <klocale.h>

#include <mlt++/Mlt.h>

#include "kdenlivesettings.h"
#include "effectslist.h"

/**Init the MLT effects
  *@author Jean-Baptiste Mardelle
  */

class initEffects
{
    public:
        initEffects();
	~initEffects();

	static Mlt::Repository *parseEffectFiles(EffectsList *audioEffectList, EffectsList *videoEffectList);
	static void parseEffectFile(EffectsList *audioEffectList, EffectsList *videoEffectList, QString name, QStringList filtersList, QStringList producersList);
	static char* ladspaEffectString(int ladspaId, QStringList params);
	static void ladspaEffectFile(const QString & fname, int ladspaId, QStringList params);

	static char* ladspaPitchEffectString(QStringList params);
	static char* ladspaReverbEffectString(QStringList params);
	static char* ladspaRoomReverbEffectString(QStringList params);
	static char* ladspaEqualizerEffectString(QStringList params);
	static char* ladspaDeclipEffectString(QStringList);
	static char* ladspaVinylEffectString(QStringList params);
	static char* ladspaLimiterEffectString(QStringList params);
	static char* ladspaPitchShifterEffectString(QStringList params);
	static char* ladspaPhaserEffectString(QStringList params);
	static char* ladspaRateScalerEffectString(QStringList params);
};

    
#endif
