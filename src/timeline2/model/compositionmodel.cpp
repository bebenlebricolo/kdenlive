/***************************************************************************
 *   Copyright (C) 2017 by Jean-Baptiste Mardelle                                  *
 *   This file is part of Kdenlive. See www.kdenlive.org.                  *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) version 3 or any later version accepted by the       *
 *   membership of KDE e.V. (or its successor approved  by the membership  *
 *   of KDE e.V.), which shall act as a proxy defined in Section 14 of     *
 *   version 3 of the license.                                             *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ***************************************************************************/
#include "compositionmodel.hpp"
#include "timelinemodel.hpp"
#include "trackmodel.hpp"
#include "undohelper.hpp"
#include <mlt++/MltTransition.h>
#include <QDebug>
#include "transitions/transitionsrepository.hpp"


CompositionModel::CompositionModel(std::weak_ptr<TimelineModel> parent, Mlt::Transition* transition, int id, const QDomElement &transitionXml, const QString &transitionId) :
    AssetParameterModel(transition, transitionXml, transitionId)
    , MoveableItem<Mlt::Transition>(parent, id)
{
}

int CompositionModel::construct(std::weak_ptr<TimelineModel> parent, const QString &transitionId, int id)
{
    auto xml = TransitionsRepository::get()->getXml(transitionId);
    Mlt::Transition *transition = TransitionsRepository::get()->getTransition(transitionId);
    std::shared_ptr<CompositionModel> composition(new CompositionModel(parent, transition, id, xml, transitionId));
    id = composition->m_id;
    if (auto ptr = parent.lock()) {
        ptr->registerComposition(composition);
    } else {
        qDebug() << "Error : construction of composition failed because parent timeline is not available anymore";
        Q_ASSERT(false);
    }

    return id;
}

bool CompositionModel::requestResize(int size, bool right, Fun& undo, Fun& redo)
{
    if (size <= 0 || size > service()->get_length()) {
        return false;
    }
    int delta = service()->get_length() - size;
    int in = service()->get_in();
    int out = service()->get_out();
    int old_in = in, old_out = out;
    //check if there is enough space on the chosen side
    if ((!right && in + delta < 0) || (right &&  out - delta >= service()->get_length())) {
        return false;
    }
    if (right) {
        out -= delta;
    } else {
        in += delta;
    }

    std::function<bool (void)> track_operation = [](){return true;};
    std::function<bool (void)> track_reverse = [](){return true;};
    /*if (m_currentTrackId != -1) {
        if (auto ptr = m_parent.lock()) {
            track_operation = ptr->requestCompositionResize_lambda(m_id, in, out, right);
        } else {
            qDebug() << "Error : Moving clip failed because parent timeline is not available anymore";
            Q_ASSERT(false);
        }
    }
    auto operation = [this, in, out, track_operation]() {
        if (track_operation()) {
            service()->set_in_and_out(in, out);
            return true;
        }
        return false;
    };
    if (operation()) {
        // Now, we are in the state in which the timeline should be when we try to revert current action. So we can build the reverse action from here
        auto ptr = m_parent.lock();
        if (m_currentTrackId != -1 && ptr) {
            track_reverse = ptr->requestCompositionResize_lambda(m_id, old_in, old_out, right);
        }
        auto reverse = [this, old_in, old_out, track_reverse]() {
            if (track_reverse()) {
                service()->set_in_and_out(old_in, old_out);
                return true;
            }
            return false;
        };
        UPDATE_UNDO_REDO(operation, reverse, undo, redo);
        return true;
    }*/
    return false;
}


Mlt::Transition* CompositionModel::service() const
{
    return static_cast<Mlt::Transition*>(m_asset.get());
}

int CompositionModel::getPlaytime() const
{
    return service()->get_length();
}
