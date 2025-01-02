#include "hexagonalgrid.h"

HexagonalGrid::HexagonalGrid(QObject *parent)
    : QAbstractItemModel(parent)
{}

QVariant HexagonalGrid::headerData(int section, Qt::Orientation orientation, int role) const
{
    // FIXME: Implement me!
}

QModelIndex HexagonalGrid::index(int row, int column, const QModelIndex &parent) const
{
    // FIXME: Implement me!
}

QModelIndex HexagonalGrid::parent(const QModelIndex &index) const
{
    // FIXME: Implement me!
}

int HexagonalGrid::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid())
        return 0;

    // FIXME: Implement me!
}

int HexagonalGrid::columnCount(const QModelIndex &parent) const
{
    if (!parent.isValid())
        return 0;

    // FIXME: Implement me!
}

QVariant HexagonalGrid::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    // FIXME: Implement me!
    return QVariant();
}
